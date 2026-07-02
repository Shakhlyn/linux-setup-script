#!/usr/bin/env python3
import json
import re
import shlex
import sys


def deny(reason: str):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": reason
        }
    }))
    sys.exit(0)


def get_command(payload: dict) -> str:
    tool_input = payload.get("tool_input", {})
    if isinstance(tool_input, dict):
        return str(tool_input.get("command", ""))
    return ""


payload = json.load(sys.stdin)
command = get_command(payload)
normalized = " ".join(command.strip().split())

if not normalized:
    sys.exit(0)

# 1. Block destructive shell commands.
destructive_shell_patterns = [
    r"\brm\s+(-[^\s]*[rf][^\s]*|-[^\s]*[fr][^\s]*)\b",
    r"\brm\s+.*\s(/|\.\.|~|\$HOME)\b",
    r"\bfind\b.+\b-delete\b",
    r"\btruncate\s+-s\s+0\b",
    r">\s*(\.env|\.env\.[A-Za-z0-9_.-]+)\b",
    r"\bdd\s+.*\bof=",
    r"\bmkfs(\.[a-z0-9]+)?\b",
    r"\bchmod\s+-R\s+777\b",
    r"\bchown\s+-R\b",
    r"\bsudo\b",
    r"\bcurl\b.*\|\s*(sh|bash|zsh)",
    r"\bwget\b.*\|\s*(sh|bash|zsh)",
    r"\bnpm\s+.*--force\b",
    r"\bpnpm\s+.*--force\b",
    r"\byarn\s+.*--force\b",
]

for pattern in destructive_shell_patterns:
    if re.search(pattern, normalized, flags=re.IGNORECASE):
        deny(f"Blocked destructive shell command: {normalized}")

# 2. Block dangerous git commands.
dangerous_git_patterns = [
    r"\bgit\s+reset\s+--hard\b",
    r"\bgit\s+clean\s+-[^\s]*f",
    r"\bgit\s+push\s+.*--force\b",
    r"\bgit\s+push\s+.*-f\b",
    r"\bgit\s+checkout\s+--\s+\.",
    r"\bgit\s+restore\s+.*\s\.",
    r"\bgit\s+restore\s+--staged\s+\.",
    r"\bgit\s+rebase\b",
    r"\bgit\s+filter-branch\b",
    r"\bgit\s+gc\s+--prune=now\b",
    r"\bgit\s+branch\s+-D\b",
]

for pattern in dangerous_git_patterns:
    if re.search(pattern, normalized, flags=re.IGNORECASE):
        deny(f"Blocked dangerous git command: {normalized}")

# 4. Block direct shell edits to .env files.
env_file_patterns = [
    r"(^|\s)(\.env|\.env\.[A-Za-z0-9_.-]+)(\s|$)",
    r">\s*(\.env|\.env\.[A-Za-z0-9_.-]+)\b",
    r"\b(touch|cp|mv|rm|sed|awk|perl|python|node|tee|cat|echo|printf|nano|vim|vi|code)\b.*\s\.env(\.|$|\s)",
]

for pattern in env_file_patterns:
    if re.search(pattern, normalized, flags=re.IGNORECASE):
        deny(
            "Blocked command that touches .env files. "
            "Use .env.example for documentation and edit real .env files manually."
        )

sys.exit(0)