shader_type canvas_item;
render_mode unshaded;
// Screen-edge looks (F695, F799, F802). Only the edges are touched, the middle stays clear.
//  - low health (F802): dark red, much thicker left and right, small thrown-paint blood streaks, heartbeat
//  - poison (1): green veins like roots growing in from the edges, pumping
//  - burn (2): glowing embers and black ash rising from the bottom, mostly up the left and right
//  - cold (3): sharp frost ferns, like frost on a window, creeping in from all four edges
//  - hit: a thin red rim drawn on top of everything
// Everything between "shared" and "end shared" is copied as-is into the 3D preview page
// (tools/make_edge_fx_page.py), so the page always matches the game.

uniform vec4 hit_color : source_color = vec4(0.85, 0.08, 0.05, 1.0);
uniform float hit_strength : hint_range(0.0, 1.0) = 0.0;
uniform int status_mode = 0;
uniform float status_fade : hint_range(0.0, 1.0) = 0.0;
uniform float status_level : hint_range(0.0, 1.0) = 0.0;
uniform float low_health : hint_range(0.0, 1.0) = 0.0;

// --- shared ---
float hash(vec2 p) {
	// No sin(): it loses precision on graphics cards and draws square patches.
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

// x = distance to the nearest cell centre, y = how close to a cell border, z = cell id (0..1).
vec3 cells(vec2 x) {
	vec2 n = floor(x);
	vec2 f = fract(x);
	float f1 = 8.0;
	float f2 = 8.0;
	float id = 0.0;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = vec2(float(i), float(j));
			vec2 o = vec2(hash(n + g), hash(n + g + 19.19));
			vec2 r = g + o - f;
			float d = dot(r, r);
			if (d < f1) {
				f2 = f1;
				f1 = d;
				id = hash(n + g + 3.7);
			} else if (d < f2) {
				f2 = d;
			}
		}
	}
	return vec3(sqrt(f1), sqrt(f2) - sqrt(f1), id);
}

// A heartbeat: two quick thumps, then a rest. rate = beats per second.
float heartbeat(float t, float rate) {
	float b = fract(t * rate);
	return exp(-b * 9.0) + 0.6 * exp(-max(b - 0.18, 0.0) * 9.0) * step(0.18, b);
}

// Mix "top" over "base" (both straight alpha).
vec4 over(vec4 base, vec4 top) {
	float a = top.a + base.a * (1.0 - top.a);
	vec3 c = (top.rgb * top.a + base.rgb * base.a * (1.0 - top.a)) / max(a, 0.0001);
	return vec4(c, a);
}

// One lumpy blob of blood: a circle with a bumpy, uneven outline. d and rad in screen heights.
float blood_blob(vec2 d, float rad, float id) {
	vec2 k = d / rad;
	float wob = (noise(k * 2.5 + id * 31.0) - 0.5) * 0.45 + (noise(k * 7.0 + id * 17.0) - 0.5) * 0.18;
	return 1.0 - smoothstep(0.85, 1.0, length(k) + wob);
}

