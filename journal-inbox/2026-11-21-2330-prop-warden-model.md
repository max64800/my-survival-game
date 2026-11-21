## Nov 21, 2026: the Prop Warden gets his own model (F468)

**What we did**
- The boss of dungeon 4 (Mossprop Workings) had been wearing the Pit Boss's body. Now he has his own: the same free
  CC0 skeleton as the other miners (so all his moves still work), painted moss-green and rotten-wood brown. He wears a
  timber helmet with moss growing on top, a mossy beard, a double-bladed felling axe (his "Great Chop" is a cutting hit),
  and a big plank shield strapped to his left forearm: four rotten planks with broken tops, two boards and a brace nailed
  across, an iron band at the bottom, moss in the joints.
- Built by script like the other miners (tools/asset_forge/builds/kaykit_miners.py, new "prop_warden" entry), hooked
  into the game (monster_model.gd) and the dungeon plan (make_mossprop.py + mossprop_workings.json).
- The model check passes (nothing floating, no shimmer), the skeleton-miner tests and the model-rules tests pass, and the
  robot picture shows him in his room.
- Owner played Mossprop Workings for the first time and gave a big list: logged as F539-F547 (+ F526 said again).

**Mistakes and hurdles (and fixes)**
- **Shield in the wrong place.** First I put the shield in the left hand's "weapon slot". In the two-handed attacks that
  hand grabs the axe handle, so the shield went straight through the handle. Fix: a small test printed which way each bone
  points in every move. The forearm always points its outside the same way (out, left, forward), so the shield is
  strapped to the forearm instead.
- **Axe blades floating as paper-thin slivers (Claude's mistake).** I shaped the blades assuming each part's points were
  measured from its own middle, but the kit tool had already moved them to their final spot. Fix: measure from the
  blade's middle. Lesson: print a part's points before bending them.
- **Floating moustache.** The model check found the moustache 1 cm away from the face. Copying the Foreman's posture and
  chest size didn't help, because the gap came from the beard's random wobble. Fix: an opt-in setting that tucks only the
  Warden's moustache 2 cm in (the other miners stay the same).
- **Game crash on the first robot run.** The game couldn't get memory while 3 other Godot games (other chats) were
  running. The second run worked.
- **VS Code crashed mid-chat**, so the owner recorded the feedback again.
