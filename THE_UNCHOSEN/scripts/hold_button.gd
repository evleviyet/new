extends Button
## A button that can require a long press. Peeking is a tap; entering a
## life is a commitment, so it asks the player to hold.

signal held

## 0 = acts like a normal tap button.
@export var hold_time: float = 0.0

var _progress: float = 0.0
var _holding: bool = false
var _done: bool = false


func _ready() -> void:
	button_down.connect(_on_down)
	button_up.connect(_on_up)
	pressed.connect(_on_pressed)


func reset() -> void:
	_progress = 0.0
	_holding = false
	_done = false
	queue_redraw()


func _on_down() -> void:
	if hold_time <= 0.0 or disabled:
		return
	_done = false
	_holding = true


func _on_up() -> void:
	_holding = false


func _on_pressed() -> void:
	if hold_time <= 0.0:
		held.emit()


func _process(delta: float) -> void:
	if hold_time <= 0.0:
		return
	if _holding:
		_progress = minf(1.0, _progress + delta / hold_time)
		if _progress >= 1.0:
			_holding = false
			_done = true
			held.emit()
		queue_redraw()
	elif not _done and _progress > 0.0:
		_progress = maxf(0.0, _progress - delta * 2.5)
		queue_redraw()


func _draw() -> void:
	if _progress <= 0.0:
		return
	var r := Rect2(Vector2(2, 2), Vector2((size.x - 4.0) * _progress, size.y - 4.0))
	draw_rect(r, Color(1.0, 0.95, 0.85, 0.16))
	draw_rect(Rect2(Vector2(2, size.y - 6.0), Vector2((size.x - 4.0) * _progress, 4.0)), Color(1.0, 0.95, 0.85, 0.8))
