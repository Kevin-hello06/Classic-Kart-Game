class_name TouchControls
extends Control
## On-screen controls for the phone. Each finger is tracked separately, so you can
## steer with the left thumb while the right thumb works the buttons, and you can
## slide a thumb from one button to another without lifting it.
##
## Three arrangements:
##  - DS style (default, both layouts): D-pad to steer, A = gas, B = brake,
##    R = drift (R also keeps the gas on). X and Y are spare, for items later.
##    On the cover screen it is drawn see-through over the race.
##  - Round, roomy (bottom screen, CONTROLS: ROUND in the pause menu).
##  - Round, compact (over the race when using a single screen).
## Move or resize things in _centres(), _ds_layout() and ROOMY_RADIUS.

# Round buttons: name -> [actions pressed, label, radius, colour, label size]
const BUTTONS := {
	"left": [["steer_left"], "<", 40.0, Color(1, 1, 1, 0.25), 16],
	"right": [["steer_right"], ">", 40.0, Color(1, 1, 1, 0.25), 16],
	"gas": [["accelerate"], "GAS", 42.0, Color(0.3, 1, 0.4, 0.3), 16],
	"drift": [["accelerate", "drift"], "DRIFT", 36.0, Color(1, 0.6, 0.2, 0.3), 8],
	"brake": [["brake"], "BRAKE", 28.0, Color(1, 0.3, 0.3, 0.3), 8],
}
# Bigger round buttons for the DS bottom screen.
const ROOMY_RADIUS := {"left": 52.0, "right": 52.0, "gas": 36.0, "drift": 36.0, "brake": 36.0}

# DS-style controls: name -> actions pressed.
const DS_ACTIONS := {
	"dleft": ["steer_left"], "dright": ["steer_right"],
	"a": ["accelerate"], "b": ["brake"], "r": ["accelerate", "drift"],
	"x": [], "y": [],
}
const DPAD_REACH := 56.0     # centre to end of each D-pad arm
const DPAD_ARM := 38.0       # arm thickness
const FACE_R := 22.0         # A/B/X/Y button radius
const FACE_GAP := 38.0       # diamond centre to each face button
const HOLE_FROM_RIGHT := 30.0  # Fold 7 inner camera, from the right edge (game px)
const DS_EDGE := 74.0  # Fold: gap from each side to the D-pad / A button (game px)
const DS_LIFT := 76.0  # Fold: how far the buttons are raised from their low spot
const PAD_DARK := Color(0.16, 0.18, 0.24, 0.95)
const PAD_EDGE := Color(0.55, 0.62, 0.75)
const FACE := Color(0.82, 0.84, 0.9, 0.95)
const PRESSED := Color(1.0, 0.85, 0.3)

var roomy := false:
	set(v):
		roomy = v
		queue_redraw()
var ds_style := false:
	set(v):
		ds_style = v
		queue_redraw()

var _fingers := {}      # finger index -> control name ("" if on nothing)
var _pressed := {}      # action -> true, for actions currently held by touch


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	resized.connect(queue_redraw)


# ---------------------------------------------------------------- layouts

func _radius(key: String) -> float:
	return ROOMY_RADIUS[key] if roomy else BUTTONS[key][2]


func _centres() -> Dictionary:
	var s := size
	if roomy:
		# Steering on the left. On the right, a triangle tucked into the corner:
		# GAS in the corner with DRIFT beside it (slide your thumb left to drift)
		# and BRAKE above, between them. The right-middle edge is left empty
		# because the Fold's inner camera hole sits there on this screen.
		return {
			"left": Vector2(72, s.y - 80),
			"right": Vector2(196, s.y - 80),
			"gas": Vector2(s.x - 52, s.y - 52),
			"drift": Vector2(s.x - 140, s.y - 52),
			"brake": Vector2(s.x - 96, s.y - 124),
		}
	return {
		"left": Vector2(56, s.y - 56),
		"right": Vector2(150, s.y - 56),
		"gas": Vector2(s.x - 56, s.y - 56),
		"drift": Vector2(s.x - 56, s.y - 150),
		"brake": Vector2(s.x - 146, s.y - 40),
	}


