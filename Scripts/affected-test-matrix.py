#!/usr/bin/env python3
#
# This source file is part of the Stanford Spezi open-source project
#
# SPDX-FileCopyrightText: 2026 Stanford University and the project authors (see CONTRIBUTORS.md)
#
# SPDX-License-Identifier: MIT
#
# Maps a list of changed files to the set of affected packages and emits TWO GitHub Actions job
# matrices: one for unit tests (run on GitHub-hosted runners) and one for UI tests (run on the
# custom/self-hosted runner). Used by .github/workflows/tests.yml so only the tests of packages
# whose code actually changed are run — and whenever a package's unit tests run, its UI tests do too.
#
# The logical sub-packages are defined in the repo-root packages.toml:
#   platforms = the platforms its unit tests run on (subject to the temporary CI_PLATFORMS limit)
#   uiTests   = the platforms its UI tests run on, straight from the UITests project's Xcode config
#               (NOT subject to CI_PLATFORMS — absent for packages with no UITests project)
# The dir -> package map used for change detection is derived from each package's targets+tests.
#
# Usage:
#   affected-test-matrix.py <changed-files.txt>     # one path per line; or the literal __ALL__
#   git diff --name-only A B | affected-test-matrix.py
#
# Emits (to stdout, GITHUB_OUTPUT format):
#   matrix={"include":[{"package":"SpeziAccount","platform":"macOS"}, ...]}        # unit tests
#   ui_matrix={"include":[{"package":"SpeziViews","platform":"iPadOS"}, ...]}      # UI tests
#   has_jobs=true|false
#   has_ui_jobs=true|false
#   affected=SpeziAccount,SpeziViews
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

# TEMPORARY: limit UNIT-test scheduling to these platforms (macCatalyst/visionOS/tvOS excluded for
# now — remove from this tuple to restore). Linux runs on GitHub-hosted ubuntu.
CI_PLATFORMS = ("iOS", "macOS", "watchOS", "Linux")

# TEMPORARY: limit UI-test scheduling to these platforms. The full per-project set (from packages.toml
# `uiTests`) is iOS/iPadOS/visionOS; iPadOS + visionOS are disabled for now — add them back here to re-enable.
UI_PLATFORMS = ("iOS",)

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

    unit, ui = [], []
    for pkg in sorted(affected):
        info = PKGS[pkg]
        for platform in info["platforms"]:
            if platform in CI_PLATFORMS:  # TEMPORARY unit-test platform limit (see CI_PLATFORMS above)
                unit.append({"package": pkg, "platform": platform})
        for platform in info.get("uiTests", []):  # UI tests: per-project platforms from packages.toml
            if platform not in UI_PLATFORMS:  # TEMPORARY UI-test platform limit (see UI_PLATFORMS above)
                continue
            ui.append({"package": pkg, "platform": platform})

    lines = [
        f'matrix={json.dumps({"include": unit})}',
        f'ui_matrix={json.dumps({"include": ui})}',
        f'has_jobs={"true" if unit else "false"}',
        f'has_ui_jobs={"true" if ui else "false"}',
        f'affected={",".join(sorted(affected)) if affected else "(none)"}',
    ]
    sys.stdout.write("\n".join(lines) + "\n")
    sys.stderr.write(
        f"[affected-test-matrix] run_all={run_all} affected={sorted(affected)} "
        f"unit_jobs={len(unit)} ui_jobs={len(ui)}\n"
    )

if __name__ == "__main__":
    main()
