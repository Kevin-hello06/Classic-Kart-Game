class_name Hud
extends Control
## Lap counter, timers, speed, and the big centre message (countdown, WRONG WAY, finish).

var _lap: Label
var _time: Label
var _best: Label
var _speed: Label
var _message: Label
var _sub: Label
var _sub_panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_lap = _label(16, Vector2(8, 8))
	_time = _label(8, Vector2(8, 30))
	_best = _label(8, Vector2(8, 44))
	_speed = _label(8, Vector2(8, 58))

	# Centre messages span the full width just above the middle of the screen.
	_message = _centre_label(32, -84)
	# Results panel (finish screen), growing downwards from just below the title.
	_sub_panel = PanelContainer.new()
	_sub_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_sub_panel.offset_top = -36
	_sub_panel.offset_bottom = -36
	_sub_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_sub_panel.grow_vertical = Control.GROW_DIRECTION_END
	_sub_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sub_panel.visible = false
	add_child(_sub_panel)
	_sub = _label(16, Vector2.ZERO)
	remove_child(_sub)
	_sub_panel.add_child(_sub)


func set_lap(lap: int, total: int) -> void:
	_lap.text = "LAP %d/%d" % [mini(lap, total), total]


func set_times(race: float, lap: float, best_lap: float) -> void:
	_time.text = "%s  LAP %s" % [Game.format_time(race), Game.format_time(lap)]
	_best.text = "BEST LAP %s" % Game.format_time(best_lap) if best_lap > 0.0 else ""


func set_speed(mps: float) -> void:
	_speed.text = "%d KM/H" % int(absf(mps) * 3.6)


func show_message(text: String, sub := "") -> void:
	_message.text = text
	_sub.text = sub
	_sub_panel.visible = sub != ""


func set_compact(on: bool) -> void:
	## In the two-screen layout, best lap and speed move to the bottom screen.
	_best.visible = not on
	_speed.visible = not on


func current_message() -> String:
	return _message.text


func _centre_label(size: int, top: float) -> Label:
	var l := _label(size, Vector2.ZERO)
	l.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	l.offset_top = top
	l.offset_bottom = top + size * 1.4
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


func _label(size: int, pos: Vector2) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font = Game.ui_font
	ls.font_size = size
	ls.line_spacing = size / 2.0
	# Hard drop shadow, one font-pixel down and right (bitmap fonts have no outline).
	ls.shadow_size = 0
	ls.shadow_color = Color(0, 0, 0, 0.85)
	ls.shadow_offset = Vector2.ONE * (size / 8)
	l.label_settings = ls
	l.position = pos
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l
