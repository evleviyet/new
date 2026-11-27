extends Node2D
## A single moment of a life, drawn procedurally and rendered small, so it
## comes out as pixel art. Used for what is seen through a door gap and for
## every card inside a life. Only the moment is shown — never what comes
## after.

@export var style: String = "red_light"
@export var active: bool = true
## Story flags, so a scene can remember what happened (a bag on the table,
## a chocolate wrapper). Empty in the corridor.
var flags: Dictionary = {}
## True once a life has been lived: other doors show traces of it.
var after: bool = false
## The corridor's last moment: three strangers on one platform.
var finale: bool = false

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
		"car_interior":
			_draw_car_interior(false)
		"car_interior_green":
			_draw_car_interior(true)
		"car_window":
			_draw_car_window(false)
		"car_window_open":
			_draw_car_window(true)
		"glass_reflection":
			_draw_glass_reflection()
		"market":
			_draw_market()
		"empty_street":
			_draw_empty_street()
		"uphill":
			_draw_uphill()
		"pickup_cab":
			_draw_pickup_cab()
		"home_door":
			_draw_home_door()
		"home_inside":
			_draw_home_inside()
		"night_door":
			_draw_night_door()
		"child_room":
			_draw_child_room()
		"letter_blank":
			_draw_letter_blank()
		"phone_table":
			_draw_phone_table()
		"postbox":
			_draw_postbox()
		"drawer":
			_draw_drawer()
		"envelope_door":
			_draw_envelope_door()
		"old_room":
			_draw_old_room()
		"apartment_entry":
			_draw_apartment_entry()
		"stairwell":
			_draw_stairwell()
		"door_ajar":
			_draw_door_ajar()
		"door_inside":
			_draw_door_inside()
		"peephole":
			_draw_peephole()
		"window_street":
			_draw_window_street()
		"suitcase":
			_draw_suitcase()
		_:
			_draw_dark()


func _f(name: String) -> bool:
	return bool(flags.get(name, false))


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
	if after:
		_person(_p(0.84, 0.90), s.y * 0.26, Color(0.05, 0.055, 0.07))
		for i in 3:
			_rect(0.88 + i * 0.02, 0.74, 0.895 + i * 0.02, 0.76, Color(0.6, 0.6, 0.6, 0.6))
	else:
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
	if after:
		# a man on the phone, two chairs away
		var mh := _p(0.20, 0.63)
		var m := Color(0.035, 0.035, 0.04)
		draw_circle(mh + Vector2(0, -s.y * 0.23), s.y * 0.028, m)
		draw_colored_polygon(PackedVector2Array([mh + Vector2(-s.x * 0.06, 0), mh + Vector2(-s.x * 0.07, -s.y * 0.19),
			mh + Vector2(s.x * 0.07, -s.y * 0.19), mh + Vector2(s.x * 0.06, 0)]), m)
		draw_line(mh + Vector2(s.x * 0.05, -s.y * 0.18), mh + Vector2(s.x * 0.03, -s.y * 0.23), m, s.x * 0.02)


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
	if after:
		for i in 4:
			_rect(0.565 + i * 0.022, 0.725, 0.583 + i * 0.022, 0.74, Color(0.85, 0.85, 0.80))
	if finale:
		# a man in a coat, a young man, an old man — apart, not looking at each other
		_person_rim(_p(0.36, 0.90), s.y * 0.30, Color(0.03, 0.03, 0.035), Color(1, 0.92, 0.75, 0.5))
		_person_rim(_p(0.50, 0.92), s.y * 0.26, Color(0.03, 0.03, 0.035), Color(1, 0.92, 0.75, 0.5))
		_person_rim(_p(0.65, 0.91), s.y * 0.29, Color(0.03, 0.03, 0.035), Color(1, 0.92, 0.75, 0.5))
	# headlight of the next one sweeping past now and then
	var sweep := fmod(t * 0.18, 1.0)
	if sweep < 0.35:
		var x := lerpf(-0.3, 1.3, sweep / 0.35)
		draw_polygon(PackedVector2Array([_p(x - 0.08, 0.0), _p(x + 0.08, 0.0), _p(x + 0.2, 1.0), _p(x - 0.2, 1.0)]),
			PackedColorArray([Color(1, 1, 0.95, 0.0), Color(1, 1, 0.95, 0.0), Color(1, 1, 0.95, 0.12), Color(1, 1, 0.95, 0.12)]))


# --- shared bits for the life scenes -------------------------------------

func _poly(pts: Array, c: Color) -> void:
	var out := PackedVector2Array()
	for v: Vector2 in pts:
		out.append(_p(v.x, v.y))
	draw_colored_polygon(out, c)


func _rain_layer(col: Color, amount: int = 90, speed: float = 0.55, slant: float = -0.006) -> void:
	var s := _s()
	for i in mini(amount, _rain.size()):
		var r: Vector3 = _rain[i]
		var y := fmod(r.y + t * speed * r.z, 1.0)
		var a := _p(r.x, y)
		draw_line(a, a + Vector2(s.x * slant, s.y * 0.03 * r.z), col, 1.0)


## Drops sitting on glass, sliding now and then.
func _drops(rect: Rect2, col: Color) -> void:
	var s := _s()
	for i in 40:
		var r: Vector3 = _rain[i]
		var slide := fmod(t * 0.04 * r.z + r.y, 1.0) if i % 5 == 0 else r.y
		var p := Vector2(rect.position.x + r.x * rect.size.x, rect.position.y + slide * rect.size.y)
		draw_circle(_p(p.x, p.y), maxf(1.0, s.x * 0.006 * r.z), col)


