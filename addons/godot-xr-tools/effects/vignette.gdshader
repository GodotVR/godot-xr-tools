shader_type spatial;
render_mode depth_test_disabled, skip_vertex_transform, unshaded, cull_disabled;

uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float radius = 1.0;
uniform float fade = 0.05;

varying float dist;

void vertex() {
	vec2 v = VERTEX.xy;
	dist = length(v);

	// outer ring is 2.0, inner ring is 1.0, so this scales purely the inner ring
	if (dist < 1.5) {
		// Adjust by radius
		dist = radius;
		v *= dist;

		// We don't know our eye center, projecting a center point in the distance gives us a good enough approximation
		vec4 eye = PROJECTION_MATRIX * vec4(0.0, 0.0, 100.0, 1.0);

		// and we offset our inner circle
		v += eye.xy / eye.w;
	}

	float z = PROJECTION_MATRIX[2][2] < 0.0 ? 0.0 : 1.0;
	POSITION = vec4(v, z, 1.0);
}

void fragment() {
	ALBEDO = color.rgb;
	ALPHA = clamp((dist - radius) / fade, 0.0, 1.0);
}
