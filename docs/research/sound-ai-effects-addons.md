# Sound, monster brains and effects: add-on research (2026-11-19)

Research only. Nothing was downloaded, installed or changed.

**Words used here**
- **Add-on / plugin:** an extra piece someone else made that we drop into the game.
- **GDExtension:** an add-on that plugs into the normal Godot program. We use these (like Voxel Tools and GodotSteam).
- **Module:** an add-on that needs Godot itself rebuilt from scratch. We never use these.
- **License:** the rules for using something. **CC0** = "do anything, no credit needed".
  **MIT** = "do anything, keep our small license note". **CC-BY** = "do anything, but credit us".
  **NC** (NonCommercial) = "not in anything you sell". NC is a hard **no** for us.
- **Host:** the player whose computer runs the real game in co-op. Others copy what the host says.

## What we already have

- Add-ons: only `addons/zylann.voxel` (Voxel Tools) and `addons/godotsteam`.
- Sound: `src/sfx.gd` plays Kenney CC0 sounds (plus our own creature sounds) at a spot in the world.
  Every sound goes to one "Master" channel. There are no echo (reverb) channels yet and no music.
- Monsters: `src/combat/monster.gd` has its own hand-made "state machine" (a list of moods:
  IDLE, WANDER, ALERT, CHASE, ATTACK, RECOVER, STUNNED, RETURN, SLEEP, FLEE).
  Only the host runs `think()`. `src/combat/monster_manager.gd` sends positions and events to the
  other players (`_ev_poses.rpc`, `_ev_spawn.rpc`, `_ev_tell.rpc`). This is already co-op-ready.
- Effects: `src/art/fire.gd` and `src/art/ambience.gd` already make fire and floating motes with
  Godot's built-in particles (`GPUParticles3D`). Fog uses Godot's built-in volumetric fog and `FogVolume`.

---

## Part 1. Sound

### 1a. Cave sound tech (echo and "sound blocked by rock")

| Rank | Option | What it is | License | Ready for us? |
|---|---|---|---|---|
| **1 (use this)** | **Godot built-in: `Area3D` reverb + low-pass on far sounds** | No add-on. An `Area3D` (an invisible box) can send any sound inside it to an echo channel (`reverb_bus_enabled`, `reverb_bus_name`, `reverb_bus_amount`). The channel has an `AudioEffectReverb` (room size, damping, wet). `AudioStreamPlayer3D` already has a built-in muffle filter (`attenuation_filter_cutoff_hz`). | Godot = MIT | Yes. Nothing to install or read. Free on the network: every computer makes its own echo. |
| 2 | Home-made "rock blocks sound" | One ray (an invisible line) from the listener to each loud sound, a few times a second. If rock is in the way: quieter and more muffled. Works with dug tunnels because it checks the real rock. | ours | Yes. About 30 lines. Cap it to the ~10 closest sounds so it stays cheap. |
| 3 | **Nexus Resonance** (Steam Audio GDExtension) | Real echo, sound through walls, and sound bending around corners. Uses Valve's Steam Audio. https://github.com/undomick/godot-nexus-resonance | MIT (Steam Audio inside is Apache 2.0, also fine) | Not yet. Made for Godot 4.6, version 0.9 / 1.0, young (86 stars). Wants "baking" (pre-computing) a fixed level. **Our caves change when you dig**, so baking fights our game. Native files can't be read line by line (see red flags). |
| 4 | stechyo **godot-steam-audio** | The older Steam Audio GDExtension. https://github.com/stechyo/godot-steam-audio | MIT | **No.** Author calls it "alpha, may crash", made for Godot 4.4, and the project was **archived (frozen) on 2026-10-07**. |
| 5 | vespergamedev godot_steamaudio | Steam Audio as a **module**. https://github.com/vespergamedev/godot_steamaudio | - | **No.** Module build: against our rules. |
| - | FMOD GDExtension | A pro sound engine. https://github.com/utopia-rise/fmod-gdextension | Add-on MIT, but FMOD itself needs its own license (free only under a money limit) | Not needed. Too big for what we want. |

**Use this:** built-in reverb areas (one echo channel for small tunnels, one for big caverns, one for
water caves) + the home-made "ray check" muffle. It matches what Steam Audio would give us 80% of the
way, costs nothing, and has no add-on to check. Look at Nexus Resonance again only if the owner wants
"hear exactly where it's coming from around a corner" sound later.

Performance: echo channels cost almost nothing. The ray checks are the only cost; limit how many and how
often. Co-op: sound is never sent over the network; each player hears their own mix.

### 1b. Free sound and music packs (commercial use OK)

