# PlanBridge architecture and release status

This repository contains a native SwiftUI implementation and a separately compiled Swift package. It is a development build, not a signed or App Store-verified release.

## Data flow

Manual entry / reviewed ICS or JSON / selected EventKit calendars → canonical `PlanItem` instants and source zones → `PlanConflictEngine` → structured evidence → local `PlanBridgeAIService` → views, typed questions, on-device voice and private notifications.

`PlanBridgeAIService` is a deterministic language implementation, not a connected LLM. It never decides overlap arithmetic. It exposes all seven service functions in the brief. A future LLM adapter can consume evidence under explicit consent, with fixed instructions prohibiting invented times, routes, source access and booking changes. No API key is required by this build.

## Implementation map

| Area | Current behavior |
| --- | --- |
| Native UI | Six-step onboarding; Today; timeline/search; conflict evidence; booking editor; trips; Ask; connections; settings; paywall |
| Storage | SwiftData envelope of versioned Codable archive, device file protection, excluded from backup, no CloudKit |
| Calendar | EventKit full access prompt, explicit calendar selection, 90-day successful-coverage window, foreground refresh, disconnect removes cached events |
| Booking input | Manual; strict ICS subset; structured PlanItem JSON array; explicit review before saving |
| Conflict checks | Overlap, arrival, buffers, driving route estimates, departure, location review, date mismatch, missing-night gaps, explicit-link time mismatch/stale calendar, reference-based duplicate candidates, missing linked calendar item, tight connections |
| Voice | Push-to-talk Speech framework, on-device capability required, typed fallback, optional spoken answers, raw audio and transcripts not persisted |
| Siri | One App Shortcut opens the authenticated app; does not speak private details on the lock screen |
| Changes | Start/end comparisons of saved observations; live airline/rail/hotel state is unavailable |
| Privacy | Device authentication, background cover, export/share cleanup, deletion, calendar disconnect, private alerts; keychain adapter reserved for future tokens |
| Subscriptions | Verified StoreKit 2 transactions, listener, entitlement refresh, dynamic product price, restore; purchase UI disabled until real legal URLs supplied |
| Commercial scope | Voice and unlimited trip checks are Pro; three local free trip checks. Core checks, buffers and privacy currently remain free. Further tiers from the brief are not marketed as implemented |
| Artwork | Eight 1024×1536 humanised concept PNGs, generated icon master and onboarding photo. Concepts are visibly marked DEMO DATA |

## Correctness boundaries

Absolute `Date` values drive duration comparisons. Each endpoint retains an IANA zone. Hotel night boundaries use the hotel's zone. Local ICS timestamps in missing or ambiguous DST hours are rejected; users must supply UTC. ICS recurrence/custom time zones are routed to Apple Calendar instead of partially imported. Date-only ICS values without an explicit time zone are not accepted.

Explicit booking-calendar links are required to assert a mismatch. Title similarity does not prove identity. A missing calendar warning is only eligible after a successful selected-calendar fetch, only within the checked interval, and says an unlinked event might exist. Hotel/all-day durations do not create normal overlaps. Cancelled and invalid records are excluded. Demo and personal plans never compare.

Apple Maps driving routes are user-triggered, require supplied locations, reject ambiguous geocoding, include source and freshness, and expire after an hour. There is no public-transport route prediction in this build. Airport/restaurant/train buffers are preferences, not objective minimum transfer times.

## Remaining production work

1. Run the macOS build and device test checklist. Only the Foundation core has been type-checked and tested here; Apple framework files have passed syntax parsing, not SDK type checking.
2. Complete automated iPhone/iPad UI coverage, VoiceOver/Dynamic Type, privacy cover timing, speech interruptions/permission revocation, SwiftData file protection and migration tests.
3. Add real publisher identifiers, signing team, support email, public legal URLs, StoreKit products and sandbox subscription tests. Review export compliance and App Privacy responses against the final binary.
4. Replace concept evidence cards with verified app captures and export the required iPhone/iPad dimensions. Do not upload the concepts as final screenshots.
5. Extend source history beyond time changes: status, location, provider revisions and retention limits. Add occurrence reconciliation for calendar providers that replace identifiers when changing an event.
6. Add comprehensive itinerary checks for trips without any accommodation, origin-to-final-return coverage, intentional overnight travel and open-ended bookings. Present unknown coverage explicitly.
7. PDF/image extraction, authorised email integration and external live data providers require real adapters, extraction review and credentials. They are deliberately unavailable in Connections.
8. Add opt-in background refresh using BackgroundTasks only after foreground sync and private alerts are device-verified. iOS does not guarantee execution time. A daily reminder currently invites the user to open the app and never claims a check ran in the background.

## Optional extensions

WidgetKit: share a minimal, opt-in summary through an App Group; default to generic counts with no itinerary. Reload after committed saves and clear snapshots on disconnect/delete. Real-time state must retain last-checked metadata.

Apple Watch: read-only summary and explicit queries using a WatchConnectivity snapshot from the phone. Preserve the same evidence IDs and source freshness. Never imply the Watch is independently connected to providers.

ActivityKit: only start a user-selected journey activity with sourced schedule information. It is not a flight tracking substitute. End at trip completion or disconnect. No activity is currently registered.

These are architectural extension points, not shipped targets or claimed integrations.

## Primary documentation consulted

- [EventKit calendar access](https://developer.apple.com/documentation/technotes/tn3152-migrating-to-the-latest-calendar-access-levels)
- [On-device recognition capability](https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportsondevicerecognition)
- [StoreKit current entitlements](https://developer.apple.com/documentation/storekit/transaction/currententitlements)
- [SwiftData configuration](https://developer.apple.com/documentation/swiftdata/modelconfiguration)
- [App Store screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications)
