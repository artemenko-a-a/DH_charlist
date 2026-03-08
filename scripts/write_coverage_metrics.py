#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def pct(value: float) -> float:
    return round(value * 100.0, 2)


def main() -> None:
    parser = argparse.ArgumentParser(description="Create compact machine-readable coverage metrics.")
    parser.add_argument("--report-json", required=True)
    parser.add_argument("--summary-text", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    report_path = Path(args.report_json)
    summary_path = Path(args.summary_text)
    output_path = Path(args.output)

    report = json.loads(report_path.read_text())

    targets = []
    total_covered = 0
    total_executable = 0

    for target in report.get("targets", []):
        executable_lines = int(target.get("executableLines", 0))
        covered_lines = int(target.get("coveredLines", 0))
        line_coverage = float(target.get("lineCoverage", 0.0))

        targets.append(
            {
                "name": target.get("name", "<unknown>"),
                "covered_lines": covered_lines,
                "executable_lines": executable_lines,
                "line_coverage": line_coverage,
                "line_coverage_pct": pct(line_coverage),
            }
        )

        total_covered += covered_lines
        total_executable += executable_lines

    overall = 0.0 if total_executable == 0 else total_covered / total_executable

    payload = {
        "source": "xcrun xccov view --report --json",
        "summary_text_path": str(summary_path),
        "report_json_path": str(report_path),
        "overall": {
            "covered_lines": total_covered,
            "executable_lines": total_executable,
            "line_coverage": overall,
            "line_coverage_pct": pct(overall),
        },
        "targets": sorted(targets, key=lambda item: item["name"]),
    }

    output_path.write_text(json.dumps(payload, indent=2) + "\n")


if __name__ == "__main__":
    main()
