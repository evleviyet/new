extends Node2D
## The corridor as a place. A very small perspective renderer — a 3D box
## drawn with 2D polygons — living inside a low-resolution SubViewport, so
## the camera can really walk to a door, lean into the gap and step through,
## and the whole thing comes out as pixel art.

const World := preload("res://scripts/world.gd")
const DoorScene := preload("res://scenes/door.tscn")

const IDLE_POS := Vector3(0.0, World.EYE, 0.0)

var cam_pos: Vector3 = IDLE_POS
var cam_yaw: float = 0.0
## Lens shift (fraction of screen height): lifts the image so a door's
## threshold light stays above the buttons.
var cam_shift: float = 0.0
## >1 shows more of the other life through the gap; eases to 1 on entering.
var peek_zoom_out: float = 1.35
## Breathing sway; switched off while stepping through a door.
var breath: float = 1.0
var doors: Array = []
var time: float = 0.0

var _focal: float = 430.0
var _size := Vector2(720, 1280)
var _center := Vector2(360, 640)
var _eff_pos := IDLE_POS
var _cos := 1.0
var _sin := 0.0
var _grids: Array[Dictionary] = []

@onready var door_layer: Node2D = $Doors


func _ready() -> void:
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()
	_build_grids()
	for d in DoorManager.get_doors():
		var door = DoorScene.instantiate()
		door_layer.add_child(door)
		door.setup(d, self)
		doors.append(door)


func _on_resize() -> void:
	_size = get_viewport_rect().size
	_center = Vector2(_size.x * 0.5, _size.y * 0.5)
	_focal = _size.x * 0.6


func view_size() -> Vector2:
	return _size


# --- camera --------------------------------------------------------------

func cam_lerp(t: float, from_pos: Vector3, from_yaw: float, from_shift: float,
		to_pos: Vector3, to_yaw: float, to_shift: float) -> void:
	var e := smoothstep(0.0, 1.0, t)
	var ey := smoothstep(0.1, 1.0, t)
	cam_pos = from_pos.lerp(to_pos, e)
	cam_yaw = lerp_angle(from_yaw, to_yaw, ey)
	cam_shift = lerpf(from_shift, to_shift, e)


func _process(delta: float) -> void:
	time += delta
	# a body breathing, not a camera floating
	_eff_pos = cam_pos + Vector3(0, sin(time * 1.2) * 0.007 * breath, 0)
	var yaw := cam_yaw + sin(time * 0.5) * 0.004 * breath
	_cos = cos(yaw)
	_sin = sin(yaw)
	for d in doors:
		d.update_light(time)
	queue_redraw()


# --- projection ----------------------------------------------------------

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


## Projects a world polygon: returns [PackedVector2Array, colors] or [].
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
	if absf(_area(sp)) < 0.05:
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


## Door under a point in this viewport's pixels, with finger-sized targets.
func pick_door(pos: Vector2, min_size: Vector2):
	var best = null
	var best_d := INF
	for d in doors:
		var poly: PackedVector2Array = d.screen_outline()
		if poly.size() < 3:
			continue
		if Geometry2D.is_point_in_polygon(pos, poly):
			return d
		var r := Rect2(poly[0], Vector2.ZERO)
		for p in poly:
			r = r.expand(p)
		var c := r.get_center()
		var gx := maxf(0.0, (min_size.x - r.size.x) * 0.5)
		var gy := maxf(0.0, (min_size.y - r.size.y) * 0.5)
		r = r.grow_individual(gx, gy, gx, gy)
		if r.has_point(pos):
			var dist := pos.distance_to(c)
			if dist < best_d:
				best_d = dist
				best = d
	return best


# --- geometry ------------------------------------------------------------

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
	# baseboards keep the perspective readable
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
