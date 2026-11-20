class_name PauseMenu
extends Control
## Pause button (top-right) and the menu it opens: Resume, Music on/off,
## Sound on/off, Restart. Esc / P / Start also pause; M toggles music anytime.

signal restart_requested

var _button: Button
var _panel: PanelContainer
var _music_btn: Button
var _sfx_btn: Button
var _layout_btn: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS

	_button = Button.new()
	_button.text = "II"
	_button.focus_mode = Control.FOCUS_NONE
	_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_button.offset_left = -46
	_button.offset_right = -6
	_button.offset_top = 3
	_button.offset_bottom = 29
	_button.pressed.connect(toggle)
	add_child(_button)

	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_panel.visible = false
	add_child(_panel)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(240, 0)
	box.add_theme_constant_override("separation", 6)
	_panel.add_child(box)

	var title := Label.new()
	title.text = "PAUSED"
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)

	_add(box, "RESUME", toggle)
	_music_btn = _add(box, "", _toggle_music)
	_sfx_btn = _add(box, "", _toggle_sfx)
	_layout_btn = _add(box, "", _cycle_layout)
	_add(box, "RESTART", _restart)
	_refresh()


func toggle() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	_panel.visible = paused
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("toggle_music"):
		_toggle_music()


func _refresh() -> void:
	_music_btn.text = "MUSIC: %s" % ("ON" if Game.music_on else "OFF")
	_sfx_btn.text = "SOUND: %s" % ("ON" if Game.sfx_on else "OFF")
	_layout_btn.text = "SCREENS: %s" % {"auto": "AUTO", "ds": "DS", "single": "ONE"}[Game.layout]


func _add(box: VBoxContainer, text: String, action: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 34)
	b.pressed.connect(action)
	box.add_child(b)
	return b


func _toggle_music() -> void:
	Game.set_music(not Game.music_on)
	_refresh()


func _toggle_sfx() -> void:
	Game.set_sfx(not Game.sfx_on)
	_refresh()


func _cycle_layout() -> void:
	Game.cycle_layout()
	_refresh()


func _restart() -> void:
	toggle()
	restart_requested.emit()
