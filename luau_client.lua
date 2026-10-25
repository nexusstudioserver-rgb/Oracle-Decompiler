--[[
	Oracle API client for Luau (executor or any Luau environment with `request`)
	=========================================================================
	No API key. One POST, one honest answer.

	local Oracle = loadstring(game:HttpGet(
		"https://oracle-websitel.vercel.app/Scripts/luau_client.lua"))()

	local text, err = Oracle.decompile(bytecodeString, "Workspace/Kill.luac")
	if text then
		print(text)               -- house-style source, stamp on top
	else
		warn("Oracle: " .. err)   -- plain-language reason, never a silent fail
	end

	`bytecodeString` is RAW Luau bytecode (getscriptbytecode(script), or the
	bytes of a .luac file). A whole place file works too - the same endpoint
	unpacks .rbxl/.rbxlx/.rbxm/.rbxmx and answers with the full document.
]]

local ORACLE_API = "https://lunaux-decompiler.dev/api/decompile"  -- public engine, no key

local httpRequest = request
	or http_request
	or (http and http.request)
	or (syn and syn.request)
	or (fluxus and fluxus.request)
	or (krnl and krnl.request)

local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function pure_b64(s)
	local parts = {}
	local len = #s
	local i = 1
	while i <= len do
		local b1 = s:byte(i)
		local b2 = s:byte(i + 1) or 0
		local b3 = s:byte(i + 2) or 0
		local n = b1 * 65536 + b2 * 256 + b3
		local c1 = math.floor(n / 262144) % 64
		local c2 = math.floor(n / 4096) % 64
		local c3 = math.floor(n / 64) % 64
		local c4 = n % 64
		local chunk = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1)
			.. B64:sub(c3 + 1, c3 + 1) .. B64:sub(c4 + 1, c4 + 1)
		local remaining = len - i + 1
		if remaining == 1 then
			chunk = chunk:sub(1, 2) .. "=="
		elseif remaining == 2 then
			chunk = chunk:sub(1, 3) .. "="
		end
		parts[#parts + 1] = chunk
		i = i + 3
	end
	return table.concat(parts)
end

-- NOTE: the globals on the right are the ENVIRONMENT's encoders; the local
-- wrapper must NOT share their name or the chain would find itself.
local base64_encode_final = (crypt and (crypt.base64encode or crypt.base64_encode))
	or base64_encode or base64encode or (base64 and base64.encode) or pure_b64

local function jsonEscape(s)
	return (tostring(s):gsub('[\\"]', "\\%0"):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t"))
end

local Oracle = {}
Oracle.API = ORACLE_API

--- Decompile one compiled Luau chunk (or a whole place file) into house style.
--- @param raw string raw bytes (bytecode or a .rbxl/.rbxm file)
--- @param filename string? label for honest notes
--- @return string|nil text, string|nil err
function Oracle.decompile(raw, filename)
	if httpRequest == nil then
		return nil, "no `request` function in this environment"
	end
	if type(raw) ~= "string" or raw == "" then
		return nil, "nothing to send - empty input"
	end
	local body = string.format('{"bytecode":"%s","filename":"%s","options":{"transformCompoundAssignments":false}}',
		base64_encode_final(raw), jsonEscape(filename or "chunk.luac"))
	local ok, res = pcall(httpRequest, {
		Url = ORACLE_API,
		Method = "POST",
		Headers = { ["Content-Type"] = "application/json" },
		Body = body,
	})
	if not ok then
		return nil, "request failed: " .. tostring(res)
	end
	if type(res) ~= "table" then
		return nil, "unexpected answer shape"
	end
	if res.Success and res.StatusCode == 200 and type(res.Body) == "string" and res.Body ~= "" then
		if res.Body:sub(1, 1) == "{" then
			return nil, "the answer was parked in pieces - use the website or pull oracle_result parts for files this big"
		end
		return res.Body, nil
	end
	return nil, string.format("server said HTTP %s: %s",
		tostring(res.StatusCode), tostring(res.Body):sub(1, 200))
end

return Oracle
