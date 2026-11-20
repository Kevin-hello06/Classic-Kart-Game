class_name Kart
extends CharacterBody3D
## Arcade kart handling: accelerate, brake/reverse, steer, and drift for a mini-turbo.
##
## Drifting: hold Drift while turning above walking pace. Keep holding and sparks
## turn blue, then orange. Let go for a boost (short for blue, longer for orange).
## The handling numbers below are the ones to tweak for "feel".

signal bumped

const MAX_SPEED := 26.0         # m/s on tarmac (about 94 km/h)
const OFFROAD_SPEED := 11.0     # top speed on grass
const BOOST_SPEED := 34.0
const ACCEL := 15.0
const BRAKE := 30.0
const REVERSE_SPEED := 8.0
const COAST_DRAG := 5.0
const TURN_RATE := 2.1          # rad/s at full lock and speed
const DRIFT_TURN := 1.3         # base turn rate while drifting
const DRIFT_MIN_SPEED := 10.0
const CHARGE_BLUE := 0.8        # seconds of drifting for a small boost
const CHARGE_ORANGE := 1.8      # seconds for a big boost

var controls_enabled := false
var speed := 0.0
var heading := 0.0
var off_road := false
var drift_dir := 0              # -1 right, 0 none, 1 left
var drift_charge := 0.0
var boost_time := 0.0
var steer_input := 0.0

var _model: Node3D
var _body: Node3D
var _front_wheels: Array[Node3D] = []
var _wheels: Array[Node3D] = []
var _sparks: Array[MeshInstance3D] = []
var _flame: MeshInstance3D
var _engine: AudioStreamPlayer
var _hop := 0.0
var _spark_mat := StandardMaterial3D.new()


func _ready() -> void:
	motion_mode = CharacterBody3D.MOTION_MODE_FLOATING  # flat track, no gravity needed
	heading = rotation.y
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.4, 0.8, 2.0)
	col.shape = box
	col.position.y = 0.5
	add_child(col)
	_build_model()

	_engine = AudioStreamPlayer.new()
	var loop: AudioStreamOggVorbis = load("res://assets/audio/engine_loop.ogg")
	loop.loop = true
	_engine.stream = loop
	_engine.bus = "SFX"
	_engine.volume_db = -14.0
	add_child(_engine)
	_engine.play()


func forward() -> Vector3:
	return Vector3(-sin(heading), 0.0, -cos(heading))


func _physics_process(delta: float) -> void:
	var throttle := 0.0
	var steer := 0.0
	var drift_held := false
	if controls_enabled:
		throttle = Input.get_action_strength("accelerate") - Input.get_action_strength("brake")
		steer = Input.get_axis("steer_right", "steer_left")
		drift_held = Input.is_action_pressed("drift")
	steer_input = steer

	_update_speed(throttle, delta)
	_update_steering(steer, drift_held, delta)

	rotation.y = heading
	velocity = forward() * speed
	move_and_slide()
	_handle_collisions()
	position.y = 0.0

	_update_visuals(delta)
	_engine.pitch_scale = 0.6 + clampf(absf(speed) / MAX_SPEED, 0.0, 1.4) * 0.9


func _update_speed(throttle: float, delta: float) -> void:
	if boost_time > 0.0:
		boost_time -= delta
		speed = move_toward(speed, BOOST_SPEED, 60.0 * delta)
		return

	if throttle > 0.0:
		speed += ACCEL * throttle * delta
	elif throttle < 0.0:
		if speed > 0.0:
			speed -= BRAKE * -throttle * delta
		else:
			speed = maxf(speed - ACCEL * 0.6 * delta, -REVERSE_SPEED)
	else:
		speed = move_toward(speed, 0.0, COAST_DRAG * delta)

	var top := OFFROAD_SPEED if off_road else MAX_SPEED
	if speed > top:
		# Bleed off speed gradually, so running wide onto grass isn't a brick wall.
		speed = move_toward(speed, top, 25.0 * delta)


func _update_steering(steer: float, drift_held: bool, delta: float) -> void:
	# Start a drift: Drift pressed while steering at speed.
	if drift_dir == 0 and drift_held and absf(steer) > 0.3 and speed > DRIFT_MIN_SPEED:
		drift_dir = 1 if steer > 0.0 else -1
		drift_charge = 0.0
		_hop = 0.25

	if drift_dir != 0:
		if not drift_held or speed < DRIFT_MIN_SPEED * 0.8:
			_release_drift()
		else:
			# Steering into the drift tightens it, steering out widens it.
			var turn := DRIFT_TURN + 0.6 * steer * drift_dir
			heading += drift_dir * turn * delta
			drift_charge += delta * (1.3 if steer * drift_dir > 0.3 else 1.0)
			return

	# Normal grip steering. Needs some speed to turn; reversed when backing up.
	var grip := clampf(absf(speed) / 8.0, 0.0, 1.0)
	if speed > MAX_SPEED * 0.8:
		grip *= 0.85  # a touch less twitchy at top speed
	heading += steer * TURN_RATE * grip * signf(speed) * delta


func _release_drift() -> void:
	if drift_charge >= CHARGE_ORANGE:
		_boost(1.2)
	elif drift_charge >= CHARGE_BLUE:
		_boost(0.6)
	drift_dir = 0
	drift_charge = 0.0


