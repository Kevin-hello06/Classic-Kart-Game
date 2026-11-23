class_name BottomScreen
extends Control
## The DS "touch screen": a title bar, a music on/off button on the left, the track
## map with your kart on it in the middle, and the touch buttons below. Drawn in code.

const TITLE_H := 28
const MAP_MAX := Vector2(256, 160)  # map panel size (shrinks to fit if space is short)
const BUTTON_ZONE := 142            # bottom strip kept clear for the touch buttons
const BORDER := Color(0.55, 0.8, 1.0)
const PANEL_BG := Color(0.03, 0.05, 0.14, 0.88)

var track: Track
var kart: Kart
var others: Array[Kart] = []    # CPU karts, drawn as coloured dots
var title := "TEST TRACK"

var _bg: Texture2D
var _map_pts := PackedVector2Array()
var _map_rect := Rect2()
var _map_scale := 1.0
var _map_origin := Vector2.ZERO
var _t := 0.0
var _music: MusicButton


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg = _pattern()
	_music = MusicButton.new()
	add_child(_music)
	resized.connect(_fit_map)


func map_rect() -> Rect2:
	## Where the map panel sits, so the touch buttons can stay clear of it.
	return _map_rect.grow(6)


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	var s := size
	draw_texture_rect(_bg, Rect2(Vector2.ZERO, s), true)
	draw_rect(Rect2(Vector2(1, 1), s - Vector2(2, 2)), BORDER, false, 2.0)

	# Title bar (pause button sits at its right end).
	draw_rect(Rect2(3, 3, s.x - 6, TITLE_H - 2), Color(0.1, 0.15, 0.36))
	draw_line(Vector2(3, TITLE_H + 1), Vector2(s.x - 3, TITLE_H + 1), BORDER, 2.0)
	draw_string(Game.ui_font, Vector2(10, 23), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16)

	if _map_pts.is_empty():
		_fit_map()
	var panel := map_rect()
	draw_rect(panel, PANEL_BG)
	draw_rect(panel, BORDER, false, 2.0)
	_draw_map()


func _draw_map() -> void:
	if _map_pts.size() < 2:
		return
	var road := maxf(3.0, Track.ROAD_HALF_WIDTH * 2.0 * _map_scale)
	draw_polyline(_map_pts, Color(0.9, 0.95, 1.0), road + 3.0)
	draw_polyline(_map_pts, Color(0.35, 0.38, 0.45), road)

	# Start/finish line.
	var t := track.tangents[0]
	var side := Vector2(t.y, -t.x) * (road * 0.5 + 2.0)
	var p0 := _to_map(track.points[0])
	draw_line(p0 - side, p0 + side, Color.WHITE, 2.0)

	# Rival karts as dots in their colours.
	for o in others:
		var q := _to_map(Vector2(o.position.x, o.position.z))
		draw_circle(q, 4.0, Color(0.05, 0.05, 0.1))
		draw_circle(q, 3.0, o.body_color)

	# Kart arrow, blinking outline like a DS map marker.
	if kart:
		var p := _to_map(Vector2(kart.position.x, kart.position.z))
		var fw := Vector2(kart.forward().x, kart.forward().z)
		var pr := Vector2(fw.y, -fw.x)
		var tri := PackedVector2Array([p + fw * 8.0, p + pr * 5.0 - fw * 5.0, p - pr * 5.0 - fw * 5.0])
		draw_colored_polygon(tri, Color(1.0, 0.25, 0.2))
		var outline := Color.WHITE if int(_t * 4.0) % 2 == 0 else Color(1.0, 0.9, 0.3)
		tri.append(tri[0])
		draw_polyline(tri, outline, 1.5)


func _fit_map() -> void:
	if not track or track.points.is_empty():
		return
	var s := size
	# Centred left to right, sitting low: just above the steering buttons.
	var top := TITLE_H + 14.0
	var bottom := s.y - BUTTON_ZONE - 12.0
	var w := minf(MAP_MAX.x, s.x - 2.0 * 150.0)  # full size on the Fold; narrower on 4:3
	var h := minf(MAP_MAX.y, bottom - top)
	_map_rect = Rect2(roundf((s.x - w) / 2.0), bottom - h, w, h)
	# Music button lines up with the top of the map panel.
	_music.position = Vector2(10, map_rect().position.y)
	var lo := track.points[0]
	var hi := lo
	for p in track.points:
		lo = lo.min(p)
		hi = hi.max(p)
	var span := hi - lo
	var inner := _map_rect.grow(-6.0)  # room for the road's thickness
	_map_scale = minf(inner.size.x / span.x, inner.size.y / span.y)
	_map_origin = _map_rect.get_center() - (lo + span * 0.5) * _map_scale
	_map_pts = PackedVector2Array()
	for p in track.points:
		_map_pts.append(_to_map(p))
	_map_pts.append(_map_pts[0])


func _to_map(p: Vector2) -> Vector2:
	return (_map_origin + p * _map_scale).round()


func _pattern() -> Texture2D:
	# 16x16 navy tile with faint diagonal stripes, like a DS menu background.
	var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
	for y in 16:
		for x in 16:
			var stripe := (x + y) % 8 < 2
			img.set_pixel(x, y, Color(0.1, 0.14, 0.3) if stripe else Color(0.07, 0.1, 0.23))
	return ImageTexture.create_from_image(img)
