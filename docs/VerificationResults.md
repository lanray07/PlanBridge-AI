# Verification results · 13 September 2026

Environment: Windows, Swift 6.3.1, x86_64-unknown-windows-msvc.

| Check | Result |
| --- | --- |
| Foundation package compilation | Passed |
| XCTest scheduling/import suite | 22 passed, 0 failed |
| All 22 app Swift files, frontend syntax parse | Passed |
| Info.plist and privacy manifest XML parsing | Passed |
| Asset catalog Contents.json parsing | Passed |
| XcodeGen YAML parsing | Passed; not executed on macOS |
| Marketing assets | Eight PNGs present, each 1024×1536 |
| Gallery localhost HTTP request | 200 |
| iOS SDK type checking / link | Not run; requires Mac + Xcode |
| iPhone/iPad simulator / device behavior | Not run |
| StoreKit sandbox / signing / submission | Not run |

Test coverage includes overlap boundaries, hotel/all-day/cancelled exclusions, airport/restaurant buffer semantics, reliable route arithmetic and expiry, DST fall-back instants, cross-date-line overlaps, DST-aware tomorrow queries, destination-zone hotel checks, missing hotel nights, strict ICS failure modes, JSON provenance reset, explicit calendar-link changes, conditional calendar coverage and demo separation.

SwiftPM emitted a Windows symbolic-link warning for its `debug` convenience directory. It still compiled, linked and ran the XCTest binary successfully. Using a no-space scratch path worked around a separate SwiftPM output-map error for the workspace path.

The generated icon master is 1254×1254. A second image-tool resize request returned the same dimensions. The Mac preparation script performs the exact 1024×1024 build-resource conversion and preserves the master. That Mac conversion has not been executed here.

Humanised visuals were inspected inline for the requested subjects, headline legibility, evidence cards and demo labelling. They remain campaign concepts: some logo treatments and incidental environmental text vary across images. Final creative production must standardise those details and use validated app captures.
# GitHub Xcode verification — 13 September 2026

GitHub run 34734882315 built with Xcode 26.3, passed the Swift core tests and passed the native iPhone 16 Pro UI test that opens Settings > Explore PlanBridge Pro. Actual screenshots are retained in marketing/native-subscription-review and uploaded to the monthly and annual subscription review fields. The screen correctly reports products unavailable in that simulator session; this is not a verified StoreKit purchase transaction.

The initial archive failed because automatic development provisioning required a registered device. Deferring signing to App Store export resolved provisioning. Apple then required all four iPad multitasking orientations; an iPad-specific Info.plist entry fixed validation. Release run 34735547650 successfully archived, signed and uploaded version 1.0.0 build 5. App Store processing and release readiness are separate from upload success.
