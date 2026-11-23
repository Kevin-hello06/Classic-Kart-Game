class_name Track
extends Node3D
## Builds a track from its TrackData definition, entirely in code: sky and lighting,
## ground, road, barriers, start gantry and themed scenery. Textures are tiny
## generated pixel images, so tracks add almost nothing to the APK size.
## Set `def` before adding the node to the scene.

const ROAD_HALF_WIDTH := TrackData.ROAD_HALF_WIDTH   # 8 m wide road
const WALL_OFFSET := TrackData.WALL_OFFSET           # barriers sit this far from the centre line
const WALL_HEIGHT := 1.0

var def: Dictionary = TrackData.get_track(0)
var points: PackedVector2Array    # sampled centre line
var tangents: PackedVector2Array
var length := 0.0
var bounds := Rect2()


func _ready() -> void:
	_sample_centre_line()
	_build_environment()
	_build_ground()
	_build_road()
	_build_walls()
	_build_start_line()
	_build_scenery()


# ---------------------------------------------------------------- queries

func count() -> int:
	return points.size()


func grid_transform(slot: int) -> Transform3D:
	## Starting grid: two staggered columns behind the line, facing along the track.
	## Slot 0 is pole position.
	var row := slot / 2
	var col := slot % 2
	var back := 6.0 + row * 6.0 + col * 3.0
	# Walk back along the centre line, so a long grid follows any bend behind the line.
	var n := points.size()
	var i := 0
	var walked := 0.0
	while walked < back:
		var j := posmod(i - 1, n)
		walked += points[i].distance_to(points[j])
		i = j
	var t := tangents[i]
	var p := points[i] + _side(i) * (2.5 if col == 0 else -2.5)
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
	# Signed sideways offset: positive = left of the centre line.
	var lateral := (p - points[best]).dot(_side(best))
	return {"index": best, "distance": sqrt(best_d), "tangent": tangents[best], "lateral": lateral}


# ---------------------------------------------------------------- building

func _sample_centre_line() -> void:
	points = TrackData.sample(def)
	var m := points.size()
	tangents = PackedVector2Array()
	tangents.resize(m)
	length = 0.0
	bounds = Rect2(points[0], Vector2.ZERO)
	for i in m:
		tangents[i] = (points[(i + 1) % m] - points[posmod(i - 1, m)]).normalized()
		length += points[i].distance_to(points[(i + 1) % m])
		bounds = bounds.expand(points[i])


func _side(i: int) -> Vector2:
	# Unit vector pointing to the left of the driving direction.
	var t := tangents[i]
	return Vector2(t.y, -t.x)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = def.sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = def.ambient
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = def.fog
	env.fog_density = def.fog_density
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 30, 0)
	sun.light_energy = def.sun
	sun.shadow_enabled = false  # no shadows: cheaper, and closer to the DS look
	add_child(sun)


func _build_ground() -> void:
	# Ground around the track; on island tracks (beach, lava) it is ringed by
	# water or lava that stretches to the horizon.
	var island: bool = def.has("outer")
	var margin := WALL_OFFSET + (45.0 if island else 250.0)
	var area := bounds.grow(margin)
	var plane := PlaneMesh.new()
	plane.size = area.size
	var mi := MeshInstance3D.new()
	mi.mesh = plane
	var mat := _material(_ground_texture())
	mat.uv1_scale = Vector3(area.size.x / 6.0, area.size.y / 6.0, 1)
	mi.material_override = mat
	mi.position = Vector3(area.get_center().x, 0, area.get_center().y)
	add_child(mi)

	if island:
		var sea := PlaneMesh.new()
		sea.size = Vector2(2000, 2000)
		var smi := MeshInstance3D.new()
		smi.mesh = sea
		var smat := _flat(def.outer)
		smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smi.material_override = smat
		smi.position = Vector3(area.get_center().x, -0.3, area.get_center().y)
		add_child(smi)


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
	banner_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	banner.material_override = banner_mat


# ---------------------------------------------------------------- scenery

