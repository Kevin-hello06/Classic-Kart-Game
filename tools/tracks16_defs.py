from design import *
# Building blocks with no net turn, so any combination still closes into a loop.
def snake(r=11): return L(r, 60) + R(r, 120) + L(r, 120) + R(r, 120) + L(r, 60)
def finger_in(d, r=10, c=10):   # dives into the infield, hairpin (left) at the tip, comes back
	return R(c, 90) + S(d) + L(r, 180) + S(d) + R(c, 90)
def finger_out(d, r=10, c=10):  # pokes outward, hairpin (right) at the tip
	return L(c, 90) + S(d) + R(r, 180) + S(d) + L(c, 90)
def notch_in(depth, w, r=10):   # square step into the infield (four 90-degree corners)
	return R(r, 90) + S(depth) + L(r, 90) + S(w) + L(r, 90) + S(depth) + R(r, 90)
def notch_out(depth, w, r=10):
	return L(r, 90) + S(depth) + R(r, 90) + S(w) + R(r, 90) + S(depth) + L(r, 90)
def loop(top, right, bottom, left, c):
	# clockwise: top heading east, right side south, bottom west, left north
	return F() + top + R(c[0], 90) + right + R(c[1], 90) + bottom + R(c[2], 90) + F() + left + R(c[3], 90)

T = {}
# ---- SPROUT CUP
T["MEADOW LOOP"] = loop(S(80), S(70), S(50) + finger_in(50) + S(80), S(40), [45, 35, 35, 40])
T["SANDY CANYON"] = loop(S(60), S(80), S(30) + notch_in(35, 25, 11) + S(25) + notch_in(35, 25, 11) + S(25) + notch_in(35, 25, 11) + S(40), S(20), [10, 10, 30, 30])
T["FROST PEAK"] = loop(S(70), S(30) + finger_out(70) + S(70), S(110), S(40) + chiLR(12, 40) + S(40), [25, 25, 25, 25])
T["AUTUMN WOODS"] = loop(S(30) + chiLR(10, 50) + S(40) + chiRL(10, 50) + S(30), S(30) + chiRL(10, 50) + S(30),
		S(30) + snake() + S(30) + snake() + S(30), S(30) + chiLR(10, 50) + S(20), [20, 15, 20, 20])
# ---- COMET CUP
T["PALM BEACH"] = loop(S(160), S(40) + chiRL(30, 25) + S(40), S(60) + finger_out(60) + S(80), S(30), [45, 40, 40, 30])
T["NEON CITY"] = loop(S(40) + notch_in(30, 40) + S(40), S(40) + notch_out(25, 40) + S(40), S(50) + notch_in(35, 40) + S(50), S(60), [10, 10, 10, 10])
T["LAVA RIDGE"] = loop(S(30) + chiLR(11, 55) + S(30), S(30) + finger_in(45) + S(30), S(30) + snake() + S(30) + chiRL(11, 55) + S(40), S(40), [12, 12, 20, 20])
T["MOON BASE"] = loop(S(40) + notch_in(30, 70, 15) + S(40), S(150), S(70) + notch_in(30, 70, 15) + S(70), S(40), [15, 15, 15, 15])
# ---- GEAR CUP
T["PLAZA MALL"] = loop(S(50) + notch_out(25, 40) + S(50), S(40) + finger_in(40) + S(50), S(50) + notch_in(30, 50) + S(50), S(30) + chiLR(10, 50) + S(20), [10, 25, 10, 10])
T["HARBOR DOCKS"] = loop(S(140), S(30) + notch_out(30, 40) + S(30) + notch_in(30, 40) + S(30), S(40) + notch_out(25, 40) + S(40), S(30), [10, 15, 30, 30])
T["JUNGLE RUINS"] = loop(S(20) + snake() + S(20), S(30) + chiRL(11, 60) + S(30), S(30) + finger_in(40) + S(30) + snake() + S(20), S(40), [15, 11, 15, 20])
T["GEAR WORKS"] = loop(S(30) + finger_in(45) + S(30) + finger_out(35) + S(30), S(30) + chiRL(10, 50) + S(30), S(220), S(50), [10, 10, 10, 10])
# ---- CROWN CUP
T["GHOST HOLLOW"] = loop(S(30) + notch_in(20, 30) + S(20) + snake() + S(20), S(40) + finger_in(40) + S(20), S(30) + notch_out(20, 30) + S(150), S(40), [12, 10, 15, 15])
T["CLOUD GARDEN"] = loop(S(60) + chiRL(15, 40) + S(60), S(110), S(80) + chiLR(15, 40) + S(80), S(30) + finger_in(60) + S(30), [45, 40, 45, 40])
T["CRYSTAL CAVES"] = loop(S(20) + snake(10) + S(20), S(20) + notch_in(20, 30) + S(20), S(20) + finger_out(35) + S(20) + snake(10) + S(20), S(30), [10, 10, 12, 12])
T["STARLIGHT HIGHWAY"] = loop(S(80) + chiRL(12, 45) + S(80), S(40) + finger_in(55) + S(30) + finger_in(55) + S(40), S(60) + finger_out(45) + S(160), S(80), [40, 12, 30, 40])
