# Track design tools (Python 3 + numpy)

Tracks are drawn as straights and corners, like a turtle: `S(metres)`, `R(radius, degrees)`
(right), `L(radius, degrees)` (left), plus ready-made pieces that keep the loop closed:
`finger_in/out` (a hairpin poking into or out of the loop), `notch_in/out` (a square step),
`chiLR/chiRL` (chicanes) and `snake()`. `loop(top, right, bottom, left, corner radii)`
builds a clockwise loop; two straights are stretched automatically so it closes exactly.

1. Edit or add a track in `tracks16_defs.py`.
2. `python3 gen_layouts.py` checks every track: corners at least 10 m, no two parts of
   the track closer than 20 m (so barriers never overlap), and the loop closes.
3. `python3 gen_trackdata.py` writes `../scripts/track_data.gd` (themes are in that script).

`design.py` also has `ascii_map()` to print a text map of a layout.
Godot ignores this folder (`.gdignore`).