func _build_scenery() -> void:
	match def.scenery:
		"trees":
			_scatter(90, [[_cyl(0.35, 0.45, 2.0, Color(0.45, 0.28, 0.15)), Vector3(0, 1, 0)],
					[_cyl(0.0, 2.2, 5.0, Color(0.15, 0.5, 0.2)), Vector3(0, 4.5, 0)]])
		"cacti":
			var green := Color(0.3, 0.55, 0.25)
			_scatter(70, [[_cyl(0.45, 0.45, 4.0, green), Vector3(0, 2, 0)],
					[_boxm(Vector3(1.2, 0.4, 0.4), green), Vector3(0.6, 2.0, 0)],
					[_boxm(Vector3(0.4, 1.2, 0.4), green), Vector3(1.05, 2.5, 0)]])
			_blocks(14, Color(0.72, 0.42, 0.26), Vector2(18, 40), Vector2(12, 30), false)
		"pines":
			_scatter(110, [[_cyl(0.3, 0.4, 1.6, Color(0.4, 0.27, 0.18)), Vector3(0, 0.8, 0)],
					[_cyl(0.0, 2.0, 5.0, Color(0.12, 0.35, 0.28)), Vector3(0, 4.0, 0)],
					[_cyl(0.0, 1.0, 1.9, Color(0.95, 0.97, 1.0)), Vector3(0, 5.8, 0)]])
		"palms":
			_scatter(45, [[_cyl(0.22, 0.32, 6.0, Color(0.6, 0.45, 0.3)), Vector3(0, 3, 0)],
					[_cyl(3.0, 0.3, 0.8, Color(0.2, 0.6, 0.25)), Vector3(0, 6.3, 0)]], 25.0)
		"city":
			_lamps(Color(0.3, 1.0, 1.0), Color(1.0, 0.3, 0.9))
			_blocks(40, Color(0.16, 0.14, 0.3), Vector2(14, 28), Vector2(18, 60), true)
		"autumn":
			# Mixed forest: orange, red and gold crowns, each colour scattered separately.
			var crown_cols := [Color(0.9, 0.45, 0.1), Color(0.75, 0.15, 0.1), Color(0.95, 0.75, 0.15)]
			for k in crown_cols.size():
				_scatter(55, [[_cyl(0.35, 0.45, 2.0, Color(0.4, 0.26, 0.15)), Vector3(0, 1, 0)],
						[_boxm(Vector3(3.2, 3.0, 3.2), crown_cols[k]), Vector3(0, 3.6, 0)]], 45.0, k)
		"moon":
			# Craters (dark low discs), white domes, beacon lights, and a planet in the sky.
			_scatter(45, [[_cyl(4.0, 5.0, 0.4, Color(0.32, 0.32, 0.36)), Vector3(0, 0.1, 0)]], 1e9, 1)
			var dome := SphereMesh.new()
			dome.radius = 4.0
			dome.height = 4.0
			dome.is_hemisphere = true
			dome.radial_segments = 10
			dome.rings = 3
			dome.material = _flat(Color(0.9, 0.92, 0.96))
			_scatter(10, [[dome, Vector3.ZERO]], 60.0, 2)
			_lamps(Color(0.3, 0.6, 1.0), Color(0.3, 0.6, 1.0))
			var planet := SphereMesh.new()
			planet.radius = 70.0
			planet.height = 140.0
			planet.radial_segments = 16
			planet.rings = 8
			var pmat := _flat(Color(0.25, 0.55, 0.95))
			pmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			planet.material = pmat
			var c := bounds.get_center()
			_multimesh(planet, [Transform3D(Basis(), Vector3(c.x + 250.0, 150.0, c.y - 420.0))])
		"mall":
			# Indoor shopping mall: lit shop fronts close to the track, pillars, planters,
			# and a fountain in the infield if there's room.
			var shop_cols := [Color(0.85, 0.3, 0.35), Color(0.25, 0.5, 0.85), Color(0.95, 0.7, 0.2), Color(0.4, 0.75, 0.45)]
			for k in shop_cols.size():
				_blocks(8, shop_cols[k], Vector2(10, 16), Vector2(7, 11), true, 22.0, k)
			_scatter(30, [[_cyl(0.8, 0.8, 12.0, Color(0.95, 0.94, 0.9)), Vector3(0, 6, 0)]], 14.0, 1)
			_scatter(30, [[_boxm(Vector3(1.6, 0.8, 1.6), Color(0.6, 0.45, 0.3)), Vector3(0, 0.4, 0)],
					[_cyl(0.0, 1.2, 2.4, Color(0.25, 0.6, 0.3)), Vector3(0, 2.0, 0)]], 10.0, 2)
			_fountain()
		"docks":
			# Stacked shipping containers in four colours, and dockside cranes.
			var box_cols := [Color(0.85, 0.25, 0.2), Color(0.2, 0.45, 0.8), Color(0.2, 0.6, 0.35), Color(0.95, 0.65, 0.15)]
			for k in box_cols.size():
				_scatter(14, [[_boxm(Vector3(6.0, 2.6, 2.4), box_cols[k]), Vector3(0, 1.3, 0)],
						[_boxm(Vector3(6.0, 2.6, 2.4), box_cols[(k + 1) % 4]), Vector3(0.3, 3.9, 0)]], 30.0, k)
			var crane := Color(0.95, 0.75, 0.15)
			_scatter(5, [[_boxm(Vector3(1.0, 22.0, 1.0), crane), Vector3(-4, 11, 0)],
					[_boxm(Vector3(1.0, 22.0, 1.0), crane), Vector3(4, 11, 0)],
					[_boxm(Vector3(26.0, 1.2, 1.2), crane), Vector3(4, 22, 0)]], 35.0, 9)
		"jungle":
			# Dense tall jungle trees and crumbling stone ruins.
			_scatter(130, [[_cyl(0.4, 0.6, 8.0, Color(0.35, 0.25, 0.15)), Vector3(0, 4, 0)],
					[_boxm(Vector3(5.0, 3.0, 5.0), Color(0.1, 0.4, 0.15)), Vector3(0, 8.5, 0)]], 1e9, 0)
			_scatter(30, [[_boxm(Vector3(1.6, 6.0, 1.6), Color(0.45, 0.48, 0.38)), Vector3(0, 3, 0)],
					[_boxm(Vector3(4.0, 1.2, 1.6), Color(0.4, 0.44, 0.34)), Vector3(1.2, 6.4, 0)]], 20.0, 1)
		"factory":
			# Pipes, machines, chimneys and warning lights.
			_scatter(25, [[_boxm(Vector3(14.0, 0.8, 0.8), Color(0.55, 0.58, 0.6)), Vector3(0, 3.5, 0)],
					[_boxm(Vector3(0.6, 3.5, 0.6), Color(0.4, 0.42, 0.45)), Vector3(-5, 1.75, 0)],
					[_boxm(Vector3(0.6, 3.5, 0.6), Color(0.4, 0.42, 0.45)), Vector3(5, 1.75, 0)]], 25.0, 0)
			_scatter(20, [[_boxm(Vector3(5.0, 3.5, 4.0), Color(0.3, 0.33, 0.36)), Vector3(0, 1.75, 0)],
					[_boxm(Vector3(1.5, 1.0, 1.5), Color(0.95, 0.6, 0.1)), Vector3(1, 4.0, 0)]], 30.0, 1)
			_scatter(8, [[_cyl(1.2, 1.5, 24.0, Color(0.45, 0.35, 0.3)), Vector3(0, 12, 0)]], 1e9, 2)
			_lamps(Color(1.0, 0.7, 0.1), Color(1.0, 0.7, 0.1))
		"ghost":
			# Dead trees, gravestones and orange lanterns in the fog.
			var bark := Color(0.12, 0.1, 0.12)
			_scatter(70, [[_cyl(0.2, 0.35, 6.0, bark), Vector3(0, 3, 0)],
					[_boxm(Vector3(2.6, 0.25, 0.25), bark), Vector3(0.9, 4.2, 0)],
					[_boxm(Vector3(0.25, 0.25, 2.0), bark), Vector3(0, 5.0, 0.6)]], 1e9, 0)
			_scatter(60, [[_boxm(Vector3(0.9, 1.3, 0.3), Color(0.5, 0.5, 0.55)), Vector3(0, 0.65, 0)]], 14.0, 1)
			_lamps(Color(1.0, 0.55, 0.15), Color(1.0, 0.55, 0.15))
		"clouds":
			# Garden hedges and flower beds on a sky island, with puffy clouds all around.
			_scatter(40, [[_boxm(Vector3(4.0, 1.4, 1.2), Color(0.2, 0.55, 0.25)), Vector3(0, 0.7, 0)],
					[_boxm(Vector3(3.6, 0.3, 0.9), Color(1.0, 0.55, 0.75)), Vector3(0, 1.5, 0)]], 25.0, 0)
			var puff := _sphere(6.0, Color.WHITE, true)
			_scatter(45, [[puff, Vector3(0, -1, 0)], [puff, Vector3(5, 1, 2)], [puff, Vector3(-4, 0, 3)]], 1e9, 1, 60.0)
		"crystals":
			# Glowing crystals in two colours, and dark rock pillars.
			for k in 2:
				var col := Color(0.3, 0.9, 1.0) if k == 0 else Color(0.95, 0.4, 1.0)
				var m := _cyl(0.0, 1.0, 5.0, col)
				(m.material as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
				_scatter(40, [[m, Vector3(0, 2.5, 0)], [m, Vector3(1.0, 1.5, 0.6)]], 25.0, k)
			_scatter(25, [[_boxm(Vector3(3.0, 16.0, 3.0), Color(0.18, 0.16, 0.22)), Vector3(0, 8, 0)]], 1e9, 3)
		"space":
			# Stars at all heights and two planets: the highway floats in space.
			var star := _boxm(Vector3(0.6, 0.6, 0.6), Color(1.0, 0.95, 0.7))
			(star.material as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			_scatter(80, [[star, Vector3(0, 8, 0)], [star, Vector3(9, 20, 4)], [star, Vector3(-7, 35, -6)]], 1e9, 0)
			var c := bounds.get_center()
			_multimesh(_sphere(60.0, Color(0.9, 0.5, 0.3), true), [Transform3D(Basis(), Vector3(c.x - 300, 80, c.y - 350))])
			_multimesh(_sphere(30.0, Color(0.4, 0.6, 1.0), true), [Transform3D(Basis(), Vector3(c.x + 280, 120, c.y + 300))])
			_lamps(Color(0.9, 0.5, 1.0), Color(0.4, 0.9, 1.0))
		"rocks":
			_scatter(60, [[_boxm(Vector3(3.0, 2.0, 2.6), Color(0.2, 0.15, 0.14)), Vector3(0, 0.8, 0)],
					[_boxm(Vector3(1.6, 1.4, 1.8), Color(0.28, 0.2, 0.17)), Vector3(1.2, 1.9, 0.4)]], 25.0)
			_lamps(Color(1.0, 0.55, 0.15), Color(1.0, 0.55, 0.15))


func _scatter(want: int, parts: Array, max_dist := 1e9, variant := 0, min_dist := 5.0) -> void:
	## Places `want` copies of a multi-part prop on the ground, clear of the barriers.
	## max_dist keeps props near the track (for island tracks).
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(def.name) + variant * 101  # same scenery every time
	var area := bounds.grow(WALL_OFFSET + 120.0)
	var xfs: Array[Transform3D] = []
	var tries := 0
	while xfs.size() < want and tries < 3000:
		tries += 1
		var p := Vector2(rng.randf_range(area.position.x, area.end.x),
				rng.randf_range(area.position.y, area.end.y))
		var d: float = locate(Vector3(p.x, 0, p.y)).distance
		if d > WALL_OFFSET + min_dist and d < WALL_OFFSET + max_dist:
			var s := rng.randf_range(0.8, 1.3)
			var b := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s))
			xfs.append(Transform3D(b, Vector3(p.x, 0, p.y)))
	for part in parts:
		var offset: Vector3 = part[1]
		var list: Array[Transform3D] = []
		for xf in xfs:
			list.append(xf * Transform3D(Basis(), offset))
		_multimesh(part[0], list)


