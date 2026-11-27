extends Node2D
## One door in the corridor = one life.
## The door lives in corridor space (3D) and is drawn through the corridor's
## camera. It never knows the future of its life; it only knows its light,
## its sounds and the one moment it shows when aralanır.

const World := preload("res://scripts/world.gd")

const WIDTH := 0.95
const HEIGHT := 2.15
const PEEK_ANGLE := 0.8
const ENTER_ANGLE := 1.75

var data: Dictionary = {}
var id: String = ""
var corridor

## World-space frame of the door: bottom-centre on the wall plane,
## `right` as seen when facing it, `normal` pointing into the corridor.
var center := Vector3.ZERO
var right := Vector3.RIGHT
var normal := Vector3.BACK

## 0 = closed. Radians the leaf has swung into the other life.
var open_angle: float = 0.0
## 0..1, used by the intro to switch lights on one by one.
var light_level: float = 0.0
## Each time the player turns away, the light under this door settles a little.
var dim: float = 1.0
var peek_texture: Texture2D
## The player has lived this life; the door stays shut and dark.
var lived: bool = false

var _seed: float = 0.0
var _intensity: float = 1.0
var _light: Color = Color.WHITE

@onready var glow: Node2D = $Glow


func setup(door_data: Dictionary, owner_corridor) -> void:
	data = door_data
	id = data["id"]
	corridor = owner_corridor
	_light = data["light_color"]
	_seed = float(hash(id) % 1000) * 0.37
	var z: float = data["z"]
	var half: float = World.HALF_W
	match String(data["wall"]):
		"left":
			center = Vector3(-half, 0.0, z)
			right = Vector3(0, 0, 1)
			normal = Vector3(1, 0, 0)
		"right":
			center = Vector3(half, 0.0, z)
			right = Vector3(0, 0, -1)
			normal = Vector3(-1, 0, 0)
		_:
			center = Vector3(0.0, 0.0, World.Z_END)
			right = Vector3(1, 0, 0)
			normal = Vector3(0, 0, -1)
	refresh_state()


func refresh_state() -> void:
	var st: Dictionary = GameManager.get_state(id)
	dim = maxf(0.55, pow(0.88, float(st["turned_away"])))
	lived = bool(st["completed"])
	if lived:
		dim = 0.12


## Door text; once any life has been lived, some doors whisper something else.
func text(key: String) -> String:
	if GameManager.any_story_completed() and String(data.get(key + "_after", "")) != "":
		return data[key + "_after"]
	return data.get(key, "")


# --- camera views --------------------------------------------------------

func facing_yaw() -> float:
	var fwd := -normal
	return atan2(fwd.x, fwd.z)


func view_approach() -> Array:
	return [center + normal * 1.35 + Vector3(0, World.EYE, 0), facing_yaw(), 0.11]


func view_peek() -> Array:
	return [center + normal * 0.42 + right * 0.32 + Vector3(0, World.EYE - 0.1, 0), facing_yaw() + 0.12, 0.0]


func view_enter() -> Array:
	return [center + normal * 0.10 + Vector3(0, World.EYE - 0.05, 0), facing_yaw(), 0.0]


# --- light ---------------------------------------------------------------

func _pattern(t: float) -> float:
	var ts := t + _seed
	match String(data.get("light_pattern", "steady")):
		"traffic":
			return 0.85 + 0.12 * sin(ts * 0.9) + 0.04 * sin(ts * 9.0)
		"candle":
			return 0.72 + 0.14 * sin(ts * 6.1) * sin(ts * 2.3 + 1.0) + 0.06 * sin(ts * 13.0)
		"tv":
			var step := floorf(ts * 7.0)
			return 0.45 + 0.45 * fposmod(sin(step * 12.9898) * 43758.5453, 1.0)
		"fluorescent":
			if fposmod(ts * 0.23, 1.0) > 0.93:
				return 0.15 if int(ts * 24.0) % 2 == 0 else 0.9
			return 0.85
		"passing":
			return 0.30 + 0.9 * pow(maxf(0.0, sin(ts * 0.55)), 14.0)
	return 0.8


func update_light(t: float) -> void:
	_intensity = light_level * dim * _pattern(t)


func light_contrib(p: Vector3) -> Color:
	if _intensity <= 0.001 and open_angle <= 0.001:
		return Color(0, 0, 0)
	# light leaking from under the door
	var src := center + normal * 0.10 + Vector3(0, 0.02, 0)
	var d := p - src
	var c := Color(0, 0, 0)
	if d.dot(normal) > -0.02:
		var k := _intensity / (1.0 + d.length_squared() * 3.5)
		c += _light * k * 0.55
	# light pouring out of the gap once the door is open
	var o := clampf(open_angle / PEEK_ANGLE, 0.0, 2.5)
	if o > 0.0:
		var src2 := center + normal * 0.05 + Vector3(0, 1.0, 0)
		var d2 := p - src2
		if d2.dot(normal) > -0.05:
			c += _light * (o * 0.45 * light_level / (1.0 + d2.length_squared() * 1.4))
	return c


# --- picking -------------------------------------------------------------

## Projected outline of the doorway (for touch). Empty if not visible.
func screen_outline() -> PackedVector2Array:
	var pts := _quad(center, right, Vector3.UP, WIDTH * 0.5, 0.0, HEIGHT, 0.0)
	var res: Array = corridor.project_world(pts)
	return res[0] if res.size() > 0 else PackedVector2Array()


# --- drawing -------------------------------------------------------------

func _process(_delta: float) -> void:
	queue_redraw()
	glow.queue_redraw()


