extends Node2D
## A single frozen moment of another life, seen through a door gap.
## Drawn procedurally so the prototype needs no art yet; each style can
## later be replaced by a painted background in assets/backgrounds/.
## Only the moment is shown — never what comes after.

@export var style: String = "red_light"
@export var active: bool = true

var t: float = 0.0
var _rain: Array[Vector3] = []
var _city: Array[Vector3] = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 200
	for i in 90:
		_rain.append(Vector3(rng.randf(), rng.randf(), rng.randf_range(0.6, 1.4)))
	for i in 26:
		_city.append(Vector3(rng.randf(), rng.randf_range(0.30, 0.52), rng.randf_range(0.4, 1.0)))


func set_style(s: String) -> void:
	style = s
	queue_redraw()


func _process(delta: float) -> void:
	if not active:
		return
	t += delta
	queue_redraw()


func _draw() -> void:
	match style:
		"red_light":
			_draw_red_light()
		"letter":
			_draw_letter()
		"wrong_door":
			_draw_wrong_door()
		"waiting":
			_draw_waiting()
		"train":
			_draw_train()
		_:
			_gradient(Color(0.9, 0.9, 0.9), Color(0.5, 0.5, 0.5))


# --- helpers -------------------------------------------------------------

func _s() -> Vector2:
	return get_viewport_rect().size


func _p(x: float, y: float) -> Vector2:
	var s := _s()
	return Vector2(x * s.x, y * s.y)


func _gradient(top: Color, bottom: Color, y0: float = 0.0, y1: float = 1.0) -> void:
	var a := _p(0, y0)
	var b := _p(1, y1)
	draw_polygon(
		PackedVector2Array([Vector2(a.x, a.y), Vector2(b.x, a.y), Vector2(b.x, b.y), Vector2(a.x, b.y)]),
		PackedColorArray([top, top, bottom, bottom]))


func _rect(x0: float, y0: float, x1: float, y1: float, c: Color) -> void:
	var a := _p(x0, y0)
	var b := _p(x1, y1)
	draw_rect(Rect2(a, b - a), c)


func _glow(center: Vector2, radius: float, c: Color, strength: float = 1.0) -> void:
	var steps := 12
	for i in steps:
		var k := float(i) / steps
		var col := c
		col.a = 0.05 * strength * (0.4 + k)
		draw_circle(center, radius * (1.0 - k * 0.92), col)


func _person(feet: Vector2, h: float, c: Color) -> void:
	var r := h * 0.075
	var shoulders := h * 0.13
	var hips := h * 0.09
	var body := PackedVector2Array([
		feet + Vector2(-h * 0.07, 0),
		feet + Vector2(-hips, -h * 0.46),
		feet + Vector2(-shoulders, -h * 0.74),
		feet + Vector2(-shoulders * 0.7, -h * 0.82),
		feet + Vector2(shoulders * 0.7, -h * 0.82),
		feet + Vector2(shoulders, -h * 0.74),
		feet + Vector2(hips, -h * 0.46),
		feet + Vector2(h * 0.07, 0),
	])
	draw_colored_polygon(body, c)
	draw_circle(feet + Vector2(0, -h * 0.82 - r * 1.05), r, c)


## Silhouette with a thin rim of light so it reads against a dark ground.
func _person_rim(feet: Vector2, h: float, c: Color, rim: Color) -> void:
	var w := maxf(2.0, h * 0.012)
	for o: Vector2 in [Vector2(-w, 0), Vector2(w, 0), Vector2(0, -w), Vector2(w * 0.7, -w * 0.7)]:
		_person(feet + o, h, rim)
	_person(feet, h, c)


func _flicker(speed: float, amount: float) -> float:
	return 1.0 - amount * (0.5 + 0.5 * sin(t * speed) * sin(t * speed * 1.73 + 1.1))


# --- styles --------------------------------------------------------------