// One blood splat, built in layers like real splatter (owner, round 5: "all the same, just different
// spikes, make it more complex"). Every splat mixes the layers differently:
//  1. a lumpy main pool made of a few overlapping blobs
//  2. thrown paint only (kind < 0.4): a wavy streak that thins along the throw, with thin strings beside it
//  3. a crown of uneven spikes out of the pool, a few long ones ending in a drop
//  4. flung drops of many sizes, stretched away from the pool
//  5. a fine mist of tiny specks
// kind >= 0.8 is mostly spray: a small pool and lots of drops. rel, r and len in screen heights.
float splat_shape(vec2 rel, float ang, float r, float len, float id, float kind) {
	vec2 dir = vec2(cos(ang), sin(ang));
	vec2 q = vec2(dot(rel, dir), dot(rel, vec2(-dir.y, dir.x)));
	float streak = 1.0 - step(0.4, kind);
	float spray = step(0.8, kind);
	float reach = r * 5.5;
	if (q.x < -reach || q.x > len * streak * 1.4 + reach || abs(q.y) > reach + max(q.x, 0.0) * 0.3) {
		return 0.0;
	}
	float bodyr = r * mix(1.0, 0.45, spray);
	float a = 0.0;
	// 1. The main pool.
	for (int i = 0; i < 4; i++) {
		float fi = float(i);
		float h = hash(vec2(id * 3.1, fi));
		float later = step(0.5, fi);
		vec2 o = vec2((h - 0.3) * 1.6, (hash(vec2(fi, id * 5.3)) - 0.5) * 1.3) * bodyr * later;
		float br = bodyr * mix(1.0, 0.3 + 0.45 * h, later);
		a = max(a, blood_blob(q - o, br, id + fi));
	}
	// 2. The thrown-paint streak.
	if (streak > 0.5) {
		float k = clamp(q.x / len, 0.0, 1.0);
		float wave = (noise(vec2(q.x / len * 3.0, id * 9.0)) - 0.5) * r * 0.9 * k;
		float sw = r * (0.35 + 0.4 * fract(id * 53.0)) * pow(1.0 - k, 0.8) + r * 0.05;
		a = max(a, (1.0 - smoothstep(sw * 0.7, sw, abs(q.y - wave))) * step(0.0, q.x) * step(q.x, len));
		for (int i = 0; i < 3; i++) {
			float fi = float(i);
			if (hash(vec2(id * 3.0, fi + 9.0)) < 0.35) {
				continue;
			}
			float off = (hash(vec2(id * 13.0, fi)) - 0.5) * r * 2.6;
			float ln = len * (0.3 + 0.7 * hash(vec2(fi, id * 7.0)));
			float kk = clamp(q.x / ln, 0.0, 1.0);
			float tw = r * 0.09 * (1.0 - kk) + r * 0.025;
			a = max(a, (1.0 - smoothstep(tw * 0.6, tw, abs(q.y - off * kk - wave))) * step(0.0, q.x) * step(q.x, ln));
		}
	}
	// 3. The crown of spikes. Spikes thrown forward are longer.
	float nt = floor(mix(5.0, 14.99, fract(id * 61.0)));
	for (int k = 0; k < 14; k++) {
		float fk = float(k);
		if (fk >= nt) {
			break;
		}
		float h1 = hash(vec2(id * 17.0, fk));
		float aa = 6.2832 * (fk + 0.6 * (hash(vec2(fk, id * 23.0)) - 0.5)) / nt + id * 6.0;
		vec2 ad = vec2(cos(aa), sin(aa));
		float fwd = 0.6 + 0.4 * max(ad.x, 0.0) * (1.0 + streak);
		float al = bodyr * (1.0 + (0.25 + 2.0 * pow(h1, 3.0)) * fwd);
		float au = dot(q, ad);
		float av = dot(q, vec2(-ad.y, ad.x));
		float kk = clamp(au / al, 0.0, 1.0);
		float aw = bodyr * (0.10 + 0.20 * hash(vec2(fk * 7.0, id))) * pow(1.0 - kk, 1.2) + r * 0.015;
		a = max(a, (1.0 - smoothstep(aw * 0.6, aw, abs(av))) * step(0.0, au) * step(au, al));
		float dr = bodyr * (0.06 + 0.10 * h1) * step(0.55, h1);
		a = max(a, 1.0 - smoothstep(dr * 0.7, dr + 0.00001, length(vec2(au - al, av))));
	}
	// 4. Flung drops.
	float nd = floor(mix(6.0, 16.99, max(fract(id * 71.0), spray)));
	for (int i = 0; i < 16; i++) {
		float fi = float(i);
		if (fi >= nd) {
			break;
		}
		float h = hash(vec2(id * 5.0, fi + 5.0));
		float da = (hash(vec2(fi, id * 11.0)) - 0.5) * mix(6.2832, 1.6, streak);
		float dd = bodyr * (1.4 + 3.2 * pow(hash(vec2(fi * 3.0, id)), 0.8)) + streak * len * hash(vec2(id, fi * 7.0));
		vec2 rad = vec2(cos(da), sin(da));
		vec2 dv = q - dd * rad;
		float ru = dot(dv, rad);
		float rv = dot(dv, vec2(-rad.y, rad.x));
		float drr = r * (0.04 + 0.14 * pow(h, 2.5));
		float stretch = 1.0 + 1.1 * hash(vec2(fi * 13.0, id));
		a = max(a, 1.0 - smoothstep(drr * 0.65, drr, length(vec2(ru / stretch, rv))));
	}
	// 5. A fine mist of specks, thicker close to the pool.
	float cs = r * 0.2;
	vec2 mg = floor(q / cs);
	float near = 1.0 - smoothstep(0.3, 1.0, length(q) / (bodyr * 3.8));
	float mist = step(1.0 - 0.22 * near * (0.5 + spray), hash(mg + id * 13.0));
	vec2 mc = (mg + 0.25 + 0.5 * vec2(hash(mg + 2.1), hash(mg + 5.7))) * cs;
	a = max(a, mist * (1.0 - smoothstep(r * 0.03, r * 0.055, length(q - mc))));
	return a;
}

