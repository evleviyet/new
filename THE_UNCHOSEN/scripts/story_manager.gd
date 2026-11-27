extends Node
## Runs a life written in data/stories/*.json.
##
## Node types:  chapter · text · card (swipe left/right) · interlude · branch · ending
## Interlude:   a short scene lived step by step — "beats" (strings or
##              {"text","if","variants"}), tapped through; "walk" adds steps.
## Pause:       "pause": seconds of silence after a weighty card is decided.
## Conditions:  {"flag": value, ...} AND-ed; a missing flag counts as false.
## Variants:    the first entry whose "if" matches replaces the text — this
##              is how earlier choices come back later, sometimes through
##              someone else's eyes.
## There are no meters and no scores. Choices only set flags.

signal node_changed

var door_id: String = ""
var story_path: String = ""
var story: Dictionary = {}
var node_id: String = ""
var flags: Dictionary = {}
## [{ "node": id, "choice": "left"/"right"/"" }]
var history: Array = []


func is_active() -> bool:
	return node_id != "" and not story.is_empty()


func start(id: String, path: String) -> void:
	door_id = id
	story_path = path
	flags = {}
	history = []
	if not _load(path):
		node_id = ""
		return
	# what happened in lives already lived, readable as "<life>:<flag>"
	for life in GameManager.life_flags:
		if life == id:
			continue
		var lf: Dictionary = GameManager.life_flags[life]
		for k in lf:
			flags["%s:%s" % [life, k]] = lf[k]
	_enter(String(story.get("start", "")))


func stop() -> void:
	door_id = ""
	story_path = ""
	story = {}
	node_id = ""
	flags = {}
	history = []


func _load(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("StoryManager: cannot open %s" % path)
		return false
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("StoryManager: %s is not valid JSON" % path)
		return false
	story = parsed
	return true


func _node(id: String) -> Dictionary:
	return story.get("nodes", {}).get(id, {})


func matches(cond: Variant) -> bool:
	if typeof(cond) != TYPE_DICTIONARY:
		return true
	for k in cond:
		if flags.get(k, false) != cond[k]:
			return false
	return true


func _apply(set_flags: Variant) -> void:
	if typeof(set_flags) == TYPE_DICTIONARY:
		for k in set_flags:
			flags[k] = set_flags[k]


## Move to a node, applying its flags and resolving branches.
func _enter(id: String) -> void:
	var guard := 0
	while guard < 64:
		guard += 1
		var n := _node(id)
		if n.is_empty():
			push_error("StoryManager: missing node %s" % id)
			node_id = ""
			return
		_apply(n.get("set"))
		if String(n.get("type", "")) == "branch":
			var nxt := String(n.get("next", ""))
			for c: Dictionary in n.get("cases", []):
				if matches(c.get("if")):
					nxt = String(c["next"])
					break
			id = nxt
			continue
		node_id = id
		node_changed.emit()
		return


## Resolves any text entry: a plain string, or {"text", "variants", "if"}.
## Returns {"text", "echo"} or {} when the entry's own "if" does not hold.
## Shared by node texts, interlude beats and ending lines.
func resolve(entry: Variant) -> Dictionary:
	if entry is String:
		return {"text": entry, "echo": false}
	if typeof(entry) != TYPE_DICTIONARY:
		return {}
	var e: Dictionary = entry
	if e.has("if") and not matches(e["if"]):
		return {}
	var out := {"text": String(e.get("text", "")), "echo": e.has("if") and not (e["if"] as Dictionary).is_empty()}
	for v: Dictionary in e.get("variants", []):
		if matches(v.get("if")):
			out["text"] = String(v["text"])
			out["echo"] = out["echo"] or not (v.get("if", {}) as Dictionary).is_empty()
			break
	return out


## A resolved, ready-to-show view of the current node.
func current() -> Dictionary:
	var n := _node(node_id)
	if n.is_empty():
		return {}
	var view := {
		"id": node_id,
		"type": String(n.get("type", "text")),
		"perspective": String(n.get("perspective", "")),
		"art": String(n.get("art", "")),
		"speaker": String(n.get("speaker", "")),
		"title": String(n.get("title", "")),
		"sfx": String(n.get("sfx", "")),
		# seconds of silence after a weighty decision
		"pause": float(n.get("pause", 0.0)),
	}
	var r := resolve({"text": n.get("text", ""), "variants": n.get("variants", [])})
	view["text"] = r["text"]
	view["echo"] = r["echo"]
	if view["type"] == "card":
		view["left"] = String(n["left"]["label"])
		view["right"] = String(n["right"]["label"])
	if view["type"] == "interlude":
		var beats: Array[Dictionary] = []
		for b: Variant in n.get("beats", []):
			var rb := resolve(b)
			if not rb.is_empty() and String(rb["text"]) != "":
				beats.append(rb)
		view["beats"] = beats
		view["walk"] = bool(n.get("walk", false))
		view["text_at"] = String(n.get("text_at", "top"))
	if view["type"] == "ending":
		var lines: Array[String] = []
		for l: Variant in n.get("lines", []):
			var rl := resolve(l)
			if not rl.is_empty():
				lines.append(String(rl["text"]))
		view["lines"] = lines
		view["closing"] = String(n.get("closing", ""))
	var p: Dictionary = story.get("perspectives", {}).get(view["perspective"], {})
	view["perspective_name"] = String(p.get("name", ""))
	var col: Array = p.get("color", [0.9, 0.9, 0.9])
	view["perspective_color"] = Color(float(col[0]), float(col[1]), float(col[2]))
	return view


## Swipe on a decision card. side: "left" or "right".
func choose(side: String) -> void:
	var n := _node(node_id)
	if String(n.get("type", "")) != "card" or not n.has(side):
		return
	var o: Dictionary = n[side]
	history.append({"node": node_id, "choice": side})
	_apply(o.get("set"))
	_enter(String(o["next"]))
	SaveManager.save()


## Tap on a chapter, text or (finished) interlude node.
func advance() -> void:
	var n := _node(node_id)
	var t := String(n.get("type", ""))
	if t == "card" or t == "ending":
		return
	history.append({"node": node_id, "choice": ""})
	_enter(String(n.get("next", "")))
	SaveManager.save()


func ambience() -> String:
	return String(story.get("ambience", "rain"))


## Flags set inside this life only (not the inherited "<life>:" ones).
func own_flags() -> Dictionary:
	var out := {}
	for k: String in flags:
		if not k.contains(":"):
			out[k] = flags[k]
	return out


func to_dict() -> Dictionary:
	if not is_active():
		return {}
	return {"door_id": door_id, "story_path": story_path, "node_id": node_id,
		"flags": flags.duplicate(true), "history": history.duplicate(true)}


func from_dict(d: Dictionary) -> void:
	stop()
	if d.is_empty():
		return
	door_id = String(d.get("door_id", ""))
	story_path = String(d.get("story_path", ""))
	if story_path == "" or not _load(story_path):
		stop()
		return
	flags = d.get("flags", {}).duplicate(true)
	history = d.get("history", []).duplicate(true)
	node_id = String(d.get("node_id", ""))
	if _node(node_id).is_empty():
		stop()
