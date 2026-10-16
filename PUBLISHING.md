# Publishing Stand Up

## GitHub test distribution

The project can be shared as source and as a DMG. Run `./script/package_dmg.sh` to build `dist/StandUp.app`, create `release/Stand-Up-0.4.0.dmg`, and write its SHA-256 checksum.

The current local package is ad hoc signed. It is suitable for testing on the developer's Mac. A tester may need to Control-click the app and choose Open, or approve it in System Settings → Privacy & Security after the first launch.

## Developer ID release

The public release path is implemented in `script/release_public.sh`. It performs these checks and actions:

1. Builds the Release app.
2. Signs the executable and app bundle with `Developer ID Application` and Hardened Runtime (`--options runtime`).
3. Creates a DMG, submits it to Apple with `xcrun notarytool`, waits for approval, and staples the ticket.
4. Runs `codesign`, `stapler validate`, `spctl`, and SHA-256 verification.

Before running it, install a Developer ID Application certificate in the login keychain and create a notarytool profile:

```sh
security find-identity -v -p codesigning
xcrun notarytool store-credentials StandUpNotary \
  --apple-id "YOUR_APPLE_ID" --team-id "YOUR_TEAM_ID" \
  --password "YOUR_APP_SPECIFIC_PASSWORD"
DEVELOPER_ID_APPLICATION="Developer ID Application: Your Name (TEAMID)" \
NOTARYTOOL_PROFILE=StandUpNotary \
./script/release_public.sh
```

The script intentionally stops when either credential is missing. The current Mac has no Developer ID identity or stored notarization profile, so its existing `0.4.0` DMG remains an ad hoc test package.

The Bundle ID in the current build is `local.demo.StandUp`; register that explicit identifier in the Apple Developer account before signing, or choose a stable identifier you control and plan a settings migration before changing it.

## Mac App Store path

The App Store build is a separate distribution configuration. It needs an Apple Distribution identity, a Mac App Store provisioning profile, App Sandbox entitlements, App Store Connect metadata, privacy disclosures, screenshots, support and privacy URLs, and an uploaded signed package. The current SwiftPM bundle uses local ad hoc signing and is not an App Store upload artifact.

The global input monitor, login item, notification behavior, and any system access must be tested under App Sandbox before submission. Do not claim App Store readiness until the signed archive passes validation and the app works with the selected entitlements.

## GitHub Release

After `script/release_public.sh` succeeds, commit the source changes, push `master`, and create the release with the notarized artifacts:

```sh
git tag -a v0.4.0 -m "Stand Up 0.4.0"
git push origin master v0.4.0
gh release create v0.4.0 release/Stand-Up-0.4.0.dmg \
  release/Stand-Up-0.4.0.dmg.sha256 --title "Stand Up 0.4.0" \
  --generate-notes
```

Only attach a DMG after notarization and `spctl -a -vv --type open` pass. Do not upload the local ad hoc DMG as a public release artifact.

## Required account work

1. Join the Apple Developer Program.
2. Register the Bundle ID `local.demo.StandUp`.
3. Create App Store and Developer ID certificates as needed.
4. Create the App Store Connect app record and reserve the `Stand Up` name.
5. Add the privacy policy, support URL, category, screenshots, description, and export-compliance answers.
6. Decide whether the App Store build uses a paid or free model.
