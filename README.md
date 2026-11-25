# Kart Racer

A small DS-style kart racer for the Galaxy Z Fold, made with Godot 4 (4.4 or newer).
Grand Prix racing against nine CPU karts: 2 cups of 4 tracks, at 50cc, 100cc and 150cc.

## Characters

| Driver | Type | Speed | Accel | Handling | Drift | Weight | Kart |
|---|---|---|---|---|---|---|---|
| RUBY | All-rounder | 3 | 3 | 3 | 3 | 3 | plain |
| AZURE | Top speed | 5 | 2 | 2 | 2 | 4 | spoiler |
| OLIVE | Nimble | 2 | 4 | 4 | 3 | 2 | big rear wheels |
| SUNNY | Quick start | 2 | 5 | 3 | 3 | 2 | antenna |
| CORAL | Light drifter | 3 | 3 | 4 | 4 | 1 | tail fins |
| VIOLET | Drift ace | 3 | 2 | 3 | 5 | 2 | spoiler |
| MINT | Grip | 2 | 3 | 5 | 3 | 2 | antenna |
| INDIGO | Heavyweight | 4 | 2 | 2 | 2 | 5 | wide body |
| SLATE | Bruiser | 4 | 3 | 2 | 2 | 4 | wide body |
| COCOA | Punchy | 3 | 4 | 2 | 3 | 3 | big rear wheels |

Every character's stats add up to 15. What each point does (3 = average):
- **Speed:** top speed +-2% per point.
- **Accel:** acceleration +-20% per point.
- **Handling:** steering, drift turn rate and safe cornering speed +-3% per point.
- **Drift:** mini-turbo charges +-15% faster per point.
- **Weight:** heavy karts lose less speed when they bump into things; light karts lose
  less speed on grass.

The numbers live in `RACERS` in `game.gd` (stats) and `apply_stats()` in `kart.gd` (effects),
so they're easy to play with. Rivals use the same stats, and their `skill` scales their top
speed, so the difficulty stays steady whoever you pick.

## Grand Prix

| Cup | Tracks |
|---|---|
| SPROUT CUP | Meadow Loop (infield hairpin), Sandy Canyon (long straight, three square canyon teeth), Frost Peak (summit hairpin), Autumn Woods (chicanes, two drift chains) |
| COMET CUP | Palm Beach (seafront straight, pier hairpin), Neon City (90-degree city blocks), Lava Ridge (ridge hairpin, snake, chicane), Moon Base (dumbbell: two tight loops) |
| GEAR CUP | Plaza Mall (indoor, around the shops), Harbor Docks (zig-zag between containers), Jungle Ruins (snakes, ruined-gate hairpin), Gear Works (double hairpin) |
| CROWN CUP | Ghost Hollow (dark, graveyard step, snake), Cloud Garden (sky island sweepers, bridge hairpin), Crystal Caves (twisting tunnels), Starlight Highway (finale: longest, three hairpins) |

The road is 10 m wide with barriers close by, and every track has 10 m hairpins or 90-degree
corners, so at 150cc you have to brake or drift; you can't hold the throttle all lap.
Drifting through long corners is clearly faster (the mini-turbos add up).

- After START you pick your driver from ten characters; the other nine are your CPU rivals.
  Each cup is 4 races of 3 laps. Points per race: 15, 12, 10, 8, 6, 5, 4, 3, 2, 1.
  Most points after 4 races wins the cup.
- You start the first race at the back of the 10-kart grid. Later races line up in the finishing
  order of the previous race, its winner on pole.
