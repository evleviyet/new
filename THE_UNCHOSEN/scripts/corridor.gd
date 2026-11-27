extends Node
## The corridor scene: title menu, the walk in, and the three interactions
## with a door — approach, aralamak, enter (or turn away).
##
##   MENU → INTRO → IDLE → (tap door) → AT_DOOR → (Arala) → PEEKING
##   PEEKING → (Vazgeç) → IDLE        PEEKING → (hold İçeri gir) → the life
##
## Drawing lives in corridor_world.gd inside a low-res SubViewport (pixel
## art); this script only directs it.

const UIStyle := preload("res://scripts/ui_style.gd")
const IDLE_POS := Vector3(0.0, 1.6, 0.0)
const MENU_POS := Vector3(0.0, 1.6, -1.6)
const ENTER_HOLD := 1.1
## Finger-sized door targets, in screen pixels.
const MIN_TARGET := Vector2(96, 150)

enum State { MENU, INTRO, IDLE, MOVING, AT_DOOR, PEEKING, ENTERING }

var state: State = State.MENU
var focus_door = null
var _tween: Tween
var _press_pos := Vector2.ZERO
var _hinted := false

@onready var pixel: SubViewportContainer = $Pixel
@onready var world = $Pixel/View/World
@onready var peek_viewport: SubViewport = $PeekViewport
@onready var peek_scene = $PeekViewport/PeekScene
@onready var ui: Control = $HUD/UI
@onready var title_box: Control = $HUD/UI/Title
@onready var menu: Control = $HUD/UI/Menu
@onready var continue_btn: Button = $HUD/UI/Menu/Continue
@onready var new_btn: Button = $HUD/UI/Menu/New
@onready var sound_btn: Button = $HUD/UI/Menu/Sound
@onready var hint: Label = $HUD/UI/Hint
@onready var caption: Label = $HUD/UI/Caption
@onready var note: Label = $HUD/UI/Note
@onready var buttons: Control = $HUD/UI/Buttons
@onready var primary = $HUD/UI/Buttons/Primary
@onready var secondary: Button = $HUD/UI/Buttons/Secondary
@onready var fade: ColorRect = $HUD/UI/Fade


func _ready() -> void:
	ui.theme = UIStyle.make_theme()
	UIStyle.style_title(title_box.get_node("Name"), 64)
	title_box.get_node("Tagline").add_theme_font_override("font", UIStyle.italic())
	caption.add_theme_font_override("font", UIStyle.italic())
	get_viewport().size_changed.connect(_on_resize)
	_on_resize()
	primary.held.connect(_on_primary)
	secondary.pressed.connect(_on_secondary)
	continue_btn.pressed.connect(_on_continue)
	new_btn.pressed.connect(_on_new_game)
	sound_btn.pressed.connect(_on_sound)
	_refresh_sound_label()
	peek_scene.active = false
	peek_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_set_buttons("", "")
	for c: CanvasItem in [caption, note, hint, menu]:
		c.modulate.a = 0.0
	menu.visible = false
	AudioManager.play_ambience("corridor")
	AudioManager.play_music("corridor")
	for d in world.doors:
		AudioManager.door_loop(d.id, d.data.get("loop", ""))
	if GameManager.session_started:
		_start_return()
	else:
		_start_menu()


func _on_resize() -> void:
	peek_viewport.size = Vector2i(world.view_size())


func _to_world(pos: Vector2) -> Vector2:
	return pos * (world.view_size() / pixel.size)


# --- menu / intro / return -----------------------------------------------

func _start_menu() -> void:
	state = State.MENU
	fade.color = Color(0, 0, 0, 1)
	title_box.modulate.a = 0.0
	world.cam_pos = MENU_POS
	continue_btn.visible = SaveManager.has_save()
	new_btn.text = "Yeniden başla" if continue_btn.visible else "Başla"
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(fade, "color:a", 0.0, 2.2)
	_tween.tween_property(title_box, "modulate:a", 1.0, 2.0).set_delay(0.5)
	var order := [4, 0, 2, 1, 3]
	for i in order.size():
		if order[i] < world.doors.size():
			_tween.tween_property(world.doors[order[i]], "light_level", 1.0, 1.6).set_delay(0.8 + i * 0.5)
	_tween.tween_callback(func() -> void:
		menu.visible = true
		_fade_ui(menu, 1.0, 0.8)).set_delay(2.2)


func _on_new_game() -> void:
	if state != State.MENU:
		return
	AudioManager.sfx("ui")
	SaveManager.new_game()
	for d in world.doors:
		d.refresh_state()
	_walk_in()


func _on_continue() -> void:
	if state != State.MENU:
		return
	AudioManager.sfx("ui")
	GameManager.session_started = true
	if StoryManager.is_active():
		state = State.ENTERING
		var tw := create_tween()
		tw.tween_property(fade, "color", Color(1, 0.97, 0.92, 1), 1.0)
		tw.tween_callback(func() -> void: GameManager.resume_life())
		return
	_walk_in()


func _on_sound() -> void:
	AudioManager.toggle_mute()
	_refresh_sound_label()


func _refresh_sound_label() -> void:
	sound_btn.text = "Ses: kapalı" if AudioManager.muted else "Ses: açık"


func _walk_in() -> void:
	state = State.INTRO
	GameManager.session_started = true
	_fade_ui(menu, 0.0, 0.5)
	_fade_ui(title_box, 0.0, 1.6)
	if _tween and _tween.is_valid():
		_tween.kill()
	for d in world.doors:
		d.light_level = 1.0
	fade.color.a = 0.0
	AudioManager.sfx("steps")
	_move_camera([IDLE_POS, 0.0, 0.0], 3.2, func() -> void:
		menu.visible = false
		state = State.IDLE
		if not _hinted:
			hint.text = "Bir kapıya dokun."
			_fade_ui(hint, 1.0, 1.0))


