#!/usr/bin/env python3
"""Daily Claude budget guard for this project (owner's rule).

The weekly limit resets Saturday 3:00 pm Dubai. Each 24 hours after that adds
1/7 of the week (~14.3%): day 1 = 14%, day 2 = 29%, ... Unused room carries over.
When TOTAL weekly usage reaches today's line, work on this game stops until the
next day starts. Typing "budget override" in a message unlocks the rest of that day.

Usage numbers come from ~/.claude/usage-latest.json, written by the status line
script (~/.claude/usage-statusline.py). No numbers = no blocking.
"""
import json, os, sys, time
from datetime import datetime, timedelta, timezone

DAY = 86400
DUBAI = timezone(timedelta(hours=4))
USAGE = os.path.expanduser("~/.claude/usage-latest.json")
OVERRIDE = os.path.expanduser("~/.claude/usage-override-dwarf-game")


def week_start(resets_at, now):
    if resets_at and resets_at > now:
        return resets_at - 7 * DAY
    # Fallback: most recent Saturday 15:00 Dubai.
    t = datetime.fromtimestamp(now, DUBAI)
    sat = (t - timedelta(days=(t.weekday() - 5) % 7)).replace(hour=15, minute=0, second=0, microsecond=0)
    if sat.timestamp() > now:
        sat -= timedelta(days=7)
    return sat.timestamp()


def verdict(used, resets_at, now):
    """Returns (blocked, day_number, line_percent, next_day_epoch)."""
    start = week_start(resets_at, now)
    day = int((now - start) // DAY) + 1
    line = min(100.0, day * 100 / 7)
    return used >= line, day, line, start + day * DAY


def main():
    hook = json.load(sys.stdin)
    try:
        u = json.load(open(USAGE))
    except (OSError, ValueError):
        return 0
    now = time.time()
    # Data from last week (before the reset) says nothing about this week.
    if u.get("resets_at") and u["resets_at"] <= now:
        return 0
    blocked, day, line, next_day = verdict(u["used"], u.get("resets_at"), now)
    if not blocked:
        return 0
    day_key = str(int(next_day))
    if "budget override" in (hook.get("prompt") or "").lower():
        open(OVERRIDE, "w").write(day_key)
        return 0
    try:
        if open(OVERRIDE).read().strip() == day_key:
            return 0
    except OSError:
        pass
    weekday = datetime.fromtimestamp(now, DUBAI).strftime("%A")
    opens = datetime.fromtimestamp(next_day, DUBAI).strftime("%a %-I:%M %p")
    print(
        f"Daily budget reached: we hit the {line:.0f}% line for day {day} ({weekday}). "
        f"Weekly usage is {u['used']:.0f}%. Work on the dwarf game pauses until {opens} Dubai time. "
        f"STOP now, don't start new work, and tell the owner this in simple words. "
        f"(Owner can type 'budget override' to keep going today.)",
        file=sys.stderr,
    )
    return 2


if __name__ == "__main__":
    sys.exit(main())
