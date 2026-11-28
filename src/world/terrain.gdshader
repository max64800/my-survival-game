shader_type spatial;
// Paints the dig-anywhere rock. Each voxel has a material number (see mat.gd):
// 0 moss, 1 stone, 2 dirt, 3 copper ore, 4 border rock, 5 clay, 6 tin ore,
// 8 mycelium, 9 silver ore, 11 amberrock, 13 sporestone, 14 old dwarf stone (a dungeon's walls), 15 the world's edge.
//
// The look: hand-painted textures (tools/art/bake_terrain_looks.py), 4 slices (looks)
// per material number in two texture arrays. Smooth terrain has no UV "wrapping paper",
// so each texture is projected from 3 sides (top, front, side) and blended: "triplanar".
// The albedo's alpha channel marks veins/specks that glow (ores, border rock, spores).

uniform sampler2DArray albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2DArray normal_tex : filter_linear_mipmap_anisotropic, repeat_enable;
const int LOOKS = 4;  // looks per material in the arrays: slice = material * 4 + look (bake_terrain_looks.py)
uniform float tex_scale = 0.33;  // one texture tile every ~3 m
uniform float bump_strength = 1.0;
uniform float flat_shading = 0.0;  // 1 = old low-poly facets
// F766: rock between the camera and the dwarf fades to a see-through speckle (set every frame by the camera,
// Dwarf._place_camera). see_radius 0 = off. Only rock in a thin tube from the camera to his chest, and not right
// next to him, so the floor under his feet always stays.
uniform vec3 see_from = vec3(0.0);
uniform vec3 see_to = vec3(0.0);
uniform float see_radius = 0.0;
// F870 (owner, Nov 25: "ore glints in lantern light"): your own lantern (Lantern._process): xyz = where, w = its reach
// (0 = no lantern / empty). Copper and tin veins near it get tiny twinkling sparkles.
global uniform vec4 lantern_at;

// Glow colour of the alpha-marked veins, per material number.
const vec3 GLOW[16] = vec3[16](
	vec3(0.0), vec3(0.0), vec3(0.0),
	vec3(0.95, 0.42, 0.12) * 0.45,  // 3 copper
	vec3(0.40, 0.20, 0.75) * 1.2,   // 4 border rock
	vec3(0.0),
	vec3(0.80, 0.84, 0.88) * 0.3,   // 6 tin (a soft grey glint, dimmer than copper)
	vec3(0.0), vec3(0.0),
	vec3(0.75, 0.85, 1.0) * 0.6,    // 9 silver
	vec3(0.0), vec3(0.0), vec3(0.0),
	vec3(0.65, 0.30, 0.95) * 0.6,   // 13 sporestone specks
	vec3(0.0), vec3(0.0));
// How rough (matte) each material is. Lower = a little shine under the lantern.
const float ROUGH[16] = float[16](0.95, 0.82, 0.93, 0.8, 0.75, 0.68, 0.8, 0.8,
	0.92, 0.8, 0.8, 0.7, 0.8, 0.84, 0.8, 0.85);
// Ores: the veins are metal.
const float METAL[16] = float[16](0.0, 0.0, 0.0, 0.85, 0.0, 0.0, 0.8, 0.0,
	0.0, 0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);

varying vec4 v_indices;
varying vec4 v_weights;
varying vec3 v_world;
varying vec3 v_wnormal;

vec4 decode_8bit_vec4(float v) {
	uint i = floatBitsToUint(v);
	return vec4(float(i & 0xffu), float((i >> 8u) & 0xffu), float((i >> 16u) & 0xffu), float((i >> 24u) & 0xffu));
}

