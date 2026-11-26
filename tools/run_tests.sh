#!/bin/sh
# Runs all auto-checks. Usage: tools/run_tests.sh [only=name] [fn=name] [verbose=1] [full=1 = also the slow checks]
# Prints only FAILs + the summary (game prints folded, shutdown chatter dropped) to save Claude tokens.
# verbose=1 shows every PASS line too; QUIET=0 shows the raw output.
# Set GODOT to your Godot program if it isn't on the PATH.
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path . --import >/dev/null 2>&1
python3 tools/quiet_run.py "$GODOT" --headless --audio-driver Dummy --path . --script res://tests/run_tests.gd -- "$@"
