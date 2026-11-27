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
const Fx := preload("res://scripts/fx.gd")
## Seconds at a door before it gives away a little more.
const DOOR_WAIT := 5.0
## What each lived life still sounds like, far away in the corridor.
const MEMORY := {
	"200_tl": {"loop": "rain", "sounds": ["horn", "coins", "car_window"]},
	"son_mektup": {"loop": "room", "sounds": ["pen", "knock"]},
	"yanlis_kapi": {"loop": "stairwell", "sounds": ["steps", "door_close"]},
}
const IDLE_POS := Vector3(0.0, 1.6, 0.0)
const MENU_POS := Vector3(0.0, 1.6, -1.6)
const ENTER_HOLD := 1.1
## Finger-sized door targets, in screen pixels.
const MIN_TARGET := Vector2(96, 150)

enum State { MENU, INTRO, IDLE, MOVING, AT_DOOR, PEEKING, ENTERING, FINALE }

var state: State = State.MENU
var focus_door = null
var _tween: Tween
var _press_pos := Vector2.ZERO
var _hinted := false
var _door_wait := 0.0
var _door_more_shown := false
var _idle_event := 20.0
var _memory_event := 30.0

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
	if not GameManager.session_started:
		AudioManager.play_music("corridor")
	for d in world.doors:
		AudioManager.door_loop(d.id, d.data.get("loop", ""))
	_apply_living()
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
	# the music stays at the threshold; inside it is only the corridor
	AudioManager.stop_music(8.0)
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
	if GameManager.pending_epilogue and GameManager.all_lives_completed() and not GameManager.finale_seen:
		GameManager.pending_epilogue = false
		tw.tween_callback(_finale)
		return
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
	_door_wait = 0.0
	_door_more_shown = false
	_move_camera(d.view_approach(), 1.7, func() -> void:
		state = State.AT_DOOR
		if d.lived:
			_show_caption("Bu kapının ardındaki hayatı yaşadın.", "Kapı artık açılmıyor.")
			_set_buttons("", "Geri dön")
		else:
			_show_caption(d.text("sound"), "")
			_set_buttons("Arala", "Geri dön"), true)


