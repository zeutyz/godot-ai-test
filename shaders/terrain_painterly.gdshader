shader_type spatial;
render_mode diffuse_toon, specular_disabled, ambient_light_disabled;

uniform float color_wash_strength = 0.16;
uniform float shadow_softness = 0.42;
uniform vec3 warm_light: source_color = vec3(1.0, 0.91, 0.72);
uniform vec3 cool_shadow: source_color = vec3(0.58, 0.67, 0.74);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec3 base_color = COLOR.rgb;
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float paper_noise = hash21(floor(world_position.xz * 0.85));
	float wash = mix(-color_wash_strength, color_wash_strength, paper_noise);
	ALBEDO = clamp(base_color + wash, vec3(0.0), vec3(1.0));
	ROUGHNESS = 1.0;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float band = smoothstep(0.24, 0.24 + shadow_softness, ndotl);
	vec3 ramp = mix(cool_shadow, warm_light, band);
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ramp * ATTENUATION;
}
