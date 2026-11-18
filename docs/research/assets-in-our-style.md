# Ready-made 3D packs in (or near) our style

Research only, Nov 19 2026. Nothing was downloaded or installed.

## Our style, in one breath

Our workbenches look like a hand-painted fantasy game: chunky wood and stone, painted shading and worn
bright edges, copper bands with rivets, nothing perfectly square or round (see
`assets/concepts/night-2026-11-15/station_gem_bench.jpg`).

**The honest finding:** almost every *free* pack is "flat-colour low-poly" (one colour per part, like
toy blocks). That is the KayKit, Quaternius and Kenney look. It is a **2 out of 5** match for us.
True hand-painted packs exist, but they are small, paid, or have looser licences.
So the best use of free packs is **shapes, sizes, rigs and animations**. We paint them ourselves.

## Two big catches before anything else

1. **Our GitHub repo is public.** Putting a file in it is the same as giving it away to everyone.
   - **CC0** (= "public domain, do anything") files are fine in the repo.
   - Paid packs, Fab, Unity Store, Synty and Mixamo files say "use in your game, but don't hand out the raw files".
     Those must **never** be committed. They could live in a folder git ignores, or be used only
     as a reference that we rebuild from.
2. **Model Rule 1** says every model is hand-built in Blender by a script, and a test checks each `.glb`
   has its build script. An imported pack model would fail that test. "Import and adapt" therefore means:
   a build script that loads the pack shape, reshapes it, paints it with our kit textures, and exports.
   **The owner should say yes to that first**, because it bends Rule 1. (We already do something similar
   for the dwarf body and clothes from Quaternius.)

## Ranked list

"Style" = how close to our look, 1 (not at all) to 5 (same). "Use" = (a) import-and-adapt, (b) reference only.
All CC0 packs: commercial use OK, no credit needed, any engine incl. Godot.

