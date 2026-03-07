#!/usr/bin/env python3
"""
check-exit-criteria.py — Iteration Exit Criteria Checker
u-maker plugin

Checks 3 exit criteria for PDCA iteration completion:
  1. No Critical/Major defects ({app}/04-check/4_Report_QA.md for all apps)
  2. All FR items implemented ({app}/01-plan/1_SRS_RA.md for all apps)
  3. Build succeeds (bun run build)

Supports v2 per-app structure (common/ + {app}/) with v1 fallback.

Usage: python3 check-exit-criteria.py [.u-maker/docs-path]

Exit codes:
  0 — All criteria met (iteration can end)
  1 — One or more criteria not met
"""

import os
import re
import sys
import json
import subprocess


# ============================================================
# Configuration
# ============================================================

# v1 fallback paths
DOC_PATHS_V1 = {
    "qa_report": "04-check/4_Report_QA.md",
    "srs": "01-plan/1_SRS_RA.md",
}


def get_apps(udocs_root):
    """Read app list from .u-maker/u-ssot.config.json."""
    config_path = os.path.join(os.path.dirname(udocs_root), ".u-maker/u-ssot.config.json")
    apps = ["web"]
    try:
        if os.path.exists(config_path):
            with open(config_path, "r", encoding="utf-8") as f:
                config = json.load(f)
            apps = (
                config.get("techStack", {})
                .get("monorepo", {})
                .get("structure", {})
                .get("apps", ["web"])
            )
    except (IOError, json.JSONDecodeError):
        pass
    return apps


def has_v2_structure(udocs_root):
    """Check if the v2 common/ directory exists."""
    return os.path.isdir(os.path.join(udocs_root, "common"))


def get_doc_path(udocs_root, doc_name, app=None):
    """
    Resolve document path based on v2 or v1 structure.
    Root docs: {udocs_root}/{doc}
    Common docs: common/{phase}/{doc}
    App docs: {app}/{phase}/{doc}
    """
    prefix = doc_name[0]
    phase_map = {
        "1": "01-plan",
        "2": "02-design",
        "3": "03-dev",
        "4": "04-check",
        "5": "05-act",
    }
    phase_dir = phase_map.get(prefix, "")

    common_docs = [
        "1_Roadmap_PM.md",
        "1_Index_PM.md",
        "2_ERD_SA.md",
        "2_UXGuide_UX.md",
        "3_UIComponents_UX.md",
        "3_DesignToken_UX.md",
        "5_IterationLog_RA.md",
        "5_Retrospective_PM.md",
    ]

    if has_v2_structure(udocs_root):
        if doc_name in common_docs:
            return os.path.join(udocs_root, "common", phase_dir, doc_name)
        return os.path.join(udocs_root, app or "web", phase_dir, doc_name)

    # v1 fallback
    return os.path.join(udocs_root, phase_dir, doc_name)


# ============================================================
# Criteria Check Functions
# ============================================================


def check_defects(udocs_root):
    """
    Criterion 2: No Critical or Major defects across ALL apps.
    Parses {app}/04-check/4_Report_QA.md for defect severity.
    """
    apps = get_apps(udocs_root)
    result = {
        "criterion": "No Critical/Major Defects",
        "passed": False,
        "critical_count": 0,
        "major_count": 0,
        "details": [],
    }

    for app in apps:
        filepath = get_doc_path(udocs_root, "4_Report_QA.md", app)

        if not os.path.exists(filepath):
            result["details"].append(f"[{app}] 4_Report_QA.md not found")
            # No QA report means no defects recorded for this app
            continue

        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
        except (IOError, UnicodeDecodeError) as e:
            result["details"].append(f"[{app}] Cannot read file: {e}")
            continue

        # Count Critical and Major defects (not resolved/closed)
        # Pattern: | ID | Title | Severity | Status | ...
        table_rows = re.findall(
            r"^\|([^|]+)\|([^|]+)\|([^|]+)\|([^|]+)\|", content, re.MULTILINE
        )

        for row in table_rows:
            cells = [c.strip() for c in row]
            if cells[0].startswith("-") or cells[0].lower() in ("id", "#", "no"):
                continue

            severity = cells[2].strip().lower() if len(cells) > 2 else ""
            status = cells[3].strip().lower() if len(cells) > 3 else ""

            # Skip resolved/closed defects
            if status in ("resolved", "closed", "fixed", "done"):
                continue

            if severity == "critical":
                result["critical_count"] += 1
                result["details"].append(f"[{app}] Critical: {cells[0]} - {cells[1]}")
            elif severity == "major":
                result["major_count"] += 1
                result["details"].append(f"[{app}] Major: {cells[0]} - {cells[1]}")

    result["passed"] = result["critical_count"] == 0 and result["major_count"] == 0
    return result


