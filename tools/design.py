"""Turtle-style track designer: straights and arcs, two 'free' straights solved to close the loop.
Checks corner radius and spacing for a narrow road (barriers 6.5 m from centre) and draws ASCII maps."""
import math, numpy as np
WALL = 7.5
MIN_SEP = 2 * WALL + 5.0     # barriers of neighbouring sections at least 5 m apart

def S(l): return [('S', l)]
def F(): return [('F',)]                      # free straight (length solved)
def R(r, deg): return [('A', r, deg)]          # right turn (clockwise on the map)
def L(r, deg): return [('A', r, -deg)]
def hpR(r=10): return R(r, 180)   # hairpin: legs 2r apart
def hpL(r=10): return L(r, 180)
def chiLR(r=12, a=50): return L(r, a) + R(r, 2*a) + L(r, a)   # left-right-left kink, ends same heading
def chiRL(r=12, a=50): return R(r, a) + L(r, 2*a) + R(r, a)

def walk(segs, frees, step=1.0):
    """Exact geometry: straights and true circular arcs (so the loop closes exactly at any step)."""
    x, y, h = 0.0, 0.0, 0.0   # heading 0 = east; y grows downward on the map
    pts = [(x, y)]; fi = 0; minr = 1e9
    for s in segs:
        if s[0] in 'SF':
            l = s[1] if s[0] == 'S' else frees[fi]
            if s[0] == 'F': fi += 1
            n = max(1, int(round(l / step)))
            for i in range(n):
                x += math.cos(h) * l / n; y += math.sin(h) * l / n; pts.append((x, y))
        else:
            r, deg = s[1], s[2]; minr = min(minr, r)
            sg = 1.0 if deg > 0 else -1.0
            cx = x + sg * r * -math.sin(h); cy = y + sg * r * math.cos(h)
            n = max(2, int(round(abs(math.radians(deg)) * r / step)))
            for i in range(n):
                h += math.radians(deg) / n
                x = cx - sg * r * -math.sin(h); y = cy - sg * r * math.cos(h)
                pts.append((x, y))
    return np.array(pts), h, minr

def solve(segs):
    # end point is linear in the two free lengths: solve end == start.
    e0, _, _ = walk(segs, [0, 0]); e1, _, _ = walk(segs, [1, 0]); e2, _, _ = walk(segs, [0, 1])
    p0, d1, d2 = e0[-1], e1[-1] - e0[-1], e2[-1] - e0[-1]
    A = np.array([d1, d2]).T
    return np.linalg.solve(A, -p0)

def check(name, segs):
    frees = solve(segs)
    if max(abs(f) for f in frees) > 3000 or min(frees) < 0:
        return dict(name=name, frees=frees, ok=False, pts=None, turn=0, length=0, sep=0, minr=0)
    pts, h, minr = walk(segs, frees)
    turn = math.degrees(h)
    length = np.sum(np.linalg.norm(np.diff(pts, axis=0), axis=1))
    sub = pts[::3]; M = len(sub); sep = 1e9
    for i in range(M):
        d = np.linalg.norm(sub - sub[i], axis=1); idx = np.arange(M)
        gap = np.minimum(abs(idx - i), M - abs(idx - i)) * 3
        far = d[gap > 2 * math.pi * WALL + 25]
        if len(far): sep = min(sep, far.min())
    ok = min(frees) > 5 and abs(abs(turn) - 360) < 1 and sep >= MIN_SEP and minr >= WALL + 2
    return dict(name=name, pts=pts, frees=frees, turn=turn, length=length, sep=sep, minr=minr, ok=ok)

def ascii_map(pts, cols=46, max_rows=26):
    lo = pts.min(0); hi = pts.max(0); span = hi - lo
    sx = (cols - 1) / span[0]
    if span[1] * sx / 2.0 + 1 > max_rows:      # tall track: shrink to fit
        sx = (max_rows - 1) * 2.0 / span[1]; cols = int(span[0] * sx) + 2
    rows = max(5, int(span[1] * sx / 2.0) + 1)
    sy = (rows - 1) / span[1] if span[1] > 0 else 1
    g = [[' '] * cols for _ in range(rows)]
    for x, y in pts:
        c = int(round((x - lo[0]) * sx)); r = int(round((y - lo[1]) * sy))
        g[r][c] = '#'
    # start line and direction
    x, y = pts[0]; c = int(round((x - lo[0]) * sx)); r = int(round((y - lo[1]) * sy)); g[r][c] = 'S'
    x2, y2 = pts[12]; c2 = int(round((x2 - lo[0]) * sx)); r2 = int(round((y2 - lo[1]) * sy))
    if (c2, r2) != (c, r):
        g[r2][c2] = '>' if c2 > c else '<' if c2 < c else ('v' if r2 > r else '^')
    return "\n".join("".join(row).rstrip() for row in g)
