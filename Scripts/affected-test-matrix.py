#!/usr/bin/env python3
#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#
# Maps a list of changed files to the set of affected packages and emits a GitHub Actions
# job matrix (one job per affected package x platform). Used by .github/workflows/tests.yml
# to run only the tests of packages whose code actually changed.
#
# Usage:
#   affected-test-matrix.py <changed-files.txt>     # one path per line; or the literal __ALL__
#   git diff --name-only A B | affected-test-matrix.py
#
# Emits (to stdout, GITHUB_OUTPUT format):
#   matrix={"include":[{"package":"SpeziAccount","platform":"macOS"}, ...]}
#   has_jobs=true|false
#   affected=SpeziAccount,SpeziHealthKit
import json, os, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
M = json.load(open(os.path.join(ROOT, "Scripts", "test-matrix.json")))
DIR2PKG = M["dir_to_package"]
PKGS = M["packages"]

# Any change to these means "run everything" (shared manifest / test infra / CI / lint config).
GLOBAL_PREFIXES = (
    "Package.swift", "Package@", "Package.resolved",
    ".swiftlint.yml", ".github/", "Scripts/", "Tests/TestPlans/", ".swiftpm/",
)

def read_changed():
    src = open(sys.argv[1]) if len(sys.argv) > 1 and sys.argv[1] != "-" else sys.stdin
    return [ln.strip() for ln in src if ln.strip()]

def main():
    changed = read_changed()
    run_all = False
    affected = set()
    for path in changed:
        if path == "__ALL__" or path.startswith(GLOBAL_PREFIXES):
            run_all = True
            break
        parts = path.split("/")
        if len(parts) >= 2 and parts[0] in ("Sources", "Tests"):
            pkg = DIR2PKG.get(parts[1])
            if pkg:
                affected.add(pkg)
        # files elsewhere (root docs, etc.) affect no package

    if run_all:
        affected = set(PKGS.keys())

    include = []
    for pkg in sorted(affected):
        for platform in PKGS[pkg]["platforms"]:
            include.append({"package": pkg, "platform": platform})

    out = os.environ.get("GITHUB_OUTPUT")
    lines = [
        f'matrix={json.dumps({"include": include})}',
        f'has_jobs={"true" if include else "false"}',
        f'affected={",".join(sorted(affected)) if affected else "(none)"}',
    ]
    sys.stdout.write("\n".join(lines) + "\n")
    sys.stderr.write(f"[affected-test-matrix] run_all={run_all} affected={sorted(affected)} jobs={len(include)}\n")

if __name__ == "__main__":
    main()