func _lit_windows(y0: float, y1: float, seed_n: int, col: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_n
	for i in 14:
		var x := rng.randf()
		var y := rng.randf_range(y0, y1)
		if rng.randf() < 0.55:
			_rect(x, y, x + 0.025, y + 0.02, col * Color(1, 1, 1, rng.randf_range(0.4, 1.0)))


func _draw_dark() -> void:
	_gradient(Color(0.02, 0.02, 0.03), Color(0.0, 0.0, 0.0))
	_rain_layer(Color(0.5, 0.5, 0.6, 0.12), 40, 0.3)


# --- ADAM ----------------------------------------------------------------

func _draw_car_interior(green: bool) -> void:
	var s := _s()
	var sig := Color(0.25, 1.0, 0.45) if green else Color(1.0, 0.14, 0.10)
	_gradient(Color(0.03, 0.03, 0.07), sig * Color(0.18, 0.08, 0.08) + Color(0.04, 0.03, 0.05), 0.0, 0.62)
	# city ahead
	_rect(0.0, 0.40, 0.22, 0.62, Color(0.03, 0.03, 0.05))
	_rect(0.70, 0.34, 1.0, 0.62, Color(0.03, 0.03, 0.05))
	_rect(0.24, 0.46, 0.40, 0.62, Color(0.04, 0.035, 0.05))
	_lit_windows(0.36, 0.58, 7, Color(1.0, 0.8, 0.5, 0.5))
	# road and the light
	_gradient(Color(0.05, 0.04, 0.05), Color(0.02, 0.02, 0.03), 0.62, 1.0)
	var lamp := _p(0.60, 0.26)
	_rect(0.595, 0.30, 0.605, 0.62, Color(0.02, 0.02, 0.03))
	_rect(0.57, 0.18, 0.63, 0.34, Color(0.03, 0.03, 0.04))
	_glow(lamp + (Vector2(0, s.y * 0.05) if green else Vector2.ZERO), s.x * 0.3, sig, 1.4)
	draw_circle(_p(0.60, 0.215), s.x * 0.018, Color(1, 0.35, 0.3) if not green else Color(0.15, 0.05, 0.05))
	draw_circle(_p(0.60, 0.30), s.x * 0.018, Color(0.4, 1.0, 0.55) if green else Color(0.03, 0.08, 0.04))
	draw_polygon(PackedVector2Array([_p(0.56, 0.62), _p(0.64, 0.62), _p(0.70, 0.78), _p(0.50, 0.78)]),
		PackedColorArray([Color(sig, 0.25), Color(sig, 0.25), Color(sig, 0.0), Color(sig, 0.0)]))
	# glass: drops and a wiper
	_drops(Rect2(0.05, 0.05, 0.9, 0.62), Color(0.8, 0.8, 1.0, 0.18))
	var ang := -0.2 - 1.2 * (0.5 + 0.5 * sin(t * 1.6))
	var piv := _p(0.30, 0.80)
	draw_line(piv, piv + Vector2(cos(ang), sin(ang)) * s.x * 0.55, Color(0.01, 0.01, 0.01), maxf(2.0, s.x * 0.012))
	# A-pillars, dashboard, wheel
	_poly([Vector2(0, 0), Vector2(0.10, 0), Vector2(0.0, 0.70)], Color(0.015, 0.012, 0.015))
	_poly([Vector2(0.90, 0), Vector2(1, 0), Vector2(1, 0.70)], Color(0.015, 0.012, 0.015))
	_poly([Vector2(0, 0.70), Vector2(1, 0.66), Vector2(1, 1), Vector2(0, 1)], Color(0.025, 0.02, 0.025))
	draw_arc(_p(0.30, 1.02), s.x * 0.24, PI * 1.08, PI * 1.92, 24, Color(0.01, 0.01, 0.012), maxf(3.0, s.x * 0.035))
	_rect(0.62, 0.74, 0.74, 0.78, sig * Color(0.5, 0.5, 0.5, 0.6))


func _draw_car_window(open: bool) -> void:
	var s := _s()
	# street seen through the side window
	_gradient(Color(0.05, 0.03, 0.06), Color(0.14, 0.04, 0.05), 0.08, 0.70)
	_lit_windows(0.12, 0.40, 3, Color(1.0, 0.75, 0.5, 0.35))
	_glow(_p(0.85, 0.12), s.x * 0.35, Color(1.0, 0.12, 0.08), 1.0)
	_rain_layer(Color(0.7, 0.7, 0.9, 0.22), 60)
	# the child
	var kid := Color(0.02, 0.012, 0.016)
	var rim := Color(0.85, 0.2, 0.15, 0.6)
	var kf := _p(0.52, 1.12)
	_person_rim(kf, s.y * 0.80, kid, rim)
	# tissue packets in a raised hand
	draw_line(_p(0.43, 0.74), _p(0.37, 0.58), kid, s.x * 0.045)
	for i in 3:
		_rect(0.31 + i * 0.035, 0.53, 0.34 + i * 0.035, 0.58, Color(0.85, 0.85, 0.80))
	if not open:
		# glass: reflection and condensation
		_poly([Vector2(0.08, 0.08), Vector2(0.92, 0.08), Vector2(0.92, 0.70), Vector2(0.08, 0.70)], Color(0.6, 0.65, 0.8, 0.10))
		_drops(Rect2(0.08, 0.08, 0.84, 0.62), Color(0.85, 0.85, 1.0, 0.25))
		var knock := absf(sin(t * 3.0))
		if knock > 0.9:
			_glow(_p(0.62, 0.40), s.x * 0.06, Color(1, 1, 1), 0.6)
	else:
		# window down: the note between two hands
		_rect(0.08, 0.66, 0.92, 0.70, Color(0.25, 0.28, 0.35, 0.6))
		draw_line(_p(0.05, 0.92), _p(0.30, 0.66), Color(0.05, 0.035, 0.035), s.x * 0.06)
		_rect(0.27, 0.62, 0.37, 0.66, Color(0.80, 0.56, 0.76))
	# door frame around the window
	_poly([Vector2(0, 0), Vector2(1, 0), Vector2(1, 0.08), Vector2(0, 0.08)], Color(0.03, 0.025, 0.03))
	_poly([Vector2(0, 0), Vector2(0.08, 0), Vector2(0.08, 1), Vector2(0, 1)], Color(0.03, 0.025, 0.03))
	_poly([Vector2(0.92, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0.92, 1)], Color(0.03, 0.025, 0.03))
	_poly([Vector2(0, 0.70), Vector2(1, 0.70), Vector2(1, 1), Vector2(0, 1)], Color(0.045, 0.035, 0.04))
	_rect(0.60, 0.78, 0.78, 0.80, Color(0.12, 0.08, 0.08))


# --- ÇOCUK ---------------------------------------------------------------

func _draw_glass_reflection() -> void:
	var s := _s()
	# the car body and its dark window
	_gradient(Color(0.06, 0.03, 0.05), Color(0.02, 0.01, 0.02))
	_poly([Vector2(0.0, 0.18), Vector2(1.0, 0.12), Vector2(1.0, 0.75), Vector2(0.0, 0.80)], Color(0.05, 0.05, 0.07))
	_poly([Vector2(0.06, 0.22), Vector2(0.94, 0.17), Vector2(0.94, 0.70), Vector2(0.06, 0.74)], Color(0.07, 0.07, 0.10))
	# inside: a man turning his head away, lit by his phone
	_person(_p(0.70, 0.95), s.y * 0.75, Color(0.035, 0.035, 0.05))
	_glow(_p(0.62, 0.55), s.x * 0.12, Color(0.5, 0.7, 1.0), 0.6)
	_rect(0.60, 0.53, 0.635, 0.58, Color(0.6, 0.8, 1.0, 0.8))
	# on the glass: your own face
	var me := Color(0.75, 0.25, 0.2, 0.22)
	draw_circle(_p(0.33, 0.40), s.x * 0.11, me)
	_poly([Vector2(0.18, 0.74), Vector2(0.22, 0.54), Vector2(0.44, 0.54), Vector2(0.48, 0.74)], me)
	_drops(Rect2(0.06, 0.2, 0.88, 0.52), Color(0.9, 0.9, 1.0, 0.25))
	_rain_layer(Color(0.7, 0.7, 0.9, 0.18), 50)
	_glow(_p(0.95, 0.05), s.x * 0.4, Color(1.0, 0.12, 0.08), 0.7)


func _draw_market() -> void:
	var s := _s()
	var hum := 0.96 + 0.04 * sin(t * 50.0)
	_gradient(Color(0.30 * hum, 0.33 * hum, 0.30 * hum), Color(0.16, 0.17, 0.16), 0.0, 0.70)
	_gradient(Color(0.20, 0.21, 0.20), Color(0.10, 0.10, 0.10), 0.70, 1.0)
	for i in 3:
		_rect(0.08 + i * 0.32, 0.04, 0.28 + i * 0.32, 0.06, Color(0.95, 1.0, 0.95))
	# shelves with things on them
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for row in 4:
		var y := 0.16 + row * 0.12
		_rect(0.0, y + 0.08, 0.55, y + 0.09, Color(0.35, 0.35, 0.33))
		var x := 0.01
		while x < 0.53:
			var w := rng.randf_range(0.025, 0.05)
			var h := rng.randf_range(0.04, 0.075)
			_rect(x, y + 0.08 - h, x + w, y + 0.08, Color.from_hsv(rng.randf(), 0.5, rng.randf_range(0.4, 0.8)))
			x += w + 0.006
	# window to the street: rain, a red glow
	_rect(0.62, 0.10, 0.98, 0.55, Color(0.05, 0.04, 0.07))
	_glow(_p(0.86, 0.22), s.x * 0.15, Color(1.0, 0.15, 0.1), 0.8)
	for i in 20:
		var r: Vector3 = _rain[i]
		var y := fmod(r.y + t * 0.5 * r.z, 1.0) * 0.45 + 0.10
		var a := _p(0.62 + r.x * 0.36, y)
		draw_line(a, a + Vector2(0, s.y * 0.02), Color(0.7, 0.7, 0.9, 0.3), 1.0)
	# counter, chocolate rack, the queue
	_rect(0.55, 0.62, 1.0, 0.72, Color(0.25, 0.22, 0.20))
	for i in 6:
		_rect(0.58 + i * 0.03, 0.57, 0.605 + i * 0.03, 0.62, Color(0.55, 0.25, 0.15) if i % 2 == 0 else Color(0.85, 0.75, 0.2))
	var q := Color(0.08, 0.08, 0.09)
	_person(_p(0.72, 0.98), s.y * 0.62, q)
	_person(_p(0.56, 1.0), s.y * 0.66, q * Color(1.2, 1.2, 1.2))
	# the child, last in line: water and bread
	var kid := Color(0.05, 0.04, 0.05)
	_person(_p(0.36, 1.0), s.y * 0.42, kid)
	_rect(0.26, 0.80, 0.29, 0.88, Color(0.6, 0.8, 0.95))
	_rect(0.41, 0.80, 0.48, 0.84, Color(0.85, 0.65, 0.35))
	if _f("chocolate"):
		_rect(0.42, 0.85, 0.46, 0.87, Color(0.55, 0.25, 0.15))


func _draw_empty_street() -> void:
	var s := _s()
	_gradient(Color(0.02, 0.03, 0.05), Color(0.03, 0.06, 0.05), 0.0, 0.62)
	_lit_windows(0.10, 0.45, 21, Color(1.0, 0.8, 0.5, 0.25))
	_gradient(Color(0.04, 0.06, 0.05), Color(0.015, 0.02, 0.02), 0.62, 1.0)
	# green, for nobody
	var g := Color(0.25, 1.0, 0.45)
	_rect(0.795, 0.12, 0.805, 0.62, Color(0.02, 0.02, 0.03))
	_rect(0.77, 0.08, 0.83, 0.24, Color(0.03, 0.03, 0.04))
	_glow(_p(0.80, 0.20), s.x * 0.28, g, 1.3)
	draw_circle(_p(0.80, 0.20), s.x * 0.016, Color(0.5, 1.0, 0.6))
	draw_polygon(PackedVector2Array([_p(0.74, 0.64), _p(0.86, 0.64), _p(0.98, 1.0), _p(0.62, 1.0)]),
		PackedColorArray([Color(g, 0.25), Color(g, 0.25), Color(g, 0.0), Color(g, 0.0)]))
	# market door spilling light on the left
	_rect(0.0, 0.30, 0.18, 0.66, Color(0.85, 0.95, 0.85))
	draw_polygon(PackedVector2Array([_p(0.0, 0.66), _p(0.18, 0.66), _p(0.36, 1.0), _p(0.0, 1.0)]),
		PackedColorArray([Color(0.8, 0.95, 0.8, 0.3), Color(0.8, 0.95, 0.8, 0.3), Color(0.8, 0.95, 0.8, 0.0), Color(0.8, 0.95, 0.8, 0.0)]))
	# the curb where the car was
	_rect(0.0, 0.70, 1.0, 0.715, Color(0.12, 0.12, 0.12))
	# a small figure with a bag
	var kid := Color(0.01, 0.012, 0.012)
	_person_rim(_p(0.30, 0.86), s.y * 0.30, kid, Color(0.6, 0.9, 0.65, 0.6))
	_rect(0.33, 0.76, 0.37, 0.81, Color(0.85, 0.85, 0.82))
	_rain_layer(Color(0.7, 0.8, 0.8, 0.22), 80)


func _draw_uphill() -> void:
	var s := _s()
	_gradient(Color(0.03, 0.03, 0.06), Color(0.06, 0.05, 0.08), 0.0, 1.0)
	# houses climbing to the right
	for i in 5:
		var x := 0.15 + i * 0.18
		var top := 0.55 - i * 0.07
		_rect(x, top, x + 0.17, 1.0, Color(0.05 + i * 0.004, 0.045, 0.06))
		_poly([Vector2(x - 0.01, top), Vector2(x + 0.085, top - 0.07), Vector2(x + 0.18, top)], Color(0.04, 0.035, 0.05))
	# one window: warm, with a shadow passing
	var wx := 0.79
	var wy := 0.32
	_rect(wx, wy, wx + 0.07, wy + 0.08, Color(1.0, 0.75, 0.40))
	_glow(_p(wx + 0.035, wy + 0.04), s.x * 0.18, Color(1.0, 0.7, 0.35), 0.9)
	var sh := fmod(t * 0.25, 1.0)
	if sh < 0.5:
		_rect(wx + sh * 0.1, wy, wx + sh * 0.1 + 0.03, wy + 0.08, Color(0.25, 0.15, 0.08))
	# the slope
	_poly([Vector2(0, 1.0), Vector2(0, 0.88), Vector2(1, 0.55), Vector2(1, 1.0)], Color(0.07, 0.065, 0.07))
	# street lamp
	_rect(0.40, 0.40, 0.41, 0.76, Color(0.02, 0.02, 0.02))
	_glow(_p(0.405, 0.40), s.x * 0.2, Color(1.0, 0.85, 0.55), 0.9)
	# the child walking up
	var kid := Color(0.012, 0.01, 0.012)
	_person_rim(_p(0.30, 0.80), s.y * 0.22, kid, Color(1.0, 0.8, 0.5, 0.5))
	if _f("errand") and not _f("returned_goods") and not _f("waited_long"):
		_rect(0.32, 0.72, 0.35, 0.76, Color(0.85, 0.85, 0.82))
	_rain_layer(Color(0.7, 0.7, 0.9, 0.2), 70)


# --- BABA ----------------------------------------------------------------

func _draw_pickup_cab() -> void:
	var s := _s()
	var green := fmod(t * 0.12, 1.0) > 0.6
	var sig := Color(0.25, 1.0, 0.45) if green else Color(1.0, 0.14, 0.10)
	_gradient(Color(0.04, 0.04, 0.06), Color(0.08, 0.06, 0.07), 0.0, 0.60)
	_gradient(Color(0.05, 0.05, 0.06), Color(0.03, 0.03, 0.04), 0.60, 1.0)
	_glow(_p(0.80, 0.14), s.x * 0.25, sig, 1.1)
	draw_circle(_p(0.80, 0.14), s.x * 0.016, sig.lightened(0.3))
	# the car in front — rear view
	var car := Color(0.03, 0.03, 0.04)
	_poly([Vector2(0.22, 0.62), Vector2(0.28, 0.44), Vector2(0.62, 0.44), Vector2(0.68, 0.62)], car)
	_rect(0.18, 0.60, 0.72, 0.74, car)
	_rect(0.30, 0.47, 0.60, 0.56, Color(0.10, 0.08, 0.09))
	for x in [0.22, 0.65]:
		_rect(x, 0.62, x + 0.05, 0.655, Color(1.0, 0.2, 0.15))
		_glow(_p(x + 0.025, 0.64), s.x * 0.07, Color(1.0, 0.15, 0.1), 0.9)
	# a small figure at its window — face lost in the rain
	_person(_p(0.80, 0.74), s.y * 0.28, Color(0.025, 0.02, 0.025))
	for i in 2:
		_rect(0.84, 0.56 + i * 0.025, 0.87, 0.58 + i * 0.025, Color(0.7, 0.7, 0.68))
	_drops(Rect2(0.05, 0.05, 0.9, 0.62), Color(0.8, 0.8, 1.0, 0.2))
	_rain_layer(Color(0.7, 0.7, 0.9, 0.25), 80, 0.7)
	# dashboard, wheel, a hand near the horn
	_poly([Vector2(0, 0.74), Vector2(1, 0.72), Vector2(1, 1), Vector2(0, 1)], Color(0.035, 0.03, 0.03))
	draw_arc(_p(0.48, 1.08), s.x * 0.28, PI * 1.1, PI * 1.9, 24, Color(0.012, 0.01, 0.01), maxf(3.0, s.x * 0.04))
	draw_circle(_p(0.48, 1.0), s.x * 0.07, Color(0.02, 0.018, 0.016))
	_poly([Vector2(0.55, 0.92), Vector2(0.62, 0.86), Vector2(0.70, 0.88), Vector2(0.64, 0.96)], Color(0.12, 0.08, 0.06))
	_rect(0.08, 0.78, 0.20, 0.80, Color(0.6, 0.45, 0.2, 0.5))


func _draw_home_door() -> void:
	var s := _s()
	_gradient(Color(0.06, 0.045, 0.035), Color(0.025, 0.02, 0.018))
	# the stairwell light behind the open door
	_rect(0.32, 0.12, 0.68, 0.92, Color(0.55, 0.50, 0.35))
	_glow(_p(0.5, 0.25), s.x * 0.3, Color(0.9, 0.8, 0.5), 0.8)
	_poly([Vector2(0.68, 0.12), Vector2(0.80, 0.06), Vector2(0.80, 0.98), Vector2(0.68, 0.92)], Color(0.10, 0.07, 0.05))
	# the boy in the doorway, wet
	var kid := Color(0.02, 0.016, 0.014)
	_person(_p(0.50, 0.92), s.y * 0.48, kid)
	for i in 8:
		var r: Vector3 = _rain[i]
		var y := fmod(r.y + t * 0.3, 1.0) * 0.06 + 0.90
		draw_circle(_p(0.44 + r.x * 0.12, y), 1.0, Color(0.6, 0.6, 0.7, 0.6))
	if _f("brought_bag"):
		_rect(0.56, 0.70, 0.62, 0.78, Color(0.85, 0.85, 0.82))
	elif _f("gift") or _f("returned_goods") or _f("waited_long"):
		_rect(0.40, 0.66, 0.44, 0.68, Color(0.80, 0.56, 0.76))
	# floor and the father's room around
	_poly([Vector2(0, 0.92), Vector2(1, 0.92), Vector2(1, 1), Vector2(0, 1)], Color(0.05, 0.035, 0.03))
	_poly([Vector2(0, 0), Vector2(0.32, 0), Vector2(0.32, 1), Vector2(0, 1)], Color(0.035, 0.028, 0.024))


func _draw_home_inside() -> void:
	var s := _s()
	_gradient(Color(0.07, 0.05, 0.035), Color(0.03, 0.022, 0.018))
	# bare bulb
	draw_line(_p(0.45, 0.0), _p(0.45, 0.16), Color(0.02, 0.02, 0.02), 1.0)
	_glow(_p(0.45, 0.18), s.x * 0.45, Color(1.0, 0.8, 0.5), 1.2)
	draw_circle(_p(0.45, 0.18), s.x * 0.02, Color(1.0, 0.95, 0.8))
	# the boy's door, closed, a line of light under it
	_rect(0.72, 0.28, 0.92, 0.80, Color(0.10, 0.07, 0.05))
	_rect(0.72, 0.795, 0.92, 0.805, Color(1.0, 0.85, 0.55))
	# table and what is on it
	_rect(0.10, 0.64, 0.62, 0.67, Color(0.18, 0.12, 0.08))
	_rect(0.14, 0.67, 0.16, 0.86, Color(0.12, 0.08, 0.05))
	_rect(0.56, 0.67, 0.58, 0.86, Color(0.12, 0.08, 0.05))
	if _f("brought_bag"):
		_rect(0.28, 0.56, 0.38, 0.64, Color(0.82, 0.82, 0.80))
		_rect(0.40, 0.60, 0.48, 0.64, Color(0.80, 0.62, 0.35))
	elif _f("gift") or _f("returned_goods") or _f("waited_long"):
		_rect(0.32, 0.625, 0.40, 0.64, Color(0.80, 0.56, 0.76))
	else:
		for i in 3:
			draw_circle(_p(0.34 + i * 0.03, 0.635), maxf(1.0, s.x * 0.008), Color(0.7, 0.65, 0.5))
	# the father, sitting, head down
	var dad := Color(0.025, 0.02, 0.018)
	draw_circle(_p(0.22, 0.42), s.x * 0.05, dad)
	_poly([Vector2(0.12, 0.66), Vector2(0.14, 0.47), Vector2(0.30, 0.47), Vector2(0.32, 0.66)], dad)
	_rect(0.0, 0.86, 1.0, 1.0, Color(0.04, 0.03, 0.025))


func _draw_night_door() -> void:
	var s := _s()
	_gradient(Color(0.012, 0.012, 0.02), Color(0.0, 0.0, 0.0))
	# a hallway, a door, and the light under it — like the corridor
	_rect(0.30, 0.12, 0.70, 0.86, Color(0.035, 0.03, 0.03))
	_rect(0.32, 0.14, 0.68, 0.86, Color(0.05, 0.04, 0.035))
	var f := 0.8 + 0.2 * sin(t * 2.0)
	_rect(0.32, 0.855, 0.68, 0.865, Color(1.0, 0.82, 0.5) * Color(f, f, f))
	draw_polygon(PackedVector2Array([_p(0.32, 0.865), _p(0.68, 0.865), _p(0.85, 1.0), _p(0.15, 1.0)]),
		PackedColorArray([Color(1, 0.8, 0.5, 0.35 * f), Color(1, 0.8, 0.5, 0.35 * f), Color(1, 0.8, 0.5, 0.0), Color(1, 0.8, 0.5, 0.0)]))
	draw_circle(_p(0.63, 0.52), maxf(1.0, s.x * 0.01), Color(0.3, 0.25, 0.15))
	_rect(0.625, 0.56, 0.635, 0.575, Color(1.0, 0.8, 0.5, 0.7 * f))


func _draw_child_room() -> void:
	var s := _s()
	_gradient(Color(0.05, 0.04, 0.035), Color(0.015, 0.012, 0.01))
	# small lamp
	_glow(_p(0.80, 0.42), s.x * 0.3, Color(1.0, 0.75, 0.4), 1.0)
	_rect(0.78, 0.40, 0.82, 0.46, Color(1.0, 0.85, 0.6))
	# radiator with tissue packets drying on it
	_rect(0.06, 0.48, 0.40, 0.62, Color(0.18, 0.16, 0.14))
	for i in 6:
		_rect(0.07 + i * 0.055, 0.44, 0.11 + i * 0.055, 0.48, Color(0.85, 0.85, 0.80))
	# bed and the boy
	_rect(0.30, 0.66, 0.95, 0.80, Color(0.20, 0.16, 0.20))
	_rect(0.30, 0.80, 0.95, 0.84, Color(0.10, 0.08, 0.08))
	var kid := Color(0.06, 0.05, 0.06)
	draw_circle(_p(0.40, 0.63), s.x * 0.05, kid)
	_poly([Vector2(0.44, 0.60), Vector2(0.92, 0.58), Vector2(0.92, 0.67), Vector2(0.44, 0.68)], Color(0.30, 0.24, 0.30))
	if _f("chocolate"):
		draw_circle(_p(0.56, 0.62), s.x * 0.04, kid)
		_rect(0.48, 0.56, 0.53, 0.58, Color(0.55, 0.25, 0.15))
	if _f("gift") and not _f("father_harsh"):
		_rect(0.36, 0.69, 0.40, 0.70, Color(0.80, 0.56, 0.76))
	# seen through a crack: dark edges
	_rect(0.0, 0.0, 0.12, 1.0, Color(0, 0, 0, 0.85))
	_rect(0.88, 0.0, 1.0, 1.0, Color(0, 0, 0, 0.6))


# --- SON MEKTUP ----------------------------------------------------------

func _desk_lamp(f: float) -> void:
	var s := _s()
	_gradient(Color(0.05, 0.035, 0.025), Color(0.02, 0.012, 0.01))
	_glow(_p(0.72, 0.30), s.x * 0.45, Color(1.0, 0.72, 0.38), 1.3 * f)
	_poly([Vector2(0.64, 0.30), Vector2(0.80, 0.30), Vector2(0.76, 0.22), Vector2(0.68, 0.22)], Color(0.09, 0.06, 0.04))
	draw_line(_p(0.72, 0.22), _p(0.86, 0.02), Color(0.06, 0.04, 0.03), 2)
	_gradient(Color(0.20 * f, 0.12 * f, 0.07 * f), Color(0.06, 0.035, 0.02), 0.58, 1.0)


func _paper(c: Vector2, lines: int, last: float, f: float) -> void:
	var s := _s()
	var u := Vector2(cos(-0.06), sin(-0.06)) * s.x * 0.24
	var v := Vector2(-sin(-0.06), cos(-0.06)) * s.y * 0.17
	var pc := _p(c.x, c.y)
	draw_colored_polygon(PackedVector2Array([pc - u - v, pc + u - v, pc + u + v, pc - u + v]), Color(0.88 * f, 0.82 * f, 0.66 * f))
	for i in lines:
		var k := -0.75 + i * 0.2
		var length := 0.85 if i < lines - 1 else last
		var a := pc - u * 0.85 + v * k
		draw_line(a, a + u * 1.7 * length, Color(0.18, 0.12, 0.10, 0.75), 1.0)


func _hand_with_pen(at: Vector2) -> void:
	var s := _s()
	var hand := Color(0.10, 0.07, 0.05)
	draw_circle(_p(at.x, at.y), s.x * 0.05, hand)
	draw_line(_p(at.x - 0.02, at.y + 0.01), _p(at.x + 0.25, at.y + 0.25), hand, s.x * 0.06)
	draw_line(_p(at.x - 0.03, at.y - 0.02), _p(at.x - 0.08, at.y + 0.02), Color(0.02, 0.02, 0.02), 2)


func _draw_letter_blank() -> void:
	var f := _flicker(6.0, 0.1)
	_desk_lamp(f)
	_paper(Vector2(0.45, 0.72), 0, 0.0, f)
	_hand_with_pen(Vector2(0.62, 0.70))
	# a cup that went cold
	_rect(0.10, 0.56, 0.18, 0.66, Color(0.30, 0.28, 0.26) * f)
	_rect(0.11, 0.565, 0.17, 0.58, Color(0.12, 0.07, 0.04))


func _draw_phone_table() -> void:
	var s := _s()
	var f := _flicker(6.0, 0.08)
	_desk_lamp(f)
	_paper(Vector2(0.30, 0.74), 6, 0.4, f)
	# old phone, screen lit, a name
	var ring := 0.5 + 0.5 * sin(t * 9.0)
	_rect(0.56, 0.62, 0.76, 0.86, Color(0.04, 0.04, 0.05))
	_rect(0.575, 0.635, 0.745, 0.80, Color(0.55 + 0.3 * ring, 0.75, 0.95))
	_glow(_p(0.66, 0.72), s.x * 0.22, Color(0.6, 0.8, 1.0), 0.6 + 0.6 * ring)
	draw_string(ThemeDB.fallback_font, _p(0.585, 0.70), "Oğlum", HORIZONTAL_ALIGNMENT_LEFT, -1, int(s.x * 0.06), Color(0.05, 0.08, 0.12))


func _draw_postbox() -> void:
	var s := _s()
	_gradient(Color(0.05, 0.05, 0.08), Color(0.09, 0.08, 0.10), 0.0, 0.7)
	_lit_windows(0.1, 0.5, 31, Color(1.0, 0.8, 0.5, 0.3))
	_gradient(Color(0.08, 0.07, 0.08), Color(0.03, 0.03, 0.035), 0.7, 1.0)
	_glow(_p(0.25, 0.25), s.x * 0.3, Color(1.0, 0.85, 0.55), 0.8)
	_rect(0.245, 0.25, 0.255, 0.75, Color(0.02, 0.02, 0.02))
	# the yellow box
	var y := Color(0.85, 0.68, 0.12)
	_rect(0.46, 0.38, 0.70, 0.80, y)
	_poly([Vector2(0.46, 0.38), Vector2(0.58, 0.32), Vector2(0.70, 0.38)], y.darkened(0.2))
	_rect(0.50, 0.46, 0.66, 0.49, Color(0.08, 0.06, 0.02))
	draw_string(ThemeDB.fallback_font, _p(0.52, 0.60), "PTT", HORIZONTAL_ALIGNMENT_LEFT, -1, int(s.x * 0.07), Color(0.15, 0.10, 0.02))
	# the envelope, half in
	var drop := clampf(fmod(t * 0.3, 1.0) * 1.5, 0.0, 1.0)
	_rect(0.53, 0.40 + drop * 0.06, 0.63, 0.47, Color(0.92, 0.90, 0.84))
	_rect(0.585, 0.58, 0.62, 0.80, Color(0.02, 0.02, 0.02))
	_rain_layer(Color(0.7, 0.7, 0.9, 0.18), 50, 0.45)


func _draw_drawer() -> void:
	var s := _s()
	_gradient(Color(0.06, 0.045, 0.03), Color(0.02, 0.015, 0.01))
	_glow(_p(0.5, 0.0), s.x * 0.6, Color(1.0, 0.8, 0.5), 0.6)
	# the desk front and an open drawer seen from above
	_rect(0.05, 0.20, 0.95, 0.42, Color(0.16, 0.10, 0.06))
	_poly([Vector2(0.12, 0.42), Vector2(0.88, 0.42), Vector2(0.96, 0.92), Vector2(0.04, 0.92)], Color(0.10, 0.065, 0.04))
	_poly([Vector2(0.18, 0.46), Vector2(0.82, 0.46), Vector2(0.88, 0.86), Vector2(0.12, 0.86)], Color(0.05, 0.035, 0.025))
	# envelope with a stamp; an old photo under it
	_poly([Vector2(0.26, 0.60), Vector2(0.62, 0.56), Vector2(0.66, 0.76), Vector2(0.30, 0.80)], Color(0.80, 0.75, 0.62))
	_rect(0.55, 0.59, 0.60, 0.645, Color(0.75, 0.25, 0.20))
	draw_line(_p(0.34, 0.68), _p(0.52, 0.66), Color(0.2, 0.15, 0.1, 0.7), 1.0)
	_poly([Vector2(0.58, 0.66), Vector2(0.80, 0.64), Vector2(0.82, 0.80), Vector2(0.60, 0.82)], Color(0.35, 0.30, 0.25))
	_rect(0.6, 0.44, 0.7, 0.46, Color(0.5, 0.4, 0.25))


func _draw_envelope_door() -> void:
	var s := _s()
	_gradient(Color(0.04, 0.04, 0.05), Color(0.015, 0.015, 0.02))
	# a front door from inside, the floor, light from the stairwell under it
	_rect(0.22, 0.04, 0.78, 0.80, Color(0.09, 0.07, 0.06))
	_rect(0.26, 0.08, 0.74, 0.40, Color(0.075, 0.058, 0.05))
	_rect(0.26, 0.44, 0.74, 0.78, Color(0.075, 0.058, 0.05))
	_rect(0.66, 0.42, 0.70, 0.45, Color(0.5, 0.45, 0.3))
	_rect(0.22, 0.795, 0.78, 0.805, Color(1.0, 0.85, 0.55, 0.8))
	_gradient(Color(0.06, 0.05, 0.045), Color(0.03, 0.025, 0.02), 0.80, 1.0)
	# the envelope on the floor
	_poly([Vector2(0.36, 0.84), Vector2(0.62, 0.82), Vector2(0.66, 0.92), Vector2(0.38, 0.95)], Color(0.86, 0.82, 0.70))
	draw_line(_p(0.36, 0.84), _p(0.51, 0.90), Color(0.5, 0.45, 0.35), 1.0)
	draw_line(_p(0.62, 0.82), _p(0.51, 0.90), Color(0.5, 0.45, 0.35), 1.0)
	_glow(_p(0.5, 0.82), s.x * 0.25, Color(1.0, 0.85, 0.55), 0.4)


func _draw_old_room() -> void:
	var s := _s()
	_gradient(Color(0.10, 0.09, 0.08), Color(0.05, 0.045, 0.04))
	# daylight through a window, dust in it
	_rect(0.62, 0.12, 0.90, 0.50, Color(0.75, 0.78, 0.80))
	draw_polygon(PackedVector2Array([_p(0.62, 0.12), _p(0.90, 0.12), _p(0.60, 1.0), _p(0.20, 1.0)]),
		PackedColorArray([Color(0.9, 0.9, 0.85, 0.18), Color(0.9, 0.9, 0.85, 0.18), Color(0.9, 0.9, 0.85, 0.0), Color(0.9, 0.9, 0.85, 0.0)]))
	for i in 18:
		var r: Vector3 = _rain[i]
		var y := fmod(r.y + t * 0.02 * r.z, 1.0)
		draw_circle(_p(0.35 + r.x * 0.4, 0.2 + y * 0.7), 1.0, Color(1, 1, 0.9, 0.4))
	# the desk, the chair, boxes
	_rect(0.10, 0.60, 0.50, 0.63, Color(0.20, 0.13, 0.08))
	_rect(0.12, 0.63, 0.14, 0.85, Color(0.15, 0.10, 0.06))
	_rect(0.46, 0.63, 0.48, 0.85, Color(0.15, 0.10, 0.06))
	_rect(0.20, 0.54, 0.32, 0.60, Color(0.85, 0.82, 0.72))
	_rect(0.55, 0.70, 0.75, 0.88, Color(0.45, 0.35, 0.22))
	_rect(0.58, 0.62, 0.74, 0.70, Color(0.50, 0.40, 0.26))
	_rect(0.0, 0.88, 1.0, 1.0, Color(0.09, 0.07, 0.06))


# --- YANLIŞ KAPI ----------------------------------------------------------

func _draw_apartment_entry() -> void:
	var s := _s()
	_gradient(Color(0.05, 0.05, 0.07), Color(0.08, 0.08, 0.09), 0.0, 1.0)
	# building front and the glass door
	_rect(0.10, 0.0, 0.90, 0.86, Color(0.12, 0.11, 0.11))
	_rect(0.30, 0.18, 0.62, 0.86, Color(0.25, 0.30, 0.28))
	_rect(0.32, 0.20, 0.60, 0.84, Color(0.55, 0.62, 0.50, 0.6))
	_glow(_p(0.46, 0.35), s.x * 0.25, Color(0.8, 0.95, 0.75), 0.6)
	# buzzer panel
	_rect(0.66, 0.40, 0.76, 0.62, Color(0.35, 0.33, 0.30))
	for i in 5:
		_rect(0.68, 0.42 + i * 0.038, 0.74, 0.45 + i * 0.038, Color(0.75, 0.70, 0.55) if i == 1 else Color(0.55, 0.52, 0.45))
	_rect(0.0, 0.86, 1.0, 1.0, Color(0.05, 0.05, 0.055))
	# the courier with a box, and the man with flowers
	var c := Color(0.03, 0.03, 0.035)
	_person(_p(0.22, 0.98), s.y * 0.58, c)
	_rect(0.20, 0.62, 0.32, 0.72, Color(0.55, 0.40, 0.25))
	var m := Color(0.045, 0.04, 0.05)
	_person_rim(_p(0.80, 0.98), s.y * 0.62, m, Color(0.75, 0.85, 0.75, 0.35))
	for i in 5:
		draw_circle(_p(0.70 + (i % 3) * 0.025, 0.56 + (i / 3) * 0.025), maxf(1.5, s.x * 0.014), Color(0.85, 0.25 + i * 0.1, 0.35))
	_rain_layer(Color(0.7, 0.7, 0.9, 0.12), 30, 0.5)


func _draw_stairwell() -> void:
	var s := _s()
	var on := 1.0 if fmod(t * 0.2, 1.0) < 0.9 else 0.6
	_gradient(Color(0.20 * on, 0.21 * on, 0.18 * on), Color(0.07, 0.07, 0.065))
	_glow(_p(0.5, 0.05), s.x * 0.5, Color(0.9, 1.0, 0.85), 0.7 * on)
	# zig-zag stairs and railing
	for i in 7:
		var y := 0.95 - i * 0.1
		var x := 0.1 + i * 0.09
		_rect(x, y, x + 0.5, y + 0.03, Color(0.30, 0.30, 0.28))
		_rect(x, y + 0.03, x + 0.5, y + 0.10, Color(0.16, 0.16, 0.15))
	draw_line(_p(0.08, 0.80), _p(0.70, 0.18), Color(0.05, 0.05, 0.05), 3)
	for i in 8:
		var x := 0.10 + i * 0.08
		draw_line(_p(x, 0.80 - i * 0.08), _p(x, 0.90 - i * 0.08), Color(0.05, 0.05, 0.05), 1)
	# a figure waiting one floor down, phone light on the face
	_person(_p(0.30, 0.90), s.y * 0.34, Color(0.03, 0.03, 0.035))
	_rect(0.32, 0.66, 0.34, 0.68, Color(0.7, 0.85, 1.0))
	if not _f("y_refused"):
		for i in 3:
			draw_circle(_p(0.24 + i * 0.02, 0.72), maxf(1.0, s.x * 0.012), Color(0.85, 0.35, 0.4))


func _draw_door_ajar() -> void:
	var s := _s()
	_gradient(Color(0.14, 0.14, 0.12), Color(0.06, 0.06, 0.055))
	_rect(0.25, 0.08, 0.75, 0.96, Color(0.18, 0.12, 0.08))
	# the gap: warm room light, a chain, half a face
	_rect(0.50, 0.10, 0.60, 0.96, Color(0.95, 0.80, 0.55))
	_glow(_p(0.55, 0.45), s.x * 0.3, Color(1.0, 0.8, 0.5), 0.8)
	draw_line(_p(0.50, 0.40), _p(0.60, 0.43), Color(0.6, 0.6, 0.6), 2)
	draw_circle(_p(0.57, 0.33), s.x * 0.05, Color(0.20, 0.12, 0.08))
	_rect(0.535, 0.40, 0.60, 0.70, Color(0.25, 0.15, 0.12))
	_rect(0.25, 0.08, 0.50, 0.96, Color(0.20, 0.13, 0.09))
	_rect(0.44, 0.50, 0.47, 0.53, Color(0.6, 0.5, 0.3))
	_rect(0.0, 0.96, 1.0, 1.0, Color(0.05, 0.05, 0.05))


func _draw_door_inside() -> void:
	var s := _s()
	_gradient(Color(0.10, 0.08, 0.07), Color(0.04, 0.035, 0.03))
	# inside her flat: the door, double lock, the stairwell light under it
	_rect(0.28, 0.06, 0.72, 0.90, Color(0.20, 0.15, 0.11))
	_rect(0.64, 0.46, 0.68, 0.50, Color(0.7, 0.6, 0.4))
	_rect(0.64, 0.38, 0.68, 0.41, Color(0.7, 0.6, 0.4))
	draw_circle(_p(0.50, 0.30), maxf(1.5, s.x * 0.012), Color(0.9, 0.9, 0.8))
	_rect(0.28, 0.895, 0.72, 0.905, Color(0.95, 1.0, 0.85, 0.8))
	var sh := fmod(t * 0.3, 1.0)
	if _f("y_let_in") and sh < 0.6:
		_rect(0.36 + sh * 0.2, 0.895, 0.44 + sh * 0.2, 0.905, Color(0.05, 0.05, 0.05))
	# boxes not yet unpacked
	_rect(0.04, 0.70, 0.22, 0.92, Color(0.45, 0.34, 0.22))
	_rect(0.78, 0.76, 0.98, 0.94, Color(0.42, 0.32, 0.20))
	_rect(0.0, 0.92, 1.0, 1.0, Color(0.06, 0.05, 0.045))


func _draw_peephole() -> void:
	var s := _s()
	_rect(0.0, 0.0, 1.0, 1.0, Color(0.0, 0.0, 0.0))
	var c := _p(0.5, 0.5)
	var r := s.x * 0.44
	draw_circle(c, r, Color(0.20, 0.21, 0.18))
	# bent corridor through the lens
	var n := 18
	for i in n:
		var a0 := TAU * i / n
		var a1 := TAU * (i + 1) / n
		var shade := 0.10 + 0.06 * sin(a0 * 2.0)
		draw_colored_polygon(PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * r, c + Vector2(cos(a1), sin(a1)) * r]),
			Color(shade + 0.05, shade + 0.06, shade + 0.04))
	draw_circle(c + Vector2(0, -r * 0.1), r * 0.45, Color(0.30, 0.32, 0.27))
	_glow(c + Vector2(0, -r * 0.7), r * 0.6, Color(0.9, 1.0, 0.85), 0.6)
	# who stands there
	if _f("y_let_in") and not _f("n_spoke"):
		_person_rim(c + Vector2(r * 0.05, r * 0.95), r * 1.25, Color(0.03, 0.03, 0.035), Color(0.8, 0.9, 0.8, 0.3))
		for i in 4:
			draw_circle(c + Vector2(-r * 0.30 + i * r * 0.07, r * 0.15), maxf(1.5, r * 0.05), Color(0.85, 0.3, 0.4))
	elif _f("y_refused") or _f("y_handed"):
		_person(c + Vector2(-r * 0.2, r * 0.95), r * 1.1, Color(0.04, 0.04, 0.045))
		_rect(0.40, 0.55, 0.52, 0.64, Color(0.55, 0.40, 0.25))
	# the brass ring of the lens
	draw_arc(c, r, 0, TAU, 48, Color(0.35, 0.28, 0.12), maxf(3.0, s.x * 0.03))


