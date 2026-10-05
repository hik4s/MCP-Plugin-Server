#!/usr/bin/env python3
"""Protocol-transparent stdio bridge for a local MCP server.

The bridge deliberately does not parse MCP messages. It forwards the newline-
delimited JSON stream in both directions so that the upstream server can speak
whatever MCP protocol era the host negotiates (legacy or modern).

Configuration is read from the JSON file named by MCP_UPSTREAM_CONFIG.
Example:
{
  "command": "python",
  "args": ["C:/path/to/your_mcp_server.py"],
  "cwd": "C:/path/to/project",
  "env": {"EXAMPLE": "value"}
}

Security properties:
- shell=False / no command-string parsing
- secrets stay in the local config/environment, not in the plugin package
- diagnostics go to stderr, never stdout
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
import threading
from pathlib import Path
from typing import Any


def log(message: str) -> None:
    print(f"[mcp-bridge] {message}", file=sys.stderr, flush=True)


def load_config() -> dict[str, Any]:
    path_text = os.environ.get("MCP_UPSTREAM_CONFIG")
    if not path_text:
        raise RuntimeError("MCP_UPSTREAM_CONFIG is not set")

    path = Path(path_text)
    if not path.exists():
        raise FileNotFoundError(
            f"Upstream config not found: {path}. Copy config/upstream.example.json "
            f"to {path} and edit it for your local MCP server."
        )

    with path.open("r", encoding="utf-8") as fh:
        data = json.load(fh)

    if not isinstance(data, dict):
        raise ValueError("Upstream config must be a JSON object")

    command = data.get("command")
    if not isinstance(command, str) or not command.strip():
        raise ValueError("Upstream config requires a non-empty string: command")

    args = data.get("args", [])
    if not isinstance(args, list) or not all(isinstance(x, str) for x in args):
        raise ValueError("Upstream config field 'args' must be an array of strings")

    cwd = data.get("cwd")
    if cwd is not None and not isinstance(cwd, str):
        raise ValueError("Upstream config field 'cwd' must be a string when provided")

    env = data.get("env", {})
    if not isinstance(env, dict) or not all(
        isinstance(k, str) and isinstance(v, str) for k, v in env.items()
    ):
        raise ValueError("Upstream config field 'env' must be an object of strings")

    return data


def pump(source: Any, destination: Any, label: str, errors: list[BaseException], close_destination: bool = False) -> None:
    try:
        while True:
            chunk = source.readline()
            if not chunk:
                break
            destination.write(chunk)
            destination.flush()
    except BaseException as exc:  # pragma: no cover - defensive bridge shutdown path
        errors.append(exc)
        log(f"{label} pump stopped: {exc}")
    finally:
        try:
            destination.flush()
        except Exception:
            pass
        if close_destination:
            try:
                destination.close()
            except Exception:
                pass


def main() -> int:
    try:
        cfg = load_config()
        command = cfg["command"]
        args = cfg.get("args", [])
        cwd = cfg.get("cwd")
        child_env = os.environ.copy()
        child_env.update(cfg.get("env", {}))

        log(f"starting upstream MCP: {command} ({len(args)} args)")
        process = subprocess.Popen(
            [command, *args],
            cwd=cwd,
            env=child_env,
            stdin=subprocess.PIPE,
            stdout=subprocess.PIPE,
            stderr=sys.stderr,
            shell=False,
            bufsize=0,
        )

        assert process.stdin is not None
        assert process.stdout is not None

        errors: list[BaseException] = []
        to_child = threading.Thread(
            target=pump,
            args=(sys.stdin.buffer, process.stdin, "host->upstream", errors, True),
            daemon=True,
        )
        from_child = threading.Thread(
            target=pump,
            args=(process.stdout, sys.stdout.buffer, "upstream->host", errors),
            daemon=True,
        )
        to_child.start()
        from_child.start()

        # Wait for the upstream process. EOF on host stdin causes the input pump
        # to finish; the upstream server normally exits on its own.
        return_code = process.wait()

        try:
            process.stdin.close()
        except Exception:
            pass

        to_child.join(timeout=2)
        from_child.join(timeout=2)

        if errors:
            log(f"bridge observed {len(errors)} stream error(s)")
        if return_code != 0:
            log(f"upstream MCP exited with code {return_code}")
        return return_code

    except Exception as exc:
        log(f"bridge failed to start: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
