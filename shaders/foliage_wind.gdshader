shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_disabled;

uniform vec4 foliage_color: source_color = vec4(0.32, 0.55, 0.24, 1.0);
uniform float wind_strength = 0.35;
uniform float wind_speed = 0.65;
uniform float wind_scale = 0.055;
uniform float vertical_mask_power = 1.0;
uniform float spherical_normal_strength = 0.0;
uniform float instance_tint_strength = 0.18;
uniform float translucency_strength = 0.22;

varying vec3 instance_tint;

float hash11(float value) {
	return fract(sin(value * 127.13) * 43758.5453);
}

float wave(vec2 world_xz, float offset) {
	float broad = sin(world_xz.x * wind_scale + TIME * wind_speed + offset);
	float cross = cos((world_xz.x + world_xz.y) * wind_scale * 0.58 + TIME * wind_speed * 1.37);
	return (broad + cross) * 0.5;
}

void vertex() {
	float id = float(INSTANCE_ID);
	instance_tint = vec3(
		0.86 + hash11(id + 11.0) * 0.24,
		0.88 + hash11(id + 23.0) * 0.22,
		0.80 + hash11(id + 37.0) * 0.18
	);
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height_mask = clamp(pow(max(VERTEX.y, 0.0), vertical_mask_power), 0.0, 1.0);
	float wind_offset = id * 0.173 + hash11(id + 51.0) * TAU;
	float wind = wave(world_position.xz, wind_offset);
	VERTEX.x += wind * wind_strength * height_mask;
	VERTEX.z += wind * wind_strength * 0.35 * height_mask;
	vec3 spherical_normal = normalize(vec3(VERTEX.x, VERTEX.y * 0.72, VERTEX.z));
	NORMAL = normalize(mix(NORMAL, spherical_normal, spherical_normal_strength));
}

void fragment() {
	vec3 tint = mix(vec3(1.0), instance_tint, instance_tint_strength);
	ALBEDO = foliage_color.rgb * tint;
	ROUGHNESS = 1.0;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float soft_band = smoothstep(0.18, 0.72, ndotl);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0) * 0.24;
	float back_light = pow(clamp(dot(-NORMAL, LIGHT), 0.0, 1.0), 1.5) * translucency_strength;
	vec3 tint = mix(vec3(1.0), instance_tint, instance_tint_strength);
	vec3 lit = foliage_color.rgb * tint * mix(vec3(0.55, 0.68, 0.52), vec3(1.05, 1.0, 0.78), soft_band);
	DIFFUSE_LIGHT += (lit + rim * vec3(0.45, 0.75, 0.36) + back_light * vec3(0.50, 0.82, 0.38)) * LIGHT_COLOR * ATTENUATION;
}
