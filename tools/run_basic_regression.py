#!/usr/bin/env python3
"""Run the project-level Godot basic regression suite.

The script talks to Godot MCP Pro through its bundled CLI. It intentionally
does not fall back to headless checks: the goal is to verify the editor-backed
runtime path used by the agents during development.
"""

from __future__ import annotations

import base64
import json
import subprocess
import sys
import time
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
CLI_PATH = ROOT / "resources" / "godot-mcp-pro-server" / "server" / "build" / "cli.js"
REQUIRED_MCP_AUTOLOADS = ("MCPGameInspector", "MCPInputService", "MCPScreenshot")


class CliError(RuntimeError):
    def __init__(self, command: list[str], returncode: int, output: str) -> None:
        self.command = command
        self.returncode = returncode
        self.output = output
        super().__init__(f"{' '.join(command)} failed with exit code {returncode}")


@dataclass
class CheckResult:
    id: str
    name: str
    status: str
    details: str = ""
    evidence: dict[str, Any] = field(default_factory=dict)


def now_stamp() -> str:
    return datetime.now().strftime("%Y%m%d-%H%M%S")


def iso_now() -> str:
    return datetime.now().astimezone().isoformat(timespec="seconds")


def extract_json(text: str) -> Any:
    decoder = json.JSONDecoder()
    for index, char in enumerate(text):
        if char not in "[{":
            continue
        try:
            value, _ = decoder.raw_decode(text[index:])
            return value
        except json.JSONDecodeError:
            continue
    raise ValueError("CLI output did not contain a JSON value")


def shorten(text: str, limit: int = 700) -> str:
    clean = " ".join(text.strip().split())
    if len(clean) <= limit:
        return clean
    return clean[: limit - 3] + "..."


def run_cli(args: list[str], timeout: int = 30) -> tuple[Any, str]:
    command = ["node", str(CLI_PATH), *args]
    try:
        completed = subprocess.run(
            command,
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
            check=False,
        )
    except FileNotFoundError as exc:
        raise CliError(command, 127, "Node.js was not found on PATH") from exc
    except subprocess.TimeoutExpired as exc:
        output = "\n".join(part for part in (exc.stdout, exc.stderr) if part)
        raise CliError(command, 124, output or f"Timed out after {timeout} seconds") from exc

    output = "\n".join(part for part in (completed.stdout, completed.stderr) if part).strip()
    if completed.returncode != 0:
        raise CliError(command, completed.returncode, output)
    return extract_json(output), output


def pass_check(check_id: str, name: str, details: str = "", **evidence: Any) -> CheckResult:
    return CheckResult(check_id, name, "passed", details, evidence)


def fail_check(check_id: str, name: str, details: str = "", **evidence: Any) -> CheckResult:
    return CheckResult(check_id, name, "failed", details, evidence)


def editor_error_count(payload: Any) -> int:
    if not isinstance(payload, dict):
        return 1
    if isinstance(payload.get("count"), int):
        return payload["count"]
    errors = payload.get("errors")
    if isinstance(errors, list):
        return len(errors)
    return 1


def write_screenshot(payload: Any, screenshot_path: Path) -> tuple[bool, str, dict[str, Any]]:
    if not isinstance(payload, dict):
        return False, "Screenshot payload was not an object", {}

    image_base64 = payload.get("image_base64")
    if isinstance(image_base64, str) and image_base64:
        try:
            data = base64.b64decode(image_base64, validate=True)
        except ValueError as exc:
            return False, f"Screenshot base64 decode failed: {exc}", {}
        screenshot_path.write_bytes(data)
        return (
            True,
            f"Saved screenshot to {screenshot_path.relative_to(ROOT)}",
            {
                "path": str(screenshot_path.relative_to(ROOT)).replace("\\", "/"),
                "width": payload.get("width"),
                "height": payload.get("height"),
                "format": payload.get("format", "png"),
            },
        )

    saved_path = payload.get("saved_path")
    if isinstance(saved_path, str) and saved_path:
        return True, f"Godot saved screenshot to {saved_path}", {"godot_path": saved_path}

    return False, "Screenshot payload did not contain image_base64 or saved_path", {}


