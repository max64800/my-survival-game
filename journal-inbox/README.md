# Journal inbox

Each Claude chat writes its journal entry here as its own new file, `<YYYY-MM-DD-HHMM>-<topic>.md`
(same format as a `JOURNAL.md` entry: a `## Nov 21: ...` heading, then bullets). Commit it with your work, then run
`python3 tools/journal/merge_inbox.py`: it moves every committed entry to the end of `JOURNAL.md` in time order.
Why: several chats run at once, and editing `JOURNAL.md` together mixed their notes up (owner, Nov 21).
