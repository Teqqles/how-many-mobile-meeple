#!/usr/bin/env python3
"""Generates CHANGELOG.md from git tags and conventional commits.

Uses the same parsing logic as generate_about_data.py to extract feat/fix
commits grouped by release tag.

Run locally:  python3 scripts/generate_changelog.py
Run in CI:    called by tag-release.yml after tagging
"""

import re
import subprocess
import sys
from datetime import datetime

sys.stdout.reconfigure(encoding="utf-8")

OUTPUT = "CHANGELOG.md"


def git(*args):
    result = subprocess.run(
        ["git", *args], capture_output=True, text=True, check=True
    )
    return result.stdout.strip()


def get_tags_descending():
    """Get all version tags sorted newest first."""
    output = git("tag", "--sort=-version:refname")
    tags = [t for t in output.splitlines() if re.match(r"^v\d+\.\d+\.\d+$", t)]
    return tags


def get_tag_date(tag):
    """Get the date a tag was created."""
    try:
        date_str = git("log", "-1", "--format=%ai", tag)
        return datetime.strptime(date_str[:10], "%Y-%m-%d").strftime("%Y-%m-%d")
    except Exception:
        return "unknown"


def get_commits_between(older, newer):
    """Get feat/fix commits between two refs."""
    range_spec = f"{older}..{newer}" if older else newer
    try:
        log_output = git("log", range_spec, "--format=%s")
    except subprocess.CalledProcessError:
        return []

    lines = [line.strip() for line in log_output.splitlines() if line.strip()]

    changes = []
    for line in lines:
        match = re.match(
            r"^(feat|fix)(?:\(([^)]*)\))?:\s*(.+?)(?:\s*\(#\d+\))?$",
            line,
            re.IGNORECASE,
        )
        if match:
            changes.append({
                "type": match.group(1).lower(),
                "scope": match.group(2) or "",
                "description": match.group(3).strip(),
            })

    return changes


def format_changes(changes):
    """Format changes into markdown sections."""
    features = [c for c in changes if c["type"] == "feat"]
    fixes = [c for c in changes if c["type"] == "fix"]

    lines = []
    if features:
        lines.append("### Added")
        for f in features:
            scope = f" **{f['scope']}:** " if f["scope"] else " "
            lines.append(f"-{scope}{f['description']}")
        lines.append("")

    if fixes:
        lines.append("### Fixed")
        for f in fixes:
            scope = f" **{f['scope']}:** " if f["scope"] else " "
            lines.append(f"-{scope}{f['description']}")
        lines.append("")

    return lines


def main():
    tags = get_tags_descending()

    if not tags:
        print("No version tags found.")
        return

    lines = [
        "# Changelog",
        "",
        "All notable changes to this project are documented here.",
        "This file is auto-generated from conventional commits on each release.",
        "",
    ]

    for i, tag in enumerate(tags):
        older = tags[i + 1] if i + 1 < len(tags) else None
        date = get_tag_date(tag)
        changes = get_commits_between(older, tag)

        if not changes:
            continue

        lines.append(f"## [{tag}] - {date}")
        lines.append("")
        lines.extend(format_changes(changes))

    with open(OUTPUT, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    print(f"Written {OUTPUT} with {len(tags)} releases")


if __name__ == "__main__":
    main()