def write_reports(run_dir: Path, started_at: str, finished_at: str, checks: list[CheckResult]) -> None:
    reports_dir = run_dir / "reports"
    reports_dir.mkdir(parents=True, exist_ok=True)
    passed = sum(1 for check in checks if check.status == "passed")
    failed = sum(1 for check in checks if check.status == "failed")
    payload = {
        "suite": "basic_regression",
        "started_at": started_at,
        "finished_at": finished_at,
        "project_root": str(ROOT),
        "run_dir": str(run_dir.relative_to(ROOT)).replace("\\", "/"),
        "summary": {
            "status": "passed" if failed == 0 else "failed",
            "passed": passed,
            "failed": failed,
            "total": len(checks),
        },
        "checks": [check.__dict__ for check in checks],
    }
    (reports_dir / "basic_regression.json").write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    lines = [
        "# Basic Regression Report",
        "",
        f"- Started: {started_at}",
        f"- Finished: {finished_at}",
        f"- Status: {payload['summary']['status']}",
        f"- Result: {passed} passed, {failed} failed, {len(checks)} total",
        "",
        "| ID | Status | Check | Details |",
        "| --- | --- | --- | --- |",
    ]
    for check in checks:
        details = check.details.replace("|", "\\|")
        lines.append(f"| {check.id} | {check.status} | {check.name} | {details} |")
    lines.append("")
    (reports_dir / "basic_regression.md").write_text("\n".join(lines), encoding="utf-8")


def print_summary(run_dir: Path, checks: list[CheckResult]) -> None:
    passed = sum(1 for check in checks if check.status == "passed")
    failed = sum(1 for check in checks if check.status == "failed")
    print("Basic regression result:")
    for check in checks:
        marker = "PASS" if check.status == "passed" else "FAIL"
        print(f"- [{marker}] {check.id} {check.name}: {check.details}")
    print(f"Reports: {run_dir.relative_to(ROOT) / 'reports'}")
    print(f"Summary: {passed} passed, {failed} failed, {len(checks)} total")


