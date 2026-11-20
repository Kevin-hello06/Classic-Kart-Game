class_name ScreenLayout
extends Control
## Arranges the game like a DS: the race on the top screen and the map,
## lap times and touch buttons on the bottom screen, with a dark gap between
## them where the Fold's hinge is.
##
## Layout "auto" picks two screens on near-square displays (the Fold's inner
## screen, a laptop window) and one screen on wide ones (the cover screen).
## The pause menu can force either.

const SCREEN_HEIGHT := 384   # each screen is 384 pixels tall internally, like 2x a DS screen
const HINGE := 8
const DS_MAX_ASPECT := 1.6   # window wider than this -> single screen

var top := Control.new()
var bottom: BottomScreen
var hinge := ColorRect.new()
var view := SubViewport.new()
var hud: Hud
var touch: TouchControls
var pause_menu: PauseMenu
var is_ds := false

var _container := SubViewportContainer.new()


func setup(camera: Camera3D, track: Track, kart: Kart, new_hud: Hud,
		new_touch: TouchControls, new_pause: PauseMenu) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = Game.ui_theme  # DS-style font, buttons and panels for everything below

	# Top screen: the 3D view renders into a SubViewport sized to the top screen,
	# so nothing is wasted drawing 3D behind the bottom screen.
	add_child(top)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.stretch = true
	_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	top.add_child(_container)
	view.handle_input_locally = false
	_container.add_child(view)
	view.add_child(camera)
	camera.make_current()

	hud = new_hud
	top.add_child(hud)

	hinge.color = Color(0.03, 0.03, 0.05)
	add_child(hinge)

	bottom = BottomScreen.new()
	bottom.track = track
	bottom.kart = kart
	add_child(bottom)

	touch = new_touch
	pause_menu = new_pause

	get_tree().root.size_changed.connect(apply_layout)
	Game.layout_changed.connect(apply_layout)
	apply_layout()


func apply_layout() -> void:
	var win := get_tree().root.size
	var aspect := float(win.x) / maxf(win.y, 1.0)
	var want_ds := Game.layout == "ds" or (Game.layout == "auto" and aspect < DS_MAX_ASPECT)
	var base := Vector2i(512, SCREEN_HEIGHT * 2 + HINGE) if want_ds else Vector2i(512, SCREEN_HEIGHT)
	if get_tree().root.content_scale_size != base:
		get_tree().root.content_scale_size = base
	is_ds = want_ds
	_place.call_deferred()


func _place() -> void:
	var s := get_viewport_rect().size
	if is_ds:
		var h := floorf((s.y - HINGE) / 2.0)
		_set_rect(top, Rect2(0, 0, s.x, h))
		_set_rect(hinge, Rect2(0, h, s.x, s.y - 2.0 * h))
		_set_rect(bottom, Rect2(0, s.y - h, s.x, h))
	else:
		_set_rect(top, Rect2(Vector2.ZERO, s))
	hinge.visible = is_ds
	bottom.visible = is_ds
	hud.set_compact(is_ds)

	# Touch buttons and the pause menu live on the bottom screen in DS mode.
	var host: Control = bottom if is_ds else top
	for c in [touch, pause_menu]:
		if c == null:
			continue
		if c.get_parent() != host:
			if c.get_parent():
				c.get_parent().remove_child(c)
			host.add_child(c)
		host.move_child(c, -1)  # keeps pause menu last, on top
		c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if pause_menu:
		host.move_child(pause_menu, -1)


func _set_rect(c: Control, r: Rect2) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	c.position = r.position
	c.size = r.size
