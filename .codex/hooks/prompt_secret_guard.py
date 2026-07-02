#!/usr/bin/env python3
import json
import re
import sys


def block(reason: str):
    print(json.dumps({
        "decision": "block",
        "reason": reason
    }))
    sys.exit(0)


payload = json.load(sys.stdin)
prompt = str(payload.get("prompt", ""))

secret_patterns = [
    # Generic assignments
    r"(?i)\b(api[_-]?key|secret|token|password|passwd|private[_-]?key|client[_-]?secret)\s*[:=]\s*['\"]?[A-Za-z0-9_\-./+=]{12,}",

    # OpenAI / common API keys
    r"\bsk-[A-Za-z0-9_-]{20,}\b",
    r"\bsk-proj-[A-Za-z0-9_-]{20,}\b",

    # GitHub tokens
    r"\bghp_[A-Za-z0-9_]{30,}\b",
    r"\bgithub_pat_[A-Za-z0-9_]{30,}\b",

    # AWS
    r"\bAKIA[0-9A-Z]{16}\b",
    r"\bASIA[0-9A-Z]{16}\b",
    r"(?i)\baws_secret_access_key\s*[:=]\s*['\"]?[A-Za-z0-9/+=]{30,}",

    # JWT
    r"\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b",

    # Private key blocks
    r"-----BEGIN (RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----",

    # URLs with embedded credentials
    r"\bhttps?://[^/\s:@]+:[^/\s:@]+@[^/\s]+",
]

for pattern in secret_patterns:
    if re.search(pattern, prompt):
        block(
            "Prompt appears to contain a secret, token, password, private key, or credential. "
            "Remove the secret and use a placeholder like YOUR_API_KEY instead."
        )

sys.exit(0)