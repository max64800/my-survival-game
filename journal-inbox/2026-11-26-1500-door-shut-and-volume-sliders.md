## 2026-11-26: Doors shut by themselves, four volume sliders (Mac, small fixes)

**What we did**
- F880 (skill pop-up only on level up) and F823 (stamina numbers): skipped, another chat already built both on Nov 23/25; they wait for the owner's play test.
- F869: an open door now swings shut by itself 30 s after it was opened. The host keeps a list of "shut at" times (`builder.gd` `_door_shut_at`, `DOOR_SHUT_TIME`) and closes the door with the normal `_ev_door` message, so every player sees it. Both leaves of a double gate get the timer. Test added to `test_doors_open_and_ladders_climb` (test_builder).
- F761: checked F876 first. Its Audio tab already had main volume + Music, so the plan didn't change and no question was needed. Added Effects and Voice sliders with their own sound buses (`sound_settings.gd`), remembered in settings.cfg. All `Sfx` sounds and the cave trickle play on Effects. Voice is ready for F739; nothing talks yet. Test: `test_effects_and_voice_volume_are_remembered` (test_sound_settings).

**Mistakes and hurdles**
- Godot isn't on the Mac, so none of this has been run yet. The owner runs the tests on the PC.
- First draft of the new settings test called `add_child` on the test itself. TestCase isn't a Node, so I switched to `tree.root.add_child` + one frame, the way test_hud_cleanup does it.
- Not covered: a door that was open when the world was saved doesn't auto-shut after loading until someone opens it again (the timers aren't saved).
