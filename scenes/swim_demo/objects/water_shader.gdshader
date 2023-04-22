shader_type spatial;
render_mode cull_disabled;

// Water material properties
uniform vec3 albedo : source_color = vec3(0.0, 0.0, 0.4);
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float roughness : hint_range(0.0, 1.0) = 0.02;
uniform float alpha = 0.7;

// Noise scale and texture
uniform float scale = 0.05;
uniform sampler2D normal_texture;

void fragment() {
	// Get the world X/Z coordinates
	vec2 world = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).xz * scale;

	// Calculate two time-varying offsets to the noise texture
	vec2 offset1 = vec2(0.05, 0.0) * sin(TIME / 5.0 * PI);
	vec2 offset2 = vec2(0.0, 0.05) * cos(TIME / 5.0 * PI);

	// Sample the noise texture at the two offsets and blend
	vec3 normal1v = texture(normal_texture, world + offset1).rgb;
	vec3 normal2v = texture(normal_texture, world + offset2).rgb;
	vec3 normal = mix(normal1v, normal2v, 0.5);

	// Set the outputs
	ALBEDO = albedo;
	METALLIC = metallic;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal;
	ALPHA = alpha;
}