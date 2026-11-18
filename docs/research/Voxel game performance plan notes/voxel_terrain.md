# Voxel terrain performance in Godot (Voxel Tools / godot_voxel) and lessons from destructible-world games

Scope: Godot 4.7 + Voxel Tools GDExtension, VoxelTerrain + VoxelMesherTransvoxel (TEXTURES_SINGLE_S4), GDScript SDF generator (~40 us per SDF query), terrain collisions, up to 4 co-op players, ~80 s world load.
Version note: the Voxel Tools changelog lists 1.4 (03/03/2025, built against Godot 4.4), 1.5 (16/09/2025), 1.6 (04/02/2026) and 1.7 (20/08/2026, latest tag), with 1.7.1 in development. The changelog does not say which Godot version each release targets. — [Changelog](https://voxel-tools.readthedocs.io/en/latest/changelog/)

## 1. VoxelTerrain vs VoxelLodTerrain, view distance, block sizes, threads, generator choice, streams

### Takeaway
For an underground co-op game with 4 players, VoxelTerrain is still the right node. It is the only one with built-in multiplayer support, and it caches generated blocks in memory. VoxelLodTerrain only pays off for very long view distances. By far the biggest load-time cost is the GDScript generator. The fixes, in order: return early on empty or solid blocks, cut down the work per voxel, move the SDF into VoxelGeneratorGraph (about C++ speed) or into native code, and save the generator's output so a block is generated only once.

### Cited Findings
**Node choice / LOD**
- VoxelLodTerrain: each LOD level doubles the block and voxel size, and Transvoxel stitches the levels together without cracks, which is what makes huge landscapes possible. The "Octree" streaming system supports only one viewer. "Clipbox" supports multiple viewers. — [Smooth terrain docs](https://voxel-tools.readthedocs.io/en/latest/smooth_terrain/)
- VoxelLodTerrain bounds with block size 16: 4 LODs gives 256, 5 LODs gives 512, 6 LODs gives 1024. With block size 32, one fewer LOD covers the same bounds. `full_load_mode` keeps every edited chunk in memory, so memory grows with the number of edits. — [Smooth terrain docs](https://voxel-tools.readthedocs.io/en/latest/smooth_terrain/)
- Detail normalmaps (fake detail on distant LOD meshes) exist only on VoxelLodTerrain. They make mesh generation slower and use more memory. Suggested start: LOD 2, tile size 4 to 16. — [Smooth terrain docs](https://voxel-tools.readthedocs.io/en/latest/smooth_terrain/)
- Multiplayer synchronizer: "VoxelLodTerrain is not supported" (support is planned). — [Multiplayer docs](https://voxel-tools.readthedocs.io/en/latest/multiplayer/)
- Caching: "VoxelTerrain caches blocks in memory until they are far from any viewer"; "VoxelLodTerrain does not cache by default, and there is no option to change that yet." — [Generators docs](https://voxel-tools.readthedocs.io/en/latest/generators/)
- LOD terrain: a shorter LOD distance means fewer blocks and smaller destroy spikes when the player moves fast, at the cost of quality. VoxelLodTerrain 1.7 lets you set each LOD distance by hand. — [Performance docs](https://voxel-tools.readthedocs.io/en/latest/performance/); [Changelog](https://voxel-tools.readthedocs.io/en/latest/changelog/)

**View distance and block sizes**
- VoxelTerrain defaults: `max_view_distance` = 128, `mesh_block_size` = 16 ("Only 16 or 32 are supported", and it also sets the VoxelInstancer chunk size). `bounds` limits where voxels exist. If any dimension is over 512 and `max_view_distance` is over 512, the distance is clamped to 512. — [VoxelTerrain API](https://voxel-tools.readthedocs.io/en/latest/api/VoxelTerrain/)
- VoxelViewer defaults: `view_distance` = 128, `requires_visuals` = true, `requires_collisions` = true. `view_distance_vertical_ratio` works only on VoxelLodTerrain with Clipbox. — [VoxelViewer API](https://voxel-tools.readthedocs.io/en/latest/api/VoxelViewer/)
- Lower the view distance to reduce the number of meshes. Raising the mesh block size from 16 to 32 cuts draw calls but makes voxel edits slower. On Godot 4 with Vulkan, size 32 is suggested for fast movement near dense terrain. Limit player speed near voxels, because fast movement creates and destroys many meshes at once. — [Performance docs](https://voxel-tools.readthedocs.io/en/latest/performance/)

**Threads**
- Project settings: `voxel/threads/count/minimum`, `voxel/threads/count/margin_below_maximum` (0 = all threads, 1 = one fewer), `voxel/threads/count/ratio_over_maximum` (0 to 1). The docs advise against giving every thread to voxels. A restart is needed after a change. Check the result with `VoxelEngine.get_stats()` or `-v`. `voxel/threads/main/time_budget_ms` caps the main-thread work per frame (default about 8 ms). — [Performance docs](https://voxel-tools.readthedocs.io/en/latest/performance/)
- 1.5 added a VoxelEngine function to change the thread count at runtime. — [Changelog](https://voxel-tools.readthedocs.io/en/latest/changelog/)
- "Editor tests with multithreaded GDScript are much slower than exported builds, so use fewer threads when testing in the editor." — [Performance docs](https://voxel-tools.readthedocs.io/en/latest/performance/)

**Generator choice**
- C++ generators are "very fast" but tedious to write. Graph generators have "similar speed to C++ generators" but support only basic operations, and they run per voxel, so they suit base ground and caves but not structures. FastNoise2 is recommended. 3D noise costs more than 2D. — [Generators docs](https://voxel-tools.readthedocs.io/en/latest/generators/)
- VoxelGeneratorGraph tricks: `sdf_clip_threshold` (range analysis skips blocks far from the surface), subdivision 16³ (8³ is more precise but has more overhead), and execution-map plus XZ caching on by default. Note: in 1.7.1-dev, `use_xz_caching` "now skips operations correctly, where previously it never skipped any". — [Performance docs](https://voxel-tools.readthedocs.io/en/latest/performance/); [Changelog](https://voxel-tools.readthedocs.io/en/latest/changelog/)
- GPU generation (`use_gpu_generation`, Vulkan only) works only for VoxelGeneratorGraph. Edited voxels fall back to the CPU. 1.7 added compute shader caching. Shader compilation can delay the first blocks, and `get_stats` reports GPU tasks so a loading screen can show them. — [Smooth terrain docs](https://voxel-tools.readthedocs.io/en/latest/smooth_terrain/); [Changelog](https://voxel-tools.readthedocs.io/en/latest/changelog/)
- GDScript generators: avoid heavy 3D loops in GDScript and use VoxelTool/VoxelBuffer bulk methods or graphs instead. Loop in Z, X, Y order. — [Performance docs](https://voxel-tools.readthedocs.io/en/latest/performance/). Scripting docs: move invariant maths out of the inner loop, return early on uniform blocks with `fill_f(100.0)` (air) or `fill_f(-100.0)` (solid), use bit shifts instead of `pow()`, and keep generators thread-safe and deterministic. — [Scripting docs](https://voxel-tools.readthedocs.io/en/latest/scripting/)
- Multipass generators cost more than single-pass ones, and their column cache can use more memory than the visible chunks. — [Generators docs](https://voxel-tools.readthedocs.io/en/latest/generators/)

**Streams / saving**
- VoxelStreamSQLite is the most complete stream: one file, and it stores both voxels and instancer data. VoxelStreamRegionFiles is older, works like Minecraft's region files, and stores voxels only. VoxelStreamScript is a custom stream written in script. — [Streams docs](https://voxel-tools.readthedocs.io/en/latest/streams/)
- By default only modified blocks are saved. If the generator is expensive, the stream can be set to save every new block ("Minecraft works this way"). `VoxelStream.save_generator_output` stores generator output, and those blocks then behave like edits. Saving happens when a block unloads or on `save_modified_blocks()`, and it runs on background threads. Pressing Godot's Stop button kills the process and can corrupt saves. — [Streams docs](https://voxel-tools.readthedocs.io/en/latest/streams/); [Generators docs](https://voxel-tools.readthedocs.io/en/latest/generators/)
- 1.6 added ZSTD as a save compression option next to LZ4. 1.7 fixed SQLite hangs when stream functions run on the main thread while worker tasks are still using the database. — [Changelog](https://voxel-tools.readthedocs.io/en/latest/changelog/)

### Inferences
- Load-time maths for this project: one 16³ block has 4,096 voxels. At about 40 us per SDF query, a block takes about 164 ms of one thread with no early-out. A 128-voxel view distance covers roughly (256/16)³ ≈ 4,096 blocks, which is about 670 CPU-seconds, or about 85 s on 8 threads. That matches the observed ~80 s load, so the GDScript per-voxel SDF is almost certainly the bottleneck. Quick wins, in order:
  1. Early-out for whole blocks. Check the block's bounding box against the cave SDF (or test the 8 corners plus the centre with a safety margin) and `fill_f` uniform blocks. In mostly-solid rock this can skip most blocks.
  2. Evaluate the SDF on a coarse grid (for example every 4 voxels) and interpolate.
  3. Lower the vertical view distance underground (VoxelTerrain has no vertical ratio, so use `bounds` or a smaller `view_distance`).
  4. Save generator output to SQLite so the second load is a disk read, not a regeneration.
  5. Long term, port the SDF to VoxelGeneratorGraph or to a small native generator.
- Keep VoxelTerrain. Caves rarely need far views, the built-in synchronizer works only with VoxelTerrain, and VoxelTerrain caches generated blocks, which VoxelLodTerrain does not.
- With TEXTURES_SINGLE_S4, the "Single" mode in 1.5+ uses one byte per voxel for texture indices, which keeps memory low. — [Changelog](https://voxel-tools.readthedocs.io/en/latest/changelog/)

### Gaps
- Whether a custom C++ generator can be built against the GDExtension edition (rather than the module build) is not confirmed in the docs I read.
- No official benchmark comparing GDScript and graph generator speed. The data-block size for VoxelTerrain is not documented on the API page.

## 2. Collision

### Takeaway
Terrain collision uses one concave trimesh per block. Building those shapes costs 3 to 5 times as much as meshing, and the cost is shape creation, not the physics step. So request collisions only where they are needed, and budget the main-thread time when shapes enter the tree (especially with Jolt).

### Cited Findings
- "Standard physics uses mesh colliders per block. Creating them is about 3 to 5 times more expensive than meshing, and loading slows significantly with collisions enabled." The alternative is Box Physics (`VoxelBoxMover` plus voxel raycasts), which is faster but only works for blocky terrain. — [Performance docs](https://voxel-tools.readthedocs.io/en/latest/performance/)
- The voxel docs say Godot Jolt makes shape creation cost worse, because Jolt defers shape setup until the collider enters the scene tree, so the cost lands on the main thread. — via search summary of [Performance docs](https://voxel-tools.readthedocs.io/en/latest/performance/) (this wording came from a search snippet, not a direct fetch)
- Godot Jolt issue: changing a body's shapes after it is in the physics space forces a full compound-shape rebuild. That took up to 8 ms for 64 shapes, and Godot Physics was similar. — [godot-jolt issue #660](https://www.Github.com/godot-jolt/godot-jolt/issues/660)
- `generate_collisions` (default true) works only if a VoxelViewer also has `requires_collisions`. `collision_margin` default 0.04. Since 1.4, "collision-only viewers no longer create visual meshes". 1.4.1 fixed needless terrain interpolation when physics interpolation is on. — [VoxelTerrain API](https://voxel-tools.readthedocs.io/en/latest/api/VoxelTerrain/); [Changelog](https://voxel-tools.readthedocs.io/en/latest/changelog/)
- Anti-tunnelling advice: limit speed, use raycasts for fast projectiles, use CCD (continuous collision detection), and check voxel data to lift objects that ended up underground. — [Performance docs](https://voxel-tools.readthedocs.io/en/latest/performance/)
- Collision LOD is not mentioned on the VoxelTerrain API page. — [VoxelTerrain API](https://voxel-tools.readthedocs.io/en/latest/api/VoxelTerrain/)
- Space Engineers' "Selective Physics Updates" simulates only the areas around players on dedicated servers. — [Marek Rosa blog 2020](https://blog.marekrosa.org/2020/08/space-engineers-server-optimizations/)

### Inferences
- Use a second VoxelViewer per player with a small `view_distance` (for example 32 to 48) and `requires_collisions = true`. Set the main visual viewer to `requires_collisions = false`. Then colliders exist only near players, while meshes stream farther out. This relies on the 1.4 fix where collision-only viewers do not create meshes.
- Monsters far from every player should not need terrain collision. Freeze them or move them along navigation data instead.

### Gaps
- I found no dedicated godot_voxel benchmark or issue for VoxelTerrain with Jolt in Godot 4.4+ (Jolt is now built into Godot). Profiling in this project is needed.

## 3. Edits / digging

### Takeaway
Use VoxelTool's bulk operations (`do_sphere`, `do_box`, `paste`), not `set_voxel` loops. Group the edits from one action into one call, because each edit remeshes the touched blocks (and rebuilds their colliders) and runs instancer ground checks.

### Cited Findings
- `set_voxel`/`get_voxel` on terrains are the slowest option. For bulk work use `do_sphere()`, `do_box()`, `raycast` and `paste()`, or `copy()` a region into a VoxelBuffer, edit it without locks, and `paste()` it back. For heavy edits, copy-on-write or a "try lock" avoids stutter. — [Performance docs](https://voxel-tools.readthedocs.io/en/latest/performance/)
- A mesh block size of 32 makes voxel edits slower than 16. — [Performance docs](https://voxel-tools.readthedocs.io/en/latest/performance/)
- Each voxel edit triggers a check for instances losing ground contact, so batching edits reduces this cost. — [Performance docs](https://voxel-tools.readthedocs.io/en/latest/performance/)
- `area_edit_notification_enabled` / `_on_area_edited` exist on VoxelTerrain (useful for invalidating game caches). — [VoxelTerrain API](https://voxel-tools.readthedocs.io/en/latest/api/VoxelTerrain/)

### Inferences
- Keep mesh_block_size = 16 for a digging game: edits stay cheap, and collider rebuilds per dig touch less geometry. Only switch to 32 if draw calls show up as the bottleneck in the profiler.
- A dig on a block border touches up to 8 blocks. Snapping dig shapes so they do not straddle borders without need, or merging several hits per frame into one `do_sphere`, cuts down remesh work.

### Gaps
- No published millisecond numbers for the remesh plus collider cost of a single edit.

## 4. Instancer, detail rendering, texturing shader cost

### Takeaway
VoxelInstancer (MultiMesh items) is the built-in way to put rocks and plants on terrain. It streams with the terrain, deletes instances when their ground is dug, and saves through SQLite. Its smart snapping needs VoxelGeneratorGraph. A hand-made MultiMesh gives full control over keep-out rules. Triplanar texture arrays cost about 3 samples per texture layer per map.

### Cited Findings
- MultiMesh items can be "very numerous", and collision can be set up through a scene. Scene instances are "much slower" and should be kept to low counts. Mesh LOD supports up to 4 meshes. A known performance issue occurs when `MultiMesh.mesh` switches between LODs. — [Instancing docs](https://voxel-tools.readthedocs.io/en/latest/instancing/)
- Persistence needs VoxelStreamSQLite. Instances can be removed when the ground they sit on is dug. `snap_to_generator_sdf_enabled` needs a generator with arbitrary-position queries (only VoxelGeneratorGraph at the time). Snapping ignores edits. — [Instancing docs](https://voxel-tools.readthedocs.io/en/latest/instancing/)
- 1.5 added instancer fading, `remove_instances_in_sphere`, and a `collision_distance` for multimesh items, so colliders are built only near chunks. 1.4 added the `OnePerTriangle` emission mode. — [Changelog](https://voxel-tools.readthedocs.io/en/latest/changelog/)
- Transvoxel texturing: Single mode = one 8-bit index per voxel, up to 256 textures, no gradients. S4 vertex grouping puts 4 indices and weights per vertex in CUSTOM1, and more than 4 textures per vertex can cause artifacts. The example triplanar function takes 3 texture samples per call (so 4 blended layers is about 12 albedo samples, more with normal and AO maps). Texture2DArray is recommended. — [Smooth terrain docs](https://voxel-tools.readthedocs.io/en/latest/smooth_terrain/)
- SDF precision: 16-bit default (range ±500, step ≈ 0.015). 8-bit gives a range of ±10 and can look blocky. Clamping lets uniform regions be optimized out to save memory. — [Smooth terrain docs](https://voxel-tools.readthedocs.io/en/latest/smooth_terrain/)

### Inferences
- The project's placement rule (nothing grown may stand inside built things) is easier to enforce with a custom MultiMesh, or with VoxelInstancer plus a filter step, because VoxelInstancer's built-in generator does not know about ruins or paths.
- Shader cost: on mid GPUs, cut triplanar to 2 projections where the normal is clearly vertical, or sample normal and AO maps only for the strongest weight, to save samples. This is standard practice, not taken from a source.

### Gaps
- No official numbers for VoxelInstancer compared with a hand-made MultiMesh.

## 5. Networking a voxel world with godot_voxel

### Takeaway
The built-in VoxelTerrainMultiplayerSynchronizer (server-authoritative, VoxelTerrain only, "very experimental") pushes blocks and edited areas over Godot RPCs. For a 4-player game where everyone has the same seed, a custom approach (send seed plus edit operations, not voxel blocks) is lighter and fits the existing "request → host approves → everyone updates" pattern.

### Cited Findings
- Server: VoxelTerrain + VoxelTerrainMultiplayerSynchronizer. One VoxelViewer per joining player with `network_peer_id` set and `requires_data_block_notifications` on. `require_visuals` can be turned off for remote players. Client: the same synchronizer node name, a local VoxelViewer with a slightly larger view distance, and no viewers on remote players. Setup must happen before terrain processing starts. — [Multiplayer docs](https://voxel-tools.readthedocs.io/en/latest/multiplayer/)
- Ideas listed as not yet built: client block caching and versioning, client-requested blocks, and seed-based diffs (send only differences when under 30% of a block changed). Large volumes over reliable UDP may be slow. — [Multiplayer docs](https://voxel-tools.readthedocs.io/en/latest/multiplayer/)
- `automatic_loading_enabled = false` stops local loading for client-side terrain. `get_viewer_network_peer_ids_in_area()` returns the peers whose viewers cover an area (useful for sending edits only to peers that have that area loaded). — [VoxelTerrain API](https://voxel-tools.readthedocs.io/en/latest/api/VoxelTerrain/)
- Valheim lesson: early terrain edits were stored as separate network instances per change. A 2021 patch reworked the system "to reduce the number of network instances and make loading faster" (older edits are converted with `optterrain`). — [Valheim patch coverage](https://www.essentiallysports.com/esports-news-valheim-iron-gate-studio-rolls-new-patch-to-rework-terrain-upgrade-hoe-and-more); third-party claim of stutter at 8,000 to 10,000 instances: [hostedgg](https://hostedgg.com/wiki/valheim/performance) (unofficial)

### Inferences
- Deterministic seed plus a replayed or merged edit log means a joining client generates the world locally and only downloads edited blocks (from the host's SQLite) or the edit list. Edits should be merged per block (as in Valheim's fix), not kept as an ever-growing list.
- The generator must stay deterministic. The docs warn that it may be called again for the same chunk. — [Generators docs](https://voxel-tools.readthedocs.io/en/latest/generators/)

### Gaps
- No public bandwidth numbers for the synchronizer. The changelog for 1.4 to 1.7 says nothing about multiplayer.

## 6. How other destructible-world games stay fast

### Takeaway
Common patterns: fixed-size chunks or sections, meshing off the main thread with a per-frame upload budget, visibility culling through cave connectivity, simulation only near players, saving edits as merged chunk data, and cheap stand-ins (impostors or LOD) for distant terrain. Teardown is the outlier, ray tracing voxels instead of meshing them.

### Cited Findings
- **Minecraft (Advanced Cave Culling, MCPE 0.9, Tommaso Checchi):** hardware occlusion queries stalled the GPU, and checking for fully opaque chunk walls culled almost nothing (about 1 in 100 chunks had six opaque sides). The new method stores 15 bits per 16³ section, one for each pair of faces that a flood fill through non-opaque blocks can connect. Rebuilding it takes 0.1 to 0.2 ms after a block change and runs in the background. It culls 50 to 99% of geometry, let caves run on all phones, and was backported to PC. — [Tomcc blog](https://tomcc.github.io/2014/08/31/visibility-1.html)
- **Sodium (Minecraft mod):** 0.5.0 made chunk meshing 40 to 60% faster. It uses multithreaded chunk preparation, a persistently mapped staging buffer for uploads, and multi-draw chunk rendering. 0.7.0 made meshing task scheduling independent of frame rate (with task effort estimation) and added a per-region terrain cache when the camera is still. — [Sodium releases](https://github.com/jellysquid3/sodium-fabric/releases); [Modrinth changelog](https://modrinth.com/mod/sodium/changelog) (via search summary)
- **7 Days to Die:** Alpha 20 added a "Dynamic Imposter System" for distant changed POI chunks, plus a configurable land-claim chunk size (higher values use more RAM). — [A20 release notes](https://7d2d.net/7d2dgamepedia/GameFeatures_Alpha20ReleaseNotes). A community modder moved chunk mesh uploads from same-frame blocking to next-frame deferred. — [TFP forum](https://community.thefunpimps.com/posts/633072). The claim that structural integrity limits collapse size comes from a player and is unverified. — [devtrackers](https://devtrackers.gg/7-days-to-die?page=64)
- **Deep Rock Galactic:** the developers confirm the caves are 100% destructible and procedural, built on Unreal with full source access, and that the procedural world was the hardest technical problem. No public technical breakdown. Community guesses (a 0.5 m grid, marching tetrahedra, CSG) are unverified. — [Unreal spotlight](https://www.unrealengine.com/spotlights/how-ghost-ship-games-found-success-with-deep-rock-galactic?lang=en-US); [r/howdidtheycodeit](https://redlib.hbubli.cc/r/howdidtheycodeit/comments/1e69166/how_did_they_code_the_pathfinding_implementation)
- **Teardown:** it rasterizes each object's bounding box and ray-traces the voxels in the fragment shader, using a modified DDA (a grid-stepping ray method) with mipmaps as a dense octree to skip empty space. Shadows use a separate packed structure. Large levels have about half a billion voxels. — [Teardown breakdown](https://juandiegomontoya.github.io/teardown_breakdown.html)
- **Space Engineers:** simulates physics only around players on servers. SE2 (2025) is working on "deformation LODs" to keep destruction and collisions detailed but cheap. — [Marek Rosa 2020](https://blog.marekrosa.org/2020/08/space-engineers-server-optimizations/); [Marek Rosa Sep 2025](https://blog.marekrosa.org/2025/09/mareks-dev-diary-september-11-2025/)
- **Astroneer:** the design goal was deformable planets "all the way to the center". I found no public implementation details (Surface Nets or dual contouring is only a community guess). — [Unreal dev interview](https://www.unrealengine.com/developer-interviews/inspired-space-inside-the-development-of-astroneer?lang=ja); [r/VoxelGameDev](https://lr.in.psf.lt/r/VoxelGameDev/comments/1c453u3/isosurface_algorithm_used_by_keen_games_in)

### Inferences
- The idea most worth copying for an underground game is Minecraft's cave culling: per-block face connectivity, then a flood fill from the camera's block, then hide blocks that cannot be reached. Caves mean heavy overdraw. Godot's built-in occlusion culling does not know voxel connectivity, so this would be a custom GDScript pass over mesh-block visibility (`mesh_block_entered`/`exited` give the block list).
- Sodium and the 7DTD modder point the same way: spread mesh uploads across frames. In godot_voxel that means keeping `voxel/threads/main/time_budget_ms` below the frame budget, perhaps 4 ms at 60 fps.

### Gaps
- Found no primary technical source for Deep Rock Galactic, No Man's Sky or Astroneer terrain. Official 7DTD notes on the cost of structural integrity were not found. Teardown's primary material (Gustafsson's blog and 2020 stream) was not fetched directly.
