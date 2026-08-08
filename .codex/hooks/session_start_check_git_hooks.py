#!/usr/bin/env python3
"""Codex SessionStart check for the repository Git hook environment.

This hook is intentionally non-blocking. It repairs the local Git hooks path
when possible and prints diagnostics for anything that still needs attention.
The actual push gate remains `.githooks/pre-push`.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path


EXPECTED_HOOKS_PATH = ".githooks"
REQUIRED_FILES = (
    ".githooks/pre-commit",
    ".githooks/pre-push",
    "tools/run_basic_regression.py",
    "tools/git_hooks/check_pre_push.py",
)


def run_git(args: list[str], cwd: Path | None = None) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=cwd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )


def find_git_root() -> Path | None:
    result = run_git(["rev-parse", "--show-toplevel"])
    if result.returncode != 0:
        print("[SessionStart] Not inside a Git repository; skipping Git hook environment check.")
        return None
    return Path(result.stdout.strip()).resolve()


def normalized_hooks_path(raw: str, root: Path) -> str:
    value = raw.strip().replace("\\", "/")
    if not value:
        return ""
    path = Path(value)
    if path.is_absolute():
        try:
            return path.resolve().relative_to(root).as_posix()
        except ValueError:
            return path.resolve().as_posix()
    return value.removeprefix("./")


def ensure_hooks_path(root: Path) -> bool:
    current = run_git(["config", "--get", "core.hooksPath"], cwd=root)
    raw = current.stdout if current.returncode == 0 else ""
    normalized = normalized_hooks_path(raw, root)
    if normalized == EXPECTED_HOOKS_PATH:
        print("[SessionStart] Git hooks path is already .githooks.")
        return True

    repair = run_git(["config", "core.hooksPath", EXPECTED_HOOKS_PATH], cwd=root)
    if repair.returncode == 0:
        previous = raw.strip() or "<unset>"
        print(f"[SessionStart] Updated git core.hooksPath from {previous} to {EXPECTED_HOOKS_PATH}.")
        return True

    message = (repair.stderr or repair.stdout or "unknown error").strip()
    print(f"[SessionStart] Failed to update core.hooksPath: {message}")
    return False


def check_required_files(root: Path) -> bool:
    ok = True
    for relative in REQUIRED_FILES:
        path = root / relative
        if path.exists():
            print(f"[SessionStart] Found {relative}.")
        else:
            print(f"[SessionStart] Missing {relative}.")
            ok = False
    return ok


def check_commands() -> bool:
    ok = True
    if shutil.which("node"):
        print("[SessionStart] Node.js is available.")
    else:
        print("[SessionStart] Node.js is missing; Godot MCP Pro CLI and pre-push regression may fail.")
        ok = False

    if shutil.which("python") or shutil.which("python3") or shutil.which("py"):
        print("[SessionStart] Python is available.")
    else:
        print("[SessionStart] Python is missing; project hooks may fail.")
        ok = False
    return ok


def main() -> int:
    root = find_git_root()
    if root is None:
        return 0

    print(f"[SessionStart] Checking Git hook environment for {root}.")
    hooks_ok = ensure_hooks_path(root)
    files_ok = check_required_files(root)
    commands_ok = check_commands()

    if hooks_ok and files_ok and commands_ok:
        print("[SessionStart] Git hook environment is ready.")
    else:
        print("[SessionStart] Git hook environment needs attention; push gate may fail until fixed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