func _draw_window_street() -> void:
	var s := _s()
	_gradient(Color(0.03, 0.03, 0.06), Color(0.06, 0.05, 0.07))
	# the street below, a lamp, a man with flowers looking up
	_rect(0.0, 0.62, 1.0, 1.0, Color(0.06, 0.06, 0.07))
	_rect(0.58, 0.20, 0.59, 0.72, Color(0.02, 0.02, 0.02))
	_glow(_p(0.585, 0.22), s.x * 0.28, Color(1.0, 0.85, 0.55), 1.1)
	draw_polygon(PackedVector2Array([_p(0.585, 0.22), _p(0.585, 0.22), _p(0.78, 0.84), _p(0.40, 0.84)]),
		PackedColorArray([Color(1, 0.85, 0.55, 0.3), Color(1, 0.85, 0.55, 0.3), Color(1, 0.85, 0.55, 0.0), Color(1, 0.85, 0.55, 0.0)]))
	_person_rim(_p(0.60, 0.84), s.y * 0.22, Color(0.03, 0.03, 0.035), Color(1, 0.85, 0.55, 0.4))
	for i in 3:
		draw_circle(_p(0.56 + i * 0.015, 0.72), maxf(1.0, s.x * 0.01), Color(0.85, 0.3, 0.4))
	_rain_layer(Color(0.7, 0.7, 0.9, 0.15), 40, 0.4)
	# window frame and curtain edge
	_rect(0.0, 0.0, 1.0, 0.04, Color(0.12, 0.10, 0.09))
	_rect(0.0, 0.96, 1.0, 1.0, Color(0.12, 0.10, 0.09))
	_rect(0.0, 0.0, 0.05, 1.0, Color(0.12, 0.10, 0.09))
	_rect(0.95, 0.0, 1.0, 1.0, Color(0.12, 0.10, 0.09))
	_rect(0.48, 0.0, 0.52, 1.0, Color(0.12, 0.10, 0.09))
	_poly([Vector2(0.05, 0.04), Vector2(0.22, 0.04), Vector2(0.16, 0.96), Vector2(0.05, 0.96)], Color(0.35, 0.18, 0.20, 0.9))
	_drops(Rect2(0.05, 0.04, 0.9, 0.92), Color(0.8, 0.8, 1.0, 0.18))