| Rank | Source | Exact license | Link | Good for |
|---|---|---|---|---|
| **1 (use this)** | **Kenney audio packs** (we already use 3) | **CC0** | https://kenney.nl/assets/category:Audio | UI, impacts, footsteps, RPG sounds, short music jingles ("Music Jingles"). |
| **2 (use this)** | **Sonniss GDC bundles** (2015-2024, plus **GDC 2026**: 7.47 GB, 347+ files) | Sonniss's own license: royalty-free, commercial use OK, **no credit needed**, unlimited projects, forever. **Not allowed:** reselling the sounds as a sound pack, claiming you recorded them, AI training. Fine inside a finished game. (There was no 2025 bundle.) | https://sonniss.com/gameaudiogdc and https://gdc.sonniss.com | Pro-quality rock, mining, digging, footsteps on gravel, creatures, water, cave rooms. Best quality free source. |
| 3 | **Freesound, CC0 filter only** | Each sound has its own license. Take **CC0** only (CC-BY OK if we credit it). **Never CC-BY-NC.** | https://freesound.org/search/?q=cave+drip&f=license:%22Creative+Commons+0%22 (change the words: `pickaxe`, `rock impact`, `gravel footstep`, `cave ambience`, `growl`) | Single drips, small creature noises, odd one-off sounds. |
| 4 | **OpenGameArt, CC0 filter** | Per item, check the page. Example: "Loopable dungeon ambience" (CC0, drips + low wind). Watch out: many items are CC-BY or GPL. | https://opengameart.org/content/loopable-dungeon-ambience ; search with License = CC0, Type = Music or Sound | Cave background loops, some game music. |
| 5 | **Pixabay** sounds and music | "Pixabay Content License" (not CC0). Commercial use OK, no credit needed. **Not allowed:** selling it on its own unchanged. Risk: some Pixabay **music** is also registered with YouTube "Content ID", so our own Shorts could get copyright claims. | https://pixabay.com/service/license-summary/ | Sound effects OK. Music: only if we keep the download page saved as proof, and avoid it in Shorts. |
| 6 | CC-BY music (e.g. Kevin MacLeod, incompetech.com) | CC-BY 4.0: free for a sold game, **credit required**. | https://incompetech.com | Backup option for music if CC0 is thin. |

Not usable: anything marked NC, "free for personal use", or the paid itch.io / Artlist cave packs seen in
searches.

**Use this:** Sonniss GDC bundles for cave, mining, digging and creature sounds (best quality, no credit
needed); Kenney for UI and jingles; Freesound CC0 to fill gaps. For music: OpenGameArt CC0 first,
CC-BY second. Log every file in `CREDITS.md` with its link, as now. Sonniss files are huge: pick only the
few sounds we need and convert them to `.ogg` like the current ones.

---

## Part 2. Monster brains

**Behavior tree:** a flowchart of choices ("Can I see a dwarf? Then chase. Else wander.").
**State machine:** a list of moods with rules for switching (what we already have).
**Utility AI:** every action gets a score, the monster does the highest-scoring one.

| Rank | Add-on | Type | Godot 4.7 OK? | Maintained? | License | Notes |
|---|---|---|---|---|---|---|
| **1** | **LimboAI** https://github.com/limbonaut/limboai | Behavior trees + state machines, visual debugger | **Yes.** v1.8.1 (2026-08-20). The **GDExtension** edition works on Godot 4.6 and newer. (The module edition is only for rebuilt Godot: not for us.) | Yes, very active | MIT (demo art CC-BY 4.0: don't ship the demo art) | Written in C++, so fast with many monsters. Can run one shared update from our manager. GDExtension edition has a few fewer features than the module. Download is 30.8 MB (native files for every platform). |
| 2 | **Beehave** https://github.com/bitbrain/beehave | Behavior trees, written in GDScript | Yes, v2.9.3 says "compatible with latest Godot 4.7" | Yes | MIT | Plain GDScript: we *can* read every file, no native files. Slower than LimboAI with many monsters (each tree node is a script). Has a debug view. |
| 3 | Godot State Charts https://github.com/derkork/godot-statecharts | State machine made of nodes | Godot 4+ | Yes | MIT | Basically a nicer version of what we have. Little gain for us. |
| 4 | Utility AI GDExtension https://github.com/JarkkoPar/Utility_AI_GDExtension | Utility AI | Last listed for Godot 4.1 | Looks quiet | MIT | **Skip:** too old for 4.7. |

**Co-op note for all of them:** none of them handles the network. That is fine: we only run the brain on
the host (like now) and keep sending results with our existing `rpc` calls. On other players' computers
the brain stays switched off.

**Recommendation: keep our own state machine for now.** It already works, is host-only, and has no add-on
to check. Ten moods in one file is still easy to follow.

