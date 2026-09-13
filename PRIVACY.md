# PlanBridge AI privacy policy

Last updated: 13 September 2026.

This policy describes the PlanBridge AI implementation maintained in this repository by the GitHub account [lanray07](https://github.com/lanray07). The app is currently in development. This policy will be updated if the released app's data handling changes.

## Plans and calendars

Plans you enter, reviewed imports, selected calendar events, trips and conflict decisions are stored locally on your device. Calendar access is optional and requires your permission. The app reads selected calendars to compare plans; it does not change provider reservations. Its local plan database is configured to use iOS file protection, is excluded from app backups, and does not use CloudKit sync. Device preferences such as selected calendars and app-lock settings are stored locally.

There is no PlanBridge server, account system, advertising SDK, analytics SDK, email integration or cloud AI service in this implementation. We do not receive, sell or use your itinerary for advertising. Answers are generated locally from available plan information.

## Voice and device authentication

Voice queries require microphone and speech permissions. Recognition is configured to run on-device and is unavailable when the device or language does not support that mode. Audio and question transcripts are not saved persistently by the app. Typed questions remain available. Optional app locking uses Apple's device authentication; PlanBridge does not receive biometric templates.

## Apple services

If you request a driving estimate, the supplied origin and destination names, addresses or coordinates are sent to Apple's geocoding and Maps services to resolve locations and calculate a route. This does not require a PlanBridge account. Apple processes this information under its own policies.

Apple handles App Store purchases, billing and subscription management. The app uses StoreKit transaction information to determine Pro access; it does not receive your payment-card details. Apple may process App Store, diagnostics and service information according to your device settings and [Apple's privacy policy](https://www.apple.com/legal/privacy/).

## Notifications, export and deletion

Notifications are scheduled locally. Private notification settings can limit the details displayed. Export creates a file that is shared only with the destination you select; that destination's policies apply. Delete all data clears local plans, trips, changes, imports and decisions. Disconnect removes cached calendar events. You can revoke calendar, microphone and speech permissions in iOS Settings. Copies you export outside the app are not removed by in-app deletion.

## Support and this website

The repository and support issues are hosted by GitHub under [GitHub's privacy statement](https://docs.github.com/en/site-policy/privacy-policies/github-general-privacy-statement). If you choose to open a support issue, your GitHub identity and the content you post are visible publicly and may be used by maintainers to respond. Do not post private itineraries or personal documents. For a privacy question, [open an issue](https://github.com/lanray07/PlanBridge-AI/issues) describing the question without sensitive details.

[Support](SUPPORT.md)
