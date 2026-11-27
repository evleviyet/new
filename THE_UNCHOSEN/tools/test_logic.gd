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
	check(enterable == 3, "three lives can be entered")
	var path: String = dm.get_door("200_tl")["story"]

	# --- audio -----------------------------------------------------------
	for snd in ["corridor", "rain", "music_corridor", "music_life", "music_ending", "ui", "steps",
			"door_open", "door_close", "enter", "card", "swipe", "tap", "echo", "chapter"]:
		check(root.get_node("AudioManager")._stream(snd) != null, "sound loads: " + snd)

	# --- random playthroughs (every life, alone and after 200 TL) -------
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for life in ["200_tl", "son_mektup", "yanlis_kapi"]:
		var lpath: String = dm.get_door(life)["story"]
		for inherited in [false, true]:
			gm.life_flags.clear()
			if inherited and life != "200_tl":
				gm.life_flags["200_tl"] = {"father_harsh": true, "chocolate": true, "gift": false}
			var endings := {}
			var echoes := 0
			for run in 150:
				sm.start(life, lpath)
				var steps := 0
				var cards := 0
				while steps < 200:
					var v: Dictionary = sm.current()
					if v.is_empty():
						check(false, "empty node mid-story (%s run %d)" % [life, run])
						break
					if v["echo"]:
						echoes += 1
					if v["sfx"] != "":
						check(ResourceLoader.exists("res://assets/audio/%s.ogg" % v["sfx"]), "card sound exists: " + v["sfx"])
					if v["type"] == "ending":
						check(v["lines"].size() == 3, "%s ending has three lines" % life)
						check(String(v["closing"]) != "", "ending has closing")
						endings[" / ".join(v["lines"])] = true
						break
					check(String(v["text"]) != "", "text present at %s:%s" % [life, v["id"]])
					if v["type"] == "card":
						cards += 1
						check(String(v["left"]) != "" and String(v["right"]) != "", "card labels at " + v["id"])
						sm.choose("left" if rng.randf() < 0.5 else "right")
					else:
						if v["type"] != "chapter":
							check(v["art"] != "", "art for %s:%s" % [life, v["id"]])
						sm.advance()
					steps += 1
				check(steps < 200, "run terminates")
				check(cards >= 6 and cards <= 15, "6-15 decisions per run in %s (got %d)" % [life, cards])
			print("%s%s: %d endings, %d echo screens" % [life, " (after 200 TL)" if inherited else "", endings.size(), echoes])
			check(endings.size() >= 8, "many endings in " + life)
			if inherited:
				check(echoes > 0, "earlier lives echo in " + life)
	gm.life_flags.clear()

	# own flags only leave a life; inherited ones stay behind
	gm.life_flags["200_tl"] = {"father_harsh": true}
	sm.start("son_mektup", dm.get_door("son_mektup")["story"])
	check(sm.flags.has("200_tl:father_harsh"), "inherited flag visible inside a later life")
	check(not sm.own_flags().has("200_tl:father_harsh"), "inherited flags are not re-exported")
	sm.stop()
	gm.life_flags.clear()

	# --- every art key is drawn by peek_scene.gd -----------------------
	var art_src := FileAccess.open("res://scripts/peek_scene.gd", FileAccess.READ).get_as_text()
	for life in ["200_tl", "son_mektup", "yanlis_kapi"]:
		var js: Dictionary = JSON.parse_string(FileAccess.open(dm.get_door(life)["story"], FileAccess.READ).get_as_text())
		for nid in js["nodes"]:
			var art := String(js["nodes"][nid].get("art", ""))
			if art != "":
				check(art_src.contains("\"%s\":" % art), "scene style exists: " + art)

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
	check(not gm.all_lives_completed(), "two lives still to live")
	gm.complete_life("son_mektup", {"m_sent": true})
	gm.complete_life("yanlis_kapi", {})
	check(gm.all_lives_completed(), "all lives lived -> finale")
	check(bool(gm.life_flags["son_mektup"]["m_sent"]), "life flags kept")
	save.save()
	gm.reset()
	save.load_game()
	check(gm.life_flags.has("son_mektup") and gm.all_lives_completed(), "lived lives survive a reload")
	gm.pending_epilogue = false
	save.new_game()

	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
	return true
