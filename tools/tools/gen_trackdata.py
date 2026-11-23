import json
L = json.load(open('layouts.json'))
def C(*v): return "Color(%s)" % ", ".join(str(x) for x in v)
TH = {
 "MEADOW LOOP": dict(scenery="trees", ground=[C(0.22,0.55,0.2), C(0.27,0.62,0.24)], road=C(0.38,0.38,0.4), kerb=[C(0.85,0.15,0.15), C(0.95,0.95,0.95)], barrier=[C(0.9,0.2,0.15), C(0.95,0.95,0.95)], sky=C(0.45,0.7,1.0), fog=C(0.65,0.8,1.0), fog_density=0.004, ambient=C(0.75,0.75,0.8), sun=0.9),
 "SANDY CANYON": dict(scenery="cacti", ground=[C(0.85,0.68,0.42), C(0.8,0.6,0.36)], road=C(0.5,0.43,0.37), kerb=[C(0.95,0.5,0.15), C(0.95,0.92,0.85)], barrier=[C(0.7,0.35,0.2), C(0.9,0.75,0.55)], sky=C(0.95,0.75,0.5), fog=C(0.95,0.8,0.6), fog_density=0.005, ambient=C(0.85,0.75,0.65), sun=1.0),
 "FROST PEAK": dict(scenery="pines", ground=[C(0.9,0.93,0.98), C(0.8,0.86,0.95)], road=C(0.45,0.48,0.56), kerb=[C(0.2,0.45,0.9), C(0.95,0.95,1.0)], barrier=[C(0.25,0.45,0.85), C(0.95,0.95,1.0)], sky=C(0.72,0.82,0.95), fog=C(0.86,0.9,0.97), fog_density=0.009, ambient=C(0.8,0.85,0.95), sun=0.8),
 "AUTUMN WOODS": dict(scenery="autumn", ground=[C(0.3,0.4,0.16), C(0.62,0.32,0.1)], road=C(0.36,0.34,0.33), kerb=[C(0.9,0.45,0.1), C(0.95,0.9,0.8)], barrier=[C(0.6,0.3,0.15), C(0.95,0.85,0.6)], sky=C(0.95,0.78,0.55), fog=C(0.9,0.72,0.5), fog_density=0.005, ambient=C(0.85,0.75,0.65), sun=0.85),
 "PALM BEACH": dict(scenery="palms", outer=C(0.15,0.55,0.8), ground=[C(0.95,0.87,0.6), C(0.9,0.81,0.54)], road=C(0.42,0.42,0.45), kerb=[C(0.1,0.7,0.6), C(0.97,0.97,0.97)], barrier=[C(1.0,0.8,0.2), C(0.97,0.97,0.97)], sky=C(0.4,0.75,1.0), fog=C(0.7,0.9,1.0), fog_density=0.003, ambient=C(0.8,0.8,0.8), sun=1.0),
 "NEON CITY": dict(scenery="city", ground=[C(0.12,0.12,0.18), C(0.15,0.15,0.22)], road=C(0.24,0.24,0.3), kerb=[C(1.0,0.25,0.85), C(0.25,0.95,1.0)], barrier=[C(1.0,0.25,0.85), C(0.25,0.95,1.0)], sky=C(0.04,0.03,0.14), fog=C(0.12,0.06,0.22), fog_density=0.006, ambient=C(0.55,0.5,0.75), sun=0.35),
 "LAVA RIDGE": dict(scenery="rocks", outer=C(1.0,0.38,0.05), ground=[C(0.25,0.18,0.16), C(0.31,0.21,0.18)], road=C(0.3,0.28,0.29), kerb=[C(1.0,0.5,0.1), C(0.15,0.15,0.15)], barrier=[C(0.95,0.45,0.1), C(0.2,0.2,0.2)], sky=C(0.35,0.12,0.1), fog=C(0.55,0.2,0.1), fog_density=0.007, ambient=C(0.8,0.6,0.55), sun=0.7),
 "MOON BASE": dict(scenery="moon", ground=[C(0.55,0.55,0.58), C(0.46,0.46,0.5)], road=C(0.26,0.28,0.33), kerb=[C(0.95,0.95,0.3), C(0.2,0.2,0.25)], barrier=[C(0.85,0.85,0.9), C(0.3,0.6,1.0)], sky=C(0.01,0.01,0.05), fog=C(0.04,0.04,0.1), fog_density=0.0015, ambient=C(0.7,0.7,0.82), sun=1.1),
 "PLAZA MALL": dict(scenery="mall", ground=[C(0.86,0.84,0.8), C(0.74,0.73,0.72)], road=C(0.52,0.52,0.58), kerb=[C(0.2,0.6,0.95), C(0.95,0.95,0.95)], barrier=[C(0.92,0.92,0.96), C(0.3,0.7,1.0)], sky=C(0.88,0.83,0.74), fog=C(0.95,0.9,0.8), fog_density=0.006, ambient=C(0.95,0.92,0.85), sun=0.6),
 "HARBOR DOCKS": dict(scenery="docks", outer=C(0.1,0.35,0.55), ground=[C(0.55,0.55,0.55), C(0.49,0.49,0.51)], road=C(0.3,0.3,0.33), kerb=[C(1.0,0.8,0.1), C(0.15,0.15,0.15)], barrier=[C(1.0,0.8,0.1), C(0.15,0.15,0.15)], sky=C(0.55,0.7,0.85), fog=C(0.7,0.78,0.85), fog_density=0.004, ambient=C(0.8,0.8,0.85), sun=0.9),
 "JUNGLE RUINS": dict(scenery="jungle", ground=[C(0.15,0.4,0.15), C(0.2,0.33,0.12)], road=C(0.45,0.4,0.32), kerb=[C(0.55,0.5,0.35), C(0.3,0.5,0.2)], barrier=[C(0.5,0.48,0.4), C(0.35,0.55,0.25)], sky=C(0.55,0.75,0.6), fog=C(0.45,0.6,0.45), fog_density=0.008, ambient=C(0.75,0.85,0.7), sun=0.8),
 "GEAR WORKS": dict(scenery="factory", ground=[C(0.35,0.36,0.38), C(0.3,0.31,0.33)], road=C(0.25,0.25,0.27), kerb=[C(1.0,0.75,0.05), C(0.1,0.1,0.1)], barrier=[C(1.0,0.75,0.05), C(0.1,0.1,0.1)], sky=C(0.5,0.45,0.4), fog=C(0.55,0.48,0.4), fog_density=0.007, ambient=C(0.85,0.8,0.75), sun=0.7),
 "GHOST HOLLOW": dict(scenery="ghost", ground=[C(0.18,0.15,0.22), C(0.22,0.2,0.25)], road=C(0.25,0.23,0.28), kerb=[C(0.6,0.3,0.8), C(0.85,0.85,0.8)], barrier=[C(0.45,0.25,0.6), C(0.8,0.8,0.75)], sky=C(0.06,0.04,0.12), fog=C(0.2,0.15,0.3), fog_density=0.012, ambient=C(0.5,0.45,0.7), sun=0.3),
 "CLOUD GARDEN": dict(scenery="clouds", outer=C(0.93,0.95,1.0), ground=[C(0.4,0.75,0.35), C(0.5,0.82,0.42)], road=C(0.72,0.7,0.66), kerb=[C(1.0,0.6,0.8), C(1.0,1.0,1.0)], barrier=[C(1.0,0.75,0.9), C(1.0,1.0,1.0)], sky=C(0.55,0.8,1.0), fog=C(0.85,0.92,1.0), fog_density=0.003, ambient=C(0.9,0.9,0.95), sun=1.0),
 "CRYSTAL CAVES": dict(scenery="crystals", ground=[C(0.16,0.14,0.2), C(0.2,0.17,0.24)], road=C(0.3,0.28,0.34), kerb=[C(0.3,0.9,1.0), C(0.9,0.4,1.0)], barrier=[C(0.3,0.9,1.0), C(0.9,0.4,1.0)], sky=C(0.02,0.02,0.06), fog=C(0.05,0.08,0.15), fog_density=0.01, ambient=C(0.55,0.55,0.75), sun=0.4),
 "STARLIGHT HIGHWAY": dict(scenery="space", outer=C(0.02,0.01,0.06), ground=[C(0.08,0.06,0.18), C(0.1,0.08,0.22)], road=C(0.16,0.16,0.3), kerb=[C(1.0,0.85,0.2), C(0.4,0.7,1.0)], barrier=[C(0.9,0.5,1.0), C(0.4,0.9,1.0)], sky=C(0.0,0.0,0.03), fog=C(0.03,0.02,0.08), fog_density=0.002, ambient=C(0.6,0.6,0.8), sun=0.6),
}
order = list(TH.keys())
def gd_layout(lay):
    items = []
    for s in lay:
        items.append('["S", %s]' % s[1] if s[0] == 'S' else '["A", %s, %s]' % (s[1], s[2]))
    lines = []; cur = []
    for it in items:
        cur.append(it)
        if len(cur) == 6: lines.append(", ".join(cur)); cur = []
    if cur: lines.append(", ".join(cur))
    return "[\n\t\t\t" + ",\n\t\t\t".join(lines) + "]"
