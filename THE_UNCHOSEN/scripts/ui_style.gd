extends RefCounted
## Shared, quiet UI look: thin borders, dark glass, warm off-white text.

const TEXT := Color(0.92, 0.90, 0.85)
const TEXT_DIM := Color(0.92, 0.90, 0.85, 0.55)


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = 28

	var normal := _box(Color(0.02, 0.02, 0.03, 0.55), Color(0.92, 0.88, 0.80, 0.45))
	var pressed := _box(Color(0.95, 0.92, 0.85, 0.16), Color(0.95, 0.92, 0.85, 0.85))
	var disabled := _box(Color(0.02, 0.02, 0.03, 0.3), Color(0.92, 0.88, 0.80, 0.15))
	for cls in ["Button"]:
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
	b.set_corner_radius_all(4)
	b.content_margin_left = 20
	b.content_margin_right = 20
	b.content_margin_top = 14
	b.content_margin_bottom = 14
	return b