float hash(vec3 p) {
	p = fract(p * 0.3183099 + 0.1);
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash(i + vec3(0, 0, 0)), hash(i + vec3(1, 0, 0)), f.x),
				   mix(hash(i + vec3(0, 1, 0)), hash(i + vec3(1, 1, 0)), f.x), f.y),
			   mix(mix(hash(i + vec3(0, 0, 1)), hash(i + vec3(1, 0, 1)), f.x),
				   mix(hash(i + vec3(0, 1, 1)), hash(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}

// Glow-worm stars (owner F217/F232). Each cell of a 3D grid `cell` metres wide may hold one tiny glowing ball (`keep` =
// how many do); where the rock passes through a ball it shows a small round spot, the same from any angle (round 3:
// dots painted from above were stretched into streaks on sloping rock). Sharp edge, no blur; each twinkles slowly.
const vec3 STAR_COLOR = vec3(0.4, 0.88, 1.0);
uniform float star_brightness = 3.2;
// The huge first cavern (layout 4, owner F260): its ceiling is all stars, with extra snakes. star_radius 0 = none.
uniform vec3 star_center = vec3(0.0);
uniform float star_radius = 0.0;
uniform float star_snakes = 1.0;
// Where you wake up: no stars at all (owner, Nov 19). quiet_radius 0 = nowhere.
uniform vec3 quiet_center = vec3(0.0);
uniform float quiet_radius = 0.0;
// The rock bridges (owner, Nov 18: glowing veins "under the bridges as well"): a = one end's top + width, b = the other
// end's top + thickness. world.gd sends the 16 nearest to the camera, twice a second.
uniform int bridge_count = 0;
// Where the glowing veins gather: tunnel mouths that lead on to another cave (owner, Nov 18: "helping the player find
// where to go next... not at dead ends"). world.gd sends the 16 nearest the camera.
uniform int guide_count = 0;
uniform vec3 guide_pts[16];

float near_guide(vec3 p) {
	float g = 0.0;
	for (int i = 0; i < 16; i++) {
		if (i >= guide_count) {
			break;
		}
		g = max(g, 1.0 - smoothstep(3.5, 7.0, distance(p, guide_pts[i])));
	}
	return g;
}
uniform vec4 bridge_a[16];
uniform vec4 bridge_b[16];

// How much p is on the underside of a rock bridge (0..1).
float under_bridge(vec3 p) {
	for (int i = 0; i < 16; i++) {
		if (i >= bridge_count) {
			break;
		}
		vec2 a = bridge_a[i].xz;
		vec2 ab = bridge_b[i].xz - a;
		float t = clamp(dot(p.xz - a, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
		float side = length(p.xz - (a + ab * t));
		float top = mix(bridge_a[i].y, bridge_b[i].y, t);
		if (side < bridge_a[i].w * 0.8 && p.y < top - 0.3 && p.y > top - bridge_b[i].w * 3.5) {
			return 1.0;
		}
	}
	return 0.0;
}  // extra snakes there (1 in the huge cavern, 2 in a normal first cavern)  // (owner: brighter; moving the camera smears tiny points a little)

vec3 star_layer(vec3 p, float cell, float radius, float keep) {
	vec3 q = p / cell;
	vec3 c = floor(q);
	float h = hash(c + vec3(3.7));
	if (h > keep) {
		return vec3(0.0);
	}
	vec3 at = c + 0.2 + 0.6 * vec3(hash(c + vec3(1.3)), hash(c + vec3(8.1)), hash(c + vec3(4.4)));
	float d = length(q - at) * cell;  // metres from the ball's middle
	float r = radius * (0.6 + 0.8 * hash(c + vec3(5.5)));
	float aa = max(fwidth(d), 0.0005);  // one pixel of soft edge, no more
	float spot = 1.0 - smoothstep(r - aa, r + aa, d);
	float twinkle = 0.7 + 0.3 * sin(TIME * (0.5 + 1.2 * hash(c + vec3(9.9))) + h * 40.0);
	// mostly teal-blue, some green, a few pale (owner: "a little bit different colour sometimes, some green dots")
	float hue = hash(c + vec3(2.2));
	// (round 2: greener greens, more of them, and purple ones, both a bit brighter so they stand out)
	vec3 tone = hue < 0.55 ? STAR_COLOR : (hue < 0.82 ? vec3(0.3, 1.0, 0.35) * 1.5 : (hue < 0.95 ? vec3(0.78, 0.32, 1.0) * 1.9 : vec3(0.85, 0.95, 1.0)));
	return tone * spot * twinkle * (0.55 + 0.45 * h / keep);
}

// The light snake (owner, Nov 17: "a snake that randomly goes around the sky... lights up some of the pieces"): each
// 40 m square of ceiling has one glowing head wandering on its own slow looping path; behind it a fading trail. Returns
// how much the snake lights this point (1 = right on the head). From the position and TIME only: the same everywhere.
float snake(vec3 p, float which) {
	vec2 cell = floor(p.xz / 40.0);
	vec2 mid = (cell + 0.5) * 40.0;
	float h1 = hash(vec3(cell, 11.0 + which * 7.0));
	float h2 = hash(vec3(cell, 23.0 + which * 7.0));
	float speed = 0.05 + 0.05 * h1;  // a full loop takes a few minutes
	float best = 1e9;
	float along = 0.0;
	vec2 prev = vec2(0.0);
	for (int k = 0; k < 14; k++) {
		float t = TIME * speed - float(k) * 0.035 + h2 * 50.0;
		// a wandering loop: two slow waves each way, so it goes back and forth, here and there
		vec2 q = mid + vec2(sin(t * 1.7) * 11.0 + sin(t * 3.1 + 1.3) * 5.0, sin(t * 1.3 + 2.0) * 11.0 + cos(t * 2.7) * 5.0);
		if (k > 0) {
			vec2 ab = q - prev;
			float u = clamp(dot(p.xz - prev, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
			float d = length(p.xz - (prev + ab * u));
			if (d < best) {
				best = d;
				along = (float(k - 1) + u) / 13.0;  // 0 = head, 1 = tail end
			}
		}
		prev = q;
	}
	float width = 1.6 * (1.0 - 0.5 * along);  // (round 3: no line of its own; a wider band of stars lights up)
	return (1.0 - smoothstep(0.0, width, best)) * (1.0 - along);
}

// One material, projected from 3 sides. Returns colour+glow mask, and a world-space normal.
void triplanar(float layer, vec3 p, vec3 bw, vec3 wn, out vec4 alb, out vec3 nrm) {
	vec2 uvx = p.zy;
	vec2 uvy = p.xz;
	vec2 uvz = p.xy;
	alb = texture(albedo_tex, vec3(uvx, layer)) * bw.x
		+ texture(albedo_tex, vec3(uvy, layer)) * bw.y
		+ texture(albedo_tex, vec3(uvz, layer)) * bw.z;
	vec3 tx = texture(normal_tex, vec3(uvx, layer)).xyz * 2.0 - 1.0;
	vec3 ty = texture(normal_tex, vec3(uvy, layer)).xyz * 2.0 - 1.0;
	vec3 tz = texture(normal_tex, vec3(uvz, layer)).xyz * 2.0 - 1.0;
	tx.xy *= bump_strength;
	ty.xy *= bump_strength;
	tz.xy *= bump_strength;
	// "Whiteout" blend: bend the surface normal by each projection's bumps.
	tx = vec3(tx.xy + wn.zy, abs(tx.z) * wn.x);
	ty = vec3(ty.xy + wn.xz, abs(ty.z) * wn.y);
	tz = vec3(tz.xy + wn.xy, abs(tz.z) * wn.z);
	nrm = tx.zyx * bw.x + ty.xzy * bw.y + tz.xyz * bw.z;
}

void vertex() {
	v_indices = decode_8bit_vec4(CUSTOM1.x);
	v_weights = decode_8bit_vec4(CUSTOM1.y) / 255.0;
	v_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_wnormal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	if (see_radius > 0.0) {
		vec3 ab = see_to - see_from;
		float t = clamp(dot(v_world - see_from, ab) / max(dot(ab, ab), 0.0001), 0.0, 1.0);
		float d = length(v_world - (see_from + ab * t));
		float fade = (1.0 - smoothstep(see_radius * 0.55, see_radius, d)) * (1.0 - smoothstep(0.7, 0.9, t));
		// A 4x4 checker of thresholds: fading = more and more of the dots left out (no see-through sorting needed).
		ivec2 q = ivec2(FRAGCOORD.xy) % 4;
		int bayer[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
		if (fade * 0.85 > (float(bayer[q.y * 4 + q.x]) + 0.5) / 16.0) {
			discard;
		}
	}
	vec4 w = v_weights / (v_weights.x + v_weights.y + v_weights.z + v_weights.w + 0.00001);
	vec3 wn = normalize(v_wnormal);
	if (flat_shading > 0.5) {
		wn = normalize((INV_VIEW_MATRIX * vec4(normalize(cross(dFdy(VERTEX), dFdx(VERTEX))), 0.0)).xyz);
	}
	// Sharper blend between the 3 projections = less smeary rock.
	vec3 bw = pow(abs(wn), vec3(4.0));
	bw /= (bw.x + bw.y + bw.z);
	vec3 p = v_world * tex_scale;

	vec3 col = vec3(0.0);
	vec3 emit = vec3(0.0);
	vec3 nrm = vec3(0.0);
	float rough = 0.0;
	float metal = 0.0;
	float ore = 0.0;  // how much copper / tin vein is here (for the glints)
	float ore_tin = 0.0;
	float ore_vein = 0.0;  // ... and how much of it is the shiny vein / flakes
	float ids[4] = float[4](v_indices.x, v_indices.y, v_indices.z, v_indices.w);
	float ws[4] = float[4](w.x, w.y, w.z, w.w);
	// Which of the 4 looks of each material shows here (owner F213): big patches from world-position noise, so every
	// computer shows the same; the last 25% of each patch fades into the next look.
	float lv = clamp((vnoise(v_world * 0.07 + vec3(40.0, 13.0, 71.0)) - 0.2) / 0.6, 0.0, 0.9999) * float(LOOKS);
	float look = floor(lv);
	float look_mix = smoothstep(0.75, 1.0, fract(lv)) * step(look, float(LOOKS) - 1.5);
	for (int k = 0; k < 4; k++) {
		if (ws[k] < 0.02) {
			continue;  // skip materials that barely show (saves texture reads)
		}
		int id = clamp(int(ids[k] + 0.5), 0, 15);
		vec4 a;
		vec3 n;
		float slice = float((id == 14 ? 1 : (id == 7 ? 2 : id)) * LOOKS) + look;  // old dwarf stone: the stone look, darker (below); 7 the road: dirt under its sand
		triplanar(slice, p, bw, wn, a, n);
		if (look_mix > 0.01) {  // only where two looks meet: read the next look too
			vec4 a2;
			vec3 n2;
			triplanar(slice + 1.0, p, bw, wn, a2, n2);
			a = mix(a, a2, look_mix);
			n = mix(n, n2, look_mix);
		}
		if (id == 14) {
			a.rgb *= vec3(0.62, 0.6, 0.6);
		}
		if (id == 7) {
			// The old road (F940, owner Nov 27: "a sand road", was grey bricks F900, dirt before that): packed pale sand
			// over the earth, fine grain, faint wind ripples and a few dark pebbles, a little darker where feet wore it
			// down the middle. On the floor only (the sides of a bump stay earth).
			float grain = vnoise(v_world * 9.0) * 0.6 + vnoise(v_world * 23.0) * 0.4;
			float ripple = sin(dot(v_world.xz, vec2(2.3, 1.1)) * 3.0 + vnoise(v_world * 1.3) * 5.0) * 0.5 + 0.5;
			float blotch = vnoise(v_world * 0.6);
			vec3 sand = mix(vec3(0.70, 0.60, 0.43), vec3(0.80, 0.70, 0.52), blotch);
			sand *= mix(0.88, 1.06, grain) * mix(0.96, 1.03, ripple);
			float pebble = step(0.86, vnoise(v_world * 6.0)) * step(0.5, hash(floor(v_world * 6.0)));
			sand = mix(sand, sand * vec3(0.55, 0.52, 0.5), pebble);
			float up = smoothstep(0.5, 0.8, wn.y);
			a.rgb = mix(a.rgb, sand, up);
			a.a = 0.0;
			vec3 sn = normalize(wn + vec3(vnoise(v_world * 23.0) - 0.5, 0.0, vnoise(v_world * 23.0 + 7.0) - 0.5) * 0.25);
			n = normalize(mix(n, sn, up));
		}
		if (id == 3 || id == 6) {
			// F966 (owner, Nov 28: "copper and tin ore are hard to spot", copper was never seen): chunky lopsided nuggets
			// painted over the rock, about a hand wide. Copper: orange metal ringed with a green-blue crust (real copper
			// rock wears one); tin: bigger silver-grey chips. The nuggets are the shiny, faintly glowing vein.
			bool cu = id == 3;
			float sc = cu ? 5.0 : 6.5;
			vec3 q = v_world * sc + vec3(vnoise(v_world * 13.0 + vec3(3.1, 0.0, 8.0)) * 0.5);
			float nv = vnoise(q + (cu ? vec3(11.0, 5.0, 2.0) : vec3(-7.0, 19.0, 4.0)));
			float vein = vnoise(v_world * 0.9 + vec3(5.0, 2.0, 9.0));  // the chips gather in bands, with plain rock between
			float cut = (cu ? 0.70 : 0.72) - 0.12 * smoothstep(0.45, 0.7, vein);
			float chunk = smoothstep(cut, cut + 0.02, nv);
			float rim = smoothstep(cut - 0.08, cut - 0.03, nv) * (1.0 - chunk);
			float lum = dot(a.rgb, vec3(0.299, 0.587, 0.114));
			float facet = hash(floor(q * 2.5)) * 0.35;  // flat chipped faces, each a little lighter or darker
			vec3 metal_c = cu ? vec3(0.90, 0.46, 0.18) : vec3(0.60, 0.63, 0.68);
			vec3 crust_c = cu ? vec3(0.20, 0.60, 0.50) : vec3(0.36, 0.38, 0.41);
			a.rgb = mix(a.rgb, crust_c * (0.75 + 0.6 * lum), rim * (cu ? 0.9 : 0.6));
			a.rgb = mix(a.rgb, metal_c * (0.6 + facet + 0.3 * lum), chunk);
			a.a = max(a.a, chunk);
		}
		col += a.rgb * ws[k];
		emit += GLOW[id] * a.a * ws[k];
		nrm += n * ws[k];
		rough += mix(ROUGH[id], 0.35, a.a * METAL[id]) * ws[k];
		metal += METAL[id] * a.a * ws[k];
		if (id == 3 || id == 6) {
			ore += ws[k];
			ore_vein += a.a * ws[k];
			ore_tin += (id == 6 ? 1.0 : 0.0) * ws[k];
		}
	}
	// Ore glints (F870): on copper and tin rock (more on its veins), a few tiny four-point stars flash white-hot for a moment, only when your
	// lantern is near and shines on them; each speck at its own time, and they shift as you move (like glitter).
	if (ore > 0.05 && lantern_at.w > 0.5) {
		vec3 L = lantern_at.xyz - v_world;
		float dl = length(L);
		float reach = (1.0 - smoothstep(lantern_at.w * 0.3, lantern_at.w * 0.55, dl)) * clamp(dot(wn, L / dl), 0.0, 1.0);
		vec3 gp = v_world * 10.0;  // one possible glint per 10 cm cube
		vec3 cell = floor(gp);
		float h = hash(cell + vec3(0.37, 1.7, 4.1));
		vec3 f = fract(gp) - 0.5;
		float off = dot(f, wn);  // how far the rock surface passes from the cube's middle
		if (reach > 0.0 && h > mix(0.88, 0.2, clamp(ore_vein * 2.0, 0.0, 1.0)) && abs(off) < 0.25) {
			f -= wn * off;  // the spot on the rock nearest the middle
			vec3 t1 = normalize(cross(wn, abs(wn.y) < 0.9 ? vec3(0.0, 1.0, 0.0) : vec3(1.0, 0.0, 0.0)));
			vec3 t2 = cross(wn, t1);
			float d1 = abs(dot(f, t1));
			float d2 = abs(dot(f, t2));
			// A tiny four-point star: a bright core and two thin crossed rays.
			float core = 1.0 - smoothstep(0.03, 0.1, length(f));
			float rays = max((1.0 - smoothstep(0.0, 0.02, d1)) * (1.0 - smoothstep(0.0, 0.4, d2)),
					(1.0 - smoothstep(0.0, 0.02, d2)) * (1.0 - smoothstep(0.0, 0.4, d1)));
			float ph = hash(cell + vec3(7.1, 2.3, 5.9));
			vec3 V = normalize(CAMERA_POSITION_WORLD - v_world);
			float tw = pow(max(sin(TIME * (1.0 + 1.6 * ph) + ph * 40.0 + dot(V, vec3(5.0, 3.0, 4.0)) * 3.0), 0.0), 10.0);
			vec3 gcol = mix(vec3(1.0, 0.86, 0.72), vec3(0.88, 0.94, 1.0), ore_tin / ore);  // copper warm-white, tin cool-white
			emit += gcol * (core + rays * 0.7) * tw * min(ore * 1.5, 1.0) * reach * 9.0;
		}
	}
	// Big soft light/dark patches so the texture repeats are hard to spot.
	float macro = vnoise(v_world * 0.07) * 0.6 + vnoise(v_world * 0.21) * 0.4;
	col *= 0.78 + 0.4 * macro;
	// Stains on the rock (owner F188, "the cave still looks empty"; picked: coloured floor stains): damp dark patches
	// and green mould on floors, orange mineral streaks running down walls. From the position only, so every computer
	// shows the same, and dug rock shows them too.
	float up = smoothstep(0.55, 0.9, wn.y);
	float damp = smoothstep(0.55, 0.75, vnoise(v_world * 0.18 + vec3(3.1, 0.0, 7.7)));
	col *= mix(1.0, 0.62, damp * up);
	rough = mix(rough, rough * 0.65, damp * up);  // damp: a little shiny
	float mould = smoothstep(0.6, 0.78, vnoise(v_world * 0.35 + vec3(11.0, 2.0, 5.0))) * smoothstep(0.3, 0.7, vnoise(v_world * 2.3));
	col = mix(col, col * vec3(0.55, 0.85, 0.4) + vec3(0.02, 0.05, 0.0), mould * up * 0.75);
	float side = 1.0 - smoothstep(0.35, 0.6, abs(wn.y));
	float streak = smoothstep(0.68, 0.85, vnoise(vec3(v_world.x * 1.6, v_world.y * 0.15, v_world.z * 1.6) + vec3(0.0, 9.0, 4.0)));
	streak *= smoothstep(0.45, 0.6, vnoise(v_world * 0.12 + vec3(20.0)));  // only in some places
	col = mix(col, col * vec3(1.35, 0.8, 0.45) + vec3(0.06, 0.02, 0.0), streak * side * 0.7);
	// Glow-worm stars on the ceilings (owner F217/F232, picked look: "star dots"): tiny soft teal-blue dots, denser in
	// some patches, none in others, each twinkling slowly. Part of the rock's own paint, so it always sits on the rock.
	float ceiling = smoothstep(0.45, 0.8, -wn.y);
	if (ceiling > 0.0) {
		float inbig = star_radius > 0.0 ? 1.0 - smoothstep(star_radius * 0.8, star_radius * 1.05, length(v_world.xz - star_center.xz)) : 0.0;
		float quiet = quiet_radius > 0.0 ? 1.0 - smoothstep(quiet_radius * 0.85, quiet_radius * 1.15, length(v_world - quiet_center)) : 0.0;
		float sn = snake(v_world, 0.0);
		if (inbig > 0.0) {
			float extra = snake(v_world, 1.0);  // a second snake there (huge cavern round 2: two extra was too many)
			if (star_snakes > 1.5) {
				extra = max(extra, snake(v_world, 2.0));  // a normal-sized first cavern: three (owner, Nov 17)
			}
			sn = max(sn, inbig * extra);
		}
		// In the huge first cavern: more and bigger star patches than elsewhere, but with dark rock between them (owner,
		// round 2: the whole ceiling was "a little bit too much"; the snakes can't cross the dark gaps).
		float pn = vnoise(v_world * 0.05 + vec3(7.0, 1.0, 3.0));
		float patches = max(smoothstep(0.45, 0.68, pn), inbig * smoothstep(0.36, 0.56, pn)) * (1.0 - quiet);
		if (patches > 0.0) {
			vec3 stars = star_layer(v_world, 0.16, 0.012, 0.75) + star_layer(v_world + vec3(31.0, 5.0, 17.0), 0.45, 0.02, 0.5);  // many tiny points
			emit += stars * (1.0 + 35.0 * sn) * patches * ceiling * star_brightness;  // stars light up as the snake passes

		}
	}

	// Glowing veins (owner, Nov 18, F190: "glowing veins in the rock walls that slowly pulse"): thin wandering lines of
	// glowing mineral on some walls, cool teal or warm amber.
	// Walls and ceilings (owner, Nov 18: "under the bridges and on the ceilings"), not floors.
	float vwall = 1.0 - smoothstep(0.5, 0.85, wn.y);
	float ub = (bridge_count > 0 && wn.y < -0.3) ? under_bridge(v_world) : 0.0;  // the undersides of the rock bridges
	vwall = max(vwall, ub);
	// Gently placed (owner, Nov 18: the first cave's whole ceiling was too much): round the mouths of tunnels that lead on,
	// under every bridge, and a few rare patches elsewhere.
	float vguide = guide_count > 0 ? near_guide(v_world) : 0.0;
	float vregion = max(max(smoothstep(0.7, 0.8, vnoise(v_world * 0.03 + vec3(19.0, 3.0, 11.0))), ub), vguide);
	if (vwall * vregion > 0.0) {
		float ridge = abs(vnoise(v_world * vec3(0.32, 0.8, 0.32) + vec3(5.0, 1.0, 9.0)) * 2.0 - 1.0);  // thin where it crosses 0.5
		float vline = (1.0 - smoothstep(0.0, 0.032, ridge)) * max(smoothstep(0.42, 0.58, vnoise(v_world * 0.45 + vec3(3.0, 7.0, 2.0))), ub);  // thin, in broken pieces (whole under bridges)
		float vhue = vnoise(v_world * 0.02 + vec3(2.0, 8.0, 1.0));
		vec3 vcol = vhue > 0.55 ? vec3(1.0, 0.62, 0.25) : vec3(0.3, 0.95, 0.8);
		// All veins light up together, once every 12.5 s (owner, Nov 18: "all of them light up at the same time, once every
		// 10 or 15 seconds", like the crystals): up in about 1.5 s, fading over 3 s, nearly dark in between.
		float vp = fract(TIME / 12.5);
		float vbreath = smoothstep(0.0, 0.12, vp) * (1.0 - smoothstep(0.2, 0.45, vp));
		col = mix(col, col * 0.6, vline * vwall * vregion * 0.5);  // the vein's groove a little darker in the light
		emit += vcol * vline * vwall * vregion * (0.06 + 3.2 * vbreath);
	}

	ALBEDO = col;
	EMISSION = emit;
	ROUGHNESS = rough;
	METALLIC = metal;
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(nrm + wn * 0.001), 0.0)).xyz);
}
