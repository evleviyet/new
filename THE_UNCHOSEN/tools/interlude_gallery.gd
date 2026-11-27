extends SceneTree
# Dev-only: renders every interlude at the start, middle and end of its walk.
#   GALLERY_OUT=/tmp/i.png xvfb-run godot --path . --rendering-driver opengl3 --script res://tools/interlude_gallery.gd

const STYLES := ["walk_to_market", "car_away", "walk_home", "night_letter", "stair_wait"]
const STEPS := [0.0, 0.5, 0.75, 1.0]
const W := 180
const H := 320

var views: Array = []
var frames := 0


func _initialize() -> void:
	var scene: PackedScene = load("res://scenes/peek_scene.tscn")
	for st: String in STYLES:
		for p: float in STEPS:
			var vp := SubViewport.new()
			vp.size = Vector2i(W, H)
			vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			vp.disable_3d = true
			var art = scene.instantiate()
			art.flags = {"y_let_in": true, "brought_bag": true}
			art.style = st
			art.progress = p
			art.walking = true
			vp.add_child(art)
			root.add_child(vp)
			views.append(vp)


func _process(_d: float) -> bool:
	frames += 1
	if frames < 40:
		return false
	var cols := STEPS.size()
	var rows := STYLES.size()
	var sheet := Image.create(cols * (W + 4), rows * (H + 4), false, Image.FORMAT_RGB8)
	sheet.fill(Color(1, 0, 1))
	for i in views.size():
		var img: Image = views[i].get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(img, Rect2i(0, 0, W, H), Vector2i((i % cols) * (W + 4), (i / cols) * (H + 4)))
	sheet.save_png(OS.get_environment("GALLERY_OUT"))
	print("interludes: ", views.size())
	quit()
	return true
