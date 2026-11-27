extends Control
## Inside a life. Cards in the manner of Reigns — swipe left or right — but
## there are no meters: a choice only changes what happens later, sometimes
## to someone else, sometimes seen through someone else's eyes.

const UIStyle := preload("res://scripts/ui_style.gd")

var _view: Dictionary = {}
var _busy: bool = false
var _pressing: bool = false
var _press_pos := Vector2.ZERO
var _last_perspective := ""
var _reveal: Tween

const DIALOGUE_COLOR := "#f1d9ae"

@onready var background: TextureRect = $Background
@onready var perspective: Label = $Perspective
@onready var story_text: RichTextLabel = $StoryText
@onready var text_shade: TextureRect = $TextShade
@onready var card = $CardHolder/Card
@onready var speaker: Label = $Speaker
@onready var choices: Control = $Choices
@onready var left_btn: Button = $Choices/Left
@onready var right_btn: Button = $Choices/Right
@onready var hint: Label = $Hint
@onready var chapter_box: Control = $Chapter
@onready var chapter_title: Label = $Chapter/Title
@onready var chapter_text: Label = $Chapter/Text
@onready var ending_box: Control = $Ending
@onready var ending_lines: VBoxContainer = $Ending/Lines
@onready var ending_closing: Label = $Ending/Closing
@onready var ending_btn: Button = $Ending/Back
@onready var fade: ColorRect = $Fade


func _ready() -> void:
	theme = UIStyle.make_theme()
	UIStyle.style_title(perspective, 26)
	UIStyle.style_title(speaker, 24)
	UIStyle.style_title(chapter_title, 88)
	UIStyle.style_title(hint, 22)
	chapter_text.add_theme_font_override("font", UIStyle.italic())
	story_text.add_theme_font_override("normal_font", UIStyle.serif())
	story_text.add_theme_font_override("italics_font", UIStyle.italic())
	text_shade.texture = _shade_texture()
	for b: Button in [left_btn, right_btn, ending_btn]:
		b.add_theme_font_override("font", UIStyle.italic())
		b.add_theme_font_size_override("font_size", 27)
	perspective.add_theme_font_override("font", UIStyle.spaced_pixel())
	ending_closing.add_theme_font_override("font", UIStyle.italic())
	card.choice_label.add_theme_font_override("font", UIStyle.italic())
	card.choice_label.add_theme_font_size_override("font_size", 32)
	for b: Button in [left_btn, right_btn]:
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	background.texture = card.art_texture()
	card.decided.connect(_on_decided)
	left_btn.pressed.connect(func() -> void: _choose_button("left"))
	right_btn.pressed.connect(func() -> void: _choose_button("right"))
	ending_btn.pressed.connect(_leave_life)
	AudioManager.clear_doors()
	AudioManager.play_ambience(StoryManager.ambience() if StoryManager.is_active() else "rain")
	AudioManager.play_music("life")
	for c: CanvasItem in [perspective, story_text, speaker, choices, hint, chapter_box, ending_box]:
		c.modulate.a = 0.0
	ending_box.visible = false
	fade.color = Color(1, 0.97, 0.92, 1)
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 0.0, 1.6)
	if not StoryManager.is_active():
		# nothing to live (missing story file): go back rather than hang
		tw.tween_callback(GameManager.return_to_corridor)
		return
	_show(StoryManager.current())


# --- showing nodes -------------------------------------------------------

func _show(view: Dictionary) -> void:
	_view = view
	_busy = true
	var type := String(view.get("type", ""))
	card.set_scene(view.get("art", ""), StoryManager.flags)
	match type:
		"chapter":
			_show_chapter(view)
		"ending":
			_show_ending(view)
		_:
			_show_card(view)


