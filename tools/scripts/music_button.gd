class_name MusicButton
extends Button
## One-tap music on/off on the bottom screen. Draws a pixel music note, crossed out
## in red when the music is off. Stays in sync with the pause menu and the M key.


func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(44, 40)
	pressed.connect(func() -> void: Game.set_music(not Game.music_on))


func _process(_delta: float) -> void:
	queue_redraw()  # picks up changes made from the pause menu or keyboard


func _draw() -> void:
	var c := (size / 2.0).round()
	var col := Color.WHITE if Game.music_on else Color(0.55, 0.6, 0.7)
	# Two beamed notes: heads, stems and the beam.
	draw_rect(Rect2(c + Vector2(-11, 4), Vector2(7, 5)), col)
	draw_rect(Rect2(c + Vector2(3, 1), Vector2(7, 5)), col)
	draw_rect(Rect2(c + Vector2(-6, -11), Vector2(2, 17)), col)
	draw_rect(Rect2(c + Vector2(8, -14), Vector2(2, 17)), col)
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-6, -11), c + Vector2(10, -14), c + Vector2(10, -10), c + Vector2(-6, -7)]), col)
	if not Game.music_on:
		draw_line(c + Vector2(-14, 12), c + Vector2(14, -14), Color(1.0, 0.3, 0.3), 3.0)
