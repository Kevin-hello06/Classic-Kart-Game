class_name ChaseCamera
extends Camera3D
## Smooth follow camera behind the kart. Widens a little during boosts.

const DISTANCE := 6.5
const HEIGHT := 2.8
const BASE_FOV := 65.0

var target: Kart


func _ready() -> void:
	fov = BASE_FOV
	far = 400.0
	snap()


func snap() -> void:
	if target:
		global_position = _desired()
		look_at(_look_point())


func _physics_process(delta: float) -> void:
	if not target:
		return
	global_position = global_position.lerp(_desired(), 1.0 - exp(-8.0 * delta))
	look_at(_look_point())
	var want_fov := BASE_FOV + (10.0 if target.boost_time > 0.0 else 0.0)
	fov = lerpf(fov, want_fov, 1.0 - exp(-5.0 * delta))


func _desired() -> Vector3:
	return target.global_position - target.forward() * DISTANCE + Vector3.UP * HEIGHT


func _look_point() -> Vector3:
	return target.global_position + target.forward() * 3.0 + Vector3.UP * 1.0
