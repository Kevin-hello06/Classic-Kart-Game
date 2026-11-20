# Kart Racer

A small DS-style kart racer for the Galaxy Z Fold, made with Godot 4 (4.4 or newer).
One test track, one kart, three laps against the clock.

## DS screens

On the Fold's inner screen (and in a laptop window) the game uses two screens, like a DS:

- **Top screen:** the race, with the lap count, timers and big messages (countdown, FINISH!).
- **Bottom screen:** the track map with your kart marker, lap splits, a speed readout,
  a drift/boost meter, the pause button and the touch buttons.
- A dark gap between them sits on the hinge, so in Flex mode (half folded) the fold
  runs between the screens instead of through the race.

On the wide cover screen the halves would be too thin, so it switches to one screen
with the information shown over the race. **SCREENS** in the pause menu switches
between AUTO, DS and ONE, and remembers your choice.

All text uses Press Start 2P, a classic 8-pixel game font, pre-rendered as a bitmap font so
every letter pixel stays square. Use font sizes 8, 16, 24 or 32 only.

## Controls

| Action | Phone | Keyboard | Gamepad |
|---|---|---|---|
| Steer | ◀ ▶ buttons | ← → or A D | Left stick / D-pad |
| Accelerate | GAS | ↑ or W | A |
| Drift (also accelerates) | DRIFT | Space or Shift | R1 |
| Brake / reverse | BRK | ↓ or S | X |
| Pause menu | II (top right of the bottom screen) | Esc or P | Start |
| Music on/off | Pause menu | M | — |

**Drifting:** hold DRIFT while turning. Sparks go white, then blue, then orange.
Let go for a mini-turbo (blue = short, orange = long). On the phone, slide your right
thumb from GAS up to DRIFT; DRIFT keeps the gas on so you never need two buttons.

## Music and sound

- `assets/audio/music_loop.ogg` is a single 13-second chiptune loop that repeats forever.
- Music and Sound each have an ON/OFF switch in the pause menu. The choice is saved.
  With music off the stream is paused, not just muted, so it costs no CPU.
- All audio is original and was synthesised by a script, so there are no licence issues.
  To use your own tune, replace `music_loop.ogg` with any `.ogg` file of the same name.

## Size

There are no image files. The road, grass, barrier and flag textures are tiny pixel images
generated in code, and the kart and trees are built from simple shapes. All the audio together
is about 100 KB, and the bitmap font is under 1 KB. An arm64-only APK should come to roughly 25–30 MB, and almost all of that
is the Godot engine itself.

## Files

```
project.godot          512x384 internal resolution, scaled up with sharp pixels
scenes/main.tscn       entry scene
scripts/game.gd        autoload: settings, music, sound effects, controls, saved records
scripts/main.gd        race flow: countdown, laps, checkpoints, wrong-way warning, finish
scripts/screen_layout.gd  DS two-screen / single-screen arrangement
scripts/bottom_screen.gd  map, lap splits, speed and drift meter (bottom screen)
scripts/track.gd       builds the track; edit CONTROL_POINTS to change the layout
scripts/kart.gd        kart handling and drifting; tweak the constants at the top for feel
scripts/chase_camera.gd
scripts/hud.gd
scripts/touch_controls.gd
scripts/pause_menu.gd
assets/audio/          music loop + engine and effect sounds (.ogg)
assets/fonts/          Press Start 2P as an 8 px bitmap font (SIL Open Font Licence, see OFL.txt)
```

## Tweaking

- **Feel:** `MAX_SPEED`, `ACCEL`, `TURN_RATE`, `DRIFT_TURN` and the charge times in `kart.gd`.
- **Track:** move or add points in `CONTROL_POINTS` in `track.gd` and keep them in driving order.
  Keep corners wide and sections of track well apart, because the barriers sit 10 m from the centre line.
- **Laps:** `LAPS` in `main.gd`.
- **Pixel look:** `viewport_width/height` in `project.godot`. Lower values look chunkier.

## Building the APK

The process is the same as for Fold Adventure. Go to Project → Export → Add… → Android,
and tick `arm64-v8a` (also `x86_64` if you test on the emulator). Then click Export Project.
The game is locked to landscape. It fits both the cover screen and the inner screen.