func _show_chapter(view: Dictionary) -> void:
	_last_perspective = view["perspective"]
	_fade(perspective, 0.0, 0.3)
	_fade(story_text, 0.0, 0.3)
	_fade(speaker, 0.0, 0.3)
	_fade(choices, 0.0, 0.3)
	_fade(hint, 0.0, 0.3)
	card.leave(0.0)
	_fade(background, 0.0, 0.6)
	AudioManager.sfx("chapter")
	chapter_title.text = view["title"]
	chapter_title.add_theme_color_override("font_color", view["perspective_color"])
	chapter_text.text = view["text"]
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_property(chapter_box, "modulate:a", 1.0, 1.2)
	tw.tween_callback(func() -> void:
		hint.text = "dokun"
		_fade(hint, 0.6, 0.8)
		_busy = false)


func _show_card(view: Dictionary) -> void:
	_fade(chapter_box, 0.0, 0.5)
	_fade(background, 0.32, 0.8)
	perspective.text = String(view["perspective_name"]).to_upper()
	perspective.add_theme_color_override("font_color", view["perspective_color"])
	_fade(perspective, 0.85, 0.6)
	story_text.text = _rich(view["text"])
	story_text.modulate.a = 1.0
	_typewrite()
	var tw := create_tween()
	tw.tween_interval(0.15)
	if view.get("echo", false):
		# an earlier choice has come back
		AudioManager.sfx("echo", -4.0)
		story_text.add_theme_color_override("default_color", Color(1.0, 0.94, 0.83))
	else:
		story_text.add_theme_color_override("default_color", Color(0.93, 0.91, 0.86))
	speaker.text = String(view.get("speaker", ""))
	_fade(speaker, 0.7 if speaker.text != "" else 0.0, 0.6)
	card.appear()
	AudioManager.sfx("card", -6.0)
	if String(view.get("sfx", "")) != "":
		AudioManager.sfx(view["sfx"], -3.0)
	if view["type"] == "card":
		card.left_label = view["left"]
		card.right_label = view["right"]
		left_btn.text = "← " + String(view["left"])
		right_btn.text = String(view["right"]) + " →"
		var decided := 0
		for h: Dictionary in StoryManager.history:
			if h.get("choice", "") != "":
				decided += 1
		if decided < 2:
			# first cards only: show how a card is decided
			hint.text = "← kartı kaydır →"
			_fade(hint, 0.55, 0.8)
		else:
			_fade(hint, 0.0, 0.3)
		_fade(choices, 1.0, 0.6)
		tw.tween_callback(func() -> void:
			card.interactive = true
			_busy = false)
	else:
		_fade(choices, 0.0, 0.3)
		hint.text = "dokun"
		tw.tween_callback(func() -> void:
			_fade(hint, 0.5, 0.6)
			_busy = false)


func _show_ending(view: Dictionary) -> void:
	_fade(perspective, 0.0, 0.4)
	_fade(story_text, 0.0, 0.4)
	_fade(speaker, 0.0, 0.4)
	_fade(choices, 0.0, 0.4)
	_fade(hint, 0.0, 0.4)
	_fade(chapter_box, 0.0, 0.4)
	card.leave(0.0)
	_fade(background, 0.0, 1.0)
	AudioManager.play_music("ending", 3.0)
	for c in ending_lines.get_children():
		c.queue_free()
	ending_box.visible = true
	ending_box.modulate.a = 1.0
	ending_closing.text = view.get("closing", "")
	ending_closing.modulate.a = 0.0
	ending_btn.modulate.a = 0.0
	ending_btn.disabled = true
	var tw := create_tween()
	tw.tween_interval(1.2)
	for line: String in view.get("lines", []):
		var l := Label.new()
		l.text = line
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.add_theme_font_size_override("font_size", 30)
		l.modulate.a = 0.0
		ending_lines.add_child(l)
		tw.tween_property(l, "modulate:a", 1.0, 1.4)
		tw.tween_interval(1.4)
	tw.tween_interval(0.6)
	tw.tween_property(ending_closing, "modulate:a", 1.0, 2.0)
	tw.tween_interval(1.0)
	tw.tween_callback(func() -> void:
		ending_btn.disabled = false
		_busy = false)
	tw.tween_property(ending_btn, "modulate:a", 1.0, 1.0)


