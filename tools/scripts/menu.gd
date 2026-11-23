extends Control
## Title menu, laid out like a DS game, in two pages:
##  1. Cup page. Top screen: the selected cup's tracks as maps and your best trophy.
##     Bottom screen: pick a speed class and a cup, then START. Locked choices say
##     what's needed (a top-3 finish in the cup, or both cups of the class, before it).
##  2. Driver page. Top screen: the chosen character's kart turning slowly, with its
##     stats. Bottom screen: the ten drivers to tap, then GO! (BACK returns).

const HINGE := ScreenLayout.HINGE
const BORDER := Color(0.55, 0.8, 1.0)
const DIM := Color(0.6, 0.7, 0.85)
const HIGHLIGHT := Color(1.0, 0.9, 0.3)
const TROPHY := [Color(1.0, 0.85, 0.25), Color(0.82, 0.86, 0.95), Color(0.85, 0.5, 0.25)]

var sel_class := 0
var sel_cup := 0
var sel_char := 0
var page := "cup"
var is_ds := false

var _top := Control.new()
var _bottom := Control.new()
var _hinge := ColorRect.new()
var _class_btns: Array[Button] = []
var _cup_btns: Array[Button] = []
var _start: Button
var _note: Label
var _maps := {}    # track index -> sampled centre line
var _bg: Texture2D
var _cup_box: VBoxContainer
var _char_box: VBoxContainer
var _char_btns: Array[Button] = []
var _go: Button
var _preview := SubViewportContainer.new()
var _preview_pivot := Node3D.new()
var _preview_kart: Kart


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = Game.ui_theme
	_bg = _pattern()
	for i in TrackData.TRACKS.size():
		_maps[i] = TrackData.sample(TrackData.TRACKS[i])

	add_child(_top)
	_top.draw.connect(_draw_top)
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hinge.color = Color(0.03, 0.03, 0.05)
	add_child(_hinge)
	add_child(_bottom)
	_bottom.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_bottom.draw.connect(_draw_bottom)
	_build_buttons()
	_build_char_page()
	_build_preview()
	for i in Game.RACERS.size():
		if Game.RACERS[i].name == Game.player_char:
			sel_char = i

	var music := MusicButton.new()
	music.position = Vector2(10, 40)
	_bottom.add_child(music)

	# Start on the newest unlocked class and cup.
	for k in TrackData.CLASSES.size():
		for c in TrackData.CUPS.size():
			if Game.is_unlocked(k, c):
				sel_class = k
				sel_cup = c
	_refresh()

	get_tree().root.size_changed.connect(_apply_layout)
	Game.layout_changed.connect(_apply_layout)
	_apply_layout()
	Game.start_music()


func _build_buttons() -> void:
	var box := _centre_box()
	_cup_box = box

	box.add_child(_row_label("SPEED CLASS"))
	var classes := HBoxContainer.new()
	classes.add_theme_constant_override("separation", 8)
	classes.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_child(classes)
	for k in TrackData.CLASSES.size():
		var b := _button(TrackData.CLASSES[k].name, Vector2(96, 34))
		b.pressed.connect(_pick_class.bind(k))
		classes.add_child(b)
		_class_btns.append(b)

	box.add_child(_row_label("CUP"))
	var cups := GridContainer.new()   # 2 x 2 grid of cups
	cups.columns = 2
	cups.add_theme_constant_override("h_separation", 8)
	cups.add_theme_constant_override("v_separation", 8)
	cups.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(cups)
	for c in TrackData.CUPS.size():
		var b := _button(TrackData.CUPS[c].name, Vector2(170, 32))
		b.pressed.connect(_pick_cup.bind(c))
		cups.add_child(b)
		_cup_btns.append(b)

	_start = _button("START", Vector2(160, 40))
	_start.toggle_mode = false
	_start.focus_mode = Control.FOCUS_ALL  # Enter / A on a gamepad starts the cup
	_start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_start.pressed.connect(_on_start)
	box.add_child(_start)

	_note = Label.new()
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.add_theme_font_size_override("font_size", 8)
	_note.add_theme_color_override("font_color", DIM)
	box.add_child(_note)


