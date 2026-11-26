# Performance research note (Godot 4.7, Forward+, Jolt, Voxel Tools)

Scope: only the gaps not already in the project notes (material batching, MultiMesh per chunk, shader warm-up, Voxel thread settings, static typing, Profiler Self column, VisibleOnScreenEnabler3D camera-only check).

Tags: [Sourced] = read on the official Godot docs page linked. [Guess] = from general experience, not checked on the docs.

Terms used:
- **LOD** (level of detail): a cheaper, simpler version of a model used when it is far away.
- **Occlusion culling**: skipping things hidden behind walls.
- **Draw call**: one instruction from the CPU asking the GPU to draw something.
- **Tick**: one fixed step of the physics engine.
- **Percentile / 1% low**: the frame time that the slowest 1% of frames reach. It shows stutter that an average hides.

---

## 1. Visibility ranges and mesh LOD

- [Sourced] `visibility_range_begin` / `visibility_range_end` hide a node when the camera is closer or farther than the set distance from the center of its box. `0` turns the check off. Source: https://docs.godotengine.org/en/stable/classes/class_geometryinstance3d.html
- [Sourced] Fade modes: `VISIBILITY_RANGE_FADE_DISABLED` (instant switch, cheapest), `..._SELF` (fades the node itself), `..._DEPENDENCIES` (fades its children). The two fade modes force transparent drawing, which costs performance. Source: https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html
- [Sourced] `visibility_parent` lets child nodes hide when their parent is hidden by its own range, so one check covers a whole group. Source: https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html
- [Sourced] `lod_bias` (default 1.0) sets how fast automatic mesh LOD drops detail. 0 forces the lowest detail. Mesh LOD is generated on import. Source: https://docs.godotengine.org/en/stable/classes/class_geometryinstance3d.html and https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html
- [Sourced] The docs say distant LODs should use simpler materials (no normal map, clearcoat or subsurface) and that the effect must be measured. Source: https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html
- [Guess] `mesh_lod_threshold` (the per-node switch distance) is not on the pages I read. It is probably a project-level setting, so check the Project Settings before using it.

**For us:** Use visibility ranges on far-away rock, decor and trees (set the fade mode to Disabled). Use the Voxel Tools LOD for terrain. Use one visibility_parent per building or dwarf group so the children hide together. Measure before and after.

---

## 2. Occlusion culling

- [Sourced] Turn it on in Project Settings under Rendering > Occlusion Culling > Use Occlusion Culling. Godot draws the occluder shapes into a small CPU buffer and hides anything fully behind them. Source: https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html
- [Sourced] `OccluderInstance3D` holds the shapes. Its "Bake Occluders" button makes them from mesh geometry, and only opaque materials are baked. Manual shapes: `BoxOccluder3D`, `QuadOccluder3D`, `SphereOccluder3D`, `PolygonOccluder3D`. `ArrayOccluder3D` is for scripts and is not editable in the editor. Source: same page.
- [Sourced] Not baked: `MultiMeshInstance3D`, particles, CSG (CSG works in 4.4+ only after conversion to MeshInstance3D). Works best indoors with many small rooms. Source: same page.
- [Sourced] Moving an `OccluderInstance3D` during play forces a rebuild of its tree. Hiding it is cheaper. Source: same page.
- [Guess] Voxel terrain is one big mesh set that changes as you dig, so baked occluders would go stale quickly. Runtime `ArrayOccluder3D` for each finished chunk surface is possible but untested here. Cost is unknown.

**For us:** Skip occlusion culling for the terrain. Maybe try it for the tunnels and rooms (built walls and ruins) later, after a measured test. Do not move occluders during play.

---

## 3. Physics cost (Jolt)

- [Sourced] Physics runs at a fixed rate, default 60 ticks per second. The setting is not named on the page I read. Source: https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html
- [Sourced] Only rigid bodies sleep. A sleeping body is not simulated and does not run `_integrate_forces()`. It wakes on a collision or a force. `can_sleep = false` keeps it awake and costs more. Source: same page.
- [Sourced] Layers say where an object is. Masks say what it looks for. Objects outside the mask are ignored, so a narrow mask is cheaper. Source: same page.
- [Sourced] `Area3D` `monitoring` must be true for signals. Overlap lists are updated once per physics step, not immediately after a move. Overlaps are only found when the layer is in the other area's mask. Source: https://docs.godotengine.org/en/stable/classes/class_area3d.html
- [Sourced] `CharacterBody3D.move_and_slide()` should be called in `_physics_process()`. `max_slides` (default 6) caps the work per call. Source: https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html
- [Guess] Jolt specifics (sleep thresholds, per-body cost, `physics/jolt_*` settings) and physics interpolation (`physics/common/physics_interpolation`) were not confirmed. The docs pages I tried returned 404. Check those in the docs search before using them.

**For us:** Keep dwarves on CharacterBody3D with narrow layers and masks (dwarf, monster, terrain, pickup). Use Area3D only for big triggers, not one per item. Use signals, not polling. Ask Jolt-specific questions later with the docs in hand.

