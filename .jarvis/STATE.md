# Batch 27 State

- status: validated
- scope: optional GitHub Actions UI workflow only
- hosted smoke run: `22848098651` green (`7m58s`)
- hosted screenshots run: `22848408585` green (`17m17s`)
- workflow assumptions:
  - `runs-on: macos-15`
  - `DEVELOPER_DIR=/Applications/Xcode_16.4.app/Contents/Developer`
  - first available iPhone simulator on runner
  - `xcrun simctl bootstatus <udid> -b` before invoking canonical UI scripts
- required CI: unchanged and still required
- optional UI workflow: still manual by design
