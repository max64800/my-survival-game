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

// One blood splat. Every splat is different (owner, round 3: "all the same, needs variety"):
//  - kind < 0.45: thrown paint, a blob and a long streak with thin strings and drops along the throw
//  - kind < 0.75: a round splat with sharp spikes all around and a few drops flung out
//  - otherwise:   only a spray of drops, no big blob
// rel, r and len are in screen heights. Returns how much blood covers this spot (0..1).
float splat_shape(vec2 rel, float ang, float r, float len, float id, float kind) {
	vec2 dir = vec2(cos(ang), sin(ang));
	float u = dot(rel, dir);
	float v = dot(rel, vec2(-dir.y, dir.x));
	if (u < -r * 3.0 || u > len * 1.3 + r * 2.0 || abs(v) > r * 3.0 + u * 0.4) {
		return 0.0;
	}
	float wob = (noise(rel * 160.0 + id * 31.0) - 0.5) * r * 0.35;
	float a = 0.0;
	float spread = 1.4 + 2.6 * fract(id * 41.0);
	if (kind < 0.75) {
		float blob = mix(1.0, 1.25, step(0.45, kind));
		a = 1.0 - smoothstep(r * 0.85 * blob, r * blob, length(vec2(u, v)) + wob);
	}
	if (kind < 0.45) {
		float k = clamp(u / len, 0.0, 1.0);
		float sw = r * (0.35 + 0.4 * fract(id * 53.0)) * pow(1.0 - k, 0.7);
		a = max(a, (1.0 - smoothstep(sw * 0.75, sw, abs(v + wob * 0.6))) * step(0.0, u) * step(u, len));
		for (int i = 0; i < 3; i++) {
			float fi = float(i);
			if (hash(vec2(id * 3.0, fi + 9.0)) < 0.25) {
				continue;
			}
			float off = (hash(vec2(id * 13.0, fi)) - 0.5) * r * spread;
			float ln = len * (0.35 + 0.8 * hash(vec2(fi, id * 7.0)));
			float kk = clamp(u / ln, 0.0, 1.0);
			float tw = r * 0.10 * (1.0 - kk) + r * 0.03;
			a = max(a, (1.0 - smoothstep(tw * 0.6, tw, abs(v - off * kk))) * step(0.0, u) * step(u, ln));
			a = max(a, 1.0 - smoothstep(r * 0.12, r * 0.19, length(vec2(u - ln, v - off))));
		}
	} else if (kind < 0.75) {
		float pa = atan(v, u);
		float spikes = 5.0 + floor(6.0 * fract(id * 61.0));
		float sp = pow(max(sin(pa * spikes + id * 20.0), 0.0), 10.0) * (0.6 + 0.8 * noise(vec2(pa * 3.0, id * 9.0)));
		a = max(a, 1.0 - smoothstep(r * (1.2 + 1.3 * sp) * 0.9, r * (1.2 + 1.3 * sp), length(vec2(u, v))));
	}
	float drops = mix(4.0, 10.0, step(0.75, kind));
	for (int i = 0; i < 10; i++) {
		float fi = float(i) + 5.0;
		if (float(i) >= drops) {
			break;
		}
		float du = len * (0.1 + 1.1 * hash(vec2(id * 5.0, fi)));
		float dv = (hash(vec2(fi, id * 11.0)) - 0.5) * (r * spread + du * 0.5);
		if (kind >= 0.45 && kind < 0.75) {
			du = (hash(vec2(id * 5.0, fi)) - 0.5) * r * 5.0;
		}
		float dr = r * (0.05 + 0.16 * pow(hash(vec2(fi * 3.0, id)), 2.0));
		a = max(a, 1.0 - smoothstep(dr * 0.6, dr, length(vec2((u - du) * 0.6, v - dv))));
	}
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
			if (kind >= 0.45 && kind < 0.75) {
				// The round ones: splat, stay, fade away, then splat again in a new spot.
				float period = 2.5 + 3.5 * fract(id * 37.0);
				float cyc = t / period + id * 7.0;
				float ph = fract(cyc);
				sid = hash(g + floor(cyc) * 1.37);
				pop = 0.55 + 0.45 * smoothstep(0.0, 0.05, ph);
				vis = smoothstep(0.0, 0.02, ph) * (1.0 - smoothstep(0.65, 0.9, ph));
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
	float sa = sp.x * zone * (0.50 + 0.35 * sp.y) * (0.75 + 0.35 * lh);
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

// One frost fern, like frost on a window: a straight spine with sharp straight needles on both sides.
// rel and len in screen heights; grow 0..1 = how far it has grown out yet.
// look: x = how much the needles lean toward the tip, y = how wide the fern is, z = needle spacing.
float frond(vec2 rel, float ang, float len, float grow, vec3 look) {
	vec2 dir = vec2(cos(ang), sin(ang));
	float u = dot(rel, dir);
	float v = abs(dot(rel, vec2(-dir.y, dir.x)));
	if (u < 0.0 || u > len * grow || v > len * look.y) {
		return 0.0;
	}
	float k = u / len;
	float sw = 0.0012 + 0.0016 * (1.0 - k);
	float a = 1.0 - smoothstep(sw * 0.5, sw, v);
	float bw = len * look.y * min(k * 5.0, 1.0) * (1.0 - k);  // needles longest in the middle, a sharp tip
	if (v < bw) {
		float sp = len * look.z;
		float sn = (u - v * look.x) / sp;
		float dl = abs(sn - floor(sn + 0.5)) * sp / sqrt(1.0 + look.x * look.x);
		float nw = 0.0011 * (1.0 - v / bw) + 0.0005;
		a = max(a, (1.0 - smoothstep(nw * 0.5, nw, dl)) * 0.8);
	}
	return a;
}

// How deep into the frost a spot is (smaller = closer to the edge); corners count as closer.
float frost_dist(vec2 p, float aspect) {
	float dx = min(p.x, aspect - p.x);
	float dy = min(p.y, 1.0 - p.y);
	return min(dx, dy) * (0.20 + 0.80 * smoothstep(0.0, 0.5, max(dx, dy)));  // round 4: much more in the corners
}

// One six-armed snowflake (owner, round 4: "more variety of snowflakes"). id picks its look: how many
// side branches and where, how long they are, a flat hexagon plate in the middle or not, sharp or
// plate-shaped arm tips. rel and size in screen heights.
float snowflake(vec2 rel, float size, float id, float rot) {
	float r = length(rel);
	if (r > size) {
		return 0.0;
	}
	float sector = 1.0472;  // 60 degrees: six arms
	float a = mod(atan(rel.y, rel.x) + rot, sector) - sector * 0.5;
	a = abs(sector * 0.5 - abs(a));  // fold so every arm (and both its sides) draws the same
	vec2 q = r * vec2(cos(a), sin(a));  // q.x runs out along the arm, q.y is beside it
	float lw = 0.0011 + 0.0012 * (1.0 - r / size);
	float f = (1.0 - smoothstep(lw * 0.5, lw, q.y)) * step(q.x, size * 0.97);
	float branches = floor(4.0 * fract(id * 3.3));
	float blen = 0.18 + 0.30 * fract(id * 5.1);
	for (int b = 0; b < 3; b++) {
		float fb = float(b);
		if (fb >= branches) {
			break;
		}
		float at = size * (0.30 + 0.22 * fb + 0.08 * fract(id * (7.0 + fb)));
		vec2 d = q - vec2(at, 0.0);
		float along = dot(d, vec2(0.5, 0.866));
		float across = abs(dot(d, vec2(-0.866, 0.5)));
		float bl = size * blen * (1.0 - 0.25 * fb);
		f = max(f, (1.0 - smoothstep(lw * 0.4, lw * 0.9, across)) * step(0.0, along) * step(along, bl));
	}
	float plate = step(0.5, fract(id * 9.7)) * size * (0.12 + 0.12 * fract(id * 2.9));
	float hexd = q.x * 0.866 + q.y * 0.5;  // distance to a flat hexagon edge
	f = max(f, (1.0 - smoothstep(lw * 0.4, lw, abs(hexd - plate))) * step(0.001, plate));
	f = max(f, (1.0 - step(plate, hexd)) * 0.35);
	float tip = step(0.6, fract(id * 4.7)) * size * 0.16;  // some arms end in a small flat plate
	f = max(f, (1.0 - smoothstep(lw * 0.4, lw, abs(length(q - vec2(size * 0.85, 0.0)) - tip))) * step(0.001, tip));
	return f;
}

vec4 frost_fx(vec2 p, float aspect, float lvl, float fade, float t) {
	// Round 3 (owner): sharp straight frost ferns like on a window, on all four edges, see-through,
	// and every burst different: thin spears, wide ferns, single ones, stars of up to six arms, and
	// patches where the frost is thick next to clear gaps.
	float w = (0.05 + 0.08 * lvl) * fade;  // round 4: not as far in along the edges
	float e = frost_dist(p, aspect) - (fbm(p * 2.5) - 0.5) * w * 0.8;
	if (e > w + 0.09) {
		return vec4(0.0);
	}
	float patchy = fbm(p * 4.0 + 7.0);
	float haze = (1.0 - smoothstep(w * 0.3, w, e)) * (0.5 + patchy);
	float solid = 1.0 - smoothstep(0.0, w * 0.35, e);
	float cn = 1.0 - smoothstep(0.05, 0.35, max(min(p.x, aspect - p.x), min(p.y, 1.0 - p.y)));
	solid = max(solid, cn * haze * 0.8);  // the corners are packed thick
	float ice = 0.0;
	for (int l = 0; l < 4; l++) {
		float s = 6.0 * pow(1.7, float(l));
		vec2 n = floor(p * s);
		for (int j = -1; j <= 1; j++) {
			for (int i = -1; i <= 1; i++) {
				vec2 g = n + vec2(float(i), float(j));
				vec2 base = (g + vec2(hash(g + s), hash(g + s + 19.19))) / s;
				vec2 rel = p - base;
				if (dot(rel, rel) * s * s > 1.0) {
					continue;
				}
				float id = hash(g + s + 3.7);
				// Clear gaps between the bursts, like the dark holes in real window frost.
				float bc = 1.0 - smoothstep(0.1, 0.4, max(min(base.x, aspect - base.x), min(base.y, 1.0 - base.y)));
				if (noise(base * 5.0 + 3.0) < 0.28 * (1.0 - bc) && l < 3) {
					continue;
				}
				float be = frost_dist(base, aspect) - (noise(base * 2.5) - 0.5) * w * 0.8;
				float grow = clamp((w - be) / (w * 0.35 + 0.001), 0.0, 1.0);
				if (grow > 0.0) {
					vec2 toc = vec2(aspect * 0.5, 0.5) - base;
					float ang = atan(toc.y, toc.x) + (id - 0.5) * 2.2;
					float len = (0.55 + 0.40 * fract(id * 7.7)) / s;
					vec3 look = vec3(0.35 + 0.9 * fract(id * 3.1), 0.12 + 0.24 * fract(id * 5.9), 0.05 + 0.06 * fract(id * 8.3));
					float arms = floor(1.0 + 5.99 * pow(fract(id * 13.7), 2.5));  // mostly 1 to 3 ferns, now and then a star
					arms = mix(arms, 1.0, step(1.5, float(l)));  // the small ones in between are single ferns
					float f = frond(rel, ang, len, grow, look);
					for (int m = 1; m < 6; m++) {
						float fm = float(m);
						if (fm >= arms) {
							break;
						}
						float aa = ang + fm * 6.2832 / arms + (hash(vec2(id, fm)) - 0.5) * 0.6;
						f = max(f, frond(rel, aa, len * (0.55 + 0.4 * hash(vec2(fm, id))), grow, look));
					}
					ice = max(ice, f * (0.55 + 0.45 * fract(id * 19.3)) * (1.0 - 0.18 * float(l)));
				}
			}
		}
	}
	// Snowflakes of many kinds scattered through the frost.
	for (int l = 0; l < 2; l++) {
		float s = 8.0 + 7.0 * float(l);
		vec2 n = floor(p * s);
		for (int j = -1; j <= 1; j++) {
			for (int i = -1; i <= 1; i++) {
				vec2 g = n + vec2(float(i), float(j)) + 300.0;
				float id = hash(g + s);
				if (id > 0.55) {
					continue;
				}
				vec2 base = (g - 300.0 + 0.25 + 0.5 * vec2(hash(g + 1.3), hash(g + 7.9))) / s;
				float be = frost_dist(base, aspect) - (noise(base * 2.5) - 0.5) * w * 0.8;
				float grow = clamp((w - be) / (w * 0.35 + 0.001), 0.0, 1.0);
				if (grow > 0.0) {
					float size = (0.22 + 0.22 * fract(id * 17.0)) / s * grow;
					ice = max(ice, snowflake(p - base, size, fract(id * 31.0), id * 40.0) * (0.7 + 0.3 * fract(id * 11.0)));
				}
			}
		}
	}
	float sparkle = step(0.992, hash(floor(p * 220.0) + floor(t * 1.5))) * ice;
	vec3 c = mix(vec3(0.80, 0.90, 1.0), vec3(1.0), clamp(ice + sparkle, 0.0, 1.0));
	float a = haze * 0.14 + solid * 0.18 + ice * 0.62 + sparkle * 0.3;
	return vec4(c, clamp(a, 0.0, 0.85) * fade);
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
