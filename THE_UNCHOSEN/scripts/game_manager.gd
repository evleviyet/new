extends Node
## Global game state: what the player has looked at, turned away from and
## entered. No scores, no morality — only what happened.

signal door_state_changed(id: String)

const CORRIDOR_SCENE := "res://scenes/corridor.tscn"
const STORY_SCENE := "res://scenes/story_scene.tscn"

## id -> { "peeks": int, "turned_away": int, "entered": bool }
var door_states: Dictionary = {}
var current_door_id: String = ""
var intro_seen: bool = false
## The door the player last stood in front of; the corridor uses it to
## place the camera when coming back from a life.
var last_door_id: String = ""


func get_state(id: String) -> Dictionary:
	if not door_states.has(id):
		door_states[id] = {"peeks": 0, "turned_away": 0, "entered": false}
	return door_states[id]


func mark_peeked(id: String) -> void:
	get_state(id)["peeks"] += 1
	last_door_id = id
	door_state_changed.emit(id)


func mark_turned_away(id: String) -> void:
	get_state(id)["turned_away"] += 1
	last_door_id = id
	door_state_changed.emit(id)


## Opening a door is not choosing it. Entering is a commitment.
func enter_life(id: String) -> void:
	get_state(id)["entered"] = true
	current_door_id = id
	last_door_id = id
	door_state_changed.emit(id)
	get_tree().change_scene_to_file.call_deferred(STORY_SCENE)


func return_to_corridor() -> void:
	current_door_id = ""
	get_tree().change_scene_to_file.call_deferred(CORRIDOR_SCENE)
