# Oracle-Decompiler ![Version](https://img.shields.io/badge/Version-V_1.0.0-8A2BE2.svg) ![License](https://img.shields.io/badge/License-All_Rights_Reserved-orange.svg) ![Discord](https://img.shields.io/badge/Discord-join-5865F2.svg)

![Oracle-Decompiler](Assets/Banner.png)

## > Discord server [here](https://discord.gg/wx4ThpAsmw)

- A decompiler & game copier for **Luau** (Roblox's Lua-based language). Oracle takes a raw `.luac` bytecode, an `.rbxm` model, or an entire `.rbxl` place and rebuilds the source behind it - every script read back through **real Luau opcodes** and returned in the Oracle **house style**: the `UniversalSynSaveInstance` stamp on top, engine banners stripped, recovered function names printed as real names.
- Whole-game downloads that **open in Studio**: you get a ZIP of `.lua` files at their folder paths plus the rebuilt place file; big games rebuild on the Download click so the server never runs out of time.
- The **translator**: drop a game you downloaded earlier back in and every script that carries a decompiler fingerprint is pushed through real opcodes again and returned in the current house style - in one drop, even for 700-script games. A game's own hand-written source is never touched and stays byte-pure.
- Powered by the [LunaUX](https://github.com/boydev-1444/lunaux-decompiler) engine (Apache-2.0); house-style lineage: Konstant, medal and the original Oracle builds. Free decompilation service - **no API key on any path**.

> Disclaimer: Oracle is honest by design. When the engine cannot read something (ancient idioms today's Luau compiler rejects, truncated blobs), that script is kept **byte-pure** with a plain-language note - never silently mangled, never half-saved. Documents and separators always say exactly how many scripts were decompiled / translated / kept. This decompiler receives regular updates to fix all those bugs.

# Using it

Oracle runs online at [oracle-websitel.vercel.app](https://oracle-websitel.vercel.app/), and the executor script runs inside any executor:

- **[Web demo](https://oracle-websitel.vercel.app/)** - drop a `.luac` / `.rbxm` / `.rbxmx` / `.rbxl` / `.rbxlx` file (or paste base64 bytecode) and read the document: every script at its place path with an honest status line. Works straight from `file://` too.
- **[Downloads](https://oracle-websitel.vercel.app/)** - the ZIP of `.lua` files in their folder paths, and the whole rebuilt game file when the input was a place. Big files travel in pieces (`oracle_upload`) and big answers come back in pieces (`oracle_result`), so multi-megabyte games never hit a host body cap.
- **Executor** - paste the [one-liner](#api-script) into Solara's Autoexec folder (or any executor with `request`, `getscriptbytecode` and `writefile`): the Oracle panel opens in-game, **DECOMPILE GAME** writes every script to `workspace/Oracle/<GameName>/<FullPath>.lua` in the house style, **SAVE .RBXL** drops the whole game file for the website flow, **DISCORD** copies the invite.

# API Script

- Paste it into an environment that supports `request`, `base64encode` / `crypt` and `getscriptbytecode`. **No API key needed** for decompile / copy.

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nexusstudioserver-rgb/Oracle-Decompiler/main/script"))()
```

- Clients for Luau and Python are in [Scripts/](Scripts); any HTTP client works - the protocol below is the whole contract.

# API Options

Everything is plain JSON over HTTP on `/api/decompile`. Passed as the `options` field:

| Option | Default | What it does |
| --- | --- | --- |
| `transformCompoundAssignments` | `false` (house) | keeps `x = x + n` instead of `x += n`, the way the Original reads |

| Request | Answer |
| --- | --- |
| `GET /api/decompile` | health JSON (build stamp, engine, supported extensions) |
| `POST {"bytecode"\|"script": "<base64>", "filename": "..."}` | one compiled Luau chunk -> house-style text; a whole place file -> the full document |
| `POST {"oracle_upload": {"id","index","total","filename"}, "chunk": "<base64 piece>"}` then `{"oracle_upload": {"id","finish":true,...}}` | one piece of a big file (hosts cap a single body) |
| `POST {"oracle_result": {"id", "part"}}` | one piece of a big answer |
| `POST {"oracle_build": {"id"}}` then `oracle_result` parts | the whole rebuilt game file for Download |

**Join the Discord for builds, help and copy-games nights: [discord.gg/wx4ThpAsmw](https://discord.gg/wx4ThpAsmw)**
