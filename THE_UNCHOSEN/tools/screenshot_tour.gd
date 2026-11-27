extends SceneTree
# Dev-only: drives the corridor through every state and saves screenshots.
# xvfb-run godot --path . --rendering-driver opengl3 --resolution 720x1280 \
#   --script res://tools/screenshot_tour.gd   (set TOUR_OUT=/some/dir)
var out := OS.get_environment("TOUR_OUT")
var frame := 0
var c
var steps := []
var t := 0.0
var next_at := 0.0
var idx := 0

func _initialize() -> void:
	change_scene_to_file("res://scenes/corridor.tscn")
	steps = [
		[1.2, "shot", "01_intro_start"],
		[3.5, "shot", "02_intro_title"],
		[2.0, "tap_skip", ""],
		[1.6, "shot", "03_idle"],
		[0.0, "approach", 0],
		[0.9, "shot", "04_moving"],
		[1.2, "shot", "05_at_door_200tl"],
		[0.0, "peek", ""],
		[2.2, "shot", "06_peek_200tl"],
		[0.0, "turn_away", ""],
		[2.4, "shot", "07_turned_away"],
		[0.0, "approach", 1],
		[2.2, "shot", "08_at_door_letter"],
		[0.0, "peek", ""],
		[2.2, "shot", "09_peek_letter"],
		[0.0, "turn_away", ""],
		[2.4, "approach", 2],
		[2.2, "peek", ""],
		[2.2, "shot", "10_peek_wrongdoor"],
		[0.0, "turn_away", ""],
		[2.4, "approach", 3],
		[2.2, "peek", ""],
		[2.2, "shot", "11_peek_waiting"],
		[0.0, "turn_away", ""],
		[2.4, "approach", 4],
		[2.2, "shot", "12_at_door_end"],
		[0.0, "peek", ""],
		[2.2, "shot", "13_peek_train"],
		[0.0, "turn_away", ""],
		[2.4, "approach", 0],
		[2.2, "peek", ""],
		[2.2, "enter", ""],
		[1.0, "shot", "14_entering"],
		[3.0, "shot", "15_story_fadein"],
		[4.0, "shot", "16_story"],
		[0.0, "quit", ""],
	]

func _process(delta: float) -> bool:
	t += delta
	if idx >= steps.size():
		return true
	if t < next_at:
		return false
	var s: Array = steps[idx]
	if t < next_at + s[0]:
		return false
	next_at = t
	idx += 1
	c = current_scene
	match s[1]:
		"shot":
			var img := root.get_texture().get_image()
			img.save_png(out + "/" + s[2] + ".png")
			print("shot ", s[2], " state=", c.get("state"))
		"tap_skip":
			c._on_tap(Vector2(10, 10))
		"approach":
			c._approach(c.doors[s[2]])
		"peek":
			c._peek()
		"turn_away":
			c._turn_away()
		"enter":
			c._enter()
		"quit":
			quit()
	return false
