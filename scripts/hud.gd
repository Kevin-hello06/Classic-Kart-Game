class_name Hud
extends Control
## Top-screen HUD: lap count and race time top-left, a lap-times panel down the
## left side, a speed + drift/boost meter panel on the right, and the big centre
## message (countdown, WRONG WAY, finish results). Used in both screen layouts.

const PANEL_W := 112
const BORDER := Color(0.55, 0.8, 1.0)
const PANEL_BG := Color(0.03, 0.05, 0.14, 0.72)
const DIM := Color(0.6, 0.7, 0.85)
const HIGHLIGHT := Color(1.0, 0.9, 0.3)
const FASTEST := Color(0.85, 0.5, 1.0)  # race fastest lap (purple)

var kart: Kart
var lap := 1
var laps := 3
var lap_time := 0.0
var best_lap := 0.0
var lap_times: Array[float] = []
var compact := false   # true on the DS top screen (no pause button up here)
var place := 1         # your current race position
var fastest_name := ""   # fastest lap of the race so far
var fastest_time := 0.0
var fastest_mine := false
var _fastest_flash := 0.0  # blinks for a few seconds after a new fastest lap
var gap_ahead := -1.0   # seconds behind the kart in front (-1 = none)
var gap_behind := -1.0  # seconds the kart behind is behind you
var ahead_name := ""
var behind_name := ""
var racers := 10

var _lap: Label
var _time: Label
var _message: Label
var _sub: Label
var _sub_panel: PanelContainer
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_lap = _label(16, Vector2(8, 8))
	_time = _label(8, Vector2(8, 30))

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
	_sub.label_settings.line_spacing = 2.0
	remove_child(_sub)
	_sub_panel.add_child(_sub)


func _process(delta: float) -> void:
	_t += delta
	_fastest_flash = maxf(_fastest_flash - delta, 0.0)
	queue_redraw()


func update_race(new_lap: int, total: int, race_time: float, new_lap_time: float,
		times: Array[float], best: float) -> void:
	lap = new_lap
	laps = total
	lap_time = new_lap_time
	lap_times = times
	best_lap = best
	_lap.text = "LAP %d/%d" % [mini(lap, laps), laps]
	_time.text = Game.format_time(race_time)


func set_fastest(who: String, time: float, mine: bool) -> void:
	fastest_name = who
	fastest_time = time
	fastest_mine = mine
	_fastest_flash = 3.0


func set_gaps(a_name: String, a_gap: float, b_name: String, b_gap: float) -> void:
	ahead_name = a_name
	gap_ahead = a_gap
	behind_name = b_name
	gap_behind = b_gap


func show_message(text: String, sub := "") -> void:
	_message.text = text
	_sub.text = sub
	_sub_panel.visible = sub != ""
	# With a results panel, lift the title so everything fits on the screen.
	var top := -186.0 if sub != "" else -84.0
	_message.offset_top = top
	_message.offset_bottom = top + 32 * 1.4
	_sub_panel.offset_top = top + 44.0
	_sub_panel.offset_bottom = top + 44.0
	queue_redraw()


func set_compact(on: bool) -> void:
	compact = on
	queue_redraw()


func current_message() -> String:
	return _message.text


# ---------------------------------------------------------------- side panels