func _quad(origin: Vector3, u: Vector3, v: Vector3, half_u: float, v0: float, v1: float, push: float) -> PackedVector3Array:
	var o := origin + normal * push
	return PackedVector3Array([o - u * half_u + v * v0, o + u * half_u + v * v0, o + u * half_u + v * v1, o - u * half_u + v * v1])


func _shade_all(pts: PackedVector3Array, base: Color) -> PackedColorArray:
	var cols := PackedColorArray()
	for p in pts:
		cols.append(corridor.shade_point(p, base))
	return cols


func _draw() -> void:
	var up := Vector3.UP
	var self_light := _light * (_intensity * 0.06)
	# frame
	var frame := _quad(center, right, up, WIDTH * 0.5 + 0.075, 0.0, HEIGHT + 0.07, 0.004)
	corridor.draw_world_poly(self, frame, _shade_all(frame, Color(0.15, 0.14, 0.13) + self_light))
	# the other life, visible only through the opening
	if open_angle > 0.001 and peek_texture:
		var opening := _quad(center, right, up, WIDTH * 0.5, 0.0, HEIGHT, 0.006)
		var b := clampf(open_angle * 2.5, 0.0, 1.0)
		corridor.draw_world_poly(self, opening, PackedColorArray([Color(b, b, b)]), peek_texture, false)
	else:
		var inner := _quad(center, right, up, WIDTH * 0.5, 0.0, HEIGHT, 0.005)
		corridor.draw_world_poly(self, inner, _shade_all(inner, Color(0.01, 0.01, 0.012)))
	# leaf: hinged on the left, swings away from us into the room
	var hinge := center - right * (WIDTH * 0.5) + normal * 0.008
	var dir := right * cos(open_angle) - normal * sin(open_angle)
	var leaf := PackedVector3Array([hinge, hinge + dir * WIDTH, hinge + dir * WIDTH + up * HEIGHT, hinge + up * HEIGHT])
	var base: Color = data["door_color"]
	var leaf_cols := _shade_all(leaf, base * 0.55 + self_light)
	if open_angle > 0.001:
		var edge := _light * clampf(open_angle, 0.0, 1.0) * 0.12
		leaf_cols[1] += edge
		leaf_cols[2] += edge
	corridor.draw_world_poly(self, leaf, leaf_cols)
	# two recessed panels
	for pr: Vector2 in [Vector2(0.16, 0.95), Vector2(1.15, 1.98)]:
		var a := hinge + dir * 0.16 + up * pr.x - normal * 0.0
		var panel := PackedVector3Array([a, a + dir * (WIDTH - 0.32), a + dir * (WIDTH - 0.32) + up * (pr.y - pr.x), a + up * (pr.y - pr.x)])
		corridor.draw_world_poly(self, panel, _shade_all(panel, base * 0.42 + self_light))
	# handle
	var hp := hinge + dir * (WIDTH - 0.11) + up * 1.0
	var n_leaf := dir.cross(up).normalized() * -1.0
	var handle := PackedVector3Array([hp - dir * 0.03 + n_leaf * 0.01, hp + dir * 0.03 + n_leaf * 0.01,
		hp + dir * 0.03 + up * 0.1 + n_leaf * 0.01, hp - dir * 0.03 + up * 0.1 + n_leaf * 0.01])
	corridor.draw_world_poly(self, handle, _shade_all(handle, Color(0.35, 0.30, 0.22) + self_light * 3.0))


## Called by the additive Glow child: the light that leaks out.
func draw_glow(canvas: CanvasItem) -> void:
	var up := Vector3.UP
	var closed := clampf(1.0 - open_angle * 4.0, 0.0, 1.0)
	var k := _intensity * closed
	if k <= 0.002:
		return
	var lc := _light
	# strip under the door
	var strip := _quad(center, right, up, WIDTH * 0.5, 0.0, 0.03, 0.012)
	var sc := Color(lc.r, lc.g, lc.b, 1.0) * Color(k, k, k, 1.0)
	corridor.draw_world_poly(canvas, strip, PackedColorArray([sc * 1.6, sc * 1.6, sc * 0.6, sc * 0.6]))
	# hairline along the free edge
	var e0 := center + right * (WIDTH * 0.5 - 0.006) + normal * 0.012
	var edge := PackedVector3Array([e0, e0 + right * 0.012, e0 + right * 0.012 + up * HEIGHT, e0 + up * HEIGHT])
	var ec := sc * 0.35
	corridor.draw_world_poly(canvas, edge, PackedColorArray([ec, ec, ec * 0.2, ec * 0.2]))
	# keyhole
	var kh := center + right * (WIDTH * 0.5 - 0.11) + up * 0.88
	var key := PackedVector3Array([kh - right * 0.012 + normal * 0.014, kh + right * 0.012 + normal * 0.014,
		kh + right * 0.012 + up * 0.035 + normal * 0.014, kh - right * 0.012 + up * 0.035 + normal * 0.014])
	corridor.draw_world_poly(canvas, key, PackedColorArray([sc * 1.2]))
	# spill on the floor
	var f0 := center + Vector3(0, 0.003, 0)
	var spill := PackedVector3Array([
		f0 - right * (WIDTH * 0.5) + normal * 0.01,
		f0 + right * (WIDTH * 0.5) + normal * 0.01,
		f0 + right * (WIDTH * 0.5 + 0.35) + normal * 1.0,
		f0 - right * (WIDTH * 0.5 + 0.35) + normal * 1.0])
	var c0 := sc * 0.55
	var c1 := Color(0, 0, 0, 1)
	corridor.draw_world_poly(canvas, spill, PackedColorArray([c0, c0, c1, c1]))
