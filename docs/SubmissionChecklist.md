# Submission requirements

No final App Review submission until every item below is verified against the selected binary.

- Purchase, restart recovery, restore and empty restore pass. Repeated runs on source 79a5eb4 still fail; build 5 is not a replacement for these checks.
- Every screenshot shows the actual shipping UI, uses a relevant keyword naturally, and matches its device size and locale. Illustrative concepts are not final screenshots.
- Localized UI uses the device's preferred supported language with an English fallback. Translation generation is distinct from language selection. Translations, placeholders, permission prompts, purchase disclosures and layouts require review.
- Localized App Store descriptions and keyword fields match implemented features. Do not claim live integrations, cloud AI or translated natural-language answers that the build does not provide.
- Store descriptions, subtitle and keywords meet Apple's limits; screenshot headlines describe the visible feature. No ranking guarantee is implied.
- App privacy, content rights, distribution availability, legal links and review details are complete.

The versioned English copy and screenshot keyword map are in `marketing/store/en-GB.json`. A draft file is not evidence that it has been saved in App Store Connect.

References: [Apple product-page guidance](https://developer.apple.com/app-store/product-page/), [localized app information](https://developer.apple.com/help/app-store-connect/manage-app-information/localize-app-information), [String Catalogs](https://developer.apple.com/documentation/xcode/localizing-and-varying-text-with-a-string-catalog).
