# Premium App Store screenshots

These images combine real PlanBridge AI XCTest captures with a generated abstract background and deterministic typography. The workflow keeps every product claim tied to visible app UI while giving the App Store gallery a consistent campaign design.

## Production

1. Run `.github/workflows/screenshots.yml` with the English language option.
2. Download the `iphone-69` and `ipad-13` screenshot artifacts.
3. Compose each set with `scripts/compose-premium-screenshots.py`.
4. Verify ten RGB PNG files at 1320×2868 for iPhone and 2048×2732 for iPad.

The source background is `backgrounds/planbridge-premium-master.png`. It was generated for this campaign as an ivory, forest-green, sage and amber abstract backdrop with no text, logo, device or product UI. Headlines, subheads, app icon and native UI captures are composited locally so all wording and interface details remain exact.

The intended gallery order is the numeric filename order, from `01-calendar-planner.png` through `10-planbridge-pro.png`.
