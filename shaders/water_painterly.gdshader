shader_type spatial;
render_mode blend_mix, depth_prepass_alpha, specular_schlick_ggx;

uniform vec4 shallow_color: source_color = vec4(0.27, 0.54, 0.62, 0.58);
uniform vec4 deep_color: source_color = vec4(0.12, 0.32, 0.48, 0.72);
uniform float wave_strength = 0.08;
uniform float wave_speed = 0.55;

void vertex() {
	float wave_a = sin(VERTEX.x * 0.08 + TIME * wave_speed);
	float wave_b = cos(VERTEX.z * 0.06 + TIME * wave_speed * 1.32);
	VERTEX.y += (wave_a + wave_b) * wave_strength;
}

void fragment() {
	float wash = sin((VERTEX.x + VERTEX.z) * 0.035 + TIME * 0.22) * 0.5 + 0.5;
	vec4 water = mix(deep_color, shallow_color, wash);
	ALBEDO = water.rgb;
	ALPHA = water.a;
	ROUGHNESS = 0.38;
	METALLIC = 0.0;
}