// One size of blood splats. s = squares per screen height (fewer = bigger splats), r0..r1 = blob size.
// Splats bunch up in the corners (and a little along the sides). Splats can start just outside the
// screen and be thrown in. The round ones keep splatting: each pops in, stays a moment, fades, and
// splats again somewhere close by (owner, round 4). x = blood, y = shade (0 dried dark, 1 fresh).
vec2 splat_layer(vec2 p, float aspect, float lh, float t, float s, float r0, float r1, float seed) {
	vec2 n = floor(p * s);
	float a = 0.0;
	float shade = 0.5;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 g = n + vec2(float(i), float(j)) + seed;
			float id = hash(g + 3.7);
			vec2 cell = (g - seed + 0.5) / s;
			float bx = max(min(cell.x, aspect - cell.x), 0.0);
			float by = max(min(cell.y, 1.0 - cell.y), 0.0);
			float corner = 1.0 - smoothstep(0.05, 0.55, max(bx, by));
			float side = (1.0 - smoothstep(0.0, 0.18, bx)) * 0.4;
			float chance = lh * (0.08 + 0.92 * max(corner, side));
			if (id >= chance) {
				continue;
			}
			float kind = fract(id * 29.7 + seed);
			float sid = id;
			float vis = 1.0;
			float pop = 1.0;
			if (kind >= 0.4) {
				// The round ones: splat, stay, fade away, then splat again in a new spot.
				float period = 2.5 + 3.5 * fract(id * 37.0);
				float cyc = t / period + id * 7.0;
				float ph = fract(cyc);
				sid = hash(g + floor(cyc) * 1.37);
				pop = 0.55 + 0.45 * smoothstep(0.0, 0.05, ph);
				vis = smoothstep(0.0, 0.02, ph) * (1.0 - smoothstep(0.80, 0.9, ph));
			}
			vec2 base = (g - seed + 0.1 + 0.8 * vec2(hash(g + sid), hash(g + sid + 19.19))) / s;
			vec2 toc = vec2(aspect * 0.5, 0.5) - base;
			float ang = atan(toc.y, toc.x) + (fract(sid * 17.3) - 0.5) * 1.8;
			float r = mix(r0, r1, pow(fract(sid * 7.3), 1.5)) * mix(1.0, 1.4, corner) * pop;
			float len = min(r * (2.0 + 7.0 * fract(sid * 3.1)), 0.55 / s);
			float sp = splat_shape(p - base, ang, r, len, sid, kind) * vis;
			if (sp > a) {
				a = sp;
				shade = fract(sid * 71.0);
			}
		}
	}
	return vec2(a, shade);
}

// All the blood: a few big splats, more middle ones, lots of small ones.
vec2 splats(vec2 p, float aspect, float lh, float t) {
	vec2 a = splat_layer(p, aspect, lh, t, 3.0, 0.018, 0.036, 0.0);
	vec2 b = splat_layer(p, aspect, lh, t, 6.0, 0.008, 0.016, 40.0);
	vec2 c = splat_layer(p, aspect, lh, t, 11.0, 0.003, 0.008, 80.0);
	vec2 m = a;
	if (b.x > m.x) {
		m = b;
	}
	if (c.x > m.x) {
		m = c;
	}
	return m;
}

vec4 low_health_fx(vec2 p, float aspect, float dx, float dy, float lh, float t) {
	// Sides much thicker than top and bottom (the owner's picture).
	float de = min(dx, dy * 2.6);
	float w = 0.10 + 0.30 * lh;
	float hb = heartbeat(t, 0.9 + 0.7 * lh);
	float n = fbm(p * 3.0);
	float e = de - (n - 0.5) * w * 0.6 - hb * 0.02 * lh;
	float m = 1.0 - smoothstep(0.0, w, e);
	vec3 c = mix(vec3(0.55, 0.04, 0.03), vec3(0.25, 0.0, 0.0), m);
	vec4 col = vec4(c, m * m * (0.30 + 0.35 * lh) * (0.85 + 0.15 * hb));
	// Blood thrown on the screen, only out near the edges.
	float zone = 1.0 - smoothstep(0.18, 0.40 + 0.10 * lh, de);
	vec2 sp = splats(p, aspect, lh, t);
	float sa = sp.x * zone * (0.70 + 0.25 * sp.y) * (0.75 + 0.30 * lh);
	vec3 blood = mix(vec3(0.20, 0.02, 0.01), vec3(0.48, 0.02, 0.03), sp.y);  // dried dark to fresh bright
	return over(col, vec4(blood, sa));
}

