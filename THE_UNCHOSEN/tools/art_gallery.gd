extends SceneTree
# Dev-only: renders every scene style at card resolution into one sheet.
#   GALLERY_OUT=/tmp/g.png xvfb-run godot --path . --rendering-driver opengl3 --script res://tools/art_gallery.gd
# GALLERY_FLAGS="y_let_in,chocolate" sets story flags for flag-aware scenes.

const STYLES := ["red_light", "letter", "wrong_door", "waiting", "train", "car_interior", "car_interior_green",
	"car_window", "car_window_open", "glass_reflection", "market", "empty_street", "uphill", "pickup_cab",
	"home_door", "home_inside", "night_door", "child_room", "letter_blank", "phone_table", "postbox",
	"drawer", "envelope_door", "old_room", "apartment_entry", "stairwell", "door_ajar", "door_inside",
	"peephole", "window_street", "suitcase"]
const CELL := 134
const SCALE := 2

var views: Array = []
var frames := 0


func _initialize() -> void:
	var flags := {}
	for f in OS.get_environment("GALLERY_FLAGS").split(",", false):
		flags[f] = true
	var scene: PackedScene = load("res://scenes/peek_scene.tscn")
	for st: String in STYLES:
		var vp := SubViewport.new()
		vp.size = Vector2i(CELL, CELL)
		vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		vp.disable_3d = true
		var art = scene.instantiate()
		art.flags = flags
		art.style = st
		vp.add_child(art)
		root.add_child(vp)
		views.append(vp)


func _process(_d: float) -> bool:
	frames += 1
	if frames < 30:
		return false
	var cols := 8
	var rows := int(ceil(views.size() / float(cols)))
	var sheet := Image.create(cols * (CELL * SCALE + 6), rows * (CELL * SCALE + 6), false, Image.FORMAT_RGB8)
	sheet.fill(Color(1, 0, 1))
	for i in views.size():
		var img: Image = views[i].get_texture().get_image()
		img.convert(Image.FORMAT_RGB8)
		img.resize(CELL * SCALE, CELL * SCALE, Image.INTERPOLATE_NEAREST)
		sheet.blit_rect(img, Rect2i(0, 0, CELL * SCALE, CELL * SCALE), Vector2i((i % cols) * (CELL * SCALE + 6), (i / cols) * (CELL * SCALE + 6)))
	sheet.save_png(OS.get_environment("GALLERY_OUT"))
	print("gallery: ", views.size(), " styles")
	quit()
	return true
