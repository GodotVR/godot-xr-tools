shader_type spatial;
render_mode depth_test_disable, skip_vertex_transform, unshaded;

uniform float alpha = 0.0;

void vertex() {
	vec3 v = VERTEX;
	POSITION = vec4(v, 1.0);
}

void fragment() {
	ALBEDO = vec3(0.0, 0.0, 0.0);
	ALPHA = alpha;
}