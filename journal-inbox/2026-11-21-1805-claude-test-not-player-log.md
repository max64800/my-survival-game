## Nov 21: Claude test games no longer pass as the owner's play log (token check chat)
- Found while building the quiet runner: a `claude=` test game printed "PLAYER GAME (not a robot)", the line the recorder
  uses to pick the owner's log, and opened the owner's watch file. Owner said fix it. `src/main.gd`: Claude test games
  (claude=... or muted) now print "CLAUDE TEST GAME (not the owner's)" and leave `user://watch.txt` alone.
  Checked with a real muted run.
