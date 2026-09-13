# Required verification on macOS / iPhone / iPad

Core automated tests are runnable on Windows or macOS. The following Apple-platform checks remain unexecuted in this Windows workspace.

1. `bash scripts/prepare-mac.sh`, then `xcodebuild -project PlanBridgeAI.xcodeproj -scheme PlanBridgeAI -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO build`. Fix SDK/compiler diagnostics before calling the app build verified.
2. Launch fresh: onboarding is shown, no personal data or external service is implied. Choose demo; all samples are marked. Switch to personal: samples disappear, no conflicts cross the boundary.
3. Add/edit/delete a booking. Restart and verify persistence. Test London DST transitions, differing departure/arrival zones and an overnight international journey. A negative interval must not save.
4. Deny calendar permission. Grant later in Settings. Select one calendar and confirm only it appears. Deselect all and confirm no cached calendar plans remain. Revoke system access while away, reopen and confirm removal. Changing an event should update the same occurrence where the provider's identifier remains stable.
5. Import `docs/example.ics`. Review without confirming; cancel and verify no save. Confirm and check fields. Test malformed UTF-8, >2 MB, recurrence, floating local dates, ambiguous fall-back and spring-forward gaps.
6. Trigger dinner vs train conflict. Check evidence, severity reason and source. Mark intentional; change a source time and confirm a fresh warning appears. Link a calendar item to a changed booking and review mismatch.
7. Test exact, missing and ambiguous addresses with Apple Maps, offline failures, route estimate expiry and preferred buffer changes.
8. Voice permission denied, unsupported on-device language, recognizer unavailable, audio interruption, background transition, rapid start/stop and earbuds removal. Verify transcripts disappear when leaving Ask and no session resumes after navigation/backgrounding.
9. Enable lock, background app, inspect app-switcher cover and reopen. Cancel authentication; data remains inaccessible. Test passcode fallback and storage opening before first device unlock.
10. Enable daily reminder and inspect private notification copy. Deny permission and verify preference/error. Clear data and confirm pending/delivered notifications and cached calendar records are removed. Export only via explicit action; temporary share file is cleaned after sheet dismissal.
11. Configure StoreKit sandbox products and real policy URLs; test purchase, cancel, pending, unverified result, renewal, expiry, refund, grace period and restore. Never grant Pro from an unverified transaction or a product outside the allowlist.
12. iPhone compact width / iPad landscape / split view / largest accessibility text / dark mode / VoiceOver. Check all buttons, headings, forms and tab navigation for clipping and legibility. Check the branded green's contrast against both system appearances.
13. Capture screenshots from the verified app using fictional data. Ensure marketing figures and claims agree with the actual captured screens. Final iPad assets are required for the iPad target.
