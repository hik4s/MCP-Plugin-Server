---
name: local-dev-bridge
description: Use the local MCP bridge for code investigation, testing, debugging, and PowerShell workflows when the user asks to work with the user's own machine or remote development environment.
---

# Local Dev Bridge

Use the connected local MCP as the source of truth for the user's machine. Prefer its native tools (`read_file`, `list_directory`, `git_status`, `powershell_run`, and `run_command`) over inventing shell commands.

## Development workflow

1. Inspect before changing. Read relevant files, project metadata, logs, and git state.
2. Explain the diagnosis and the intended change.
3. Make the smallest useful change.
4. Run focused tests or validation after the change.
5. Report exactly what changed and what was verified.

## PowerShell and remote operations

Treat PowerShell execution, remote sessions, service changes, package installation, registry changes, firewall/network changes, credential handling, and deletion as actions that can change the user's environment.

Before an action with material side effects:
- show the command or a faithful summary;
- state the target host/path when relevant;
- request user approval before executing it.

Read-only inspection can be performed without approval when the host's permission model allows it.

Never request, echo, or store passwords, access tokens, private keys, or other secrets in chat or plugin files. Prefer existing authenticated sessions and environment-managed credentials.

## When MCP tools are unavailable

Do not pretend the local machine is reachable. Explain that the bridge is not connected or that its upstream MCP failed to start, then use only information available in the conversation.
