// The little pickable mushrooms (glowcap, firecap, hollowcap, bellcap...: one model, tinted per kind). They lean away
// from a dwarf walking through them, like the ferns (owner F219), but stiffer. The bend: bend.gdshaderinc.
// One material per part of the model (soil, stem, gills, cap); the cap and gills of glowing kinds glow.
shader_type spatial;
render_mode world_vertex_coords;

#include "res://src/art/bend.gdshaderinc"

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap;
uniform float use_normal = 0.0;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform vec4 emission_color : source_color = vec4(0.0);
uniform float emission_energy = 0.0;
uniform float roughness = 0.8;

void vertex() {
	VERTEX += bend_offset(VERTEX, MODEL_MATRIX[3].xyz, MODEL_MATRIX[1].xyz, TIME);
}

void fragment() {
	vec3 tex = texture(albedo_tex, UV).rgb;
	ALBEDO = tex * albedo_color.rgb;
	if (use_normal > 0.5) {
		NORMAL_MAP = texture(normal_tex, UV).rgb;
	}
	ROUGHNESS = roughness;
	EMISSION = emission_color.rgb * tex * emission_energy;  // colour x picture, like the old material (not a white glow)
}