def check_fr_completion(udocs_root):
    """
    Criterion 3: All FR (Functional Requirements) implemented across ALL apps.
    Parses {app}/01-plan/1_SRS_RA.md for FR status.
    """
    apps = get_apps(udocs_root)
    result = {
        "criterion": "All FR Implemented",
        "passed": False,
        "total_fr": 0,
        "implemented_fr": 0,
        "unimplemented_fr": 0,
        "details": [],
    }

    for app in apps:
        filepath = get_doc_path(udocs_root, "1_SRS_RA.md", app)

        if not os.path.exists(filepath):
            result["details"].append(f"[{app}] 1_SRS_RA.md not found")
            result["unimplemented_fr"] += 1  # count as failure
            continue

        try:
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
        except (IOError, UnicodeDecodeError) as e:
            result["details"].append(f"[{app}] Cannot read file: {e}")
            continue

        # Find FR entries: #### FR-NNN: Title
        # And check for implementation status markers
        fr_pattern = re.compile(r"^####\s+(FR-\d+):\s*(.+)", re.MULTILINE)
        matches = fr_pattern.findall(content)

        # Check status in table format or inline markers
        # Pattern: | FR-NNN | Title | Status |
        table_rows = re.findall(
            r"^\|\s*(FR-\d+)\s*\|([^|]+)\|([^|]+)\|", content, re.MULTILINE
        )

        if table_rows:
            # Table format
            for row in table_rows:
                fr_id = row[0].strip()
                fr_title = row[1].strip()
                fr_status = row[2].strip().lower()

                result["total_fr"] += 1
                if fr_status in ("done", "implemented", "complete", "completed"):
                    result["implemented_fr"] += 1
                else:
                    result["unimplemented_fr"] += 1
                    result["details"].append(
                        f"[{app}] Unimplemented: {fr_id} - {fr_title} ({fr_status})"
                    )
        elif matches:
            # Heading format — count headings as total, check for status markers
            for fr_id, fr_title in matches:
                result["total_fr"] += 1
                # Look for status marker after the heading
                status_pattern = re.compile(
                    rf"####\s+{re.escape(fr_id)}.*?(?:Status|Implementation):\s*(\w+)",
                    re.DOTALL,
                )
                status_match = status_pattern.search(content)
                if status_match and status_match.group(1).lower() in (
                    "done",
                    "implemented",
                    "complete",
                    "completed",
                ):
                    result["implemented_fr"] += 1
                else:
                    result["unimplemented_fr"] += 1
                    result["details"].append(f"[{app}] Unimplemented: {fr_id} - {fr_title}")
        else:
            result["details"].append(f"[{app}] No FR entries found in SRS")

    if result["total_fr"] == 0 and result["unimplemented_fr"] == 0:
        result["details"].append("No FR entries found across all apps")
    else:
        result["passed"] = result["unimplemented_fr"] == 0

    return result


def check_build():
    """
    Criterion 4: Build succeeds (bun run build).
    """
    result = {
        "criterion": "Build Success",
        "passed": False,
        "details": [],
    }

    try:
        proc = subprocess.run(
            ["bun", "run", "build"],
            capture_output=True,
            text=True,
            timeout=120,
        )
        if proc.returncode == 0:
            result["passed"] = True
            result["details"].append("Build completed successfully")
        else:
            result["details"].append(f"Build failed (exit code {proc.returncode})")
            # Include last few lines of stderr
            stderr_lines = proc.stderr.strip().split("\n")
            for line in stderr_lines[-5:]:
                if line.strip():
                    result["details"].append(f"  {line.strip()}")
    except FileNotFoundError:
        result["details"].append("bun command not found")
    except subprocess.TimeoutExpired:
        result["details"].append("Build timed out (120s)")
    except Exception as e:
        result["details"].append(f"Build error: {e}")

    return result


# ============================================================
# Main
# ============================================================


def main():
    # Determine .u-maker/docs path
    if len(sys.argv) > 1:
        udocs_root = sys.argv[1]
    else:
        udocs_root = os.path.join(os.getcwd(), ".u-maker/docs")

    print("=" * 60)
    print("  u-maker: Exit Criteria Check")
    print(f"  Path: {udocs_root}")
    print("=" * 60)
    print()

    # Run all 3 criteria checks
    criteria = []

    print("[1/3] Checking defect status (all apps)...")
    criteria.append(check_defects(udocs_root))

    print("[2/3] Checking FR completion (all apps)...")
    criteria.append(check_fr_completion(udocs_root))

    print("[3/3] Running build check...")
    criteria.append(check_build())

    # Display results
    print()
    print("=" * 60)
    print("  Results")
    print("=" * 60)

    all_passed = True
    for c in criteria:
        status = "PASS" if c["passed"] else "FAIL"
        if not c["passed"]:
            all_passed = False
        print(f"  [{status}] {c['criterion']}")
        for detail in c["details"]:
            print(f"         {detail}")

    # Overall result
    print()
    print("-" * 60)
    if all_passed:
        print("  RESULT: All exit criteria MET. Iteration can complete.")
    else:
        passed_count = sum(1 for c in criteria if c["passed"])
        print(
            f"  RESULT: {passed_count}/3 criteria met. Iteration continues."
        )
    print()

    # JSON output
    result = {
        "success": all_passed,
        "criteria": criteria,
        "summary": {
            "total": len(criteria),
            "passed": sum(1 for c in criteria if c["passed"]),
            "failed": sum(1 for c in criteria if not c["passed"]),
        },
    }

    print("--- JSON Result ---")
    print(json.dumps(result, indent=2, ensure_ascii=False))

    sys.exit(0 if all_passed else 1)


if __name__ == "__main__":
    main()
