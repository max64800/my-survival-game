"""Moves journal entries from journal-inbox/ into JOURNAL.md (owner, Nov 21).

Why: 4-5 Claudes run at once. When they all edit JOURNAL.md, their notes get mixed up and untangling them costs
tokens. So each chat writes its entry as its OWN new file, journal-inbox/<YYYY-MM-DD-HHMM>-<topic>.md, and commits
it with its work. This script (run it right after a commit:  python3 tools/journal/merge_inbox.py) adds every
committed inbox file to the end of JOURNAL.md in time order, deletes it, and commits just that, without touching
anything else anyone is working on (other chats' unsaved JOURNAL.md lines stay unsaved in the working copy).
"""
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
INBOX = "journal-inbox"


def git(*args, env=None, inp=None):
    r = subprocess.run(["git", *args], cwd=ROOT, env=env, input=inp, capture_output=True)
    return r.returncode, r.stdout


def main():
    folder = os.path.join(ROOT, INBOX)
    names = sorted(n for n in os.listdir(folder) if n.endswith(".md") and n != "README.md") if os.path.isdir(folder) else []
    ready = []
    for n in names:
        rel = f"{INBOX}/{n}"
        tracked = git("ls-files", "--error-unmatch", rel)[0] == 0
        clean = git("diff", "--quiet", "HEAD", "--", rel)[0] == 0
        if tracked and clean:  # only entries already committed and unchanged (another chat may still be writing one)
            ready.append(rel)
    if not ready:
        print("journal inbox: nothing to merge")
        return 0
    text = ""
    for rel in ready:
        body = open(os.path.join(ROOT, rel), encoding="utf-8").read().replace("\r\n", "\n").strip("\n")
        text += "\n\n" + body + "\n"
    # 1) the committed JOURNAL.md = the last committed one + the entries
    code, head = git("show", "HEAD:JOURNAL.md")
    if code:
        print("journal inbox: can't read JOURNAL.md from git"); return 1
    new_head = head.decode("utf-8").rstrip("\n") + "\n" + text
    idx = os.path.join(tempfile.mkdtemp(), "index")
    env = dict(os.environ, GIT_INDEX_FILE=idx)
    blob = git("hash-object", "-w", "--stdin", inp=new_head.encode("utf-8"))[1].decode().strip()
    git("read-tree", "HEAD", env=env)
    git("update-index", "--cacheinfo", f"100644,{blob},JOURNAL.md", env=env)
    for rel in ready:
        git("update-index", "--force-remove", rel, env=env)
    code, out = git("commit", "-q", "-m", f"Journal: {len(ready)} inbox entr{'y' if len(ready) == 1 else 'ies'} moved into JOURNAL.md", env=env)
    if code:
        print("journal inbox: commit failed", out.decode(errors="replace")); return 1
    # 2) the working copy: keep whatever is there (other chats' unsaved lines) and add the entries at the end
    jp = os.path.join(ROOT, "JOURNAL.md")
    raw = open(jp, "rb").read()
    before = len(raw)
    raw = raw.rstrip(b"\r\n") + b"\n" + text.encode("utf-8")
    assert len(raw) >= before, "JOURNAL.md got shorter: stopped"
    open(jp, "wb").write(raw)
    for rel in ready:
        os.remove(os.path.join(ROOT, rel))
    git("reset", "-q", "--", "JOURNAL.md", *ready)  # the real index follows the new commit for just these paths
    print(f"journal inbox: moved {len(ready)} entr{'y' if len(ready) == 1 else 'ies'} into JOURNAL.md (committed, not pushed)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
