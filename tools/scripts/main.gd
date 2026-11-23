extends Node3D
## One race of a Grand Prix: builds the track and ten karts (you + nine CPU racers),
## runs the countdown, tracks laps and positions for everyone, then shows the race
## results with points and, after the last race, the cup standings and unlocks.
##
## Laps only count if a kart passes the three checkpoints (quarter, half and
## three-quarter way round) in order, so cutting back across the line doesn't work.

const LAPS := 3
const CHECKPOINTS := 4   # the line plus three sectors

enum State { COUNTDOWN, RACING, FINISHED, RESULTS, STANDINGS }


class Racer:
	var name: String
	var kart: Kart
	var driver: CpuDriver
	var is_player := false
	var index := 0
	var next_cp := 1
	var lap := 1
	var lap_time := 0.0
	var lap_times: Array[float] = []
	var finished := false
	var finish_time := 0.0
	# Race time when this kart first reached each point of the race (one slot per
	# track sample per lap). Comparing two karts' times at the same point gives the gap.
	var pass_times := PackedFloat32Array()
	var last_mark := -1

	func mark(n: int, t: float) -> void:
		var p := int(progress(n))
		if p < 0 or pass_times.is_empty():
			return
		p = mini(p, pass_times.size() - 1)
		for q in range(last_mark + 1, p + 1):
			pass_times[q] = t
		last_mark = maxi(last_mark, p)

	func progress(n: int) -> float:
		## Distance round the race in track samples, for ranking.
		var i := float(index)
		if next_cp == 1 and index > n * 3 / 4:
			i -= n  # still behind the line before it first crosses it
		return (lap - 1) * n + i


var state := State.COUNTDOWN
var track: Track
var racers: Array[Racer] = []
var player: Racer
var kart: Kart              # the player's kart (used by the screens and tests)
var camera: ChaseCamera
var hud: Hud
var pause_menu: PauseMenu
var screens: ScreenLayout

var race_time := 0.0
var best_lap := 0.0
var countdown := 3.5
var final_order: Array = []
var _last_count := -1
var _wait := 0.0
var _wrong_way_time := 0.0


func _ready() -> void:
	if Game.points.is_empty():
		Game.points = {}
		for r in Game.RACERS:
			Game.points[r.name] = 0
	track = Track.new()
	track.def = TrackData.get_track(Game.current_track_index())
	add_child(track)
	_spawn_racers()

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
	screens.bottom.title = "%s  %d/%d" % [track.def.name, Game.race_no + 1, TrackData.CUPS[Game.cup].tracks.size()]
	for r in racers:
		if not r.is_player:
			screens.bottom.others.append(r.kart)

	best_lap = Game.best_lap_for(track.def.name)
	hud.kart = kart
	_update_hud()


func _spawn_racers() -> void:
	var cls: Dictionary = TrackData.CLASSES[Game.cc]
	# Grid: first race in roster order with you at the back; later races by the
	# current standings, leader on pole.
	var order: Array = []
	if Game.race_no == 0:
		for d in Game.RACERS:
			if d.name != Game.player_char:
				order.append(d.name)
		order.append(Game.player_char)
	else:
		order = Game.standings()

	for slot in order.size():
		var def := Game.character(order[slot])
		var r := Racer.new()
		r.name = def.name
		r.is_player = def.name == Game.player_char
		var k := Kart.new()
		k.apply_stats(def, cls.speed, cls.accel)
		k.is_cpu = not r.is_player
		k.transform = track.grid_transform(slot)
		add_child(k)
		r.kart = k
		r.index = track.locate(k.position).index
		r.pass_times.resize(track.count() * (LAPS + 1))
		r.pass_times.fill(-1.0)
		if r.is_player:
			player = r
			kart = k
			k.bumped.connect(func(): Game.play_sfx("bump", -6.0))
		else:
			# Rivals use their character stats too; skill scales their top speed.
			r.driver = _add_driver(k, def.skill + Game.CLASS_SKILL[Game.cc], def.lane, k.top_speed)
		racers.append(r)


