shader_type spatial;
// Paints the dig-anywhere rock. Each voxel has a material number (see mat.gd):
// 0 moss, 1 stone, 2 dirt, 3 copper ore, 4 border rock, 5 clay,
// 8 mycelium, 9 silver ore, 11 amberrock, 13 sporestone, 15 the world's edge.
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

// Glow colour of the alpha-marked veins, per material number.
const vec3 GLOW[16] = vec3[16](
	vec3(0.0), vec3(0.0), vec3(0.0),
	vec3(0.95, 0.42, 0.12) * 0.55,  // 3 copper
	vec3(0.40, 0.20, 0.75) * 1.2,   // 4 border rock
	vec3(0.0), vec3(0.0), vec3(0.0), vec3(0.0),
	vec3(0.75, 0.85, 1.0) * 0.6,    // 9 silver
	vec3(0.0), vec3(0.0), vec3(0.0),
	vec3(0.65, 0.30, 0.95) * 0.6,   // 13 sporestone specks
	vec3(0.0), vec3(0.0));
// How rough (matte) each material is. Lower = a little shine under the lantern.
const float ROUGH[16] = float[16](0.95, 0.82, 0.93, 0.8, 0.75, 0.68, 0.8, 0.8,
	0.92, 0.8, 0.8, 0.7, 0.8, 0.84, 0.8, 0.85);
// Ores: the veins are metal.
const float METAL[16] = float[16](0.0, 0.0, 0.0, 0.85, 0.0, 0.0, 0.0, 0.0,
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
uniform float star_brightness = 3.2;  // (owner: brighter; moving the camera smears tiny points a little)

float star_layer(vec3 p, float cell, float radius, float keep) {
	vec3 q = p / cell;
	vec3 c = floor(q);
	float h = hash(c + vec3(3.7));
	if (h > keep) {
		return 0.0;
	}
	vec3 at = c + 0.2 + 0.6 * vec3(hash(c + vec3(1.3)), hash(c + vec3(8.1)), hash(c + vec3(4.4)));
	float d = length(q - at) * cell;  // metres from the ball's middle
	float r = radius * (0.6 + 0.8 * hash(c + vec3(5.5)));
	float aa = max(fwidth(d), 0.0005);  // one pixel of soft edge, no more
	float spot = 1.0 - smoothstep(r - aa, r + aa, d);
	float twinkle = 0.7 + 0.3 * sin(TIME * (0.5 + 1.2 * hash(c + vec3(9.9))) + h * 40.0);
	return spot * twinkle * (0.55 + 0.45 * h / keep);
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
		float slice = float(id * LOOKS) + look;
		triplanar(slice, p, bw, wn, a, n);
		if (look_mix > 0.01) {  // only where two looks meet: read the next look too
			vec4 a2;
			vec3 n2;
			triplanar(slice + 1.0, p, bw, wn, a2, n2);
			a = mix(a, a2, look_mix);
			n = mix(n, n2, look_mix);
		}
		col += a.rgb * ws[k];
		emit += GLOW[id] * a.a * ws[k];
		nrm += n * ws[k];
		rough += mix(ROUGH[id], 0.35, a.a * METAL[id]) * ws[k];
		metal += METAL[id] * a.a * ws[k];
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
		float patches = smoothstep(0.45, 0.68, vnoise(v_world * 0.05 + vec3(7.0, 1.0, 3.0)));
		if (patches > 0.0) {
			float stars = star_layer(v_world, 0.16, 0.012, 0.75) + star_layer(v_world + vec3(31.0, 5.0, 17.0), 0.45, 0.02, 0.5);  // many tiny points
			emit += STAR_COLOR * stars * patches * ceiling * star_brightness;
		}
	}

	ALBEDO = col;
	EMISSION = emit;
	ROUGHNESS = rough;
	METALLIC = metal;
	NORMAL = normalize((VIEW_MATRIX * vec4(normalize(nrm + wn * 0.001), 0.0)).xyz);
}
