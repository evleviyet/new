extends RefCounted
## Shared, quiet UI look: thin borders, dark glass, warm off-white text.
## Pixelify Sans for labels and buttons, Lora for everything that is read.

const TEXT := Color(0.92, 0.90, 0.85)
const TEXT_DIM := Color(0.92, 0.90, 0.85, 0.55)

const PIXEL_PATH := "res://assets/fonts/PixelifySans.ttf"
const SERIF_PATH := "res://assets/fonts/Lora.ttf"
const ITALIC_PATH := "res://assets/fonts/Lora-Italic.ttf"


## Pixelify Sans with a wider word space, which it needs at UI sizes.
static func pixel() -> Font:
	return load("res://assets/fonts/pixel_ui.tres")


## Pixelify with generous letter spacing, for small headings like ADAM.
static func spaced_pixel() -> Font:
	var f := FontVariation.new()
	f.base_font = load(PIXEL_PATH)
	f.spacing_glyph = 5
	f.spacing_space = 10
	return f


static func serif() -> Font:
	return load(SERIF_PATH)


static func italic() -> Font:
	return load(ITALIC_PATH)


static func weighted(path: String, weight: int) -> Font:
	var f := FontVariation.new()
	f.base_font = load(path)
	f.variation_opentype = {"wght": weight}
	return f


static func style_title(label: Label, size: int) -> void:
	label.add_theme_font_override("font", pixel())
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_constant_override("outline_size", 0)


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = serif()
	t.default_font_size = 28

	var normal := _box(Color(0.02, 0.02, 0.03, 0.6), Color(0.92, 0.88, 0.80, 0.45))
	var pressed := _box(Color(0.95, 0.92, 0.85, 0.16), Color(0.95, 0.92, 0.85, 0.85))
	var disabled := _box(Color(0.02, 0.02, 0.03, 0.3), Color(0.92, 0.88, 0.80, 0.15))
	var cls := "Button"
	t.set_stylebox("normal", cls, normal)
	t.set_stylebox("hover", cls, normal)
	t.set_stylebox("pressed", cls, pressed)
	t.set_stylebox("hover_pressed", cls, pressed)
	t.set_stylebox("disabled", cls, disabled)
	t.set_stylebox("focus", cls, StyleBoxEmpty.new())
	t.set_color("font_color", cls, TEXT)
	t.set_color("font_hover_color", cls, TEXT)
	t.set_color("font_pressed_color", cls, Color.WHITE)
	t.set_color("font_hover_pressed_color", cls, Color.WHITE)
	t.set_color("font_focus_color", cls, TEXT)
	t.set_color("font_disabled_color", cls, TEXT_DIM)
	t.set_font("font", cls, pixel())
	t.set_font_size("font_size", cls, 30)

	t.set_color("font_color", "Label", TEXT)
	t.set_font_size("font_size", "Label", 28)
	t.set_constant("line_spacing", "Label", 6)
	return t


static func _box(bg: Color, border: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = bg
	b.border_color = border
	b.set_border_width_all(2)
	b.set_corner_radius_all(0)
	b.content_margin_left = 20
	b.content_margin_right = 20
	b.content_margin_top = 14
	b.content_margin_bottom = 14
	return b
