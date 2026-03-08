#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HOST_DIR="$ROOT_DIR/DHCharListHost"
RUN_DIR="$HOST_DIR/artifacts/ui-smoke/$(date +%Y%m%d-%H%M%S)"
RESULT_BUNDLE_PATH="$RUN_DIR/TestResults.xcresult"
LOG_PATH="$RUN_DIR/xcodebuild-ui-smoke.log"

_pick_simulator_destination() {
    xcrun simctl list devices available --json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime in sorted(data.get('devices', {}).keys(), reverse=True):
    if 'iOS' not in runtime:
        continue
    for device in data['devices'][runtime]:
        if device.get('isAvailable') and 'iPhone' in device.get('name', ''):
            print('id=' + device['udid'])
            sys.exit(0)
print('platform=iOS Simulator,OS=latest')
" 2>/dev/null || echo "platform=iOS Simulator,OS=latest"
}

DESTINATION="${UI_DESTINATION:-$(_pick_simulator_destination)}"

mkdir -p "$RUN_DIR"

COMMAND=(
  xcodebuild
  test
  -project "$HOST_DIR/DHCharListHost.xcodeproj"
  -scheme DHCharListHost
  -destination "$DESTINATION"
  -resultBundlePath "$RESULT_BUNDLE_PATH"
  -only-testing:DHCharListHostUITests/DHCharListHostSmokeUITests/testSmokeCoreFlowsAndEntryPoints
)

echo "Running: ${COMMAND[*]}"
"${COMMAND[@]}" 2>&1 | tee "$LOG_PATH"

echo "UI smoke result bundle: $RESULT_BUNDLE_PATH"
echo "UI smoke log: $LOG_PATH"
echo "UI smoke destination used: $DESTINATION"
