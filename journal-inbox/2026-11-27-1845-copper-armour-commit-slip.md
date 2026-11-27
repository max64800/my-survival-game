## 2026-11-27 18:45 — Commit slip: other chats' journal drafts (F914 chat)

- Mistake: after merging the journal, Claude ran `git add journal-inbox` (the whole folder). That also committed five unfinished journal drafts from other chats, and they were pushed.
- Fix: un-tracked them again with `git rm --cached` (the files stay on disk for their own chats) and pushed. None of them had personal paths in them.
- Lesson: after merge_inbox, add only `JOURNAL.md` and your own inbox file by name, never the whole folder.
