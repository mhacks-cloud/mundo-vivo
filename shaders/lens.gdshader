shader_type spatial;
render_mode unshaded, fog_disabled, cull_disabled, depth_draw_never, depth_test_disabled;

uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform sampler2D scene_depth : hint_depth_texture, repeat_disable, filter_nearest;
uniform float strength = 0.8;
uniform float focal_distance = 24.0;
uniform float vignette = 0.08;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}
void fragment() {
	vec2 uv = SCREEN_UV;
	float depth = texture(scene_depth, uv).r;
	vec4 view = INV_PROJECTION_MATRIX * vec4(vec3(uv, depth) * 2.0 - 1.0, 1.0);
	float meters = -view.z / view.w;
	float far_blur = smoothstep(focal_distance + 4.0, focal_distance + 22.0, meters);
	float near_blur = 1.0 - smoothstep(focal_distance - 10.0, focal_distance - 5.0, meters);
	float coc = clamp((far_blur + near_blur * 0.51) * strength, 0.0, 1.0);
	vec3 color = textureLod(scene_color, uv, 0.0).rgb;
	if (coc > 0.055) {
		vec2 radius = coc * 3.9 / VIEWPORT_SIZE;
		vec3 soft = textureLod(scene_color, uv, 0.8 * coc).rgb * 0.36;
		soft += textureLod(scene_color, uv + radius * vec2(-1.0, -0.6), coc).rgb * 0.16;
		soft += textureLod(scene_color, uv + radius * vec2(1.0, 0.6), coc).rgb * 0.16;
		soft += textureLod(scene_color, uv + radius * vec2(-0.6, 1.0), coc).rgb * 0.16;
		soft += textureLod(scene_color, uv + radius * vec2(0.6, -1.0), coc).rgb * 0.16;
		color = mix(color, soft, coc);
	}
	float luminance = dot(color, vec3(0.2126, 0.7152, 0.0722));
	color = mix(vec3(luminance), color, 1.05);
	color = max(color * (1.0 + 0.08 * (color - 0.48)), vec3(0.0));
	float edge = smoothstep(0.28, 0.78, length((uv - 0.5) * vec2(1.0, 0.86)));
	ALBEDO = color * (1.0 - vignette * edge);
	ALPHA = 1.0;
}