func _draw_suitcase() -> void:
	var s := _s()
	_gradient(Color(0.06, 0.06, 0.09), Color(0.02, 0.02, 0.03))
	_glow(_p(0.85, 0.20), s.x * 0.3, Color(0.6, 0.7, 1.0), 0.5)
	# bed and, on it or above the wardrobe, a suitcase
	_rect(0.05, 0.62, 0.95, 0.80, Color(0.22, 0.20, 0.26))
	_rect(0.05, 0.80, 0.95, 0.86, Color(0.10, 0.09, 0.12))
	if _f("y_let_in"):
		_poly([Vector2(0.25, 0.62), Vector2(0.70, 0.62), Vector2(0.74, 0.48), Vector2(0.21, 0.48)], Color(0.30, 0.18, 0.12))
		_rect(0.27, 0.50, 0.68, 0.60, Color(0.12, 0.08, 0.06))
		for i in 4:
			_rect(0.30 + i * 0.09, 0.52, 0.37 + i * 0.09, 0.58, Color.from_hsv(0.1 * i, 0.3, 0.6))
	else:
		_rect(0.62, 0.06, 0.95, 0.56, Color(0.14, 0.11, 0.09))
		_rect(0.66, 0.0, 0.90, 0.06, Color(0.30, 0.18, 0.12))
	_rect(0.0, 0.86, 1.0, 1.0, Color(0.05, 0.05, 0.06))