func _blocks(want: int, color: Color, width: Vector2, height: Vector2, glow: bool,
		near := 1e9, variant := 0) -> void:
	## Big background boxes: canyon mesas, city buildings or mall shops. `near` keeps
	## them within that distance of the barriers.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(def.name) + 7 + variant * 13
	var area := bounds.grow(WALL_OFFSET + 160.0)
	var list: Array[Transform3D] = []
	var tries := 0
	while list.size() < want and tries < 3000:
		tries += 1
		var p := Vector2(rng.randf_range(area.position.x, area.end.x),
				rng.randf_range(area.position.y, area.end.y))
		var w := rng.randf_range(width.x, width.y)
		var dist: float = locate(Vector3(p.x, 0, p.y)).distance
		if dist > WALL_OFFSET + w * 0.75 + 4.0 and dist < WALL_OFFSET + w * 0.75 + near:
			var h := rng.randf_range(height.x, height.y)
			var b := Basis(Vector3.UP, rng.randf() * 0.3).scaled(Vector3(w, h, w * rng.randf_range(0.7, 1.2)))
			list.append(Transform3D(b, Vector3(p.x, h / 2.0, p.y)))
	var mesh := _boxm(Vector3.ONE, color)
	if glow:
		mesh.material = _building_material(color)
	_multimesh(mesh, list)


