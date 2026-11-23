extends Node
## Global helper (autoload "Game"): settings, music, sound effects, controls, and the
## Grand Prix: which cup/class is being raced, points, and unlocked progress.
## Settings and progress are saved to user://settings.cfg between launches.

const SETTINGS_PATH := "user://settings.cfg"
const LAYOUTS := ["auto", "ds", "single"]

signal layout_changed

const RACE_SCENE := "res://scenes/main.tscn"
const MENU_SCENE := "res://scenes/menu.tscn"
const POINTS := [15, 12, 10, 8, 6, 5, 4, 3, 2, 1]   # points for 1st..10th in each race

# Ten characters. You pick one; the other nine are your CPU rivals.
# stats: speed, accel(eration), handling, drift (boost charge), weight; each 1-5,
# every character's stats add up to 15 so nobody is simply better.
# skill: how well that character drives when the CPU controls it (fraction of top speed).
# look: an extra part on the kart so each one is easy to spot.
const RACERS := [
	{"name": "RUBY", "type": "ALL-ROUNDER", "body": Color(0.9, 0.2, 0.2), "suit": Color(1.0, 0.85, 0.2),
		"stats": [3, 3, 3, 3, 3], "look": "", "skill": 0.97, "lane": 0.31},
	{"name": "AZURE", "type": "TOP SPEED", "body": Color(0.2, 0.45, 0.95), "suit": Color(0.9, 0.9, 0.95),
		"stats": [5, 2, 2, 2, 4], "look": "spoiler", "skill": 0.995, "lane": -1.25},
	{"name": "OLIVE", "type": "NIMBLE", "body": Color(0.35, 0.6, 0.2), "suit": Color(0.95, 0.8, 0.5),
		"stats": [2, 4, 4, 3, 2], "look": "bigwheels", "skill": 0.98, "lane": 1.25},
	{"name": "SUNNY", "type": "QUICK START", "body": Color(1.0, 0.75, 0.1), "suit": Color(0.3, 0.3, 0.35),
		"stats": [2, 5, 3, 3, 2], "look": "antenna", "skill": 0.985, "lane": -0.62},
	{"name": "CORAL", "type": "LIGHT DRIFTER", "body": Color(1.0, 0.5, 0.45), "suit": Color(0.25, 0.55, 0.6),
		"stats": [3, 3, 4, 4, 1], "look": "fins", "skill": 0.975, "lane": 0.94},
	{"name": "VIOLET", "type": "DRIFT ACE", "body": Color(0.6, 0.3, 0.85), "suit": Color(0.95, 0.95, 0.95),
		"stats": [3, 2, 3, 5, 2], "look": "spoiler", "skill": 0.965, "lane": 0.62},
	{"name": "MINT", "type": "GRIP", "body": Color(0.45, 0.9, 0.7), "suit": Color(0.35, 0.25, 0.5),
		"stats": [2, 3, 5, 3, 2], "look": "antenna", "skill": 0.955, "lane": -0.94},
	{"name": "INDIGO", "type": "HEAVYWEIGHT", "body": Color(0.2, 0.2, 0.55), "suit": Color(1.0, 0.6, 0.2),
		"stats": [4, 2, 2, 2, 5], "look": "wide", "skill": 0.945, "lane": 1.25},
	{"name": "SLATE", "type": "BRUISER", "body": Color(0.45, 0.5, 0.55), "suit": Color(0.9, 0.4, 0.2),
		"stats": [4, 3, 2, 2, 4], "look": "wide", "skill": 0.935, "lane": 0.0},
	{"name": "COCOA", "type": "PUNCHY", "body": Color(0.5, 0.32, 0.2), "suit": Color(0.95, 0.9, 0.75),
		"stats": [3, 4, 2, 3, 3], "look": "bigwheels", "skill": 0.925, "lane": -1.25},
]
const STAT_NAMES := ["SPEED", "ACCEL", "HANDLING", "DRIFT", "WEIGHT"]
# CPU skill shifts per class: gentler at 50cc, tougher at 150cc.
const CLASS_SKILL := [-0.03, 0.0, 0.02]

var music_on := true
var sfx_on := true
var best_laps := {}    # track name -> best lap time in seconds
var best_places := {}  # "class:cup" -> best final cup position (1 = won)
var layout := "auto"   # auto: two screens on the near-square inner screen, one on the cover screen
var player_char := "RUBY"   # the character you drive
var ds_controls := true  # D-pad + ABXY + R on the bottom screen (false = round buttons)

# The Grand Prix in progress.
var cc := 0            # speed class index into TrackData.CLASSES
var cup := 0           # cup index into TrackData.CUPS
var race_no := 0       # 0..2 within the cup
var points := {}       # racer name -> points so far this cup
var last_race := []    # finishing order of the last race (names)

