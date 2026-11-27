extends Node2D
## The corridor. A very small perspective renderer — a 3D box drawn with
## 2D polygons — so the camera can really walk up to a door, lean in to the
## gap and step through, without any 3D assets.
##
## Flow:  INTRO → IDLE → (tap door) → AT_DOOR → (Arala) → PEEKING
##        PEEKING → (Vazgeç) → IDLE        PEEKING → (hold İçeri gir) → life

const World := preload("res://scripts/world.gd")
const UIStyle := preload("res://scripts/ui_style.gd")
const DoorScene := preload("res://scenes/door.tscn")

const IDLE_POS := Vector3(0.0, World.EYE, 0.0)
const ENTER_HOLD := 1.1

enum State { INTRO, IDLE, MOVING, AT_DOOR, PEEKING, ENTERING }

var state: State = State.INTRO
var cam_pos: Vector3 = IDLE_POS
var cam_yaw: float = 0.0
## Lens shift (fraction of screen height): lifts the image so a door's
## threshold light stays above the buttons.
var cam_shift: float = 0.0
## >1 shows more of the other life through the gap; eases to 1 on entering.
var peek_zoom_out: float = 1.35
var focus_door = null
var doors: Array = []
var time: float = 0.0

var _focal: float = 430.0
var _size := Vector2(720, 1280)
var _center := Vector2(360, 640)
var _eff_pos := IDLE_POS
var _cos := 1.0
var _sin := 0.0
var _grids: Array[Dictionary] = []
var _tween: Tween
var _ui_tween: Tween
var _press_pos := Vector2.ZERO
var _hinted := false

@onready var door_layer: Node2D = $Doors
@onready var peek_viewport: SubViewport = $PeekViewport
@onready var peek_scene = $PeekViewport/PeekScene
@onready var ui: Control = $HUD/UI
@onready var title_box: Control = $HUD/UI/Title
@onready var hint: Label = $HUD/UI/Hint
@onready var caption: Label = $HUD/UI/Caption
@onready var note: Label = $HUD/UI/Note
@onready var buttons: Control = $HUD/UI/Buttons
@onready var primary = $HUD/UI/Buttons/Primary
@onready var secondary: Button = $HUD/UI/Buttons/Secondary
@onready var fade: ColorRect = $HUD/UI/Fade


func _ready() -> void:
	ui.theme = UIStyle.make_theme()
	get_tree().root.size_changed.connect(_on_resize)
	_on_resize()
	_build_grids()
	for d in DoorManager.get_doors():
		var door = DoorScene.instantiate()
		door_layer.add_child(door)
		door.setup(d, self)
		doors.append(door)
	primary.held.connect(_on_primary)
	secondary.pressed.connect(_on_secondary)
	peek_scene.active = false
	peek_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_set_buttons("", "")
	caption.modulate.a = 0.0
	note.modulate.a = 0.0
	hint.modulate.a = 0.0
	if GameManager.intro_seen:
		_start_return()
	else:
		_start_intro()


func _on_resize() -> void:
	_size = get_viewport_rect().size
	_center = Vector2(_size.x * 0.5, _size.y * 0.5)
	_focal = _size.x * 0.6
	if peek_viewport:
		peek_viewport.size = Vector2i(_size)


# --- intro / return ------------------------------------------------------

