extends Node
## Music, ambience, one-shot sounds and the muffled lives behind the doors.
## Sounds are looked up by name in res://assets/audio/<name>.ogg; a missing
## file is simply silent, so content can be added at any time.

const AUDIO_DIR := "res://assets/audio/"
const CLOSED_CUTOFF := 700.0
const OPEN_CUTOFF := 12000.0

var muted: bool = false

var _music: Array[AudioStreamPlayer] = []
var _music_idx := 0
var _music_name := ""
var _ambience: AudioStreamPlayer
var _ambience_name := ""
var _sfx: Array[AudioStreamPlayer] = []
var _sfx_next := 0
var _doors: Dictionary = {}   # id -> AudioStreamPlayer
var _door_lowpass: AudioEffectLowPassFilter
var _cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_make_bus("Music", -4.0)
	_make_bus("Ambience", -6.0)
	_make_bus("SFX", -3.0)
	var doors_bus := _make_bus("Doors", -2.0)
	_door_lowpass = AudioEffectLowPassFilter.new()
	_door_lowpass.cutoff_hz = CLOSED_CUTOFF
	AudioServer.add_bus_effect(doors_bus, _door_lowpass)
	for i in 2:
		var m := AudioStreamPlayer.new()
		m.bus = "Music"
		m.volume_db = -80.0
		add_child(m)
		_music.append(m)
	_ambience = AudioStreamPlayer.new()
	_ambience.bus = "Ambience"
	add_child(_ambience)
	for i in 8:
		var s := AudioStreamPlayer.new()
		s.bus = "SFX"
		add_child(s)
		_sfx.append(s)


func _make_bus(bus_name: String, db: float) -> int:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		idx = AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		AudioServer.set_bus_send(idx, "Master")
	AudioServer.set_bus_volume_db(idx, db)
	return idx


func _looped(s: AudioStream) -> AudioStream:
	if s is AudioStreamOggVorbis:
		(s as AudioStreamOggVorbis).loop = true
	return s


func _stream(sound: String) -> AudioStream:
	if sound == "":
		return null
	if _cache.has(sound):
		return _cache[sound]
	var path := AUDIO_DIR + sound + ".ogg"
	var s: AudioStream = null
	if ResourceLoader.exists(path):
		s = load(path)
	_cache[sound] = s
	return s


# --- settings ------------------------------------------------------------

func set_muted(value: bool) -> void:
	muted = value
	AudioServer.set_bus_mute(0, muted)


func toggle_mute() -> void:
	set_muted(not muted)
	SaveManager.save_settings()


# --- music & ambience ----------------------------------------------------

func play_music(track: String, fade: float = 2.5) -> void:
	if track == _music_name:
		return
	_music_name = track
	var old := _music[_music_idx]
	_music_idx = 1 - _music_idx
	var nu := _music[_music_idx]
	var tw := create_tween().set_parallel(true)
	tw.tween_property(old, "volume_db", -80.0, fade)
	var s := _looped(_stream("music_" + track)) if track != "ending" else _stream("music_" + track)
	if s:
		nu.stream = s
		nu.volume_db = -40.0
		nu.play()
		tw.tween_property(nu, "volume_db", 0.0, fade)


func play_ambience(track: String, fade: float = 2.0) -> void:
	if track == _ambience_name:
		return
	_ambience_name = track
	var s := _looped(_stream(track))
	var tw := create_tween()
	tw.tween_property(_ambience, "volume_db", -60.0, fade * 0.5)
	tw.tween_callback(func() -> void:
		if s:
			_ambience.stream = s
			_ambience.play()
		else:
			_ambience.stop())
	tw.tween_property(_ambience, "volume_db", 0.0, fade * 0.5)


## Fire-and-forget sound. pitch_var adds a little life to repeats.
func sfx(sound: String, volume_db: float = 0.0, pitch_var: float = 0.05) -> void:
	var s := _stream(sound)
	if s == null:
		return
	var p := _sfx[_sfx_next]
	_sfx_next = (_sfx_next + 1) % _sfx.size()
	p.stream = s
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()


# --- the lives behind the doors ------------------------------------------

func door_loop(id: String, sound: String) -> void:
	clear_door(id)
	var s := _looped(_stream(sound))
	if s == null:
		return
	var p := AudioStreamPlayer.new()
	p.bus = "Doors"
	p.stream = s
	p.volume_db = -80.0
	add_child(p)
	p.play(randf() * 4.0)
	_doors[id] = p


func set_door_volume(id: String, linear: float) -> void:
	if _doors.has(id):
		_doors[id].volume_db = linear_to_db(clampf(linear, 0.0001, 1.0))


## Opening a door takes the wall away from its sound.
func open_door_sound(_id: String, open: bool) -> void:
	var tw := create_tween()
	tw.tween_property(_door_lowpass, "cutoff_hz", OPEN_CUTOFF if open else CLOSED_CUTOFF, 1.2 if open else 0.8)


func clear_door(id: String) -> void:
	if _doors.has(id):
		_doors[id].queue_free()
		_doors.erase(id)


func clear_doors() -> void:
	for id in _doors.keys():
		clear_door(id)
	_door_lowpass.cutoff_hz = CLOSED_CUTOFF


func _exit_tree() -> void:
	# let go of every stream so nothing is held when the engine shuts down
	clear_doors()
	for p: AudioStreamPlayer in _music + _sfx + [_ambience]:
		p.stop()
		p.stream = null
	_cache.clear()