func _draw_red_light() -> void:
	var s := _s()
	_gradient(Color(0.02, 0.025, 0.07), Color(0.10, 0.03, 0.05), 0.0, 0.64)
	_gradient(Color(0.06, 0.02, 0.03), Color(0.02, 0.01, 0.02), 0.64, 1.0)
	# far city
	for c in _city:
		var col := Color(1.0, 0.8, 0.55, 0.12 * c.z)
		draw_circle(_p(c.x, c.y), 2.0 + 3.0 * c.z, col)
	# traffic light
	var pulse := 0.9 + 0.1 * sin(t * 1.4)
	_rect(0.655, 0.20, 0.665, 0.64, Color(0.03, 0.03, 0.04))
	_rect(0.62, 0.12, 0.70, 0.30, Color(0.04, 0.04, 0.05))
	var red := _p(0.66, 0.155)
	_glow(red, s.x * 0.34, Color(1.0, 0.12, 0.08), 1.6 * pulse)
	draw_circle(red, s.x * 0.026, Color(1.0, 0.35, 0.28))
	draw_circle(_p(0.66, 0.21), s.x * 0.022, Color(0.12, 0.08, 0.02))
	draw_circle(_p(0.66, 0.265), s.x * 0.022, Color(0.02, 0.08, 0.04))
	# wet road reflections
	draw_polygon(
		PackedVector2Array([_p(0.62, 0.66), _p(0.70, 0.66), _p(0.78, 1.0), _p(0.54, 1.0)]),
		PackedColorArray([Color(1, 0.1, 0.08, 0.30 * pulse), Color(1, 0.1, 0.08, 0.30 * pulse),
			Color(1, 0.1, 0.08, 0.0), Color(1, 0.1, 0.08, 0.0)]))
	# the car (side view, facing right) — driver window down
	var car := Color(0.025, 0.022, 0.03)
	draw_colored_polygon(PackedVector2Array([
		_p(0.26, 0.70), _p(0.26, 0.62), _p(0.38, 0.60), _p(0.48, 0.52), _p(0.74, 0.52),
		_p(0.84, 0.60), _p(0.94, 0.62), _p(0.96, 0.70)]), car)
	# lit window, the man inside, his arm out with the folded note
	draw_colored_polygon(PackedVector2Array([_p(0.51, 0.545), _p(0.71, 0.545), _p(0.78, 0.60), _p(0.48, 0.60)]),
		Color(0.22, 0.10, 0.08))
	_person_rim(_p(0.63, 0.64), s.y * 0.16, Color(0.05, 0.03, 0.03), Color(0.45, 0.20, 0.14))
	# the car door hides him below the window
	draw_colored_polygon(PackedVector2Array([_p(0.26, 0.70), _p(0.26, 0.62), _p(0.38, 0.60), _p(0.84, 0.60),
		_p(0.94, 0.62), _p(0.96, 0.70)]), car)
	draw_line(_p(0.58, 0.59), _p(0.49, 0.585), Color(0.06, 0.035, 0.035), s.x * 0.022)
	draw_rect(Rect2(_p(0.445, 0.575), _p(0.05, 0.016)), Color(0.78, 0.55, 0.75))
	# taillight
	draw_circle(_p(0.265, 0.645), s.x * 0.012, Color(1.0, 0.2, 0.15))
	_glow(_p(0.265, 0.645), s.x * 0.08, Color(1.0, 0.1, 0.1), 0.8)
	# wheels
	draw_circle(_p(0.38, 0.70), s.x * 0.05, Color(0.01, 0.01, 0.01))
	draw_circle(_p(0.83, 0.70), s.x * 0.05, Color(0.01, 0.01, 0.01))
	# the child at the window, reaching
	var child := Color(0.015, 0.01, 0.015)
	_person_rim(_p(0.40, 0.75), s.y * 0.15, child, Color(0.75, 0.16, 0.12, 0.9 * pulse))
	draw_line(_p(0.415, 0.65), _p(0.445, 0.595), Color(0.75, 0.16, 0.12, 0.9 * pulse), s.x * 0.024)
	draw_line(_p(0.415, 0.65), _p(0.445, 0.595), child, s.x * 0.014)
	# rain
	for r in _rain:
		var y := fmod(r.y + t * 0.55 * r.z, 1.0)
		var a := _p(r.x, y)
		draw_line(a, a + Vector2(-s.x * 0.006, s.y * 0.028 * r.z), Color(0.7, 0.7, 0.9, 0.22), 1.5)


