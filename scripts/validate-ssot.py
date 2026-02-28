#!/usr/bin/env python3
"""
validate-ssot.py — SSoT Document Validation Script
u-ssot plugin

Validates:
  1. Common header fields (Owner, Status, Version, Last Updated)
  2. Folder structure (all 5 phase dirs exist)
  3. Related Docs links exist

Usage: python3 validate-ssot.py [u-docs-path]

Exit codes:
  0 — All validations passed
  1 — One or more validations failed
"""

import os
import re
import sys
import json


# ============================================================
# Configuration
# ============================================================

REQUIRED_PHASE_DIRS = [
    "01-plan",
    "02-design",
    "03-dev",
    "04-check",
    "05-act",
]

# Header field patterns
HEADER_PATTERNS = {
    "Owner": re.compile(r"^\s*-\s*\*\*Owner\*\*:\s*.+", re.MULTILINE),
    "Status": re.compile(
        r"^\s*-\s*\*\*Status\*\*:\s*(Draft|Review|Final)", re.MULTILINE
    ),
    "Version": re.compile(
        r"^\s*-\s*\*\*Version\*\*:\s*v\d+\.\d+\.\d+", re.MULTILINE
    ),
    "Last Updated": re.compile(
        r"^\s*-\s*\*\*Last Updated\*\*:\s*\d{4}-\d{2}-\d{2}", re.MULTILINE
    ),
}

RELATED_DOCS_PATTERN = re.compile(
    r"^\s*-\s*\*\*Related Docs\*\*:\s*.+", re.MULTILINE
)


# ============================================================
# Validation Functions
# ============================================================


def find_md_files(root_dir):
    """Recursively find all .md files under root_dir."""
    md_files = []
    for dirpath, _dirnames, filenames in os.walk(root_dir):
        for fname in sorted(filenames):
            if fname.endswith(".md"):
                md_files.append(os.path.join(dirpath, fname))
    return md_files


def validate_header(filepath, content):
    """Validate common SSoT header fields in a document."""
    issues = []

    for field_name, pattern in HEADER_PATTERNS.items():
        if not pattern.search(content):
            issues.append(f"Missing or invalid '{field_name}' header field")

    return issues


def validate_related_docs(filepath, content, udocs_root):
    """Validate that Related Docs links reference existing files."""
    issues = []

    match = RELATED_DOCS_PATTERN.search(content)
    if not match:
        issues.append("Missing 'Related Docs' header field")
        return issues

    line = match.group(0)

    # Extract markdown links [text](path)
    links = re.findall(r"\[([^\]]*)\]\(([^)]+)\)", line)

    for link_text, link_path in links:
        # Resolve relative paths from the document's directory
        doc_dir = os.path.dirname(filepath)
        resolved = os.path.normpath(os.path.join(doc_dir, link_path))

        if not os.path.exists(resolved):
            issues.append(f"Related doc link not found: {link_path}")

    return issues


def validate_folder_structure(udocs_root):
    """Validate that all 5 required phase directories exist."""
    issues = []

    for phase_dir in REQUIRED_PHASE_DIRS:
        full_path = os.path.join(udocs_root, phase_dir)
        if not os.path.isdir(full_path):
            issues.append(f"Missing phase directory: {phase_dir}/")

    return issues


# ============================================================
# Main
# ============================================================


def main():
    # Determine u-docs path
    if len(sys.argv) > 1:
        udocs_root = sys.argv[1]
    else:
        udocs_root = os.path.join(os.getcwd(), "u-docs")

    if not os.path.isdir(udocs_root):
        print(f"Error: u-docs directory not found at {udocs_root}")
        sys.exit(1)

    print("=" * 60)
    print("  u-ssot: SSoT Document Validation")
    print(f"  Path: {udocs_root}")
    print("=" * 60)
    print()

    total_files = 0
    passed_files = 0
    failed_files = 0
    all_issues = {}

    # 1. Validate folder structure
    print("[1/2] Validating folder structure...")
    structure_issues = validate_folder_structure(udocs_root)
    if structure_issues:
        for issue in structure_issues:
            print(f"  FAIL: {issue}")
    else:
        print("  PASS: All phase directories exist")
    print()

    # 2. Validate individual documents
    print("[2/2] Validating document headers...")
    md_files = find_md_files(udocs_root)

    if not md_files:
        print("  No .md files found in u-docs/")
        print()
    else:
        for filepath in md_files:
            total_files += 1
            rel_path = os.path.relpath(filepath, udocs_root)

            # Skip README files
            if os.path.basename(filepath).lower() == "readme.md":
                continue

            try:
                with open(filepath, "r", encoding="utf-8") as f:
                    content = f.read()
            except (IOError, UnicodeDecodeError) as e:
                all_issues[rel_path] = [f"Cannot read file: {e}"]
                failed_files += 1
                continue

            issues = []
            issues.extend(validate_header(filepath, content))
            issues.extend(validate_related_docs(filepath, content, udocs_root))

            if issues:
                all_issues[rel_path] = issues
                failed_files += 1
                print(f"  FAIL: {rel_path}")
                for issue in issues:
                    print(f"        - {issue}")
            else:
                passed_files += 1
                print(f"  PASS: {rel_path}")

    # Summary
    print()
    print("=" * 60)
    print("  Summary")
    print("=" * 60)
    print(f"  Total files scanned: {total_files}")
    print(f"  Passed: {passed_files}")
    print(f"  Failed: {failed_files}")
    print(f"  Structure issues: {len(structure_issues)}")
    print()

    # JSON output for programmatic consumption
    result = {
        "udocs_path": udocs_root,
        "total_files": total_files,
        "passed": passed_files,
        "failed": failed_files,
        "structure_issues": structure_issues,
        "file_issues": all_issues,
        "success": failed_files == 0 and len(structure_issues) == 0,
    }

    # Write JSON result to stdout marker
    print("--- JSON Result ---")
    print(json.dumps(result, indent=2, ensure_ascii=False))

    if result["success"]:
        print("\nAll validations PASSED.")
        sys.exit(0)
    else:
        print("\nSome validations FAILED.")
        sys.exit(1)


if __name__ == "__main__":
    main()
