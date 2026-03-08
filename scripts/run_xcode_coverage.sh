#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_PATH="${COVERAGE_PROJECT_PATH:-$ROOT_DIR/DHCharListHost/DHCharListHost.xcodeproj}"
SCHEME="${COVERAGE_SCHEME:-DHCharListHost}"
DESTINATION="${COVERAGE_DESTINATION:-id=99E2D143-E43E-4CE7-9F72-D05AE2A7A51C}"
OUTPUT_ROOT="${COVERAGE_OUTPUT_ROOT:-$ROOT_DIR/DHCharListHost/artifacts/coverage}"
XCODE_HOME="${COVERAGE_XCODE_HOME:-/tmp/dhcharlist-xcode-home}"
ISOLATE_XCODE_HOME="${COVERAGE_ISOLATE_XCODE_HOME:-0}"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
RUN_DIR="$OUTPUT_ROOT/$TIMESTAMP"
RESULT_BUNDLE_PATH="$RUN_DIR/TestResults.xcresult"
BUILD_LOG_PATH="$RUN_DIR/xcodebuild-test.log"
SUMMARY_TEXT_PATH="$RUN_DIR/xccov-summary.txt"
REPORT_JSON_PATH="$RUN_DIR/xccov-report.json"
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

echo "Running: ${COMMAND[*]}"
set +e
if [[ "$ISOLATE_XCODE_HOME" == "1" ]]; then
    CFFIXED_USER_HOME="$XCODE_HOME" HOME="$XCODE_HOME" "${COMMAND[@]}" 2>&1 | tee "$BUILD_LOG_PATH"
else
    "${COMMAND[@]}" 2>&1 | tee "$BUILD_LOG_PATH"
fi
XCODEBUILD_EXIT=${PIPESTATUS[0]}
set -e

if [[ $XCODEBUILD_EXIT -ne 0 ]]; then
    echo "xcodebuild test failed with exit code $XCODEBUILD_EXIT" >&2

    if grep -q "not currently configured for the test action" "$BUILD_LOG_PATH"; then
        cat >&2 <<'MSG'
Detected scheme-without-tests configuration.
The current DHCharListHost scheme has no attached test targets, so coverage cannot be generated from this scheme yet.
Either attach tests to DHCharListHost, or rerun with a scheme that has tests using COVERAGE_SCHEME=... .
MSG
    fi

    if grep -Eq "CoreSimulatorService connection became invalid|Connection refused" "$BUILD_LOG_PATH"; then
        cat >&2 <<'MSG'
CoreSimulator is unavailable in this environment; iOS-simulator-based test execution is blocked.
MSG
    fi

    if grep -q "Could not resolve package dependencies" "$BUILD_LOG_PATH"; then
        cat >&2 <<'MSG'
Package dependency resolution failed during xcodebuild test.
If COVERAGE_ISOLATE_XCODE_HOME=1 is enabled, retry with the default local user-home path first.
If this persists on your machine, run inside full Xcode environment and retry.
MSG
    fi

    exit "$XCODEBUILD_EXIT"
fi

xcrun xccov view --report "$RESULT_BUNDLE_PATH" > "$SUMMARY_TEXT_PATH"
xcrun xccov view --report --json "$RESULT_BUNDLE_PATH" > "$REPORT_JSON_PATH"

python3 "$ROOT_DIR/scripts/write_coverage_metrics.py" \
    --report-json "$REPORT_JSON_PATH" \
    --summary-text "$SUMMARY_TEXT_PATH" \
    --output "$METRICS_JSON_PATH"

ln -sfn "$RUN_DIR" "$OUTPUT_ROOT/latest"

cat <<MSG
Coverage artifacts generated:
- Result bundle: $RESULT_BUNDLE_PATH
- xccov text summary: $SUMMARY_TEXT_PATH
- xccov JSON report: $REPORT_JSON_PATH
- machine metrics JSON: $METRICS_JSON_PATH
- latest symlink: $OUTPUT_ROOT/latest
- destination used: $DESTINATION
MSG
