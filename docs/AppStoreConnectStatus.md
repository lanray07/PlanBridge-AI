# App Store Connect preparation

Updated 13 September 2026. App remains Prepare for Submission. Nothing was submitted for review or released.

## App identity

- App: PlanBridge AI
- Apple ID: 6811447442
- Bundle ID: com.PlanBridgeAI.app
- SKU: PLANBRIDGEAI-IOS-001
- Version: 1.0
- Primary localization: English (U.K.)

## Saved metadata and assets

- Subtitle: Calendar & Booking Monitor
- Primary category: Productivity; secondary: Travel
- Age questionnaire saved; global rating 4+
- Promotional text, description, keywords and review notes saved. Copy describes current implementation limits, including no live provider or cloud AI connection.
- Sign-in required is off.
- Eight images uploaded to the iPhone 6.5-inch slot, 1242 x 2688 RGB PNG.
- Eight images uploaded to the iPad 13-inch slot, 2048 x 2732 RGB PNG.
- Both device sets ordered: conflicts, timeline, changes, connections, voice, morning, trip, privacy.
- Artwork is labelled illustrative demo material, not native build captures. Validate or replace with accurate native screenshots before submission.
- Original artwork is preserved. Exact-size exports are under marketing/app-store-drafts; regenerate with scripts/prepare-store-assets.py. User expressly authorized standard image resizing.

## Subscriptions

Group PlanBridge Pro, ID 22380859. English (U.K.) group display name saved. Both products are service level 1, with the same benefits.

| Product | Product identifier | Apple ID | Duration |
| --- | --- | --- | --- |
| PlanBridge Pro Monthly | com.planbridge.ai.pro.monthly | 6811483981 | 1 month |
| PlanBridge Pro Annual | com.planbridge.ai.pro.annual | 6811484978 | 1 year upfront |

Both have English (U.K.) names and the description: Unlimited trip checks and on-device voice questions.

Both have review notes and the accepted 1024 x 1024 promotional image marketing/app-store-drafts/subscriptions/planbridge-pro-1024.png. Promotional artwork was not used as an in-app purchase review screenshot.

## Still required

- App-level distribution availability.
- Final App Privacy disclosures and content-rights information.
- Resolve purchase/restore transaction failures in native tests; see [StoreKit validation](StoreKitValidation.md). Product loading and a priced native screenshot are now available.
- Final validation of marketing claims and screenshot accuracy against that build.

Public terms and privacy URLs are configured in source. Both subscription products have all current countries/regions selected. No family sharing or monthly-with-12-month-commitment option was enabled. Copyright is populated in App Store Connect.

The user supplied review contact details, which were saved successfully in App Store Connect along with the pending review notes. Contact details are not copied into this public repository.

## Launch pricing

User authorized competitive pricing. UK base prices selected on 13 September 2026: GBP 2.99 per month and GBP 24.99 per year upfront. Annual billing saves GBP 10.89 (about 30.4%) compared with twelve monthly payments. Apple's generated equivalents cover 175 price regions, including USD 2.99/month and USD 24.99/year in the US. Price schedules do not by themselves configure territory availability or submit the products for review.

Pricing reflects the current limited Pro benefits. Benchmark: [TripIt Pro](https://www.tripit.com/web/pro/pricing) advertises USD 49/year with additional travel services. No introductory trial or promotional discount was configured.

## GitHub publication

The project was pushed to https://github.com/lanray07/PlanBridge-AI on main. Public pages were verified without authentication:

- Support: https://github.com/lanray07/PlanBridge-AI/blob/main/SUPPORT.md
- Privacy: https://github.com/lanray07/PlanBridge-AI/blob/main/PRIVACY.md
- Marketing: https://github.com/lanray07/PlanBridge-AI

All three URLs were saved in App Store Connect. Public [terms](https://github.com/lanray07/PlanBridge-AI/blob/main/TERMS.md) now link to Apple's Standard EULA and explain subscription billing. Terms and privacy links are included in the app and listing description.

## Native build and subscription assets

Xcode 26.3 core and simulator UI tests passed in run 34734882315. Both subscription review fields were subsequently updated to the priced native capture from run 34737813698. Both retain the promotional image. Updated terms, availability and accurate validation notes are saved; transaction validation remains blocked as detailed in [StoreKit validation](StoreKitValidation.md).

[Release run 34735547650](https://github.com/lanray07/PlanBridge-AI/actions/runs/34735547650) succeeded: version 1.0.0, build 5, source efc5dc4. Xcode reported ARCHIVE SUCCEEDED, Upload succeeded (100%), and EXPORT SUCCEEDED. Secrets remained on the GitHub runner. Signing is performed during App Store export using the existing API key. No App Review submission or public release was performed.
