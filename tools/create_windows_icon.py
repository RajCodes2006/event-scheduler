"""Generate Daymark's Windows launcher ICO from vector-like Pillow shapes."""
from pathlib import Path
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "build" / "branding" / "daymark_icon.ico"
BASE = 512
SCALE = 4
SIZE = BASE * SCALE


def sc(value: float) -> int:
    return round(value * SCALE)


def box(x1, y1, x2, y2):
    return tuple(sc(v) for v in (x1, y1, x2, y2))


def bezier(p0, p1, p2, p3, steps=12):
    points = []
    for i in range(steps + 1):
        t = i / steps
        u = 1 - t
        x = u**3 * p0[0] + 3*u*u*t*p1[0] + 3*u*t*t*p2[0] + t**3*p3[0]
        y = u**3 * p0[1] + 3*u*u*t*p1[1] + 3*u*t*t*p2[1] + t**3*p3[1]
        points.append((sc(x), sc(y)))
    return points


gradient = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
gd = ImageDraw.Draw(gradient)
top = (12, 43, 91)
bottom = (7, 17, 43)
for y in range(SIZE):
    t = y / max(SIZE - 1, 1)
    color = tuple(round(top[c] * (1 - t) + bottom[c] * t) for c in range(3)) + (255,)
    gd.line((0, y, SIZE, y), fill=color)
mask = Image.new("L", (SIZE, SIZE), 0)
ImageDraw.Draw(mask).rounded_rectangle(box(0, 0, 512, 512), radius=sc(105), fill=255)
gradient.putalpha(mask)
img = gradient
D = ImageDraw.Draw(img)

# Calendar body and blue header.
D.rounded_rectangle(box(68, 81, 441, 431), radius=sc(40), fill="#04122F")
D.rounded_rectangle(box(68, 70, 441, 424), radius=sc(40), fill="#087FF5")
D.rounded_rectangle(box(68, 168, 441, 424), radius=sc(40), fill="#F8FAFF")
D.rectangle(box(68, 190, 441, 220), fill="#F8FAFF")

# Calendar rings.
D.rounded_rectangle(box(139, 45, 181, 157), radius=sc(21), fill="#FFFFFF")
D.rounded_rectangle(box(328, 45, 370, 157), radius=sc(21), fill="#FFFFFF")

# Date grid.
for x in (112, 179, 246, 313):
    for y in (225, 293, 361):
        D.rounded_rectangle(box(x, y, x + 47, y + 45), radius=sc(10), fill="#D8E3F5")
D.rounded_rectangle(box(246, 225, 293, 270), radius=sc(10), fill="#13A7FF")
D.rounded_rectangle(box(179, 293, 226, 338), radius=sc(10), fill="#FF4369")

# Reminder bell badge.
D.ellipse(box(278, 247, 445, 414), fill="#0B5CE0")
bell = []
bell += bezier((360, 284), (343, 284), (337, 300), (335, 317))
bell += bezier((335, 317), (333, 339), (329, 350), (315, 363))[1:]
bell += bezier((315, 363), (307, 371), (313, 380), (324, 380))[1:]
bell += bezier((324, 380), (350, 382), (378, 382), (402, 380))[1:]
bell += bezier((402, 380), (413, 379), (417, 371), (407, 362))[1:]
bell += bezier((407, 362), (397, 351), (393, 335), (391, 316))[1:]
bell += bezier((391, 316), (389, 298), (377, 284), (360, 284))[1:]
D.polygon(bell, fill="#FFFFFF")
D.ellipse(box(351, 386, 371, 404), fill="#FFFFFF")
D.line((sc(430), sc(267), sc(443), sc(246)), fill="#FFFFFF", width=sc(9))
D.line((sc(444), sc(290), sc(465), sc(278)), fill="#FFFFFF", width=sc(9))

icon = img.resize((256, 256), Image.Resampling.LANCZOS)
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
icon.save(OUTPUT, format="ICO", sizes=[(16, 16), (24, 24), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
print(f"Created {OUTPUT}")
