class_name Track
extends Node3D
## Builds the test track entirely in code: road, grass, barriers, start line and trees.
## Textures are tiny generated images drawn with sharp pixels for the DS look,
## so the track adds almost nothing to the APK size.
##
## To change the layout, edit CONTROL_POINTS (x, z in metres before SCALE).
## The road is a smooth closed curve through them, driven in list order.

const CONTROL_POINTS := [
	Vector2(0, 0), Vector2(60, 0), Vector2(110, 10), Vector2(130, 50),
	Vector2(110, 90), Vector2(70, 95), Vector2(50, 70), Vector2(20, 70),
	Vector2(0, 100), Vector2(-40, 110), Vector2(-80, 90), Vector2(-90, 50),
	Vector2(-70, 15), Vector2(-40, 0),
]
const SCALE := 1.6
const STEPS_PER_POINT := 16
const ROAD_HALF_WIDTH := 6.0
const WALL_OFFSET := 10.0      # barriers sit this far from the centre line
const WALL_HEIGHT := 1.0

var points: PackedVector2Array    # sampled centre line
var tangents: PackedVector2Array
var length := 0.0


func _ready() -> void:
	_sample_centre_line()
	_build_ground()
	_build_road()
	_build_walls()
	_build_start_line()
	_build_trees()


# ---------------------------------------------------------------- queries

func count() -> int:
	return points.size()


func start_transform() -> Transform3D:
	## Grid spot just behind the line, facing along the track.
	var p := points[0] - tangents[0] * 6.0
	var t := tangents[0]
	var facing := Basis(Vector3.UP, atan2(-t.x, -t.y))
	return Transform3D(facing, Vector3(p.x, 0.0, p.y))


func locate(pos: Vector3, hint := -1) -> Dictionary:
	## Nearest centre-line sample to pos. Pass the last index as hint to search
	## only nearby samples (cheap); -1 searches the whole track.
	var p := Vector2(pos.x, pos.z)
	var n := points.size()
	var best := 0
	var best_d := INF
	var from := 0
	var to := n
	if hint >= 0:
		from = hint - 12
		to = hint + 13
	for k in range(from, to):
		var i := posmod(k, n)
		var d := p.distance_squared_to(points[i])
		if d < best_d:
			best_d = d
			best = i
	return {"index": best, "distance": sqrt(best_d), "tangent": tangents[best]}


# ---------------------------------------------------------------- building

