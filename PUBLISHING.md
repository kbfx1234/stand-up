# Publishing Stand Up

## GitHub test distribution

The project can be shared as source and as a DMG. Run `./script/package_dmg.sh` to build `dist/StandUp.app`, create `release/Stand-Up-0.3.2.dmg`, and write its SHA-256 checksum.

The current local package is ad hoc signed. It is suitable for testing on the developer's Mac. A tester may need to Control-click the app and choose Open, or approve it in System Settings → Privacy & Security after the first launch.

For public distribution without that warning, sign the app with a Developer ID Application certificate, enable Hardened Runtime, notarize the DMG or ZIP with `xcrun notarytool`, staple the ticket, and verify with `spctl`.

## Mac App Store path

The App Store build is a separate distribution configuration. It needs an Apple Distribution identity, a Mac App Store provisioning profile, App Sandbox entitlements, App Store Connect metadata, privacy disclosures, screenshots, support and privacy URLs, and an uploaded signed package. The current SwiftPM bundle uses local ad hoc signing and is not an App Store upload artifact.

The global input monitor, login item, notification behavior, and any system access must be tested under App Sandbox before submission. Do not claim App Store readiness until the signed archive passes validation and the app works with the selected entitlements.

## Required account work

1. Join the Apple Developer Program.
2. Register the Bundle ID `local.demo.StandUp`.
3. Create App Store and Developer ID certificates as needed.
4. Create the App Store Connect app record and reserve the `Stand Up` name.
5. Add the privacy policy, support URL, category, screenshots, description, and export-compliance answers.
6. Decide whether the App Store build uses a paid or free model.