func _start_return() -> void:
	# Coming back from a life: the light is still in your eyes.
	state = State.IDLE
	title_box.modulate.a = 0.0
	_hinted = true
	world.cam_pos = IDLE_POS
	for d in world.doors:
		d.light_level = 1.0
	fade.color = Color(1, 0.97, 0.92, 1)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 1.8)
	if GameManager.pending_epilogue:
		GameManager.pending_epilogue = false
		tw.tween_callback(func() -> void:
			_show_caption("Arkanda bir kapı kapandı.", "Diğerlerinin ardında hayatlar sürüyor.")
			var later := create_tween()
			later.tween_interval(5.0)
			later.tween_callback(func() -> void:
				if state == State.IDLE:
					_fade_ui(caption, 0.0, 1.5)
					_fade_ui(note, 0.0, 1.5)))


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
	var wp := _to_world(pos)
	match state:
		State.IDLE:
			var d = world.pick_door(wp, MIN_TARGET * (world.view_size() / pixel.size))
			if d:
				_approach(d)
		State.AT_DOOR:
			if focus_door and not focus_door.lived and Geometry2D.is_point_in_polygon(wp, focus_door.screen_outline()):
				_peek()


func _go_back() -> void:
	match state:
		State.AT_DOOR:
			_leave_door()
		State.PEEKING:
			_turn_away()
		State.MENU, State.IDLE:
			SaveManager.save()
			get_tree().quit()


# --- the three interactions ----------------------------------------------

## 1. Approach: you hear it, you see the light under it.
func _approach(d) -> void:
	focus_door = d
	state = State.MOVING
	_hinted = true
	_fade_ui(hint, 0.0, 0.4)
	_fade_ui(caption, 0.0, 0.3)
	_fade_ui(note, 0.0, 0.3)
	AudioManager.sfx("steps")
	_move_camera(d.view_approach(), 1.7, func() -> void:
		state = State.AT_DOOR
		if d.lived:
			_show_caption("Bu kapının ardındaki hayatı yaşadın.", "Kapı artık açılmıyor.")
			_set_buttons("", "Geri dön")
		else:
			_show_caption(d.text("sound"), "")
			_set_buttons("Arala", "Geri dön"))


func _leave_door() -> void:
	state = State.MOVING
	_set_buttons("", "")
	_fade_ui(caption, 0.0, 0.3)
	_fade_ui(note, 0.0, 0.3)
	AudioManager.sfx("steps")
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
	peek_scene.after = GameManager.any_story_completed()
	peek_scene.active = true
	peek_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	d.peek_texture = peek_viewport.get_texture()
	AudioManager.sfx("door_open")
	AudioManager.open_door_sound(d.id, true)
	var tw := create_tween()
	tw.tween_property(d, "open_angle", d.PEEK_ANGLE, 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(0.15)
	world.peek_zoom_out = 1.35
	_move_camera(d.view_peek(), 1.5, func() -> void:
		state = State.PEEKING
		if d.data["enterable"] and not d.lived:
			_show_caption(d.text("moment"), "İçeri girmek bir seçimdir. Basılı tut.")
			_set_buttons("İçeri gir", "Vazgeç", ENTER_HOLD)
		else:
			_show_caption(d.text("moment"), "Kapı bundan fazla açılmıyor.")
			_set_buttons("", "Vazgeç"))


## Turning away: the life stays where it is, a possibility.
func _turn_away() -> void:
	var d = focus_door
	state = State.MOVING
	_set_buttons("", "")
	_fade_ui(note, 0.0, 0.3)
	_fade_ui(caption, 0.0, 0.3)
	GameManager.mark_turned_away(d.id)
	SaveManager.save()
	AudioManager.open_door_sound(d.id, false)
	var tw := create_tween()
	tw.tween_property(d, "open_angle", 0.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		AudioManager.sfx("door_close")
		peek_scene.active = false
		peek_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		d.refresh_state())
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
	world.breath = 0.0
	AudioManager.sfx("enter")
	Input.vibrate_handheld(60)
	var tw := create_tween()
	tw.tween_property(d, "open_angle", d.ENTER_ANGLE, 1.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_move_camera(d.view_enter(), 2.0, func() -> void: pass)
	create_tween().tween_property(world, "peek_zoom_out", 1.0, 2.0)
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
			if focus_door and focus_door.data["enterable"] and not focus_door.lived:
				_enter()


func _on_secondary() -> void:
	AudioManager.sfx("ui")
	match state:
		State.AT_DOOR:
			_leave_door()
		State.PEEKING:
			_turn_away()


# --- per-frame -----------------------------------------------------------

func _process(_delta: float) -> void:
	# each life is heard louder the closer you stand to its door
	for d in world.doors:
		var dist: float = (world.cam_pos - (d.center + Vector3(0, 1.0, 0))).length()
		var v := 1.0 / (1.0 + dist * dist * 0.45)
		AudioManager.set_door_volume(d.id, v * d.light_level * (0.25 if d.lived else 1.0))


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


## view = [position: Vector3, yaw: float, lens_shift: float]
func _move_camera(view: Array, dur: float, done: Callable) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(world.cam_lerp.bind(world.cam_pos, world.cam_yaw, world.cam_shift, view[0], view[1], view[2]), 0.0, 1.0, dur)
	_tween.tween_callback(done)
