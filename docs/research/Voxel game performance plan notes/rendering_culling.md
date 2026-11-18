# Rendering performance in Godot 4.7 (Forward+): culling, LOD, instancing, lights, overdraw

Context baseline (from the assignment, not a source): ~1100 draw calls, 1.3-1.8M triangles, GPU ~3.9 ms, frame ~5 ms on an RTX 3060 Ti; target is integrated GPUs.

## 1. "Only drawing what you look at": frustum culling, occlusion culling, portals, Horizon Zero Dawn

### Takeaway
Godot does frustum culling automatically, per node, using each node's AABB. A MultiMesh is culled as one whole object, so big spread-out MultiMeshes waste work. Occlusion culling is a CPU raster (Embree) of OccluderInstance3D shapes. Baked occluders must stay static, but ArrayOccluder3D can be filled from script, which makes runtime occluders for procedural or voxel terrain possible. It gains less in Forward+ than in Mobile because Forward+ already has a depth prepass. Rooms and Portals existed only in Godot 3.x and were not carried into 4.x. Horizon Zero Dawn's "view cone" is ordinary frustum culling plus occlusion tests against the previous frame's depth buffer, run on the GPU over 0.5-1.5M static instances. The idea transfers. The GPU-driven implementation does not, because Godot does not expose it.

