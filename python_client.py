#!/usr/bin/env python3
"""Oracle raw-engine client - Python 3, stdlib only.  No API key.
Returns the engine answer as-is; the styled product is the `script` one-liner.

    from python_client import decompile_bytes
    text = decompile_bytes(open("Kill.luac", "rb").read(), "Workspace/Kill.luac")

or from the command line:

    python3 python_client.py Kill.luac [out.lua]

Send a compiled Luau chunk and get the house-style source back (the
UniversalSynSaveInstance stamp on top).  Whole place files work too: the same
endpoint unpacks .rbxl/.rbxlx/.rbxm/.rbxmx and answers with the full document;
very big answers arrive "parked" as JSON ({"ok": true, "result": {"id", "parts"}})
- pull them piece by piece with {"oracle_result": {"id": ..., "part": k}}.
"""
import base64
import json
import sys
import urllib.request

API = "https://lunaux-decompiler.dev/api/decompile"  # public engine, no key


def post(body, api=API, timeout=90):
    req = urllib.request.Request(
        api, data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json",
                 "User-Agent": "OracleLocalBridge/2.0 (local desktop tool)"},
        method="POST")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read().decode("utf-8", "replace")


def decompile_bytes(raw, filename="chunk.luac", api=API):
    """raw bytes of a compiled chunk (or a whole place file) -> text."""
    answer = post({"bytecode": base64.b64encode(raw).decode("ascii"),
                   "filename": filename,
                   "options": {"transformCompoundAssignments": False}}, api)
    if answer.lstrip().startswith("{"):
        meta = json.loads(answer)
        res = meta.get("result") or {}
        rid = meta.get("id") or res.get("id")
        parts = meta.get("parts") or res.get("parts")
        if rid and parts:
            return "".join(post({"oracle_result": {"id": rid, "part": k}}, api)
                           for k in range(parts))
    return answer


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        raise SystemExit(1)
    src = sys.argv[1]
    text = decompile_bytes(open(src, "rb").read(), src)
    if len(sys.argv) > 2:
        open(sys.argv[2], "w", encoding="utf-8").write(text)
        print("wrote %s (%d chars)" % (sys.argv[2], len(text)))
    else:
        print(text)
