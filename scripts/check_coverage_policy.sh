#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
METRICS_PATH="${COVERAGE_METRICS_PATH:-$ROOT_DIR/DHCharListHost/artifacts/coverage/latest/coverage-metrics.json}"
POLICY_PATH="${COVERAGE_POLICY_PATH:-$ROOT_DIR/Docs/coverage-baseline.json}"

if [[ ! -f "$METRICS_PATH" ]]; then
    echo "Coverage metrics file not found: $METRICS_PATH" >&2
    echo "Run scripts/run_xcode_coverage.sh first." >&2
    exit 2
fi

if [[ ! -f "$POLICY_PATH" ]]; then
    echo "Coverage policy baseline not found: $POLICY_PATH" >&2
    exit 2
fi

python3 - "$METRICS_PATH" "$POLICY_PATH" <<'PY'
import json
import sys

metrics_path = sys.argv[1]
policy_path = sys.argv[2]

with open(metrics_path, "r", encoding="utf-8") as handle:
    metrics = json.load(handle)

with open(policy_path, "r", encoding="utf-8") as handle:
    policy = json.load(handle)

baseline = policy.get("baseline", {})
policy_cfg = policy.get("policy", {})

package_metrics = metrics.get("package_surface")
package_baseline = baseline.get("package_surface", {})

require_package_surface = bool(policy_cfg.get("require_package_surface", True))
require_all_baseline_files_present = bool(policy_cfg.get("require_all_baseline_files_present", True))
allowed_package_drop_pp = float(policy_cfg.get("allowed_package_drop_pp", 0.5))
allowed_area_drop_pp = float(policy_cfg.get("allowed_area_drop_pp", 1.0))
enforce_area_regression = bool(policy_cfg.get("enforce_area_regression", True))
minimum_package_file_count = int(policy_cfg.get("minimum_package_file_count", 20))
minimum_area_executable_lines = int(policy_cfg.get("minimum_area_executable_lines", 1))

if not package_baseline:
    print("Package coverage baseline is not set yet in Docs/coverage-baseline.json.", file=sys.stderr)
    print("Refresh the baseline from a real package-surface coverage capture before enabling the strict gate.", file=sys.stderr)
    sys.exit(2)

failures: list[str] = []

if package_metrics is None:
    if require_package_surface:
        failures.append(
            "package coverage surface is missing from coverage-metrics.json; the report is not truthful enough "
            "to gate Sources/DHCharList"
        )
else:
    baseline_overall = float(package_baseline.get("line_coverage_pct", 0.0))
    current_overall = float(package_metrics.get("line_coverage_pct", 0.0))
    min_allowed = baseline_overall - allowed_package_drop_pp
    current_file_count = int(package_metrics.get("file_count", 0))
    baseline_file_count = int(package_baseline.get("file_count", 0))

    print("Package surface coverage gate:")
    print(f"- baseline package coverage: {baseline_overall:.2f}%")
    print(f"- current package coverage:  {current_overall:.2f}%")
    print(f"- allowed regression budget: {allowed_package_drop_pp:.2f}pp")
    print(f"- minimum allowed now:       {min_allowed:.2f}%")
    print(f"- package files seen:        {current_file_count}")

    if current_file_count < minimum_package_file_count:
        failures.append(
            f"package coverage file count is too small ({current_file_count} < {minimum_package_file_count}); "
            "coverage artifacts look incomplete"
        )

    if baseline_file_count > 0 and current_file_count < baseline_file_count:
        failures.append(
            f"package coverage surface shrank below baseline ({current_file_count} < {baseline_file_count}); "
            "some source files are missing from coverage"
        )

    if current_overall + 1e-9 < min_allowed:
        failures.append(
            f"package coverage regressed: current {current_overall:.2f}% < minimum {min_allowed:.2f}%"
        )

    baseline_files = {str(item["path"]) for item in package_baseline.get("files", [])}
    current_files = {str(item.get("path", "")) for item in package_metrics.get("files", [])}
    if require_all_baseline_files_present:
        missing_files = sorted(path for path in baseline_files if path not in current_files)
        if missing_files:
            preview = ", ".join(missing_files[:5])
            failures.append(
                f"package coverage is missing baseline source files ({len(missing_files)} missing). "
                f"Examples: {preview}"
            )

    if enforce_area_regression:
        baseline_areas = {
            str(area["name"]): area
            for area in package_baseline.get("areas", [])
            if int(area.get("executable_lines", 0)) >= minimum_area_executable_lines
        }
        current_areas = {
            str(area.get("name", "<unknown>")): area
            for area in package_metrics.get("areas", [])
        }

        if baseline_areas:
            print("Per-area non-regression:")
        for area_name in sorted(baseline_areas):
            baseline_area = baseline_areas[area_name]
            current_area = current_areas.get(area_name)
            baseline_area_pct = float(baseline_area.get("line_coverage_pct", 0.0))
            minimum_area_pct = baseline_area_pct - allowed_area_drop_pp

            if current_area is None:
                failures.append(f"package coverage area missing from current report: {area_name}")
                continue

            current_area_exec = int(current_area.get("executable_lines", 0))
            current_area_pct = float(current_area.get("line_coverage_pct", 0.0))
            print(
                f"- {area_name}: baseline {baseline_area_pct:.2f}% | current {current_area_pct:.2f}% | "
                f"min {minimum_area_pct:.2f}%"
            )

            if current_area_exec < minimum_area_executable_lines:
                failures.append(
                    f"package coverage area {area_name} dropped below executable-line floor "
                    f"({current_area_exec} < {minimum_area_executable_lines})"
                )
                continue

            if current_area_pct + 1e-9 < minimum_area_pct:
                failures.append(
                    f"package coverage regressed for area {area_name}: current {current_area_pct:.2f}% < "
                    f"minimum {minimum_area_pct:.2f}%"
                )

if failures:
    print("Coverage policy check FAILED:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    sys.exit(1)

print("Coverage policy check passed.")
PY