func _draw_letter() -> void:
	var s := _s()
	var f := _flicker(7.0, 0.12)
	_gradient(Color(0.05, 0.03, 0.02), Color(0.02, 0.01, 0.008))
	# desk
	_gradient(Color(0.16 * f, 0.09 * f, 0.05 * f), Color(0.05, 0.025, 0.015), 0.62, 1.0)
	# lamp cone
	var lamp := _p(0.60, 0.24)
	draw_polygon(PackedVector2Array([lamp + Vector2(-s.x * 0.04, 0), lamp + Vector2(s.x * 0.04, 0), _p(0.95, 0.70), _p(0.25, 0.70)]),
		PackedColorArray([Color(1, 0.7, 0.35, 0.40 * f), Color(1, 0.7, 0.35, 0.40 * f), Color(1, 0.6, 0.3, 0.0), Color(1, 0.6, 0.3, 0.0)]))
	draw_colored_polygon(PackedVector2Array([lamp + Vector2(-s.x * 0.06, s.y * 0.005), lamp + Vector2(s.x * 0.06, s.y * 0.005),
		lamp + Vector2(s.x * 0.03, -s.y * 0.05), lamp + Vector2(-s.x * 0.03, -s.y * 0.05)]), Color(0.08, 0.05, 0.03))
	draw_line(lamp + Vector2(0, -s.y * 0.05), _p(0.80, 0.02), Color(0.06, 0.04, 0.03), 4)
	_glow(lamp + Vector2(0, s.y * 0.01), s.x * 0.22, Color(1, 0.7, 0.35), 1.4 * f)
	# paper, slightly turned
	var c := _p(0.52, 0.71)
	var u := Vector2(cos(-0.08), sin(-0.08)) * s.x * 0.22
	var v := Vector2(-sin(-0.08), cos(-0.08)) * s.y * 0.085
	draw_colored_polygon(PackedVector2Array([c - u - v, c + u - v, c + u + v, c - u + v]), Color(0.86 * f, 0.78 * f, 0.60 * f))
	for i in 6:
		var k := -0.7 + i * 0.26
		var length := 0.85 if i < 5 else 0.32
		var a := c - u * 0.85 + v * k
		draw_line(a, a + u * 1.7 * length, Color(0.15, 0.10, 0.08, 0.7), 2)
	# pen resting where the sentence stops
	var tip := c - u * 0.85 + u * 1.7 * 0.32 + v * 0.6
	draw_line(tip, tip + Vector2(s.x * 0.09, -s.y * 0.06), Color(0.03, 0.02, 0.02), 6)
	# someone sitting in front of it, back to us
	_person(_p(0.20, 1.06), s.y * 0.55, Color(0.012, 0.008, 0.006))


func _draw_wrong_door() -> void:
	var s := _s()
	var tv := 0.75 + 0.25 * sin(t * 13.0) * sin(t * 5.3)
	_gradient(Color(0.03, 0.035, 0.05), Color(0.01, 0.012, 0.02))
	var light := Color(0.70 * tv, 0.80 * tv, 0.98 * tv)
	_glow(_p(0.51, 0.50), s.x * 0.5, Color(0.6, 0.75, 1.0), 1.2 * tv)
	_rect(0.40, 0.22, 0.62, 0.80, light)
	# floor spill
	draw_polygon(PackedVector2Array([_p(0.40, 0.80), _p(0.62, 0.80), _p(0.80, 1.0), _p(0.25, 1.0)]),
		PackedColorArray([Color(light, 0.5), Color(light, 0.5), Color(light, 0.0), Color(light, 0.0)]))
	# open door leaf
	draw_colored_polygon(PackedVector2Array([_p(0.62, 0.22), _p(0.70, 0.18), _p(0.70, 0.86), _p(0.62, 0.80)]), Color(0.05, 0.05, 0.07))
	# the one holding the door, smiling — we only see the shape
	var holder := Color(0.02, 0.02, 0.03)
	_person(_p(0.50, 0.80), s.y * 0.40, holder)
	draw_line(_p(0.55, 0.52), _p(0.62, 0.50), holder, s.x * 0.022)
	# someone waiting in the dark — barely there
	_person(_p(0.86, 0.90), s.y * 0.46, Color(0.045, 0.05, 0.065))
	draw_line(_p(0.80, 0.52), _p(0.80, 0.80), Color(0.25, 0.32, 0.45, 0.25 * tv), 2)


