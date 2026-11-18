# CPU-side performance for a Godot 4.7 GDScript voxel game: script speed, threading, physics, memory and loading

Project context (from the brief, not from sources): ~40,000 nodes; firefly swarm in GDScript cost 5-6 ms per frame until it moved to a shader; cave/decoration planning takes 4-22 s per system (millions of SDF queries at ~40 µs each); up to 110 RigidBody3D debris pieces with convex shapes against voxel trimesh colliders (Godot Physics, ~2 ms); world load ~80 s; 4-player co-op; uses Voxel Tools (GDExtension).

## GDScript performance: typing, Packed arrays, allocations, process callbacks, node count, servers

### Takeaway
Static typing everywhere is the cheapest big win (typed VM instructions make operations 25-50% faster and native calls 70-150% faster in the developer's own benchmarks). After that, the big wins are structural: fewer nodes, no per-frame work on far objects, and driving very large object counts through RenderingServer/PhysicsServer3D or shaders instead of nodes.

### Cited Findings
- Typed GDScript emits specialized VM instructions when operand types are known at compile time; the interpreter skips runtime type lookup and can call native functions directly. Author: "to enjoy the most benefit you have to use static typing for everything." — [Godot blog: GDScript progress report, typed instructions](https://godotengine.org/article/gdscript-progress-report-typed-instructions)
- Measured gains from typing (synthetic, debug build; release expected better): operators ~25-50% faster; built-in type method calls ~30% (70% with pre-validated args); native class method calls ~70-80% (120-150% with pre-validated args); built-in functions like `sin()` ~25-50%; `for` iteration ~10-50% (smaller for dictionaries/strings); subscript/attribute access ~5-7%. — [Godot blog](https://godotengine.org/article/gdscript-progress-report-typed-instructions)
- Not optimized at that time: the compiler does no code optimization (no inlining/constant folding passes), type inference could be better. — [Godot blog](https://godotengine.org/article/gdscript-progress-report-typed-instructions)
- Community benchmark (1-billion-iteration loops): a Vector2 distance test went from 24,980 ms untyped to 11,238 ms typed (-55%) in a debug build. A different repost of similar tests shows 1.42x-2.07x speedups; numbers disagree between sources. — [beep.blog via search snippet](https://beep.blog/2024-02-14-gdscript-typing); [dev.to](https://dev.to/ziva/static-typing-in-gdscript-the-30-minutes-that-saved-me-30-hours-1m8k) (could not fetch beep.blog directly; numbers from search snippet)
- Official Godot benchmark site: a typed int Array run ~121 ms vs ~193 ms untyped; some entries show little difference; string arrays slow either way; typed Dictionary not reported faster on the forum. — [benchmarks.godotengine.org](https://benchmarks.godotengine.org/benchmark/2024-01-26_503447861)
- Built-in engine functions run at the same speed from any language; only your own script logic gets faster by switching language. — [Godot docs: CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html)
- Every node has a cost because `_process()`/`_physics_process()` propagate through the tree; fewer nodes holding more content often perform better; `remove_child()` can outperform pausing or hiding a node (reattach later with `add_child()`). — [Godot docs: CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html)
- Measure with `Time.get_ticks_usec()` around code, run 1,000+ times and average; first run is often slower (cache effects); start/stop the built-in profiler manually because it slows the game. — [Godot docs: CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html)
- Servers (RenderingServer, PhysicsServer3D) bypass the scene system; the docs say to use them for cases like "tens of thousands of instances" processed every frame, after other optimizations. Node drawbacks listed: extra complexity, lower performance than direct API calls, node-controlled objects can't be driven by multiple threads, higher memory use. — [Godot docs: Optimization using Servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html)
- Server rules: objects are RIDs you must free yourself; RIDs don't hold a reference, so keep the Resource (e.g. Mesh) alive yourself; don't control RIDs of objects that already belong to a node. 3D example: `RenderingServer.instance_create()`, `instance_set_scenario(get_world_3d().scenario)`, `instance_set_base(mesh_rid)`, `instance_set_transform()`. — [Godot docs: Using Servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html)
- Do NOT call value-returning functions on RenderingServer/PhysicsServer3D every frame: they stall the asynchronous servers and "will severely decrease performance" in non-obvious ways. — [Godot docs: Using Servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html)
- Arrays, Dictionaries and Objects are passed by reference (not copied); only base types (int, float, String, vectors) are copied. RefCounted objects are freed by reference counting, not a stop-the-world GC. — [Godot docs: GDScript: An introduction to dynamic languages](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_advanced.html)
- Experienced forum advice: "be very sparing" with what runs every frame; GDScript helpers ~2x slower than equivalent built-in C++ (`find_children()`) is fine for rare logic but not per-frame code. — [Godot Forum](https://forum.godotengine.org/t/performance-implications-of-using-native-code-instead-of-gdscript/120365)

### Inferences
- The firefly result (5-6 ms -> ~0 after shader) matches the docs' guidance: anything with hundreds+ of elements updated per frame should be a shader, MultiMesh, GPU particles or a server-level loop, not per-node GDScript.
- With ~40,000 nodes, the quickest audit is: which nodes have `_process`/`_physics_process` enabled (`set_process(false)` / `set_physics_process(false)` on idle or far ones), and which purely decorative nodes (static rocks, crystals, clutter) could be merged into MultiMeshInstance3D or created as RenderingServer instances without nodes. Removing far subtrees with `remove_child()` instead of hiding them follows the CPU-optimization page.
- Turn on the project setting that warns/errors on untyped declarations (Debug > GDScript > Untyped Declaration) so every hot file is fully typed; use `PackedFloat32Array`/`PackedVector3Array`/`PackedInt32Array` for big numeric data (contiguous memory, typed) and pre-allocate with `resize()` rather than `append()` in hot loops. (General practice; the typed-array gain is supported by the benchmark site, Packed-array numbers were not found.)
- Signal cost: no measured figures found. Treat signals as cheap for events but avoid emitting per-element-per-frame.

### Gaps
- No authoritative benchmark found for signal emit cost, Node vs RefCounted vs server memory per object, or `_process` vs `_physics_process` overhead per node.
- No official release-note evidence found of GDScript VM speedups in 4.5-4.7 specifically (4.5 notes focus on core/editor optimization and debugging features like backtraces). The University of Twente thesis on typed vs dynamic GDScript ([essay.utwente.nl](https://essay.utwente.nl/essays/107857)) was found but its results were not readable.

## Moving hot code: C++ GDExtension, C#, compute shaders

### Takeaway
Pure-math hot loops (like SDF evaluation) are where native code helps most: reported speedups range ~5x-20x over GDScript, while engine-call-heavy code (node creation) shows little gain. For SDF/terrain generation the best option in this project is probably to push work into Voxel Tools' native pieces (VoxelGeneratorGraph, bulk VoxelTool ops) or a small godot-cpp GDExtension; compute shaders are possible but add GPU round-trip complexity.

### Cited Findings
- C++ via GDExtension usually gives the fastest code but is harder to deploy across platforms; C# is a middle ground but watch for GC pauses (use pooling). — [Godot docs: CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html)
- GDScript docs: for very computationally intensive games, keep most code in GDScript and write only the performance-critical parts in C++. — [Godot docs](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_advanced.html)
- Vendor benchmark (Jenova C++ framework, not godot-cpp, Godot 4.5 beta1, i9-12900K): math stress test C++ 245.6 ms vs GDScript 5,078.9 ms (~20x) vs C# 3,564.1 ms. Self-reported by a vendor. — [Jenova benchmark page](https://jenova-framework.github.io/docs/pages/Misc/Benchmark)
- Rust GDExtension Fibonacci test (Reddit, unoptimized build): GDScript 390 ms vs Rust 77 ms (~5x). — reported in search summary of [gdextensions_vs_gdscript_test](https://awesome.ecosyste.ms/projects/github.com%2Fantzgames%2Fgdextensions_vs_gdscript_test) / r/godot; not independently verified
- Counterexample: a C++ GDExtension loop that creates Node2D children was not faster than GDScript, because engine calls dominate. — [Godot Forum](https://forum.godotengine.org/t/c-create-nodes-slower-than-gdscript-what-i-am-doing-wrong/55520)
- Voxel Tools: GDScript is slow for intensive 3D loops over voxel buffers; use it as "logic glue" calling VoxelTool/VoxelBuffer methods or graphs. Single `set_voxel`/`get_voxel` calls are the slowest path (locking + several data structures); prefer `do_sphere()`, `do_box()`, `raycast`, `paste()`, or `copy()` a region into a VoxelBuffer, work lock-free, `paste()` back. Iterate Z, then X, then Y for cache locality. — [Voxel Tools docs: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)
- VoxelGeneratorGraph processes buffers (e.g. 16x16 slices) rather than single voxels, uses range analysis to skip regions, SDF clipping to skip blocks fully above/below the surface, dynamic branch skipping, and XZ caching; it also has a GPU backend (shaders compile on a background thread; FastNoiseLite count and cellular noise lengthen compile). — [Voxel Tools docs: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)
- Running GDScript on multiple threads in the editor carries a large penalty that exported builds don't have; compare performance in exported builds. — [Voxel Tools docs: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)
- Compute shaders are GLSL, run only on RenderingDevice renderers (Forward+/Mobile), dispatched by creating a local RenderingDevice (`RenderingServer.create_local_rendering_device()`), loading SPIR-V, building a pipeline, binding storage buffers in uniform sets, dispatching, then `submit()`/`sync()` and reading the buffer back; local devices can't be inspected with RenderDoc. — [Godot docs: Using compute shaders](https://docs.godotengine.org/en/stable/tutorials/shaders/compute_shaders.html)

### Inferences
- 40 µs per SDF query is very slow even for GDScript; it likely means each query walks many shapes/noise calls or allocates. Order of attack: (1) type everything and remove per-call allocations; (2) evaluate SDFs on a coarse grid in batches and only refine near the surface (the same "range analysis / clipping" idea VoxelGeneratorGraph uses); (3) spread across WorkerThreadPool group tasks (see next section); (4) port the SDF evaluator to a small godot-cpp GDExtension taking/returning Packed arrays, where a 5-20x gain is plausible for pure math; (5) a compute shader can evaluate millions of SDF points in one dispatch, but the planning code must then be data-parallel.
- Combined effect (inference, not measured): typing (~1.5-2x) x threads (~4-6x on an 8-core CPU) x native port (~5-20x) could plausibly turn 22 s into well under 1 s, but must be measured.
- C# brings GC and marshalling concerns and needs the .NET build of Godot; for a GDScript-only project, a targeted GDExtension for one or two hot functions is the lighter change.

### Gaps
- No rigorous, reproducible godot-cpp vs GDScript benchmark found from Godot developers; the godot-benchmarks repo includes both and can be run locally.
- No measured numbers for GPU SDF generation in Godot or readback overhead.

## Threading: WorkerThreadPool, thread safety, call_deferred, threaded loading

### Takeaway
Use `WorkerThreadPool.add_group_task()` for embarrassingly parallel planning (one element per chunk/column/region), keep threads away from the live scene tree, and hand results back with `call_deferred`. Arrays/Dictionaries can be read and their existing elements written from many threads, but any resize needs a Mutex.

### Cited Findings
- `add_task(action: Callable, high_priority := false, description := "") -> int` runs on one worker; `add_group_task(action: Callable, elements: int, tasks_needed := -1, high_priority := false, description := "") -> int` calls `action(i)` for i in 0..elements-1 across workers (-1 = all workers). — [Godot docs: WorkerThreadPool](https://docs.godotengine.org/en/stable/classes/class_workerthreadpool.html)
- Every task must be awaited with `wait_for_task_completion()` / `wait_for_group_task_completion()` so resources are cleaned up; `ERR_BUSY` signals a possible deadlock (a task waiting on an older task); `is_task_completed()`/`is_group_task_completed()` allow polling; `get_group_processed_element_count()` gives progress. Using the pool for cheap work can hurt performance. — [Godot docs: WorkerThreadPool](https://docs.godotengine.org/en/stable/classes/class_workerthreadpool.html)
- Scene tree: accessing the active tree from threads is unsafe; use `call_deferred`/`set_deferred`; building node hierarchies outside the tree on a thread is fine, add them on the main thread. Only one thread should create/load scene chunks. — [Godot docs: Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html)
- Resources: modifying one resource from multiple threads is unsupported; passing references across threads is fine. — [Godot docs: Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html)
- Servers: most singletons are thread-safe; Rendering/Physics servers need the rendering thread model "Separate" / physics "Run on Separate Thread" for thread-safe use; avoid GPU-facing ops (creating textures, image read/write) from other threads. AStar2D/3D/AStarGrid2D are not thread-safe (one object per thread). Navigation servers are thread-safe. — [Godot docs: Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html)
- GDScript Arrays/Dictionaries: reading and writing existing elements from multiple threads is OK; anything that changes size (append, erase, resize) needs a Mutex. — [Godot docs: Thread-safe APIs](https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html)
- Jolt's "Run On Separate Thread" / thread safety is experimental and lightly tested. — [Godot docs: Using Jolt Physics](https://docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html)
- Voxel Tools: don't give all CPU threads to voxel work; thread count is tuned by `voxel/threads/count/minimum`, `margin_below_maximum`, `ratio_over_maximum` (restart needed); main-thread work (mesh upload, collider creation) is capped by `voxel/threads/main/time_budget_ms` (default ~8 ms). — [Voxel Tools docs: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)

### Inferences
- Pattern for world planning: pre-size `PackedFloat32Array`/`Array` result buffers (one slot per region) on the main thread, run `add_group_task(plan_region, region_count)`, each task writes only its own slot (allowed without mutex), poll `is_group_task_completed()` each frame to drive a loading bar, then `wait_for_group_task_completion()` and instantiate nodes on the main thread. Give each task its own RandomNumberGenerator seeded from region index so results stay deterministic for co-op (host and clients get the same world).
- Do not let worker threads compete with Voxel Tools' own thread pool at full width during gameplay; during the loading screen it is fine.
- Profile threaded GDScript in an exported build, since the editor penalty (Voxel Tools docs) can hide the real gain.

### Gaps
- No official numbers on WorkerThreadPool overhead per task (the docs only say cheap tasks can hurt).

## Physics: Jolt vs Godot Physics, sleeping, layers, tick rate, interpolation, debris

### Takeaway
Jolt has been built in since 4.4 and is the default for new 3D projects since 4.6, but existing projects keep their old engine, so this project is likely still on Godot Physics (matching the brief). Switching is one project setting and is the main physics lever; beyond that, cap and pool debris, let it sleep fast, keep tick rate at 60 with interpolation, and fake far/small debris without physics.

### Cited Findings
- Jolt was added as an alternative 3D engine in 4.4 (marked experimental then); in 4.6 (released Jan 27, 2026) the experimental label was removed and Jolt became the default for new 3D projects; existing projects keep their settings and results will differ. — [Godot 4.6 release page](https://godotengine.org/releases/4.6/); [GameFromScratch](https://gamefromscratch.com/godot-4-6-released/); [Godot 4.4 Jolt docs](https://docs.godotengine.org/en/4.4/tutorials/physics/using_jolt_physics.html)
- Godot Jolt extension authors claim "Better performance, mainly, but also generally having a more stable simulation compared to Godot Physics," with no published numbers; the extension is now in maintenance mode. — [godot-jolt GitHub](https://github.com/godot-jolt/godot-jolt)
- GameFromScratch says Godot Jolt "performs significantly better" than built-in physics, citing a video (not verifiable numbers). — [GameFromScratch](https://gamefromscratch.com/godot-4-4-gets-native-jolt-physics-support/)
- Jolt differences that matter here: shapes shrink before applying margin (not grow); ghost collisions mitigated by active edge detection and enhanced internal edge removal (helps bodies sliding over trimesh terrain); contact impulses are estimates; kinematic-body contact reporting is off by default for performance; enabling ray-cast face index increases ConcavePolygonShape3D (trimesh) memory by ~25%; sleep settings `physics/jolt_physics_3d/simulation/allow_sleep`, `sleep_velocity_threshold`, `sleep_time_threshold`. — [Godot docs: Using Jolt Physics](https://docs.godotengine.org/en/stable/tutorials/physics/using_jolt_physics.html)
- Use simplified collision shapes; remove distant/off-screen physics objects or reuse them from a pool; lowering tick rate reduces CPU but adds jitter and input lag, keep 60 Hz for real-time games; use physics interpolation, which is "far cheaper than running extra physics ticks." — [Godot docs: CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html)
- Physics interpolation is off by default; it smooths displayed transforms between physics ticks at a cost of 1-2 ticks of display lag; keep tick rate fixed at design time. — [Godot docs: Physics interpolation intro](https://docs.godotengine.org/en/stable/tutorials/physics/interpolation/physics_interpolation_introduction.html)
- Voxel Tools: each terrain block gets a static mesh collider; collider creation costs ~3-5x more than meshing (builds an acceleration structure) and runs on the main thread spread over frames, slowing terrain loading considerably vs. no collisions; tunnelling risk for fast objects (limit speed, raycasts, CCD). — [Voxel Tools docs: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)
- Servers page: PhysicsServer3D can create bodies without nodes (body_create, shape, space, force-integration callback) for very large counts. — [Godot docs: Using Servers](https://docs.godotengine.org/en/stable/tutorials/performance/using_servers.html)

### Inferences
- 110 convex bodies costing ~2 ms in Godot Physics is high but expected for convex-vs-trimesh pairs; first try switching `physics/3d/physics_engine` to Jolt in a branch and measure the same debris scene (the "physics_process" time in the Monitors tab). Test for behaviour changes (stacking, margins) before committing.
- Debris recipe: pool a fixed number of RigidBody3D (e.g. 30-50) and recycle the oldest; use the simplest shape (BoxShape3D/SphereShape3D or a low-vertex convex hull) instead of detailed convex; put debris on its own collision layer with a mask that hits only terrain (not other debris, not players), which removes debris-debris pairs; lower sleep thresholds so pieces freeze quickly; after N seconds asleep, replace the body with a plain mesh (or MultiMesh entry) and free the body; for tiny chips, use GPU particles with collision or a tween instead of real bodies.
- Keep 60 Hz physics; enable `physics/common/physics_interpolation` only if the dwarf/camera jitter is an issue, and call `reset_physics_interpolation()` after teleports (method exists on Node3D; not quoted in fetched page).
- Collider cost for voxel chunks matters for the 80 s load: consider only generating colliders near players (4-player co-op means near any player).

### Gaps
- No reliable published Jolt vs Godot Physics benchmark with numbers for Godot 4.4-4.7 was found; the project must measure its own scene.
- No numbers found for trimesh vs convex cost ratios in either engine.

## Memory and loading: caching, streaming, loading screens, shader stutter, pooling

### Takeaway
The 80 s load should be attacked by (1) not recomputing deterministic plans each launch (cache the planned world to disk per seed), (2) moving planning to worker threads behind a non-freezing loading screen, and (3) background resource loading with `ResourceLoader.load_threaded_request`. Shader stutter is largely handled by 4.4+ ubershaders/pipeline precompilation on Forward+/Mobile, with gaps that monitors can reveal.

### Cited Findings
- `ResourceLoader.load_threaded_request(path)` starts loading in background threads; `load_threaded_get_status(path, progress_array)` returns status and fills `progress[0]` with completion; `load_threaded_get(path)` returns the resource, blocking like `load()` if not finished. — [Godot docs: Background loading](https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html)
- Before 4.4, pipelines compiled when an object first appeared on screen, causing first-time hitches. 4.4 added ubershaders (one pipeline precompiled per shader that can switch specialization constants at render time; optimized variants compile in the background) and pipeline precompilation at load time; this works only on Vulkan/D3D12/Metal (not the Compatibility renderer); some cases still aren't covered and 2D has no precompilation; use the pipeline compilation monitors to detect remaining stutter. — [Godot docs: Reducing stutter from shader (pipeline) compilations](https://docs.godotengine.org/en/4.7/tutorials/performance/pipeline_compilations.html)
- Godot 4.5 focused on optimizing core components; in the Third-Person Shooter demo, load times fell by a claimed ~20x on some platforms (Windows D3D12, macOS Metal). — [search summary of Godot 4.5 coverage](https://godotengine.org/releases/4.5/) (secondhand; figure not confirmed on the official page)
- Godot 4.6 made Direct3D 12 the default rendering driver on Windows for new projects. — [Godot 4.6 coverage via search](https://godotengine.org/releases/4.6/)
- Pool distant/expensive physics objects; for C#, pooling avoids GC pauses. — [Godot docs: CPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/cpu_optimization.html)
- Voxel Tools caps main-thread mesh/collider work at ~8 ms per frame by default (`voxel/threads/main/time_budget_ms`); a larger budget during the loading screen loads faster. Mesh block size 32 cuts draw calls but makes edits slower. — [Voxel Tools docs: Performance](https://voxel-tools.readthedocs.io/en/latest/performance/)

### Inferences
- Caching: because planning is seeded and deterministic, save the plan output (decoration positions, cave graph, etc.) as `PackedFloat32Array`/`PackedVector3Array` in a binary file under `user://cache/<seed>_<version>.bin` via `FileAccess.store_var()` or `var_to_bytes()` (or a custom Resource saved with `ResourceSaver` as `.res`); on load, check a version number and recompute if the planner changed. For co-op, the host can send the seed and clients compute/load the same cache, or the host streams the cached plan.
- Loading screen without freezing: run planning in WorkerThreadPool group tasks and keep the main thread rendering a progress bar from `get_group_processed_element_count()`; instantiate nodes in small batches per frame (e.g. a time budget of ~8 ms, mirroring Voxel Tools) instead of one giant loop; temporarily raise `voxel/threads/main/time_budget_ms` during the load screen.
- Only plan/instantiate what is near players first (streaming), and fill the rest in the background during play.
- Warm up shaders by showing every material once behind the loading screen (common practice; not quoted in fetched docs beyond the precompilation discussion).

### Gaps
- No official numbers found for `store_var`/binary file speed vs recomputation, or for `load_threaded_request` with `use_sub_threads` (not covered on the fetched page).
- No figures found for memory cost per Node vs RenderingServer instance.
