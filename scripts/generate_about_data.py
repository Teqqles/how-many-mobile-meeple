#!/usr/bin/env python3
"""Generates lib/assets/about_data.json from GitHub issues and git version log.

Run via: make generate_about_data
"""

import json
import re
import subprocess
import sys
import urllib.request

sys.stdout.reconfigure(encoding="utf-8")

REPO = "Teqqles/how-many-mobile-meeple"
OUTPUT = "lib/assets/about_data.json"


def fetch_github_issues():
    url = f"https://api.github.com/repos/{REPO}/issues?state=open&per_page=30"
    req = urllib.request.Request(url, headers={"Accept": "application/vnd.github.v3+json"})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            issues = json.loads(resp.read())
    except Exception as e:
        print(f"  Warning: GitHub API request failed ({e}), using empty issues list")
        return []

    result = []
    for issue in issues:
        if "pull_request" in issue:
            continue
        labels = [label["name"] for label in issue.get("labels", [])]
        result.append({
            "number": issue["number"],
            "title": issue["title"],
            "labels": labels,
        })
    return result


def git(*args):
    result = subprocess.run(
        ["git", *args], capture_output=True, text=True, check=True
    )
    return result.stdout.strip()


def find_previous_minor_tag(version):
    """Find the latest tag from the previous minor version.

    E.g. if version is 2.8.1, find the highest 2.7.x tag.
    """
    match = re.match(r"^(\d+)\.(\d+)\.", version)
    if not match:
        return None

    major = int(match.group(1))
    minor = int(match.group(2))

    tags_output = git("tag", "--list", "--sort=-version:refname")
    tags = [t.strip() for t in tags_output.splitlines() if t.strip()]

    prev_minor = minor - 1
    prefix = f"v{major}.{prev_minor}."

    for tag in tags:
        if tag.startswith(prefix):
            return tag

    return None


def get_recent_changes(version):
    prev_tag = find_previous_minor_tag(version)
    if not prev_tag:
        return [], ""

    log_range = f"{prev_tag}..HEAD"
    log_output = git("log", log_range, "--format=%s")
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

    return changes, prev_tag


def get_version():
    with open("pubspec.yaml") as f:
        for line in f:
            if line.startswith("version:"):
                version = line.split(":", 1)[1].strip()
                return version.split("+")[0]
    return "unknown"


def main():
    version = get_version()

    print("Fetching open issues from GitHub...")
    issues = fetch_github_issues()

    print(f"Getting recent changes since previous minor (current: {version})...")
    changes, since_tag = get_recent_changes(version)

    data = {
        "version": version,
        "since_version": since_tag,
        "recent_changes": changes,
        "upcoming": issues,
    }

    with open(OUTPUT, "w") as f:
        json.dump(data, f, indent=2)

    print(f"\nWritten to: {OUTPUT}")
    print(f"Version: {version} (changes since: {since_tag})")

    print(f"\n--- Recent Changes since {since_tag} ({len(changes)}) ---")
    for change in changes:
        prefix = "+" if change["type"] == "feat" else "*"
        scope = f"({change['scope']}) " if change["scope"] else ""
        print(f"  {prefix} {scope}{change['description']}")
    if not changes:
        print("  (none)")

    print(f"\n--- Upcoming ({len(issues)}) ---")
    for issue in issues:
        labels = ", ".join(issue["labels"])
        tag = f" [{labels}]" if labels else ""
        print(f"  #{issue['number']} {issue['title']}{tag}")
    if not issues:
        print("  (none)")


if __name__ == "__main__":
    main()