**When it gets too big, use LimboAI (GDExtension edition)**. Signs: bosses with many phases, monsters
that need "plans" (flank, call friends, hide), or `monster.gd` growing far past ~750 lines. How it would
fit:
1. Keep `Monster` and `MonsterManager` as they are. Only the inside of `think()` changes.
2. Each kind of monster gets one behavior-tree file (bat, snail, beetle, boss) instead of `if` chains.
3. The tree's blackboard (its notepad) holds `target_peer`, `home`, HP. The tree calls our existing
   helpers: `mgr.nearest_noticer(m)`, `mgr.alert_pack()`, `mgr.send_tell()`.
4. Set the tree player to manual update and step it from `MonsterManager._host_step()`, so only the host
   thinks and we control how often far monsters think (saves time with many monsters).
5. Move one monster kind first, test it, then the rest.

---

## Part 3. Effects (sparks, dust, fire, glow)

**Shader:** a small program that tells the graphics card how to paint a surface.
**Particles:** many tiny pictures flying around (sparks, dust, smoke).

| Rank | Source | License | Link | Fit with our hand-painted look |
|---|---|---|---|---|
| **1 (use this)** | **Godot built-in particles + our own painted textures** (as `fire.gd` already does) | ours | `GPUParticles3D`; swing trails: turn on particle trails with `RibbonTrailMesh` (works in our Forward+ renderer); fog: built-in volumetric fog + `FogVolume` (already used) | Best: we paint the textures ourselves, so the style always matches the workbenches. |
| **2 (use this)** | **Kenney Particle Pack** (80 pictures: smoke, sparks, flares, magic, dirt) | **CC0** | https://kenney.nl/assets/particle-pack | Good starting shapes. Clean and soft, a bit "clean cartoon"; tint and use as masks, or paint over in our style. |
| 3 | **godotshaders.com** | **Per shader**: each page shows CC0, MIT, GPL v3 or "Shadertoy port" at the bottom. Take **CC0 or MIT only**. **GPL = no** (would force our whole game open). **Shadertoy ports = no** (Shadertoy default is NC). | https://godotshaders.com/shader-license/cc0/ and https://godotshaders.com/shader-license/mit/ | Good for crystal glow, water drips, wobbly flames, toon fire. Copy only the idea/code; keep our colours. |
| 4 | REEBOO Stylized VFX Free Sample (hit spark, sword slash, pickup sparkle, < 100 particles each) | MIT | https://github.com/REEBO0/reeboo-stylized-vfx-free | Stylized, small, made for Godot 4.4. Good for hit sparks and swing arcs. Small enough to read in full. |
| 5 | VFEZ-godot (stackable shader effects) | MIT | https://github.com/alexnikop/vfez-godot | Mostly 2D-style effects; check if it helps for 3D. |
| 6 | GDQuest Godot 4 VFX assets | **Code MIT, but pictures and models CC-BY-NC-SA** | https://github.com/gdquest-demos/godot-4-VFX-assets | Learn from the shader code only. **Do not copy its textures or models** (NC = not in a sold game). |

**Use this:** keep making effects with Godot's built-in particles, start from Kenney's CC0 particle
pictures, and paint our own versions for the final look. When a hard effect is needed (crystal glow,
heat shimmer, toon fire), borrow a **CC0 or MIT** shader from godotshaders.com, write its link and license
into `CREDITS.md`, and recolour it. For hit sparks and swing trails, REEBOO's MIT sample is a good
example to read and copy ideas from.

---

## Red flags and "read every file" notes

- **Native files can't be read.** GDExtensions ship as `.dll` / `.so` / `.dylib` (finished machine code).
  We can only read their source code on GitHub and must download from the official Releases page.
  LimboAI (30.8 MB, C++, many files) and Nexus Resonance (C++ + Steam Audio) are big jobs to review.
  Voxel Tools and GodotSteam are the same kind; we already accepted that.
- **Beehave, REEBOO, godotshaders code** are plain GDScript / shader text: small enough to read in full.
- **No telemetry** (secret data sending) was mentioned by any of them. Nexus Resonance links to Discord and
  Ko-fi (donations) only. Beehave includes test-runner scripts (`runtest.sh`): never needed, never run.
- **Sonniss** downloads come from Sonniss's own server, Google Drive mirrors or a torrent: use the official
  server. They are plain sound files (`.wav`), no programs.
- **Licenses to watch:** NC (GDQuest art, Shadertoy), GPL (some godotshaders), Pixabay music + Content ID,
  LimboAI demo art (CC-BY). Archived: stechyo godot-steam-audio.

## Short answer

1. **Sound:** no add-on. Use Godot's built-in echo areas + a small "rock in the way" check. Get sounds from
   Sonniss GDC bundles and Kenney (both free for sold games, no credit needed), Freesound CC0 for gaps.
2. **Monsters:** keep our own state machine. If it gets too big, switch to **LimboAI GDExtension** (host only).
3. **Effects:** built-in particles + Kenney CC0 particle pictures + our own paint; CC0/MIT shaders from
   godotshaders.com when needed.

Checked 2026-11-19. Version numbers and licenses can change: check the page again before downloading.
