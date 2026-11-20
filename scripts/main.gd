extends Node3D
## Sets up the race and runs it: countdown, laps, checkpoints, finish.
##
## Laps only count if you pass the three checkpoints (quarter, half and
## three-quarter way round) in order, so cutting back across the line doesn't work.

const LAPS := 3
const CHECKPOINTS := 4   # the line plus three sectors

enum State { COUNTDOWN, RACING, FINISHED }

var state := State.COUNTDOWN
var track: Track
var kart: Kart
var camera: ChaseCamera
var hud: Hud
var pause_menu: PauseMenu
var screens: ScreenLayout
var lap_times: Array[float] = []

var lap := 1
var race_time := 0.0
var lap_time := 0.0
var best_lap := 0.0
var countdown := 3.5
var _last_count := -1
var _track_index := 0
var _next_checkpoint := 1
var _finish_wait := 0.0
var _wrong_way_time := 0.0


func _ready() -> void:
	_build_environment()

	track = Track.new()
	add_child(track)

	kart = Kart.new()
	kart.transform = track.start_transform()
	add_child(kart)
	kart.bumped.connect(func(): Game.play_sfx("bump", -6.0))
	_track_index = track.locate(kart.position).index

	camera = ChaseCamera.new()
	camera.target = kart

	# DS-style screens: race on top, map and touch buttons on the bottom.
	var ui := CanvasLayer.new()
	add_child(ui)
	hud = Hud.new()
	var touch: TouchControls = TouchControls.new() if DisplayServer.is_touchscreen_available() else null
	pause_menu = PauseMenu.new()
	pause_menu.restart_requested.connect(restart)
	screens = ScreenLayout.new()
	ui.add_child(screens)
	screens.setup(camera, track, kart, hud, touch, pause_menu)

	best_lap = Game.best_lap
	hud.set_lap(lap, LAPS)
	hud.set_times(0.0, 0.0, best_lap)
	hud.set_speed(0.0)


func _physics_process(delta: float) -> void:
	match state:
		State.COUNTDOWN:
			_run_countdown(delta)
		State.RACING:
			race_time += delta
			lap_time += delta
			_track_progress()
		State.FINISHED:
			_finish_wait -= delta
			_track_progress()

	hud.set_times(race_time, lap_time, best_lap)
	hud.set_speed(kart.speed)
	var b := screens.bottom
	b.lap = lap
	b.laps = LAPS
	b.lap_time = lap_time
	b.best_lap = best_lap
	b.lap_times = lap_times


func _unhandled_input(event: InputEvent) -> void:
	if state == State.FINISHED and _finish_wait <= 0.0:
		var tapped: bool = event is InputEventScreenTouch and event.pressed
		if tapped or event.is_action_pressed("ui_accept"):
			restart()


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _run_countdown(delta: float) -> void:
	countdown -= delta
	var n := ceili(countdown)
	if n != _last_count and n <= 3:
		_last_count = n
		if n > 0:
			hud.show_message(str(n))
			Game.play_sfx("beep")
		else:
			hud.show_message("GO!")
			Game.play_sfx("go")
			Game.start_music()
			kart.controls_enabled = true
			state = State.RACING
			get_tree().create_timer(1.0).timeout.connect(_clear_go)


func _clear_go() -> void:
	if state == State.RACING:
		hud.show_message("")


func _track_progress() -> void:
	var info := track.locate(kart.position, _track_index)
	var index: int = info.index
	var n := track.count()

	kart.off_road = info.distance > Track.ROAD_HALF_WIDTH + 0.5

	# Checkpoints: sector k starts at k/4 of the way round.
	if _next_checkpoint < CHECKPOINTS and index >= n * _next_checkpoint / CHECKPOINTS \
			and index < n * (_next_checkpoint + 1) / CHECKPOINTS:
		_next_checkpoint += 1

	# Crossing the line forwards: index wraps from the end back to the start.
	var crossed := _track_index > n * 3 / 4 and index < n / 4
	_track_index = index
	if crossed and _next_checkpoint == CHECKPOINTS and state == State.RACING:
		_complete_lap()

	if state == State.RACING:
		_check_wrong_way(info.tangent)


func _complete_lap() -> void:
	_next_checkpoint = 1
	lap_times.append(lap_time)
	if best_lap == 0.0 or lap_time < best_lap:
		best_lap = lap_time
	if lap >= LAPS:
		_finish()
		return
	lap += 1
	lap_time = 0.0
	hud.set_lap(lap, LAPS)
	Game.play_sfx("lap")
	hud.show_message("FINAL LAP!" if lap == LAPS else "LAP %d" % lap)
	get_tree().create_timer(1.2).timeout.connect(_clear_go)


func _finish() -> void:
	state = State.FINISHED
	kart.controls_enabled = false
	_finish_wait = 1.5
	Game.play_sfx("finish")
	var record := Game.record_race(race_time, best_lap)
	var lines := ["TIME     " + Game.format_time(race_time),
			"BEST LAP " + Game.format_time(best_lap)]
	lines.append("NEW RECORD!" if record else "RECORD   " + Game.format_time(Game.best_race))
	lines.append("")
	lines.append("TAP TO RACE AGAIN" if DisplayServer.is_touchscreen_available() else "PRESS ENTER")
	hud.show_message("FINISH!", "\n".join(lines))


func _check_wrong_way(tangent: Vector2) -> void:
	var fwd := kart.forward()
	var going_back := Vector2(fwd.x, fwd.z).dot(tangent) < -0.5 and kart.speed > 4.0
	_wrong_way_time = _wrong_way_time + get_physics_process_delta_time() if going_back else 0.0
	if _wrong_way_time > 0.8:
		hud.show_message("WRONG WAY!")
	elif not going_back and hud.current_message() == "WRONG WAY!":
		hud.show_message("")


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.45, 0.7, 1.0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.75, 0.8)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.65, 0.8, 1.0)
	env.fog_density = 0.004
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = 0.9
	sun.shadow_enabled = false  # no shadows: cheaper, and closer to the DS look
	add_child(sun)