func _add_driver(k: Kart, skill: float, lane: float, speed: float) -> CpuDriver:
	var d := CpuDriver.new()
	d.track = track
	d.skill = skill
	d.lane = lane
	d.base_speed = speed
	k.add_child(d)
	return d


func _physics_process(delta: float) -> void:
	if state == State.COUNTDOWN:
		_run_countdown(delta)
	else:
		race_time += delta
		_wait -= delta
		for r in racers:
			_update_racer(r, delta)
		_catch_up()
		if state == State.RACING:
			_check_wrong_way()
		elif state == State.FINISHED and _wait <= 0.0:
			_show_results()
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if _wait > 0.0 or (state != State.RESULTS and state != State.STANDINGS):
		return
	var tapped: bool = event is InputEventScreenTouch and event.pressed
	if not (tapped or event.is_action_pressed("ui_accept")):
		return
	if state == State.RESULTS:
		if Game.is_last_race():
			_show_standings()
		else:
			Game.next_race()
	else:
		Game.to_menu()


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


# ---------------------------------------------------------------- race flow

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
			for r in racers:
				r.kart.controls_enabled = true
			state = State.RACING
			get_tree().create_timer(1.0).timeout.connect(_clear_message)


func _clear_message() -> void:
	if state == State.RACING:
		hud.show_message("")


func _update_racer(r: Racer, delta: float) -> void:
	var info := track.locate(r.kart.position, r.index)
	var index: int = info.index
	var n := track.count()
	r.kart.off_road = info.distance > Track.ROAD_HALF_WIDTH + 0.5
	if r.finished:
		r.index = index
		return
	r.lap_time += delta

	# Checkpoints: sector k starts at k/4 of the way round.
	if r.next_cp < CHECKPOINTS and index >= n * r.next_cp / CHECKPOINTS \
			and index < n * (r.next_cp + 1) / CHECKPOINTS:
		r.next_cp += 1

	# Crossing the line forwards: index wraps from the end back to the start.
	var crossed := r.index > n * 3 / 4 and index < n / 4
	r.index = index
	if crossed and r.next_cp == CHECKPOINTS:
		_complete_lap(r)
	r.mark(n, race_time)


func _complete_lap(r: Racer) -> void:
	r.next_cp = 1
	r.lap_times.append(r.lap_time)
	if r.is_player:
		if Game.record_lap(track.def.name, r.lap_time) or best_lap == 0.0:
			best_lap = Game.best_lap_for(track.def.name)
	if r.lap >= LAPS:
		r.finished = true
		r.finish_time = race_time
		if r.is_player:
			_player_finished()
		return
	r.lap += 1
	r.lap_time = 0.0
	if r.is_player:
		Game.play_sfx("lap")
		hud.show_message("FINAL LAP!" if r.lap == LAPS else "LAP %d" % r.lap)
		get_tree().create_timer(1.2).timeout.connect(_clear_message)


func _player_finished() -> void:
	state = State.FINISHED
	_wait = 2.5
	Game.play_sfx("finish")
	# Hand your kart to a CPU driver for a victory lap.
	kart.is_cpu = true
	_add_driver(kart, 0.9, 0.0, kart.top_speed)
	# Final order: everyone already finished (by time), then the rest by distance.
	final_order = _ranking()
	var place := final_order.find(Game.player_char) + 1
	hud.show_message("FINISH!  " + _ordinal(place))


func _ranking() -> Array:
	var n := track.count()
	var list := racers.duplicate()
	list.sort_custom(func(a: Racer, b: Racer) -> bool:
		if a.finished != b.finished:
			return a.finished
		if a.finished:
			return a.finish_time < b.finish_time
		return a.progress(n) > b.progress(n))
	var names := []
	for r in list:
		names.append(r.name)
	return names


