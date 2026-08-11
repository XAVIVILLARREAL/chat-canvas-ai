import math
from PIL import Image, ImageDraw, ImageFilter

S = 1024  # final size
SS = 4096  # supersampled size for smooth edges

# ---------- helpers ----------
def lerp(c1, c2, t):
    return tuple(int(round(a + (b - a) * t)) for a, b in zip(c1, c2))

def rounded_gradient(size, radius, c1, c2, direction="diag"):
    img = Image.new("RGBA", (size, size))
    px = img.load()
    for y in range(size):
        for x in range(size):
            if direction == "diag":
                t = (x + y) / (2 * size)
            elif direction == "v":
                t = y / size
            else:
                t = x / size
            px[x, y] = lerp(c1, c2, t) + (255,)
    mask = Image.new("L", (size, size), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle([0, 0, size - 1, size - 1], radius=radius, fill=255)
    img.putalpha(mask)
    return img

def thick_line(d, p1, p2, width, fill):
    d.line([p1, p2], fill=fill, width=width)

def draw_dot(d, cx, cy, r, fill):
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=fill)

def draw_spark(d, cx, cy, r, fill):
    """4-point star spark (AI symbol)."""
    pts = []
    for i in range(8):
        ang = math.pi / 4 * i
        rr = r if i % 2 == 0 else r * 0.38
        pts.append((cx + rr * math.cos(ang), cy + rr * math.sin(ang)))
    d.polygon(pts, fill=fill)

# ---------- build at supersample ----------
ss = rounded_gradient(SS, int(SS * 0.22), (11, 18, 32), (14, 165, 233), "diag")
d = ImageDraw.Draw(ss)

u = SS / S  # unit = 4px per final px

# subtle radial glow top-left
glow = Image.new("RGBA", (SS, SS), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.ellipse([-SS*0.3, -SS*0.4, SS*0.9, SS*1.2], fill=(255,255,255,26))
glow = glow.filter(ImageFilter.GaussianBlur(SS*0.15))
ss = Image.alpha_composite(ss, glow)
d = ImageDraw.Draw(ss)

# ---- neural nodes (AI network) ----
node_fill = (165, 85, 247, 255)      # purple
node_fill2 = (56, 189, 248, 255)     # cyan
line_col = (255, 255, 255, 110)

nodes = [
    (0.30*SS, 0.27*SS),
    (0.22*SS, 0.42*SS),
    (0.37*SS, 0.38*SS),
    (0.27*SS, 0.55*SS),
]
# connect lines
for i in range(len(nodes)):
    for j in range(i+1, len(nodes)):
        thick_line(d, nodes[i], nodes[j], int(0.012*SS), line_col)
# nodes
for n in nodes:
    draw_dot(d, n[0], n[1], int(0.035*SS), node_fill)

# ---- terminal chevron ">" ----
white = (255, 255, 255, 255)
w = int(0.10 * SS)  # stroke width
cx = 0.60 * SS
cy = 0.50 * SS
# chevron: two strokes meeting at right point
top = (cx - 0.15*SS, cy - 0.26*SS)
right = (cx + 0.17*SS, cy)
bot = (cx - 0.15*SS, cy + 0.26*SS)
# draw as thick lines with round caps via circles at joints
def line_round(d, a, b, wd, fill):
    d.line([a, b], fill=fill, width=wd)
    draw_dot(d, a[0], a[1], wd//2, fill)
    draw_dot(d, b[0], b[1], wd//2, fill)

line_round(d, top, right, w, white)
line_round(d, right, bot, w, white)

# AI spark on the chevron tip
draw_spark(d, right[0], right[1], int(0.075*SS), (56, 189, 248, 255))

# terminal cursor block (underscore)
cur_w = int(0.085*SS)
cur_h = int(0.030*SS)
d.rounded_rectangle(
    [cx + 0.24*SS, cy - cur_h/2, cx + 0.24*SS + cur_w, cy + cur_h/2],
    radius=int(cur_h/2), fill=(56, 189, 248, 255),
)

# downscale with high quality
img = ss.resize((S, S), Image.LANCZOS)
img.save("assets/logo/logo.png")
print("logo.png guardado", img.size)
