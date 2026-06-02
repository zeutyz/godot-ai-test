shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_disabled;

uniform vec4 foliage_color: source_color = vec4(0.32, 0.55, 0.24, 1.0);
uniform float wind_strength = 0.35;
uniform float wind_speed = 0.65;
uniform float wind_scale = 0.055;
uniform float vertical_mask_power = 1.0;
uniform float spherical_normal_strength = 0.0;

float wave(vec2 world_xz, float offset) {
	float broad = sin(world_xz.x * wind_scale + TIME * wind_speed + offset);
	float cross = cos((world_xz.x + world_xz.y) * wind_scale * 0.58 + TIME * wind_speed * 1.37);
	return (broad + cross) * 0.5;
}

void vertex() {
	vec3 world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float height_mask = clamp(pow(max(VERTEX.y, 0.0), vertical_mask_power), 0.0, 1.0);
	float wind = wave(world_position.xz, float(INSTANCE_ID) * 0.173);
	VERTEX.x += wind * wind_strength * height_mask;
	VERTEX.z += wind * wind_strength * 0.35 * height_mask;
	vec3 spherical_normal = normalize(vec3(VERTEX.x, VERTEX.y * 0.72, VERTEX.z));
	NORMAL = normalize(mix(NORMAL, spherical_normal, spherical_normal_strength));
}

void fragment() {
	ALBEDO = foliage_color.rgb;
	ROUGHNESS = 1.0;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float soft_band = smoothstep(0.18, 0.72, ndotl);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0) * 0.24;
	vec3 lit = foliage_color.rgb * mix(vec3(0.55, 0.68, 0.52), vec3(1.05, 1.0, 0.78), soft_band);
	DIFFUSE_LIGHT += (lit + rim * vec3(0.45, 0.75, 0.36)) * LIGHT_COLOR * ATTENUATION;
}