func _draw_waiting() -> void:
	var s := _s()
	var on := 1.0
	var phase := fmod(t * 0.4, 1.0)
	if phase > 0.90:
		on = 0.35 if int(t * 22.0) % 2 == 0 else 1.0
	_gradient(Color(0.20 * on, 0.25 * on, 0.22 * on), Color(0.10, 0.12, 0.11), 0.0, 0.58)
	_gradient(Color(0.16, 0.18, 0.17), Color(0.07, 0.08, 0.08), 0.58, 1.0)
	# fluorescent tube
	_rect(0.25, 0.085, 0.75, 0.10, Color(0.85 * on, 1.0 * on, 0.92 * on))
	_glow(_p(0.5, 0.093), s.x * 0.4, Color(0.7, 1.0, 0.85), 0.9 * on)
	# queue display
	_rect(0.72, 0.20, 0.88, 0.26, Color(0.03, 0.02, 0.02))
	var font := ThemeDB.fallback_font
	draw_string(font, _p(0.735, 0.248), "A 47", HORIZONTAL_ALIGNMENT_LEFT, -1, int(s.x * 0.05), Color(1.0, 0.25, 0.15))
	# chairs
	for i in 5:
		var x := 0.14 + i * 0.16
		var chair := Color(0.22, 0.32, 0.42)
		_rect(x, 0.50, x + 0.12, 0.62, chair.darkened(0.15))
		_rect(x, 0.62, x + 0.12, 0.65, chair)
		_rect(x + 0.01, 0.65, x + 0.02, 0.74, Color(0.1, 0.1, 0.1))
		_rect(x + 0.10, 0.65, x + 0.11, 0.74, Color(0.1, 0.1, 0.1))
	# the woman with the phone, seated on the middle chair
	var w := Color(0.03, 0.035, 0.035)
	var hip := _p(0.52, 0.63)
	draw_circle(hip + Vector2(0, -s.y * 0.21), s.y * 0.026, w)
	draw_colored_polygon(PackedVector2Array([hip + Vector2(-s.x * 0.05, 0), hip + Vector2(-s.x * 0.065, -s.y * 0.17),
		hip + Vector2(s.x * 0.065, -s.y * 0.17), hip + Vector2(s.x * 0.05, 0)]), w)
	draw_colored_polygon(PackedVector2Array([hip + Vector2(-s.x * 0.05, 0), hip + Vector2(s.x * 0.05, -s.y * 0.02),
		hip + Vector2(s.x * 0.06, s.y * 0.11), hip + Vector2(-s.x * 0.02, s.y * 0.11)]), w)
	# phone, turning in her hands
	var pc := hip + Vector2(0, -s.y * 0.06)
	var ang := sin(t * 1.3) * 1.2
	var pu := Vector2(cos(ang), sin(ang)) * s.x * 0.018
	var pv := Vector2(-sin(ang), cos(ang)) * s.x * 0.032
	draw_colored_polygon(PackedVector2Array([pc - pu - pv, pc + pu - pv, pc + pu + pv, pc - pu + pv]), Color(0.75, 0.92, 1.0))
	_glow(pc, s.x * 0.08, Color(0.7, 0.9, 1.0), 0.8)


func _draw_train() -> void:
	var s := _s()
	_gradient(Color(0.015, 0.015, 0.03), Color(0.03, 0.03, 0.045), 0.0, 0.66)
	# train body
	_rect(-0.1, 0.27, 1.1, 0.66, Color(0.10, 0.11, 0.13))
	for i in 6:
		var x := -0.05 + i * 0.2
		if i == 2:
			continue
		_rect(x, 0.33, x + 0.13, 0.45, Color(0.85, 0.80, 0.66))
	# the open door
	_rect(0.36, 0.30, 0.54, 0.66, Color(0.95, 0.90, 0.76))
	_glow(_p(0.45, 0.48), s.x * 0.35, Color(1.0, 0.92, 0.75), 1.0)
	draw_polygon(PackedVector2Array([_p(0.36, 0.66), _p(0.54, 0.66), _p(0.62, 0.86), _p(0.28, 0.86)]),
		PackedColorArray([Color(1, 0.92, 0.75, 0.35), Color(1, 0.92, 0.75, 0.35), Color(1, 0.92, 0.75, 0.0), Color(1, 0.92, 0.75, 0.0)]))
	# platform
	_gradient(Color(0.09, 0.09, 0.10), Color(0.03, 0.03, 0.035), 0.66, 1.0)
	_rect(0.0, 0.69, 1.0, 0.70, Color(0.65, 0.55, 0.15))
	# one suitcase, nobody
	var sc := Color(0.04, 0.035, 0.035)
	_rect(0.56, 0.74, 0.66, 0.84, sc)
	draw_arc(_p(0.61, 0.74), s.x * 0.025, PI, TAU, 10, sc, 4)
	# headlight of the next one sweeping past now and then
	var sweep := fmod(t * 0.18, 1.0)
	if sweep < 0.35:
		var x := lerpf(-0.3, 1.3, sweep / 0.35)
		draw_polygon(PackedVector2Array([_p(x - 0.08, 0.0), _p(x + 0.08, 0.0), _p(x + 0.2, 1.0), _p(x - 0.2, 1.0)]),
			PackedColorArray([Color(1, 1, 0.95, 0.0), Color(1, 1, 0.95, 0.0), Color(1, 1, 0.95, 0.12), Color(1, 1, 0.95, 0.12)]))
