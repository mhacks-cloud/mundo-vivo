shader_type spatial;
render_mode diffuse_burley;

uniform sampler2D grass_map : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_map : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D cobble_map : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform sampler2D bank_map : source_color, filter_nearest_mipmap_anisotropic, repeat_enable;
uniform vec4 footprints[9];
uniform vec3 ground_tint : source_color = vec3(1.0);
uniform float wetness = 0.0;
uniform float frost = 0.0;
varying vec2 position_xz;

void vertex() {
	position_xz = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}
float rect(vec2 p, vec2 center, vec2 extent) {
	vec2 d = abs(p - center) - extent;
	return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0);
}
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(41.17, 81.91))) * 43758.545);
}
void fragment() {
	vec2 p = position_xz;
	float ragged = sin(p.x * 4.5 + p.y * 0.8) * 0.11 + sin(p.y * 7.2 - p.x) * 0.11
		+ (hash(floor(p * 19.0)) - 0.5) * 0.14;
	float stone = min(rect(p, vec2(0.0), vec2(5.87, 4.44)), rect(p, vec2(0.0, 2.0), vec2(9.95, 1.3)));
	stone = min(stone, rect(p, vec2(0.0, -9.0), vec2(1.03, 5.62)));
	float trail = min(rect(p, vec2(0.0, 8.5), vec2(1.11, 6.0)), rect(p, vec2(-9.0, 7.0), vec2(8.0, 0.83)));
	trail = min(trail, rect(p, vec2(-1.0, -12.0), vec2(10.95, 0.94)));
	trail = min(trail, rect(p, vec2(18.7, -12.0), vec2(2.75, 1.0)));
	trail = min(trail, rect(p, vec2(20.3, 2.0), vec2(4.32, 1.25)));
	trail = min(trail, rect(p, vec2(21.0, -9.0), vec2(1.08, 10.2)));
	float shore = 1.0 - smoothstep(0.0, 0.96, abs(abs(p.x - 13.0) - 3.0) + ragged);
	float cobble = 1.0 - smoothstep(-0.10, 0.20, stone + ragged);
	float dirt = 1.0 - smoothstep(-0.16, 0.24, trail + ragged);
	vec3 grass = texture(grass_map, p * 0.40).rgb * ground_tint;
	float mottled = sin(p.x * 0.61 + sin(p.y * 0.42)) * sin(p.y * 0.53 - p.x * 0.29);
	grass *= 0.79 + 0.24 * mottled + 0.10 * sin(p.x * 1.22 + p.y * 1.05);
	grass = mix(grass, vec3(0.70, 0.75, 0.72), frost * smoothstep(-0.4, 0.4, mottled));
	vec3 earth = texture(dirt_map, p * 0.43).rgb * vec3(0.92, 0.84, 0.72);
	vec3 stone_color = texture(cobble_map, p * 0.25).rgb * vec3(0.93, 0.91, 0.82);
	vec3 roots = texture(bank_map, p * 0.51).rgb;
	float contact = 1.0;
	for (int i = 0; i < 9; i++) {
		float dist = rect(p, footprints[i].xy, footprints[i].zw);
		contact = min(contact, 0.53 + 0.47 * smoothstep(-0.04, 0.86, dist + ragged * 0.2));
	}
	float moss = smoothstep(0.10, 0.45, mottled) * (1.0 - smoothstep(0.1, 0.9, abs(stone)));
	stone_color = mix(stone_color, grass, moss * 0.25);
	ALBEDO = mix(mix(mix(grass, roots, shore), earth, dirt), stone_color, cobble)
		* contact * (1.0 - wetness * 0.25);
	ROUGHNESS = mix(0.96, 0.66, wetness * cobble);
	SPECULAR = 0.22;
	AO = contact;
}
