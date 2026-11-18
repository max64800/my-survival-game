# Co-op and saves: what can go wrong, and what to do (research, Nov 19 2026)

Part C is co-op (playing together). Part D is saves (keeping the world safe on disk).
For each topic: **what can go wrong**, **how good games do it**, **what we should do** (with our files).

A few words first:
- **Host** = the player whose PC runs the "real" world. Friends are **clients**.
- **RPC** = a message one PC sends to another ("please dig here", "a hole was dug here").
- **Packet** = one parcel of data sent over the internet.
- **Snapshot** = a full photo of the world's changes, as data.

What we already have (good news, it is a solid base):
- `src/net/game_authority.gd` is the referee. Friends send `request_*`; the host checks it
  (for example "is it within reach?", `REACH`) and then tells everyone `_ev_*`.
- `src/net/session.gd` connects players two ways: direct IP (ENet) or a Steam friends-only lobby
  (`SteamMultiplayerPeer`). Steam part is marked "not yet tested with real accounts".
- `src/main.gd` `_on_peer_connected` sends a late joiner the seed + `authority.snapshot()` in one `_welcome` RPC.
- The world on disk = seed + `edit_log` (a list of every dig, `Array[Vector4]`), replayed on load.
- `src/save_game.gd` already writes to a `.tmp` file, then renames, and keeps 3 backups (`.1 .2 .3`).
  It loads with `get_var(false)`, which never builds code objects from the file. That is the safe choice.
- `src/debug/netcheck.gd` is a robot that checks host and friend see the same holes.

---

## Part C: Co-op problems

### C1. The host leaves
- **What goes wrong:** the host's PC *is* the world. When it leaves, everyone is kicked out.
  Today `_on_server_disconnected` (main.gd) shows "The host left", waits 4 s and reloads. Friends lose nothing
  (the host saved), but the session just ends.