func _build_char_page() -> void:
	_char_box = _centre_box()
	_char_box.visible = false
	_char_box.add_child(_row_label("CHOOSE YOUR DRIVER"))
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 6)
	_char_box.add_child(grid)
	for i in Game.RACERS.size():
		var def: Dictionary = Game.RACERS[i]
		var b := _button(def.name, Vector2(80, 32))   # 5 across fits a phone-width panel
		b.add_theme_font_size_override("font_size", 8)
		b.icon = _swatch(def.body, def.suit)
		b.pressed.connect(_pick_char.bind(i))
		grid.add_child(b)
		_char_btns.append(b)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	_char_box.add_child(row)
	var back := _button("BACK", Vector2(110, 38))
	back.toggle_mode = false
	back.pressed.connect(_show_page.bind("cup"))
	row.add_child(back)
	_go = _button("GO!", Vector2(150, 38))
	_go.toggle_mode = false
	_go.focus_mode = Control.FOCUS_ALL
	_go.pressed.connect(_on_go)
	row.add_child(_go)


func _build_preview() -> void:
	# A tiny separate 3D world on the top screen where the chosen kart turns slowly.
	_preview.stretch = true
	_preview.visible = false
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.add_child(_preview)
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	_preview.add_child(vp)
	var env := Environment.new()
	env.background_mode = Environment.BG_CLEAR_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.8, 0.9)
	env.ambient_light_energy = 0.7
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, 35, 0)
	vp.add_child(sun)
	var cam := Camera3D.new()
	cam.fov = 40.0
	cam.position = Vector3(0, 2.6, 7.0)
	vp.add_child(cam)
	cam.look_at(Vector3(0, 0.7, 0))
	vp.add_child(_preview_pivot)


func _show_page(which: String) -> void:
	page = which
	_cup_box.visible = page == "cup"
	_char_box.visible = page == "chars"
	_preview.visible = page == "chars"
	if page == "chars":
		_pick_char(sel_char)
		_go.grab_focus.call_deferred()
	else:
		_refresh()
	_place.call_deferred()


func _pick_char(i: int) -> void:
	sel_char = clampi(i, 0, Game.RACERS.size() - 1)
	for k in _char_btns.size():
		_char_btns[k].button_pressed = k == sel_char
	if _preview_kart:
		_preview_kart.queue_free()
	_preview_kart = Kart.new()
	_preview_kart.is_cpu = true  # no engine sound
	_preview_kart.apply_stats(Game.RACERS[sel_char], 20.0, 12.0)
	_preview_pivot.add_child(_preview_kart)
	_top.queue_redraw()


func _on_go() -> void:
	Game.player_char = Game.RACERS[sel_char].name
	Game.save_settings()
	Game.start_cup(sel_class, sel_cup)


func _process(delta: float) -> void:
	if page == "chars":
		_preview_pivot.rotation.y += delta * 0.8