| # | Pack | Price | Licence | Format | Style | Use | What we'd use it for |
|---|---|---|---|---|---|---|---|
| 1 | [Quaternius Ultimate Monsters](https://quaternius.com/packs/ultimatemonsters.html) (50 animated monsters) | Free | CC0 | glTF, FBX, blend | 2 | a | Ready rigs + walk/attack/death animations to put under our own creature shapes. Biggest time-saver. |
| 2 | [Quaternius Fantasy Props MegaKit](https://quaternius.itch.io/fantasy-props-megakit) | Free (94 models); Pro $9.99; Source $14.99 (has .blend) | CC0 | glTF, FBX, OBJ | 3 | a | Barrels, crates, chests, shelves, tables, candles. Good starting shapes for decor. |
| 3 | [KayKit Dungeon Remastered](https://kaylousberg.itch.io/kaykit-dungeon-remastered) (200+ pieces) | Free (pay what you want) | CC0 (asks: don't resell unchanged) | glTF, FBX, OBJ | 2 | a | Chests, barrels, torches, stairs, wall sizes. Also on the [Godot Asset Library](https://godotengine.org/asset-library/asset/2126). |
| 4 | [loafbrr Mines and Cave Set](https://loafbrr.itch.io/mines-and-cave-set) (178 pieces) | Free | CC0 | GLB, FBX, blend, Godot version | ? (page doesn't show; check pictures) | a | Mine supports, tunnels, rails. The only free *mining* kit found. |
| 5 | [Quaternius Stylized Nature MegaKit](https://quaternius.com/packs/stylizednaturemegakit.html) | Free part (60-70%); rest via Patreon | CC0 | glTF, FBX, OBJ | 3 | a | 27 rocks, plants. Rock shapes for cave floors. |
| 6 | [KayKit Character Animations](https://kaylousberg.itch.io/kaykit-character-animations) | Free | CC0 | glTF, FBX | n/a | a | Extra human moves (mining, tool use) for the dwarf, next to the Quaternius library we already use. |
| 7 | [KayKit Skeletons](https://kaylousberg.itch.io/kaykit-skeletons) | Free | CC0 | glTF, FBX | 2 | a | Rigged undead with 90+ animations, base for a skeleton enemy. |
| 8 | [Quaternius LowPoly Animated Monsters](https://quaternius.itch.io/lowpoly-animated-monsters) | Free | CC0 | FBX, OBJ, blend | 2 | a | More creature rigs and attack/jump animations. |
| 9 | [Red's Dungeon Interior pack](https://redvampire.itch.io/dungeon-interior-asset-pack) (60 meshes) | $2.55+ | Royalty-free **with credit**; no AI training, no blockchain | blend, FBX, GLB | 4 | a/b | Truly hand-painted trimsheet. Doors, grates, torches, debris. Credit line needed. Keep out of the public repo. |
| 10 | [WizP Handpainted Dungeon Kit](https://wizp.itch.io/handpainted-dungeon-kit) | $4.99+ | Author's words: "any purpose, commercial or not", no resale. **No formal licence file: flag** | FBX, GLB | 4 | b | Closest painted look found (dark, "Battle Chasers" feel). Best as a painting reference. |
| 11 | [Tidal Flask FANTASTIC Dungeon Pack](https://www.fab.com/) (search the name on Fab) | From ~$89.99 now (was free until Apr 21 2026) | Fab Standard Licence: any engine, commercial OK, no handing out raw files | FBX, blend, Unity, Unreal | 4 | b | 1,000 stylized dungeon pieces. Check if the owner's Fab account claimed it in April. |
| 12 | [Sketchfab "Dungeon modular set"](https://sketchfab.com/3d-models/dungeon-modular-set-23fa0fb122d74a9c82e6343675457fbd) | Free | CC-BY (credit needed) | glTF via Sketchfab | 3-4 | b | Small hand-painted practice set; some textures missing. |
| 13 | Sketchfab search: "hand painted" + filter Downloadable + licence CC0 or CC-BY | Free | Check each model | glTF | varies | a/b | Many single hand-painted props (rocks, chests, mushrooms). Model by model, not packs. |
| 14 | [OpenGameArt Lowpoly Crystals Pack](https://opengameart.org/content/lowpoly-crystals-pack) (28 crystals) | Free | CC0 (one comment questions extra author rules: flag) | FBX, OBJ, blend | 2 | a | Crystal cluster shapes. |
| 15 | [OpenGameArt Low Poly Mushroom Kit](https://opengameart.org/content/low-poly-mushroom-kit) | Free | CC0 | check page | 2 | a | Mushroom shapes for glowcaps. |
| 16 | [OpenGameArt Stylized Low Poly Tools](https://opengameart.org/content/stylized-low-poly-tools) | Free | CC0 | check page | 2 | a | Pickaxe, hammer, shovel shapes. |
| 17 | [OpenGameArt 3D Low Poly Chests](https://opengameart.org/content/3d-low-poly-chests) | Free | CC0 | check page | 2-3 | a | Chest with a lid that opens (useful for F345, chest lid opening). |
| 18 | Kenney [Survival Kit](https://kenney.nl/assets/survival-kit) / Mini Dungeon / Fantasy Town | Free | CC0 | glTF, FBX, OBJ | 1 | b | Size and layout reference only. (Not re-checked this session; Kenney is always CC0.) |
| 19 | [KayKit Adventurers](https://godotengine.org/asset-library/asset/2129) | Free | CC0 | glTF, FBX | 2 | b | Weapon and shield shapes; characters too cute for us. |
| 20 | [asgart-3d Mining Props](https://asgart-3d.itch.io/miningprops) | €20+ | Says "suitable for commercial projects", has LICENSE.txt (read before buying) | not stated: flag | 3 | b | Pickaxe, lantern, bucket, crystals, ingots. |
| 21 | Synty POLYGON Dungeon / Fantasy (often in [Humble bundles](https://gamefromscratch.com/synty-fantasy-game-dev-asset-humble-bundle/), ~$30) | Paid | Synty EULA: works in Godot "technically", no official support, no sharing raw files | FBX | 2 | b | Huge amounts, but flat-colour atlas, not hand-painted. |
| 22 | Unity Asset Store hand-painted packs | Paid / some free | Unity EULA allows other engines ([Unity support](https://support.unity.com/hc/en-us/articles/34387186019988-Can-I-use-assets-from-the-Asset-Store-with-other-engines)), **except** Unity-made assets under the "Unity Companion Licence" | FBX, Unity | up to 5 | b | The best hand-painted art lives here. Private use only (not in public repo). |
| 23 | Mixamo (Adobe) animations | Free (Adobe login) | Royalty-free for games, no credit; no sharing raw files | FBX | n/a | a (private) | Many human moves. Raw files can't go in the public repo: grey area, ask first. |
| 24 | [OpenGameArt Handpainted Rock Textures](https://opengameart.org/content/handpainted-rock-textures) | Free | CC0 | PNG 1k/2k | 3-4 | b | Painting reference for our ChatGPT texture sheets (Rule 6 wants our own sheets). |
| 25 | [Lynocs Stylized Texture Pack](https://lynocs.itch.io/texture-pack) | Free | CC0 | PNG | 3 | b | Stone and wood painting reference. |
| 26 | [Screaming Brain Tiny Texture Pack 2](https://opengameart.org/node/134959) | Free | CC0 | PNG 128-512 px | 2 | b | Too small for us; reference only. |

### Left out on purpose
- [gojuro Free Stylized Fantasy Props](https://gojuro.itch.io/free-fantasy-props): "personal projects only". Not for a sold game.
- [lukky-nl Handpainted fantasy props](https://lukky-nl.itch.io/handpainted-fantasy-props-pack): nice look, but **no licence written anywhere**. Only usable if the author answers in writing.
- [Emilulz Low Poly Mines](https://emilulz.itch.io/low-poly-mines): licence not shown on the page.
- Fab items marked "Reference Only" or "Quixel Legacy", and Epic sample content (Unreal only).
- Any paid dwarf model found (CGTrader etc.): PBR or Warcraft-copy looks, and our dwarf is already built.
- Note: no truly free, hand-painted, commercial-OK **dwarf** or **cave creature** was found.

## Best picks, short version
- **Import-and-adapt (a):** #1 Ultimate Monsters (rigs + animations), #2 Fantasy Props MegaKit,
  #3 KayKit Dungeon, #4 Mines and Cave Set, #6 KayKit animations. All CC0, so no repo problem.
- **Reference only (b):** #10 WizP, #9 Red, #11 Tidal Flask for how hand-painting should look;
  textures #24-25 to steer our ChatGPT texture sheets.

## How we'd bring one in safely

1. **Owner picks** one pack and says yes to "import a shape, then rebuild it in our style" (Rule 1).
2. **Licence check, written down.** Open the pack page, save the exact licence words. Green light only for:
   CC0, or a licence that clearly says commercial games OK. Anything unclear: ask the author, or skip.
3. **Safe download.** Into its own empty folder outside the project. No install scripts, no running
   anything that comes with it. Look inside first (Max's global rule for downloads).
4. **Public repo rule.** CC0: may go in the repo. Paid / Fab / Unity / Synty / Mixamo / CC-BY-with-limits:
   keep the raw files out of git (ignored folder), and only our changed result goes in, after the owner OKs it.
5. **Log it in `CREDITS.md`** the same day: what, link, licence, date, and which of our files use it.
   If credit is required (CC-BY, Red's pack), add the credit line for the game's credits screen.
6. **Adapt to our model rules** with a build script in `tools/asset_forge/builds/`:
   - break perfect boxes/circles, add chunky bevels and wobble (art style rule);
   - repaint with our kit textures: several paintings per surface, worn bright edges, dark gaps (Rule 6);
   - fix any doubled surfaces (Rule 2), layers for building pieces (Rule 3), round doors (Rule 5);
   - for creatures: keep the pack's bones and animations, swap in our own body parts.
7. **Run the checks** (model rules tests, side-by-side picture next to our concept art). Not done until they pass.

Sources not linked above: [Fab licence discussion](https://forums.unrealengine.com/t/can-i-use-assets-from-fab-for-godot-engine/2451166),
[Synty FAQ](https://syntystore.com/community/faq), [Mixamo FAQ thread](https://community.adobe.com/t5/mixamo-discussions/mixamo-faq-licensing-royalties-ownership-eula-and-tos/td-p/13234775),
[Fantastic Dungeon Pack news](https://www.cgchannel.com/2026/04/get-650-free-3d-assets-for-building-dungeons-in-blender-unity-and-unreal-engine/).