func _boost(seconds: float) -> void:
	boost_time = maxf(boost_time, seconds)
	Game.play_sfx("boost", -4.0)


func start_boost(seconds: float) -> void:
	## Used by the start line: a well-timed launch, or for testing.
	_boost(seconds)


func _handle_collisions() -> void:
	for i in get_slide_collision_count():
		var hit := get_slide_collision(i)
		var impact := -forward().dot(hit.get_normal()) * signf(speed)
		if impact > 0.25:
			speed *= 1.0 - impact * 0.7
			drift_dir = 0
			drift_charge = 0.0
			if impact > 0.5:
				bumped.emit()
			break


# ---------------------------------------------------------------- looks

func _update_visuals(delta: float) -> void:
	# Body swings out during a drift, and leans into turns.
	var slide := drift_dir * 0.45
	_body.rotation.y = lerp_angle(_body.rotation.y, slide, 10.0 * delta)
	_body.rotation.z = lerpf(_body.rotation.z, -steer_input * 0.06 * clampf(speed / MAX_SPEED, 0, 1), 8.0 * delta)
	_hop = maxf(_hop - delta, 0.0)
	_body.position.y = sin(_hop / 0.25 * PI) * 0.35 if _hop > 0.0 else 0.0

	for w in _wheels:
		w.rotation.x -= speed * delta / 0.35
	for w in _front_wheels:
		w.rotation.y = steer_input * 0.4

	var level := 0
	if drift_dir != 0:
		level = 2 if drift_charge >= CHARGE_ORANGE else (1 if drift_charge >= CHARGE_BLUE else 0)
	var flicker := Engine.get_physics_frames() % 4 < 2
	for s in _sparks:
		s.visible = drift_dir != 0 and flicker
	_spark_mat.albedo_color = [Color(1, 1, 0.8), Color(0.3, 0.6, 1.0), Color(1.0, 0.55, 0.1)][level]

	_flame.visible = boost_time > 0.0
	if _flame.visible:
		_flame.scale = Vector3.ONE * (0.8 + 0.4 * float(flicker))


func _build_model() -> void:
	_model = Node3D.new()
	add_child(_model)
	_body = Node3D.new()
	_model.add_child(_body)

	var red := _flat(Color(0.9, 0.2, 0.2))
	var dark := _flat(Color(0.15, 0.15, 0.18))
	var yellow := _flat(Color(1.0, 0.85, 0.2))
	var skin := _flat(Color(0.95, 0.75, 0.6))

	_part(_body, _box_mesh(Vector3(1.3, 0.35, 1.9)), Vector3(0, 0.45, 0), red)       # chassis
	_part(_body, _box_mesh(Vector3(1.0, 0.25, 0.5)), Vector3(0, 0.45, -1.1), red)    # nose
	_part(_body, _box_mesh(Vector3(1.4, 0.2, 0.3)), Vector3(0, 0.45, -1.4), dark)    # bumper
	_part(_body, _box_mesh(Vector3(0.8, 0.5, 0.15)), Vector3(0, 0.85, 0.55), dark)   # seat back
	_part(_body, _box_mesh(Vector3(0.6, 0.55, 0.5)), Vector3(0, 0.9, 0.2), yellow)   # driver
	var head := SphereMesh.new()
	head.radius = 0.32
	head.height = 0.64
	head.radial_segments = 8
	head.rings = 4
	_part(_body, head, Vector3(0, 1.45, 0.2), skin)
	var helmet := SphereMesh.new()
	helmet.radius = 0.36
	helmet.height = 0.5
	helmet.radial_segments = 8
	helmet.rings = 4
	helmet.is_hemisphere = true
	_part(_body, helmet, Vector3(0, 1.5, 0.2), yellow)

	var wheel := CylinderMesh.new()
	wheel.top_radius = 0.35
	wheel.bottom_radius = 0.35
	wheel.height = 0.3
	wheel.radial_segments = 8
	for pos in [Vector3(-0.75, 0.35, -0.75), Vector3(0.75, 0.35, -0.75),
			Vector3(-0.75, 0.35, 0.75), Vector3(0.75, 0.35, 0.75)]:
		var pivot := Node3D.new()  # pivot steers; the mesh inside rolls
		pivot.position = pos
		_body.add_child(pivot)
		var roller := Node3D.new()
		pivot.add_child(roller)
		var mi := _part(roller, wheel, Vector3.ZERO, dark)
		mi.rotation.z = PI / 2
		_wheels.append(roller)
		if pos.z < 0.0:
			_front_wheels.append(pivot)

	_spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for x in [-0.75, 0.75]:
		var s := _part(_body, _box_mesh(Vector3(0.25, 0.25, 0.25)), Vector3(x, 0.15, 1.15), _spark_mat)
		s.visible = false
		_sparks.append(s)

	var cone := CylinderMesh.new()
	cone.top_radius = 0.25
	cone.bottom_radius = 0.0
	cone.height = 1.0
	cone.radial_segments = 6
	var flame_mat := _flat(Color(1.0, 0.6, 0.1))
	flame_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_flame = _part(_body, cone, Vector3(0, 0.45, 1.4), flame_mat)
	_flame.rotation.x = -PI / 2
	_flame.visible = false


func _box_mesh(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


func _part(parent: Node3D, mesh: Mesh, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi


func _flat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	return mat
