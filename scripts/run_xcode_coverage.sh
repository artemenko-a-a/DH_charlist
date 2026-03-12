#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="${COVERAGE_PROJECT_PATH:-$ROOT_DIR/DHCharListHost/DHCharListHost.xcodeproj}"
SCHEME="${COVERAGE_SCHEME:-DHCharListHost}"
XCODE_HOME="${COVERAGE_XCODE_HOME:-/tmp/dhcharlist-xcode-home}"
ISOLATE_XCODE_HOME="${COVERAGE_ISOLATE_XCODE_HOME:-0}"
OUTPUT_ROOT="${COVERAGE_OUTPUT_ROOT:-$ROOT_DIR/DHCharListHost/artifacts/coverage}"
SWIFTPM_BUILD_PATH="${COVERAGE_SWIFTPM_BUILD_PATH:-/tmp/dh_charlist-coverage-build}"
XCODEBUILD_MAX_ATTEMPTS="${COVERAGE_XCODEBUILD_ATTEMPTS:-2}"

_pick_simulator_destination() {
    local simctl_destination
    simctl_destination="$(xcrun simctl list devices available --json 2>/dev/null | python3 -c "
import json, sys
pro_match = None
phone_match = None
fallback = None
data = json.load(sys.stdin)
for runtime in sorted(data.get('devices', {}).keys(), reverse=True):
    if 'iOS' not in runtime:
        continue
    for device in data['devices'][runtime]:
        if not device.get('isAvailable'):
            continue
        name = device.get('name', '')
        value = 'id=' + device['udid']
        if 'iPhone' in name and 'Pro' in name:
            pro_match = pro_match or value
        elif 'iPhone' in name:
            phone_match = phone_match or value
        else:
            fallback = fallback or value
if pro_match:
    print(pro_match)
elif phone_match:
    print(phone_match)
elif fallback:
    print(fallback)
" 2>/dev/null || true)"
    if [[ -n "$simctl_destination" ]]; then
        echo "$simctl_destination"
        return 0
    fi

    xcodebuild -showdestinations -project "$PROJECT_PATH" -scheme "$SCHEME" 2>/dev/null | python3 -c "
import re, sys
pro_match = None
phone_match = None
fallback = None
for line in sys.stdin:
    if 'platform:iOS Simulator' not in line or 'id:' not in line or 'placeholder' in line:
        continue
    match = re.search(r'id:([^,} ]+)', line)
    if not match:
        continue
    value = 'id=' + match.group(1).strip()
    if 'name:iPhone' in line and 'Pro' in line:
        pro_match = pro_match or value
    elif 'name:iPhone' in line:
        phone_match = phone_match or value
    elif fallback is None:
        fallback = value
if pro_match is not None:
    print(pro_match)
    sys.exit(0)
if phone_match is not None:
    print(phone_match)
    sys.exit(0)
if fallback is not None:
    print(fallback)
    sys.exit(0)
print('platform=iOS Simulator,OS=latest')
" 2>/dev/null || echo "platform=iOS Simulator,OS=latest"
}

DESTINATION="${COVERAGE_DESTINATION:-$(_pick_simulator_destination)}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$OUTPUT_ROOT/$TIMESTAMP"
RESULT_BUNDLE_PATH="$RUN_DIR/TestResults.xcresult"
BUILD_LOG_PATH="$RUN_DIR/xcodebuild-test.log"
SUMMARY_TEXT_PATH="$RUN_DIR/xccov-summary.txt"
REPORT_JSON_PATH="$RUN_DIR/xccov-report.json"
SWIFTPM_LOG_PATH="$RUN_DIR/swiftpm-test.log"
SWIFTPM_CODECOV_JSON_PATH="$RUN_DIR/swiftpm-codecov.json"
METRICS_JSON_PATH="$RUN_DIR/coverage-metrics.json"

mkdir -p "$RUN_DIR"
if [[ "$ISOLATE_XCODE_HOME" == "1" ]]; then
    mkdir -p "$XCODE_HOME/Library/Caches/org.swift.swiftpm/manifests/ManifestLoading"
    mkdir -p "$XCODE_HOME/Library/Logs/CoreSimulator"
fi

COMMAND=(
    xcodebuild
    test
    -project "$PROJECT_PATH"
    -scheme "$SCHEME"
    -destination "$DESTINATION"
    -enableCodeCoverage YES
    -resultBundlePath "$RESULT_BUNDLE_PATH"
)

_is_retryable_simulator_failure() {
    local log_path="$1"
    grep -Eq \
        "CoreSimulatorService connection became invalid|CoreSimulatorService connection interrupted|Connection refused|Software caused connection abort|Unable to boot the Simulator|launchd_sim may have crashed or quit responding|Interrupted system call" \
        "$log_path"
}

XCODEBUILD_EXIT=0
XCODEBUILD_RESULT_BUNDLE_PATH="$RESULT_BUNDLE_PATH"
XCODEBUILD_BUILD_LOG_PATH="$BUILD_LOG_PATH"