func _refresh() -> void:
	for k in _class_btns.size():
		var open := Game.is_unlocked(k, 0)
		_class_btns[k].disabled = not open
		_class_btns[k].text = TrackData.CLASSES[k].name if open else "LOCKED"
		_class_btns[k].button_pressed = k == sel_class
	for c in _cup_btns.size():
		var open := Game.is_unlocked(sel_class, c)
		_cup_btns[c].disabled = not open
		_cup_btns[c].text = TrackData.CUPS[c].name if open else "LOCKED"
		_cup_btns[c].button_pressed = c == sel_cup
	var ok := Game.is_unlocked(sel_class, sel_cup)
	_start.disabled = not ok
	if not ok:
		_note.text = "TOP 3 IN %s TO UNLOCK" % TrackData.CUPS[maxi(sel_cup - 1, 0)].name
	else:
		_note.text = "4 RACES  -  10 KARTS  -  TOP 3 UNLOCKS MORE"
	if ok:
		_focus_start.call_deferred()
	_top.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if page == "chars":
		# Left/right moves through drivers, up/down jumps a row, Esc goes back.
		var step := 0
		if event.is_action_pressed("steer_left"):
			step = -1
		elif event.is_action_pressed("steer_right"):
			step = 1
		elif event.is_action_pressed("accelerate"):
			step = -5
		elif event.is_action_pressed("brake"):
			step = 5
		if step != 0:
			_pick_char(posmod(sel_char + step, Game.RACERS.size()))
		if event.is_action_pressed("ui_cancel"):
			_show_page("cup")
		return
	# Keyboard / gamepad: left/right changes class, up/down changes cup.
	var dk := 0
	if event.is_action_pressed("steer_left"):
		dk = -1
	elif event.is_action_pressed("steer_right"):
		dk = 1
	if dk != 0:
		var k := clampi(sel_class + dk, 0, TrackData.CLASSES.size() - 1)
		if Game.is_unlocked(k, 0):
			sel_class = k
			_refresh()
	if event.is_action_pressed("brake") or event.is_action_pressed("accelerate"):
		var c := clampi(sel_cup + (1 if event.is_action_pressed("brake") else -1), 0, TrackData.CUPS.size() - 1)
		sel_cup = c
		_refresh()


# ---------------------------------------------------------------- layout

func _apply_layout() -> void:
	if not is_inside_tree():
		return
	is_ds = Game.use_two_screens()
	var base := Vector2i(512, ScreenLayout.SCREEN_HEIGHT * 2 + HINGE) if is_ds \
			else Vector2i(512, ScreenLayout.SCREEN_HEIGHT)
	if get_tree().root.content_scale_size != base:
		get_tree().root.content_scale_size = base
	_place.call_deferred()


func _place() -> void:
	if not is_inside_tree():
		return
	var s := get_viewport_rect().size
	if is_ds:
		var h := floorf((s.y - HINGE) / 2.0)
		_set_rect(_top, Rect2(0, 0, s.x, h))
		_set_rect(_hinge, Rect2(0, h, s.x, s.y - 2.0 * h))
		_set_rect(_bottom, Rect2(0, s.y - h, s.x, h))
	else:
		# One wide screen: maps on the left, buttons on the right.
		var w := floorf(s.x * 0.48)
		_set_rect(_top, Rect2(0, 0, w, s.y))
		_set_rect(_bottom, Rect2(w, 0, s.x - w, s.y))
	_hinge.visible = is_ds
	var pr := _preview_rect(_top.size)
	_preview.position = pr.position + Vector2(2, 2)
	_preview.size = pr.size - Vector2(4, 4)
	_top.queue_redraw()
	_bottom.queue_redraw()


func _set_rect(c: Control, r: Rect2) -> void:
	c.position = r.position
	c.size = r.size


# ---------------------------------------------------------------- drawing

