shader_type canvas_item;
// A glow along the screen edges: red when you're hit, green/orange/blue while poisoned/burning/chilled (F695).

uniform vec4 edge_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	float d = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
	float glow = pow(1.0 - clamp(d / 0.35, 0.0, 1.0), 2.0);
	COLOR = vec4(edge_color.rgb, glow * strength);
}
