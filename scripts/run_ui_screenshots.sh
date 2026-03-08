#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOST_DIR="$ROOT_DIR/DHCharListHost"
RUN_DIR="$HOST_DIR/artifacts/ui-screenshots/$(date +%Y%m%d-%H%M%S)"
RESULT_BUNDLE_PATH="$RUN_DIR/TestResults.xcresult"
ATTACHMENTS_DIR="$RUN_DIR/attachments"
LOG_PATH="$RUN_DIR/xcodebuild-ui-screenshots.log"
DESTINATION="${UI_DESTINATION:-id=99E2D143-E43E-4CE7-9F72-D05AE2A7A51C}"

mkdir -p "$RUN_DIR" "$ATTACHMENTS_DIR"

COMMAND=(
  xcodebuild
  test
  -project "$HOST_DIR/DHCharListHost.xcodeproj"
  -scheme DHCharListHost
  -destination "$DESTINATION"
  -resultBundlePath "$RESULT_BUNDLE_PATH"
  -only-testing:DHCharListHostUITests/DHCharListHostScreenshotUITests/testCaptureSeededSmokeScreens
)

echo "Running: ${COMMAND[*]}"
"${COMMAND[@]}" 2>&1 | tee "$LOG_PATH"

xcrun xcresulttool export attachments \
  --path "$RESULT_BUNDLE_PATH" \
  --output-path "$ATTACHMENTS_DIR"

echo "Screenshot result bundle: $RESULT_BUNDLE_PATH"
echo "Screenshot log: $LOG_PATH"
echo "Exported screenshots: $ATTACHMENTS_DIR"
echo "Screenshot destination used: $DESTINATION"