- Fastest lap of the race (anyone's): shown live as the purple FL row under the gaps
  (blinks when someone beats it, chime if it's you), and on the results screen with its lap.
- After every race: the results, then tap for the cup standings (total points, points just
  scored, and places moved: ^2 = up two, v1 = down one). The last race adds the trophy and unlocks.
- **Unlocks (finish in the top 3 = a trophy):**
  - Top 3 in a cup unlocks the next cup at the same class (Sprout → Comet → Gear → Crown).
  - Top 3 in all four cups unlocks the next class (50cc → 100cc → 150cc).
- Higher classes are faster for everyone, and the CPU drivers get sharper. They brake for
  hairpins and drift through long corners for boosts, like you. They never cheat,
  but they ease off a little when far ahead of you and push a little when far behind,
  so races stay close.
- During a race the top screen shows the time gap to the kart just ahead and just behind
  you (updated four times a second). In the results, karts still on track when you finish
  get an estimated time (marked `~`) from how far behind they were.
- Trophies, unlocks and your best lap on each track are saved.
- Pause menu: RESTART replays the current race (points so far are kept), QUIT CUP returns to the menu.

## DS screens

On the Fold's inner screen (and in a laptop window) the game uses two screens, like a DS:

- **Top screen:** the race, with the lap count and race time top-left, a lap-times panel
  down the left side, a speed and drift/boost meter panel on the right, and big messages
  (countdown, FINISH!).
- **Bottom screen:** the track map with your kart marker in the middle, the pause button
  (II, a DS-style START pill at the bottom-centre), and the touch controls. **CONTROLS** in the
  pause menu picks DS style (D-pad, A/B/X/Y, R) or ROUND (big round buttons).
  On the Fold the DS-style buttons sit raised, a bit over halfway down, the D-pad and A the
  same distance from each side (DS_EDGE, DS_LIFT in touch_controls.gd), with
  A/B/X/Y and R pulled in from the edge. Both styles keep the right-middle edge empty,
  because the Fold's inner camera hole sits there. To move or resize them, edit `_ds_layout()`, `_centres()` and `ROOMY_RADIUS`
  in `touch_controls.gd`.
- A dark gap between them sits on the hinge, so in Flex mode (half folded) the fold
  runs between the screens instead of through the race.

On the 21:9 cover screen the halves would be too thin, so it switches to one screen
with the information and a see-through D-pad and A/B/X/Y shown over the race. The
two-screen layout is made for the 8:7 inner screen. **SCREENS** in the pause menu switches
between AUTO, DS and ONE, and remembers your choice.

On phones, the HUD, buttons and menus keep a clear margin on both sides (at least 4.5% of
the width, more if the phone reports a bigger camera cutout), so centred punch holes
(Galaxy S), corner punch holes and iPhone notches never cover anything. The race itself
still fills the whole screen. Tune `SIDE_MARGIN` in `safe_insets()` in `game.gd`.

All text uses Press Start 2P, a classic 8-pixel game font, pre-rendered as a bitmap font so
every letter pixel stays square. Use font sizes 8, 16, 24 or 32 only.

## Controls

| Action | Phone | Keyboard | Gamepad |
|---|---|---|---|
| Steer | D-pad ◀ ▶ (ROUND: ◀ ▶ buttons) | ← → or A D | Left stick / D-pad |
| Accelerate | A (ROUND: GAS) | ↑ or W | A |
| Drift (also accelerates) | R (ROUND: DRIFT) | Space or Shift | R1 |
| Brake / reverse | B (ROUND: BRAKE) | ↓ or S | X |
| Pause menu | II (bottom-centre of the bottom screen, like DS START; left side with ROUND controls; top right on one screen) | Esc or P | Start |
| Music on/off | II pause menu during races (note button on the title menu) | M (anywhere) | — |

**Drifting:** hold DRIFT while turning. Sparks go white, then blue, then orange.
Let go for a mini-turbo (blue = short, orange = long). On the phone, slide your right
thumb from A up to R (ROUND: from GAS left to DRIFT). Drift keeps the gas on, so you
never need two buttons at once.

## Music and sound

- `assets/audio/music_loop.ogg` is a single 13-second chiptune loop that repeats forever.
- During a race, switch music in the II pause menu (MUSIC: ON/OFF). The title menu has a
  one-tap music-note button. M does the same on a keyboard, anywhere in the game.
- Music and Sound each also have an ON/OFF switch in the pause menu. The choice is saved.
  With music off the stream is paused, not just muted, so it costs no CPU.
- All audio is original and was synthesised by a script, so there are no licence issues.
  To use your own tune, replace `music_loop.ogg` with any `.ogg` file of the same name.

## Size

There are no image files. The road, grass, barrier and flag textures are tiny pixel images
generated in code, and the karts and scenery are built from simple shapes. Each track is
a short list of straights and corners plus a colour theme, so all 16 tracks together are
about 16 KB. All the audio together
is about 100 KB, and the bitmap font is under 1 KB. Measured against Godot 4.4.1's official Android template: an arm64-only APK is about
26 MB (25 MB engine + 0.23 MB game data, with all 16 tracks). Once installed, Android unpacks the engine,
so the app takes about 100 MB on the phone.

## Files

```
project.godot          512x384 internal resolution, scaled up with sharp pixels
scenes/menu.tscn       title menu (starting scene)
scenes/main.tscn       a race
scripts/game.gd        autoload: settings, audio, controls, cup points, unlocks, saved progress
scripts/menu.gd        DS-style menu: pick class and cup, see tracks and trophies
scripts/main.gd        a race: grid, countdown, laps and positions for all karts, results, standings
scripts/track_data.gd  every track, cup and speed class (layouts, themes, scenery)
scripts/cpu_driver.gd  CPU racer: follows the track, slows for corners, catch-up
scripts/screen_layout.gd  DS two-screen / single-screen arrangement
scripts/bottom_screen.gd  bottom screen: title bar and map
scripts/music_button.gd   one-tap music on/off button (title menu)
scripts/track.gd       builds a track (road, barriers, sky, scenery) from its definition
scripts/kart.gd        kart handling and drifting; tweak the constants at the top for feel
scripts/chase_camera.gd
scripts/hud.gd         top-screen HUD: laps panel, speed/drift panel, messages
scripts/touch_controls.gd
scripts/pause_menu.gd
assets/audio/          music loop + engine and effect sounds (.ogg)
assets/fonts/          Press Start 2P as an 8 px bitmap font (SIL Open Font Licence, see OFL.txt)
```

## Tweaking

- **Feel:** `MAX_SPEED`, `ACCEL`, `TURN_RATE`, `DRIFT_TURN` and the charge times in `kart.gd`.
- **Tracks:** each track is an entry in `TRACKS` in `track_data.gd`: a layout of straights
  (`["S", metres]`) and corners (`["A", radius, degrees]`, + right / - left), a start
  position, colours and a scenery type (trees, cacti, pines, autumn, palms, city, rocks,
  moon, mall, docks, jungle, factory, ghost, clouds, crystals, space). The layouts were
  designed with a small tool that checks every loop closes, corners are at least 10 m and
  no two parts of the track come closer than 20 m. List a track's number in a cup in `CUPS`.
- **Characters:** stats, colours and kart part in `RACERS` in `game.gd`; what the stats do in
  `apply_stats()` in `kart.gd`.
- **Difficulty:** each rival's `skill` in `RACERS` in `game.gd` (fraction of top speed),
  `CLASS_SKILL` for the per-class shift, and class speeds in `CLASSES` in `track_data.gd`.
- **Laps:** `LAPS` in `main.gd`.
- **Pixel look:** `viewport_width/height` in `project.godot`. Lower values look chunkier.

## Building the APK

The process is the same as for Fold Adventure. Go to Project → Export → Add… → Android,
and tick `arm64-v8a` (also `x86_64` if you test on the emulator). Then click Export Project.
The game is locked to landscape. It fits both the cover screen and the inner screen.
