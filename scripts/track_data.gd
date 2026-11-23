class_name TrackData
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
	{
		"name": "MEADOW LOOP", "scenery": "trees", "start": 100.8,
		"layout": [
			["S", 155.0], ["A", 45, 90], ["S", 70], ["A", 35, 90], ["S", 50], ["A", 10, 90],
			["S", 50], ["A", 10, -180], ["S", 50], ["A", 10, 90], ["S", 80], ["A", 35, 90],
			["S", 75.0], ["A", 40, 90]],
		"ground": [Color(0.22, 0.55, 0.2), Color(0.27, 0.62, 0.24)], "road": Color(0.38, 0.38, 0.4),
		"kerb": [Color(0.85, 0.15, 0.15), Color(0.95, 0.95, 0.95)], "barrier": [Color(0.9, 0.2, 0.15), Color(0.95, 0.95, 0.95)],
		"sky": Color(0.45, 0.7, 1.0), "fog": Color(0.65, 0.8, 1.0), "fog_density": 0.004, "ambient": Color(0.75, 0.75, 0.8), "sun": 0.9,
	},
	{
		"name": "SANDY CANYON", "scenery": "cacti", "start": 212.6,
		"layout": [
			["S", 327.0], ["A", 10, 90], ["S", 80], ["A", 10, 90], ["S", 30], ["A", 11, 90],
			["S", 35], ["A", 11, -90], ["S", 25], ["A", 11, -90], ["S", 35], ["A", 11, 90],
			["S", 25], ["A", 11, 90], ["S", 35], ["A", 11, -90], ["S", 25], ["A", 11, -90],
			["S", 35], ["A", 11, 90], ["S", 25], ["A", 11, 90], ["S", 35], ["A", 11, -90],
			["S", 25], ["A", 11, -90], ["S", 35], ["A", 11, 90], ["S", 40], ["A", 30, 90],
			["S", 40.0], ["A", 30, 90]],
		"ground": [Color(0.85, 0.68, 0.42), Color(0.8, 0.6, 0.36)], "road": Color(0.5, 0.43, 0.37),
		"kerb": [Color(0.95, 0.5, 0.15), Color(0.95, 0.92, 0.85)], "barrier": [Color(0.7, 0.35, 0.2), Color(0.9, 0.75, 0.55)],
		"sky": Color(0.95, 0.75, 0.5), "fog": Color(0.95, 0.8, 0.6), "fog_density": 0.005, "ambient": Color(0.85, 0.75, 0.65), "sun": 1.0,
	},
	{
		"name": "FROST PEAK", "scenery": "pines", "start": 71.5,
		"layout": [
			["S", 110.0], ["A", 25, 90], ["S", 30], ["A", 10, -90], ["S", 70], ["A", 10, 180],
			["S", 70], ["A", 10, -90], ["S", 70], ["A", 25, 90], ["S", 110], ["A", 25, 90],
			["S", 69.15], ["A", 12, -40], ["A", 12, 80], ["A", 12, -40], ["S", 40], ["A", 25, 90]],
		"ground": [Color(0.9, 0.93, 0.98), Color(0.8, 0.86, 0.95)], "road": Color(0.45, 0.48, 0.56),
		"kerb": [Color(0.2, 0.45, 0.9), Color(0.95, 0.95, 1.0)], "barrier": [Color(0.25, 0.45, 0.85), Color(0.95, 0.95, 1.0)],
		"sky": Color(0.72, 0.82, 0.95), "fog": Color(0.86, 0.9, 0.97), "fog_density": 0.009, "ambient": Color(0.8, 0.85, 0.95), "sun": 0.8,
	},
	{
		"name": "AUTUMN WOODS", "scenery": "autumn", "start": 69.0,
		"layout": [
			["S", 106.14], ["A", 10, -50], ["A", 10, 100], ["A", 10, -50], ["S", 40], ["A", 10, 50],
			["A", 10, -100], ["A", 10, 50], ["S", 30], ["A", 20, 90], ["S", 30], ["A", 10, 50],
			["A", 10, -100], ["A", 10, 50], ["S", 30], ["A", 15, 90], ["S", 30], ["A", 11, -60],
			["A", 11, 120], ["A", 11, -120], ["A", 11, 120], ["A", 11, -60], ["S", 30], ["A", 11, -60],
			["A", 11, 120], ["A", 11, -120], ["A", 11, 120], ["A", 11, -60], ["S", 30], ["A", 20, 90],
			["S", 35.0], ["A", 10, -50], ["A", 10, 100], ["A", 10, -50], ["S", 20], ["A", 20, 90]],
		"ground": [Color(0.3, 0.4, 0.16), Color(0.62, 0.32, 0.1)], "road": Color(0.36, 0.34, 0.33),
		"kerb": [Color(0.9, 0.45, 0.1), Color(0.95, 0.9, 0.8)], "barrier": [Color(0.6, 0.3, 0.15), Color(0.95, 0.85, 0.6)],
		"sky": Color(0.95, 0.78, 0.55), "fog": Color(0.9, 0.72, 0.5), "fog_density": 0.005, "ambient": Color(0.85, 0.75, 0.65), "sun": 0.85,
	},
	{
		"name": "PALM BEACH", "scenery": "palms", "start": 120.2, "outer": Color(0.15, 0.55, 0.8),
		"layout": [
			["S", 185.0], ["A", 45, 90], ["S", 40], ["A", 30, 25], ["A", 30, -50], ["A", 30, 25],
			["S", 40], ["A", 40, 90], ["S", 60], ["A", 10, -90], ["S", 60], ["A", 10, 180],
			["S", 60], ["A", 10, -90], ["S", 80], ["A", 40, 90], ["S", 145.71], ["A", 30, 90]],
		"ground": [Color(0.95, 0.87, 0.6), Color(0.9, 0.81, 0.54)], "road": Color(0.42, 0.42, 0.45),
		"kerb": [Color(0.1, 0.7, 0.6), Color(0.97, 0.97, 0.97)], "barrier": [Color(1.0, 0.8, 0.2), Color(0.97, 0.97, 0.97)],
		"sky": Color(0.4, 0.75, 1.0), "fog": Color(0.7, 0.9, 1.0), "fog_density": 0.003, "ambient": Color(0.8, 0.8, 0.8), "sun": 1.0,
	},
	{
		"name": "NEON CITY", "scenery": "city", "start": 919.6,
		"layout": [
			["S", 60.0], ["A", 10, 90], ["S", 30], ["A", 10, -90], ["S", 40], ["A", 10, -90],
			["S", 30], ["A", 10, 90], ["S", 40], ["A", 10, 90], ["S", 40], ["A", 10, -90],
			["S", 25], ["A", 10, 90], ["S", 40], ["A", 10, 90], ["S", 25], ["A", 10, -90],
			["S", 40], ["A", 10, 90], ["S", 50], ["A", 10, 90], ["S", 35], ["A", 10, -90],
			["S", 40], ["A", 10, -90], ["S", 35], ["A", 10, 90], ["S", 50], ["A", 10, 90],
			["S", 160.0], ["A", 10, 90]],
		"ground": [Color(0.12, 0.12, 0.18), Color(0.15, 0.15, 0.22)], "road": Color(0.24, 0.24, 0.3),
		"kerb": [Color(1.0, 0.25, 0.85), Color(0.25, 0.95, 1.0)], "barrier": [Color(1.0, 0.25, 0.85), Color(0.25, 0.95, 1.0)],
		"sky": Color(0.04, 0.03, 0.14), "fog": Color(0.12, 0.06, 0.22), "fog_density": 0.006, "ambient": Color(0.55, 0.5, 0.75), "sun": 0.35,
	},
	{
		"name": "LAVA RIDGE", "scenery": "rocks", "start": 95.0, "outer": Color(1.0, 0.38, 0.05),
		"layout": [
			["S", 146.21], ["A", 11, -55], ["A", 11, 110], ["A", 11, -55], ["S", 30], ["A", 12, 90],
			["S", 30], ["A", 10, 90], ["S", 45], ["A", 10, -180], ["S", 45], ["A", 10, 90],
			["S", 30], ["A", 12, 90], ["S", 30], ["A", 11, -60], ["A", 11, 120], ["A", 11, -120],
			["A", 11, 120], ["A", 11, -60], ["S", 30], ["A", 11, 55], ["A", 11, -110], ["A", 11, 55],
			["S", 40], ["A", 20, 90], ["S", 84.0], ["A", 20, 90]],
		"ground": [Color(0.25, 0.18, 0.16), Color(0.31, 0.21, 0.18)], "road": Color(0.3, 0.28, 0.29),
		"kerb": [Color(1.0, 0.5, 0.1), Color(0.15, 0.15, 0.15)], "barrier": [Color(0.95, 0.45, 0.1), Color(0.2, 0.2, 0.2)],
		"sky": Color(0.35, 0.12, 0.1), "fog": Color(0.55, 0.2, 0.1), "fog_density": 0.007, "ambient": Color(0.8, 0.6, 0.55), "sun": 0.7,
	},
	{
		"name": "MOON BASE", "scenery": "moon", "start": 485.3,
		"layout": [
			["S", 100.0], ["A", 15, 90], ["S", 30], ["A", 15, -90], ["S", 70], ["A", 15, -90],
			["S", 30], ["A", 15, 90], ["S", 40], ["A", 15, 90], ["S", 150], ["A", 15, 90],
			["S", 70], ["A", 15, 90], ["S", 30], ["A", 15, -90], ["S", 70], ["A", 15, -90],
			["S", 30], ["A", 15, 90], ["S", 70], ["A", 15, 90], ["S", 150.0], ["A", 15, 90]],
		"ground": [Color(0.55, 0.55, 0.58), Color(0.46, 0.46, 0.5)], "road": Color(0.26, 0.28, 0.33),
		"kerb": [Color(0.95, 0.95, 0.3), Color(0.2, 0.2, 0.25)], "barrier": [Color(0.85, 0.85, 0.9), Color(0.3, 0.6, 1.0)],
		"sky": Color(0.01, 0.01, 0.05), "fog": Color(0.04, 0.04, 0.1), "fog_density": 0.0015, "ambient": Color(0.7, 0.7, 0.82), "sun": 1.1,
	},
	{
		"name": "PLAZA MALL", "scenery": "mall", "start": 915.5,
		"layout": [
			["S", 75.0], ["A", 10, -90], ["S", 25], ["A", 10, 90], ["S", 40], ["A", 10, 90],
			["S", 25], ["A", 10, -90], ["S", 50], ["A", 10, 90], ["S", 40], ["A", 10, 90],
			["S", 40], ["A", 10, -180], ["S", 40], ["A", 10, 90], ["S", 50], ["A", 25, 90],
			["S", 50], ["A", 10, 90], ["S", 30], ["A", 10, -90], ["S", 50], ["A", 10, -90],
			["S", 30], ["A", 10, 90], ["S", 50], ["A", 10, 90], ["S", 94.36], ["A", 10, -50],
			["A", 10, 100], ["A", 10, -50], ["S", 20], ["A", 10, 90]],
		"ground": [Color(0.86, 0.84, 0.8), Color(0.74, 0.73, 0.72)], "road": Color(0.52, 0.52, 0.58),
		"kerb": [Color(0.2, 0.6, 0.95), Color(0.95, 0.95, 0.95)], "barrier": [Color(0.92, 0.92, 0.96), Color(0.3, 0.7, 1.0)],
		"sky": Color(0.88, 0.83, 0.74), "fog": Color(0.95, 0.9, 0.8), "fog_density": 0.006, "ambient": Color(0.95, 0.92, 0.85), "sun": 0.6,
	},
	{
		"name": "HARBOR DOCKS", "scenery": "docks", "start": 1039.6, "outer": Color(0.1, 0.35, 0.55),
		"layout": [
			["S", 165.0], ["A", 10, 90], ["S", 30], ["A", 10, -90], ["S", 30], ["A", 10, 90],
			["S", 40], ["A", 10, 90], ["S", 30], ["A", 10, -90], ["S", 30], ["A", 10, 90],
			["S", 30], ["A", 10, -90], ["S", 40], ["A", 10, -90], ["S", 30], ["A", 10, 90],
			["S", 30], ["A", 15, 90], ["S", 40], ["A", 10, -90], ["S", 25], ["A", 10, 90],
			["S", 40], ["A", 10, 90], ["S", 25], ["A", 10, -90], ["S", 40], ["A", 30, 90],
			["S", 215.0], ["A", 30, 90]],
		"ground": [Color(0.55, 0.55, 0.55), Color(0.49, 0.49, 0.51)], "road": Color(0.3, 0.3, 0.33),
		"kerb": [Color(1.0, 0.8, 0.1), Color(0.15, 0.15, 0.15)], "barrier": [Color(1.0, 0.8, 0.1), Color(0.15, 0.15, 0.15)],
		"sky": Color(0.55, 0.7, 0.85), "fog": Color(0.7, 0.78, 0.85), "fog_density": 0.004, "ambient": Color(0.8, 0.8, 0.85), "sun": 0.9,
	},
	{
		"name": "JUNGLE RUINS", "scenery": "jungle", "start": 59.2,
		"layout": [
			["S", 91.0], ["A", 11, -60], ["A", 11, 120], ["A", 11, -120], ["A", 11, 120], ["A", 11, -60],
			["S", 20], ["A", 15, 90], ["S", 30], ["A", 11, 60], ["A", 11, -120], ["A", 11, 60],
			["S", 30], ["A", 11, 90], ["S", 30], ["A", 10, 90], ["S", 40], ["A", 10, -180],
			["S", 40], ["A", 10, 90], ["S", 30], ["A", 11, -60], ["A", 11, 120], ["A", 11, -120],
			["A", 11, 120], ["A", 11, -60], ["S", 20], ["A", 15, 90], ["S", 89.11], ["A", 20, 90]],
		"ground": [Color(0.15, 0.4, 0.15), Color(0.2, 0.33, 0.12)], "road": Color(0.45, 0.4, 0.32),
		"kerb": [Color(0.55, 0.5, 0.35), Color(0.3, 0.5, 0.2)], "barrier": [Color(0.5, 0.48, 0.4), Color(0.35, 0.55, 0.25)],
		"sky": Color(0.55, 0.75, 0.6), "fog": Color(0.45, 0.6, 0.45), "fog_density": 0.008, "ambient": Color(0.75, 0.85, 0.7), "sun": 0.8,
	},
	{
		"name": "GEAR WORKS", "scenery": "factory", "start": 695.0,
		"layout": [
			["S", 80.0], ["A", 10, 90], ["S", 45], ["A", 10, -180], ["S", 45], ["A", 10, 90],
			["S", 30], ["A", 10, -90], ["S", 35], ["A", 10, 180], ["S", 35], ["A", 10, -90],
			["S", 30], ["A", 10, 90], ["S", 30], ["A", 10, 50], ["A", 10, -100], ["A", 10, 50],
			["S", 30], ["A", 10, 90], ["S", 220], ["A", 10, 90], ["S", 90.64], ["A", 10, 90]],
		"ground": [Color(0.35, 0.36, 0.38), Color(0.3, 0.31, 0.33)], "road": Color(0.25, 0.25, 0.27),
		"kerb": [Color(1.0, 0.75, 0.05), Color(0.1, 0.1, 0.1)], "barrier": [Color(1.0, 0.75, 0.05), Color(0.1, 0.1, 0.1)],
		"sky": Color(0.5, 0.45, 0.4), "fog": Color(0.55, 0.48, 0.4), "fog_density": 0.007, "ambient": Color(0.85, 0.8, 0.75), "sun": 0.7,
	},
	{
		"name": "GHOST HOLLOW", "scenery": "ghost", "start": 824.5,
		"layout": [
			["S", 61.79], ["A", 10, 90], ["S", 20], ["A", 10, -90], ["S", 30], ["A", 10, -90],
			["S", 20], ["A", 10, 90], ["S", 20], ["A", 11, -60], ["A", 11, 120], ["A", 11, -120],
			["A", 11, 120], ["A", 11, -60], ["S", 20], ["A", 12, 90], ["S", 40], ["A", 10, 90],
			["S", 40], ["A", 10, -180], ["S", 40], ["A", 10, 90], ["S", 20], ["A", 10, 90],
			["S", 30], ["A", 10, -90], ["S", 20], ["A", 10, 90], ["S", 30], ["A", 10, 90],
			["S", 20], ["A", 10, -90], ["S", 150], ["A", 15, 90], ["S", 92.0], ["A", 15, 90]],
		"ground": [Color(0.18, 0.15, 0.22), Color(0.22, 0.2, 0.25)], "road": Color(0.25, 0.23, 0.28),
		"kerb": [Color(0.6, 0.3, 0.8), Color(0.85, 0.85, 0.8)], "barrier": [Color(0.45, 0.25, 0.6), Color(0.8, 0.8, 0.75)],
		"sky": Color(0.06, 0.04, 0.12), "fog": Color(0.2, 0.15, 0.3), "fog_density": 0.012, "ambient": Color(0.5, 0.45, 0.7), "sun": 0.3,
	},
	{
		"name": "CLOUD GARDEN", "scenery": "clouds", "start": 344.1, "outer": Color(0.93, 0.95, 1.0),
		"layout": [
			["S", 100.0], ["A", 15, 40], ["A", 15, -80], ["A", 15, 40], ["S", 60], ["A", 45, 90],
			["S", 110], ["A", 40, 90], ["S", 80], ["A", 15, -40], ["A", 15, 80], ["A", 15, -40],
			["S", 80], ["A", 45, 90], ["S", 40.0], ["A", 10, 90], ["S", 60], ["A", 10, -180],
			["S", 60], ["A", 10, 90], ["S", 30], ["A", 40, 90]],
		"ground": [Color(0.4, 0.75, 0.35), Color(0.5, 0.82, 0.42)], "road": Color(0.72, 0.7, 0.66),
		"kerb": [Color(1.0, 0.6, 0.8), Color(1.0, 1.0, 1.0)], "barrier": [Color(1.0, 0.75, 0.9), Color(1.0, 1.0, 1.0)],
		"sky": Color(0.55, 0.8, 1.0), "fog": Color(0.85, 0.92, 1.0), "fog_density": 0.003, "ambient": Color(0.9, 0.9, 0.95), "sun": 1.0,
	},
	{
		"name": "CRYSTAL CAVES", "scenery": "crystals", "start": 752.4,
		"layout": [
			["S", 80.0], ["A", 10, -60], ["A", 10, 120], ["A", 10, -120], ["A", 10, 120], ["A", 10, -60],
			["S", 20], ["A", 10, 90], ["S", 20], ["A", 10, 90], ["S", 20], ["A", 10, -90],
			["S", 30], ["A", 10, -90], ["S", 20], ["A", 10, 90], ["S", 20], ["A", 10, 90],
			["S", 20], ["A", 10, -90], ["S", 35], ["A", 10, 180], ["S", 35], ["A", 10, -90],
			["S", 20], ["A", 10, -60], ["A", 10, 120], ["A", 10, -120], ["A", 10, 120], ["A", 10, -60],
			["S", 20], ["A", 12, 90], ["S", 106.0], ["A", 12, 90]],
		"ground": [Color(0.16, 0.14, 0.2), Color(0.2, 0.17, 0.24)], "road": Color(0.3, 0.28, 0.34),
		"kerb": [Color(0.3, 0.9, 1.0), Color(0.9, 0.4, 1.0)], "barrier": [Color(0.3, 0.9, 1.0), Color(0.9, 0.4, 1.0)],
		"sky": Color(0.02, 0.02, 0.06), "fog": Color(0.05, 0.08, 0.15), "fog_density": 0.01, "ambient": Color(0.55, 0.55, 0.75), "sun": 0.4,
	},
	{
		"name": "STARLIGHT HIGHWAY", "scenery": "space", "start": 1294.9, "outer": Color(0.02, 0.01, 0.06),
		"layout": [
			["S", 108.06], ["A", 12, 45], ["A", 12, -90], ["A", 12, 45], ["S", 80], ["A", 40, 90],
			["S", 40], ["A", 10, 90], ["S", 55], ["A", 10, -180], ["S", 55], ["A", 10, 90],
			["S", 30], ["A", 10, 90], ["S", 55], ["A", 10, -180], ["S", 55], ["A", 10, 90],
			["S", 40], ["A", 12, 90], ["S", 60], ["A", 10, -90], ["S", 45], ["A", 10, 180],
			["S", 45], ["A", 10, -90], ["S", 160], ["A", 30, 90], ["S", 172.0], ["A", 40, 90]],
		"ground": [Color(0.08, 0.06, 0.18), Color(0.1, 0.08, 0.22)], "road": Color(0.16, 0.16, 0.3),
		"kerb": [Color(1.0, 0.85, 0.2), Color(0.4, 0.7, 1.0)], "barrier": [Color(0.9, 0.5, 1.0), Color(0.4, 0.9, 1.0)],
		"sky": Color(0.0, 0.0, 0.03), "fog": Color(0.03, 0.02, 0.08), "fog_density": 0.002, "ambient": Color(0.6, 0.6, 0.8), "sun": 0.6,
	},
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
