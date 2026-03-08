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

overall_pct = float(metrics.get("overall", {}).get("line_coverage_pct", 0.0))
enforce_target_regression = bool(policy.get("policy", {}).get("enforce_target_regression", False))
minimum_target_executable_lines = int(
    policy.get("policy", {}).get("minimum_executable_lines_for_target_gate", 1)
)

all_targets = metrics.get("targets", [])
tracked_targets = []
if enforce_target_regression:
    for target in all_targets:
        name = str(target.get("name", "<unknown>"))
        executable_lines = int(target.get("executable_lines", 0))
        if executable_lines < minimum_target_executable_lines:
            continue
        if name.endswith("Tests.xctest"):
            continue
        tracked_targets.append(
            {
                "name": name,
                "covered_lines": int(target.get("covered_lines", 0)),
                "executable_lines": executable_lines,
                "line_coverage_pct": float(target.get("line_coverage_pct", 0.0)),
            }
        )

policy["status"] = "active"
policy["captured_at"] = datetime.now(timezone.utc).replace(microsecond=0).isoformat()
policy.setdefault("baseline", {})
policy["baseline"]["overall_line_coverage_pct"] = round(overall_pct, 2)
policy["baseline"]["metrics_source"] = metrics_path
policy["baseline"]["targets"] = sorted(tracked_targets, key=lambda item: item["name"])
policy["baseline"].pop("notes", None)

with open(policy_path, "w", encoding="utf-8") as handle:
    json.dump(policy, handle, indent=2)
    handle.write("\n")

print(f"Baseline refreshed from: {metrics_path}")
print(f"Updated overall baseline: {overall_pct:.2f}%")
if tracked_targets:
    print("Tracked targets:")
    for target in sorted(tracked_targets, key=lambda item: item["name"]):
        print(f"- {target['name']}: {target['line_coverage_pct']:.2f}%")
else:
    print("Tracked targets: none (target gate disabled or no eligible targets)")
PY
