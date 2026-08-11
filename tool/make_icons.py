import os
from PIL import Image

SRC = "assets/logo/logo.png"
img = Image.open(SRC).convert("RGBA")

# ---- Android mipmaps ----
sizes = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}
for name, s in sizes.items():
    out = f"android/app/src/main/res/mipmap-{name}/ic_launcher.png"
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.resize((s, s), Image.LANCZOS).save(out)
    print("android", out, s)

# ---- Windows .ico (multi-size) ----
sizes_ico = [16, 24, 32, 48, 64, 128, 256]
out_ico = "windows/runner/resources/app_icon.ico"
os.makedirs(os.path.dirname(out_ico), exist_ok=True)
img.save(out_ico, format="ICO", sizes=[(s, s) for s in sizes_ico])
print("windows ico", out_ico)

# ---- Web icons ----
web_icons = {
    "web/icons/Icon-192.png": 192,
    "web/icons/Icon-512.png": 512,
    "web/icons/Icon-maskable-192.png": 192,
    "web/icons/Icon-maskable-512.png": 512,
    "web/favicon.png": 32,
}
for out, s in web_icons.items():
    os.makedirs(os.path.dirname(out), exist_ok=True)
    img.resize((s, s), Image.LANCZOS).save(out)
    print("web", out, s)

print("OK")
