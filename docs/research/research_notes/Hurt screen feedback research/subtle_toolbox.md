# Subtle hurt-signal toolbox (3D third-person dwarf game)

Scope: small "you got hurt" signals to use instead of, or next to, a full-screen edge effect. Each value is tagged:
- **[Sourced]** taken from the linked page (checked in this research)
- **[Suggested]** a starting value from general game-dev practice, NOT verified by a source here. Tune by feel.
- **[Gap]** searched, nothing usable found

Existing game values (from the team): hit-stop 0.06 s light, 0.11 s heavy; camera shake on the attacker.

## HUD: health bar and ghost (delayed-damage) bar

### Takeaway
A "ghost bar" (a second bar segment that lags behind the real health and drains after a hit) is a well-known subtle signal: the player sees how much they lost without the screen changing. Exact timings from real games were NOT found in this research.

### Cited Findings
- Street Fighter Alpha 3 uses a second, differently coloured bar that trails behind the main health bar and shows the damage just taken. Source: [Derek Daniels, "Damage Presentation" (2013)](https://derek-daniels.squarespace.com/blog/2013/3/1/damage-presentation) (search summary only; page not fetched).
- Tekken 8 has a grey "recoverable health" bar, and Giant Bomb defines the general idea as "Recoverable Health" / "Red Health": [Esports.gg Tekken 8 health guide](https://esports.gg/guides/tekken-8/health-in-tekken-8-explained), [Giant Bomb wiki](https://giantbomb.com/wiki/Concepts/Recoverable_Health).
- Windrose (not a fighting game) uses "Temporal Health": damage turns part of HP into a translucent segment that vanishes if not won back in time: [Allthings.how](https://allthings.how/temporal-health-in-windrose-explained/).
- Unreal Marketplace has a trailing damage-bar widget for action/RPG games: [FAB listing](https://www.fab.com/listings/0ab7ee41-cdf5-4010-840f-0fd2e15c4742) (search result only).

### Inferences
- A ghost bar is a good "you got hurt" signal because it changes only the HUD corner, not the whole screen. It also tells the player the hit size.
- Keep the real health bar updating instantly and let only the ghost segment lag, so the number on screen is always honest.
- Use an unscaled (real-time) timer for the ghost drain. The game uses hit-stop, which slows game time; a ghost bar tied to game time would freeze during hit-stop.

### Toolbox (HUD)
| Option | Value | Source |
|---|---|---|
| Ghost bar hold before drain | 0.5 to 1.0 s, then drain | [Suggested] (from the brief; not verified) |
| Ghost bar drain speed | ease-out over 0.3 to 0.5 s | [Suggested] |
| Ghost colour | pale yellow or white, low alpha (about 0.6) | [Suggested] |
| Bar shake on hit | 2 to 4 px sideways, 0.1 s, decays | [Suggested] |
| Heart-icon shake (Zelda/Minecraft-style) | short 0.15 to 0.25 s jiggle on the lost heart only | [Gap] (not searched; no sourced numbers) |
| Floating damage numbers | small, fade in 0.1 s, float 30 to 40 px over 0.6 s | [Suggested] |
| Low-health bar pulse | slow 1 Hz pulse on the bar only | [Suggested] (see the low-health section) |

## Character: hurt animation, tint, blink, grunt

### Takeaway
Most hurt feedback in games is on the character itself. Values were NOT sourced here for hurt flash colour or invulnerability blink timing beyond one reference point.

### Cited Findings
- Terraria's default invulnerability after taking damage is 0.67 s: [Terraria wiki, Invulnerability frames](https://terraria.wiki.gg/wiki/Invulnerability_frames). (Reference point only; it is a sandbox game.)
- A game-feel article claims a 2-frame white flash on impact is a common default and that Hollow Knight uses it on every hit: [freegamesprites, game feel 2D combat](https://freegamesprites.com/es/news/game-feel-2d-combat-juice-tricks). Secondary source, not verified.
- Hades i-frame and hit-flash frame counts were NOT found: [Gap]. A Hades Steam thread says dash i-frames feel shorter, with no frame count.

### Toolbox (character)
| Option | Value | Source |
|---|---|---|
| White flash on dwarf (Hades-style) | 2 to 3 frames at 60 fps (0.03 to 0.05 s), then back | [Suggested]; 2 frames is the one secondary claim above |
| Red tint (Minecraft-style) | modulate toward red, about 40 to 50 percent, 0.15 to 0.25 s | [Suggested] (Minecraft values not searched) |
| Invulnerability blink | 0.5 to 0.7 s total, on/off every 0.07 to 0.1 s, only the dwarf mesh | [Suggested]; the 0.67 s total comes from Terraria [Sourced] |
| Flinch | 0.2 to 0.3 s head/torso lean, no root motion change | [Suggested] |
| Dwarf grunt | short voice clip, random pick of 3 to 4, 0.3 to 0.6 s | [Suggested] |

Caution: keep the blink on the dwarf only and at most a few seconds of total time. Repeated blinking is a fast on/off pattern, so see the photosensitivity section.

## Camera: a small kick when the PLAYER is hit

### Takeaway
A trauma-based shake (offset = trauma squared, trauma drops over time) is a clean, tunable model. Accessibility guidance says camera shake must be optional, so every camera signal should have a slider.

### Cited Findings
- Trauma model: trauma 0 to 1; offset scales with trauma squared; decay 4.0 per second; max offset 12 px at full trauma; a hit adds 0.3 to 0.4 trauma. Source: [saltmire, Godot 4 screen shake and hit stop (dev.to)](https://dev.to/saltmire/godot-4-screen-shake-and-hit-stop-in-one-script-11eh). Note this is a 2D Camera2D example; for 3D, use degrees or centimetres instead of pixels.
- Hit-stop default in the same article: 0.08 s freeze, time scale 0.05, timer runs in real time, and "60 to 120 ms is plenty". Source: same page.
- Accessibility guidance (Xbox XAG 117): avoid camera shake, camera bobbing and motion blur, or provide a way to turn them off. Halo Infinite lets players set radial blur, screen shake and full-screen effects from 0 to 100 percent. Cyberpunk 2077 has an additive-camera slider. Elder Scrolls Online has a head-bob slider. Source: [Microsoft XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117).
- Overwatch 2 shake was judged too aggressive, and players ask for toggles regularly: [Blizzard forum thread](https://us.forums.blizzard.com/en/overwatch/t/overwatch-2-accessibility-and-screen-shake/671231) (search summary only).

### Toolbox (camera, player hit)
| Option | Value | Source |
|---|---|---|
| Hurt kick, light hit | trauma 0.2 to 0.3, about 0.2 to 0.3 degrees of pitch/roll, 0.15 s | [Suggested]; trauma values from saltmire [Sourced] |
| Hurt kick, heavy hit | trauma 0.4, about 0.5 degrees, 0.25 s | [Suggested] |
| Shake frequency | re-randomise every frame at 60 fps, which is the saltmire pattern | [Sourced] (the pattern; no Hz value stated) |
| Brief FOV punch | +2 to +3 degrees for 0.1 s, then back | [Suggested]; FOV-as-setting is in XAG 117 [Sourced] |
| Tiny slow-mo | not recommended as a default: hit-stop already slows time | [Suggested] |
| Player setting | "Hurt camera effects" 0 to 100 percent, default about 50 | [Sourced as the pattern: Halo Infinite, XAG 117] |

Caution: camera motion in third person can cause motion sickness. Keep the kick short, small, and off by default for players who choose the "reduce motion" setting.

## Audio: grunt, impact, muffle, ringing, heartbeat, ducking

### Takeaway
A muffle (low-pass filter) on hits or a short ring is a strong subtle signal. Godot gives you the tool; the durations below are suggestions, not sourced.

### Cited Findings
- Godot's AudioEffectLowPassFilter attenuates frequencies above a cutoff; its default cutoff is 2000 Hz, and the cutoff is the `cutoff_hz` property on AudioEffectFilter. The docs say it can muffle sounds: [Godot docs, AudioEffectLowPassFilter](https://docs.godotengine.org/en/4.7/classes/class_audioeffectlowpassfilter.html). A Godot 4.4 tutorial lists muffled-by-wall as a use case: [Godot docs, audio effects](https://docs.godotengine.org/en/4.4/tutorials/audio/audio_effects.html).

### Toolbox (audio)
| Option | Value | Source |
|---|---|---|
| Hit muffle (world sounds) | cutoff to 800 to 1200 Hz on a dedicated bus, then tween back to 2000 or higher over 0.3 to 0.5 s | [Suggested] (cutoff default is sourced) |
| Ear ring (heavy hit only) | a quiet high tone at about 4 to 6 kHz, volume -30 dB, 0.8 to 1.5 s fade | [Suggested] (tinnitus values not researched) |
| Heartbeat at low health | slow thump at 60 to 80 BPM, only below the low-health threshold | [Suggested] |
| Music duck on hit | music -4 to -6 dB for 0.3 s, then back | [Suggested] |
| Impact thud | short low layer under the hit sound, 60 to 120 ms | [Suggested] |

Owner rule: sounds must be from real CC0 recordings, with no synth beeps or whooshes (project memory). Muffle and ring can be made by filtering real recordings.

## Rumble (controller vibration)

### Takeaway
Godot's rumble call is simple and fully documented. The per-hit patterns below are suggestions.

### Cited Findings
- `Input.start_joy_vibration(device, weak_magnitude, strong_magnitude, duration)`: magnitudes 0.0 to 1.0; duration 0 means "as long as possible" (about 65 s per the docs); `stop_joy_vibration(device)` stops early. Source: [Godot docs, Input](https://docs.godotengine.org/en/stable/classes/class_input.html).

### Toolbox (rumble)
| Hit size | weak | strong | duration | Source |
|---|---|---|---|---|
| Light hit taken | 0.15 | 0.0 | 0.08 s | [Suggested] |
| Heavy hit taken | 0.3 | 0.6 | 0.18 s | [Suggested] |
| Low-health heartbeat | 0.0 | 0.12 | 0.1 s per beat | [Suggested] |

Give rumble its own on/off and strength setting. Use `device` from `Input.get_connected_joypads()`; with 4-player co-op, send rumble only to the player who was hit.

## Screen-space effects (corner or bottom tint, desaturation, aberration, blur)

### Takeaway
The owner said the full-screen edge was "too much" and a plain red flash "too plain". Corner-only tints and short desaturation are the middle ground. Chromatic aberration and radial blur are more sci-fi and motion-heavy; Xbox guidance flags blur as a motion-sickness trigger.

### Cited Findings
- Radial blur and full-screen effects appear on XAG 117's list of settings to make adjustable: [Microsoft XAG 117](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/117).
- Photosensitivity: WCAG 2.3.1 says content passes at three or fewer flashes per second, or below the general and red flash thresholds. The red-flash test exists because people are more sensitive to red flashing; the brightness limits given are 20 cd/m² (general) and 6 cd/m² (red): [W3C Understanding 2.3.1](https://www.w3.org/WAI/WCAG22/Understanding/three-flashes-or-below-threshold.html), [digital.gov.bc.ca](https://digital.gov.bc.ca/design/wcag/physical-reactions).
- MDN, quoting the Epilepsy Foundation: flashing around 5 to 30 Hz is the most likely to trigger seizures: [MDN, seizure disorders](https://developer.mozilla.org/en-US/docs/Web/Accessibility/Guides/Seizure_disorders).

### Toolbox (screen-space)
| Option | Value | Source |
|---|---|---|
| Bottom-edge tint | red at alpha 0.15 to 0.25, bottom 15 percent of screen, 0.3 s fade out | [Suggested] |
| Corner-only tint | alpha 0.2, only the corner nearest the hit direction | [Suggested] |
| Desaturation pulse | saturation to 0.6, 0.15 s up, 0.4 s back | [Suggested] |
| Vignette | keep under 10 to 15 percent of screen, alpha 0.2 max | [Suggested] |
| Chromatic aberration | 1 to 2 px shift, 0.1 s; avoid as default (sci-fi look) | [Suggested] |
| Radial blur | do not use for hurt; it is a motion-sickness trigger | [Sourced as a risk: XAG 117] |

Photosensitivity rule for this project: never flash the whole screen red, and keep any repeated flash below about 3 per second. A single flash per hit is fine. In big fights with many hits, skip the flash and use the HUD or audio signal.

Implementation in Godot 4: a `ColorRect` on a `CanvasLayer` with a `canvas_item` shader (`shader_type canvas_item;` with a `uniform vec4` colour and a `uniform float strength`), driven by a `Tween` on `strength`. This is a common pattern; no source was fetched for the exact code.

## Low-health states that stay subtle

### Takeaway
Keep low-health cues on the HUD and audio, not on the whole picture, so the player can still see the cave when they are hurt. Specific threshold numbers were NOT sourced.

### Toolbox (low health)
| Option | Value | Source |
|---|---|---|
| Threshold | 25 to 30 percent of max health | [Suggested] (brief's range; not sourced) |
| HUD-only pulse | bar pulses 1 Hz, colour shift only | [Suggested] |
| Heartbeat audio | as above | [Suggested] |
| Slight desaturation | saturation 0.8 at threshold, not lower | [Suggested] |
| Death-spiral guard | keep the enemy and lantern light readable; never let effects cover more than 15 percent of screen | [Suggested] |

## Gaps (not found in this research)
- Dark Souls or Elden Ring ghost-bar timings: not found. Search returned only general pages.
- Hades hit-flash and i-frame frame counts: not found.
- Minecraft red-hurt tint values: not searched.
- Chromatic aberration, heartbeat thresholds, tinnitus and music-ducking durations: not searched; values above are suggestions.
- The Vlambeer "Art of Screenshake" talk and Jonasson/Purho "Juice it or lose it" talk: the search found only summaries. The "0.1 to 0.3 s camera shake" and "3-frame freeze" claims came from search summaries without a checked primary page. Treat them as weak.
- Jan Willem Nijman / Vlambeer slides: not reached (the gamejuice.pages.dev page is a waitlist placeholder with no numbers).
- Swink, "Game Feel" (2008): the book exists and defines game feel, but no numbers were retrieved from it.
- Medium "Practical juicing for game devs" (dvdfu): blocked with HTTP 403; not read.

## Prototype order suggested for the team (3 to 5 options)
1. Ghost bar on the HUD (safest, no screen change). Real-time timer.
2. Small trauma camera kick, with a player slider, off by default for reduced motion.
3. Muffle on the bus plus a short ring on heavy hits only.
4. Rumble per hit size, per-player.
5. Bottom-edge tint, 0.2 alpha, one flash per hit, no stacking.

Test each one against the owner's "too much" and "too plain" feedback, one at a time.