func _start_intro() -> void:
	state = State.INTRO
	fade.color = Color(0, 0, 0, 1)
	title_box.modulate.a = 0.0
	cam_pos = IDLE_POS + Vector3(0, 0, -1.6)
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(fade, "color:a", 0.0, 2.0)
	_tween.tween_property(title_box, "modulate:a", 1.0, 2.0).set_delay(0.6)
	var order := [4, 0, 2, 1, 3]
	for i in order.size():
		if order[i] < doors.size():
			_tween.tween_property(doors[order[i]], "light_level", 1.0, 1.6).set_delay(1.0 + i * 0.55)
	_tween.tween_method(_cam_lerp.bind(cam_pos, 0.0, 0.0, IDLE_POS, 0.0, 0.0), 0.0, 1.0, 5.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.chain().tween_callback(_finish_intro)


func _finish_intro() -> void:
	if state != State.INTRO:
		return
	if _tween:
		_tween.kill()
	GameManager.intro_seen = true
	cam_pos = IDLE_POS
	cam_yaw = 0.0
	cam_shift = 0.0
	fade.color.a = 0.0
	for d in doors:
		d.light_level = 1.0
	state = State.IDLE
	var tw := create_tween()
	tw.tween_property(title_box, "modulate:a", 0.0, 1.2)
	if not _hinted:
		hint.text = "Bir kapıya dokun."
		tw.tween_property(hint, "modulate:a", 1.0, 1.0)


func _start_return() -> void:
	# Coming back from a life: the light is still in your eyes.
	state = State.IDLE
	title_box.modulate.a = 0.0
	_hinted = true
	for d in doors:
		d.light_level = 1.0
	fade.color = Color(1, 0.97, 0.92, 1)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 1.6)


# --- input ---------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_go_back()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_pos = event.position
		elif event.position.distance_to(_press_pos) < 30.0:
			_on_tap(event.position)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_go_back()


func _on_tap(pos: Vector2) -> void:
	match state:
		State.INTRO:
			_finish_intro()
		State.IDLE:
			var d = _pick_door(pos)
			if d:
				_approach(d)
		State.AT_DOOR:
			if focus_door and Geometry2D.is_point_in_polygon(pos, focus_door.screen_outline()):
				_peek()


func _go_back() -> void:
	match state:
		State.AT_DOOR:
			_leave_door()
		State.PEEKING:
			_turn_away()


func _pick_door(pos: Vector2):
	var best = null
	var best_d := INF
	for d in doors:
		var poly: PackedVector2Array = d.screen_outline()
		if poly.size() < 3:
			continue
		if Geometry2D.is_point_in_polygon(pos, poly):
			return d
		# far doors are thin slivers: give every door a finger-sized target
		var r := Rect2(poly[0], Vector2.ZERO)
		for p in poly:
			r = r.expand(p)
		var c := r.get_center()
		r = r.grow_individual(maxf(0.0, (96.0 - r.size.x) * 0.5), maxf(0.0, (150.0 - r.size.y) * 0.5),
			maxf(0.0, (96.0 - r.size.x) * 0.5), maxf(0.0, (150.0 - r.size.y) * 0.5))
		if r.has_point(pos):
			var dist := pos.distance_to(c)
			if dist < best_d:
				best_d = dist
				best = d
	return best


# --- the three interactions ----------------------------------------------

## 1. Approach: you hear it, you see the light under it.
func _approach(d) -> void:
	focus_door = d
	state = State.MOVING
	_hinted = true
	_fade_ui(hint, 0.0, 0.4)
	_fade_ui(caption, 0.0, 0.3)
	_fade_ui(note, 0.0, 0.3)
	var v: Array = d.view_approach()
	_move_camera(v, 1.7, func() -> void:
		state = State.AT_DOOR
		_show_caption(d.data["sound"], "")
		_set_buttons("Arala", "Geri dön"))


func _leave_door() -> void:
	state = State.MOVING
	_set_buttons("", "")
	_fade_ui(caption, 0.0, 0.3)
	_move_camera([IDLE_POS, 0.0, 0.0], 1.5, func() -> void:
		state = State.IDLE
		focus_door = null)


