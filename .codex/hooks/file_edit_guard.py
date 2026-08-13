#!/usr/bin/env python3
import json
import re
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


payload = json.load(sys.stdin)
tool_input = payload.get("tool_input", {})

if isinstance(tool_input, dict):
    command = str(tool_input.get("command", ""))
else:
    command = str(tool_input)

# Block modifications to real env files, but allow .env.example.
blocked_env_patterns = [
    r"(^|/)\.env($|\s)",
    r"(^|/)\.env\.(local|development|production|test|staging|preview)($|\s)",
    r"(^|/)\.env\.[A-Za-z0-9_.-]+($|\s)",
]

allowed_patterns = [
    r"(^|/)\.env\.example($|\s)",
    r"(^|/)example\.env($|\s)",
]

for allowed in allowed_patterns:
    command = re.sub(allowed, "", command)

for pattern in blocked_env_patterns:
    if re.search(pattern, command):
        deny(
            "Blocked edit to a protected .env file. "
            "Codex may edit .env.example, but not real environment files."
        )

sys.exit(0)