def run_basic_regression() -> int:
    started_at = iso_now()
    run_dir = ROOT / "tmp" / "tests" / f"run-{now_stamp()}"
    screenshots_dir = run_dir / "screenshots"
    (run_dir / "frames").mkdir(parents=True, exist_ok=True)
    (run_dir / "reports").mkdir(parents=True, exist_ok=True)
    screenshots_dir.mkdir(parents=True, exist_ok=True)

    checks: list[CheckResult] = []
    project_info: Any = None
    main_scene = "main"
    played_scene = False

    if not CLI_PATH.exists():
        checks.append(
            fail_check(
                "BR-001",
                "Godot MCP Pro CLI is available",
                f"Missing CLI at {CLI_PATH.relative_to(ROOT)}",
            )
        )
        write_reports(run_dir, started_at, iso_now(), checks)
        print_summary(run_dir, checks)
        return 1

    try:
        project_info, _ = run_cli(["project", "info"], timeout=35)
        checks.append(pass_check("BR-001", "Godot MCP Pro is reachable", "project info succeeded"))
    except Exception as exc:
        details = shorten(exc.output if isinstance(exc, CliError) else str(exc))
        checks.append(fail_check("BR-001", "Godot MCP Pro is reachable", details))

    try:
        if not isinstance(project_info, dict):
            raise ValueError("project info was not available")
        missing = [
            key
            for key in ("project_name", "godot_version", "main_scene")
            if not project_info.get(key)
        ]
        if missing:
            raise ValueError(f"missing fields: {', '.join(missing)}")
        main_scene = str(project_info["main_scene"])
        version = project_info.get("godot_version", {})
        version_text = version.get("string") if isinstance(version, dict) else str(version)
        checks.append(
            pass_check(
                "BR-002",
                "Project metadata is readable",
                f"{project_info['project_name']} / {version_text} / {main_scene}",
                main_scene=main_scene,
            )
        )
    except Exception as exc:
        checks.append(fail_check("BR-002", "Project metadata is readable", shorten(str(exc))))

    try:
        errors_before, _ = run_cli(["editor", "errors"], timeout=25)
        count = editor_error_count(errors_before)
        if count != 0:
            raise ValueError(f"editor reported {count} error(s)")
        checks.append(pass_check("BR-003", "Editor has no errors", "0 errors"))
    except Exception as exc:
        details = shorten(exc.output if isinstance(exc, CliError) else str(exc))
        checks.append(fail_check("BR-003", "Editor has no errors", details))

    try:
        play_result, _ = run_cli(["scene", "play", "--mode", main_scene], timeout=35)
        if not isinstance(play_result, dict) or play_result.get("playing") is not True:
            raise ValueError(f"unexpected play result: {play_result!r}")
        played_scene = True
        time.sleep(1.0)
        checks.append(pass_check("BR-004", "Main scene starts", f"started {main_scene}"))
    except Exception as exc:
        details = shorten(exc.output if isinstance(exc, CliError) else str(exc))
        checks.append(fail_check("BR-004", "Main scene starts", details, main_scene=main_scene))

    try:
        screenshot_payload, _ = run_cli(["editor", "screenshot"], timeout=35)
        ok, details, evidence = write_screenshot(
            screenshot_payload,
            screenshots_dir / "main_scene.png",
        )
        if not ok:
            raise ValueError(details)
        checks.append(pass_check("BR-005", "Main scene screenshot is captured", details, **evidence))
    except Exception as exc:
        details = shorten(exc.output if isinstance(exc, CliError) else str(exc))
        checks.append(fail_check("BR-005", "Main scene screenshot is captured", details))

    try:
        runtime_tree, _ = run_cli(["runtime", "tree", "--max_depth", "3"], timeout=30)
        tree = runtime_tree.get("tree") if isinstance(runtime_tree, dict) else None
        if not tree:
            raise ValueError("runtime tree payload did not contain tree")
        root_name = tree.get("name", "<unknown>") if isinstance(tree, dict) else "<unknown>"
        checks.append(pass_check("BR-006", "Runtime scene tree is readable", f"root: {root_name}"))
    except Exception as exc:
        details = shorten(exc.output if isinstance(exc, CliError) else str(exc))
        checks.append(fail_check("BR-006", "Runtime scene tree is readable", details))

    try:
        if not isinstance(project_info, dict):
            raise ValueError("project info was not available")
        autoloads = project_info.get("autoloads")
        if not isinstance(autoloads, dict):
            raise ValueError("autoloads field was not an object")
        missing = [name for name in REQUIRED_MCP_AUTOLOADS if name not in autoloads]
        if missing:
            raise ValueError(f"missing autoloads: {', '.join(missing)}")
        checks.append(
            pass_check(
                "BR-007",
                "MCP autoloads exist",
                ", ".join(REQUIRED_MCP_AUTOLOADS),
            )
        )
    except Exception as exc:
        checks.append(fail_check("BR-007", "MCP autoloads exist", shorten(str(exc))))

    try:
        stop_result, _ = run_cli(["scene", "stop"], timeout=25)
        if played_scene and (not isinstance(stop_result, dict) or stop_result.get("stopped") is not True):
            raise ValueError(f"unexpected stop result: {stop_result!r}")
        errors_after, _ = run_cli(["editor", "errors"], timeout=25)
        count = editor_error_count(errors_after)
        if count != 0:
            raise ValueError(f"editor reported {count} error(s) after stop")
        checks.append(pass_check("BR-008", "Scene stops cleanly", "stopped and 0 editor errors"))
    except Exception as exc:
        details = shorten(exc.output if isinstance(exc, CliError) else str(exc))
        checks.append(fail_check("BR-008", "Scene stops cleanly", details))

    finished_at = iso_now()
    write_reports(run_dir, started_at, finished_at, checks)
    print_summary(run_dir, checks)
    return 0 if all(check.status == "passed" for check in checks) else 1


if __name__ == "__main__":
    raise SystemExit(run_basic_regression())
