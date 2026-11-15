#!/usr/bin/env python3
# Self-check for check.py: python3 tools/claude-budget/test_check.py
import os, sys
sys.path.insert(0, os.path.dirname(__file__))
from check import verdict, DAY

reset = 1_000_000_000 + 7 * DAY  # week starts at 1_000_000_000
start = reset - 7 * DAY

assert verdict(10, reset, start + 3600) == (False, 1, 100 / 7, start + DAY)   # day 1, 10% < 14%
assert verdict(15, reset, start + 3600)[0] is True                              # day 1, 15% >= 14%
assert verdict(15, reset, start + DAY + 1)[:2] == (False, 2)                    # day 2 line is 29%
assert verdict(20, reset, start + 4 * DAY)[0] is False                          # carry-over: day 5 line 71%
assert verdict(99, reset, start + 6.9 * DAY)[2] == 100                          # day 7 line is 100%
# Fallback with no reset time: still a day number 1..7.
assert 1 <= verdict(0, None, start)[1] <= 7
print("ok")
