extends Control
## One card. Dragged sideways it tilts and shows the choice it would make;
## let go past the threshold and it is decided. The picture is a scene
## rendered small (pixel art) in its own SubViewport.

signal decided(side: String)

const THRESHOLD := 0.22   # fraction of card width
const MAX_TILT := 0.16

var interactive: bool = false
var left_label: String = ""
var right_label: String = ""
var _base := Vector2.ZERO
var _drag := 0.0
var _tween: Tween

@onready var art_view: SubViewport = $Art/View
@onready var scene = $Art/View/Scene
@onready var band: Control = $Band
@onready var choice_label: Label = $Band/Choice


func _ready() -> void:
	_base = position
	band.modulate.a = 0.0
	pivot_offset = Vector2(size.x * 0.5, size.y * 1.6)
	resized.connect(func() -> void: pivot_offset = Vector2(size.x * 0.5, size.y * 1.6))


func _process(_delta: float) -> void:
	# a card waiting for a decision floats very slightly, like a held breath
	if interactive and absf(_drag) < 0.5 and not (_tween and _tween.is_running()):
		var tt := Time.get_ticks_msec() / 1000.0
		position.y = _base.y + sin(tt * 1.3) * 3.0
		rotation = sin(tt * 0.8) * 0.006


func art_texture() -> Texture2D:
	return art_view.get_texture()


func set_scene(style: String, flags: Dictionary) -> void:
	scene.flags = flags
	scene.set_style(style)


func drag_to(dx: float) -> void:
	if not interactive:
		return
	_drag = dx
	position.y = _base.y
	position.x = _base.x + dx
	rotation = clampf(dx / (size.x * 2.5), -MAX_TILT, MAX_TILT)
	var k := clampf(absf(dx) / (size.x * THRESHOLD), 0.0, 1.0)
	band.modulate.a = k
	if dx < 0:
		choice_label.text = left_label
		choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	else:
		choice_label.text = right_label
		choice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT


func release() -> void:
	if not interactive:
		return
	if absf(_drag) >= size.x * THRESHOLD:
		decide("left" if _drag < 0 else "right")
	else:
		_snap_back()


## Decide without a drag (buttons, keys): the card still leans first.
func decide(side: String) -> void:
	if not interactive:
		return
	interactive = false
	var dir := -1.0 if side == "left" else 1.0
	choice_label.text = left_label if side == "left" else right_label
	_kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(band, "modulate:a", 1.0, 0.15)
	_tween.tween_property(self, "position:x", _base.x + dir * size.x * 1.6, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "rotation", dir * 0.45, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, 0.35).set_delay(0.12)
	_tween.chain().tween_callback(func() -> void: decided.emit(side))


func nudge() -> void:
	_kill()
	_tween = create_tween()
	_tween.tween_property(self, "rotation", 0.04, 0.08)
	_tween.tween_property(self, "rotation", -0.03, 0.1)
	_tween.tween_property(self, "rotation", 0.0, 0.1)


## Fade the current picture out sideways (text cards) — no decision.
func leave(dir: float = -1.0) -> void:
	interactive = false
	_kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "position:x", _base.x + dir * size.x * 0.25, 0.3)
	_tween.tween_property(self, "modulate:a", 0.0, 0.3)


func appear() -> void:
	_kill()
	_drag = 0.0
	position = _base + Vector2(0, 40)
	rotation = 0.0
	scale = Vector2(0.96, 0.96)
	modulate.a = 0.0
	band.modulate.a = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "position", _base, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, 0.35)


func _snap_back() -> void:
	_kill()
	_drag = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(self, "position:x", _base.x, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "rotation", 0.0, 0.25)
	_tween.tween_property(band, "modulate:a", 0.0, 0.2)


func _kill() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
