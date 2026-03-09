#!/usr/bin/env python3
import argparse
import json
from pathlib import Path


def pct(value: float) -> float:
    return round(value * 100.0, 2)


def relative_to_root(path: str, root: Path) -> str:
    try:
        return str(Path(path).resolve().relative_to(root.resolve()))
    except ValueError:
        return path


def main() -> None:
    parser = argparse.ArgumentParser(description="Create compact machine-readable coverage metrics.")
    parser.add_argument("--report-json", required=True)
    parser.add_argument("--summary-text", required=True)
    parser.add_argument("--swiftpm-codecov-json", required=True)
    parser.add_argument("--package-source-root", required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()

    report_path = Path(args.report_json)
    summary_path = Path(args.summary_text)
    swiftpm_report_path = Path(args.swiftpm_codecov_json)
    package_source_root = Path(args.package_source_root)
    output_path = Path(args.output)

    xccov_report = json.loads(report_path.read_text())
    swiftpm_report = json.loads(swiftpm_report_path.read_text())

    host_targets = []
    host_total_covered = 0
    host_total_executable = 0

    for target in xccov_report.get("targets", []):
        executable_lines = int(target.get("executableLines", 0))
        covered_lines = int(target.get("coveredLines", 0))
        line_coverage = float(target.get("lineCoverage", 0.0))

        host_targets.append(
            {
                "name": target.get("name", "<unknown>"),
                "covered_lines": covered_lines,
                "executable_lines": executable_lines,
                "line_coverage": line_coverage,
                "line_coverage_pct": pct(line_coverage),
            }
        )

        host_total_covered += covered_lines
        host_total_executable += executable_lines

    host_overall = 0.0 if host_total_executable == 0 else host_total_covered / host_total_executable

    package_files = []
    package_areas: dict[str, dict[str, float | int | str]] = {}
    package_total_covered = 0
    package_total_executable = 0

    for export in swiftpm_report.get("data", []):
        for file_entry in export.get("files", []):
            filename = str(file_entry.get("filename", ""))
            summary = file_entry.get("summary", {}).get("lines", {})
            executable_lines = int(summary.get("count", 0))
            if executable_lines <= 0:
                continue
            file_path = Path(filename)
            try:
                relative_path = str(file_path.resolve().relative_to(package_source_root.resolve()))
            except ValueError:
                continue

            covered_lines = int(summary.get("covered", 0))
            line_coverage = 0.0 if executable_lines == 0 else covered_lines / executable_lines
            area_name = relative_path.split("/", 1)[0]

            package_files.append(
                {
                    "path": relative_path,
                    "covered_lines": covered_lines,
                    "executable_lines": executable_lines,
                    "line_coverage": line_coverage,
                    "line_coverage_pct": pct(line_coverage),
                }
            )

            area = package_areas.setdefault(
                area_name,
                {
                    "name": area_name,
                    "covered_lines": 0,
                    "executable_lines": 0,
                    "file_count": 0,
                },
            )
            area["covered_lines"] = int(area["covered_lines"]) + covered_lines
            area["executable_lines"] = int(area["executable_lines"]) + executable_lines
            area["file_count"] = int(area["file_count"]) + 1

            package_total_covered += covered_lines
            package_total_executable += executable_lines

    package_areas_payload = []
    for area_name, area in sorted(package_areas.items()):
        executable_lines = int(area["executable_lines"])
        covered_lines = int(area["covered_lines"])
        line_coverage = 0.0 if executable_lines == 0 else covered_lines / executable_lines
        package_areas_payload.append(
            {
                "name": area_name,
                "covered_lines": covered_lines,
                "executable_lines": executable_lines,
                "file_count": int(area["file_count"]),
                "line_coverage": line_coverage,
                "line_coverage_pct": pct(line_coverage),
            }
        )

    package_overall = 0.0 if package_total_executable == 0 else package_total_covered / package_total_executable

    payload = {
        "source": "xcodebuild xccov + SwiftPM code coverage JSON",
        "summary_text_path": str(summary_path),
        "report_json_path": str(report_path),
        "swiftpm_codecov_json_path": str(swiftpm_report_path),
        "host_xccov": {
            "covered_lines": host_total_covered,
            "executable_lines": host_total_executable,
            "line_coverage": host_overall,
            "line_coverage_pct": pct(host_overall),
        },
        "targets": sorted(host_targets, key=lambda item: item["name"]),
        "package_surface": {
            "source_root": str(package_source_root),
            "file_count": len(package_files),
            "covered_lines": package_total_covered,
            "executable_lines": package_total_executable,
            "line_coverage": package_overall,
            "line_coverage_pct": pct(package_overall),
            "areas": package_areas_payload,
            "files": sorted(package_files, key=lambda item: item["path"]),
        },
    }

    output_path.write_text(json.dumps(payload, indent=2) + "\n")


if __name__ == "__main__":
    main()
