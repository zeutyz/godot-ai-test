shader_type spatial;
render_mode diffuse_toon, specular_disabled, ambient_light_disabled;

uniform float color_wash_strength = 0.16;
uniform float shadow_softness = 0.42;
uniform float rim_strength = 0.16;
uniform vec3 warm_light: source_color = vec3(1.0, 0.91, 0.72);
uniform vec3 cool_shadow: source_color = vec3(0.58, 0.67, 0.74);
uniform vec3 atmospheric_rim: source_color = vec3(0.62, 0.78, 0.70);

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float value_noise(vec2 p) {
	vec2 cell = floor(p);
	vec2 local = fract(p);
	vec2 smooth_local = local * local * (3.0 - 2.0 * local);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, smooth_local.x), mix(c, d, smooth_local.x), smooth_local.y);
}

float fbm(vec2 p) {
	float total = 0.0;
	float amplitude = 0.5;
	for (int octave = 0; octave < 4; octave++) {
		total += value_noise(p) * amplitude;
		p *= 2.03;
		amplitude *= 0.5;
	}
	return total;
}

void fragment() {
	vec3 base_color = COLOR.rgb;
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float paper_noise = fbm(world_position.xz * 0.075);
	float fine_wash = value_noise(world_position.xz * 0.42);
	float wash = mix(-color_wash_strength, color_wash_strength, paper_noise);
	wash += (fine_wash - 0.5) * color_wash_strength * 0.35;
	ALBEDO = clamp(base_color + wash, vec3(0.0), vec3(1.0));
	ROUGHNESS = 1.0;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float band = smoothstep(0.24, 0.24 + shadow_softness, ndotl);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.2) * rim_strength;
	vec3 ramp = mix(cool_shadow, warm_light, band);
	DIFFUSE_LIGHT += (ALBEDO * LIGHT_COLOR * ramp + atmospheric_rim * rim) * ATTENUATION;
}