entries = []
for n in order:
    t = TH[n]; lay = L[n]
    extra = (', "outer": %s' % t['outer']) if 'outer' in t else ''
    entries.append('''	{
		"name": "%s", "scenery": "%s", "start": %s%s,
		"layout": %s,
		"ground": [%s], "road": %s,
		"kerb": [%s], "barrier": [%s],
		"sky": %s, "fog": %s, "fog_density": %s, "ambient": %s, "sun": %s,
	},''' % (n, t['scenery'], lay['start'], extra, gd_layout(lay['layout']), ", ".join(t['ground']), t['road'], ", ".join(t['kerb']), ", ".join(t['barrier']), t['sky'], t['fog'], t['fog_density'], t['ambient'], t['sun']))
src = '''class_name TrackData
extends RefCounted
## Every track, cup and speed class in one place. A track is a list of straights and
## corners plus a colour theme and a scenery type; everything else is generated in
## code, so each track adds only about a kilobyte to the APK.
##
## Layout: ["S", metres] is a straight, ["A", radius, degrees] a corner (positive =
## right, negative = left). The road is 10 m wide with barriers 7.5 m from the centre,
## so keep corners at least 10 m in radius and sections of track 20 m apart.
## Tracks are drawn with tools/design.py, which checks this and closes each loop.
## "start" is how far along the layout the start line sits (on the longest straight).

const ROAD_HALF_WIDTH := 5.0
const WALL_OFFSET := 7.5

const CUPS := [
	{"name": "SPROUT CUP", "tracks": [0, 1, 2, 3]},
	{"name": "COMET CUP", "tracks": [4, 5, 6, 7]},
	{"name": "GEAR CUP", "tracks": [8, 9, 10, 11]},
	{"name": "CROWN CUP", "tracks": [12, 13, 14, 15]},
]

# Top speed in m/s for each class. CPU karts scale from these too.
const CLASSES := [
	{"name": "50CC", "speed": 20.0, "accel": 12.0},
	{"name": "100CC", "speed": 26.0, "accel": 15.0},
	{"name": "150CC", "speed": 31.0, "accel": 18.0},
]

const TRACKS := [
%s
]


static func get_track(i: int) -> Dictionary:
	return TRACKS[i]


static func sample(def: Dictionary, step := 4.0) -> PackedVector2Array:
	## The centre line as points about `step` metres apart, starting at the start line.
	## Corners are true circular arcs, so the loop closes exactly.
	var pts := PackedVector2Array()
	var p := Vector2.ZERO
	var h := 0.0  # heading: 0 = +x; turning right increases it (towards +z)
	pts.append(p)
	for seg in def.layout:
		if seg[0] == "S":
			var length: float = seg[1]
			var n := maxi(1, roundi(length / step))
			var d := Vector2(cos(h), sin(h)) * (length / n)
			for i in n:
				p += d
				pts.append(p)
		else:
			var r: float = seg[1]
			var turn := deg_to_rad(float(seg[2]))
			var sg := signf(turn)
			var centre := p + sg * r * Vector2(-sin(h), cos(h))
			var n := maxi(2, roundi(absf(turn) * r / step))
			for i in n:
				h += turn / n
				p = centre - sg * r * Vector2(-sin(h), cos(h))
				pts.append(p)
	pts.remove_at(pts.size() - 1)  # last point is the first one again
	# Rotate so index 0 is the start line.
	var walked := 0.0
	var k := 0
	while k < pts.size() - 1 and walked < float(def.get("start", 0.0)):
		walked += pts[k].distance_to(pts[k + 1])
		k += 1
	var out := pts.slice(k)
	out.append_array(pts.slice(0, k))
	return out
''' % "\n".join(entries)
open('../scripts/track_data.gd', 'w').write(src)
print("written", len(src), "bytes")
