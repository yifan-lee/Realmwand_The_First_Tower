#!/usr/bin/env python3
"""Validate progress documentation in a Git pre-push hook."""

from __future__ import annotations

import argparse
import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
ZERO_SHA = "0" * 40
PROGRESS_RE = re.compile(r"^docs/progress/[^/]+\.md$")
VALID_STATUS_RE = re.compile(r"(通过|失败|阻断|未执行)")


@dataclass
class PushRef:
    local_ref: str
    local_sha: str
    remote_ref: str
    remote_sha: str

    @property
    def is_delete(self) -> bool:
        return self.local_sha == ZERO_SHA

    @property
    def is_new_remote_ref(self) -> bool:
        return self.remote_sha == ZERO_SHA

    @property
    def rev_spec(self) -> str:
        if self.is_new_remote_ref:
            return self.local_sha
        return f"{self.remote_sha}..{self.local_sha}"


def run_git(args: list[str], check: bool = True) -> subprocess.CompletedProcess[str]:
    completed = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if check and completed.returncode != 0:
        output = "\n".join(part for part in (completed.stdout, completed.stderr) if part).strip()
        raise RuntimeError(output or f"git {' '.join(args)} failed")
    return completed


def parse_push_refs(text: str) -> list[PushRef]:
    refs: list[PushRef] = []
    for raw_line in text.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        parts = line.split()
        if len(parts) != 4:
            raise ValueError(f"Invalid pre-push input line: {raw_line!r}")
        refs.append(PushRef(*parts))
    return refs


def read_stdin(args: argparse.Namespace) -> str:
    if args.stdin_file:
        return Path(args.stdin_file).read_text(encoding="utf-8")
    return sys.stdin.read()


def collect_names_and_patch(refs: list[PushRef]) -> tuple[set[str], str]:
    names: set[str] = set()
    patches: list[str] = []
    for ref in refs:
        if ref.is_delete:
            continue
        spec = ref.rev_spec
        names_result = run_git(["log", "--format=", "--name-only", spec, "--", "docs/progress"], check=False)
        patch_result = run_git(["log", "-p", "--format=", spec, "--", "docs/progress"], check=False)

        if names_result.returncode != 0 and not ref.is_new_remote_ref:
            spec = ref.local_sha
            names_result = run_git(["log", "--format=", "--name-only", spec, "--", "docs/progress"], check=False)
            patch_result = run_git(["log", "-p", "--format=", spec, "--", "docs/progress"], check=False)

        if names_result.returncode != 0:
            raise RuntimeError(names_result.stderr.strip() or "Unable to inspect pushed progress files")
        if patch_result.returncode != 0:
            raise RuntimeError(patch_result.stderr.strip() or "Unable to inspect pushed progress diff")

        for line in names_result.stdout.splitlines():
            normalized = line.strip().replace("\\", "/")
            if PROGRESS_RE.match(normalized):
                names.add(normalized)
        patches.append(patch_result.stdout)
    return names, "\n".join(patches)


def added_progress_text(patch: str) -> str:
    added: list[str] = []
    for line in patch.splitlines():
        if line.startswith("+++") or not line.startswith("+"):
            continue
        added.append(line[1:])
    return "\n".join(added)


def validate_progress(refs: list[PushRef]) -> int:
    active_refs = [ref for ref in refs if not ref.is_delete]
    if not active_refs:
        print("[pre-push] Only branch deletions detected; skipping progress checks.")
        return 0

    names, patch = collect_names_and_patch(active_refs)
    if not names:
        print("[pre-push] Refusing push: no docs/progress/*.md update found in pushed commits.")
        print("[pre-push] Add this session's progress entry before pushing.")
        return 1

    added_text = added_progress_text(patch)
    if "### 测试结果" not in added_text:
        print("[pre-push] Refusing push: progress update is missing `### 测试结果`.")
        return 1

    if not VALID_STATUS_RE.search(added_text):
        print("[pre-push] Refusing push: progress update lacks one of 通过 / 失败 / 阻断 / 未执行.")
        return 1

    print("[pre-push] Progress update includes test results.")
    for name in sorted(names):
        print(f"[pre-push] Checked: {name}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--stdin-file", help="Read pre-push stdin from a file")
    args = parser.parse_args()
    try:
        refs = parse_push_refs(read_stdin(args))
        if not refs:
            print("[pre-push] No refs received; skipping progress checks.")
            return 0
        return validate_progress(refs)
    except Exception as exc:
        print(f"[pre-push] Refusing push: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