func _show_results() -> void:
	state = State.RESULTS
	_wait = 1.0
	Game.add_race_result(final_order)
	var lines: Array[String] = []
	for i in final_order.size():
		var r := _racer(final_order[i])
		# Karts still racing get an estimated time: your time plus how far behind you they are.
		var t := " " + Game.format_time(r.finish_time) if r.finished \
				else "~" + Game.format_time(player.finish_time + maxf(gap_between(player, r), 0.0))
		var mark := ">" if r.is_player else " "
		lines.append("%s%2d %-6s %s +%d" % [mark, i + 1, r.name, t, Game.POINTS[i]])
	lines.append("")
	lines.append("TAP FOR STANDINGS" if Game.is_last_race() else "TAP FOR NEXT RACE")
	hud.show_message("RACE %d RESULTS" % (Game.race_no + 1), "\n".join(lines))


func _show_standings() -> void:
	state = State.STANDINGS
	_wait = 1.0
	var table := Game.standings()
	var lines: Array[String] = []
	for i in table.size():
		var mark := ">" if table[i] == Game.player_char else " "
		lines.append("%s%2d %-6s %3d PTS" % [mark, i + 1, table[i], Game.points[table[i]]])
	var place := table.find(Game.player_char) + 1
	lines.append("")
	lines.append(["GOLD TROPHY!", "SILVER TROPHY!", "BRONZE TROPHY!"][place - 1] if place <= 3
			else "TOP 3 TO UNLOCK MORE")
	for unlocked in Game.finish_cup(place):
		lines.append("NEW: " + unlocked)
	lines.append("TAP FOR MENU")
	hud.show_message(TrackData.CUPS[Game.cup].name + "  " + _ordinal(place), "\n".join(lines))
	if place <= 3:
		Game.play_sfx("finish")


func _racer(racer_name: String) -> Racer:
	for r in racers:
		if r.name == racer_name:
			return r
	return null


func gap_between(front: Racer, back: Racer) -> float:
	## Seconds `back` is behind `front`: how long ago `front` was where `back` is now.
	## -1 if unknown (e.g. back is actually ahead).
	var p := int(back.progress(track.count()))
	if p < 0 or p >= front.pass_times.size() or front.pass_times[p] < 0.0:
		return -1.0
	return race_time - front.pass_times[p]


func _update_gaps(order: Array) -> void:
	var i := order.find(Game.player_char)
	var ahead := _racer(order[i - 1]) if i > 0 else null
	var behind := _racer(order[i + 1]) if i < order.size() - 1 else null
	hud.set_gaps(ahead.name if ahead else "", gap_between(ahead, player) if ahead else -1.0,
			behind.name if behind else "", gap_between(player, behind) if behind else -1.0)


func _catch_up() -> void:
	# CPU karts far ahead of you ease off a little; far behind push a little.
	var n := track.count()
	var metres := track.length / n
	for r in racers:
		if r.driver == null or r.is_player:
			continue
		if player.finished:
			r.driver.catch_up = 1.0
			continue
		var gap := (r.progress(n) - player.progress(n)) * metres
		r.driver.catch_up = clampf(1.0 - gap / 2500.0, 0.94, 1.06)


func _check_wrong_way() -> void:
	var info := track.locate(kart.position, player.index)
	var tangent: Vector2 = info.tangent
	var fwd := kart.forward()
	var going_back := Vector2(fwd.x, fwd.z).dot(tangent) < -0.5 and kart.speed > 4.0
	_wrong_way_time = _wrong_way_time + get_physics_process_delta_time() if going_back else 0.0
	if _wrong_way_time > 0.8:
		hud.show_message("WRONG WAY!")
	elif not going_back and hud.current_message() == "WRONG WAY!":
		hud.show_message("")


func _update_hud() -> void:
	var live := state != State.FINISHED and state < State.RESULTS
	var order := _ranking() if live else final_order
	hud.place = order.find(Game.player_char) + 1
	# Time gaps to the karts just ahead and behind, refreshed four times a second.
	if state == State.RACING and Engine.get_physics_frames() % 15 == 0:
		_update_gaps(order)
	elif not live:
		hud.set_gaps("", -1.0, "", -1.0)
	hud.racers = racers.size()
	hud.update_race(player.lap, LAPS, race_time, player.lap_time, player.lap_times, best_lap)


static func _ordinal(n: int) -> String:
	return str(n) + (["ST", "ND", "RD"][n - 1] if n >= 1 and n <= 3 else "TH")