var ui_font: Font      # crisp pixel font used by all the UI (use sizes 8, 16, 24, 32)
var ui_theme: Theme

var _music: AudioStreamPlayer
var _sounds := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep working while the game is paused
	_setup_buses()
	_setup_input()
	_load_settings()
	_setup_theme()

	_music = AudioStreamPlayer.new()
	_music.bus = "Music"
	var song: AudioStreamOggVorbis = load("res://assets/audio/music_loop.ogg")
	song.loop = true  # one short tune that repeats forever
	_music.stream = song
	_music.volume_db = -8.0
	add_child(_music)

	for sound in ["beep", "go", "boost", "lap", "finish", "bump"]:
		_sounds[sound] = load("res://assets/audio/%s.ogg" % sound)
	_apply_audio()


# ---------------------------------------------------------------- music & sound

func _unhandled_input(event: InputEvent) -> void:
	# M toggles music anywhere: menu, race, or paused.
	if event.is_action_pressed("toggle_music"):
		set_music(not music_on)


func start_music() -> void:
	if not _music.playing:
		_music.play()
	_music.stream_paused = not music_on


func set_music(on: bool) -> void:
	music_on = on
	_apply_audio()
	save_settings()


func set_sfx(on: bool) -> void:
	sfx_on = on
	_apply_audio()
	save_settings()


func play_sfx(sound: String, volume_db := 0.0) -> void:
	if not sfx_on or not _sounds.has(sound):
		return
	var p := AudioStreamPlayer.new()
	p.stream = _sounds[sound]
	p.bus = "SFX"
	p.volume_db = volume_db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


func _apply_audio() -> void:
	# Pausing the stream (not just muting) means no CPU is spent on music when it's off.
	if _music:
		_music.stream_paused = not music_on
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not sfx_on)


func _setup_buses() -> void:
	for bus_name in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")


# ---------------------------------------------------------------- display

func toggle_controls() -> void:
	ds_controls = not ds_controls
	save_settings()
	layout_changed.emit()


func cycle_layout() -> void:
	layout = LAYOUTS[(LAYOUTS.find(layout) + 1) % LAYOUTS.size()]
	save_settings()
	layout_changed.emit()


func _setup_theme() -> void:
	# Press Start 2P pre-rendered as an 8 px bitmap font. Only whole-number scaling
	# is allowed, so every letter pixel stays a perfect square.
	var font: FontFile = load("res://assets/fonts/press_start_8.fnt")
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	ui_font = font

	# DS-style menus: navy panels with light-blue borders.
	var theme := Theme.new()
	theme.default_font = ui_font
	theme.default_font_size = 16
	theme.set_stylebox("normal", "Button", _box(Color(0.12, 0.17, 0.36), Color(0.55, 0.8, 1.0)))
	theme.set_stylebox("hover", "Button", _box(Color(0.2, 0.28, 0.52), Color(0.75, 0.9, 1.0)))
	theme.set_stylebox("pressed", "Button", _box(Color(0.55, 0.8, 1.0), Color.WHITE))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_pressed_color", "Button", Color(0.05, 0.08, 0.2))
	theme.set_stylebox("panel", "PanelContainer", _box(Color(0.04, 0.07, 0.18, 0.94), Color(0.9, 0.95, 1.0), 6, 10))
	ui_theme = theme


static func _box(bg: Color, border: Color, radius := 4, margin := 6) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	sb.anti_aliasing = false
	return sb


# ---------------------------------------------------------------- Grand Prix

func start_cup(class_index: int, cup_index: int) -> void:
	cc = class_index
	cup = cup_index
	race_no = 0
	points.clear()
	for r in RACERS:
		points[r.name] = 0
	last_race.clear()
	get_tree().change_scene_to_file(RACE_SCENE)


func character(char_name: String) -> Dictionary:
	for r in RACERS:
		if r.name == char_name:
			return r
	return {}


func current_track_index() -> int:
	return TrackData.CUPS[cup].tracks[race_no]


func is_last_race() -> bool:
	return race_no >= TrackData.CUPS[cup].tracks.size() - 1


func add_race_result(order: Array) -> void:
	## order = racer names from 1st to last. Adds points for this race.
	last_race = order.duplicate()
	for i in order.size():
		points[order[i]] = points.get(order[i], 0) + POINTS[i]


func standings() -> Array:
	## Racer names sorted by points; ties go to whoever placed higher in the last race.
	var names := points.keys()
	names.sort_custom(func(a, b):
		if points[a] != points[b]:
			return points[a] > points[b]
		return last_race.find(a) < last_race.find(b))
	return names


