#!/usr/bin/env bash
set -euo pipefail

input="$(cat)"

python3 - <<'PY' "$input"
import json
import re
import sys

payload = json.loads(sys.argv[1])

tool_name = str(payload.get("toolName") or payload.get("tool") or "")
arguments = payload.get("arguments") or {}
command = ""

if isinstance(arguments, dict):
    command = str(arguments.get("command") or arguments.get("args") or "")

if tool_name == "run_in_terminal" and re.search(r"(^|\s)(docker|docker compose|docker-compose|git)(\s|$)", command):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "ask",
            "permissionDecisionReason": "This command is a Docker or Git operation. It must not be executed automatically. Please ask the user to run it explicitly and only after the user gives approval."
        }
    }))
else:
    print(json.dumps({"continue": True}))
PY
