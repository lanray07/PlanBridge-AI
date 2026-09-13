# PlanBridge AI

**Catch conflicts before they disrupt your plans.**

Native iPhone/iPad development build: SwiftUI, a tested deterministic scheduling core, selected EventKit calendars, reviewed booking imports, trip checks, private on-device voice, SwiftData storage and StoreKit 2 infrastructure.

## Start here

- [Support](SUPPORT.md) and [Privacy policy](PRIVACY.md).

- Open `marketing/index.html` for the eight humanised campaign concepts.
- Read `docs/Architecture.md` for implemented behavior and remaining release work.
- Read `docs/DeviceVerification.md` before distributing a build.

## Run on a Mac

Requires Xcode with the iOS 17+ SDK, Swift 6 and XcodeGen.

```sh
brew install xcodegen
bash scripts/prepare-mac.sh
open PlanBridgeAI.xcodeproj
```

Choose a simulator, or set your own signing team and bundle identifier for a physical device. `prepare-mac.sh` converts the generated icon master to Apple's exact 1024×1024 resource size and generates the Xcode project. No signing credentials are stored here.

## Test the core

```sh
swift test
```

Windows paths with spaces can trigger a SwiftPM output-map error. Use a scratch path without spaces:

```powershell
swift test --scratch-path C:/Users/User/.codex/builds/PlanBridgeAI
```

All 22 core tests passed, and the Xcode 26.3 compilation workflow passes. Release run 34735547650 uploaded version 1.0.0 build 5. Later native tests load both products and capture the priced paywall, but purchase/restore assertions still fail in the hosted simulator, including run 34738753910 with 90-second waits. The release gate prevents uploading those unvalidated changes. Build 5 remains the latest confirmed upload. See [StoreKit validation](docs/StoreKitValidation.md).

## Data and integrations

Personal mode starts empty. Demo mode is explicit and separate. Connect only selected Apple calendars or add/import your own bookings. ICS import rejects unsupported recurrence, custom time zones and ambiguous timestamps; it never silently saves extraction results. Structured JSON import accepts an array of the Codable `PlanItem` schema with ISO-8601 timestamps; a full export is a `PlanArchive` for inspection, not currently an automatic restore file.

No live airline, rail, hotel, restaurant or email integration exists. The app says so. Driving estimates are requested explicitly from Apple Maps using the supplied locations. “AI” answers currently use local evidence-grounded language rules; no LLM or backend is connected.

## StoreKit setup

Product IDs: `com.planbridge.ai.pro.monthly`, `com.planbridge.ai.pro.annual`. Both products are configured in App Store Connect. Public terms and privacy URLs are configured in `ReleaseConfiguration`, enabling the purchase buttons when StoreKit returns products. Names and prices come from StoreKit; no trial is advertised. `UITests/PlanBridge.storekit` is a test-only local catalogue; production builds use App Store Connect products. The release workflow tests purchases, restart recovery, restore and empty restore before uploading.

This version grants Pro voice queries and unlimited trip checks. Three trip checks are locally free. All privacy controls are free. The broader proposed premium integrations and widgets are not represented as available products.

## Artwork

Eight full-resolution **development concepts** live in `marketing/concepts`. They are 1024×1536 PNGs with demo labels, not final App Store screenshot exports. `marketing/prompts.json` records built-in image generation prompts and original asset paths. The app includes a generated onboarding photo and icon master.

Before release, create screenshots from a verified native build and align the marketing cards with actual UI. Draft iPhone/iPad exports and subscription promotional artwork have been uploaded to App Store Connect. Nothing has been submitted for review. See `docs/AppStoreConnectStatus.md` for remaining requirements.

The supplied brief is preserved in `docs/OriginalBrief.txt`; it ends after the word “Create” in section 35.
