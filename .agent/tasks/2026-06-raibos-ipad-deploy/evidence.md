# Evidence

## Summary

Overall result: PASS. Code changes, automated checks, physical iPad build, install, and launch completed.

## AC1 - Updated main

Status: PASS.

- `git pull --ff-only origin main` completed before implementation and fast-forwarded local `main` to `0b41f28`.
- Current HEAD evidence: `raw/git-head.txt` shows `0b41f28 (HEAD -> main, origin/main, origin/HEAD) Correct Raibos imported character data`.
- Pre-change status was clean; current pre-commit status is recorded in `raw/git-status-before-commit.txt` and only contains intentional task changes.

## AC2 - Райбос included in iOS roster path

Status: PASS.

- Added `Sources/DHCharList/Application/RaibosCharacterSeed.swift`.
- Added `RaibosCharacterSeedBootstrap`, which lists existing persisted characters and upserts `Райбос-2 Д-2` only when no matching Райбос character exists.
- Wired host startup in `DHCharListHost/DHCharListHost/DHCharListHostApp.swift` to run the non-destructive bootstrap outside UI-test-only reset/seed paths.
- Focused tests in `Tests/DHCharListTests/RaibosCharacterSeedTests.swift` prove seed data, missing-roster insert, no duplicate when Райбос already exists, and marker skip behavior.

## AC3 - Automated checks

Status: PASS.

- `swift test --disable-sandbox --package-path /Users/an.artemenko/repos/DH_charlist --build-path /tmp/dh_charlist-build --filter Raibos`
  - Final result: exit 0.
  - Raw log: `raw/focused-raibos-2.txt`.
- `make test`
  - Result: exit 0, 207 Swift tests passed.
  - Raw log: `raw/make-test.txt`.
- `make ci`
  - Initial result: failed because the required iOS 26.5 runtime was missing.
  - Raw log: `raw/make-ci.txt`.
- `xcodebuild -downloadPlatform iOS -buildVersion 26.5 -architectureVariant arm64`
  - Result: exit 0, installed iOS 26.5 simulator/runtime support.
  - Raw log: `raw/download-platform-ios-26-5.txt`.
- Fresh `make ci` after installing iOS 26.5
  - Result: exit 0.
  - Swift tests: 207 passed.
  - Xcode generic iOS simulator build: passed.
  - Xcode UI coverage run: 16 tests, 0 failures.
  - Coverage policy: passed; package coverage 26.41% vs 19.09% required minimum.
  - Raw log: `raw/make-ci-after-ios-26-5.txt`.

## AC4 - Physical iPad install

Status: PASS.

- Connected device evidence: `raw/devicectl-devices.txt` shows `iPad (Андрей)` available and paired, CoreDevice identifier `90DEFFEE-3BF3-59C6-A8D2-B29632AC0998`.
- First device build command failed with exit 65 because `DHCharListHost` has no development team configured.
  - Raw log: `raw/xcodebuild-device-ipad-2.txt`.
- Retry with the locally available team ID and automatic signing failed with exit 65:
  - Xcode reported `No Account for Team "J7NPK94U5Y"`.
  - Xcode reported no iOS App Development provisioning profile for `com.example.DHCharListHost`.
  - Raw log: `raw/xcodebuild-device-ipad-3.txt`.
- Explicit Personal Team retry with `DEVELOPMENT_TEAM=J7NPK94U5Y CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates -allowProvisioningDeviceRegistration` failed with exit 65 for the same account/profile reason.
  - Raw log: `raw/xcodebuild-device-ipad-4-personal-team.txt`.
- Retry after the user reported the Apple account was added also failed with exit 65 for the same account/profile reason.
  - Raw log: `raw/xcodebuild-device-ipad-5-after-account.txt`.
- Local Xcode signing state after the Personal Team retry shows no local provisioning profiles and empty Xcode provisioning team mappings.
  - Raw log: `raw/xcode-local-signing-state-after-personal-team.txt`.
- Local Xcode CLI state after the user-reported account addition still shows `/Applications/Xcode.app/Contents/Developer`, no alternate Xcode.app, zero local provisioning profiles, and empty Xcode provisioning team mappings.
  - Raw log: `raw/xcode-cli-state-after-account-ready.txt`.
- Local provisioning profile check: `raw/provisioning-profile-dir-check.txt` shows `NO_PROFILE_DIR`.
- Xcode account settings showed the real Personal Team ID as `Y8QK9BKTCW`, not `J7NPK94U5Y`.
  - Raw log: `raw/xcode-signing-state-after-y8q-build.txt`.
- Device build with `DEVELOPMENT_TEAM=Y8QK9BKTCW CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates -allowProvisioningDeviceRegistration` succeeded.
  - Raw log: `raw/xcodebuild-device-ipad-8-personal-team-y8q.txt`.
  - Signing identity: `Apple Development: artemenko.nsk@gmail.com (J7NPK94U5Y)`.
  - Provisioning profile: `iOS Team Provisioning Profile: com.example.DHCharListHost`.
  - App bundle path: `/tmp/dh_charlist-device-build/Build/Products/Debug-iphoneos/DHCharListHost.app`.
- `xcrun devicectl device install app --device 90DEFFEE-3BF3-59C6-A8D2-B29632AC0998 /tmp/dh_charlist-device-build/Build/Products/Debug-iphoneos/DHCharListHost.app`
  - Result: exit 0.
  - Installed bundle ID: `com.example.DHCharListHost`.
  - Raw log: `raw/devicectl-install-ipad-1.txt`.
- First launch failed because iOS required manually trusting the developer profile.
  - Raw log: `raw/devicectl-launch-ipad-1.txt`.
- After the user trusted the developer profile on the iPad, `xcrun devicectl device process launch --device 90DEFFEE-3BF3-59C6-A8D2-B29632AC0998 com.example.DHCharListHost`
  - Result: exit 0.
  - Raw log: `raw/devicectl-launch-ipad-2-after-trust.txt`.
- Installed app listing confirms `DH CharList com.example.DHCharListHost 1.0 1`.
  - Raw log: `raw/devicectl-apps-ipad-after-install.txt`.

## AC5 - Proof and repository state

Status: PASS.

- Proof artifacts updated in `.agent/tasks/2026-06-raibos-ipad-deploy/`.
- Deployment blocker was resolved and recorded in `problems.md`.
- `git status` after proof updates still includes `.swiftpm/xcode/package.xcworkspace/xcuserdata/an.artemenko.xcuserdatad/UserInterfaceState.xcuserstate`, a user/Xcode UI state change created while the user interacted with Xcode Accounts; it is intentionally left unstaged and uncommitted.
