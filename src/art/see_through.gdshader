shader_type spatial;
render_mode cull_disabled;
// F807: the stand-in paint for a built piece's own model (a plain StandardMaterial3D from its .glb) while it sits
// between the camera and the dwarf. Same colour, picture, roughness and shine, plus the see-through circle.
// Made by CameraFade (src/player/camera_fade.gd); don't set it up by hand. ("cull_disabled" is swapped to
// "cull_back" in code for one-sided models.)
#include "res://src/art/see_through.gdshaderinc"

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_tex = false;
uniform bool use_color = false;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);
uniform float roughness = 1.0;
uniform float metallic = 0.0;
uniform float specular = 0.5;
uniform vec3 emission : source_color = vec3(0.0);
uniform float emission_energy = 0.0;

void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy;
}

void fragment() {
	if (see_cut(VERTEX, VIEW_MATRIX, PROJECTION_MATRIX, CAMERA_POSITION_WORLD, FRAGCOORD.xy)) {
		discard;
	}
	vec4 c = albedo;
	if (has_tex) {
		c *= texture(albedo_tex, UV);
	}
	if (use_color) {
		c *= COLOR;
	}
	ALBEDO = c.rgb;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	SPECULAR = specular;
	EMISSION = emission * emission_energy;
}
