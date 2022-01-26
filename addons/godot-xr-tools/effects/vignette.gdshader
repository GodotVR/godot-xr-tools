shader_type spatial;
render_mode depth_test_disable, skip_vertex_transform, unshaded;

uniform vec4 color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float radius = 1.0;
uniform float fade = 0.2;

varying float dist;

void vertex() {
	vec3 v = VERTEX;
	dist = length(v);

	// outer ring is 2.0, inner ring is 1.0, so this scales purely the inner ring
	if (dist < 1.5) {
		dist = radius;
		v *= dist;

		// TODO figure out how to offset this so its centered on the eye
		// we can probably calculate this from our projection matrix
	}
	POSITION = vec4(v, 1.0);
}

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = clamp((dist - radius) / fade, 0.0, 1.0);
}
