shader_type spatial;
render_mode cull_disabled, diffuse_burley;

varying vec2 river;
void vertex() {
	river = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void fragment() {
	vec2 p = floor(river * 32.0) / 32.0;
	float shear = sin(p.y * 0.70 + TIME * 0.38) * 0.15 + sin(p.y * 1.30 - TIME * 0.7) * 0.09;
	vec2 wave = vec2((p.x + shear) * 10.0, p.y * 1.35 - TIME * 0.75);
	wave.y += hash(vec2(floor(wave.x), 13.0)) * 3.0;
	vec2 cell = floor(wave);
	vec2 f = fract(wave);
	float seed = hash(cell);
	float line = (1.0 - smoothstep(0.04, 0.22, abs(f.x - 0.5))) *
		smoothstep(0.16, 0.38, f.y) * (1.0 - smoothstep(0.64, 0.88, f.y));
	float foam = line * smoothstep(0.67, 0.98, seed);
	float bank = smoothstep(2.44, 3.0, abs(river.x - 13.0));
	float ripple = sin(p.x * 7.2 + p.y * 0.86 - TIME * 0.81) * 0.11 + 0.40;
	vec3 deep = mix(vec3(0.055, 0.16, 0.17), vec3(0.10, 0.31, 0.25), ripple + bank * 0.27);
	ALBEDO = mix(deep, vec3(0.38, 0.59, 0.46), foam * 0.52 + bank * 0.09);
	ROUGHNESS = 0.43;
	SPECULAR = 0.42;
}