vec4 poison_fx(vec2 p, float d, float lvl, float fade, float t) {
	// Green veins like roots, growing in from the edges and pumping like a heartbeat.
	float w = (0.10 + 0.10 * lvl) * fade;
	float reach = 1.0 - smoothstep(0.0, w, d + (fbm(p * 2.2) - 0.5) * w * 0.7);
	if (reach <= 0.0) {
		return vec4(0.0);
	}
	vec2 q = p * 3.2;
	vec2 warp = vec2(fbm(q + vec2(0.0, 1.3)), fbm(q + vec2(5.2, 1.7)));
	float n1 = fbm(q * 1.2 + warp * 1.8);
	float n2 = fbm(q * 2.7 + warp * 2.4 + vec2(3.1, 7.7));
	float th1 = 0.030 * reach;
	float th2 = 0.018 * reach;
	float v1 = 1.0 - smoothstep(th1 * 0.35, th1, abs(n1 - 0.5));
	float v2 = (1.0 - smoothstep(th2 * 0.35, th2, abs(n2 - 0.5))) * smoothstep(0.35, 0.8, reach);
	float vein = max(v1, v2 * 0.8);
	// The pump: a bright wave running inward along the veins with every heartbeat.
	float hb = heartbeat(t, 1.1);
	float wave = 0.5 + 0.5 * sin(t * 5.0 - d * 45.0);
	float glow = vein * (0.35 + 0.65 * hb * wave);
	vec3 c = mix(vec3(0.10, 0.40, 0.07), vec3(0.62, 1.0, 0.32), glow);
	float haze = (1.0 - smoothstep(0.0, w * 0.55, d)) * (0.16 + 0.10 * lvl) * (0.8 + 0.2 * hb);
	vec4 col = vec4(vec3(0.20, 0.55, 0.10), haze * fade);
	return over(col, vec4(c, vein * (0.55 + 0.25 * lvl) * fade));
}

// One layer of rising sparks. s = how many fit in a screen height (more = smaller and further away),
// v = how fast they rise. Returns x = orange glow, y = white-hot core.
vec2 ember_layer(vec2 p, float aspect, float s, float v, float seed, float lvl, float fade, float t) {
	float dx = min(p.x, aspect - p.x);
	float h = 1.0 - p.y;
	vec2 q = p;
	q.x += (noise(vec2(p.y * 2.5 - t * 0.4, seed + p.x * 1.5)) - 0.5) * 0.12;  // drift on the hot air
	q.y += t * v;
	vec2 x = q * s;
	vec2 c = floor(x);
	float id = hash(c + seed);
	// Mostly up the left and right sides; a few in the middle that die out halfway up.
	float side = 1.0 - smoothstep(0.05, 0.45, dx);
	float chance = (0.12 + 0.55 * side) * (0.7 + 0.3 * lvl) * fade;
	if (id > chance) {
		return vec2(0.0);
	}
	float top = mix(0.25 + 0.25 * fract(id * 9.1), 0.75 + 0.35 * fract(id * 5.7), side);
	float life = 1.0 - smoothstep(top * 0.5, top, h);
	vec2 o = 0.32 + 0.36 * vec2(hash(c + seed + 7.1), hash(c + seed + 3.3));
	vec2 rel = (fract(x) - o) / s;
	float sz = (0.10 + 0.07 * fract(id * 31.0)) / s;
	// A short glowing tail below the spark, because it is moving up.
	float ty = rel.y * mix(1.0, 0.5, step(0.0, rel.y));
	float dt = length(vec2(rel.x, ty));
	float flick = 0.55 + 0.45 * sin(t * (6.0 + 10.0 * fract(id * 3.7)) + id * 60.0);
	float core = (1.0 - smoothstep(sz * 0.25, sz * 0.6, dt)) * life * (0.6 + 0.4 * flick);
	float halo = pow(1.0 - smoothstep(0.0, sz * 2.0, length(rel)), 2.0) * 0.55 * life * flick;
	return vec2(max(halo, core * 0.8), core);
}