## 2. Aralamak: only this moment. Never what comes after.
func _peek() -> void:
	var d = focus_door
	state = State.MOVING
	_set_buttons("", "")
	_fade_ui(caption, 0.0, 0.3)
	GameManager.mark_peeked(d.id)
	peek_scene.set_style(d.data["peek_style"])
	peek_scene.active = true
	peek_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	d.peek_texture = peek_viewport.get_texture()
	var tw := create_tween()
	tw.tween_property(d, "open_angle", d.PEEK_ANGLE, 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(0.15)
	var v: Array = d.view_peek()
	peek_zoom_out = 1.35
	_move_camera(v, 1.5, func() -> void:
		state = State.PEEKING
		if d.data["enterable"]:
			_show_caption(d.data["moment"], "İçeri girmek bir seçimdir. Basılı tut.")
			_set_buttons("İçeri gir", "Vazgeç", ENTER_HOLD)
		else:
			_show_caption(d.data["moment"], "Kapı bundan fazla açılmıyor.")
			_set_buttons("", "Vazgeç"))


## Turning away: the life stays where it is, a possibility.
func _turn_away() -> void:
	var d = focus_door
	state = State.MOVING
	_set_buttons("", "")
	_fade_ui(note, 0.0, 0.3)
	_fade_ui(caption, 0.0, 0.3)
	GameManager.mark_turned_away(d.id)
	var tw := create_tween()
	tw.tween_property(d, "open_angle", 0.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		peek_scene.active = false
		peek_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		d.dim = maxf(0.55, d.dim * 0.88))
	_move_camera([IDLE_POS, 0.0, 0.0], 2.0, func() -> void:
		state = State.IDLE
		focus_door = null
		_show_caption("Bu ihtimal olduğu yerde kalıyor.", "")
		var later := create_tween()
		later.tween_interval(2.6)
		later.tween_callback(func() -> void:
			if state == State.IDLE:
				_fade_ui(caption, 0.0, 1.2)))


## 3. Enter: you are no longer watching. This is the commitment.
func _enter() -> void:
	var d = focus_door
	state = State.ENTERING
	_set_buttons("", "")
	_fade_ui(caption, 0.0, 0.4)
	_fade_ui(note, 0.0, 0.4)
	var tw := create_tween()
	tw.tween_property(d, "open_angle", d.ENTER_ANGLE, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var v: Array = d.view_enter()
	_move_camera(v, 2.0, func() -> void: pass)
	create_tween().tween_property(self, "peek_zoom_out", 1.0, 2.0)
	fade.color = Color(1, 0.97, 0.92, 0)
	var ft := create_tween()
	ft.tween_interval(1.2)
	ft.tween_property(fade, "color:a", 1.0, 0.9)
	ft.tween_interval(0.3)
	ft.tween_callback(func() -> void: GameManager.enter_life(d.id))


func _on_primary() -> void:
	match state:
		State.AT_DOOR:
			_peek()
		State.PEEKING:
			if focus_door and focus_door.data["enterable"]:
				_enter()


func _on_secondary() -> void:
	match state:
		State.AT_DOOR:
			_leave_door()
		State.PEEKING:
			_turn_away()


# --- UI helpers ----------------------------------------------------------

func _show_caption(text: String, sub: String) -> void:
	caption.text = text
	note.text = sub
	_fade_ui(caption, 1.0, 0.8)
	_fade_ui(note, 0.75 if sub != "" else 0.0, 1.2)


func _fade_ui(c: CanvasItem, alpha: float, dur: float) -> void:
	var tw := create_tween()
	tw.tween_property(c, "modulate:a", alpha, dur)


func _set_buttons(primary_text: String, secondary_text: String, hold: float = 0.0) -> void:
	primary.visible = primary_text != ""
	primary.text = primary_text
	primary.hold_time = hold
	primary.reset()
	secondary.visible = secondary_text != ""
	secondary.text = secondary_text
	var show: bool = primary.visible or secondary.visible
	buttons.modulate.a = 0.0
	if show:
		_fade_ui(buttons, 1.0, 0.5)


# --- camera --------------------------------------------------------------

## view = [position: Vector3, yaw: float, lens_shift: float]
func _move_camera(view: Array, dur: float, done: Callable) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_cam_lerp.bind(cam_pos, cam_yaw, cam_shift, view[0], view[1], view[2]), 0.0, 1.0, dur)
	_tween.tween_callback(done)


func _cam_lerp(t: float, from_pos: Vector3, from_yaw: float, from_shift: float,
		to_pos: Vector3, to_yaw: float, to_shift: float) -> void:
	var e := smoothstep(0.0, 1.0, t)
	var ey := smoothstep(0.1, 1.0, t)
	cam_pos = from_pos.lerp(to_pos, e)
	cam_yaw = lerp_angle(from_yaw, to_yaw, ey)
	cam_shift = lerpf(from_shift, to_shift, e)


# --- rendering -----------------------------------------------------------

func _process(delta: float) -> void:
	time += delta
	# a body breathing, not a camera floating
	var breath := 0.0 if state == State.ENTERING else 1.0
	_eff_pos = cam_pos + Vector3(0, sin(time * 1.2) * 0.007 * breath, 0)
	var yaw := cam_yaw + sin(time * 0.5) * 0.004 * breath
	_cos = cos(yaw)
	_sin = sin(yaw)
	for d in doors:
		d.update_light(time)
	queue_redraw()


func to_cam(p: Vector3) -> Vector3:
	var d := p - _eff_pos
	return Vector3(d.x * _cos - d.z * _sin, d.y, d.x * _sin + d.z * _cos)


func light_at(p: Vector3) -> Color:
	var c := Color(0.030, 0.030, 0.038)
	# what the eyes adjust to right around you
	var dc := p - _eff_pos
	c += Color(0.030, 0.030, 0.036) / (1.0 + dc.length_squared() * 0.7)
	for d in doors:
		c += d.light_contrib(p)
	return c


func shade_point(p: Vector3, base: Color) -> Color:
	var l := light_at(p)
	return Color(base.r * (0.5 + l.r * 6.0), base.g * (0.5 + l.g * 6.0), base.b * (0.5 + l.b * 6.0), base.a) + l * 0.25


## Projects a world polygon: returns [PackedVector2Array, fog factors] or [].
func project_world(pts: PackedVector3Array) -> Array:
	var cam := PackedVector3Array()
	for p in pts:
		cam.append(to_cam(p))
	return _clip_project(cam, PackedColorArray(), false)


func draw_world_poly(canvas: CanvasItem, pts: PackedVector3Array, cols: PackedColorArray,
		tex: Texture2D = null, fogged: bool = true) -> void:
	var cam := PackedVector3Array()
	for p in pts:
		cam.append(to_cam(p))
	var full := PackedColorArray()
	for i in cam.size():
		var c: Color = cols[i] if i < cols.size() else cols[0]
		if fogged:
			var f := exp(-World.FOG * cam[i].length())
			c = Color(c.r * f, c.g * f, c.b * f, c.a)
		full.append(c)
	var res := _clip_project(cam, full, true)
	if res.is_empty():
		return
	var sp: PackedVector2Array = res[0]
	if absf(_area(sp)) < 0.5:
		return
	if tex:
		var uvs := PackedVector2Array()
		for p in sp:
			uvs.append(Vector2(0.5, 0.5) + (p / _size - Vector2(0.5, 0.5)) * peek_zoom_out)
		canvas.draw_polygon(sp, res[1], uvs, tex)
	else:
		canvas.draw_polygon(sp, res[1])


func _clip_project(cam: PackedVector3Array, cols: PackedColorArray, with_colors: bool) -> Array:
	var out_p := PackedVector2Array()
	var out_c := PackedColorArray()
	var n := cam.size()
	var any_in := false
	for q in cam:
		if q.z >= World.NEAR:
			any_in = true
			break
	if not any_in:
		return []
	for i in n:
		var a := cam[i]
		var b := cam[(i + 1) % n]
		var a_in := a.z >= World.NEAR
		var b_in := b.z >= World.NEAR
		if a_in:
			out_p.append(_to_screen(a))
			if with_colors:
				out_c.append(cols[i])
		if a_in != b_in:
			var t := (World.NEAR - a.z) / (b.z - a.z)
			out_p.append(_to_screen(a.lerp(b, t)))
			if with_colors:
				out_c.append(cols[i].lerp(cols[(i + 1) % n], t))
	if out_p.size() < 3:
		return []
	# skip polygons entirely off-screen
	var r := Rect2(out_p[0], Vector2.ZERO)
	for p in out_p:
		r = r.expand(p)
	if not r.intersects(Rect2(Vector2.ZERO, _size)):
		return []
	return [out_p, out_c]


func _to_screen(q: Vector3) -> Vector2:
	return Vector2(_center.x + _focal * q.x / q.z, _center.y - cam_shift * _size.y - _focal * q.y / q.z)


func _area(p: PackedVector2Array) -> float:
	var a := 0.0
	for i in p.size():
		var j := (i + 1) % p.size()
		a += p[i].x * p[j].y - p[j].x * p[i].y
	return a * 0.5


func _build_grids() -> void:
	var w := World.HALF_W
	var length := World.Z_END - World.Z_BACK
	var floor_c := Color(0.085, 0.078, 0.072)
	var wall_c := Color(0.070, 0.070, 0.080)
	var ceil_c := Color(0.040, 0.040, 0.048)
	_grids = [
		_grid(Vector3(-w, 0, World.Z_BACK), Vector3(2 * w, 0, 0), Vector3(0, 0, length), 6, 30, floor_c),
		_grid(Vector3(-w, World.CEIL, World.Z_BACK), Vector3(2 * w, 0, 0), Vector3(0, 0, length), 3, 18, ceil_c),
		_grid(Vector3(-w, 0, World.Z_BACK), Vector3(0, World.CEIL, 0), Vector3(0, 0, length), 5, 30, wall_c),
		_grid(Vector3(w, 0, World.Z_BACK), Vector3(0, World.CEIL, 0), Vector3(0, 0, length), 5, 30, wall_c),
		_grid(Vector3(-w, 0, World.Z_END), Vector3(2 * w, 0, 0), Vector3(0, World.CEIL, 0), 6, 5, wall_c * 0.9),
		_grid(Vector3(-w, 0, World.Z_BACK), Vector3(2 * w, 0, 0), Vector3(0, World.CEIL, 0), 2, 2, wall_c * 0.8),
	]


func _grid(origin: Vector3, u: Vector3, v: Vector3, nu: int, nv: int, base: Color) -> Dictionary:
	var pts := PackedVector3Array()
	for j in nv + 1:
		for i in nu + 1:
			pts.append(origin + u * (float(i) / nu) + v * (float(j) / nv))
	return {"pts": pts, "nu": nu, "nv": nv, "base": base}


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, _size), Color.BLACK)
	for g in _grids:
		_draw_grid(g)
	# a baseboard line on both walls keeps the perspective readable
	for side: float in [-1.0, 1.0]:
		var x := side * (World.HALF_W - 0.005)
		var pts := PackedVector3Array([Vector3(x, 0.0, World.Z_BACK), Vector3(x, 0.0, World.Z_END),
			Vector3(x, 0.09, World.Z_END), Vector3(x, 0.09, World.Z_BACK)])
		var cols := PackedColorArray()
		for p in pts:
			cols.append(shade_point(p, Color(0.03, 0.03, 0.035)))
		draw_world_poly(self, pts, cols)


func _draw_grid(g: Dictionary) -> void:
	var pts: PackedVector3Array = g["pts"]
	var nu: int = g["nu"]
	var nv: int = g["nv"]
	var base: Color = g["base"]
	var cols := PackedColorArray()
	for p in pts:
		cols.append(shade_point(p, base))
	var stride := nu + 1
	for j in nv:
		for i in nu:
			var a := j * stride + i
			var quad := PackedVector3Array([pts[a], pts[a + 1], pts[a + 1 + stride], pts[a + stride]])
			var qc := PackedColorArray([cols[a], cols[a + 1], cols[a + 1 + stride], cols[a + stride]])
			draw_world_poly(self, quad, qc)
