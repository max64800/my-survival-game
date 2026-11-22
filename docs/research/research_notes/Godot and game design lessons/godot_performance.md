# Godot 4.x performance techniques for the dwarf cave game

Scope: Godot 4.7 (Forward+, GDScript) and Voxel Tools GDExtension. Gaps the existing plan does NOT cover are marked **[NEW]**. The existing plan (`docs/research/Voxel game performance plan.md`) already covers: GPU firefly swarm and `custom_aabb`, threaded cave planning, `fill_f` early-out, visibility ranges on clutter/roots/grass/water/labels, the no-visuals remote viewer, a Potato/Low/Medium/High graphics menu (scale, shadow atlas, SSAO, `mesh_lod_threshold`), distance fade plus shadows off on decorative lights, Jolt trial and debris pooling, the Forward+ vs Compatibility choice, HZD-style culling and Minecraft-style cave connectivity culling, MultiMesh per chunk, `ArrayOccluder3D`, SQLite terrain stream, group tasks, typed GDScript, collision-only viewers, `mesh_block_size` 16 vs 32, co-op dig commands, and `Performance.add_custom_monitor`. This note adds the rest and does not repeat those items except where a new source confirms or corrects them.

Caveat on the existing plan: it says Jolt "became the default for new 3D projects in 4.6" (cited to the 4.6 release page). I did not re-verify that. The 4.7 upgrade guide says nothing about a default change. Check the 4.6 release page before relying on it.

## Draw calls and many-mesh scenes

### Takeaway
MultiMesh is the right tool for thousands of identical things, but it has no per-instance culling, so split it into chunks. Forward+ auto-instances plain MeshInstance3D nodes that share one mesh and one material, but only if the material is opaque or alpha-scissor/alpha-hash. Shared materials matter as much as draw-call counts.

