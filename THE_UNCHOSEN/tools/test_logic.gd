extends SceneTree
# Headless logic tests for story, save and game state.
#   godot --headless --path . --script res://tools/test_logic.gd
# Exits with code 1 on any failure.

var failures := 0
var checks := 0


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL: ", what)


func _initialize() -> void:
	# autoloads are ready on the first frame
	pass


var _ran := false


func _process(_d: float) -> bool:
	if _ran:
		return true
	_ran = true
	var dm = root.get_node("DoorManager")
	var gm = root.get_node("GameManager")
	var sm = root.get_node("StoryManager")
	var save = root.get_node("SaveManager")

	# --- doors -----------------------------------------------------------
	var doors: Array = dm.get_doors()
	check(doors.size() == 5, "five doors")
	var enterable := 0
	for d: Dictionary in doors:
		if d["enterable"]:
			enterable += 1
			check(FileAccess.file_exists(d["story"]), "story file exists for " + d["id"])
		check(d["sound"] != "" and d["moment"] != "", "door texts for " + d["id"])
		check(ResourceLoader.exists("res://assets/audio/%s.ogg" % d["loop"]), "door loop sound for " + d["id"])
	check(enterable == 1, "exactly one enterable door in 0.1")
	var path: String = dm.get_door("200_tl")["story"]

	# --- audio -----------------------------------------------------------
	for snd in ["corridor", "rain", "music_corridor", "music_life", "music_ending", "ui", "steps",
			"door_open", "door_close", "enter", "card", "swipe", "tap", "echo", "chapter"]:
		check(root.get_node("AudioManager")._stream(snd) != null, "sound loads: " + snd)

	# --- random playthroughs --------------------------------------------
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var endings := {}
	var max_steps := 0
	for run in 300:
		sm.start("200_tl", path)
		var steps := 0
		var cards := 0
		while steps < 200:
			var v: Dictionary = sm.current()
			if v.is_empty():
				check(false, "empty node mid-story (run %d)" % run)
				break
			check(String(v["text"]) != "" or v["type"] == "ending", "text present at " + v["id"])
			if v["type"] == "ending":
				check(v["lines"].size() == 3, "ending has three lines")
				check(String(v["closing"]) != "", "ending has closing")
				endings[" / ".join(v["lines"])] = true
				break
			if v["type"] == "card":
				cards += 1
				check(String(v["left"]) != "" and String(v["right"]) != "", "card has two labels at " + v["id"])
				sm.choose("left" if rng.randf() < 0.5 else "right")
			else:
				check(v["art"] != "" or v["type"] == "chapter", "art for " + v["id"])
				sm.advance()
			steps += 1
		max_steps = maxi(max_steps, steps)
		check(steps < 200, "run %d terminates" % run)
		check(cards >= 6 and cards <= 15, "6-15 decisions per run (got %d)" % cards)
	print("random runs: 300, distinct endings seen: ", endings.size(), ", longest run: ", max_steps, " screens")
	check(endings.size() >= 10, "many different endings")

	# --- the core rule: no meters, no scores ----------------------------
	var f := FileAccess.open(path, FileAccess.READ)
	var raw := f.get_as_text().to_lower()
	for word in ["score", "puan", "karma", "morality", "ahlak"]:
		check(not raw.contains("\"" + word), "no %s in story data" % word)

	# --- save / continue ------------------------------------------------
	save.new_game()
	check(not sm.is_active(), "new game clears story")
	check(gm.door_states.is_empty(), "new game clears doors")
	gm.mark_peeked("son_mektup")
	gm.mark_turned_away("son_mektup")
	sm.start("200_tl", path)
	sm.advance()      # chapter
	sm.advance()      # a1
	sm.choose("right")  # open the window
	var node_before: String = sm.node_id
	var flags_before: Dictionary = sm.flags.duplicate()
	save.save()
	sm.stop()
	gm.reset()
	save.load_game()
	check(sm.is_active(), "story resumes after load")
	check(sm.node_id == node_before, "same node after load (%s)" % sm.node_id)
	check(sm.flags == flags_before, "same flags after load")
	check(int(gm.get_state("son_mektup")["turned_away"]) == 1, "door memory survives load")

	# --- completing a life ----------------------------------------------
	check(not gm.any_story_completed(), "nothing lived yet")
	sm.stop()
	gm.complete_life("200_tl")
	check(gm.any_story_completed(), "life completed")
	check(bool(gm.get_state("200_tl")["completed"]), "door marked lived")
	gm.pending_epilogue = false
	save.new_game()

	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
	return true
