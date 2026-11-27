extends SceneTree
# Dev-only: jumps to the moment every life has been lived and films the finale.
#   TOUR_OUT=/dir xvfb-run godot --path . --rendering-driver opengl3 --resolution 720x1280 --script res://tools/finale_tour.gd

var out := OS.get_environment("TOUR_OUT")
var t := 0.0
var shots := [13.5, 22.0, 26.0]
var boarded := false


func _initialize() -> void:
	var gm = root.get_node("GameManager")
	for id in ["200_tl", "son_mektup", "yanlis_kapi"]:
		gm.get_state(id)["completed"] = true
		gm.life_flags[id] = {}
	gm.session_started = true
	gm.pending_epilogue = true
	gm.finale_seen = false
	change_scene_to_file("res://scenes/corridor.tscn")


func _process(delta: float) -> bool:
	t += delta
	if shots.size() > 0 and t >= shots[0]:
		shots.pop_front()
		var img := root.get_texture().get_image()
		img.save_png("%s/finale_%02d.png" % [out, int(t)])
		print("shot ", int(t))
	var scene = current_scene
	if not boarded and t > 14.0 and scene and scene.get("state") == 7:
		boarded = true
		scene._finale_choice(true)
	if shots.is_empty():
		quit()
	return false
