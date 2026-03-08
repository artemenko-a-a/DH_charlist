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

baseline_overall = baseline.get("overall_line_coverage_pct")
allowed_drop_pp = float(policy_cfg.get("allowed_overall_drop_pp", 0.5))
target_drop_pp = float(policy_cfg.get("allowed_target_drop_pp", allowed_drop_pp))
enforce_target_regression = bool(policy_cfg.get("enforce_target_regression", False))
minimum_target_executable_lines = int(policy_cfg.get("minimum_executable_lines_for_target_gate", 1))

if baseline_overall is None:
    print("Baseline overall coverage is not set yet in Docs/coverage-baseline.json.", file=sys.stderr)
    print("Capture and freeze a baseline from a real xccov run before enabling strict regression checks.", file=sys.stderr)
    sys.exit(2)

current_overall = float(metrics.get("overall", {}).get("line_coverage_pct", 0.0))
min_allowed = float(baseline_overall) - allowed_drop_pp
failures: list[str] = []

print(f"Baseline overall line coverage: {baseline_overall:.2f}%")
print(f"Current overall line coverage:  {current_overall:.2f}%")
print(f"Allowed regression budget:      {allowed_drop_pp:.2f}pp")
print(f"Minimum allowed now:            {min_allowed:.2f}%")

if current_overall + 1e-9 < min_allowed:
    failures.append(
        f"overall coverage regressed: current {current_overall:.2f}% < minimum {min_allowed:.2f}%"
    )

if enforce_target_regression:
    baseline_targets = {
        str(target["name"]): target
        for target in baseline.get("targets", [])
        if int(target.get("executable_lines", 0)) >= minimum_target_executable_lines
    }
    current_targets = {
        str(target.get("name", "<unknown>")): target
        for target in metrics.get("targets", [])
    }

    if baseline_targets:
        print("Per-target non-regression (staged conservative gate):")
    for name in sorted(baseline_targets):
        baseline_target = baseline_targets[name]
        current_target = current_targets.get(name)
        baseline_target_pct = float(baseline_target.get("line_coverage_pct", 0.0))
        target_min_allowed = baseline_target_pct - target_drop_pp

        if current_target is None:
            failures.append(f"target missing from current report: {name}")
            continue

        current_target_exec = int(current_target.get("executable_lines", 0))
        current_target_pct = float(current_target.get("line_coverage_pct", 0.0))
        print(
            f"- {name}: baseline {baseline_target_pct:.2f}% | current {current_target_pct:.2f}% | "
            f"min {target_min_allowed:.2f}%"
        )

        if current_target_exec < minimum_target_executable_lines:
            failures.append(
                f"target {name} dropped below executable line floor ({current_target_exec} < "
                f"{minimum_target_executable_lines})"
            )
            continue

        if current_target_pct + 1e-9 < target_min_allowed:
            failures.append(
                f"target coverage regressed for {name}: current {current_target_pct:.2f}% < "
                f"minimum {target_min_allowed:.2f}%"
            )

if failures:
    print("Coverage policy check FAILED:", file=sys.stderr)
    for failure in failures:
        print(f"- {failure}", file=sys.stderr)
    sys.exit(1)

print("Coverage policy check passed.")
PY