func _draw_top() -> void:
	var s := _top.size
	var f := Game.ui_font
	_top.draw_rect(Rect2(Vector2.ZERO, s), Color(0.05, 0.07, 0.18))
	for y in range(0, int(s.y), 4):  # faint scanlines
		_top.draw_line(Vector2(0, y), Vector2(s.x, y), Color(1, 1, 1, 0.025))
	if page == "chars":
		_draw_driver(s, f)
		return
	_centre(_top, f, "KART RACER", Vector2(s.x / 2.0, 46), 32, HIGHLIGHT)
	var cup: Dictionary = TrackData.CUPS[sel_cup]
	_centre(_top, f, "%s  %s" % [cup.name, TrackData.CLASSES[sel_class].name], Vector2(s.x / 2.0, 76), 16, Color.WHITE)

	# The cup's three tracks.
	var n: int = cup.tracks.size()
	var cell_w := minf(270.0, (s.x - 24.0) / n)
	var cell := Vector2(cell_w - 10.0, roundf(cell_w * 0.6))
	var x0 := (s.x - cell_w * n) / 2.0 + 5.0
	for i in n:
		var ti: int = cup.tracks[i]
		var r := Rect2(Vector2(x0 + i * cell_w, 96), cell)
		_top.draw_rect(r, Color(0.03, 0.05, 0.14, 0.9))
		_top.draw_rect(r, BORDER, false, 2.0)
		_draw_map(_maps[ti], r.grow(-10), TrackData.TRACKS[ti].ground[0].lightened(0.2))
		# Names wider than their map go onto two lines (narrow screens).
		var tname: String = TrackData.TRACKS[ti].name
		if f.get_string_size(tname, HORIZONTAL_ALIGNMENT_LEFT, -1, 8).x > cell.x and " " in tname:
			var words := tname.split(" ", false, 1)
			_centre(_top, f, words[0], Vector2(r.get_center().x, r.end.y + 14), 8, DIM)
			_centre(_top, f, words[1], Vector2(r.get_center().x, r.end.y + 25), 8, DIM)
		else:
			_centre(_top, f, tname, Vector2(r.get_center().x, r.end.y + 16), 8, DIM)

	# The rivals, in their kart colours.
	var ry := 96.0 + cell.y + 60.0
	var names := []
	for r in Game.RACERS:
		if r.name != Game.player_char:
			names.append(r)
	var item_w := 74.0
	var per_row := mini(names.size(), maxi(1, int((s.x - 16.0) / item_w)))
	_centre(_top, f, "RIVALS", Vector2(s.x / 2.0, ry - 14.0), 8, DIM)
	for i in names.size():
		var row := i / per_row
		var in_row := mini(per_row, names.size() - row * per_row)
		var rx := s.x / 2.0 - item_w * in_row / 2.0
		var p := Vector2(rx + (i % per_row) * item_w, ry + row * 14.0)
		_top.draw_rect(Rect2(p + Vector2(4, -7), Vector2(8, 8)), names[i].body)
		_top.draw_string(f, p + Vector2(16, 1), names[i].name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)

	# Best trophy for this cup and class.
	var best := Game.best_place(sel_class, sel_cup)
	var y := s.y - 28.0
	if not Game.is_unlocked(sel_class, sel_cup):
		_centre(_top, f, "LOCKED", Vector2(s.x / 2.0, y), 16, Color(0.9, 0.4, 0.4))
	elif best == 0:
		_centre(_top, f, "NOT RACED YET", Vector2(s.x / 2.0, y), 16, DIM)
	else:
		var label := "BEST: %d%s" % [best, ["ST", "ND", "RD"][best - 1] if best <= 3 else "TH"]
		var col: Color = TROPHY[best - 1] if best <= 3 else Color.WHITE
		_centre(_top, f, label, Vector2(s.x / 2.0, y), 16, col)
		if best <= 3:
			_draw_trophy(Vector2(s.x / 2.0 - f.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x / 2.0 - 22, y - 8), col)


func _preview_rect(s: Vector2) -> Rect2:
	return Rect2(16, 44, minf(s.x * 0.45, 260.0), s.y - 64)