func _ds_layout() -> Dictionary:
	## D-pad on the left, A/B/X/Y diamond on the right with the R shoulder above it.
	## Fold bottom screen: both raised (DS_LIFT) and set the same distance in from
	## each side (DS_EDGE = left edge to D-pad = A to right edge). The diamond sits far
	## enough in that A stays clear of the Fold's inner camera hole (middle of the
	## right edge, about HOLE_FROM_RIGHT in). One screen: low, near the edges, as before.
	var s := size
	var face: Vector2
	var dpad: Vector2
	if roomy:
		face = Vector2(s.x - DS_EDGE - (FACE_R + 2.0) - FACE_GAP, s.y - 80.0 - DS_LIFT)
		dpad = Vector2(DS_EDGE + DPAD_REACH + 2.0, s.y - 86.0 - DS_LIFT)
	else:
		face = Vector2(s.x - 96.0, s.y - 80.0)
		dpad = Vector2(84.0, s.y - 86.0)
	return {
		"dpad": dpad,
		"face": face,
		"a": face + Vector2(FACE_GAP, 0),
		"b": face + Vector2(0, FACE_GAP),
		"x": face + Vector2(0, -FACE_GAP),
		"y": face + Vector2(-FACE_GAP, 0),
		"r": Rect2(face.x - 50, face.y - 100, 80, 32),
	}


# ---------------------------------------------------------------- hit testing

func _control_at(pos: Vector2) -> String:
	if ds_style:
		var lay := _ds_layout()
		var d: Vector2 = pos - lay.dpad
		# Generous D-pad: anywhere in a circle around it, decided by left/right of centre.
		if d.length() <= DPAD_REACH * 1.35 and absf(d.x) > 8.0:
			return "dleft" if d.x < 0.0 else "dright"
		var r_rect: Rect2 = lay.r
		if r_rect.grow(8).has_point(pos):
			return "r"
		var best := ""
		var best_d := FACE_R * 1.45
		for k in ["a", "b", "x", "y"]:
			var dist := pos.distance_to(lay[k])
			if dist < best_d:
				best_d = dist
				best = k
		return best
	var centres := _centres()
	for key in BUTTONS:
		# Slightly generous hit area so thumbs don't slip off.
		if pos.distance_to(centres[key]) <= _radius(key) * 1.2:
			return key
	return ""


func _actions(key: String) -> Array:
	if key == "":
		return []
	return DS_ACTIONS[key] if ds_style else BUTTONS[key][0]


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# Convert to this control's own coordinates (it may sit on the bottom screen).
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		event = make_input_local(event)
	if event is InputEventScreenTouch:
		if event.pressed:
			_fingers[event.index] = _control_at(event.position)
		else:
			_fingers.erase(event.index)
		_sync()
	elif event is InputEventScreenDrag and _fingers.has(event.index):
		var b := _control_at(event.position)
		if b != _fingers[event.index]:
			_fingers[event.index] = b
			_sync()


func _notification(what: int) -> void:
	# Let go of everything if the app loses focus mid-press.
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		_fingers.clear()
		_sync()


func _sync() -> void:
	var want := {}
	for b in _fingers.values():
		for action in _actions(b):
			want[action] = true
	for action in _pressed.keys():
		if not want.has(action):
			Input.action_release(action)
	for action in want:
		if not _pressed.has(action):
			Input.action_press(action)
	_pressed = want
	queue_redraw()


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	var held := {}
	for b in _fingers.values():
		held[b] = true
	if ds_style:
		_draw_ds(held)
	else:
		_draw_round(held)


