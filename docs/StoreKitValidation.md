# StoreKit validation status — 19 September 2026

## Latest result

[Run 35457681244](https://github.com/lanray07/PlanBridge-AI/actions/runs/35457681244), source aafa487, passed all 22 core tests and the full monthly/annual purchase, restart recovery, restore and empty-restore UI test. Archive, upload and export succeeded for version 1.0.0 build 15. The test now terminates the installed app before resetting StoreKit, avoiding overlap with its startup entitlement request, and stops on its first failure. No purchase assertion was removed. This passing run supports the test-setup race hypothesis; it is not evidence of a production StoreKit service defect.

Build 15 supersedes build 5 as the latest confirmed upload. Newer screenshot wording and localization preparation are separate changes that still require their own release verification. Nothing has been submitted for App Review.

## Completed

- Public terms link to Apple's Standard EULA and explain subscription billing. Terms and privacy links are wired into the app and saved in the listing description.
- App Store Connect products use GBP 2.99/month and GBP 24.99/year upfront, with Apple's regional equivalents. Both have all current territories selected.
- Native product loading works. The unedited priced paywall capture is [subscription-priced.png](../marketing/native-subscription-review/subscription-priced.png). Both prices, periods, restore and legal links appear.
- Both subscription review screenshots were replaced with the priced native capture, and both saves completed. Both retain promotional artwork. Their review notes identify the unresolved transaction validation; the temporary App Store Connect sign-out was resolved.
- Product loading now runs independently of receipt synchronization. Purchases show an App Store progress indicator.
- Core tests and Xcode 26.3 compilation pass.

## Historical failures

[Run 34738753910](https://github.com/lanray07/PlanBridge-AI/actions/runs/34738753910), source 11e1a1b, failed native monthly and annual purchase, restart recovery and restore assertions with 90-second waits. The empty-restore check passed. An earlier Xcode 16.4 run passed the annual path but failed monthly; this has not been reliable enough to call validated.

Diagnostics show StoreKit test mode enabled and product loading succeeding, but transactions do not consistently complete. Earlier logs contain receipt synchronization and AppleMediaServices token/network errors. The precise cause remains unresolved; increasing the wait did not solve it. No purchase success is inferred from a screenshot or successful compilation.

Tests use an explicit StoreKit test plan, ad hoc simulator signing, Xcode 16.4 and iOS 18.5. The upload step switches to Xcode 26.3 and runs only after tests pass. Test records are local simulator records; no real payment is made.

No updated build was uploaded by those failing runs. Build 5 contained the earlier disabled-purchase configuration; it has now been superseded by build 15 above.

## Next work

Validate the selected binary in TestFlight/sandbox and complete the remaining screenshot, localization and app-level privacy/availability checks before App Review.
