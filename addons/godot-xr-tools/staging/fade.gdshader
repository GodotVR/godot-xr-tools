shader_type spatial;
render_mode depth_test_disabled, skip_vertex_transform, unshaded, cull_disabled;

uniform float alpha = 0.0;

void vertex() {
	POSITION = vec4(VERTEX.x, -VERTEX.y, 0.0, 1.0);
}

void fragment() {
	ALBEDO = vec3(0.0, 0.0, 0.0);
	ALPHA = alpha;
}