---

## 4. Animation cost

- [Sourced] `AnimationPlayer` / `AnimationMixer` have `callback_mode_process` (IDLE, PHYSICS, MANUAL). The old AnimationPlayer enum values are deprecated and point at AnimationMixer. Source: https://docs.godotengine.org/en/stable/classes/class_animationplayer.html
- [Sourced] `advance(delta)` on AnimationMixer moves the animation forward by hand. Calling `seek(..., update_only = true)` skips method, audio and animation tracks. Source: same page.
- [Sourced] The optimization page says skinning and morphing are expensive, and recommends lower animation rates for distant or hidden meshes. `VisibleOnScreenEnabler3D` is the tool for this (already known to the project). Source: https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html
- [Guess] Running far characters at 10 to 15 updates per second with `MANUAL` mode and `advance()` should save CPU. Skeleton3D modifiers (IK) probably cost the most per character. Not measured.

**For us:** For far dwarves and monsters, set `callback_mode_process` to MANUAL and call `advance()` at a lower rate, for example when the dwarf is outside the camera distance band. Profile with the Profiler before and after. Keep IK only for near characters.

---

## 5. Threads

- [Sourced] Accessing objects from several threads is not always safe. Use a Mutex around shared data. Source: https://docs.godotengine.org/en/stable/tutorials/performance/using_multiple_threads.html
- [Sourced] Scene tree nodes are not thread-safe. Do not call functions or set properties on nodes from a worker thread. Use `call_deferred` or `set_deferred` to hand the work back to the main thread. Building a node tree off the active tree is fine. Source: https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html
- [Sourced] Rendering nodes (MeshInstance3D, Sprite) are not thread-safe. GDScript array resizing needs a Mutex. Navigation servers are thread-safe. RenderingServer and PhysicsServer are only safe on other threads when their separate-thread project settings are on. Source: https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html
- [Sourced] Loading a resource on a thread and adding it on the main thread is the recommended pattern. Source: same page.
- [Guess] `WorkerThreadPool` (`add_task`, `add_group_task`, `wait_for_task_completion`) is the built-in pool. Not checked on its class page in this pass.

**For us:** Build chunk meshes and data on worker threads, then hand the finished result to the main thread with `call_deferred`. Never touch scene nodes from a worker. Voxel Tools already threads its own work, so do not add a second pool on top without a test.

---

## 6. Finding slow frames

- [Sourced] Frame time budget: at 60 FPS one frame has 16.6 ms. The slowest part sets the pace, so speeding up a part that is not the bottleneck does nothing. Source: https://docs.godotengine.org/en/stable/tutorials/performance/general_optimization.html
- [Sourced] CPU and GPU run side by side. Frame time is set by the slower one. Test: drop the render resolution. If FPS rises, the GPU is the bottleneck. If it does not, it is the CPU. Source: same page (the scaling test itself is common practice, [Guess] on the exact setting name).
- [Sourced] Monitors: `Performance.get_monitor(Performance.TIME_PROCESS)` (seconds per frame), `TIME_PHYSICS_PROCESS`, `RENDER_TOTAL_DRAW_CALLS_IN_FRAME`. Source: https://docs.godotengine.org/en/stable/classes/class_performance.html
- [Sourced] `Performance.add_custom_monitor(id, callable, arguments, type)` adds your own number to the Monitor tab. A slash in the id sets the category. The value must be zero or positive. Source: same page.
- [Guess] Use percentiles, not averages. Log each frame time to a file and report the 1% low (the 99th percentile frame time) for each test run. An average FPS of 60 can hide stutter.
- [Guess] `RenderingServer.viewport_set_measure_render_time` and `viewport_get_measured_render_time_cpu/_gpu` exist for GPU timing. Their descriptions were not on the page I read (too long to load). Check the RenderingServer class page before use.

**For us:** Add a custom monitor for chunks rebuilt per second and dwarves updated per frame. Record 1% lows in each test. Test with a smaller window before changing code. Use the Profiler Self column (already known) for the CPU side.

---

## Sources read
- https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html
- https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html
- https://docs.godotengine.org/en/stable/tutorials/physics/physics_introduction.html
- https://docs.godotengine.org/en/stable/classes/class_area3d.html
- https://docs.godotengine.org/en/stable/classes/class_characterbody3d.html
- https://docs.godotengine.org/en/stable/classes/class_animationplayer.html
- https://docs.godotengine.org/en/stable/classes/class_geometryinstance3d.html
- https://docs.godotengine.org/en/stable/classes/class_performance.html
- https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html
- https://docs.godotengine.org/en/stable/tutorials/performance/general_optimization.html
- https://docs.godotengine.org/en/stable/tutorials/performance/using_multiple_threads.html
- https://docs.godotengine.org/en/stable/tutorials/performance/thread_safe_apis.html
- Not found (404): physics_interpolation and using_physics_interpolation pages; ANIMATION tree page path.
