#!/bin/sh
# Runs all auto-checks. Usage: tools/run_tests.sh [only=name]
# Set GODOT to your Godot program if it isn't on the PATH.
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
"$GODOT" --headless --path . --import >/dev/null 2>&1
"$GODOT" --headless --path . --script res://tests/run_tests.gd -- "$@"
