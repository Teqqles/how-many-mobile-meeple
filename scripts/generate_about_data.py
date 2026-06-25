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


def get_recent_changes():
    """Get all feat/fix commits from the last 30 days."""
    log_output = git("log", "--since=30 days ago", "--format=%s")
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


def get_version():
    with open("pubspec.yaml") as f:
        for line in f:
            if line.startswith("version:"):
                version = line.split(":", 1)[1].strip()
                return version.split("+")[0]
    return "unknown"


def parse_args():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--issues-file", help="Path to pre-fetched issues JSON file")
    return parser.parse_args()


def main():
    args = parse_args()
    version = get_version()

    if args.issues_file:
        print(f"Loading issues from {args.issues_file}...")
        with open(args.issues_file) as f:
            issues = json.load(f)
    else:
        print("Fetching open issues from GitHub...")
        issues = fetch_github_issues()

    print(f"Getting recent changes from last 30 days (current: {version})...")
    changes = get_recent_changes()

    data = {
        "version": version,
        "recent_changes": changes,
        "upcoming": issues,
    }

    with open(OUTPUT, "w") as f:
        json.dump(data, f, indent=2)

    print(f"\nWritten to: {OUTPUT}")
    print(f"Version: {version}")

    print(f"\n--- What's New (last 30 days, {len(changes)}) ---")
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