for (( attempt = 1; attempt <= XCODEBUILD_MAX_ATTEMPTS; attempt++ )); do
    ATTEMPT_RESULT_BUNDLE_PATH="$RESULT_BUNDLE_PATH"
    ATTEMPT_BUILD_LOG_PATH="$BUILD_LOG_PATH"

    if [[ $attempt -gt 1 ]]; then
        ATTEMPT_RESULT_BUNDLE_PATH="$RUN_DIR/TestResults-attempt$attempt.xcresult"
        ATTEMPT_BUILD_LOG_PATH="$RUN_DIR/xcodebuild-test-attempt$attempt.log"
    fi

    ATTEMPT_COMMAND=(
        xcodebuild
        test
        -project "$PROJECT_PATH"
        -scheme "$SCHEME"
        -destination "$DESTINATION"
        -enableCodeCoverage YES
        -resultBundlePath "$ATTEMPT_RESULT_BUNDLE_PATH"
    )

    echo "Coverage xcodebuild attempt $attempt/$XCODEBUILD_MAX_ATTEMPTS"
    echo "Running: ${ATTEMPT_COMMAND[*]}"

    set +e
    if [[ "$ISOLATE_XCODE_HOME" == "1" ]]; then
        CFFIXED_USER_HOME="$XCODE_HOME" HOME="$XCODE_HOME" "${ATTEMPT_COMMAND[@]}" 2>&1 | tee "$ATTEMPT_BUILD_LOG_PATH"
    else
        "${ATTEMPT_COMMAND[@]}" 2>&1 | tee "$ATTEMPT_BUILD_LOG_PATH"
    fi
    XCODEBUILD_EXIT=${PIPESTATUS[0]}
    set -e

    XCODEBUILD_RESULT_BUNDLE_PATH="$ATTEMPT_RESULT_BUNDLE_PATH"
    XCODEBUILD_BUILD_LOG_PATH="$ATTEMPT_BUILD_LOG_PATH"

    if [[ $XCODEBUILD_EXIT -eq 0 ]]; then
        break
    fi

    if [[ $attempt -lt XCODEBUILD_MAX_ATTEMPTS ]] && _is_retryable_simulator_failure "$ATTEMPT_BUILD_LOG_PATH"; then
        echo "Retrying coverage xcodebuild after transient CoreSimulator failure..."
        sleep 2
        continue
    fi

    break
done

if [[ $XCODEBUILD_EXIT -ne 0 ]]; then
    echo "xcodebuild test failed with exit code $XCODEBUILD_EXIT" >&2

    if grep -q "not currently configured for the test action" "$XCODEBUILD_BUILD_LOG_PATH"; then
        cat >&2 <<'MSG'
Detected scheme-without-tests configuration.
The current DHCharListHost scheme has no attached test targets, so coverage cannot be generated from this scheme yet.
Either attach tests to DHCharListHost, or rerun with a scheme that has tests using COVERAGE_SCHEME=... .
MSG
    fi

    if grep -Eq "CoreSimulatorService connection became invalid|CoreSimulatorService connection interrupted|Connection refused|Software caused connection abort|Unable to boot the Simulator|launchd_sim may have crashed or quit responding|Interrupted system call" "$XCODEBUILD_BUILD_LOG_PATH"; then
        cat >&2 <<'MSG'
CoreSimulator is unavailable in this environment; iOS-simulator-based test execution is blocked.
MSG
    fi

    if grep -q "Could not resolve package dependencies" "$XCODEBUILD_BUILD_LOG_PATH"; then
        cat >&2 <<'MSG'
Package dependency resolution failed during xcodebuild test.
If COVERAGE_ISOLATE_XCODE_HOME=1 is enabled, retry with the default local user-home path first.
If this persists on your machine, run inside full Xcode environment and retry.
MSG
    fi

    exit "$XCODEBUILD_EXIT"
fi

xcrun xccov view --report "$XCODEBUILD_RESULT_BUNDLE_PATH" > "$SUMMARY_TEXT_PATH"
xcrun xccov view --report --json "$XCODEBUILD_RESULT_BUNDLE_PATH" > "$REPORT_JSON_PATH"

SWIFTPM_TEST_COMMAND=(
    swift
    test
    --enable-code-coverage
    --build-path "$SWIFTPM_BUILD_PATH"
)

echo "Running: ${SWIFTPM_TEST_COMMAND[*]}"
set +e
"${SWIFTPM_TEST_COMMAND[@]}" 2>&1 | tee "$SWIFTPM_LOG_PATH"
SWIFTPM_TEST_EXIT=${PIPESTATUS[0]}
set -e

if [[ $SWIFTPM_TEST_EXIT -ne 0 ]]; then
    echo "swift test --enable-code-coverage failed with exit code $SWIFTPM_TEST_EXIT" >&2
    exit "$SWIFTPM_TEST_EXIT"
fi

SWIFTPM_CODECOV_PATH="$(swift test --show-codecov-path --build-path "$SWIFTPM_BUILD_PATH" | tail -n 1)"
if [[ -z "$SWIFTPM_CODECOV_PATH" || ! -f "$SWIFTPM_CODECOV_PATH" ]]; then
    echo "SwiftPM code coverage JSON not found after coverage run." >&2
    echo "Expected path: $SWIFTPM_CODECOV_PATH" >&2
    exit 2
fi

cp "$SWIFTPM_CODECOV_PATH" "$SWIFTPM_CODECOV_JSON_PATH"

python3 "$ROOT_DIR/scripts/write_coverage_metrics.py" \
    --report-json "$REPORT_JSON_PATH" \
    --summary-text "$SUMMARY_TEXT_PATH" \
    --swiftpm-codecov-json "$SWIFTPM_CODECOV_JSON_PATH" \
    --package-source-root "$ROOT_DIR/Sources/DHCharList" \
    --output "$METRICS_JSON_PATH"

ln -sfn "$RUN_DIR" "$OUTPUT_ROOT/latest"

cat <<MSG
Coverage artifacts generated:
- Result bundle: $XCODEBUILD_RESULT_BUNDLE_PATH
- xccov text summary: $SUMMARY_TEXT_PATH
- xccov JSON report: $REPORT_JSON_PATH
- SwiftPM coverage log: $SWIFTPM_LOG_PATH
- SwiftPM coverage JSON: $SWIFTPM_CODECOV_JSON_PATH
- machine metrics JSON: $METRICS_JSON_PATH
- latest symlink: $OUTPUT_ROOT/latest
- destination used: $DESTINATION
MSG
