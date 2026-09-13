# StoreKit validation status — 13 September 2026

## Completed

- Public terms link to Apple's Standard EULA and explain subscription billing. Terms and privacy links are wired into the app and saved in the listing description.
- App Store Connect products use GBP 2.99/month and GBP 24.99/year upfront, with Apple's regional equivalents. Both have all current territories selected.
- Native product loading works. The unedited priced paywall capture is [subscription-priced.png](../marketing/native-subscription-review/subscription-priced.png). Both prices, periods, restore and legal links appear.
- The monthly review screenshot was replaced and Save returned disabled before App Store Connect signed out. The annual record still has the previous native review capture; both retain promotional artwork.
- Product loading now runs independently of receipt synchronization. Purchases show an App Store progress indicator.
- Core tests and Xcode 26.3 compilation pass.

## Release blocker

[Run 34738753910](https://github.com/lanray07/PlanBridge-AI/actions/runs/34738753910), source 11e1a1b, failed native monthly and annual purchase, restart recovery and restore assertions with 90-second waits. The empty-restore check passed. An earlier Xcode 16.4 run passed the annual path but failed monthly; this has not been reliable enough to call validated.

Diagnostics show StoreKit test mode enabled and product loading succeeding, but transactions do not consistently complete. Earlier logs contain receipt synchronization and AppleMediaServices token/network errors. The precise cause remains unresolved; increasing the wait did not solve it. No purchase success is inferred from a screenshot or successful compilation.

Tests use an explicit StoreKit test plan, ad hoc simulator signing, Xcode 16.4 and iOS 18.5. The upload step switches to Xcode 26.3 and runs only after tests pass. Test records are local simulator records; no real payment is made.

No updated build was uploaded by these failing runs. Version 1.0.0 build 5 remains the latest confirmed upload and still contains the earlier disabled-purchase configuration. Nothing was submitted for App Review.

## Next work

Restore the App Store Connect browser session, finish the annual screenshot update, and reproduce purchase/restore using an interactive native StoreKit or device sandbox session. Resolve the transaction failure before dispatching another release upload. Product-page illustrative screenshots and app-level privacy/availability details also need final release validation.