func _lamps(left: Color, right: Color) -> void:
	## Glowing lamp posts along both sides of the track, just outside the barriers.
	var poles: Array[Transform3D] = []
	var heads := [[], []]
	for i in range(0, points.size(), 10):
		for k in 2:
			var side := 1.0 if k == 0 else -1.0
			var p := points[i] + _side(i) * (WALL_OFFSET + 1.5) * side
			poles.append(Transform3D(Basis(), Vector3(p.x, 2.5, p.y)))
			heads[k].append(Transform3D(Basis(), Vector3(p.x, 5.1, p.y)))
	_multimesh(_cyl(0.15, 0.15, 5.0, Color(0.35, 0.35, 0.4)), poles)
	for k in 2:
		var head := _boxm(Vector3(0.9, 0.5, 0.9), left if k == 0 else right)
		(head.material as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var typed: Array[Transform3D] = []
		typed.assign(heads[k])
		_multimesh(head, typed)


func _fountain() -> void:
	# A fountain in the middle of the infield, if the middle is clear of the track.
	var c := bounds.get_center()
	if locate(Vector3(c.x, 0, c.y)).distance < WALL_OFFSET + 10.0:
		return
	var base := MeshInstance3D.new()
	base.mesh = _cyl(7.0, 7.5, 1.0, Color(0.85, 0.85, 0.88))
	base.position = Vector3(c.x, 0.5, c.y)
	add_child(base)
	var water := MeshInstance3D.new()
	var wm := _cyl(6.4, 6.4, 0.2, Color(0.35, 0.7, 1.0))
	(wm.material as StandardMaterial3D).shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	water.mesh = wm
	water.position = Vector3(c.x, 1.05, c.y)
	add_child(water)
	var spout := MeshInstance3D.new()
	spout.mesh = _cyl(0.4, 1.0, 5.0, Color(0.6, 0.85, 1.0))
	spout.position = Vector3(c.x, 3.0, c.y)
	add_child(spout)


func _sphere(r: float, color: Color, unshaded := false) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 10
	m.rings = 5
	var mat := _flat(color)
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.material = mat
	return m


func _multimesh(mesh: Mesh, xfs: Array[Transform3D]) -> void:
	if xfs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = xfs.size()
	for i in xfs.size():
		mm.set_instance_transform(i, xfs[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	add_child(mmi)


func _cyl(top: float, bottom: float, h: float, color: Color) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 6
	m.rings = 1
	m.material = _flat(color)
	return m


func _boxm(size: Vector3, color: Color) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	m.material = _flat(color)
	return m


func _building_material(color: Color) -> StandardMaterial3D:
	# Dark building with a grid of lit windows, as a tiny generated texture.
	var img := Image.create(8, 8, false, Image.FORMAT_RGB8)
	for y in 8:
		for x in 8:
			var lit := x % 2 == 1 and y % 2 == 1 and (x * 3 + y * 5) % 7 != 0
			img.set_pixel(x, y, Color(1.0, 0.9, 0.5) if lit else color)
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.uv1_scale = Vector3(3, 6, 1)
	return mat


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


# Tiny procedural textures (32x32 or smaller), coloured by the track's theme.

func _road_texture() -> Texture2D:
	var img := Image.create(32, 32, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var base: Color = def.road
	for y in 32:
		for x in 32:
			var c := base.lightened(rng.randf() * 0.08)
			if x <= 1 or x >= 30:  # kerbs
				c = def.kerb[0] if y < 16 else def.kerb[1]
			elif (x == 15 or x == 16) and y < 12:  # centre dashes
				c = Color(0.95, 0.95, 0.8)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _ground_texture() -> Texture2D:
	var img := Image.create(16, 16, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	for y in 16:
		for x in 16:
			img.set_pixel(x, y, def.ground[0] if rng.randf() > 0.3 else def.ground[1])
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _barrier_texture() -> Texture2D:
	var img := Image.create(16, 8, true, Image.FORMAT_RGB8)
	for y in 8:
		for x in 16:
			var c: Color = def.barrier[0] if x < 8 else def.barrier[1]
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
