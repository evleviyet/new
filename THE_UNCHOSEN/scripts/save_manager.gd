extends Node
## Local save: one JSON file in user://. Written after every decision, so
## closing the app never loses a choice. Settings live in their own file and
## survive a new game.

const SAVE_PATH := "user://save.json"
const SETTINGS_PATH := "user://settings.json"
const VERSION := 1


func _ready() -> void:
	load_settings()
	load_game()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_APPLICATION_FOCUS_OUT]:
		if GameManager.session_started:
			save()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save() -> void:
	var data := {
		"version": VERSION,
		"game": GameManager.to_dict(),
		"story": StoryManager.to_dict(),
	}
	_write(SAVE_PATH, data)


func load_game() -> void:
	var data := _read(SAVE_PATH)
	if data.is_empty():
		return
	GameManager.from_dict(data.get("game", {}))
	StoryManager.from_dict(data.get("story", {}))


func new_game() -> void:
	GameManager.reset()
	StoryManager.stop()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	save()


func save_settings() -> void:
	_write(SETTINGS_PATH, {"muted": AudioManager.muted})


func load_settings() -> void:
	var s := _read(SETTINGS_PATH)
	if not s.is_empty():
		AudioManager.set_muted(bool(s.get("muted", false)))


func _write(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("SaveManager: cannot write %s" % path)
		return
	f.store_string(JSON.stringify(data, "\t"))


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
