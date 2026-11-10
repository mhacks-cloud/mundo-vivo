shader_type spatial;
render_mode cull_disabled, diffuse_burley;

uniform float daylight = 0.85;
uniform float rain = 0.0;
varying vec2 river;

void vertex() {
	river = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void fragment() {
	vec2 p = floor(river * 49.0) / 49.0;
	float current = TIME * (0.64 + rain * 0.38);
	float shift = sin(p.y * 1.1 - current) * 0.13 + sin(p.y * 2.5 - current * 1.5) * 0.045;
	vec2 waves = vec2((p.x + shift) * 9.0, p.y * 1.64 - current);
	waves.y += hash(vec2(floor(waves.x), 13.0)) * 3.0;
	vec2 f = fract(waves);
	float seed = hash(floor(waves));
	float crest = (1.0 - smoothstep(0.065, 0.25, abs(f.x - 0.5)))
		* smoothstep(0.13, 0.39, f.y) * (1.0 - smoothstep(0.64, 0.86, f.y));
	float bank = smoothstep(2.33, 2.99, abs(p.x - 13.0));
	float spray = 0.5 + 0.5 * sin(p.y * 5.2 + sin(p.y * 2.51) - current * 2.1);
	float foam = bank * bank * smoothstep(0.54, 0.96, spray) * 0.32;
	float pulse = 0.48 + 0.23 * sin(p.x * 4.0 + sin(p.y * 0.62) - current);
	float reflection = pow(1.0 - max(dot(NORMAL, VIEW), 0.0), 3.1);
	vec3 deep = mix(vec3(0.036, 0.14, 0.16), vec3(0.105, 0.32, 0.27), pulse + bank * 0.21);
	vec3 sky = mix(vec3(0.15, 0.22, 0.34), vec3(0.42, 0.61, 0.64), daylight);
	float sparkle = crest * smoothstep(0.64, 0.96, seed) * (0.11 + reflection * 0.31);
	ALBEDO = mix(deep, sky, reflection * 0.56) + (foam + sparkle) * vec3(0.49, 0.59, 0.55);
	EMISSION = sky * reflection * (0.024 + daylight * 0.065);
	ROUGHNESS = 0.32 + rain * 0.18;
	SPECULAR = 0.48;
}