func _leave_door() -> void:
	state = State.MOVING
	_set_buttons("", "")
	_fade_ui(caption, 0.0, 0.3)
	_fade_ui(note, 0.0, 0.3)
	AudioManager.sfx("steps")
	_move_camera([IDLE_POS, 0.0, 0.0], 1.5, func() -> void:
		state = State.IDLE
		focus_door = null, true)


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
	# the handle goes down, the latch gives with a small jolt, then the gap
	var tw := create_tween()
	tw.tween_property(d, "handle_turn", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(d, "open_angle", 0.05, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.3)
	tw.tween_property(d, "handle_turn", 0.0, 0.3)
	tw.parallel().tween_property(d, "open_angle", d.PEEK_ANGLE, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
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


# --- the last door ---------------------------------------------------------

## Every life behind the corridor has been lived. The last door opens by
## itself. It does not explain anything.
func _finale() -> void:
	state = State.FINALE
	var d = world.doors[world.doors.size() - 1]
	focus_door = d
	_show_caption("Arkanda üç kapı kapandı.", "Koridorun sonunda bir kapı kendiliğinden aralanıyor.")
	AudioManager.play_music("ending", 4.0)
	var tw := create_tween()
	tw.tween_interval(4.0)
	tw.tween_callback(func() -> void:
		_fade_ui(caption, 0.0, 0.6)
		_fade_ui(note, 0.0, 0.6)
		AudioManager.sfx("steps")
		_move_camera(d.view_approach(), 2.6, func() -> void:
			peek_scene.set_style("train")
			peek_scene.after = true
			peek_scene.finale = true
			peek_scene.active = true
			peek_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			d.peek_texture = peek_viewport.get_texture()
			AudioManager.sfx("door_open")
			AudioManager.open_door_sound(d.id, true)
			create_tween().tween_property(d, "open_angle", d.PEEK_ANGLE, 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			world.peek_zoom_out = 1.35
			_move_camera(d.view_peek(), 1.8, func() -> void:
				_show_caption("Peronda üç kişi bekliyor. Hiçbiri diğerini tanımıyor.", "Trenin kapıları açık.")
				_set_buttons("Bin", "Vazgeç", ENTER_HOLD))))


func _finale_choice(boarded: bool) -> void:
	state = State.ENTERING
	GameManager.finale_seen = true
	SaveManager.save()
	_set_buttons("", "")
	_fade_ui(caption, 0.0, 0.5)
	_fade_ui(note, 0.0, 0.5)
	var d = focus_door
	var tw := create_tween()
	if boarded:
		Input.vibrate_handheld(60)
		AudioManager.sfx("enter")
		create_tween().tween_property(d, "open_angle", d.ENTER_ANGLE, 1.6)
		_move_camera(d.view_enter(), 2.0, func() -> void: pass)
		fade.color = Color(1, 0.97, 0.92, 0)
		tw.tween_interval(1.2)
		tw.tween_property(fade, "color:a", 1.0, 1.0)
		tw.tween_callback(func() -> void:
			_credits("Trene biniyorsun. Nereye gittiğini bilmiyorsun.\nKimse bilmiyor."))
	else:
		AudioManager.open_door_sound(d.id, false)
		create_tween().tween_property(d, "open_angle", 0.0, 1.0)
		tw.tween_interval(1.0)
		tw.tween_callback(func() -> void: AudioManager.sfx("door_close"))
		_move_camera([IDLE_POS, 0.0, 0.0], 2.5, func() -> void: pass)
		fade.color = Color(0, 0, 0, 0)
		tw.tween_interval(1.8)
		tw.tween_property(fade, "color:a", 1.0, 1.5)
		tw.tween_callback(func() -> void:
			_credits("Kapı kapanıyor. Tren gidiyor.\nKoridor hâlâ orada."))


func _credits(last_line: String) -> void:
	title_box.get_node("Tagline").text = last_line + "\n\n\nHer kapı bir hayat.\nHer hayat bir ihtimal.\nHer seçim bir vazgeçiş."
	title_box.modulate.a = 0.0
	caption.text = ""
	# credits sit above the fade, which settles into darkness
	title_box.move_to_front()
	note.move_to_front()
	create_tween().tween_property(fade, "color", Color(0.015, 0.015, 0.02, 1), 2.5)
	note.text = "Müzik ve kayıtlar: Meta Open Sound (CC0) · Fontlar: Pixelify Sans, Lora (OFL) · Godot Engine"
	var tw := create_tween()
	tw.tween_interval(1.5)
	tw.tween_property(title_box, "modulate:a", 1.0, 2.5)
	tw.tween_property(note, "modulate:a", 0.6, 1.5)
	tw.tween_interval(9.0)
	tw.tween_property(title_box, "modulate:a", 0.0, 2.0)
	tw.parallel().tween_property(note, "modulate:a", 0.0, 2.0)
	tw.tween_callback(func() -> void:
		GameManager.session_started = false
		get_tree().reload_current_scene())


func _on_primary() -> void:
	if state == State.FINALE:
		_finale_choice(true)
		return
	match state:
		State.AT_DOOR:
			_peek()
		State.PEEKING:
			if focus_door and focus_door.data["enterable"] and not focus_door.lived:
				_enter()


func _on_secondary() -> void:
	AudioManager.sfx("ui")
	if state == State.FINALE:
		_finale_choice(false)
		return
	match state:
		State.AT_DOOR:
			_leave_door()
		State.PEEKING:
			_turn_away()


# --- per-frame -----------------------------------------------------------

func _process(delta: float) -> void:
	_living_tick(delta)
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
	Fx.fade(c, alpha, dur)


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
## walking: the head bobs with the steps on the way.
func _move_camera(view: Array, dur: float, done: Callable, walking: bool = false) -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(world.cam_lerp.bind(world.cam_pos, world.cam_yaw, world.cam_shift, view[0], view[1], view[2]), 0.0, 1.0, dur)
	_tween.tween_callback(done)
	if walking:
		var w := create_tween()
		w.tween_property(world, "walk", 1.0, dur * 0.25)
		w.tween_interval(dur * 0.45)
		w.tween_property(world, "walk", 0.0, dur * 0.3)


# --- a corridor that remembers -------------------------------------------

## Every life lived changes the corridor a little. Nothing says so.
func _apply_living() -> void:
	var lived: Array = []
	for id in MEMORY:
		if bool(GameManager.get_state(id)["completed"]):
			lived.append(id)
	world.warmth = lived.size() / 3.0
	for d in world.doors:
		if String(d.data["wall"]) == "end":
			d.beckon = float(lived.size())
	var loops: Array = []
	for id in lived:
		loops.append(MEMORY[id]["loop"])
	AudioManager.set_memory_layers(loops)


func _lived_ids() -> Array:
	var out: Array = []
	for id in MEMORY:
		if bool(GameManager.get_state(id)["completed"]):
			out.append(id)
	return out


func _living_tick(delta: float) -> void:
	# waiting at a door: it gives away a little more, never the future
	if state == State.AT_DOOR and focus_door and not focus_door.lived and not _door_more_shown:
		_door_wait += delta
		if _door_wait >= DOOR_WAIT:
			_door_more_shown = true
			focus_door.pass_shadow(2.6)
			AudioManager.memory_sfx("steps")
			var more: String = focus_door.text("sound_more")
			if more != "":
				var tw := Fx.fade(caption, 0.0, 0.6)
				tw.tween_callback(func() -> void:
					if state == State.AT_DOOR:
						_show_caption(more, ""))
	if state != State.IDLE and state != State.AT_DOOR:
		return
	# now and then someone passes behind a door
	_idle_event -= delta
	if _idle_event <= 0.0:
		_idle_event = randf_range(16.0, 32.0)
		var candidates: Array = world.doors.filter(func(d) -> bool: return not d.lived and d != focus_door)
		if not candidates.is_empty():
			candidates.pick_random().pass_shadow(randf_range(2.0, 3.2))
	# and the lives already lived are heard, far away
	var lived := _lived_ids()
	if lived.is_empty():
		return
	_memory_event -= delta
	if _memory_event <= 0.0:
		_memory_event = randf_range(25.0, 55.0)
		var sounds: Array = MEMORY[lived.pick_random()]["sounds"]
		AudioManager.memory_sfx(sounds.pick_random())
