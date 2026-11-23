import sys, json; sys.path.insert(0, '.')
exec(open('tracks16_defs.py').read())
from design import solve, walk
out = {}
for name, segs in T.items():
    frees = list(solve(segs)); fi = 0; flat = []
    for s in segs:
        if s[0] == 'F':
            flat.append(['S', round(frees[fi], 2)]); fi += 1
        elif s[0] == 'S':
            flat.append(['S', s[1]])
        else:
            flat.append(['A', s[1], s[2]])
    # merge consecutive straights
    merged = []
    for s in flat:
        if merged and s[0] == 'S' and merged[-1][0] == 'S':
            merged[-1][1] = round(merged[-1][1] + s[1], 2)
        else:
            merged.append(list(s))
    # start line: 65% along the longest straight
    dist = 0.0; best = (0, 0.0)
    import math
    for s in merged:
        L = s[1] if s[0] == 'S' else abs(math.radians(s[2])) * s[1]
        if s[0] == 'S' and s[1] > best[0]:
            best = (s[1], dist + 0.65 * s[1])
        dist += L
    out[name] = {"layout": merged, "start": round(best[1], 1), "length": round(dist, 1)}
json.dump(out, open('layouts.json', 'w'), indent=0)
for n, v in out.items():
    print(f"{n:18s} {v['length']:6.0f} m  start at {v['start']:6.1f} m  segments {len(v['layout'])}")
