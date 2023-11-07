shader_type spatial;
render_mode unshaded;

uniform sampler2D scope_texture : source_color;
uniform float radius = 0.05;
uniform float depth = 0.35;

varying vec3 v;

void vertex() {
	v = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz - (MODELVIEW_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
}

void fragment() {
	if (length(v) < radius) {

		vec3 view_dir = normalize(normalize(-VERTEX + EYE_OFFSET) * mat3(TANGENT, -BINORMAL, NORMAL));
		vec2 adj_uv = UV - view_dir.xy * (depth * 10.0);

		adj_uv -= vec2(0.5);
		adj_uv *= 0.5;

		if (length(adj_uv) < 0.5) {
			vec4 c = texture(scope_texture, adj_uv + vec2(0.5));
			ALBEDO = c.xyz;
		} else {
			ALBEDO = vec3(0.0);
		}
	} else {
		discard;
	}
}