func _draw() -> void:
	if _sub_panel.visible:
		return  # results on screen: hide the side panels
	var f := Game.ui_font
	var s := size

	# Left: lap splits and best lap.
	var lp := Rect2(8, 46, PANEL_W, 104)
	_panel(lp)
	draw_string(f, lp.position + Vector2(8, 16), "LAPS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	for i in laps:
		var y := lp.position.y + 36 + i * 16
		var text := "-:--.--"
		var col := DIM
		if i < lap_times.size():
			text = Game.format_time(lap_times[i])
			col = HIGHLIGHT if lap_times[i] == best_lap else Color.WHITE
		elif i == lap - 1:
			text = Game.format_time(lap_time)
			col = Color(0.6, 1.0, 0.7)
		draw_string(f, Vector2(lp.position.x + 8, y), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
		_text_right(f, Vector2(lp.end.x - 8, y), text, 8, col)
	draw_line(Vector2(lp.position.x + 6, lp.end.y - 22), Vector2(lp.end.x - 6, lp.end.y - 22), BORDER * Color(1, 1, 1, 0.5), 1.0)
	draw_string(f, Vector2(lp.position.x + 8, lp.end.y - 8), "BEST", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	_text_right(f, Vector2(lp.end.x - 8, lp.end.y - 8),
			Game.format_time(best_lap) if best_lap > 0.0 else "-:--.--", 8, HIGHLIGHT)

	# Time gaps to the karts just ahead and behind, under the laps panel.
	var rows := []
	if gap_ahead >= 0.0:
		rows.append(["AHEAD ", ahead_name, gap_ahead, Color(1.0, 0.55, 0.5)])
	if gap_behind >= 0.0:
		rows.append(["BEHIND", behind_name, gap_behind, Color(0.6, 1.0, 0.7)])
	if fastest_time > 0.0:
		rows.append(["FL", fastest_name, fastest_time, FASTEST])
	if not rows.is_empty():
		var gp := Rect2(8, lp.end.y + 6, PANEL_W + 40, 8 + rows.size() * 14)
		_panel(gp)
		for i in rows.size():
			if rows[i][0] == "FL":
				# Fastest lap of the race (purple, like F1); blinks when someone beats it.
				var y2 := gp.position.y + 16 + i * 14
				if _fastest_flash > 0.0 and int(_t * 6.0) % 2 == 0:
					continue
				var who_col := Color(1.0, 0.9, 0.3) if fastest_mine else Color.WHITE
				draw_string(f, Vector2(gp.position.x + 6, y2), "FL", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, FASTEST)
				draw_string(f, Vector2(gp.position.x + 26, y2), fastest_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, who_col)
				_text_right(f, Vector2(gp.end.x - 6, y2), Game.format_time(fastest_time), 8, FASTEST)
				continue
			var y := gp.position.y + 16 + i * 14
			draw_string(f, Vector2(gp.position.x + 6, y), rows[i][0], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
			draw_string(f, Vector2(gp.position.x + 62, y), rows[i][1], HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
			_text_right(f, Vector2(gp.end.x - 6, y), "%.1f" % rows[i][2], 8, rows[i][3])

	# Right: speed and drift / boost meter. On one screen it sits below the pause button.
	var rp := Rect2(s.x - 8 - PANEL_W, 8 if compact else 40, PANEL_W, 96)
	_panel(rp)
	draw_string(f, rp.position + Vector2(8, 16), "SPEED", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	_text_right(f, Vector2(rp.end.x - 8, rp.position.y + 16), "KM/H", 8, DIM)
	var kmh := int(absf(kart.speed) * 3.6) if kart else 0
	_text_right(f, Vector2(rp.end.x - 8, rp.position.y + 50), str(kmh), 24, Color.WHITE)
	_draw_meter(Rect2(rp.position.x + 8, rp.position.y + 64, PANEL_W - 16, 22))

	# Race position under the speed panel, big like on the DS: "2ND /6".
	var suffix: String = ["ST", "ND", "RD"][place - 1] if place >= 1 and place <= 3 else "TH"
	var pos_col: Color = [HIGHLIGHT, Color(0.85, 0.9, 1.0), Color(1.0, 0.65, 0.35)][place - 1] if place <= 3 \
			else Color.WHITE
	var y := rp.end.y + 40
	var total := "/%d" % racers
	_text_right(f, Vector2(rp.end.x, y), total, 16, DIM)
	var tw := f.get_string_size(total, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_text_right(f, Vector2(rp.end.x - tw - 2, y), suffix, 16, pos_col)
	var sw := f.get_string_size(suffix, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x
	_text_right(f, Vector2(rp.end.x - tw - sw - 2, y), str(place), 32, pos_col)


func _draw_meter(r: Rect2) -> void:
	# 10 segments. Fills while drifting (white, blue, then orange); flashes during a boost.
	var segs := 10
	var fill := 0
	var col := Color(0.3, 0.6, 1.0)
	var label := "DRIFT"
	if kart and kart.boost_time > 0.0:
		fill = segs if int(_t * 12.0) % 2 == 0 else 0
		col = Color(1.0, 0.55, 0.1)
		label = "BOOST!"
	elif kart and kart.drift_dir != 0:
		fill = int(clampf(kart.drift_charge / Kart.CHARGE_ORANGE, 0.0, 1.0) * segs)
		if kart.drift_charge >= Kart.CHARGE_ORANGE:
			col = Color(1.0, 0.55, 0.1)
		elif kart.drift_charge < Kart.CHARGE_BLUE:
			col = Color(0.85, 0.9, 1.0)
	var w := (r.size.x - (segs - 1) * 2.0) / segs
	for i in segs:
		var seg := Rect2(r.position.x + i * (w + 2.0), r.position.y + 12, w, r.size.y - 12)
		draw_rect(seg, col if i < fill else Color(0.12, 0.15, 0.25))
	draw_string(Game.ui_font, r.position + Vector2(0, 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)


func _panel(r: Rect2) -> void:
	draw_rect(r, PANEL_BG)
	draw_rect(r, BORDER, false, 2.0)


func _text_right(f: Font, pos: Vector2, text: String, fs: int, col: Color) -> void:
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, Vector2(pos.x - w, pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


# ---------------------------------------------------------------- labels

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