func _sample_centre_line() -> void:
	# Closed Catmull-Rom spline through the control points.
	var cps := []
	for c in CONTROL_POINTS:
		cps.append(c * SCALE)
	var n := cps.size()
	points = PackedVector2Array()
	for i in n:
		var p0: Vector2 = cps[posmod(i - 1, n)]
		var p1: Vector2 = cps[i]
		var p2: Vector2 = cps[(i + 1) % n]
		var p3: Vector2 = cps[(i + 2) % n]
		for k in STEPS_PER_POINT:
			var t := float(k) / STEPS_PER_POINT
			var t2 := t * t
			var t3 := t2 * t
			points.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t
					+ (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2
					+ (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	var m := points.size()
	tangents = PackedVector2Array()
	tangents.resize(m)
	length = 0.0
	for i in m:
		tangents[i] = (points[(i + 1) % m] - points[posmod(i - 1, m)]).normalized()
		length += points[i].distance_to(points[(i + 1) % m])


func _side(i: int) -> Vector2:
	# Unit vector pointing to the left of the driving direction.
	var t := tangents[i]
	return Vector2(t.y, -t.x)


func _build_road() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var m := points.size()
	var v := 0.0
	for i in m:
		var j := (i + 1) % m
		var seg := points[i].distance_to(points[j])
		var a_l := points[i] + _side(i) * ROAD_HALF_WIDTH
		var a_r := points[i] - _side(i) * ROAD_HALF_WIDTH
		var b_l := points[j] + _side(j) * ROAD_HALF_WIDTH
		var b_r := points[j] - _side(j) * ROAD_HALF_WIDTH
		var v2 := v + seg / 6.0
		_quad(st, _v3(a_l, 0.02), _v3(a_r, 0.02), _v3(b_r, 0.02), _v3(b_l, 0.02),
				Vector2(0, v), Vector2(1, v), Vector2(1, v2), Vector2(0, v2))
		v = v2
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _material(_road_texture())
	add_child(mi)


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(700, 700)
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	var mat := _material(_grass_texture())
	mat.uv1_scale = Vector3(120, 120, 1)
	mi.material_override = mat
	mi.position = Vector3(30, 0, 80)
	add_child(mi)


func _build_walls() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := PackedVector3Array()
	var m := points.size()
	for side: float in [1.0, -1.0]:
		var v := 0.0
		for i in m:
			var j := (i + 1) % m
			var a := points[i] + _side(i) * WALL_OFFSET * side
			var b := points[j] + _side(j) * WALL_OFFSET * side
			var v2 := v + a.distance_to(b) / 4.0
			var p0 := _v3(a, 0.0)
			var p1 := _v3(b, 0.0)
			var p2 := _v3(b, WALL_HEIGHT)
			var p3 := _v3(a, WALL_HEIGHT)
			_quad(st, p0, p1, p2, p3, Vector2(v, 1), Vector2(v2, 1), Vector2(v2, 0), Vector2(v, 0))
			faces.append_array([p0, p1, p2, p0, p2, p3])
			v = v2
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := _material(_barrier_texture())
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # same brightness on both sides
	mi.material_override = mat
	add_child(mi)

	var shape := ConcavePolygonShape3D.new()
	shape.backface_collision = true
	shape.set_faces(faces)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	col.shape = shape
	body.add_child(col)
	add_child(body)


func _build_start_line() -> void:
	var t := tangents[0]
	var yaw := atan2(-t.x, -t.y)
	var line := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(ROAD_HALF_WIDTH * 2.0, 2.0)
	line.mesh = plane
	var mat := _material(_checker_texture())
	mat.uv1_scale = Vector3(6, 1, 1)
	line.material_override = mat
	line.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(points[0].x, 0.03, points[0].y))
	add_child(line)

	# Simple gantry over the line: two posts and a banner.
	var arch := Node3D.new()
	arch.transform = line.transform
	add_child(arch)
	var post_mat := _flat(Color(0.85, 0.85, 0.9))
	for x in [-ROAD_HALF_WIDTH - 1.0, ROAD_HALF_WIDTH + 1.0]:
		_box(arch, Vector3(0.6, 5.0, 0.6), Vector3(x, 2.5, 0), post_mat)
	var banner := _box(arch, Vector3(ROAD_HALF_WIDTH * 2.0 + 2.6, 1.2, 0.3), Vector3(0, 5.2, 0), null)
	var banner_mat := _material(_checker_texture())
	banner_mat.uv1_scale = Vector3(8, 1, 1)
	banner.material_override = banner_mat


func _build_trees() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42  # same trees every time
	var spots: Array[Vector2] = []
	var tries := 0
	while spots.size() < 90 and tries < 2000:
		tries += 1
		var p := Vector2(rng.randf_range(-260, 320), rng.randf_range(-200, 360))
		if locate(Vector3(p.x, 0, p.y)).distance > WALL_OFFSET + 5.0:
			spots.append(p)

	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.35
	trunk.bottom_radius = 0.45
	trunk.height = 2.0
	trunk.radial_segments = 6
	trunk.material = _flat(Color(0.45, 0.28, 0.15))
	var crown := CylinderMesh.new()
	crown.top_radius = 0.0
	crown.bottom_radius = 2.2
	crown.height = 5.0
	crown.radial_segments = 6
	crown.material = _flat(Color(0.15, 0.5, 0.2))

	for pair in [[trunk, 1.0], [crown, 4.5]]:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = pair[0]
		mm.instance_count = spots.size()
		for i in spots.size():
			var s := 0.8 + 0.5 * fmod(spots[i].x * 0.37 + spots[i].y * 0.11, 1.0)
			var xf := Transform3D(Basis().scaled(Vector3(s, s, s)),
					Vector3(spots[i].x, pair[1] * s, spots[i].y))
			mm.set_instance_transform(i, xf)
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		add_child(mmi)


# ---------------------------------------------------------------- helpers

func _v3(p: Vector2, y: float) -> Vector3:
	return Vector3(p.x, y, p.y)


func _quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3,
		ua: Vector2, ub: Vector2, uc: Vector2, ud: Vector2) -> void:
	for pair in [[a, ua], [c, uc], [b, ub], [a, ua], [d, ud], [c, uc]]:
		st.set_uv(pair[1])
		st.add_vertex(pair[0])


func _box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos
	if mat:
		mi.material_override = mat
	parent.add_child(mi)
	return mi


func _material(tex: Texture2D) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	return mat


func _flat(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	return mat


# Tiny procedural textures (32x32 or smaller).

func _road_texture() -> Texture2D:
	var img := Image.create(32, 32, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for y in 32:
		for x in 32:
			var g := 0.36 + rng.randf() * 0.06
			var c := Color(g, g, g + 0.02)
			if x <= 1 or x >= 30:  # red/white kerbs
				c = Color(0.85, 0.15, 0.15) if y < 16 else Color(0.95, 0.95, 0.95)
			elif (x == 15 or x == 16) and y < 12:  # centre dashes
				c = Color(0.95, 0.95, 0.8)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _grass_texture() -> Texture2D:
	var img := Image.create(16, 16, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	for y in 16:
		for x in 16:
			var k := rng.randf()
			img.set_pixel(x, y, Color(0.22, 0.55, 0.2) if k > 0.3 else Color(0.27, 0.62, 0.24))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _barrier_texture() -> Texture2D:
	var img := Image.create(16, 8, true, Image.FORMAT_RGB8)
	for y in 8:
		for x in 16:
			var c := Color(0.9, 0.2, 0.15) if x < 8 else Color(0.95, 0.95, 0.95)
			if y == 0 or y == 7:
				c = Color(0.3, 0.3, 0.35)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _checker_texture() -> Texture2D:
	var img := Image.create(4, 4, true, Image.FORMAT_RGB8)
	for y in 4:
		for x in 4:
			img.set_pixel(x, y, Color.WHITE if (x / 2 + y / 2) % 2 == 0 else Color(0.08, 0.08, 0.08))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
