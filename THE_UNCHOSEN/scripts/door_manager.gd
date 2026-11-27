extends Node
## Loads door definitions from data/doors.json.
## Stories and doors live in data files, never in code, so new lives can be
## added without touching the scripts.

const DOORS_PATH := "res://data/doors.json"

var _doors: Array[Dictionary] = []
var _by_id: Dictionary = {}


func _ready() -> void:
	_load()


func _load() -> void:
	_doors.clear()
	_by_id.clear()
	var file := FileAccess.open(DOORS_PATH, FileAccess.READ)
	if file == null:
		push_error("DoorManager: cannot open %s" % DOORS_PATH)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("doors"):
		push_error("DoorManager: %s is not valid door data" % DOORS_PATH)
		return
	for raw: Variant in parsed["doors"]:
		var door: Dictionary = _normalize(raw)
		_doors.append(door)
		_by_id[door["id"]] = door


func _normalize(raw: Dictionary) -> Dictionary:
	var d := raw.duplicate(true)
	d["door_color"] = _to_color(d.get("door_color", [0.15, 0.14, 0.14]))
	d["light_color"] = _to_color(d.get("light_color", [1, 1, 1]))
	d["z"] = float(d.get("z", 3.0))
	d["wall"] = String(d.get("wall", "left"))
	d["enterable"] = bool(d.get("enterable", false))
	d["light_pattern"] = String(d.get("light_pattern", "steady"))
	d["peek_style"] = String(d.get("peek_style", ""))
	for key in ["title", "sound", "moment", "entry_text", "sound_after", "moment_after", "loop", "story"]:
		d[key] = String(d.get(key, ""))
	return d


func _to_color(v: Variant) -> Color:
	if v is Array and v.size() >= 3:
		return Color(float(v[0]), float(v[1]), float(v[2]))
	return Color.WHITE


func get_doors() -> Array[Dictionary]:
	return _doors


func get_door(id: String) -> Dictionary:
	return _by_id.get(id, {})
