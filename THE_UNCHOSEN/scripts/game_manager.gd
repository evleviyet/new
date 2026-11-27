extends Node
## Global game state: what the player has looked at, turned away from,
## entered and lived. No scores, no morality — only what happened.

signal door_state_changed(id: String)

const CORRIDOR_SCENE := "res://scenes/corridor.tscn"
const STORY_SCENE := "res://scenes/story_scene.tscn"

## id -> { "peeks": int, "turned_away": int, "entered": bool, "completed": bool }
var door_states: Dictionary = {}
var current_door_id: String = ""
## True once the player has left the title menu in this run of the app.
var session_started: bool = false
## Set when a life ends; the corridor shows a short epilogue on return.
var pending_epilogue: bool = false
## id -> flags of a life once it has been lived. Other lives can read them
## as "<id>:<flag>" — the lives are separate, but they touch.
var life_flags: Dictionary = {}
## The corridor's last moment, after every enterable life has been lived.
var finale_seen: bool = false


func reset() -> void:
	door_states.clear()
	life_flags.clear()
	current_door_id = ""
	pending_epilogue = false
	finale_seen = false


func all_lives_completed() -> bool:
	for d: Dictionary in DoorManager.get_doors():
		if d["enterable"] and not bool(get_state(d["id"])["completed"]):
			return false
	return true


func get_state(id: String) -> Dictionary:
	if not door_states.has(id):
		door_states[id] = {"peeks": 0, "turned_away": 0, "entered": false, "completed": false}
	var st: Dictionary = door_states[id]
	for k in ["peeks", "turned_away"]:
		st[k] = int(st.get(k, 0))
	for k in ["entered", "completed"]:
		st[k] = bool(st.get(k, false))
	return st


func any_story_completed() -> bool:
	for id in door_states:
		if bool(door_states[id].get("completed", false)):
			return true
	return false


func mark_peeked(id: String) -> void:
	get_state(id)["peeks"] += 1
	door_state_changed.emit(id)


func mark_turned_away(id: String) -> void:
	get_state(id)["turned_away"] += 1
	door_state_changed.emit(id)


## Opening a door is not choosing it. Entering is a commitment.
func enter_life(id: String) -> void:
	get_state(id)["entered"] = true
	current_door_id = id
	var door: Dictionary = DoorManager.get_door(id)
	StoryManager.start(id, door.get("story", ""))
	SaveManager.save()
	door_state_changed.emit(id)
	get_tree().change_scene_to_file.call_deferred(STORY_SCENE)


## Continue a life that was interrupted (app closed mid-story).
func resume_life() -> void:
	current_door_id = StoryManager.door_id
	get_tree().change_scene_to_file.call_deferred(STORY_SCENE)


func complete_life(id: String, flags: Dictionary = {}) -> void:
	get_state(id)["completed"] = true
	life_flags[id] = flags.duplicate(true)
	pending_epilogue = true
	SaveManager.save()
	door_state_changed.emit(id)


func return_to_corridor() -> void:
	current_door_id = ""
	get_tree().change_scene_to_file.call_deferred(CORRIDOR_SCENE)


func to_dict() -> Dictionary:
	return {"door_states": door_states.duplicate(true), "life_flags": life_flags.duplicate(true),
		"finale_seen": finale_seen}


func from_dict(d: Dictionary) -> void:
	door_states = d.get("door_states", {}).duplicate(true)
	life_flags = d.get("life_flags", {}).duplicate(true)
	finale_seen = bool(d.get("finale_seen", false))
