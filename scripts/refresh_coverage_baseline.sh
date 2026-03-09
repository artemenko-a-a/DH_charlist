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
    echo "Coverage baseline file not found: $POLICY_PATH" >&2
    exit 2
fi

python3 - "$METRICS_PATH" "$POLICY_PATH" <<'PY'
import json
import sys
from datetime import datetime, timezone

metrics_path = sys.argv[1]
policy_path = sys.argv[2]

with open(metrics_path, "r", encoding="utf-8") as handle:
    metrics = json.load(handle)

with open(policy_path, "r", encoding="utf-8") as handle:
    policy = json.load(handle)

package_surface = metrics.get("package_surface")
if not package_surface:
    print("coverage-metrics.json does not contain package_surface; refresh would freeze a misleading baseline.", file=sys.stderr)
    sys.exit(2)

policy_cfg = policy.get("policy", {})
enforce_area_regression = bool(policy_cfg.get("enforce_area_regression", True))
minimum_area_executable_lines = int(
    policy_cfg.get("minimum_area_executable_lines", 1)
)
minimum_package_file_count = int(policy_cfg.get("minimum_package_file_count", 20))
current_package_file_count = int(package_surface.get("file_count", 0))
existing_baseline_file_count = int(
    policy.get("baseline", {}).get("package_surface", {}).get("file_count", 0)
)

if current_package_file_count < minimum_package_file_count:
    print(
        "coverage-metrics.json package_surface is too small to refresh baseline "
        f"({current_package_file_count} < {minimum_package_file_count}).",
        file=sys.stderr,
    )
    sys.exit(2)

if existing_baseline_file_count > 0 and current_package_file_count < existing_baseline_file_count:
    print(
        "coverage-metrics.json package_surface shrank below the existing baseline "
        f"({current_package_file_count} < {existing_baseline_file_count}); "
        "refusing to refresh from a potentially incomplete capture.",
        file=sys.stderr,
    )
    sys.exit(2)

tracked_areas = []
if enforce_area_regression:
    for area in package_surface.get("areas", []):
        executable_lines = int(area.get("executable_lines", 0))
        if executable_lines < minimum_area_executable_lines:
            continue
        tracked_areas.append(
            {
                "name": str(area.get("name", "<unknown>")),
                "covered_lines": int(area.get("covered_lines", 0)),
                "executable_lines": executable_lines,
                "file_count": int(area.get("file_count", 0)),
                "line_coverage_pct": float(area.get("line_coverage_pct", 0.0)),
            }
        )

tracked_files = [
    {
        "path": str(file_entry.get("path", "<unknown>")),
        "executable_lines": int(file_entry.get("executable_lines", 0)),
        "covered_lines": int(file_entry.get("covered_lines", 0)),
        "line_coverage_pct": float(file_entry.get("line_coverage_pct", 0.0)),
    }
    for file_entry in package_surface.get("files", [])
]

policy["status"] = "active"
policy["captured_at"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
policy["source_of_truth"] = (
    "SwiftPM code coverage JSON over Sources/DHCharList for gate enforcement, "
    "with xcodebuild/xccov host artifacts retained as diagnostics"
)
policy["baseline"] = {
    "metrics_source": metrics_path,
    "package_surface": {
    "line_coverage_pct": round(float(package_surface.get("line_coverage_pct", 0.0)), 2),
    "covered_lines": int(package_surface.get("covered_lines", 0)),
    "executable_lines": int(package_surface.get("executable_lines", 0)),
    "file_count": int(package_surface.get("file_count", 0)),
    "files": sorted(tracked_files, key=lambda item: item["path"]),
    "areas": sorted(tracked_areas, key=lambda item: item["name"]),
    },
    "host_xccov": {
        "line_coverage_pct": round(float(metrics.get("host_xccov", {}).get("line_coverage_pct", 0.0)), 2),
        "covered_lines": int(metrics.get("host_xccov", {}).get("covered_lines", 0)),
        "executable_lines": int(metrics.get("host_xccov", {}).get("executable_lines", 0)),
    },
}
policy["policy"] = {
    "require_package_surface": bool(policy_cfg.get("require_package_surface", True)),
    "require_all_baseline_files_present": bool(policy_cfg.get("require_all_baseline_files_present", True)),
    "allowed_package_drop_pp": float(policy_cfg.get("allowed_package_drop_pp", 0.5)),
    "enforce_area_regression": enforce_area_regression,
    "allowed_area_drop_pp": float(policy_cfg.get("allowed_area_drop_pp", 1.0)),
    "minimum_package_file_count": minimum_package_file_count,
    "minimum_area_executable_lines": minimum_area_executable_lines,
    "changed_code_expectation": policy_cfg.get(
        "changed_code_expectation",
        "This gate is baseline-first package coverage, not diff coverage; new or changed package code should still add direct tests where practical, especially in Domain/Application/Infrastructure.",
    ),
    "layer_expectations": policy_cfg.get(
        "layer_expectations",
        {
            "Domain": "Prefer strong meaningful coverage. New logic should include direct tests.",
            "Application": "Prefer strong meaningful coverage for use-case and orchestration paths.",
            "Infrastructure/Persistence": "Prefer strong coverage around repository behavior and serialization pathways.",
            "Presentation/SwiftUI": "Coverage is measured and guarded as part of package surface visibility, but large SwiftUI surfaces still rely heavily on behavior-oriented tests and smoke checks.",
        },
    ),
}
policy["staged_adoption"] = [
    "Stage 1: capture hybrid host diagnostics plus truthful SwiftPM package surface coverage.",
    "Stage 2 (current): require package surface presence, baseline file presence, package non-regression, and per-area non-regression.",
    "Stage 3: add stronger changed-file or diff-aware gates only after the repository has a truthful implementation for that signal.",
]

with open(policy_path, "w", encoding="utf-8") as handle:
    json.dump(policy, handle, indent=2)
    handle.write("\n")

print(f"Baseline refreshed from: {metrics_path}")
print(f"Updated package baseline: {float(package_surface.get('line_coverage_pct', 0.0)):.2f}%")
if tracked_areas:
    print("Tracked package areas:")
    for area in sorted(tracked_areas, key=lambda item: item["name"]):
        print(f"- {area['name']}: {area['line_coverage_pct']:.2f}%")
else:
    print("Tracked package areas: none")
PY
