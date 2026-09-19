# Localization preparation

The app currently ships English text. Do not advertise other supported languages yet.

`Localizable.xcstrings` and `SWIFT_EMIT_LOC_STRINGS` enable Xcode's automatic extraction of localizable interface strings. The verification workflow exports English localization resources as `localization-source`. SwiftUI resolves bundled translations using the preferred supported device language and falls back to English. Reusable label views now look up their text as localization keys instead of displaying every value verbatim.

This is extraction and localization infrastructure, not an automatic translation service. A provider/credential decision and target-language selection are pending. No translation API has been called and no personal plan data has been sent anywhere.

Before enabling a locale:

1. Translate exported UI strings, permission prompts, static labels passed through arrays/custom views, and App Store metadata. Preserve placeholders and keep booking names and user-entered text unchanged.
2. Review transaction messages, billing intervals, plural forms, dynamic conflict explanations and natural-language question handling. The current local question engine uses English rules; translating its buttons does not make the engine multilingual.
3. Import reviewed translations into the String Catalog and enable only locales with complete coverage.
4. Capture and inspect the actual UI in that locale on iPhone and iPad, including long text, purchase/restore, and accessibility labels.
5. Upload matching localized screenshots and metadata. Recheck the selected release binary before submission.

Translation generation must operate only on public source copy. Runtime translation of personal bookings is a separate feature and has not been authorized or implemented.
