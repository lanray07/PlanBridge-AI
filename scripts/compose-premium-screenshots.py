"""Compose premium App Store images from unedited native XCTest captures."""
import argparse
import json
from pathlib import Path
import re
from PIL import Image, ImageDraw, ImageFilter, ImageFont, ImageOps

parser = argparse.ArgumentParser()
parser.add_argument("--captures", type=Path, required=True)
parser.add_argument("--device", choices=["iphone-69", "ipad-13"], required=True)
parser.add_argument("--output", type=Path, required=True)
args = parser.parse_args()

root = Path(__file__).resolve().parents[1]
metadata = json.loads((root / "marketing/store/en-GB.json").read_text(encoding="utf-8"))
background = Image.open(root / "marketing/premium-store/backgrounds/planbridge-premium-master.png").convert("RGBA")
icon = Image.open(root / "App/Resources/Assets.xcassets/AppIcon.appiconset/icon.png").convert("RGBA")
manifest = json.loads((args.captures / "manifest.json").read_text(encoding="utf-8"))

captures = {}
for test in manifest:
    for attachment in test.get("attachments", []):
        suggested = attachment.get("suggestedHumanReadableName", "")
        match = re.search(r"(?:en(?:-GB)?-)?(\d{2}-[a-z-]+)_", suggested)
        if match and not attachment.get("isAssociatedWithFailure"):
            captures[match.group(1)] = args.captures / attachment["exportedFileName"]

subheads = {
    "01-calendar-planner": "Plans, bookings and conflicts — together.",
    "02-booking-conflicts": "See what overlaps, and why it matters.",
    "03-calendar-timeline": "Appointments and travel in one clear view.",
    "04-trip-organizer": "Keep every journey clear and organised.",
    "05-trip-check": "Check the details before you set off.",
    "06-private-questions": "Clear answers from plans on your device.",
    "07-privacy-controls": "No account. No cloud AI. Your choice.",
    "08-calendar-connections": "Select only the calendars you want.",
    "09-review-imports": "Nothing is saved until you confirm.",
    "10-planbridge-pro": "Unlimited trip checks and on-device voice."
}

if args.device == "iphone-69":
    canvas_size = (1320, 2868); margin = 82; top = 105; phone_width = 1030
    title_size = 78; body_size = 34; brand_size = 29; screen_top = 590; radius = 62
else:
    canvas_size = (2048, 2732); margin = 122; top = 92; phone_width = 1540
    title_size = 92; body_size = 40; brand_size = 34; screen_top = 535; radius = 56

font_root = Path("C:/Windows/Fonts")
title_font = ImageFont.truetype(str(font_root / "georgiab.ttf"), title_size)
body_font = ImageFont.truetype(str(font_root / "segoeui.ttf"), body_size)
brand_font = ImageFont.truetype(str(font_root / "segoeuib.ttf"), brand_size)

def cover(image, size):
    return ImageOps.fit(image, size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))

def rounded(image, radius):
    mask = Image.new("L", image.size)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, image.width - 1, image.height - 1), radius=radius, fill=255)
    result = Image.new("RGBA", image.size)
    result.paste(image, mask=mask)
    return result, mask

args.output.mkdir(parents=True, exist_ok=True)
missing = []
for item in metadata["screenshots"]:
    shot_id = item["id"]
    source_path = captures.get(shot_id)
    if not source_path:
        missing.append(shot_id)
        continue
    canvas = Image.new("RGBA", canvas_size, "#F7F5EF")
    art = cover(background, canvas_size)
    if int(shot_id[:2]) % 2 == 0:
        art = ImageOps.mirror(art)
    canvas.alpha_composite(art)
    draw = ImageDraw.Draw(canvas)

    icon_size = 58 if args.device == "iphone-69" else 66
    icon_small, icon_mask = rounded(icon.resize((icon_size, icon_size), Image.Resampling.LANCZOS), 15)
    canvas.alpha_composite(icon_small, (margin, top))
    draw.text((margin + icon_size + 18, top + 8), "PLANBRIDGE AI", font=brand_font, fill="#315D49")

    title_y = top + icon_size + 52
    title_box_width = canvas.width - margin * 2
    words = item["headline"].split()
    lines, current = [], ""
    for word in words:
        proposed = (current + " " + word).strip()
        if draw.textbbox((0, 0), proposed, font=title_font)[2] <= title_box_width:
            current = proposed
        else:
            lines.append(current); current = word
    if current: lines.append(current)
    for line in lines[:2]:
        draw.text((margin, title_y), line, font=title_font, fill="#173C30")
        title_y += int(title_size * 1.10)
    draw.text((margin, title_y + 16), subheads[shot_id], font=body_font, fill="#53625C")

    source = Image.open(source_path).convert("RGB")
    scaled_height = round(source.height * phone_width / source.width)
    screen = source.resize((phone_width, scaled_height), Image.Resampling.LANCZOS).convert("RGBA")
    max_height = canvas.height - screen_top + 150
    if screen.height > max_height:
        screen = screen.crop((0, 0, screen.width, max_height))
    screen, screen_mask = rounded(screen, radius)
    x = (canvas.width - screen.width) // 2
    shadow = Image.new("RGBA", canvas.size)
    shadow_mask = Image.new("L", canvas.size)
    ImageDraw.Draw(shadow_mask).rounded_rectangle((x, screen_top, x + screen.width, screen_top + screen.height), radius=radius, fill=150)
    shadow_mask = shadow_mask.filter(ImageFilter.GaussianBlur(34))
    shadow.paste((18, 45, 36, 120), mask=shadow_mask)
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(screen, (x, screen_top))
    draw = ImageDraw.Draw(canvas)
    draw.rounded_rectangle((x, screen_top, x + screen.width - 1, screen_top + screen.height - 1), radius=radius, outline="#FFFFFF", width=3)
    canvas.convert("RGB").save(args.output / f"{shot_id}.png", optimize=True)

if missing:
    raise SystemExit("Missing native captures: " + ", ".join(missing))
print(f"Created {len(metadata['screenshots'])} premium {args.device} screenshots in {args.output}")
