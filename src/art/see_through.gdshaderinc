// F807 (owner, Nov 23): a see-through CIRCLE round the dwarf. Built pieces between the camera and him leave out
// almost all their dots right round him on screen, and fewer and fewer toward the screen's corners.
// The camera (CameraFade) sets the globals every frame. A piece in the way gets its own copy of its paint, whose
// "see_amount" fades it in and out (a plain uniform: an "instance uniform" ran out of room, every prop uses this paint).
// Leaving dots out (a 4x4 checker of thresholds, like the rock's speckle F766) needs no see-through sorting.
global uniform vec3 see_target;  // his chest
global uniform vec3 see_cam;     // the player's camera (shadows are drawn from the lights: those stay whole)
global uniform vec3 see_shape;   // x = how clear in the middle, y = how clear at the corners, z = circle size (screen heights)
uniform float see_amount = 0.0;

const int SEE_BAYER[16] = int[](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);

// True = leave this dot out. vtx = VERTEX (view space) in fragment().
bool see_cut(vec3 vtx, mat4 view, mat4 proj, vec3 cam_world, vec2 frag) {
	if (see_amount <= 0.0 || distance(cam_world, see_cam) > 0.05) {
		return false;
	}
	vec3 tv = (view * vec4(see_target, 1.0)).xyz;
	if (-vtx.z > -tv.z - 0.25) {
		return false;  // only what's in front of him (the floor he stands on stays whole)
	}
	vec2 a = vtx.xy / max(-vtx.z, 0.01);
	vec2 b = tv.xy / max(-tv.z, 0.01);
	float d = length(a - b) * abs(proj[1][1]) * 0.5;  // how far from him on screen, in screen heights (abs: the up-down sign can be flipped)
	float clear = mix(see_shape.x, see_shape.y, smoothstep(see_shape.z * 0.12, see_shape.z, d)) * see_amount;
	ivec2 q = ivec2(frag) % 4;
	return clear > (float(SEE_BAYER[q.y * 4 + q.x]) + 0.5) / 16.0;
}
