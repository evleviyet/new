extends SceneTree
# Dev-only: plays the whole game once and saves a screenshot at each step.
#   TOUR_OUT=/some/dir xvfb-run godot --path . --rendering-driver opengl3 \
#     --resolution 720x1280 --script res://tools/screenshot_tour.gd
# TOUR_CHOICES="right,right,left,..." overrides the card decisions.

var out := OS.get_environment("TOUR_OUT")
var choices: Array = []
var steps: Array = []
var idx := 0
var wait := 0.0
var shots := 0
var story_last := ""
var story_wait := 0.0


func _initialize() -> void:
	var env := OS.get_environment("TOUR_CHOICES")
	choices = Array((env if env != "" else "right,right,left,right,left,left,right,left,left,left").split(","))
	print("choices: ", choices)
	change_scene_to_file("res://scenes/corridor.tscn")
	steps = [
		[3.6, "shot", "menu"],
		[0.0, "call", "_on_new_game"],
		[3.8, "shot", "idle"],
		[0.0, "approach", 0],
		[2.1, "shot", "at_door"],
		[0.0, "call", "_peek"],
		[2.2, "shot", "peek"],
		[0.0, "call", "_enter"],
		[1.0, "shot", "entering"],
		[3.5, "story", ""],
		[3.0, "shot", "epilogue"],
		[2.0, "approach", 4],
		[2.2, "call", "_peek"],
		[2.2, "shot", "peek_after_train"],
		[0.0, "call", "_turn_away"],
		[2.4, "approach", 0],
		[2.2, "shot", "lived_door"],
		[0.5, "quit", ""],
	]
	wait = steps[0][0]


func _shot(name: String) -> void:
	shots += 1
	var img := root.get_texture().get_image()
	img.save_png("%s/%02d_%s.png" % [out, shots, name])
	print("shot ", shots, " ", name)


func _process(delta: float) -> bool:
	wait -= delta
	if wait > 0.0:
		return false
	if idx >= steps.size():
		return true
	var s: Array = steps[idx]
	var scene = current_scene
	if scene == null:
		return false
	match s[1]:
		"shot":
			_shot(s[2])
		"call":
			scene.call(s[2])
		"approach":
			scene._approach(scene.world.doors[s[2]])
		"story":
			if not _story_step(scene, delta):
				return false
		"quit":
			quit()
	idx += 1
	if idx < steps.size():
		wait = steps[idx][0]
	return false


# Plays cards until the life ends and the corridor is back. Returns true when done.
func _story_step(scene, delta: float) -> bool:
	if scene.name == "Corridor":
		return true
	if scene.name != "StoryScene" or scene._busy:
		return false
	var view: Dictionary = scene._view
	var id: String = view.get("id", "")
	if id != story_last:
		story_last = id
		story_wait = 0.9
		return false
	story_wait -= delta
	if story_wait > 0.0:
		return false
	if story_wait > -0.5:
		_shot("story_" + id)
		story_wait = -1.0
		if view["type"] == "card" and choices.size() > 0:
			scene.card.drag_to(-90.0 if choices[0] == "left" else 90.0)
			wait = 0.3
			_shot_later = "drag_" + id
		return false
	match String(view["type"]):
		"card":
			if _shot_later != "":
				_shot(_shot_later)
				_shot_later = ""
			scene.card.release()
			scene._choose_button(choices.pop_front() if choices.size() > 0 else "left")
		"ending":
			if scene.ending_btn.disabled:
				return false
			_shot("ending_full")
			scene._leave_life()
		_:
			scene._advance()
	return false


var _shot_later := ""