### Cited Findings
**Frustum culling**
- Godot performs view frustum culling automatically. The docs say a naive renderer may try to draw 10x to 100x more than is visible. — [Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- A MultiMesh "is spatially indexed as a single object" and is not culled per instance. Instances spread far apart can reduce performance because every instance always renders. — [MultiMesh class](https://docs.godotengine.org/en/stable/classes/class_multimesh.html)
- `MultiMesh.custom_aabb`: "Setting this manually prevents costly runtime AABB recalculations." Instances can be arbitrary, so the user must provide the visibility AABB. This matters when a vertex shader moves instances, for example fireflies. — [MultiMesh class](https://docs.godotengine.org/en/stable/classes/class_multimesh.html)
- `MultiMesh.visible_instance_count` (default -1 = all) limits how many instances are drawn without resizing buffers. It is useful as a per-quality density knob. — [MultiMesh class](https://docs.godotengine.org/en/stable/classes/class_multimesh.html)
- Placing far-apart instances in separate MultiMeshInstance3D nodes improves LOD selection and lets frustum and occlusion culling work per node. In other words, chunk your MultiMeshes. — [Mesh LOD docs](https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html)
- Batched (merged) 3D objects cannot be culled individually, so off-screen parts of a combined mesh still render. This is the trade-off against merging. — [GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- For animated things off screen, VisibleOnScreenEnabler3D or VisibleOnScreenNotifier3D can pause or lower the update rate of distant or occluded meshes. — [Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)

**Occlusion culling (Godot 4)**
- How it works: occluder geometry is rasterized on the CPU into a low-resolution buffer with Embree. Occludee AABBs are tested against it, and an object is culled only if its AABB is fully occluded. — [Occlusion culling](https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html)
- It is most effective indoors with many small rooms. Large occluders such as walls work better than small props, and small objects get culled more easily than large ones. — [Occlusion culling](https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html)
- Forward+ already runs a depth prepass, so the gain there is smaller. Mobile has no depth prepass, so occlusion culling cuts shading overdraw more noticeably. It adds CPU cost and "may not be worth the added setup and CPU usage" in scenes with few culling opportunities. — [Occlusion culling](https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html)
- Settings live under Project Settings > Rendering > Occlusion Culling: Use Occlusion Culling, BVH Build Quality, and Occlusion Rays Per Thread. Runtime toggle: `get_tree().root.use_occlusion_culling`. — [Occlusion culling](https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html)
- Shapes: QuadOccluder3D, BoxOccluder3D, SphereOccluder3D, PolygonOccluder3D, and ArrayOccluder3D. ArrayOccluder3D cannot be edited in the editor but is "useful for procedural generation from a script". — [Occlusion culling](https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html)
- Moving an OccluderInstance3D, or its parent, forces a costly BVH rebuild. Toggling visibility is cheaper. If an occluder must move, use a primitive shape rather than a baked one. — [Occlusion culling](https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html)
- Baking takes opaque MeshInstance3D nodes in the editor. MultiMeshInstance3D and CSG need manually placed occluders. "Ignore Occlusion Culling" opts an occludee out. Too much simplification causes false culling of visible objects. — [Occlusion culling](https://docs.godotengine.org/en/stable/tutorials/3d/occlusion_culling.html)
- A third-party addon's docs note that the built-in bake "will bake all MeshInstances and ignore Terrain3D". Terrain addons that build their own meshes need their own occluder path. — [Terrain3D occlusion docs](https://terrain3d.readthedocs.io/en/latest/docs/occlusion_culling.html)
- In 2020, the Voxel Tools maintainer said better culling for chunk meshes was not possible without engine changes. That comment predates Godot 4. — [godot_voxel issue #150](https://github.com/Zylann/godot_voxel/issues/150)

**Rooms and Portals**
- Rooms and Portals (Room, RoomGroup, RoomManager, and Portal nodes, plus an optional PVS) was added in Godot 3.4 by lawnjelly (PR #46130). — [PR #46130](https://github.com/godotengine/godot/pull/46130); [3.x docs](https://docs.godotengine.org/en/3.5/tutorials/3d/portals/first_steps_with_rooms_and_portals.html)
- Godot 4.0 replaced it with raster occlusion culling. An open proposal asks to port portals and rooms to 4.x and argues they are cheaper on the CPU. — [godot-proposals #3920](https://github.com/godotengine/godot-proposals/issues/3920); a related proposal says geometric occluders "enjoyed far more usage compared to portals and rooms": [godot-proposals #5967](https://github.com/godotengine/godot-proposals/issues/5967)

**Horizon Zero Dawn / Decima (Guerrilla)**
- Decima tests objects against the previous frame's depth buffer. On PS4 it builds a conservative MIP chain from compressed depth tiles and reprojects bounding boxes against one MIP level. Small objects cost a 4-texel test. Guerrilla called it "not perfect, but good enough". It is used for the player camera, not for shadow maps. — [Decima Engine: Visibility in HZD (GCAP 2017)](https://www.slideshare.net/slideshow/decima-engine-visibility-in-horizon-zero-dawn/82371923)
- Static culling runs in GPU compute. Each thread does a filter, a parent/child LOD check, then frustum, size and occlusion tests. Scale is typically 500K-1.5M static instances and 10-30 MB of GPU data, and the main query takes about 1-2 ms. Batching the visibility output cut render-pipeline items by about 60-70%. — [Decima Visibility slides](https://www.slideshare.net/slideshow/decima-engine-visibility-in-horizon-zero-dawn/82371923)
- The well-known HZD "view cone" GIF shows frustum culling. A non-official explainer estimates that a 90-degree cone skips about 3/4 of vertex work outdoors. — [gist by nothings (non-official)](https://gist.github.com/nothings/913056601b56e5719cc987684a16544e)
- Guerrilla's talk "Streaming the World of Horizon Zero Dawn" covers world streaming. I found no transcript. — [Guerrilla](https://guerrilla-games.com/read/Streaming-the-World-of-Horizon-Zero-Dawn)

### Inferences
- In caves the terrain itself is the occluder. A practical plan is to generate a few coarse ArrayOccluder3D or BoxOccluder3D shapes per voxel chunk from solid regions, rebuilt only when a chunk is dug. The cost is a BVH rebuild per change, so batch these updates. In Forward+ the main gain is fewer draw calls and less CPU and vertex work, not less pixel shading.
- The cheapest wins are probably: (a) split decoration MultiMeshes per chunk with tight `custom_aabb`, so frustum and occlusion culling and LOD work; (b) visibility ranges on chunk decorations; (c) lower `visible_instance_count` on low presets.
- HZD's lesson is "cull hierarchically, cull small things early, and reuse last frame's depth". Godot's engine already does the frustum and occlusion parts. A game script can copy the "size test" with visibility_range_end on small props.

### Gaps
- No exact defaults found for Occlusion Rays Per Thread or BVH Build Quality, and no CPU cost per occluder.
- No cited source on runtime ArrayOccluder3D update cost per chunk, or on whether Voxel Tools (GDExtension) generates occluders. The repo docs need checking.
- No public numbers for the HZD streaming talk.

## 2. Visibility ranges, mesh LOD, HLOD, impostors

### Takeaway
Use automatic mesh LOD for imported meshes. It also works for MultiMeshInstance3D, but one LOD is chosen per node. Add visibility ranges with Fade Mode Disabled plus hysteresis margins for cheap culling of small props by distance, and `visibility_parent` for HLOD. Alpha fades force transparency and cost performance, while dithering is the cheaper fade.

### Cited Findings
- `visibility_range_begin` / `_end` hide an instance when the camera is closer or farther than the given distance to its AABB center. `_begin_margin` / `_end_margin` set transitions. Fade modes: Disabled (instant, margins act as hysteresis, the fastest), Self (alpha-blend, forces transparency), and Dependencies (for HLOD, also transparent). — [Visibility ranges](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html)
- `visibility_parent` for HLOD: children are hidden while the parent is visible within its range, and only after the parent fully fades out. The parent must be a GeometryInstance3D but need not be the scene-tree parent. Nodes hidden through Visible are excluded from the dependency tree. — [Visibility ranges](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html)
- A merged far mesh (HLOD) cuts draw calls while keeping culling up close. Per-pixel shading is often the GPU bottleneck and LOD does not reduce it, so give distant LODs simpler materials (no normal maps, rim, clearcoat, SSS, refraction, or proximity fade). — [Visibility ranges](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html)
- Dithering is faster than alpha fade and has no sorting glitches, but it needs a separate material per LOD: set margins to 0 and use "Object Dither" distance fade on the materials. — [Visibility ranges](https://docs.godotengine.org/en/stable/tutorials/3d/visibility_ranges.html)
- Automatic mesh LOD is generated on import with meshoptimizer, by default for glTF, .blend, Collada and FBX. It works with MeshInstance3D, MultiMeshInstance3D, GPUParticles3D and CPUParticles3D. Selection is screen-space, so FOV and resolution are accounted for. — [Mesh LOD](https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html)
- `mesh_lod_threshold`: Project Settings > Rendering > Mesh LOD > LOD Change > Threshold Pixels (default 1.0 = "perceptually lossless"), changed at runtime with `get_viewport().mesh_lod_threshold`. Per object, `GeometryInstance3D.lod_bias` above 1 delays LOD changes and below 1 advances them. — [Mesh LOD](https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html)
- In a MultiMesh, all instances use one LOD, chosen from the AABB point nearest the camera. This is another reason to chunk. — [Mesh LOD](https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html)
- The official graphics settings demo sets `mesh_lod_threshold` to 8.0 (Very Low), 4.0 (Low, intended), 2.0 (Medium), 1.0 (High) and 0.0 (Ultra). — [godot-demo-projects graphics_settings](https://github.com/godotengine/godot-demo-projects/blob/master/3d/graphics_settings/settings.gd)
- Impostors (pre-rendered views) and billboards are cheap at a distance, but stacked transparent quads eat fill rate. Impostors are "complex to set up". — [Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- Lights and decals have their own Distance Fade, and the docs recommend combining it with LOD and visibility ranges. — [Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)

### Inferences
- The decoration meshes are built in Blender and exported as glTF, so they get automatic LODs for free. Check that the import generates them. Measure with the "Disable Mesh LOD" debug draw mode and View Information.
- Voxel terrain LOD is a separate system (VoxelLodTerrain), not Godot's mesh LOD.
- For small cave props, a visibility_range_end of about 20-40 m with Fade Disabled plus a 2-5 m margin is the cheapest big draw-call cut. These numbers are a judgment call and need tuning.

### Gaps
- The docs do not cover `ArrayMesh`/`ImporterMesh.generate_lods()` for procedural meshes, or shadow-pass LOD behaviour.
- No quantitative LOD gain figures in the official docs.

## 3. MultiMesh vs many MeshInstance3D, batching, GPU animation, node costs

### Takeaway
Forward+ auto-instances MeshInstance3D nodes that share the same mesh and opaque or alpha-scissor material. Alpha-blended materials are not auto-instanced and should use MultiMesh. Material count matters more than polycount. Vertex work is cheap on desktop but costly on mobile and iGPUs when triangles are smaller than a pixel.

### Cited Findings
- Automatic instancing works only in Forward+, for MeshInstance3D nodes sharing the same mesh and material, and only with opaque or alpha-tested materials. Alpha-blended and depth-prepass materials are not auto-instanced, so use MultiMesh for those. — [Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- MultiMesh draws "many thousands" of instances in one draw call, which suits grass, flocks and particles. — [Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html); [MultiMesh class](https://docs.godotengine.org/en/stable/classes/class_multimesh.html)
- MultiMesh caveats: all instances share one object's light limit, so instances past the limit get no lighting (relevant in Mobile and Compatibility, which allow 8 omni + 8 spot per mesh). Blend shapes are ignored. The deprecated `transform_array` and similar accessors are "very slow". `use_custom_data` gives `INSTANCE_CUSTOM` in shaders, packed to 16 bits in Compatibility. — [MultiMesh class](https://docs.godotengine.org/en/stable/classes/class_multimesh.html)
- Fewer materials renders faster: 20,000 objects with 100 materials is much faster than with 20,000 materials. StandardMaterial3D instances with the same enabled features share a shader. Texture atlases help. — [GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- Vertex cost is low on modern PC GPUs and "polycount matters much less than many artists assume". Still, avoid triangles smaller than a pixel. Skinning and morphs add vertex cost. — [GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- Joining meshes at runtime is too expensive in 3D. Join static meshes ahead of time. — [GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- Skinning is costly. Lower the polycount of animated models, limit how many are on screen, and lower the animation rate for distant ones. — [Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)

### Inferences
- Fireflies moved in a vertex shader are the right pattern: no per-frame CPU work. Their MultiMesh needs a `custom_aabb` that covers the whole motion range so culling stays correct.
- Each voxel chunk is at least one draw call per material, shadow pass included. Voxel Tools says block size 32 instead of 16 cuts draw calls (see section 7).

### Gaps
- No cited benchmark for MeshInstance3D node count overhead vs MultiMesh in 4.x (CPU per node).

## 4. Lights and shadows

### Takeaway
Forward+ handles many omni lights cheaply through clustering (default 512 clustered elements in view). Shadows are the real cost: an omni cube shadow is 6 renders, dual paraboloid is 2, and a spot light is 1. Use Distance Fade on every crystal light, shadows off on small lights, and emissive materials plus glow instead of real lights where possible. Mobile and Compatibility cap lights at 8 omni + 8 spot per mesh, which hits big voxel chunks and MultiMeshes hard.

### Cited Findings
- Forward+ has no fixed cap, but the default is 512 clustered elements (omni, spot, decals, reflection probes) in view, adjustable in Rendering > Limits > Cluster Builder > Max Clustered Elements. Mobile allows 8 omni + 8 spot per mesh and 256 + 256 per view, not changeable. Compatibility allows 8 + 8 per mesh, adjustable through Rendering > Limits > OpenGL (Max Renderable Elements, Max Lights per Object) at the cost of compile time and speed. — [Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html); [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- Going over the limits makes lights pop. Distance Fade (`distance_fade_enabled`, `_begin`, `_length`, `_shadow`) culls the light after begin + length so it is "no longer sent to the shader", and the shadow can fade sooner. Splitting large meshes improves light culling. — [Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- Omni Cube shadows (the default) render 6 faces, while Dual Paraboloid renders 2 and is faster but can deform. Spot shadows are "significantly faster" (1 texture). Directional PSSM with 4 splits renders an object up to 5 times. Set Max Distance. — [Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- The positional shadow atlas has 4 quadrants, and the default supports 88 shadowed lights (4+4+16+64). Shadows re-render only when their slot changes or a caster changes. The default shadow map size is 4096, and the docs suggest 2048 for low end. Default filter is Soft Low, and Soft Very Low or Hard is cheaper. 16-bit depth is recommended, and 32-bit is significantly slower. PCSS (`light_size`/`light_angular_distance` > 0) is expensive. — [Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- Small or distant omni and spot lights often lose little visually without shadows. Smaller shadow maps help. — [GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- Light bake mode Static plus LightmapGI makes lights "much faster". Emissive materials can replace area lights. Suggested split: DirectionalLight Dynamic, most omni and spot lights Static. — [Lights and shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html); [Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- A light's Volumetric Fog Energy set to 0 slightly improves performance and avoids ghosting on short-lived lights. — [Volumetric fog](https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html)
- SDFGI is "relatively demanding on the GPU" and not suited to low end. `rendering/global_illumination/gi/use_half_resolution` helps. `sdfgi_use_occlusion` costs performance. A lower `sdfgi_min_cell_size` makes updates heavier and causes stutter on fast camera moves. — [Environment class](https://docs.godotengine.org/en/stable/classes/class_environment.html)
- SDFGI and VoxelGI exist only in Forward+. — [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- Demo presets: directional atlas 512/1024/2048/4096/8192, positional atlas 0 (off) to 8192, shadow filter Hard to Soft Ultra, applied through `RenderingServer.directional_shadow_atlas_set_size()`, `get_viewport().positional_shadow_atlas_size`, and `directional_/positional_soft_shadow_filter_set_quality()`. — [graphics_settings demo](https://github.com/godotengine/godot-demo-projects/blob/master/3d/graphics_settings/settings.gd)

### Inferences
- Fully destructible terrain rules out LightmapGI for terrain, and baked VoxelGI goes stale when terrain changes. So GI options are SDFGI (only on high presets) or none plus a tuned ambient light. Crystal glow can be emission plus glow, with a real OmniLight only for the few nearest crystals: distance fade begin about 15-25 m, shadows off, fog energy 0. Those numbers are a judgment call.
- On Mobile and Compatibility, a voxel chunk or decoration MultiMesh touched by more than 8 crystal lights loses lights. Small chunks and distance-faded lights matter even more there.

### Gaps
- No cited per-light GPU cost numbers for Forward+ clustered lights (cost per unshadowed omni).
- No cited numbers for SDFGI, VoxelGI or LightmapGI cost in ms.

## 5. Transparency, overdraw, particles, volumetric fog, post effects

### Takeaway
Transparency is drawn back to front with no Z-buffer help, so every layer costs fill rate. Volumetric fog cost scales with Volume Size x Volume Depth (froxels) and is Forward+ only. SSR, SSIL, SDFGI and SSAO are the main post-effect costs, and SSR, SSIL and volumetric fog are Forward+ only.

### Cited Findings
- Transparent objects are sorted back to front, cannot be sorted by material, and cost fill rate for every layer. Keep transparent areas small, and split partly transparent objects into a separate surface. Sometimes more opaque geometry is faster than transparency tricks. — [GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html); [Optimizing 3D performance](https://docs.godotengine.org/en/stable/tutorials/performance/optimizing_3d_performance.html)
- Fill-rate test: disable V-Sync and compare FPS in a large window and a tiny window. A big gain means fill-rate bound. For shaded particles, consider forcing vertex shading. Variable rate shading can cut shading cost. — [GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- Volumetric fog project settings (Rendering > Environment > Volumetric Fog): Volume Size (froxel X/Y, smaller = faster), Volume Depth (slices, fewer = faster but artifacts during motion), and Use Filter (blur). Temporal reprojection costs "minimal" but ghosts. Length can be reduced at no performance cost. GI Inject and Ambient Inject each have a small cost when above 0. Keep density textures at 64^3 or smaller. — [Volumetric fog](https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html)
- Cheaper alternatives: regular depth and height fog, and quad-based fake fog (works in Mobile and Compatibility, generally cheaper, but has sorting issues). — [Volumetric fog](https://docs.godotengine.org/en/stable/tutorials/3d/volumetric_fog.html)
- SSR is "slower" than VoxelGI or ReflectionProbe reflections, and `ssr_max_steps` higher is slower. The demo presets use 8/32/56 steps. — [Environment class](https://docs.godotengine.org/en/stable/classes/class_environment.html); [graphics_settings demo](https://github.com/godotengine/godot-demo-projects/blob/master/3d/graphics_settings/settings.gd)
- The SSAO and SSIL quality APIs are `RenderingServer.environment_set_ssao_quality(quality, half_size, adaptive_target, blur_passes, fadeout_from, fadeout_to)`. The demo uses `(LEVEL, true, 0.5, 2, 50, 300)` for SSAO and `(LEVEL, true, 0.5, 4, 50, 300)` for SSIL. Glow low uses `environment_glow_set_use_bicubic_upscale(false)`. Volumetric fog low uses `environment_set_volumetric_fog_filter_active(false)`. — [graphics_settings demo](https://github.com/godotengine/godot-demo-projects/blob/master/3d/graphics_settings/settings.gd)
- Post-processing and shadows are costly fragment work and should be tested on target hardware. — [GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- Glow works in all renderers. Compatibility uses a simpler glow optimized for low end. — [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html); [Environment class](https://docs.godotengine.org/en/stable/classes/class_environment.html)

### Inferences
- "Volumetric-looking fog" on potato presets should drop to depth and height fog or quad fake fog. On medium, use a lower Volume Size and Depth with the filter off.
- If lowering resolution gives a big FPS gain on an iGPU, the game is fill-rate bound (fog, SSAO, transparent glow sprites). If not, it is bound by draw calls or CPU.

### Gaps
- No cited ms costs for SSAO, SSIL, SSR or volumetric fog at given settings. No defaults confirmed for volume_size/volume_depth (commonly 64 and 64, unverified).

## 6. Renderers: Forward+ vs Mobile vs Compatibility on low-end PCs

### Takeaway
For old and low-end PCs, Compatibility (OpenGL) is fastest and Forward+ is slowest. Compatibility loses volumetric fog, SDFGI, VoxelGI, SSIL, SSR, TAA and FSR. Mobile also loses SSAO. A low preset could ship Compatibility as a separate launch option, but the renderer cannot be switched at runtime without restarting.

### Cited Findings
- Compatibility has low base cost and high scaling cost. Mobile is medium on both. Forward+ has the highest base cost and lowest scaling cost and is "the slowest renderer on old and low-end hardware". Mobile is "slower than Compatibility" on old and low-end hardware. — [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- Feature table: SDFGI, VoxelGI, volumetric fog, SSIL, SSR, TAA and FSR2 are Forward+ only. SSAO works in Compatibility and Forward+ but not Mobile. Glow works in all. Compatibility lacks particle trails and particle SDF collision. — [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- Since 4.4, Forward+ and Mobile fall back Vulkan <-> D3D12 and then to Compatibility if neither works (Rendering > Rendering Device > Fallback to OpenGL 3). — [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- Switching renderers may need manual scene, lighting and environment changes. — [Renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- The official docs suggest designing for the lowest common denominator and adding extras on stronger hardware. — [GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)

### Inferences
- A practical approach is a "Potato mode" launch option that restarts the game with the Compatibility renderer. The renderer is picked at startup, for example with a command-line `--rendering-method gl_compatibility` or a per-platform project setting override. This approach is not confirmed in the fetched docs. The game would then use fake fog, no SSIL or SSR, and emissive crystals with few real lights.

### Gaps
- No cited benchmarks of Forward+ vs Compatibility on Intel or AMD iGPUs.
- Not confirmed in the fetched pages: command-line `--rendering-method`, and whether the renderer can be changed by settings without a restart.

## 7. Resolution scaling, anti-aliasing, settings menu presets

### Takeaway
`scaling_3d_scale` is the biggest single lever for iGPUs: 0.5 renders about a quarter of the pixels. FSR 1 and FSR 2.2 are Forward+ only, and on very slow GPUs FSR's own cost can outweigh its benefit. The official graphics-settings demo is a ready template for preset menus.

### Cited Findings
- Modes: Bilinear (all renderers, the default), FSR 1.0 (Forward+, slower than bilinear but higher quality, and on very slow GPUs its cost may outweigh the benefit), and FSR 2.2 (Forward+, the slowest, includes its own TAA so "Use TAA" is ignored, added in 4.2). — [Resolution scaling](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html)
- `scaling_3d_scale` is per axis: at 1080p, 0.5 is 0.52 MPix vs 2.07 MPix native. If lowering it doesn't help, the bottleneck is elsewhere (draw calls, SDFGI, SSAO, SSR). — [Resolution scaling](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html)
- `fsr_sharpness`: 0.0 is the sharpest and 2.0 the least, default 0.2. Automatic mipmap bias is `log2(scale) + custom`, with -0.25 for FXAA, -0.5 for TAA, and -0.75 for both. Manual `texture_mipmap_bias` is recommended between -0.5 and 0. — [Resolution scaling](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html)
- Demo settings API: `get_viewport().scaling_3d_mode` (BILINEAR/FSR/FSR2), `scaling_3d_scale`, `fsr_sharpness`, `msaa_3d` (off, 2x, 4x, 8x), `use_taa`, `screen_space_aa` (FXAA, and SMAA in newer versions), VSync via `DisplayServer.window_set_vsync_mode`, `Engine.max_fps`, shadow atlas and filter, `mesh_lod_threshold`, SSR, SSAO, SSIL, SDFGI half-res, glow bicubic, volumetric fog filter, and Very Low to Ultra presets. On Compatibility the demo disables FSR, TAA, screen-space AA, SDFGI, SSAO, SSR, SSIL and volumetric fog. — [graphics_settings demo](https://github.com/godotengine/godot-demo-projects/blob/master/3d/graphics_settings/settings.gd)
- The docs recommend exposing both resolution scale and graphics settings in menus. — [Resolution scaling](https://docs.godotengine.org/en/stable/tutorials/3d/resolution_scaling.html)

### Inferences (suggested preset menu, based on the levers above)
- Potato or Low: scale 0.5-0.67 bilinear (or FSR1 if it measures faster), no MSAA or TAA, FXAA optional, shadows off or 1024 Hard, directional shadow max distance short, positional atlas 0-1024, SSAO, SSIL, SSR, SDFGI and volumetric fog off, depth fog instead, glow low, `mesh_lod_threshold` 4-8, MultiMesh `visible_instance_count` lowered, prop visibility_range_end shorter, crystal light distance fade short and few lights, Max FPS cap.
- Medium: scale 0.77 with FSR1, shadows 2048 Soft Very Low, SSAO low half-size, volumetric fog with a small Volume Size and Depth and the filter off, LOD threshold 2.
- High: scale 1.0 or FSR2 0.77, TAA or MSAA 2x, shadows 4096 Soft Low, SSAO medium, volumetric fog on, LOD threshold 1.
- Ultra: SSIL, SDFGI (if used), 8192 shadows, LOD threshold 0.

### Voxel Tools notes (relevant to draw calls)
- Voxel terrain makes many unique meshes, which means many draw calls and lots of culling work. To reduce it: lower the view distance, lower the LOD distance (VoxelLodTerrain), or raise the mesh block size 16 -> 32 (fewer draw calls, slower edits). On Vulkan, destroying many mesh buffers causes CPU spikes when moving fast. Block size 32 and lower LOD distance help. — [Voxel Tools performance](https://voxel-tools.readthedocs.io/en/latest/performance/)

### Gaps
- No cited numbers for the ms cost of FSR1 or FSR2 on iGPUs, or MSAA vs TAA vs FXAA cost in 4.7.
- No SMAA confirmation in the fetched sources (believed added around 4.5, unverified).
