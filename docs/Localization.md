# Localization preparation

The app currently ships English text. Do not advertise other supported languages yet.

`Localizable.xcstrings` and `SWIFT_EMIT_LOC_STRINGS` enable Xcode's automatic extraction of localizable interface strings. The verification workflow exports English localization resources as `localization-source`. SwiftUI resolves bundled translations using the preferred supported device language and falls back to English. Reusable label views now look up their text as localization keys instead of displaying every value verbatim.

The selected cost-free approach is bundled, AI-assisted translation drafting with automatic device-language selection. It has no translation API or per-user translation fee. Draft locales are French, Spanish and German; English remains the shipping language until coverage and review are complete. No translation API has been called and no personal plan data has been sent anywhere.

`localization/interface-drafts.json` and its detail/disclosure supplements contain French, Spanish and German drafts for every translatable entry in the Xcode export from run 35457762061. `scripts/prepare-localizations.py <exported Localizable.xcstrings>` reports missing source entries and checks placeholder order. Adding `--compile` refuses incomplete or unreviewed translations, then generates the bundled catalog only when both checks pass. This avoids presenting a partially translated app as a finished localization. The automatic export does not detect every dynamic or custom-view string; those call sites still need review. Exported-string coverage alone is not whole-app localization coverage.

Before enabling a locale:

1. Translate exported UI strings, permission prompts, static labels passed through arrays/custom views, and App Store metadata. Preserve placeholders and keep booking names and user-entered text unchanged.
2. Review transaction messages, billing intervals, plural forms, dynamic conflict explanations and natural-language question handling. The current local question engine uses English rules; translating its buttons does not make the engine multilingual.
3. Import reviewed translations into the String Catalog and enable only locales with complete coverage.
4. Capture and inspect the actual UI in that locale on iPhone and iPad, including long text, purchase/restore, and accessibility labels.
5. Upload matching localized screenshots and metadata. Recheck the selected release binary before submission.

Translation generation must operate only on public source copy. Runtime translation of personal bookings is a separate feature and has not been authorized or implemented.
