shader_type canvas_item;
// Pixel-art finish for the low-res world: ordered (Bayer 4x4) dithering and
// a limited number of tones per channel. Quantised in a perceptual curve so
// the dark corridor keeps its shades instead of crushing to black.

uniform float levels : hint_range(2.0, 64.0) = 12.0;
uniform float dither : hint_range(0.0, 2.0) = 1.0;
uniform vec3 tint = vec3(1.0, 1.0, 1.0);

const mat4 BAYER = mat4(
	vec4(0.0, 8.0, 2.0, 10.0),
	vec4(12.0, 4.0, 14.0, 6.0),
	vec4(3.0, 11.0, 1.0, 9.0),
	vec4(15.0, 7.0, 13.0, 5.0));

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	vec2 px = floor(UV / TEXTURE_PIXEL_SIZE);
	int x = int(mod(px.x, 4.0));
	int y = int(mod(px.y, 4.0));
	float b = (BAYER[x][y] + 0.5) / 16.0 - 0.5;
	vec3 g = sqrt(max(c.rgb * tint, vec3(0.0)));
	g = floor(g * levels + b * dither + 0.5) / levels;
	COLOR = vec4(g * g, c.a);
}