func _draw_driver(s: Vector2, f: Font) -> void:
	var def: Dictionary = Game.RACERS[sel_char]
	_centre(_top, f, "%s  %s" % [TrackData.CUPS[sel_cup].name, TrackData.CLASSES[sel_class].name],
			Vector2(s.x / 2.0, 26), 16, Color.WHITE)
	var pr := _preview_rect(s)
	_top.draw_rect(pr, Color(0.03, 0.05, 0.14))
	_top.draw_rect(pr, BORDER, false, 2.0)
	# Name, type and stat bars to the right of the turning kart.
	var x0 := pr.end.x + 18.0
	var w := s.x - x0 - 16.0
	_top.draw_string(f, Vector2(x0, 84), def.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 32, def.body.lightened(0.25))
	_top.draw_string(f, Vector2(x0, 104), def.type, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, HIGHLIGHT)
	for i in Game.STAT_NAMES.size():
		var y := 132.0 + i * 36.0
		var v: int = def.stats[i]
		_top.draw_string(f, Vector2(x0, y), Game.STAT_NAMES[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
		var seg := (w - 4 * 4.0) / 5.0
		for k in 5:
			var col := Color(0.12, 0.15, 0.25)
			if k < v:
				col = HIGHLIGHT if v >= 4 else BORDER
			_top.draw_rect(Rect2(x0 + k * (seg + 4.0), y + 6, seg, 12), col)


func _swatch(body: Color, suit: Color) -> Texture2D:
	var img := Image.create(10, 10, false, Image.FORMAT_RGB8)
	img.fill(body)
	img.fill_rect(Rect2i(3, 0, 4, 4), suit)
	return ImageTexture.create_from_image(img)


func _centre_box() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_bottom.add_child(box)
	return box


func _draw_bottom() -> void:
	var s := _bottom.size
	_bottom.draw_texture_rect(_bg, Rect2(Vector2.ZERO, s), true)
	_bottom.draw_rect(Rect2(Vector2(1, 1), s - Vector2(2, 2)), BORDER, false, 2.0)
	_bottom.draw_rect(Rect2(3, 3, s.x - 6, 26), Color(0.1, 0.15, 0.36))
	_bottom.draw_line(Vector2(3, 29), Vector2(s.x - 3, 29), BORDER, 2.0)
	_bottom.draw_string(Game.ui_font, Vector2(10, 23), "GRAND PRIX", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)


func _draw_map(pts: PackedVector2Array, r: Rect2, col: Color) -> void:
	var lo := pts[0]
	var hi := lo
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var span := hi - lo
	var sc := minf(r.size.x / span.x, r.size.y / span.y)
	var origin := r.get_center() - (lo + span * 0.5) * sc
	var line := PackedVector2Array()
	for p in pts:
		line.append((origin + p * sc).round())
	line.append(line[0])
	_top.draw_polyline(line, col, 4.0)
	_top.draw_polyline(line, Color(0.35, 0.38, 0.45), 2.0)
	_top.draw_circle(line[0], 3.0, Color.WHITE)


func _draw_trophy(c: Vector2, col: Color) -> void:
	_top.draw_rect(Rect2(c + Vector2(-7, -8), Vector2(14, 9)), col)          # cup
	_top.draw_rect(Rect2(c + Vector2(-10, -7), Vector2(3, 5)), col)          # handles
	_top.draw_rect(Rect2(c + Vector2(7, -7), Vector2(3, 5)), col)
	_top.draw_rect(Rect2(c + Vector2(-2, 1), Vector2(4, 4)), col)            # stem
	_top.draw_rect(Rect2(c + Vector2(-6, 5), Vector2(12, 3)), col)           # base


func _centre(on: Control, f: Font, text: String, pos: Vector2, fs: int, col: Color) -> void:
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	on.draw_string(f, Vector2(roundf(pos.x - w / 2.0), pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _row_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", DIM)
	return l


func _button(text: String, min_size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.toggle_mode = true
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE  # arrows change class/cup instead of moving focus
	return b


func _pick_class(k: int) -> void:
	sel_class = k
	_refresh()


func _pick_cup(c: int) -> void:
	sel_cup = c
	_refresh()


func _focus_start() -> void:
	if _start.is_inside_tree():
		_start.grab_focus()


func _on_start() -> void:
	if Game.is_unlocked(sel_class, sel_cup):
		_show_page("chars")


func _pattern() -> Texture2D:
	var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
	for y in 16:
		for x in 16:
			var stripe := (x + y) % 8 < 2
			img.set_pixel(x, y, Color(0.1, 0.14, 0.3) if stripe else Color(0.07, 0.1, 0.23))
	return ImageTexture.create_from_image(img)
