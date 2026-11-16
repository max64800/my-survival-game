// Shiny crystal (owner, Nov 16: "crystals should have different shine depending on where you stand, and hard edges
// we can see"). A cave has almost nothing for glass to reflect, so each flat facet reflects a made-up "cave of
// lights" instead: as you walk round, a facet turns its reflection toward a bright spot and flashes, then goes dark.
// The rims glint (fresnel), and the narrow cut edges (thin facets at their own angle) light up as hard lines.
// The painted picture (cave_plants.py: pale, with cracks, cloud and bubbles) is tinted with the kind's colour.
shader_type spatial;
render_mode specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(0.35, 0.75, 1.0, 1.0);
uniform float glow = 0.45;   // how much it shines by itself
uniform float shine = 1.6;   // how bright the flashes are

// A few bright "lights" in the made-up surroundings (directions in world space), plus a soft brighter sky above.
float fake_lights(vec3 r) {
	float s = 0.0;
	s += pow(max(dot(r, normalize(vec3(0.55, 0.62, 0.32))), 0.0), 90.0);
	s += pow(max(dot(r, normalize(vec3(-0.7, 0.35, 0.45))), 0.0), 70.0) * 0.8;
	s += pow(max(dot(r, normalize(vec3(0.1, 0.3, -0.95))), 0.0), 110.0) * 0.9;
	s += pow(max(dot(r, normalize(vec3(-0.3, 0.9, -0.3))), 0.0), 40.0) * 0.6;
	s += pow(max(dot(r, normalize(vec3(0.8, -0.1, -0.55))), 0.0), 60.0) * 0.5;
	// many small sparkles all round, so some facet always catches one wherever you stand
	float w = 0.5 + 0.5 * sin(r.x * 7.3 + 1.1) * sin(r.y * 5.9 + 0.4) * sin(r.z * 6.7 + 2.3);
	s += pow(w, 14.0) * 1.2;
	s += smoothstep(0.2, 1.0, r.y) * 0.12;
	return s;
}

void fragment() {
	vec3 paint = texture(albedo_tex, UV).rgb;
	vec3 col = paint * tint.rgb;
	vec3 n = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	vec3 v = normalize((INV_VIEW_MATRIX * vec4(VIEW, 0.0)).xyz);
	vec3 r = reflect(-v, n);
	float facing = clamp(dot(n, v), 0.0, 1.0);
	float fres = pow(1.0 - facing, 3.0);
	float flash = fake_lights(r);
	ALBEDO = col * 0.3;
	ROUGHNESS = 0.06;
	METALLIC = 0.15;
	SPECULAR = 1.0;
	// own glow, a little brighter on facets turned toward you (light from inside)
	vec3 inner = col * glow * (0.25 + 0.95 * facing * facing);
	// reflections: white-hot in the middle of a flash, tinted at its edge; the rim glints in the crystal's colour
	vec3 refl = mix(tint.rgb, vec3(1.0), clamp(flash, 0.0, 1.0)) * flash * shine;
	EMISSION = inner + refl + tint.rgb * fres * 0.35;
}
