extends Control
## Inside a life. For prototype 0.1 this is the threshold only: the player
## has committed, the moment keeps going behind them, and the decision cards
## (story_manager + decision_card) will start here in the next milestone.

const UIStyle := preload("res://scripts/ui_style.gd")

@onready var background = $Background
@onready var title: Label = $Margin/VBox/Title
@onready var body: Label = $Margin/VBox/Body
@onready var note: Label = $Margin/VBox/Note
@onready var back: Button = $Margin/VBox/Back
@onready var fade: ColorRect = $Fade


func _ready() -> void:
	theme = UIStyle.make_theme()
	var door: Dictionary = DoorManager.get_door(GameManager.current_door_id)
	if door.is_empty():
		door = DoorManager.get_door("200_tl")
	background.set_style(door.get("peek_style", ""))
	title.text = door.get("title", "")
	body.text = door.get("entry_text", "")
	note.text = "Artık sadece bakmıyorsun. Bu hayatın içindesin.\n\n[Prototip 0.1 — karar kartları bir sonraki aşamada burada başlayacak.]"
	back.pressed.connect(_on_back)
	for c: CanvasItem in [title, body, note, back]:
		c.modulate.a = 0.0
	fade.color = Color(1, 0.97, 0.92, 1)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 1.8)
	tw.tween_property(title, "modulate:a", 1.0, 1.0)
	tw.tween_property(body, "modulate:a", 1.0, 1.4)
	tw.tween_property(note, "modulate:a", 0.7, 1.0).set_delay(0.6)
	tw.tween_property(back, "modulate:a", 1.0, 0.6)


func _on_back() -> void:
	back.disabled = true
	var tw := create_tween()
	tw.tween_property(fade, "color", Color(0, 0, 0, 1), 0.9)
	tw.tween_callback(GameManager.return_to_corridor)