func next_race() -> void:
	race_no += 1
	get_tree().change_scene_to_file(RACE_SCENE)


func to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func finish_cup(place: int) -> Array[String]:
	## Saves the cup result and returns messages for anything newly unlocked.
	var before := _unlock_snapshot()
	var key := "%d:%d" % [cc, cup]
	if best_places.get(key, 99) > place:
		best_places[key] = place
		save_settings()
	var news: Array[String] = []
	var after := _unlock_snapshot()
	for k in after:
		if after[k] and not before[k]:
			news.append(k)
	return news


func best_place(class_index: int, cup_index: int) -> int:
	return best_places.get("%d:%d" % [class_index, cup_index], 0)


func is_unlocked(class_index: int, cup_index: int) -> bool:
	## Cup 2 needs a top-3 finish in Cup 1 at the same class. A class needs top-3
	## finishes in both cups of the class below it.
	if class_index > 0:
		for c in TrackData.CUPS.size():
			var p := best_place(class_index - 1, c)
			if p == 0 or p > 3:
				return false
	if cup_index > 0:
		var p := best_place(class_index, cup_index - 1)
		if p == 0 or p > 3:
			return false
	return true


func _unlock_snapshot() -> Dictionary:
	var out := {}
	for k in TrackData.CLASSES.size():
		for c in TrackData.CUPS.size():
			out["%s %s" % [TrackData.CLASSES[k].name, TrackData.CUPS[c].name]] = is_unlocked(k, c)
	return out


# ---------------------------------------------------------------- screens

func use_two_screens() -> bool:
	## DS two-screen layout on near-square displays (the Fold's 8:7 inner screen),
	## one screen on wide ones (the 21:9 cover screen), unless the player chose.
	var win := get_tree().root.size
	var aspect := float(win.x) / maxf(win.y, 1.0)
	return layout == "ds" or (layout == "auto" and aspect < ScreenLayout.DS_MAX_ASPECT)


# ---------------------------------------------------------------- saving

func best_lap_for(track_name: String) -> float:
	return best_laps.get(track_name, 0.0)


func record_lap(track_name: String, lap: float) -> bool:
	## Returns true if this is a new best lap for the track.
	var old: float = best_laps.get(track_name, 0.0)
	if old == 0.0 or lap < old:
		best_laps[track_name] = lap
		save_settings()
		return true
	return false


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_on", music_on)
	cfg.set_value("audio", "sfx_on", sfx_on)
	cfg.set_value("display", "layout", layout)
	cfg.set_value("player", "character", player_char)
	cfg.set_value("display", "ds_controls", ds_controls)
	cfg.set_value("records", "best_laps", best_laps)
	cfg.set_value("progress", "best_places", best_places)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_on = cfg.get_value("audio", "music_on", true)
	sfx_on = cfg.get_value("audio", "sfx_on", true)
	layout = cfg.get_value("display", "layout", "auto")
	player_char = cfg.get_value("player", "character", "RUBY")
	if character(player_char).is_empty():
		player_char = "RUBY"
	ds_controls = cfg.get_value("display", "ds_controls", true)
	best_laps = cfg.get_value("records", "best_laps", {})
	best_places = cfg.get_value("progress", "best_places", {})


# ---------------------------------------------------------------- controls

func _setup_input() -> void:
	# Keyboard + gamepad bindings. Touch buttons press these same actions.
	_bind("accelerate", [KEY_UP, KEY_W], [JOY_BUTTON_A])
	_bind("brake", [KEY_DOWN, KEY_S], [JOY_BUTTON_X])
	_bind("steer_left", [KEY_LEFT, KEY_A], [JOY_BUTTON_DPAD_LEFT])
	_bind("steer_right", [KEY_RIGHT, KEY_D], [JOY_BUTTON_DPAD_RIGHT])
	_bind("drift", [KEY_SPACE, KEY_SHIFT], [JOY_BUTTON_RIGHT_SHOULDER])
	_bind("pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])
	_bind("toggle_music", [KEY_M], [])
	for pair in [["steer_left", -1.0], ["steer_right", 1.0]]:
		var ev := InputEventJoypadMotion.new()
		ev.axis = JOY_AXIS_LEFT_X
		ev.axis_value = pair[1]
		InputMap.action_add_event(pair[0], ev)


func _bind(action: String, keys: Array, buttons: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, 0.2)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
	for b in buttons:
		var ev := InputEventJoypadButton.new()
		ev.button_index = b
		InputMap.action_add_event(action, ev)


static func format_time(t: float) -> String:
	var minutes := int(t / 60.0)
	var seconds := fmod(t, 60.0)
	return "%d:%05.2f" % [minutes, seconds]
