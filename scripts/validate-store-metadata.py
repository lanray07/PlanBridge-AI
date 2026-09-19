"""Validate versioned App Store copy before publishing it."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
limits = {"name": 30, "subtitle": 30, "promotionalText": 170,
          "keywords": 100, "description": 4000}
errors = []
files = sorted((ROOT / "marketing/store").glob("*.json"))
if not files:
    errors.append("No store metadata found")
for path in files:
    data = json.loads(path.read_text(encoding="utf-8"))
    for field, limit in limits.items():
        value = data.get(field, "")
        if not isinstance(value, str) or not value.strip() or len(value) > limit:
            errors.append(f"{path.name}: {field} must contain 1–{limit} characters")
    keywords = [word.strip().casefold() for word in data["keywords"].split(",")]
    if len(keywords) != len(set(keywords)):
        errors.append(f"{path.name}: duplicate keywords")
    for shot in data.get("screenshots", []):
        if shot["keyword"].casefold() not in shot["headline"].casefold():
            errors.append(f"{path.name}: {shot['id']} headline omits its keyword")
    print(f"{path.name}: description {len(data['description'])}/4000; keywords {len(data['keywords'])}/100")
if errors:
    raise SystemExit("\n".join(errors))
print("Store copy limits and screenshot keyword mappings passed. Publication review is separate.")
