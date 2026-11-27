shader_type canvas_item;
// Dark edges + a little film grain. Keeps the corridor feeling enclosed.

uniform float strength : hint_range(0.0, 1.0) = 0.85;
uniform float grain : hint_range(0.0, 0.3) = 0.07;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV - 0.5;
	uv.y *= 1.1;
	float v = smoothstep(0.28, 0.78, length(uv)) * strength;
	float n = hash(floor(FRAGCOORD.xy * 0.5) + floor(fract(TIME * 6.0) * 64.0));
	COLOR = vec4(0.0, 0.0, 0.0, clamp(v + n * grain, 0.0, 1.0));
}
