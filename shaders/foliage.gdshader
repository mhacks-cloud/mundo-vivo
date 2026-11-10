shader_type spatial;
render_mode cull_disabled, diffuse_lambert_wrap, specular_disabled;

uniform sampler2D foliage_texture : source_color, filter_nearest_mipmap, repeat_disable;
uniform vec3 season_tint : source_color = vec3(1.0);
uniform float wind = 0.11;
uniform vec3 camera_origin;
uniform vec3 actor_position;
uniform float cutaway = 0.0;
varying vec3 world_position;
varying vec4 plant_tint;

void vertex() {
	vec3 center = MODEL_MATRIX[3].xyz;
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float sway = sin(TIME * 1.7 + center.x * 1.9 + center.z * 0.72)
		+ 0.42 * sin(TIME * 3.3 + center.x + center.z);
	VERTEX.x += wind * sway * (1.0 - UV.y) * (1.0 - UV.y);
	plant_tint = COLOR;
}

void fragment() {
	vec4 leaf = texture(foliage_texture, UV);
	ALPHA = leaf.a;
	ALPHA_SCISSOR_THRESHOLD = 0.49;
	vec3 ray = actor_position - camera_origin;
	float along = dot(world_position - camera_origin, ray) / max(dot(ray, ray), 0.01);
	vec3 point = camera_origin + ray * along;
	float opening = (1.0 - smoothstep(0.4, 1.15, distance(point, world_position))) * cutaway;
	float dither = fract(dot(floor(FRAGCOORD.xy), vec2(0.754877, 0.56984)));
	if (along > 0.03 && along < 1.05 && dither < opening) {
		discard;
	}
	vec3 tone = mix(season_tint, vec3(1.0), plant_tint.a);
	ALBEDO = leaf.rgb * plant_tint.rgb * tone;
	ROUGHNESS = 1.0;
}