func _draw_ds(held: Dictionary) -> void:
	var lay := _ds_layout()
	var f := Game.ui_font
	var c: Vector2 = lay.dpad

	# D-pad: a cross with an arrow on each arm; the pressed arm lights up.
	var h := Rect2(c - Vector2(DPAD_REACH, DPAD_ARM / 2.0), Vector2(DPAD_REACH * 2.0, DPAD_ARM))
	var v := Rect2(c - Vector2(DPAD_ARM / 2.0, DPAD_REACH), Vector2(DPAD_ARM, DPAD_REACH * 2.0))
	draw_rect(h.grow(2), PAD_EDGE)
	draw_rect(v.grow(2), PAD_EDGE)
	draw_rect(h, PAD_DARK)
	draw_rect(v, PAD_DARK)
	var lit := Color(PRESSED, 0.5)
	if held.has("dleft"):
		draw_rect(Rect2(h.position, Vector2(DPAD_REACH - DPAD_ARM / 2.0, DPAD_ARM)), lit)
	if held.has("dright"):
		draw_rect(Rect2(c + Vector2(DPAD_ARM / 2.0, -DPAD_ARM / 2.0),
				Vector2(DPAD_REACH - DPAD_ARM / 2.0, DPAD_ARM)), lit)
	draw_circle(c, 9.0, Color(0.1, 0.11, 0.15))
	for dir: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		var tip := c + dir * (DPAD_REACH - 8.0)
		var back := c + dir * (DPAD_REACH - 22.0)
		var side := Vector2(dir.y, -dir.x) * 9.0
		var steer := dir.y == 0.0
		draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]),
				Color(0.85, 0.88, 0.95) if steer else Color(0.4, 0.43, 0.5))

	# A/B/X/Y diamond. X and Y are spare for now (items later), so drawn dimmed.
	for k: String in ["a", "b", "x", "y"]:
		var p: Vector2 = lay[k]
		var spare := k == "x" or k == "y"
		var fill := PRESSED if held.has(k) else FACE
		if spare:
			fill = Color(0.45, 0.48, 0.56, 0.5)
		draw_circle(p, FACE_R + 2.0, PAD_EDGE)
		draw_circle(p, FACE_R, fill)
		var letter := k.to_upper()
		var w := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
		draw_string(f, (p + Vector2(-w / 2.0, 8)).round(), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
				Color(0.25, 0.27, 0.33) if spare else Color(0.1, 0.12, 0.2))
	# Small captions so new players know what A and B do.
	_caption(f, lay.a + Vector2(0, FACE_R + 12), "GAS")
	_caption(f, lay.b + Vector2(-FACE_R - 26, 4), "BRAKE")

	# R shoulder button (drift).
	var r: Rect2 = lay.r
	draw_rect(r.grow(2), PAD_EDGE)
	draw_rect(r, PRESSED if held.has("r") else PAD_DARK)
	var col := Color(0.1, 0.12, 0.2) if held.has("r") else Color.WHITE
	draw_string(f, r.position + Vector2(8, 24), "R", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, col)
	draw_string(f, r.position + Vector2(32, 20), "DRIFT", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)


func _caption(f: Font, centre: Vector2, text: String) -> void:
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x
	draw_string(f, (centre - Vector2(w / 2.0, 0)).round(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 8,
			Color(0.75, 0.82, 0.95))


func _draw_round(held: Dictionary) -> void:
	var centres := _centres()
	var font := Game.ui_font
	for key in BUTTONS:
		var c: Vector2 = centres[key]
		var r := _radius(key)
		var col: Color = BUTTONS[key][3]
		if held.has(key):
			col.a = 0.6
		draw_circle(c, r, col)
		draw_arc(c, r, 0, TAU, 32, Color(1, 1, 1, 0.5), 2.0)
		var text: String = BUTTONS[key][1]
		if text == "<" or text == ">":  # draw steering arrows as solid triangles
			var d := -1.0 if text == "<" else 1.0
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(r * 0.35 * d, 0), c + Vector2(-r * 0.25 * d, -r * 0.35),
				c + Vector2(-r * 0.25 * d, r * 0.35)]),
				Color(1, 1, 1, 0.8))
			continue
		var fs: int = BUTTONS[key][4]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, (c + Vector2(-w / 2.0, fs / 2.0)).round(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