- **How others do it:** Valheim, Core Keeper and Deep Rock Galactic do **not** move the host. The session ends.
  Valheim and Core Keeper offer a free **dedicated server** (a program that runs the world with no player)
  instead ([Valheim world move guide](https://connecthosting.net/blog/move-valheim-world-to-dedicated-server),
  [Core Keeper co-op guide](https://www.itechguides.com/how-to-play-core-keeper-co-op-with-friends/)).
  **Host migration** (a friend takes over live) is very hard and rare in indie games; even big studios get it wrong
  ([Warframe players losing loot on migration](https://forums.warframe.com/topic/1358724-when-will-you-fix-the-host-migration-everything-collected-is-lost/)).
- **Our plan:** keep "session ends", like the big ones. Add two cheap things:
  1. The host saves **before** it quits or leaves to the menu (already done on window close; also do it on "Leave game").
  2. Later, a "Give world to a friend" button: the host sends its save file to a friend (a **save handoff**).
  Skip live host migration.

### C2. Who owns the world save
- **What goes wrong:** if friends also save, you get 4 different copies of the "same" world that disagree.
- **How others do it:** in Valheim and Terraria the world file lives only on the host. Each player's *character*
  is a separate file. Valheim's character file lives on the player's own PC (which lets people cheat-carry items between worlds).
- **Our plan:** we already do "only the host saves" (`SaveGame.save` returns "Only the host saves the world").
  Friends' dwarves are stored *inside* the host's world save, by **slot number**.
  **Problem:** `_free_slot()` gives the first free number. If Friend 2 joins before Friend 1 next time,
  they get Friend 1's bag and skills. Fix: key the dwarf by the friend's **Steam ID** (their fixed Steam account number),
  fall back to slot only for direct-IP tests.

### C3. Joining mid-game (sending the dug world to a new player)
- **What goes wrong:** the whole catch-up package (`snapshot()`, including every dig ever) goes in **one** RPC.
  Steam's network has a size limit of **512 KB per message**
  ([GameNetworkingSockets issue: "Max is 524288"](https://github.com/ValveSoftware/GameNetworkingSockets/issues/394)).
  Each dig is about 20 bytes, so after roughly 20,000-25,000 digs (plus stations, chests, drops) the welcome
  message is too big and **the friend can never join**. Direct IP (ENet) splits big messages, so our tests won't catch this.
  Also, replaying 25,000 digs on load gets slow.
- **How others do it:** voxel games send the world **in pieces (chunks)**, nearest first, while showing a loading screen.
  Zylann's Voxel Tools has a `VoxelTerrainMultiplayerSynchronizer` for this, and its stream saves
  **only blocks that changed** ([Voxel Tools streams](https://voxel-tools.readthedocs.io/en/latest/streams/),
  [changelog](https://voxel-tools.readthedocs.io/en/latest/changelog/)).
- **Our plan (two steps):**
  1. Now: cut the welcome into parts. Send the small stuff first, then `edits` in batches of ~2,000,
     then a "done" message. Compress `edits` as one `PackedFloat32Array` (a tight list of numbers), not a list of Vector4s.
  2. Later, when the log gets huge: save and send **changed chunks** instead of the full dig history.
  Add a netcheck case with 30,000 fake digs that fails if any single message is over 400 KB.

### C4. Four players digging at once
- **What goes wrong:** two digs in the same spot in a different order give different shapes; lots of digs flood the network.
- **How we do it now (good):** the host decides the order; reliable RPCs arrive in order; `_apply_pending_digs`
  makes nearby digs wait their turn, so a fill and a dig never swap. Each dig is one small message (a `Vector4`).
- **Our plan:** keep it. If 4 players with fast picks cause stutter, **batch** digs: send all digs from one
  frame (1/60 s) in one message instead of one each. No other change needed now.

### C5. Hiding lag (prediction)
- **What goes wrong:** a friend swings, the request goes to the host and back. With 100 ms ping the hole appears
  late and digging feels "sticky". Today friends wait for the host; nothing is predicted.
- **How others do it:** **client prediction** = the friend's game shows the result right away, then corrects it
  if the host says no. Most co-op survival games predict *effects* (sound, sparks, swing) but let the host decide
  *results* (the hole, the loot, the damage).
- **Our plan:** play the swing, sound and sparks instantly on the friend's PC (no waiting). Keep the hole and loot
  host-decided. Only if digging still feels slow: show a "ghost" hole instantly and undo it if the host rejects it.
  Combat: let the friend see their own hit spark instantly; the host decides damage. Monsters already move with
  `unreliable_ordered` (fast messages that may drop, which is fine for movement).

### C6. Desync (players seeing different worlds)
- **What goes wrong:** a message is missed or applied twice, and the friend's cave slowly differs from the host's.
  A friend then walks through a wall the host thinks is there.
- **How others do it:** send a small **checksum** (a fingerprint number of the data) now and then; if it differs, resend.
- **Our plan:** every 30 s the host sends the count of edits + a simple fingerprint of the last 100 edits.
  If a friend's doesn't match, it asks for the missing edits. `netcheck.gd` already compares counts; reuse that idea.

### C7. Steam lobbies, relay and NAT
- **NAT** = your home router hides your PC; strangers can't reach it directly. Direct IP play needs port-forwarding.
- **How others do it:** Steam's **Datagram Relay** sends traffic through Valve's servers. No port-forwarding,
  and IP addresses stay hidden ([Steam Datagram Relay](https://partner.steamgames.com/doc/features/multiplayer/steamdatagramrelay)).
  `SteamMultiplayerPeer` uses Steam's socket system as a drop-in for ENet
  ([steam-multiplayer-peer](https://github.com/expressobits/steam-multiplayer-peer)).
- **Our plan:** `session.gd` already uses a friends-only lobby + `SteamMultiplayerPeer`. Good. Missing:
  test it on 2 real Steam accounts; check the lobby's `"game"` tag when joining (app 480 "Spacewar" is shared by
  thousands of test games); get our own app id before release. Keep direct IP for home tests only.

### C8. Bandwidth (how much data per second)
- **Rule of thumb:** keep each player under ~10-30 KB/s in normal play, so weak home internet works.
- **Our numbers:** a dwarf pose (`_net_pose`, position + turn) is ~20 bytes. At 20 per second × 4 players it's tiny.
  Digs are tiny. The risk is only the big welcome message (C3).
- **Our plan:** send pose at 20 times a second, not every frame, and only when the dwarf moved. Add a debug line
  that prints bytes sent per second.

### C9. Testing co-op alone
- Godot can start several game windows at once: **Debug > Customize Run Instances**
  ([Godot multiplayer article](https://godotengine.org/article/multiplayer-in-godot-4-0-scene-replication/)).
  We already have the `netcheck` robot doing host + friend over direct IP.
- **Missing:** fake bad internet. Add a test option that delays and drops messages (e.g. 150 ms, 2 % loss),
  and a 4-window run. Steam itself can't be tested with one account; it needs 2 PCs or 2 accounts.

---

## Part D: Saves that never break

### D1. Safe writing (atomic writes)
- **What goes wrong:** the game crashes or power goes out mid-save, leaving half a file.
- **How others do it:** write a temp file, check it, then rename it over the old one. The rename is all-or-nothing.
- **Ours:** `save_game.gd` already does temp + rename + backups. Two small gaps:
  1. It doesn't **read the temp file back** before renaming. Add: `read(tmp)` must not be empty, else stop and keep the old save.
  2. It ignores the results of `rename_absolute`. If a rename fails (antivirus or OneDrive holding the file on Windows),
     we don't know. Check the result and show "Save failed" if so.

### D2. Backups and rotation
- **Ours:** 3 backups, rotated on every save, and loading falls back to the newest good one. Good.
- **Gap:** all 3 backups can be only 15 minutes old (autosave every 5 min). If a bug quietly ruins the world,
  all backups are ruined too within 15 minutes.
- **Plan:** also keep **one backup per day** for the last 3 days (`world_X.save.day1` etc.).

### D3. Save versions and updates (the biggest save risk)
- **What goes wrong:** `read()` throws away any file whose `version` isn't exactly `VERSION` (1).
  The day we change the save and set `VERSION = 2`, **every old save and every backup looks broken**:
  the world list hides them and "Continue" finds nothing. Players would think their worlds were deleted.
- **How others do it:** every save has a version number; the game keeps small **migration** steps
  ("turn a version 1 save into version 2") and runs them in order on load. Valheim players are told to back up
  before big updates because version mismatches are the main thing that stops worlds loading
  ([Valheim update guide](https://guildorder.com/games/valheim/guides/migrating-a-crew-through-a-major-update)).
- **Plan:** change `read()` to accept any version up to ours and run `migrate_1_to_2()` etc. Refuse only saves from a
  **newer** game, with a clear message ("This world is from a newer version, please update"). Before migrating,
  copy the old file to `world_X.save.v1` so nothing is lost. Add a test that keeps a real version-1 save in the repo
  and checks it still loads after every change.

### D4. Steam Cloud
- **What it is:** Steam copies save files to its servers so they follow you to another PC.
- **What goes wrong:** two PCs with different saves give a "conflict" window; picking wrong loses progress.
  Steam does not auto-pick ([Steam Support](https://help.steampowered.com/faqs/view/68D2-35AB-09A9-7678)).
- **Plan:** when we have our own app id, turn on **Auto-Cloud** for `user://saves/*.save` only (not backups,
  not robot saves). Keep files small (see D7) so uploads are fast.

### D5. Spotting a broken file (checksums)
- **What goes wrong:** a file can be cut short or have flipped bits. A compressed file usually fails to open (good),
  but not always.
- **Plan:** store a checksum next to the data: save `{data, check = hash of data}`; on load, recompute and compare.
  Godot has `hash()` and `HashingContext` for this. If it differs, try the next backup (the fallback already exists).

### D6. When to autosave
- **Ours:** every 5 minutes + on quit (spec 5.11), host only. Fine.
- **Plan:** also save on "Leave game"/"Back to menu", right after a friend leaves, and after big events
  (boss beaten, station built). Don't save during a fight or while chunks are still loading; wait a few seconds instead.
  Show a small icon while saving.

### D7. Saving the voxel world (only what changed)
- **Ours:** we save the seed + every dig ever (`edit_log`). Simple and correct, but it only grows. 100 hours of
  digging = a big file and a slow load (every dig is replayed).
- **How others do it:** Voxel Tools' streams save **only changed blocks** (16×16×16 cubes) and skip the rest,
  because the seed can rebuild untouched rock ([Voxel Tools streams](https://voxel-tools.readthedocs.io/en/latest/streams/),
  [VoxelStream](https://voxel-tools.readthedocs.io/en/latest/api/VoxelStream/)).
- **Plan:** keep the dig log for now. When it passes ~20,000 digs, switch to "changed chunks" (one stored block per
  chunk someone touched). This also fixes C3. Measure first: print the dig count and file size in the save note.

### D8. Co-op save ownership
- Covered in C2. Short version: host owns the world file; friends' dwarves live in it, keyed by Steam ID.
  Optional later: a friend also keeps a copy of their own dwarf, so they can bring it to another world
  (that's how Valheim works, but it allows cheating; ask the owner first).

### D9. What Godot gives us, and the traps
- `FileAccess.store_var` / `get_var(false)`: plain data, safe. **This is what we use. Keep it.**
- `ResourceSaver` / `ResourceLoader` with `.tres`/`.res` files: **never for saves.** A `.tres` can contain a script
  that runs the moment it's loaded, so a shared "cool world save" could run harmful code
  ([GDQuest save guide](https://gdquest.com/library/save_game_godot4),
  [Safe Resource Loader warning](https://github.com/derkork/godot-safe-resource-loader)).
  Also never use `get_var(true)` on a save.
- New in 2026: a reported code-run bug in Godot 4.1-4.7.2 when loading **translation (.po) files**
  ([oss-security](https://seclists.org/oss-sec/2026/q4/396)). We don't load those from players, but watch for a Godot patch.
- Co-op data is also "a file from a stranger": the host must treat every `request_*` as untrusted (it does with
  `REACH` checks), and friends should check sizes in the `_welcome` data before using it.

---

## Top 5 risks to fix before co-op (Step 2) grows

1. **Save version lock-out (D3).** Changing `VERSION` in `src/save_game.gd` today would hide every world.
   Add migrations + "newer version" message + a test with an old save. *Small job, huge risk.*
2. **Welcome message too big for Steam (C3).** `_welcome` in `src/main.gd` sends everything in one message;
   past ~20,000 digs friends can't join over Steam (512 KB limit). Send it in parts; pack edits tightly.
3. **Friends get the wrong dwarf (C2).** `_free_slot()` in `src/main.gd` matches dwarves by join order.
   Use Steam ID.
4. **Save not checked before replacing (D1, D5).** In `src/save_game.gd`, read the temp file back, check rename results,
   add a checksum. Add one daily backup (D2).
5. **Steam path never tested (C7, C9).** `src/net/session.gd` Steam code is untested with real accounts, and we have no
   bad-internet test. Do one 2-account test on the PC, and add a lag/loss option to `netcheck`.

Nice-to-have later: effects-first prediction for friends (C5), desync fingerprint (C6), changed-chunk saves (D7),
Steam Cloud (D4), "give world to a friend" (C1).

## Sources
- [Steam Datagram Relay](https://partner.steamgames.com/doc/features/multiplayer/steamdatagramrelay) ·
  [Steam networking overview](https://partner.steamgames.com/doc/features/multiplayer/networking) ·
  [GameNetworkingSockets 512 KB limit](https://github.com/ValveSoftware/GameNetworkingSockets/issues/394)
- [steam-multiplayer-peer](https://github.com/expressobits/steam-multiplayer-peer) · [GodotSteam P2P tutorial](https://godotsteam.com/tutorials/p2p)
- [Voxel Tools streams](https://voxel-tools.readthedocs.io/en/latest/streams/) · [VoxelStream API](https://voxel-tools.readthedocs.io/en/latest/api/VoxelStream/) · [Voxel Tools changelog](https://voxel-tools.readthedocs.io/en/latest/changelog/)
- [Godot multiplayer in 4.0 (multiple instances tip)](https://godotengine.org/article/multiplayer-in-godot-4-0-scene-replication/)
- [GDQuest: saving in Godot 4](https://gdquest.com/library/save_game_godot4) · [Godot Safe Resource Loader](https://github.com/derkork/godot-safe-resource-loader) · [oss-security Godot report](https://seclists.org/oss-sec/2026/q4/396)
- [Valheim: moving a world](https://connecthosting.net/blog/move-valheim-world-to-dedicated-server) · [Valheim: big updates](https://guildorder.com/games/valheim/guides/migrating-a-crew-through-a-major-update)
- [Core Keeper co-op](https://www.itechguides.com/how-to-play-core-keeper-co-op-with-friends/) · [Deep Rock Galactic: host migration requests](https://devtrackers.gg/deep-rock-galactic/p/17551c7b-host-migration-should-be-mandatory-for-any-game-with-peer-to-peer-connections)
- [Steam Cloud conflicts (Steam Support)](https://help.steampowered.com/faqs/view/68D2-35AB-09A9-7678)

Note: Valheim/Core Keeper facts come from fan and hosting guides, not official studio pages. Byte sizes are estimates;
measure before acting on C3/D7.
