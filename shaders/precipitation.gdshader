shader_type canvas_item;
uniform float strength : hint_range(0.0, 1.0) = 0.0;
uniform bool snow = false;
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}
void fragment() {
	vec2 uv = UV;
	uv.x -= uv.y * (snow ? 0.09 : 0.24);
	vec2 p = uv * (snow ? vec2(67.0, 37.0) : vec2(135.0, 35.0));
	p.y -= TIME * (snow ? 3.8 : 44.0);
	vec2 cell = floor(p);
	vec2 f = fract(p);
	float random = hash(cell);
	float x = abs(f.x - (0.20 + random * 0.60));
	float y = abs(f.y - 0.5);
	float drop = (1.0 - smoothstep(0.022, snow ? 0.16 : 0.105, x)) *
		(1.0 - smoothstep(0.035, snow ? 0.14 : 0.39, y));
	float amount = strength * drop * step(0.84, random);
	COLOR = vec4(snow ? vec3(0.94, 0.98, 1.0) : vec3(0.64, 0.81, 0.87), amount * 0.57);
}
