# TestFlight Distribution Notes

Batch 28 brings the repository to a truthful distribution-prepared state without pretending Apple-account-controlled steps are already complete.

## What is already validated

- SwiftPM package build/test remains green.
- `DHCharListHost` builds in Xcode for `generic/platform=iOS Simulator`.
- `DHCharListHost` Release build succeeds for `generic/platform=iOS` with signing disabled.
- `DHCharListHost` archive succeeds for `generic/platform=iOS` with signing disabled.
- Archive metadata was inspected directly:
  - `CFBundleIdentifier = com.example.DHCharListHost`
  - `CFBundleShortVersionString = 1.0`
  - `CFBundleVersion = 1`
  - `SigningIdentity = ""`
  - `Team = ""`
- Export probing against that archive fails with the exact expected manual-signing boundary:
  - `error: exportArchive No Team Found in Archive`

This means the app is structurally archive-ready, but real TestFlight distribution still depends on local Apple signing context.

## Current committed distribution baseline

- host app project: `DHCharListHost/DHCharListHost.xcodeproj`
- shared scheme: `DHCharListHost`
- signing style: Automatic
- committed team identifier: none
- committed app bundle identifier: `com.example.DHCharListHost`
- committed display name: `DH CharList`
- committed version/build: `1.0` / `1`
- app icons: placeholder light/dark/tinted 1024 assets only

## Manual steps required before real TestFlight upload

1. Replace the placeholder bundle identifier `com.example.DHCharListHost` with your real production identifier.
2. In Xcode `Signing & Capabilities`, select your Apple Developer team for `DHCharListHost`.
3. Ensure the App Store Connect app record exists for that bundle identifier.
4. Replace the placeholder AppIcon assets with final branded assets if you are preparing a real external build.
5. Bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` for the release you intend to upload.
6. Create a signed archive with your local signing context.
7. Export/upload with Organizer or `xcodebuild -exportArchive` using a real team ID and signing context.
8. Complete TestFlight/App Store Connect metadata outside the repo as needed.

## Validated commands

SwiftPM validation:

```bash
swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build
swift build --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build
```

Xcode build validation:

```bash
xcodebuild \
  -project DHCharListHost/DHCharListHost.xcodeproj \
  -scheme DHCharListHost \
  -configuration Debug \
  -destination 'generic/platform=iOS Simulator' \
  build
```

Unsigned Release build validation:

```bash
xcodebuild \
  -project DHCharListHost/DHCharListHost.xcodeproj \
  -scheme DHCharListHost \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  build \
  CODE_SIGNING_ALLOWED=NO
```

Unsigned archive validation:

```bash
xcodebuild \
  -project DHCharListHost/DHCharListHost.xcodeproj \
  -scheme DHCharListHost \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  archive \
  -archivePath /tmp/DHCharListHost-Batch28.xcarchive \
  CODE_SIGNING_ALLOWED=NO
```

Archive metadata inspection:

```bash
plutil -p /tmp/DHCharListHost-Batch28.xcarchive/Info.plist
```

## Practical signed archive/export path

Archive from Xcode:

1. Open `DHCharListHost/DHCharListHost.xcodeproj`.
2. Select scheme `DHCharListHost`.
3. Set destination to `Any iOS Device (arm64)`.
4. Confirm your real team and bundle identifier are configured.
5. Run `Product > Archive`.
6. Use Organizer to validate/upload to TestFlight.

Archive from CLI after signing is configured locally:

```bash
xcodebuild \
  -project DHCharListHost/DHCharListHost.xcodeproj \
  -scheme DHCharListHost \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  archive \
  -archivePath /tmp/DHCharListHost-Release.xcarchive \
  -allowProvisioningUpdates
```

Example export options template:

- `Docs/testflight-export-options.example.plist`

Example export after signing is configured locally:

```bash
xcodebuild \
  -exportArchive \
  -archivePath /tmp/DHCharListHost-Release.xcarchive \
  -exportPath /tmp/DHCharListHost-TestFlight-export \
  -exportOptionsPlist Docs/testflight-export-options.example.plist \
  -allowProvisioningUpdates
```

If you use CLI upload instead of Organizer, you still need one of:

- an Apple ID account already added to Xcode with access to the selected team
- or an App Store Connect authentication key passed via `-authenticationKeyPath`, `-authenticationKeyID`, and `-authenticationKeyIssuerID`

## Truthful state after Batch 28

- archive-ready: yes
- signed export validated here: no
- TestFlight-ready: not yet
- TestFlight-prepared with exact manual finish line: yes
