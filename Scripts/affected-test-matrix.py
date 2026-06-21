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
# The logical sub-packages (their source/test target dirs + platforms) are defined in the
# repo-root packages.toml; the dir -> package map used for change detection is derived from it
# (so a new target only needs to be added to packages.toml, never to a separate inverse map).
#
# Usage:
#   affected-test-matrix.py <changed-files.txt>     # one path per line; or the literal __ALL__
#   git diff --name-only A B | affected-test-matrix.py
#
# Emits (to stdout, GITHUB_OUTPUT format):
#   matrix={"include":[{"package":"SpeziAccount","platform":"macOS"}, ...]}
#   has_jobs=true|false
#   affected=SpeziAccount,SpeziHealthKit
import json, os, sys, tomllib

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
with open(os.path.join(ROOT, "packages.toml"), "rb") as f:
    PKGS = tomllib.load(f)

# dir (directly under Sources/ or Tests/) -> logical package, derived from each package's
# `targets` + `tests`. A change under Tests/<X>/UITests/... still routes via its <X> test dir.
DIR2PKG = {}
for _pkg, _info in PKGS.items():
    for _d in _info.get("targets", []) + _info.get("tests", []):
        DIR2PKG[_d] = _pkg

# Any change to these means "run everything" (shared manifest / test infra / CI / lint / pkg defs).
GLOBAL_PREFIXES = (
    "Package.swift", "Package@", "Package.resolved", "packages.toml",
    ".swiftlint.yml", ".github/", "Scripts/", "Tests/TestPlans/", ".swiftpm/",
)

# TEMPORARY: limit CI test scheduling to these platforms. A package is scheduled on a platform only
# if it both supports that platform (per packages.toml) and the platform is listed here. macCatalyst
# / visionOS / tvOS are deliberately left out for now. Linux is on and runs on GitHub-hosted ubuntu
# (see .github/workflows/tests.yml); Apple platforms run via run-package-tests.sh on macOS.
CI_PLATFORMS = ("iOS", "macOS", "watchOS", "Linux")

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
            if platform not in CI_PLATFORMS:  # TEMPORARY platform limit (see CI_PLATFORMS above)
                continue
            include.append({"package": pkg, "platform": platform})

    lines = [
        f'matrix={json.dumps({"include": include})}',
        f'has_jobs={"true" if include else "false"}',
        f'affected={",".join(sorted(affected)) if affected else "(none)"}',
    ]
    sys.stdout.write("\n".join(lines) + "\n")
    sys.stderr.write(f"[affected-test-matrix] run_all={run_all} affected={sorted(affected)} jobs={len(include)}\n")

if __name__ == "__main__":
    main()