# --- input ---------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if _busy or _view.is_empty():
		return
	var type := String(_view.get("type", ""))
	if type == "card":
		if event.is_action_pressed("ui_left"):
			_choose_button("left")
		elif event.is_action_pressed("ui_right"):
			_choose_button("right")
	elif type != "ending" and event.is_action_pressed("ui_accept"):
		_advance()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and type == "text" and _revealing():
			_reveal.kill()
			story_text.visible_ratio = 1.0
			return
		if event.pressed:
			_pressing = true
			_press_pos = event.position
		elif _pressing:
			_pressing = false
			var moved: float = event.position.x - _press_pos.x
			if type == "card":
				if absf(moved) < 12.0:
					card.nudge()
				else:
					card.release()
					if not card.interactive:
						_busy = true
			elif type != "ending" and (absf(moved) < 30.0 or absf(moved) > 80.0):
				_advance()
	elif event is InputEventMouseMotion and _pressing and type == "card":
		card.drag_to(event.position.x - _press_pos.x)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		# there is no stepping out of a life halfway; the app just closes
		SaveManager.save()
		get_tree().quit()


func _choose_button(side: String) -> void:
	if _busy or String(_view.get("type", "")) != "card" or not card.interactive:
		return
	_busy = true
	card.decide(side)


func _on_decided(side: String) -> void:
	_busy = true
	Input.vibrate_handheld(25)
	AudioManager.sfx("swipe")
	_fade(story_text, 0.0, 0.25)
	_fade(choices, 0.0, 0.25)
	StoryManager.choose(side)
	_next_after(0.35)


func _advance() -> void:
	_busy = true
	AudioManager.sfx("tap", -6.0)
	if String(_view.get("type", "")) == "text":
		card.leave(-1.0)
		_fade(story_text, 0.0, 0.25)
	else:
		_fade(chapter_box, 0.0, 0.4)
	_fade(hint, 0.0, 0.2)
	StoryManager.advance()
	_next_after(0.35)


func _next_after(delay: float) -> void:
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(func() -> void: _show(StoryManager.current()))


func _leave_life() -> void:
	ending_btn.disabled = true
	AudioManager.sfx("door_close")
	var id := StoryManager.door_id
	var lived := StoryManager.own_flags()
	StoryManager.stop()
	GameManager.complete_life(id, lived)
	var tw := create_tween()
	tw.tween_property(fade, "color", Color(0, 0, 0, 1), 1.4)
	tw.tween_callback(GameManager.return_to_corridor)


## Spoken words — anything between “ ” — are set in italics, warmer.
func _rich(text: String) -> String:
	var t := text.replace("[", "[lb]")
	# keep amounts whole: "200 TL" never breaks across lines
	var re := RegEx.create_from_string("(\\d) (TL|lira)")
	t = re.sub(t, "$1\u00a0$2", true)
	var out := ""
	var inside := false
	for ch in t:
		if ch == "“" and not inside:
			inside = true
			out += "[i][color=%s]“" % DIALOGUE_COLOR
		elif ch == "”" and inside:
			inside = false
			out += "”[/color][/i]"
		else:
			out += ch
	if inside:
		out += "[/color][/i]"
	return out


## The text arrives at the pace of reading, not all at once.
func _typewrite() -> void:
	if _reveal and _reveal.is_valid():
		_reveal.kill()
	story_text.visible_ratio = 0.0
	var n := story_text.get_total_character_count()
	_reveal = create_tween()
	_reveal.tween_interval(0.2)
	_reveal.tween_property(story_text, "visible_ratio", 1.0, clampf(n * 0.026, 0.4, 2.6))


func _revealing() -> bool:
	return _reveal != null and _reveal.is_running() and story_text.visible_ratio < 1.0


func _shade_texture() -> Texture2D:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.0))
	g.set_color(1, Color(0, 0, 0, 0.0))
	g.add_point(0.25, Color(0, 0, 0, 0.5))
	g.add_point(0.75, Color(0, 0, 0, 0.5))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0.0)
	tex.fill_to = Vector2(0.5, 1.0)
	tex.width = 4
	tex.height = 64
	return tex


func _fade(c: CanvasItem, a: float, d: float) -> void:
	create_tween().tween_property(c, "modulate:a", a, d)
