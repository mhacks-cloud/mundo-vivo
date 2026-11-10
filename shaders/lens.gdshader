shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene_color : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float defocus : hint_range(0.0, 1.0) = 0.60;
void fragment() {
	vec2 uv = SCREEN_UV;
	float far_edge = (1.0 - smoothstep(0.04, 0.41, uv.y)) * 2.5;
	float near_edge = smoothstep(0.72, 1.0, uv.y) * 2.0;
	vec3 color = textureLod(scene_color, uv, (far_edge + near_edge) * defocus).rgb;
	float vignette = smoothstep(0.31, 0.76, length((uv - 0.5) * vec2(1.0, 0.82)));
	COLOR = vec4(color * (1.0 - 0.18 * vignette), 1.0);
}
