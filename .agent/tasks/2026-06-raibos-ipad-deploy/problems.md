# Problems

## P1 - Physical iPad deployment blocked by signing state

Status: RESOLVED.

The connected iPad was visible to CoreDevice and Xcode, but early `xcodebuild` attempts could not produce an installable device build because the wrong team ID was used and local signing was not yet provisioned.

Evidence:

- `raw/devicectl-devices.txt` shows `iPad (Андрей)` as available and paired.
- `raw/xcodebuild-device-ipad-2.txt` failed with exit 65 because `DHCharListHost` has no development team configured.
- `raw/xcodebuild-device-ipad-3.txt` failed with exit 65 after passing `DEVELOPMENT_TEAM=J7NPK94U5Y CODE_SIGN_STYLE=Automatic -allowProvisioningUpdates`; Xcode reported no account for that team and no matching profile for `com.example.DHCharListHost`.
- `raw/xcodebuild-device-ipad-4-personal-team.txt` failed with exit 65 after explicitly choosing Personal Team `J7NPK94U5Y` and allowing device registration; Xcode again reported no account for the team and no matching profile.
- `raw/xcodebuild-device-ipad-5-after-account.txt` failed with exit 65 after the user reported the Apple account was added; Xcode still reported no account for team `J7NPK94U5Y`.
- `raw/xcode-local-signing-state-after-personal-team.txt` shows zero local `.mobileprovision` profiles and no Xcode provisioning team mappings for the project.
- `raw/xcode-cli-state-after-account-ready.txt` shows the active CLI developer directory is `/Applications/Xcode.app/Contents/Developer`, there is no alternate Xcode.app, local provisioning profile count is still zero, and Xcode provisioning team mappings remain empty.
- `raw/provisioning-profile-dir-check.txt` shows `NO_PROFILE_DIR`.
- Xcode account settings later showed the real Personal Team ID as `Y8QK9BKTCW`; see `raw/xcode-signing-state-after-y8q-build.txt`.
- `raw/xcodebuild-device-ipad-8-personal-team-y8q.txt` succeeded with `DEVELOPMENT_TEAM=Y8QK9BKTCW` and created/used `iOS Team Provisioning Profile: com.example.DHCharListHost`.
- `raw/devicectl-install-ipad-1.txt` shows the app installed on `iPad (Андрей)`.
- `raw/devicectl-launch-ipad-2-after-trust.txt` shows the app launched successfully after the user trusted the developer profile on the iPad.

Resolution:

Use the Xcode Personal Team ID `Y8QK9BKTCW` for device builds:

```sh
xcodebuild -project DHCharListHost/DHCharListHost.xcodeproj \
  -scheme DHCharListHost \
  -configuration Debug \
  -destination 'platform=iOS,id=00008122-000A242936DA801C' \
  -derivedDataPath /tmp/dh_charlist-device-build \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  DEVELOPMENT_TEAM=Y8QK9BKTCW \
  CODE_SIGN_STYLE=Automatic \
  build
```
