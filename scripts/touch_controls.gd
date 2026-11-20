class_name TouchControls
extends Control
## On-screen buttons for the phone. Each finger is tracked separately, so you can
## steer with the left thumb while the right thumb slides between GAS and DRIFT.
## DRIFT also accelerates, so the right thumb never has to press two buttons at once.

# name -> [actions pressed, label, radius, colour, label size]
const BUTTONS := {
	"left": [["steer_left"], "<", 40.0, Color(1, 1, 1, 0.25), 16],
	"right": [["steer_right"], ">", 40.0, Color(1, 1, 1, 0.25), 16],
	"gas": [["accelerate"], "GAS", 42.0, Color(0.3, 1, 0.4, 0.3), 16],
	"drift": [["accelerate", "drift"], "DRIFT", 36.0, Color(1, 0.6, 0.2, 0.3), 8],
	"brake": [["brake"], "BRAKE", 28.0, Color(1, 0.3, 0.3, 0.3), 8],
}

var _fingers := {}      # finger index -> button name ("" if on nothing)
var _pressed := {}      # action -> true, for actions currently held by touch


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	resized.connect(queue_redraw)


func _centres() -> Dictionary:
	var s := size
	return {
		"left": Vector2(56, s.y - 56),
		"right": Vector2(150, s.y - 56),
		"gas": Vector2(s.x - 56, s.y - 56),
		"drift": Vector2(s.x - 56, s.y - 150),
		"brake": Vector2(s.x - 146, s.y - 40),
	}


func _button_at(pos: Vector2) -> String:
	var centres := _centres()
	for key in BUTTONS:
		# Slightly generous hit area so thumbs don't slip off.
		if pos.distance_to(centres[key]) <= BUTTONS[key][2] * 1.2:
			return key
	return ""


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	# Convert to this control's own coordinates (it may sit on the bottom screen).
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		event = make_input_local(event)
	if event is InputEventScreenTouch:
		if event.pressed:
			_fingers[event.index] = _button_at(event.position)
		else:
			_fingers.erase(event.index)
		_sync()
	elif event is InputEventScreenDrag and _fingers.has(event.index):
		var b := _button_at(event.position)
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
		if b != "":
			for action in BUTTONS[b][0]:
				want[action] = true
	for action in _pressed.keys():
		if not want.has(action):
			Input.action_release(action)
	for action in want:
		if not _pressed.has(action):
			Input.action_press(action)
	_pressed = want
	queue_redraw()


func _draw() -> void:
	var centres := _centres()
	var held := {}
	for b in _fingers.values():
		held[b] = true
	var font := Game.ui_font
	for key in BUTTONS:
		var c: Vector2 = centres[key]
		var r: float = BUTTONS[key][2]
		var col: Color = BUTTONS[key][3]
		if held.has(key):
			col.a = 0.6
		draw_circle(c, r, col)
		draw_arc(c, r, 0, TAU, 32, Color(1, 1, 1, 0.5), 2.0)
		var text: String = BUTTONS[key][1]
		if text == "<" or text == ">":  # draw steering arrows as solid triangles
			var d := -1.0 if text == "<" else 1.0
			draw_colored_polygon(PackedVector2Array([
				c + Vector2(14 * d, 0), c + Vector2(-10 * d, -14), c + Vector2(-10 * d, 14)]),
				Color(1, 1, 1, 0.8))
			continue
		var fs: int = BUTTONS[key][4]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(font, (c + Vector2(-w / 2.0, fs / 2.0)).round(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
