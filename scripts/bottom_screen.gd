class_name BottomScreen
extends Control
## The DS "touch screen": a track map with your kart on it, lap times, speed and a
## drift/boost meter, over a patterned DS-style background. Drawn entirely in code.

const TITLE_H := 28
const PANEL_W := 104
const PANEL_H := 96
const BORDER := Color(0.55, 0.8, 1.0)
const PANEL_BG := Color(0.03, 0.05, 0.14, 0.88)
const DIM := Color(0.6, 0.7, 0.85)
const HIGHLIGHT := Color(1.0, 0.9, 0.3)

var track: Track
var kart: Kart
var lap := 1
var laps := 3
var lap_times: Array[float] = []
var lap_time := 0.0
var best_lap := 0.0

var _bg: Texture2D
var _map_pts := PackedVector2Array()
var _map_rect := Rect2()
var _map_scale := 1.0
var _map_origin := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg = _pattern()
	resized.connect(_fit_map)


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	var s := size
	var f := Game.ui_font
	draw_texture_rect(_bg, Rect2(Vector2.ZERO, s), true)
	draw_rect(Rect2(Vector2(1, 1), s - Vector2(2, 2)), BORDER, false, 2.0)

	# Title bar (pause button sits at its right end).
	draw_rect(Rect2(3, 3, s.x - 6, TITLE_H - 2), Color(0.1, 0.15, 0.36))
	draw_line(Vector2(3, TITLE_H + 1), Vector2(s.x - 3, TITLE_H + 1), BORDER, 2.0)
	draw_string(f, Vector2(10, 23), "TEST TRACK", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
	if best_lap > 0.0:
		_text_right(f, Vector2(s.x - 54, 20), "BEST " + Game.format_time(best_lap), 8, HIGHLIGHT)

	# Map in the middle.
	if _map_pts.is_empty():
		_fit_map()
	_panel(_map_rect.grow(6))
	_draw_map()

	# Left panel: lap times.
	var lp := Rect2(8, TITLE_H + 10, PANEL_W, PANEL_H)
	_panel(lp)
	draw_string(f, lp.position + Vector2(8, 16), "LAPS", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	for i in laps:
		var y := lp.position.y + 38 + i * 18
		var text := "-:--.--"
		var col := Color.WHITE
		if i < lap_times.size():
			text = Game.format_time(lap_times[i])
			if lap_times[i] == best_lap:
				col = HIGHLIGHT
		elif i == lap - 1:
			text = Game.format_time(lap_time)
			col = Color(0.6, 1.0, 0.7)
		else:
			col = DIM
		draw_string(f, Vector2(lp.position.x + 8, y), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
		_text_right(f, Vector2(lp.end.x - 8, y), text, 8, col)

	# Right panel: speed and drift / boost meter.
	var rp := Rect2(s.x - 8 - PANEL_W, TITLE_H + 10, PANEL_W, PANEL_H)
	_panel(rp)
	draw_string(f, rp.position + Vector2(8, 16), "SPEED", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)
	var kmh := int(absf(kart.speed) * 3.6) if kart else 0
	_text_right(f, Vector2(rp.end.x - 8, rp.position.y + 50), str(kmh), 24, Color.WHITE)
	_text_right(f, Vector2(rp.end.x - 8, rp.position.y + 16), "KM/H", 8, DIM)
	_draw_meter(Rect2(rp.position.x + 8, rp.position.y + 66, PANEL_W - 16, 20))


func _draw_meter(r: Rect2) -> void:
	# 10 segments. Fills while drifting (blue, then orange); flashes during a boost.
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
		var seg := Rect2(r.position.x + i * (w + 2.0), r.position.y + 10, w, r.size.y - 10)
		draw_rect(seg, col if i < fill else Color(0.12, 0.15, 0.25))
	draw_string(Game.ui_font, r.position + Vector2(0, 8), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, DIM)


func _draw_map() -> void:
	if _map_pts.size() < 2:
		return
	var road := maxf(4.0, Track.ROAD_HALF_WIDTH * 2.0 * _map_scale)
	draw_polyline(_map_pts, Color(0.9, 0.95, 1.0), road + 4.0)
	draw_polyline(_map_pts, Color(0.35, 0.38, 0.45), road)

	# Start/finish line.
	var t := track.tangents[0]
	var side := Vector2(t.y, -t.x) * (road * 0.5 + 2.0)
	var p0 := _to_map(track.points[0])
	draw_line(p0 - side, p0 + side, Color.WHITE, 3.0)

	# Kart arrow, blinking outline like a DS map marker.
	if kart:
		var p := _to_map(Vector2(kart.position.x, kart.position.z))
		var fw := Vector2(kart.forward().x, kart.forward().z)
		var pr := Vector2(fw.y, -fw.x)
		var tri := PackedVector2Array([p + fw * 9.0, p + pr * 6.0 - fw * 6.0, p - pr * 6.0 - fw * 6.0])
		draw_colored_polygon(tri, Color(1.0, 0.25, 0.2))
		var outline := Color.WHITE if int(_t * 4.0) % 2 == 0 else Color(1.0, 0.9, 0.3)
		tri.append(tri[0])
		draw_polyline(tri, outline, 1.5)


func _fit_map() -> void:
	if not track or track.points.is_empty():
		return
	var s := size
	var top := TITLE_H + 16.0
	_map_rect = Rect2(PANEL_W + 22, top, s.x - 2 * (PANEL_W + 22), s.y - top - 116)
	var lo := track.points[0]
	var hi := lo
	for p in track.points:
		lo = lo.min(p)
		hi = hi.max(p)
	var span := hi - lo
	var inner := _map_rect.grow(-8.0)  # room for the road's thickness
	_map_scale = minf(inner.size.x / span.x, inner.size.y / span.y)
	_map_origin = _map_rect.get_center() - (lo + span * 0.5) * _map_scale
	_map_pts = PackedVector2Array()
	for p in track.points:
		_map_pts.append(_to_map(p))
	_map_pts.append(_map_pts[0])


func _to_map(p: Vector2) -> Vector2:
	return (_map_origin + p * _map_scale).round()


func _panel(r: Rect2) -> void:
	draw_rect(r, PANEL_BG)
	draw_rect(r, BORDER, false, 2.0)


func _text_right(f: Font, pos: Vector2, text: String, fs: int, col: Color) -> void:
	var w := f.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, Vector2(pos.x - w, pos.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _pattern() -> Texture2D:
	# 16x16 navy tile with faint diagonal stripes, like a DS menu background.
	var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
	for y in 16:
		for x in 16:
			var stripe := (x + y) % 8 < 2
			img.set_pixel(x, y, Color(0.1, 0.14, 0.3) if stripe else Color(0.07, 0.1, 0.23))
	return ImageTexture.create_from_image(img)
