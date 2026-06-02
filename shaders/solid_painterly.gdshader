shader_type spatial;
render_mode diffuse_toon, specular_disabled;

uniform vec4 albedo_color: source_color = vec4(0.5, 0.45, 0.38, 1.0);
uniform float rim_strength = 0.18;

void fragment() {
	ALBEDO = albedo_color.rgb;
	ROUGHNESS = 1.0;
}

void light() {
	float ndotl = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float band = smoothstep(0.2, 0.78, ndotl);
	float rim = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 2.0) * rim_strength;
	vec3 shade = mix(vec3(0.48, 0.54, 0.58), vec3(1.0, 0.94, 0.78), band);
	DIFFUSE_LIGHT += (albedo_color.rgb * shade * LIGHT_COLOR + vec3(0.42, 0.54, 0.60) * rim) * ATTENUATION;
}
