#!/usr/bin/env python3
"""
check-exit-criteria.py — Iteration Exit Criteria Checker
u-agent-ssot plugin

Checks 4 exit criteria for PDCA iteration completion:
  1. All backlog items are Done (5ACT_Backlog.md)
  2. No Critical/Major defects (4QA_Report.md)
  3. All FR items implemented (1A_SRS.md)
  4. Build succeeds (bun run build)

Usage: python3 check-exit-criteria.py [u-docs-path]

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

DOC_PATHS = {
    "backlog": "05-act/5ACT_Backlog.md",
    "qa_report": "04-check/4QA_Report.md",
    "srs": "01-plan/1A_SRS.md",
}


# ============================================================
# Criteria Check Functions
# ============================================================


def check_backlog(udocs_root):
    """
    Criterion 1: All backlog items must be Done.
    Parses 5ACT_Backlog.md for items with status != Done.
    """
    filepath = os.path.join(udocs_root, DOC_PATHS["backlog"])
    result = {
        "criterion": "Backlog All Done",
        "passed": False,
        "total_items": 0,
        "open_items": 0,
        "details": [],
    }

    if not os.path.exists(filepath):
        result["details"].append("5ACT_Backlog.md not found")
        # No backlog file means no open items
        result["passed"] = True
        return result

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except (IOError, UnicodeDecodeError) as e:
        result["details"].append(f"Cannot read file: {e}")
        return result

    # Parse table rows for status column
    # Expected format: | ID | Title | Status | ... |
    table_rows = re.findall(
        r"^\|([^|]+)\|([^|]+)\|([^|]+)\|", content, re.MULTILINE
    )

    for row in table_rows:
        cells = [c.strip() for c in row]
        # Skip header and separator rows
        if cells[0].startswith("-") or cells[0].lower() in ("id", "#", "no"):
            continue

        result["total_items"] += 1
        status = cells[2].strip() if len(cells) > 2 else ""

        if status.lower() != "done":
            result["open_items"] += 1
            result["details"].append(f"Open: {cells[0]} - {cells[1]} ({status})")

    result["passed"] = result["open_items"] == 0
    return result


def check_defects(udocs_root):
    """
    Criterion 2: No Critical or Major defects.
    Parses 4QA_Report.md for defect severity.
    """
    filepath = os.path.join(udocs_root, DOC_PATHS["qa_report"])
    result = {
        "criterion": "No Critical/Major Defects",
        "passed": False,
        "critical_count": 0,
        "major_count": 0,
        "details": [],
    }

    if not os.path.exists(filepath):
        result["details"].append("4QA_Report.md not found")
        # No QA report means no defects recorded
        result["passed"] = True
        return result

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except (IOError, UnicodeDecodeError) as e:
        result["details"].append(f"Cannot read file: {e}")
        return result

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
            result["details"].append(f"Critical: {cells[0]} - {cells[1]}")
        elif severity == "major":
            result["major_count"] += 1
            result["details"].append(f"Major: {cells[0]} - {cells[1]}")

    result["passed"] = result["critical_count"] == 0 and result["major_count"] == 0
    return result


def check_fr_completion(udocs_root):
    """
    Criterion 3: All FR (Functional Requirements) implemented.
    Parses 1A_SRS.md for FR status.
    """
    filepath = os.path.join(udocs_root, DOC_PATHS["srs"])
    result = {
        "criterion": "All FR Implemented",
        "passed": False,
        "total_fr": 0,
        "implemented_fr": 0,
        "unimplemented_fr": 0,
        "details": [],
    }

    if not os.path.exists(filepath):
        result["details"].append("1A_SRS.md not found")
        return result

    try:
        with open(filepath, "r", encoding="utf-8") as f:
            content = f.read()
    except (IOError, UnicodeDecodeError) as e:
        result["details"].append(f"Cannot read file: {e}")
        return result

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
                    f"Unimplemented: {fr_id} - {fr_title} ({fr_status})"
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
                result["details"].append(f"Unimplemented: {fr_id} - {fr_title}")

    if result["total_fr"] == 0:
        result["details"].append("No FR entries found in SRS")
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
    # Determine u-docs path
    if len(sys.argv) > 1:
        udocs_root = sys.argv[1]
    else:
        udocs_root = os.path.join(os.getcwd(), "u-docs")

    print("=" * 60)
    print("  u-agent-ssot: Exit Criteria Check")
    print(f"  Path: {udocs_root}")
    print("=" * 60)
    print()

    # Run all 4 criteria checks
    criteria = []

    print("[1/4] Checking backlog status...")
    criteria.append(check_backlog(udocs_root))

    print("[2/4] Checking defect status...")
    criteria.append(check_defects(udocs_root))

    print("[3/4] Checking FR completion...")
    criteria.append(check_fr_completion(udocs_root))

    print("[4/4] Running build check...")
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
            f"  RESULT: {passed_count}/4 criteria met. Iteration continues."
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
