class_name CpuDriver
extends Node
## Drives a kart around the track: aims at a point a little way ahead on its own
## lane, and lifts off or brakes when a corner is coming. Add as a child of a Kart.
##
## skill scales the kart's top speed (1.0 = the character's full top speed).
## catch_up is set each frame by the race: just above 1 when far behind the player,
## just below 1 when far ahead, so races stay close without the CPU cheating.

var kart: Kart
var track: Track
var skill := 0.95
var lane := 0.0          # preferred metres left (+) or right (-) of the centre line
var catch_up := 1.0
var base_speed := Kart.MAX_SPEED
var drift_keen := 0.5    # chance of drifting a long corner (better drivers drift more)

var _index := -1
var _t := 0.0
var _phase := 0.0


var _drift_ok := false
var _last_corner := 0


func _ready() -> void:
	kart = get_parent() as Kart
	_phase = randf() * TAU
	drift_keen = clampf((skill - 0.88) * 7.0, 0.2, 0.95)


func _physics_process(delta: float) -> void:
	if not kart or not track or not kart.controls_enabled:
		return
	_t += delta
	kart.top_speed = base_speed * skill * catch_up

	var info := track.locate(kart.position, _index)
	_index = info.index
	var n := track.count()

	# Follow the road: match its direction a little way ahead, and steer back
	# towards this driver's lane (which drifts slowly so the pack spreads out).
	var want_lane := lane + sin(_t * 0.35 + _phase) * 0.5
	kart.cpu_steer = path_steer(track, kart, _index, want_lane, info.lateral)

	_update_drift(n)
	var corner := corner_speed(track, _index, kart.speed, kart.turn_mult)
	if kart.speed < corner - 0.5:
		kart.cpu_throttle = 1.0
	elif kart.speed > corner + 1.0:
		kart.cpu_throttle = -0.6   # brake (about 18 m/s^2)
	else:
		kart.cpu_throttle = 0.3    # hold speed


static func path_steer(t: Track, k: Kart, index: int, want_lane: float, lateral: float) -> float:
	## Steering (-1 right .. 1 left) that follows the track centre line offset by want_lane.
	## Heading term: turn to match the road direction slightly ahead.
	## Lateral term: drift back onto the wanted line (gentler at speed).
	var n := t.count()
	var ahead: Vector2 = t.tangents[(index + 1 + int(absf(k.speed) * 0.06)) % n]
	var f := Vector2(k.forward().x, k.forward().z)
	if f.dot(ahead) < 0.0:
		# Facing backwards (after a crash): full lock round towards the road direction.
		return -1.0 if f.angle_to(ahead) > 0.0 else 1.0
	var heading_err := f.angle_to(ahead)          # > 0: road turns right of where we point
	var lane_err := lateral - want_lane           # > 0: we're left of the line
	var correction := atan(1.2 * lane_err / maxf(absf(k.speed), 4.0))
	return clampf(-(heading_err * 2.6) - correction * 1.6, -1.0, 1.0)


static func corner_speed(t: Track, index: int, speed: float, turn_mult := 1.0, brake := 14.0) -> float:
	## Fastest speed allowed right now: every corner in the next stretch has a safe
	## speed (a kart turns at most about 1.75 rad/s, so speed <= turn rate / curvature),
	## and from here we can still brake down to it in time:  v^2 <= v_corner^2 + 2*brake*d.
	var n := t.count()
	var seg := t.length / n
	var reach := 6 + int(absf(speed) * 0.7)
	var allowed := INF
	for k in range(1, reach):
		var a: Vector2 = t.tangents[(index + k) % n]
		var b: Vector2 = t.tangents[(index + k + 3) % n]
		var curvature := acos(clampf(a.dot(b), -1.0, 1.0)) / (3.0 * seg)
		if curvature > 0.002:
			var v_corner := 1.7 * turn_mult / curvature
			allowed = minf(allowed, sqrt(v_corner * v_corner + 2.0 * brake * k * seg))
	return allowed


func _update_drift(n: int) -> void:
	## Drift through long corners for mini-turbo boosts, like a player would.
	## turn_ahead > 0 means the track bends right over the next ~30 m.
	var turn_ahead := track.tangents[_index].angle_to(track.tangents[(_index + 8) % n])
	if kart.drift_dir == 0:
		# Only long corners that keep turning one way (hairpins, big sweepers) are worth
		# drifting; quick zig-zags are not. Decide once per corner whether to drift it.
		# The road must keep curving the same way for the next ~32 m (no straight in between).
		var long_corner := absf(turn_ahead) > 0.9
		for k in range(0, 8, 2):
			var step := track.tangents[(_index + k) % n].angle_to(track.tangents[(_index + k + 2) % n])
			if absf(step) < 0.12 or signf(step) != signf(turn_ahead):
				long_corner = false
		var corner_id := 1 if long_corner else 0
		if corner_id != _last_corner:
			_last_corner = corner_id
			_drift_ok = corner_id == 1 and randf() < drift_keen
		kart.cpu_drift = _drift_ok and long_corner \
				and kart.speed > Kart.DRIFT_MIN_SPEED + 2.0 and absf(kart.cpu_steer) > 0.35
	else:
		# Keep drifting while the corner keeps turning the same way (drift_dir 1 = left).
		kart.cpu_drift = turn_ahead * -kart.drift_dir > 0.2