### Cited Findings
- Automatic instancing is Forward+ only. It applies to MeshInstance3D nodes that share the same mesh and material. It needs opaque or alpha-tested (alpha scissor or alpha hash) materials, and alpha-blended and depth-prepass materials are not instanced. — [Godot: Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- Example from the same source: 20,000 objects sharing 100 materials render much faster than 20,000 objects with 20,000 materials. — [Godot: GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- MultiMesh has "all-or-none visibility": no per-instance screen or frustum culling. The fix is a custom visibility rect or several MultiMeshes split by area. Simple meshes usually handle this well. — [Godot: Using MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html)
- MultiMesh guidance: thousands of instances that need per-frame processing belong on servers, hundreds of thousands to millions suit MultiMesh, and GDScript is fine for a few thousand instances. Allocate the maximum count up front and change `visible_instance_count`. Vertex shaders can animate instances via `INSTANCE_ID` or `INSTANCE_CUSTOM`. The page is marked as possibly outdated for 4.7. — [Godot: Using MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html)
- The "tens of thousands of instances processed every frame" threshold for servers is the only numeric guidance on the servers page. — [Godot: Optimization using Servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html)
- Using servers: calling server functions that return values can stall the asynchronous servers and "will severely decrease performance if you call them every frame." — [Godot: Optimization using Servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html)
- Distant objects: a naive renderer may draw 10x to 100x more than is visible. Use manual visibility ranges (HLOD) on 3D nodes, and mesh LOD generated on import. Combine methods, e.g. visibility range plus lower mesh LOD. Groups of distant objects can be drawn as one unit, and imposters are pre-rendered views on a quad. — [Godot: Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- Keep transparent objects to a minimum. Transparent objects can't be sorted by material and are drawn back to front. Split a small transparent section into its own surface with its own material. — [Godot: Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- Animated models: lower polycounts, limit how many are on screen, reduce animation rates for distant or occluded meshes, pause animations the player is unlikely to notice. `VisibleOnScreenEnabler3D` or `VisibleOnScreenNotifier3D` can switch animation off based on visibility. — [Godot: Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- Fill-rate test: turn V-Sync off and compare FPS in a large window and a very small one. A big gain means fill-rate bound. Little gain means another bottleneck. — [Godot: GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- Vertex cost is low on PC and console. Use LODs for distant objects and avoid triangles smaller than a pixel (the advice is written for mobile, so treat as a general hint). — [Godot: GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)

### Inferences
- **[NEW] Building pieces:** every ruin piece that uses the same opaque material resource (the same `.tres` instance, not a copy per piece) lets Forward+ auto-instance it for free. Check that the clay-brick, cut-stone and plank pieces share one material each. Duplicated materials per piece (for example, a per-piece tint) would turn off this batching. Tint through a shared material with per-instance colour instead.
- **[NEW] Transparency:** any alpha-blended ruin, glass, or glow material breaks auto-instancing and forces back-to-front sorting. Use alpha-scissor (cutout) for leaves, grates and the like.
- **[NEW] Creatures:** animation is probably a large share of the 12 FPS fight-room cost. Turn off skeleton/AnimationTree updates for creatures outside the camera or behind rock, and lower the update rate for distant ones. `VisibleOnScreenEnabler3D` only sees the camera frustum, not rock blocking the view (inference from the docs' wording).
- Frustum culling is per node bounding box. A big MultiMesh is culled as one unit, so per-chunk MultiMesh (already in the existing plan) is the rule.

### Gaps
- No official source compares MultiMesh with merged ArrayMesh (SurfaceTool) for static ruin geometry. Not researched; needs a benchmark in the game.
- No source gives a measured cost of an auto-instanced draw vs a non-instanced one.

## Lights and shadows in Forward+

### Takeaway
Forward+ handles many lights in view (512 by default). The expensive part is shadows: an omni light with cube shadows renders 6 times, a spot renders once, and every shadowed light takes a slot in one shared atlas. Crystals and mushrooms should be spot or omni lights with no shadows, with distance fade on, and they should never be baked-only.

### Cited Findings
- Forward+ clustering limit: 512 clustered elements in view (omni, spot, decals, reflection probes), changed in Project Settings > Rendering > Limits > Cluster Builder > Max Clustered Elements. Exceeding the limit makes lights pop in and out. Up to 8 DirectionalLights are visible at once on all renderers. — [Godot: Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- Positional shadow atlas: 4 quadrants, default 4096 size, suggested 2048 for low-end GPUs. Default allocation is 4+4+16+64 = 88 shadowed lights in the frustum. Each light is re-rendered only when its slot size changes or a caster changes. All directional shadows share one atlas, so each extra shadowed DirectionalLight lowers the resolution of all of them. — [Godot: Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- Shadow cost: omni Cube renders 6 faces (default, most accurate and slowest), omni Dual Paraboloid renders 2, spot renders 1. Directional shadows use 4 PSSM splits by default, so an object spanning all four is drawn 5 times. — [Godot: Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- Distance fade: Begin (where fading starts), Shadow (where the shadow fades, can be earlier than the light), Length. The light is fully invisible at Begin + Length, then culled. The docs give no default numbers. — [Godot: Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- Tips: enable Distance Fade, split large level meshes for culling, bake Static lights, use emissive materials instead of lights for large-area glow, keep PCSS soft shadows to a few large lights (set Angular Distance or Size to 0 to disable), keep shadow Max Distance as low as possible, and avoid area lights. — [Godot: Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- Docs advice: "disabling shadows on as many lights and objects as possible is the best improvement"; small or distant OmniLights and SpotLights can often have shadows disabled with little visual loss. — [Godot: GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- Static bake mode: lights set to Static are baked into lightmaps. Static lights can't cast shadows onto baked meshes, so directional light stays Dynamic. — [Godot: Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- LightmapGI: lightmaps are fixed after baking and "can't be modified at all." Changing lights or geometry needs a rebake. Baking takes minutes or longer. Only MeshInstance3D nodes set to Static bake mode get lightmapped. Up to 8 LightmapGI nodes render at once. — [Godot: Using LightmapGI](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_lightmap_gi.html)
- The LightmapGI docs say SDFGI "can support large open worlds without any need for baking." — [Godot: Using LightmapGI](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_lightmap_gi.html)
- Shadow bias: raise Normal Bias first (less peter-panning). No numeric defaults are given. — [Godot: Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)

### Inferences
- **[NEW] LightmapGI and baked lights are the wrong fit for this game.** Dug tunnels and changing caves break baked lighting, and rebakes take minutes. Use dynamic lights, not LightmapGI. The same applies to VoxelGI, which the pipeline doc lists as a trigger for stutter (see below).
- **[NEW] Shadow budget per light type for crystals:** an omni light with cube shadows costs 6 renders; use spot lights for crystals (1 render) or omni with shadows off. The existing plan's "shadows off on decorative lights" is correct; the cost-per-type numbers above make it more urgent for omni lights.
- **[NEW] Forward+ light count is not the limit; atlas slots and directional shadow count are.** Keep directional shadows to one (sun-like light, if any) because each extra one lowers the atlas resolution for all of them. A dwarf's lantern with shadows is probably the only shadowed light needed.
- **[NEW] Distance fade needs all three values set.** Begin, Shadow and Length should each be tuned per light type. The existing plan's crystal fade values (12-35 m) are plausible but unsourced.

### Gaps
- No Godot docs number for SDFGI or VoxelGI cost. The question of whether SDFGI is cheap enough for a dug cave is not answered by these sources.
- The Dynamic bake mode is not explained on the docs page.

## Voxel Tools specific (terrain meshing, threads, collision, editing)

### Takeaway
Voxel Tools' documented knobs are thread counts, the main-thread time budget, mesh block size, LOD distance, and collision. Thread settings need a restart. Exported builds run threaded GDScript much faster than the editor.

### Cited Findings
- Thread settings: `voxel/threads/count/minimum`, `voxel/threads/count/margin_below_maximum` (1 means max minus 1), and `voxel/threads/count/ratio_over_maximum` (0 to 1). Leave some cores free for the game. Check the count with `VoxelEngine.get_stats()` or `-v` / `verbose_stdout`. Thread settings need a restart. — [Voxel Tools: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)
- `voxel/threads/main/time_budget_ms`: caps main-thread work per frame, default about 8 ms. — [Voxel Tools: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)
- Mesh block size 32 reduces draw calls but makes edits slower. Reducing the LOD distance means fewer blocks to destroy. Limiting player speed near voxels helps when moving fast near many blocks (the page's Vulkan note for 4.x). — [Voxel Tools: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)
- The VoxelTerrain API reference notes an internal limit of 512 for constant LOD terrains. — [Voxel Tools: VoxelTerrain API (via search snippet)](https://voxel-tools.readthedocs.io/en/latest/api/VoxelTerrain/)
- Editor runs of multithreaded GDScript (such as `VoxelGeneratorScript`) are much slower because of debug synchronization. Exported builds don't have this penalty. — [Voxel Tools: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)
- Edit efficiently: iterate z, then x, then y for cache locality. Use bulk methods (`do_sphere()`, `do_box()`, `raycast`, `paste()`) instead of repeated `get_voxel`/`set_voxel`. For custom bulk edits, `copy()` a `VoxelBuffer`, edit it, then `paste()` it back. — [Voxel Tools: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)
- Collision: standard physics uses mesh colliders per block, which are slow and run on the main thread. Disabling collisions loads terrain much faster. `VoxelBoxMover` and voxel raycasts are faster but only work with axis-aligned boxes on blocky terrain. — [Voxel Tools: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)
- VoxelGeneratorGraph (CPU): `sdf_clip_threshold` skips blocks; a 16x16x16 subdivision is usually good (must divide the block size); range analysis, execution map, and XZ caching can be toggled in the inspector. Shader (GPU) generators: reduce `FastNoiseLite` node count to cut shader compile time. — [Voxel Tools: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)
- Godot 3.x note in the same page: the OpenGL slow-mesh-update fixes (verbose stdout, vsync, time budget) are for Godot 3.x. Do not apply them to 4.x without checking. — [Voxel Tools: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)

### Inferences
- **[NEW] Thread count:** the game should set `voxel/threads/count/ratio_over_maximum` (or `margin_below_maximum`) in `project.godot` so a 4-core Potato PC doesn't starve the game of CPU time. Set it through the settings menu, then restart. Check with `VoxelEngine.get_stats()` in the perf log.
- **[NEW] Time budget during load:** raise `time_budget_ms` during the loading screen, then lower it for play, as the existing plan says. The docs say ~8 ms is the default; this is a good starting point to measure from.
- **[NEW] Measure in an exported build**, as the existing plan says. The editor is misleading for threaded GDScript.
- **[NEW] Bulk edits for digging:** the dig code should use `do_sphere()` (or `paste()` of a prepared buffer) for each dig, not per-voxel loops in GDScript. This matters for the co-op dig command path too.
- **[NEW] Mesh block size and hot digs:** the docs connect fast player movement near many small blocks with slowdowns. Keep 16 for digging speed (existing plan), but consider 32 for distant blocks only, if Voxel Tools' setup allows it (not verified).

### Gaps
- Whether Voxel Tools' `VoxelLodTerrain` can use per-block visibility or LOD tricks for caves is not covered by these sources. The existing plan already notes the lack of LOD caching.
- No measured numbers for collision cost on this game's terrain; only the docs' "3 to 5 times as much as meshing" figure from the existing plan (not re-verified here).

## GDScript CPU hot spots

### Takeaway
GDScript is fine for a few thousand instances. Above that, use servers or MultiMesh. Typed declarations are the cheapest speedup. Avoid reading server values every frame. Removing nodes from the tree is faster than hiding them.

### Cited Findings
- Typed GDScript "improves performance by using optimized opcodes when operand/argument types are known at compile time." Typed global-scope calls such as `absf()`, `floori()`, `clampi()` are listed as typed instructions. The docs give no speed numbers. — [Godot: Static typing](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html)
- Untyped declaration warnings: `UNTYPED_DECLARATION` and `INFERRED_DECLARATION` are off by default. Turn them on in Project Settings > Debug > GDScript (Advanced Settings on). — [Godot: Static typing](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html)
- The Godot blog's typed-instructions numbers (operators 25-50% faster, native method calls 70-150% faster) are cited in the existing plan. These come from a 4.x-era blog post and were not re-verified in this pass. — [Godot blog: typed instructions](https://godotengine.org/article/gdscript-progress-report-typed-instructions) (cited in existing plan)
- CPU advice: `_process()` and `_physics_process()` "propagate through the tree," which adds overhead with very large node counts. Node count issues show up from thousands to tens of thousands of nodes, depending on platform. Removing nodes from the tree can outperform pausing or hiding them. — [Godot: CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html)
- Physics ticks: keep 60 Hz for real-time movement. Fixed-timestep interpolation is "orders of magnitude faster" than a physics tick and reduces jitter. — [Godot: CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html)
- Threads: use them for calculations that can run in parallel across cores, and guard against race conditions. — [Godot: CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html)
- 4.7 change: setting a single packed-array element no longer calls the setter for the whole packed-array property. This may cut overhead, but the page does not quantify it. Code that relied on the setter firing changes behaviour. Also, overrides of methods with a typed return need an explicit return statement. — [Godot 4.7 upgrade guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)

### Inferences
- **[NEW] Per-frame allocations and signals vs polling:** the official docs say nothing numeric about signals vs polling or about per-frame allocations in GDScript. Rule of thumb only: avoid creating new arrays, dictionaries or strings inside `_process`; reuse buffers. Measure with the profiler's Self column before changing code.
- **[NEW] Node removal vs visibility:** the CPU page says removing nodes outperforms pausing or hiding them. Creatures far away and debris that is asleep are candidates for being removed or swapped for plain mesh instances, not for visibility toggles.
- **[NEW] Packed arrays in 4.7:** the packed-array setter change may help the cave planners and the MultiMesh buffer writes, if they set one element at a time. Check and benchmark after upgrading.

### Gaps
- No official numbers for signals vs polling costs or for allocation costs in GDScript.
- No official sources on `_process` vs `_physics_process` cost beyond the propagation note.

## Physics (Jolt vs Godot Physics)

### Takeaway
Jolt is built in and is intended to be faster and more stable. The evidence found so far is not clean: one community benchmark shows Jolt slower than Rapier in one 3D query test, and the Godot pull request warns about adding and removing shapes on bodies that are already in the tree. Measure on the game's own scene.

### Cited Findings
- Built-in Jolt: the pull request says users "should (generally, but not always) be able to expect better physics performance, both in terms of CPU performance and simulation stability." Adding or changing shapes on a body already in the tree can make performance worse than Godot Physics. — [Godot: Jolt physics PR text, via forum benchmark thread](https://forum.godotengine.org/t/physics-engine-comparison-rapier-vs-godot-vs-box2d-3d-vs-jolt/142786)
- Community benchmark (Godot 4.7's built-in Jolt): in 3D, "Query storm" Rapier was 4.0x faster than Jolt, roughly on par with Box3D. One table shows a 3D smash test going from 18.1 ms to 12.0 ms (51% faster) between two builds, but the columns are not clearly labelled. Treat with caution. — [Godot forum: Physics engine comparison](https://forum.godotengine.org/t/physics-engine-comparison-rapier-vs-godot-vs-box2d-3d-vs-jolt/142786)
- The 4.4 Jolt docs call the built-in version experimental and say it lacks parity with Godot Physics and with the Godot Jolt extension. These docs are from 4.4 and may be stale. — [Godot: Using Jolt Physics (4.4)](https://docs.godotengine.org/en/4.4/tutorials/physics/using_jolt_physics.html)
- 4.7 Jolt changes: SoftBody3D mass defaults to 1 kg for the whole body, `linear_stiffness` is applied differently, Area3D now reports overlaps with SoftBody3D, and WorldBoundaryShape3D plane sign is flipped. — [Godot 4.7 upgrade guide](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html)
- Physics interpolation: see CPU optimization above. — [Godot: CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html)

### Inferences
- **[NEW] Test Jolt on the actual cave scene,** including terrain collider creation during digs. The benchmark found is a synthetic query test, not a dug-cave test.
- **[NEW] Debris:** because Jolt is weak when shapes change on bodies in the tree, debris should be created with its final shape (box or sphere, set once), never reshaped after spawning.
- **[NEW] Soft bodies:** if the game uses SoftBody3D anywhere (for example, sacks or moss), the 4.7 changes mean re-tuning under Jolt.

### Gaps
- No clean, labelled benchmark of Jolt vs Godot Physics for 4.4 to 4.7 was found. No source gives a number for terrain collider creation under Jolt.
- The existing plan's statement that Jolt became default in 4.6 is not confirmed by the 4.7 upgrade guide. Check the 4.6 release notes.

## Profiling

### Takeaway
The built-in profiler (Debugger panel) is the first tool. It is off by default and costly, so turn it on only for a test run. Use the Self column to find the function itself, and compare frame time with physics time and idle time to tell CPU from GPU.

### Cited Findings
- The Profiler shows a function list and a performance graph. Click Start (or Autostart). Key numbers: frame time, physics frame (budget 16.66 ms at 60 FPS by default), idle time, physics time. Inclusive counts nested calls; Self counts only the function's own body. Click a spike to pause on that frame. — [Godot: The Profiler](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/the_profiler.html)
- Frame time spikes while physics and script times are normal point to rendering (the docs' example is particles/visual effects). — [Godot: The Profiler](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/the_profiler.html) (inference in the docs, not a stated rule)
- Fine timing: wrap code with `Time.get_ticks_usec()`. — [Godot: The Profiler](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/the_profiler.html)
- Average over 1,000 or more runs for micro-benchmarks, since timers are imprecise and caches skew single runs. — [Godot: CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html)
- Pipeline compilation monitors in the debugger count compilations by cause (Mesh, Draw, Surface, Specialization, Canvas). A spike in Surface during play usually means a feature was not enabled early. Spikes outside loading screens cause first-run hitches. — [Godot: Reducing stutter from shader compilations](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)

### Inferences
- **[NEW] Use the Surface and Mesh pipeline counters as a stutter test** in the scripted cave walk. Any spike there after loading is a real hitch to fix before the GPU work.
- **[NEW] Add the pipeline counters to the perf log** (existing plan's `Performance.add_custom_monitor`). Not covered by the existing plan.

### Gaps
- RenderDoc, the GPU-side profiler, and headless measurement were not researched in this pass. Headless runs skip rendering, so they can time GDScript and planning, not frame cost. This still needs a source before being used in tests.

## Load time and shader stutter

### Takeaway
Godot 4.4+ precompiles shaders for Forward+ at load time, but only for listed features. Some features cause compile stutter if they are first used during play. Threaded loading is available, but `load_threaded_get` blocks if called too early.

### Cited Findings
- Godot 4.4 moved pipeline compilation from "when first on screen" to detecting and precompiling pipelines at load time, with ubershaders as a fallback that builds specialized versions in the background. Precompilation applies to Forward+ and Mobile only, not Compatibility. — [Godot 4.4 docs: Reducing stutter from shader compilations](https://docs.godotengine.org/en/4.4/tutorials/performance/pipeline_compilations.html) (via search snippet)
- Features to enable early so their pipelines build during loading: MSAA level change, ReflectionProbe, separate specular, motion vectors (TAA/FSR2), normal/roughness buffer (SDFGI, VoxelGI, SSR, SSAO, SSIL), LightmapGI, VoxelGI, SDFGI, 16/32-bit shadow depth, omni dual-paraboloid or cubemap shadows. — [Godot: Reducing stutter from shader compilations](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)
- Practical fix from the docs: render a scene using those features early in loading, even off-screen in a SubViewport. — [Godot: Reducing stutter from shader compilations (latest)](https://docs.godotengine.org/en/latest/tutorials/performance/pipeline_compilations.html) (via search snippet)
- Mesh pipeline stutter: loading meshes during gameplay can stutter; loading them on a background thread helps. Specialization compiles run in the background but may lower frame rate. 2D nodes have no precompilation. Changing MSAA at runtime causes stutter. — [Godot: Reducing stutter from shader compilations](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)
- Compatibility renderer: no precompilation; preload materials, shaders and particles by showing them for one frame in view during loading. — [Godot: Reducing stutter from shader compilations](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)
- Shader Baker: an export preset option (off by default); it exports only shaders that match `rendering/rendering_device/driver` for the target platform. — [Godot: Reducing stutter from shader compilations](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html)
- Driver pipeline caches are usually wiped on driver updates and are hard to share across machines. — [Godot 4.4 docs (it): pipeline compilations](https://docs.godotengine.org/it/4.4/tutorials/performance/pipeline_compilations.html) (via search snippet)
- Threaded loading: `ResourceLoader.load_threaded_request`, `load_threaded_get_status` (with a progress array), `load_threaded_get`. If the load is not finished when `load_threaded_get` is called, it blocks. The page does not say which resource types can load in threads. — [Godot: Background loading](https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html)

### Inferences
- **[NEW] Shader warm-up scene:** the game should, during the loading screen, render one of each piece/crystal/creature/glow material plus a spot light and a distance-fade light in a SubViewport. This covers the feature list above. Do not enable SDFGI, VoxelGI or ReflectionProbe mid-game, and do not change MSAA during play.
- **[NEW] Threaded loads for ruins and creatures:** request the big ruin and creature scenes with `load_threaded_request` in the loading flow, and call `load_threaded_get` only after the status says done. This avoids a blocking load on the first encounter.
- **[NEW] Import settings** (texture compression, mesh LOD generation at import) were not researched in this pass. The GPU page says VRAM texture compression is on by default for 3D and helps large textures; it is not a load-time setting by itself.

### Gaps
- No official numbers for load time gains from threaded loading or from shader precompilation. The 110-150 s load figure is the project's own measurement.
- Which resource types can be loaded on threads is not stated on the background-loading page.
- The URL `docs.godotengine.org/en/stable/tutorials/performance/shader_precompilation.html` returned 404; the correct page is `pipeline_compilations.html`.

## Physics, debris and collision layers (cross-check)

### Takeaway
Layers and masks are the cheap part: debris should mask only terrain. The existing plan already covers pooling and layers; nothing new was found in the official docs for layers.

### Cited Findings
- None new beyond the Jolt and Voxel Tools citations above.

### Inferences
- The existing plan's debris recipe (pool 30-50 bodies, box or sphere shapes, own layer, sleep then freeze to a plain mesh) matches the advice that shape changes on bodies in the tree are costly. Keep it.

### Gaps
- No official source on collision layer cost was found in this pass.

## Summary of new actions (not in the existing plan)

1. Share one opaque material instance across all building pieces of one kind, so Forward+ auto-instances them. Check that no piece makes its own material copy.
2. Use spot lights (1 shadow render) or no-shadow omni lights for crystals and mushrooms. Keep directional shadows to at most one.
3. Do not use LightmapGI or baked lighting for the cave (static only, rebakes take minutes). Use dynamic lights.
4. Warm up a SubViewport of representative materials and lights during loading; avoid enabling SDFGI, VoxelGI or ReflectionProbe mid-game, and never change MSAA in play.
5. Use `load_threaded_request` for ruin and creature scenes.
6. Pause or reduce animation (`VisibleOnScreenEnabler3D`, lower rate) for creatures far away or out of view.
7. Remove, don't hide, far or sleeping debris and creatures where that's cheaper (CPU docs).
8. Set Voxel Tools thread counts through the settings menu (`ratio_over_maximum`), keep a core free, and check `VoxelEngine.get_stats()`.
9. Use bulk edit methods (`do_sphere`, `paste`) for digs; iterate z, x, y in custom loops.
10. Turn on `UNTYPED_DECLARATION` warnings and type hot files (existing plan, step 9 — listed here for the 4.7 packed-array change).
11. Add pipeline compile counters (Surface, Mesh) to the scripted perf log.
12. Keep transparency to small surfaces; use alpha-scissor for cutouts.

## Sources (fetched or seen)
- Godot 4.x docs: [Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html); [Using MultiMesh](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html); [CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html); [Optimization using Servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html); [GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html); [Reducing stutter from shader compilations](https://docs.godotengine.org/en/stable/tutorials/performance/pipeline_compilations.html); [Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html); [Using LightmapGI](https://docs.godotengine.org/en/stable/tutorials/3d/global_illumination/using_lightmap_gi.html); [Static typing](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/static_typing.html); [The Profiler](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/the_profiler.html); [Background loading](https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html); [Upgrading to 4.7](https://docs.godotengine.org/en/stable/tutorials/migrating/upgrading_to_godot_4.7.html); [Using Jolt Physics (4.4)](https://docs.godotengine.org/en/4.4/tutorials/physics/using_jolt_physics.html)
- Voxel Tools: [Performance](https://voxel-tools.readthedocs.io/en/latest/performance/); [VoxelTerrain API](https://voxel-tools.readthedocs.io/en/latest/api/VoxelTerrain/)
- Community: [Godot forum: Physics engine comparison](https://forum.godotengine.org/t/physics-engine-comparison-rapier-vs-godot-vs-box2d-3d-vs-jolt/142786)
- Godot release info seen only in search snippets (not fetched): [Godot 4.7 release page](https://godotengine.org/releases/4.7/); [Phoronix on 4.7](https://phoronix.com/news/godot-4.7-released) (4.7 shipped June 18, 2026 per search snippets; HDR output, AreaLight3D node; no performance section found).

## Overall gaps
- No official Godot doc gives measured frame costs for MultiMesh vs merged meshes, auto-instancing gains, or SDFGI/VoxelGI cost. These need in-game benchmarks.
- No clean Jolt vs Godot Physics benchmark for 4.4-4.7 exists in these sources.
- RenderDoc, the GPU profiler, and headless measurement were not researched.
- Godot 4.7 has no performance section in its release notes that I could find; the performance-relevant changes are the packed-array setter and sky-reflection roughness default.
- The shader precompilation URL the researcher brief implied (`shader_precompilation.html`) does not exist; use `pipeline_compilations.html`.
