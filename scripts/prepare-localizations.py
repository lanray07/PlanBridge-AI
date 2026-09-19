"""Check bundled translation coverage; compile only complete, reviewed drafts.

No network access or translation API is used. Source catalogs come from Xcode's
localization-source artifact. This deliberately rejects partial translations.
"""
import argparse
import json
from pathlib import Path
import re
import sys

sys.stdout.reconfigure(encoding="utf-8")

parser = argparse.ArgumentParser()
parser.add_argument("source", type=Path)
parser.add_argument("--compile", action="store_true")
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
catalog = json.loads(args.source.read_text(encoding="utf-8"))
draft = json.loads((root / "localization/interface-drafts.json").read_text(encoding="utf-8"))
for supplemental in sorted((root / "localization").glob("interface-*-drafts.json")):
    additions = json.loads(supplemental.read_text(encoding="utf-8"))["translations"]
    overlap = set(additions) & set(draft["translations"])
    if overlap:
        raise SystemExit(f"Duplicate translation keys in {supplemental.name}: {sorted(overlap)}")
    draft["translations"].update(additions)
placeholder = re.compile(r"%(?:\d+\$)?(?:lld|ld|d|u|f|@)")
missing = []
errors = []
for key, entry in catalog["strings"].items():
    if entry.get("shouldTranslate") is False or not key.strip():
        continue
    # Brand names and punctuation-only/numeric format strings are invariant.
    if key in {"PlanBridge", "PlanBridge AI", "PlanBridge Pro", "%lld", "%@ – %@", "%@ → %@"}:
        entry["shouldTranslate"] = False
        continue
    values = draft["translations"].get(key)
    if values is None:
        missing.append(key)
        continue
    if len(values) != len(draft["languages"]):
        errors.append(f"Wrong number of translations: {key}")
        continue
    for language, value in zip(draft["languages"], values):
        if not value.strip() or placeholder.findall(key) != placeholder.findall(value):
            errors.append(f"Invalid placeholders or empty text: {language}: {key}")
        entry.setdefault("localizations", {})[language] = {"stringUnit": {"state": "translated", "value": value}}

print(f"Languages: {', '.join(draft['languages'])}; missing source entries: {len(missing)}")
for key in missing:
    print("MISSING: " + key.replace("\n", "\\n"))
if errors:
    raise SystemExit("\n".join(errors))
if args.compile:
    if missing or draft["reviewStatus"] != "reviewed":
        raise SystemExit("Compilation blocked: complete coverage and reviewed status are required.")
    target = root / "App/Resources/Localizable.xcstrings"
    target.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("Compiled reviewed bundled translations; device-language selection is automatic.")
