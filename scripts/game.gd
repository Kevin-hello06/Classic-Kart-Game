extends Node
## Global helper (autoload "Game"): settings, music, sound effects and controls.
## Settings are saved to user://settings.cfg so they stick between launches.

const SETTINGS_PATH := "user://settings.cfg"
const LAYOUTS := ["auto", "ds", "single"]

signal layout_changed

var music_on := true
var sfx_on := true
var best_race := 0.0   # best 3-lap total in seconds, 0 = none yet
var best_lap := 0.0
var layout := "auto"   # auto: two screens on the near-square inner screen, one on the cover screen

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


# ---------------------------------------------------------------- saving

func record_race(total: float, lap: float) -> bool:
	## Returns true if this race set a new record.
	var new_record := best_race == 0.0 or total < best_race
	if new_record:
		best_race = total
	if best_lap == 0.0 or lap < best_lap:
		best_lap = lap
	save_settings()
	return new_record


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_on", music_on)
	cfg.set_value("audio", "sfx_on", sfx_on)
	cfg.set_value("display", "layout", layout)
	cfg.set_value("records", "best_race", best_race)
	cfg.set_value("records", "best_lap", best_lap)
	cfg.save(SETTINGS_PATH)


func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return
	music_on = cfg.get_value("audio", "music_on", true)
	sfx_on = cfg.get_value("audio", "sfx_on", true)
	layout = cfg.get_value("display", "layout", "auto")
	best_race = cfg.get_value("records", "best_race", 0.0)
	best_lap = cfg.get_value("records", "best_lap", 0.0)


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