// One layer of black ash flakes, tumbling as they float up. Returns x = ash, y = a glowing rim on some.
vec2 ash_layer(vec2 p, float aspect, float s, float v, float seed, float lvl, float fade, float t) {
	float dx = min(p.x, aspect - p.x);
	float h = 1.0 - p.y;
	vec2 q = p;
	q.x += (noise(vec2(p.y * 1.8 - t * 0.3, seed)) - 0.5) * 0.2;
	q.y += t * v;
	vec2 x = q * s;
	vec2 c = floor(x);
	float id = hash(c + seed);
	float side = 1.0 - smoothstep(0.05, 0.45, dx);
	if (id > (0.06 + 0.35 * side) * (0.7 + 0.3 * lvl) * fade) {
		return vec2(0.0);
	}
	float top = mix(0.25 + 0.2 * fract(id * 9.1), 0.7 + 0.3 * fract(id * 5.7), side);
	float life = 1.0 - smoothstep(top * 0.6, top, h);
	vec2 o = 0.32 + 0.36 * vec2(hash(c + seed + 7.1), hash(c + seed + 3.3));
	vec2 rel = (fract(x) - o) / s;
	float spin = t * (1.0 + 2.0 * fract(id * 4.3)) + id * 20.0;
	vec2 r = vec2(cos(spin) * rel.x - sin(spin) * rel.y, sin(spin) * rel.x + cos(spin) * rel.y);
	r.x /= 0.35 + 0.65 * abs(cos(spin * 0.7));  // tumbling: the flake turns edge-on and back
	float sz = (0.09 + 0.08 * fract(id * 23.0)) / s;
	float ang = atan(r.y, r.x);
	float edge = 1.0 + 0.30 * sin(ang * 3.0 + id * 40.0) + 0.18 * sin(ang * 7.0 + id * 90.0);  // a torn, uneven flake
	float shape = length(vec2(r.x, r.y / 0.65)) / (sz * edge);
	float ash = (1.0 - smoothstep(0.8, 1.0, shape)) * life;
	float rim = (1.0 - smoothstep(0.0, 0.25, abs(shape - 0.85))) * step(0.6, fract(id * 13.0)) * life;
	return vec2(ash, rim * ash);
}

vec4 fire_fx(vec2 p, float aspect, float dx, float lvl, float fade, float t) {
	// Round 3 (owner): lots of embers and black ash rising from under the screen, mostly up the sides.
	float h = 1.0 - p.y;
	float side = 1.0 - smoothstep(0.0, 0.40, dx);
	float flick = 0.80 + 0.20 * noise(vec2(t * 7.0, 2.0));
	float n = fbm(vec2(p.x * 3.0, p.y * 2.0 + t * 0.5));
	float glow = (1.0 - smoothstep(0.0, 0.10 + 0.30 * side, h + (n - 0.5) * 0.12)) * (0.10 + 0.25 * side);
	vec4 col = vec4(vec3(0.95, 0.32, 0.05), glow * flick * fade);
	for (int i = 0; i < 2; i++) {
		float fi = float(i);
		vec2 a = ash_layer(p, aspect, 10.0 + 8.0 * fi, 0.16 + 0.05 * fi, 50.0 + fi * 17.0, lvl, fade, t);
		col = over(col, vec4(mix(vec3(0.06, 0.04, 0.03), vec3(1.0, 0.40, 0.06), a.y), a.x * 0.85 * fade));
	}
	for (int i = 0; i < 3; i++) {
		float fi = float(i);
		vec2 e = ember_layer(p, aspect, 14.0 + 13.0 * fi, 0.38 - 0.07 * fi, fi * 31.0, lvl, fade, t);
		col = over(col, vec4(mix(vec3(1.0, 0.38, 0.05), vec3(1.0, 0.88, 0.55), e.y), e.x * fade));
	}
	return col;
}

// How far a spot is from where the ice starts (smaller = deeper in the ice). The corners freeze first and
// deepest (round, out from each corner); the edges between them only get a thinner band.
float frost_dist(vec2 p, float aspect) {
	float dx = min(p.x, aspect - p.x);
	float dy = min(p.y, 1.0 - p.y);
	return min(length(vec2(dx, dy)) * 1.0, min(dx, dy) * 3.6 + 0.03);
}

// Frozen-lake ice (owner, round 5: "like a frozen lake, the cracks you see in Antarctica", corners frozen
// solid at 5 stacks, creeping toward the middle). Solid see-through ice grows out of the corners, split into
// plates by bright white cracks with thin hairline cracks between them, milky salt-like crust in patches,
// and a white frosty front where the ice is still growing toward the middle.
vec4 frost_fx(vec2 p, float aspect, float lvl, float fade, float t) {
	float w = (0.08 + 0.30 * lvl) * fade;
	float e = frost_dist(p, aspect) - (fbm(p * 3.0) - 0.5) * w * 0.5 - (noise(p * 22.0) - 0.5) * w * 0.12;
	if (e > w + 0.06) {
		return vec4(0.0);
	}
	float body = 1.0 - smoothstep(w * 0.9, w, e);
	float depth = clamp(1.0 - e / max(w, 0.001), 0.0, 1.0);
	// Bend the spot a little first, so the cracks come out jagged instead of straight.
	vec2 q = p + (vec2(fbm(p * 7.0), fbm(p * 7.0 + 5.3)) - 0.5) * 0.05;
	vec3 big = cells(q * 4.5);
	vec3 small = cells(q * 12.0 + 3.0);
	float inside = smoothstep(0.08, 0.3, depth);
	float crack = (1.0 - smoothstep(0.008, 0.022, big.y)) * inside;
	float shadow = clamp((1.0 - smoothstep(0.03, 0.08, big.y)) * inside - crack, 0.0, 1.0);
	float glow = (1.0 - smoothstep(0.0, 0.18, big.y)) * 0.5 * inside;
	float hair = (1.0 - smoothstep(0.012, 0.03, small.y)) * step(0.42, noise(q * 6.0 + 2.0)) * 0.7 * inside;
	float milk = smoothstep(0.45, 0.78, fbm(p * 9.0 + big.z * 4.0));
	float grain = step(0.72, noise(p * 260.0)) * (0.3 + 0.7 * milk);
	float rim = smoothstep(w * 0.55, w * 0.92, e) * body;
	float sparkle = step(0.993, hash(floor(p * 220.0) + floor(t * 1.5))) * crack;
	vec3 deep = mix(vec3(0.40, 0.60, 0.76), vec3(0.66, 0.81, 0.93), 0.5 * big.z + 0.5 * (1.0 - depth));
	vec3 c = mix(deep, vec3(0.90, 0.95, 1.0), clamp(milk * 0.7 + rim * 0.8 + glow * 0.6 + grain * 0.5, 0.0, 1.0));
	c *= 1.0 - 0.25 * shadow;
	c = mix(c, vec3(1.0), clamp(crack + hair + sparkle, 0.0, 1.0));
	float a = body * (0.20 + 0.36 * depth + 0.06 * big.z + 0.18 * milk + 0.25 * rim + 0.12 * grain);
	a += body * (crack * 0.5 + hair * 0.35 + glow * 0.15);
	a += sparkle * 0.3;
	return vec4(c, clamp(a, 0.0, 0.9) * fade);
}

vec4 edge_fx(vec2 uv, float aspect, float t) {
	// Measure in screen heights so the edge is equally thick on all four sides.
	vec2 p = vec2(uv.x * aspect, uv.y);
	float dx = min(p.x, aspect - p.x);
	float dy = min(p.y, 1.0 - p.y);
	float d = min(dx, dy);
	vec4 col = vec4(0.0);
	if (low_health > 0.0) {
		col = low_health_fx(p, aspect, dx, dy, low_health, t);
	}
	if (status_mode != 0 && status_fade > 0.0) {
		float lvl = clamp(status_level, 0.0, 1.0);
		if (status_mode == 1) {
			col = over(col, poison_fx(p, d, lvl, status_fade, t));
		} else if (status_mode == 2) {
			col = over(col, fire_fx(p, aspect, dx, lvl, status_fade, t));
		} else if (status_mode == 3) {
			col = over(col, frost_fx(p, aspect, lvl, status_fade, t));
		}
	}
	if (hit_strength > 0.0) {
		float rim = pow(1.0 - clamp(d / 0.07, 0.0, 1.0), 2.0);
		col = over(col, vec4(hit_color.rgb, rim * hit_strength));
	}
	return col;
}
// --- end shared ---

void fragment() {
	COLOR = edge_fx(UV, SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x, TIME);
}
