--[[
	ORACLE - copy any game from inside your executor
	=================================================
	Paste ONE line into Solara's Autoexec folder (or any executor with
	`request`, `getscriptbytecode` and `writefile`):

	    loadstring(game:HttpGet("https://raw.githubusercontent.com/nexusstudioserver-rgb/Oracle-Decompiler/main/script"))()

	(the file lives at the TOP LEVEL of github.com/nexusstudioserver-rgb/
	Oracle-Decompiler named `script`; the raw URL above is the loader.
	Any static host works the same way.)

	This script is fully standalone: it sends bytecode straight to the public
	LunaUX engine (no API key, no Oracle server) and restyles the answer into
	the Oracle house style RIGHT HERE in the executor - stamp on top, engine
	banners gone, recovered names printed as real names behind hard gates.

	DECOMPILE GAME  - writes every Script/LocalScript/ModuleScript to
	                  workspace/Oracle/<GameName>/<FullPath>.lua
	SAVE .RBXL      - drops the whole game file for the website flow
	DISCORD         - copies the invite
]]

local STAMP = "-- Saved by UniversalSynSaveInstance (Join to Copy Games) https://discord.gg/wx4ThpAsmw"
local ENGINE = "https://lunaux-decompiler.dev/api/decompile"
local DISCORD = "https://discord.gg/wx4ThpAsmw"

-- ============================================================ environment ===
local function pick(...)
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if v ~= nil then
			return v
		end
	end
	return nil
end

local httpRequest = pick(request, http_request,
	(type(http) == "table" and http.request) or nil,
	(type(syn) == "table" and syn.request) or nil,
	(type(fluxus) == "table" and fluxus.request) or nil,
	(type(krnl) == "table" and krnl.request) or nil)
local getBytecode = pick(getscriptbytecode,
	(type(syn) == "table" and syn.getscriptbytecode) or nil)
local writeFile = pick(writefile,
	(type(syn) == "table" and syn.writefile) or nil)
local makeFolder = pick(makefolder, make_directory,
	(type(syn) == "table" and syn.makefolder) or nil)
local isFolder = pick(isfolder,
	(type(syn) == "table" and syn.isfolder) or nil)
local getClone = pick(getrawmetatable and nil or nil,
	(type(game) == "table" and game.GetObjects) or nil)
local setClipboard = pick(setclipboard, toclipboard,
	(type(syn) == "table" and syn.setclipboard) or nil)
local getHui = pick(gethui,
	(type(syn) == "table" and syn.gethui) or nil)
local saveInstance = pick(saveinstance,
	(type(syn) == "table" and syn.saveinstance) or nil)

local tspawn, twait
do
	local okT = pcall(function()
		tspawn = task.spawn
		twait = task.wait
	end)
	if not okT or tspawn == nil then
		tspawn = spawn or coroutine.wrap
	end
	if not okT or twait == nil then
		twait = wait or function(t)
			local goal = os.clock() + (t or 0.1)
			while os.clock() < goal do end
		end
	end
end

-- ============================================================== base64 =====
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function pureBase64(s)
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

local b64encode = pick(
	(type(crypt) == "table" and (crypt.base64encode or crypt.base64_encode)) or nil,
	(type(base64) == "table" and base64.encode) or nil,
	pureBase64)

local function jsonEscape(s)
	return (tostring(s):gsub('[\\"]', "\\%0"):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("\t", "\\t"))
end

-- ================================================== house style (Luau) =====
-- A faithful port of the Oracle server styler: same rules, same hard gates.
local KEYWORDS = {
	and_ = 1, break_ = 1, continue_ = 1, do_ = 1, else_ = 1, elseif_ = 1, end_ = 1,
	false_ = 1, for_ = 1, function_ = 1, if_ = 1, in_ = 1, local_ = 1, nil_ = 1,
	not_ = 1, or_ = 1, repeat_ = 1, return_ = 1, then_ = 1, true_ = 1, until_ = 1, while_ = 1,
}
for k in pairs(KEYWORDS) do
	local w = k:gsub("_$", "")
	KEYWORDS[k] = nil
	KEYWORDS[w] = true
end

local function splitLines(text)
	local out = {}
	local cur = {}
	for ch in (text .. "\n"):gmatch("([^\n]*)\n") do
		out[#out + 1] = ch
	end
	return out
end

local function rstrip(s)
	return s:gsub("[ \t\r]+$", "")
end

local function lstripSpace(s)
	return s:gsub("^[ \t]+", "")
end

local function isIdentChar(c)
	return c:match("[%w_]") ~= nil
end

local function parseType(s, i)
	local last = nil
	while true do
		local c = s:sub(i, i)
		if c == "" or c:match("[%a_]") == nil then
			return last
		end
		local j = i
		while j <= #s and s:sub(j, j):match("[%w_.]") do
			j = j + 1
		end
		i = j
		local k = i
		while k <= #s and (s:sub(k, k) == " " or s:sub(k, k) == "\t") do
			k = k + 1
		end
		if s:sub(k, k) == "<" then
			local g = s:find(">", k, true)
			if not g then
				return last
			end
			if s:sub(k + 1, g - 1):find("[<>\n]") then
				return last
			end
			i = g + 1
		end
		if s:sub(i, i) == "?" then
			i = i + 1
		end
		last = i - 1
		local k2 = i
		while k2 <= #s and (s:sub(k2, k2) == " " or s:sub(k2, k2) == "\t") do
			k2 = k2 + 1
		end
		if s:sub(k2, k2) == "|" then
			local k3 = k2 + 1
			while k3 <= #s and (s:sub(k3, k3) == " " or s:sub(k3, k3) == "\t") do
				k3 = k3 + 1
			end
			i = k3
		else
			return last
		end
	end
end

local function skipWs(s, i)
	while i <= #s and (s:sub(i, i) == " " or s:sub(i, i) == "\t") do
		i = i + 1
	end
	return i
end

local function bareCall(rhs)
	if rhs:sub(-1) ~= ")" then
		return nil
	end
	local openAt = rhs:find("(", 1, true)
	if not openAt then
		return nil
	end
	local head = rhs:sub(1, openAt - 1)
	if head:match("^[%a_][%w.:]*$") == nil then
		return nil
	end
	local depth, inStr, esc = 0, nil, false
	for i = openAt, #rhs do
		local ch = rhs:sub(i, i)
		if inStr then
			if esc then
				esc = false
			elseif ch == "\\" then
				esc = true
			elseif ch == inStr then
				inStr = nil
			end
		elseif ch == '"' or ch == "'" then
			inStr = ch
		elseif ch == "(" then
			depth = depth + 1
		elseif ch == ")" then
			depth = depth - 1
			if depth == 0 and i < #rhs then
				return nil
			end
			if depth < 0 then
				return nil
			end
		end
	end
	if depth ~= 0 or inStr then
		return nil
	end
	return rhs
end

local function countChar(s, ch)
	local n = 0
	for i = 1, #s do
		if s:sub(i, i) == ch then
			n = n + 1
		end
	end
	return n
end

local function styleLine(line)
	-- R1: return-type annotation off (keep parameter annotations)
	local p = 1
	while true do
		p = line:find(")", p, true)
		if not p then
			break
		end
		local q = skipWs(line, p + 1)
		if line:sub(q, q) == ":" then
			q = skipWs(line, q + 1)
			local e = parseType(line, q)
			if e then
				local t = skipWs(line, e + 1)
				if t > #line or line:sub(t, t + 1) == "--" then
					local prefix = line:sub(1, p - 1)
					if countChar(prefix, '"') % 2 == 0 and countChar(prefix, "'") % 2 == 0 then
						line = line:sub(1, p - 1) .. ")" .. line:sub(e + 1)
						break
					end
				end
			end
		end
		p = p + 1
	end
	-- R2: trailing --[[ Line: N | Named "x" ]]  ->  -- line: N | named "x"
	local bp = line:find("--[[", 1, true)
	if bp then
		local i = skipWs(line, bp + 4)
		if line:sub(i, i + 4) == "Line:" then
			i = skipWs(line, i + 5)
			local ds = i
			while i <= #line and line:sub(i, i):match("%d") do
				i = i + 1
			end
			local digits = line:sub(ds, i - 1)
			if digits ~= "" then
				local named = nil
				local ok = true
				local j = skipWs(line, i)
				if line:sub(j, j) == "|" then
					j = skipWs(line, j + 1)
					if line:sub(j, j + 4) == "Named" then
						j = skipWs(line, j + 5)
						if line:sub(j, j) == '"' then
							local ce = line:find('"', j + 1, true)
							if ce then
								named = line:sub(j + 1, ce - 1)
								j = skipWs(line, ce + 1)
							else
								ok = false
							end
						else
							ok = false
						end
					else
						ok = false
					end
				end
				if ok and line:sub(j, j + 1) == "]]" then
					j = skipWs(line, j + 2)
					if j > #line then
						local head = rstrip(line:sub(1, bp - 1))
						local tail = "-- line: " .. digits
						if named then
							tail = tail .. ' | named "' .. named .. '"'
						end
						if head ~= "" then
							line = head .. " " .. tail
						else
							line = tail
						end
					end
				end
			end
		end
	end
	-- R3: local _ = CALL  ->  bare CALL
	do
		local i = 1
		local indent = ""
		local ws = skipWs(line, 1)
		indent = line:sub(1, ws - 1)
		i = ws
		if line:sub(i, i + 4) == "local" then
			i = skipWs(line, i + 5)
			local okDisc = false
			if line:sub(i, i) == "_" then
				i = i + 1
				okDisc = true
				while true do
					local j = skipWs(line, i)
					if line:sub(j, j) == "," then
						j = skipWs(line, j + 1)
						if line:sub(j, j) == "_" then
							i = j + 1
						else
							okDisc = false
							break
						end
					else
						i = j
						break
					end
				end
			end
			if okDisc and line:sub(i, i) == "=" and line:sub(i, i + 1) ~= "==" then
				local rhs = rstrip(line:sub(skipWs(line, i + 1)))
				local bare = bareCall(rhs)
				if bare then
					line = indent .. bare
				end
			end
		end
	end
	-- R4: local x: TYPE =  ->  local x =
	do
		local ws = skipWs(line, 1)
		local i = ws
		if line:sub(i, i + 4) == "local" then
			local j = skipWs(line, i + 5)
			if line:sub(j, j):match("[%a_]") then
				while j <= #line and isIdentChar(line:sub(j, j)) do
					j = j + 1
				end
				local prefixEnd = j - 1
				local k = skipWs(line, j)
				if line:sub(k, k) == ":" then
					k = skipWs(line, k + 1)
					local e = parseType(line, k)
					if e then
						local t = skipWs(line, e + 1)
						if line:sub(t, t) == "=" and line:sub(t, t + 1) ~= "==" then
							line = line:sub(1, prefixEnd) .. " =" .. line:sub(t + 1)
						end
					end
				end
			end
		end
	end
	return line
end

-- ---- char mask: 'c' code, 's' string, 'm' comment -------------------------
local function charMask(text)
	local n = #text
	local mask = {}
	for i = 1, n do
		mask[i] = "c"
	end
	local i, longOpen = 1, nil
	while i <= n do
		local ch = text:sub(i, i)
		if longOpen then
			mask[i] = longOpen.kind
			if ch == "]" then
				local eq = text:match("^%](=*)%]", i)
				if eq and #eq == longOpen.lvl then
					for k = i, i + #eq + 1 do
						mask[k] = longOpen.kind
					end
					i = i + #eq + 2
					longOpen = nil
				else
					i = i + 1
				end
			else
				i = i + 1
			end
		elseif ch == "\n" then
			i = i + 1
		elseif text:sub(i, i + 1) == "--" then
			local eq = text:match("^%-%-%[(=*)%[", i)
			if eq then
				for k = i, i + 3 + #eq do
					mask[k] = "m"
				end
				i = i + 4 + #eq
				longOpen = { lvl = #eq, kind = "m" }
			else
				local j = text:find("\n", i, true) or (n + 1)
				for k = i, j - 1 do
					mask[k] = "m"
				end
				i = j
			end
		elseif ch == '"' or ch == "'" then
			mask[i] = "s"
			i = i + 1
			while i <= n do
				local c2 = text:sub(i, i)
				mask[i] = "s"
				i = i + 1
				if c2 == "\\" and i <= n then
					mask[i] = "s"
					i = i + 1
				elseif c2 == ch or c2 == "\n" then
					break
				end
			end
		elseif ch == "[" then
			local eq = text:match("^%[(=*)%[", i)
			if eq then
				for k = i, i + 1 + #eq do
					mask[k] = "s"
				end
				i = i + 2 + #eq
				longOpen = { lvl = #eq, kind = "s" }
			else
				i = i + 1
			end
		else
			i = i + 1
		end
	end
	return mask
end

local function wordTokens(text, mask, allowComment)
	local out = {}
	local i, n = 1, #text
	while i <= n do
		local c = text:sub(i, i)
		if c:match("[%a_]") then
			local j = i
			while j <= n and isIdentChar(text:sub(j, j)) do
				j = j + 1
			end
			local okk = true
			for k = i, j - 1 do
				local mk = mask[k]
				if mk == "s" or (mk == "m" and not allowComment) then
					okk = false
					break
				end
			end
			if okk then
				out[#out + 1] = { s = i, e = j - 1, w = text:sub(i, j - 1) }
			end
			i = j
		else
			i = i + 1
		end
	end
	return out
end

local function prevWord(text, p)
	local q = p - 1
	while q >= 1 and (text:sub(q, q) == " " or text:sub(q, q) == "\t") do
		q = q - 1
	end
	local e = q
	while q >= 1 and isIdentChar(text:sub(q, q)) do
		q = q - 1
	end
	return text:sub(q + 1, e)
end

local function nextNonSpace(text, p)
	local q = p
	while q <= #text and (text:sub(q, q) == " " or text:sub(q, q) == "\t") do
		q = q + 1
	end
	return text:sub(q, q + 1)
end

local function underscoreRefsOk(text, mask, declSet)
	for _, tok in ipairs(wordTokens(text, mask, false)) do
		if tok.w == "_" and not declSet[tok.s] then
			local nxt = nextNonSpace(text, tok.e + 1)
			local prevCh = tok.s > 1 and text:sub(tok.s - 1, tok.s - 1) or ""
			local pw = prevWord(text, tok.s)
			if pw == "local" and nxt:sub(1, 1) == "=" and nxt:sub(1, 2) ~= "==" then
				-- binding, fine
			elseif pw == "for" and (nxt:sub(1, 1) == "=" or nxt:sub(1, 1) == "," or nxt:sub(1, 2) == "in") then
				-- loop var, fine
			elseif nxt:sub(1, 2) == "in" then
				-- pairs var, fine
			elseif prevCh == "(" or prevCh == "," then
				local depth, q, openAt = 0, tok.s - 1, -1
				while q >= 1 do
					if mask[q] == "c" then
						local ch = text:sub(q, q)
						if ch == ")" then
							depth = depth + 1
						elseif ch == "(" then
							if depth == 0 then
								openAt = q
								break
							end
							depth = depth - 1
						end
					end
					q = q - 1
				end
				if openAt < 0 then
					return false
				end
				local w1 = prevWord(text, openAt)
				local w0 = ""
				if w1 ~= "" then
					w0 = prevWord(text, openAt - #w1)
				end
				if w1 ~= "function" and w0 ~= "function" then
					return false
				end
			else
				return false
			end
		end
	end
	return true
end

local function isSlotId(id)
	if id == "_" then
		return true
	end
	local letters, digits = id:match("^([a-z]+)([0-9]+)$")
	return letters ~= nil and #letters <= 3 and #digits <= 4
end

local function findWholeWord(hay, word)
	local init = 1
	while true do
		local f = hay:find(word, init, true)
		if not f then
			return nil
		end
		local before = f > 1 and hay:sub(f - 1, f - 1) or ""
		local after = hay:sub(f + #word, f + #word)
		if (before == "" or not isIdentChar(before)) and (after == "" or not isIdentChar(after)) then
			return f
		end
		init = f + 1
	end
end

local function stripNamedTails(text)
	local lines = splitLines(text)
	for i, ln in ipairs(lines) do
		lines[i] = ln:gsub('( %-%- line: %d+) | named "[^"]-"$', "%1")
	end
	return table.concat(lines, "\n")
end

local function stripNamedBlocks(text)
	return (text:gsub("%s*| Named \"[^\"]-\"( %]%])", "%1"))
end

local function materializeNamed(text)
	local ok, result = pcall(function()
		local lines = splitLines(text)
		local offs = {}
		local o = 0
		for _, ln in ipairs(lines) do
			offs[#offs + 1] = o
			o = o + #ln + 1
		end
		local mask = charMask(text)

		local cands = {}
		for idx, ln in ipairs(lines) do
			local formA = ln:match("^([ \t]*local function )")
			local formB = formA == nil and ln:match("^([ \t]*local )") or nil
			local id, openP
			if formA then
				local rest = #formA + 1
				local js = rest
				while js <= #ln and isIdentChar(ln:sub(js, js)) do
					js = js + 1
				end
				id = ln:sub(rest, js - 1)
				openP = js
				if ln:sub(openP, openP) ~= "(" then
					id = nil
				end
			elseif formB then
				local rest = #formB + 1
				local js = rest
				while js <= #ln and isIdentChar(ln:sub(js, js)) do
					js = js + 1
				end
				id = ln:sub(rest, js - 1)
				local k = skipWs(ln, js)
				if ln:sub(k, k) == "=" and ln:sub(k, k + 1) ~= "==" then
					k = skipWs(ln, k + 1)
					if ln:sub(k, k + 7) == "function" then
						openP = skipWs(ln, k + 8)
						if ln:sub(openP, openP) ~= "(" then
							id = nil
						end
					else
						id = nil
					end
				else
					id = nil
				end
			end
			if id and isSlotId(id) then
				local ts = ln:find(") -- line: ", 1, true)
				if ts and ln:sub(ts):match('^%) %-%- line: %d+ | named "[^"]+"$') then
					local digits, name = ln:sub(ts):match('^%) %-%- line: (%d+) | named "([^"]+)"$')
					local idPos = ln:find(id, #(formA or formB) + 1, true)
					cands[#cands + 1] = {
						idx = idx, id = id, X = name,
						declAt = offs[idx] + (idPos or 1) - 1,
						formA = formA ~= nil,
						digits = digits,
					}
				end
			end
		end

		local scratch = stripNamedBlocks(stripNamedTails(text))

		local approved, used, declEdits = {}, {}, {}
		local slotCands, underCands = {}, {}
		for _, c in ipairs(cands) do
			if c.id == "_" then
				underCands[#underCands + 1] = c
			else
				slotCands[#slotCands + 1] = c
			end
		end

		for _, c in ipairs(slotCands) do
			local X = c.X
			if X:match("^[%a_][%w_]*$") and not KEYWORDS[X] and X ~= "_" and not used[X]
				and not findWholeWord(scratch, X)
				and not text:find("[,{][ \t]*" .. c.id .. "[ \t]*=")
				and not text:find("%[['\"]" .. c.id .. "['\"]%]") then
				if approved[c.id] == nil then
					approved[c.id] = X
					used[X] = true
				end
			end
		end

		local declSet = {}
		for _, c in ipairs(underCands) do
			declSet[c.declAt + 1] = true
		end
		if #underCands > 0 and underscoreRefsOk(text, mask, declSet) then
			for _, c in ipairs(underCands) do
				local X = c.X
				if X:match("^[%a_][%w_]*$") and not KEYWORDS[X] and X ~= "_" and not used[X]
					and not findWholeWord(scratch, X) then
					used[X] = true
					declEdits[#declEdits + 1] = c
				end
			end
		end

		if next(approved) == nil and #declEdits == 0 then
			return stripNamedBlocks(stripNamedTails(text))
		end

		-- slot renames: redirect every code+comment occurrence
		local edits, counts = {}, {}
		for k in pairs(approved) do
			counts[k] = 0
		end
		for _, tok in ipairs(wordTokens(text, mask, true)) do
			local new = approved[tok.w]
			if new then
				local before = tok.s > 1 and text:sub(tok.s - 1, tok.s - 1) or ""
				if mask[tok.s] == "c" and (before == "." or before == ":") then
					-- field access: never renamed
				else
					edits[#edits + 1] = { s = tok.s, e = tok.e, new = new }
					counts[tok.w] = counts[tok.w] + 1
				end
			end
		end
		for k, v in pairs(counts) do
			if v == 0 then
				return text
			end
		end
		table.sort(edits, function(a, b) return a.s > b.s end)
		local out = text
		for _, ed in ipairs(edits) do
			out = out:sub(1, ed.s - 1) .. ed.new .. out:sub(ed.e + 1)
		end

		if #declEdits > 0 then
			local outLines = splitLines(out)
			for _, c in ipairs(declEdits) do
				local ln = outLines[c.idx]
				if ln:find("local function _(", 1, true) then
					outLines[c.idx] = ln:gsub("local function _%(", "local function " .. c.X .. "(", 1)
				elseif ln:find("local _ = function(", 1, true) then
					outLines[c.idx] = ln:gsub("local _ = function%(", "local " .. c.X .. " = function(", 1)
				end
			end
			out = table.concat(outLines, "\n")
		end

		return stripNamedBlocks(stripNamedTails(out))
	end)
	if ok then
		return result
	end
	return text
end

local function stripEngineBanner(text)
	local lines = splitLines(text)
	local i, cut = 1, false
	while i <= #lines do
		local ln = rstrip(lines[i]:gsub("^\239\187\191", ""))
		if ln:sub(1, 23) == "-- [[ lunaux-decompiler" or ln:sub(1, 18) == "-- [[ Luau version" then
			i = i + 1
			cut = true
		elseif cut and ln == "" then
			i = i + 1
		else
			break
		end
	end
	if not cut then
		return text
	end
	local out = {}
	for k = i, #lines do
		out[#out + 1] = lines[k]
	end
	return table.concat(out, "\n")
end

local function houseStyle(text)
	if text == nil or text == "" then
		return text
	end
	local lines = splitLines(text)
	for i, ln in ipairs(lines) do
		lines[i] = styleLine(ln)
	end
	return materializeNamed(table.concat(lines, "\n"))
end

-- ================================================================ engine ===
local function engineDecompile(rawBytes, filename)
	if httpRequest == nil then
		return nil, "no `request` function in this executor"
	end
	local body = string.format('{"bytecode":"%s","filename":"%s","options":{"transformCompoundAssignments":false}}',
		b64encode(rawBytes), jsonEscape(filename or "chunk.luac"))
	local lastErr = "no answer"
	for attempt = 1, 2 do
		local ok, res = pcall(httpRequest, {
			Url = ENGINE,
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
				["User-Agent"] = "OracleLocalBridge/2.0 (local desktop tool)",
			},
			Body = body,
		})
		if not ok then
			lastErr = "engine request failed: " .. tostring(res)
		elseif type(res) ~= "table" then
			lastErr = "unexpected engine answer"
		elseif res.Success and res.StatusCode == 200 and type(res.Body) == "string" and res.Body ~= "" then
			return STAMP .. "\n\n" .. houseStyle(stripEngineBanner(res.Body)), nil
		else
			lastErr = string.format("engine said HTTP %s: %s",
				tostring(res.StatusCode), tostring(res.Body):sub(1, 160))
		end
		if attempt == 1 then
			twait(0.3)
		end
	end
	return nil, lastErr
end

-- ============================================================= gui+jobs ====
local function gameName()
	local ok, id = pcall(function() return game.PlaceId end)
	if ok and type(id) == "number" and id > 0 then
		return "Place" .. id
	end
	return "Game"
end

local function safeName(s)
	return tostring(s):gsub('[\\/:*?"<>|]', "_")
end

local function ensureFolder(path)
	if makeFolder == nil then
		return
	end
	local parts = {}
	for part in path:gmatch("[^/]+") do
		parts[#parts + 1] = part
	end
	local acc = ""
	for _, part in ipairs(parts) do
		acc = acc == "" and part or (acc .. "/" .. part)
		if isFolder == nil or not isFolder(acc) then
			pcall(makeFolder, acc)
		end
	end
end

local function collectScripts()
	local items = {}
	local function walk(node, path)
		for _, child in ipairs(node:GetChildren()) do
			local ok = pcall(function() return child.ClassName end)
			if ok then
				local childPath = path == "" and child.Name or (path .. "/" .. child.Name)
				if child:IsA("LuaSourceContainer") then
					local inCore = false
					local anc = child
					while anc ~= nil do
						if anc == game:GetService("CoreGui") then
							inCore = true
							break
						end
						anc = anc.Parent
					end
					if not inCore then
						items[#items + 1] = { instance = child, path = childPath }
					end
				else
					walk(child, childPath)
				end
			end
		end
	end
	walk(game, "")
	return items
end

local statusLabel, outputBox, gui

local function note(text)
	if outputBox then
		outputBox.Text = outputBox.Text .. text .. "\n"
	end
end

local function setStatus(text)
	if statusLabel then
		statusLabel.Text = text
	end
end

local function buildGui()
	if gui then
		return gui
	end
	local parent = (getHui and getHui()) or game:GetService("CoreGui")
	local screen = Instance.new("ScreenGui")
	screen.Name = "OraclePanel"
	screen.ResetOnSpawn = false
	pcall(function() screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
	screen.Parent = parent

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(0, 380, 0, 250)
	frame.Position = UDim2.new(0.5, -190, 0.5, -125)
	frame.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
	frame.BorderSizePixel = 0
	frame.Active = true
	frame.Draggable = true
	frame.Parent = screen

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -70, 0, 34)
	title.BackgroundTransparency = 1
	title.Text = "ORACLE  -  copy any game"
	title.TextColor3 = Color3.fromRGB(235, 238, 245)
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.Parent = frame

	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 26, 0, 26)
	close.Position = UDim2.new(1, -30, 0, 4)
	close.BackgroundColor3 = Color3.fromRGB(40, 40, 48)
	close.Text = "X"
	close.TextColor3 = Color3.fromRGB(200, 200, 210)
	close.Font = Enum.Font.GothamBold
	close.TextSize = 13
	close.Parent = frame
	close.MouseButton1Click:Connect(function()
		screen.Enabled = not screen.Enabled
	end)

	local function button(text, y, color)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, -24, 0, 34)
		b.Position = UDim2.new(0, 12, 0, y)
		b.BackgroundColor3 = color
		b.Text = text
		b.TextColor3 = Color3.fromRGB(250, 250, 252)
		b.Font = Enum.Font.GothamBold
		b.TextSize = 14
		b.Parent = frame
		return b
	end

	local decompileBtn = button("DECOMPILE GAME", 40, Color3.fromRGB(47, 127, 224))
	local saveBtn = button("SAVE .RBXL", 80, Color3.fromRGB(58, 62, 74))
	local discordBtn = button("DISCORD", 120, Color3.fromRGB(88, 101, 242))

	statusLabel = Instance.new("TextLabel")
	statusLabel.Size = UDim2.new(1, -24, 0, 20)
	statusLabel.Position = UDim2.new(0, 12, 0, 160)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "ready - " .. DISCORD
	statusLabel.TextColor3 = Color3.fromRGB(150, 156, 170)
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextSize = 12
	statusLabel.Parent = frame

	outputBox = Instance.new("TextBox")
	outputBox.Size = UDim2.new(1, -24, 1, -190)
	outputBox.Position = UDim2.new(0, 12, 0, 184)
	outputBox.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
	outputBox.TextColor3 = Color3.fromRGB(170, 176, 190)
	outputBox.Font = Enum.Font.Code
	outputBox.TextSize = 11
	outputBox.TextXAlignment = Enum.TextXAlignment.Left
	outputBox.TextYAlignment = Enum.TextYAlignment.Top
	outputBox.MultiLine = true
	outputBox.ClearTextOnFocus = false
	outputBox.Text = ""
	outputBox.Parent = frame

	decompileBtn.MouseButton1Click:Connect(function()
		tspawn(runDecompile)
	end)
	saveBtn.MouseButton1Click:Connect(function()
		tspawn(runSave)
	end)
	discordBtn.MouseButton1Click:Connect(function()
		if setClipboard then
			pcall(setClipboard, DISCORD)
			note("[discord] invite copied")
		else
			note("[discord] " .. DISCORD)
		end
	end)

	gui = screen
	return screen
end

function runDecompile()
	if getBytecode == nil then
		note("[error] this executor has no getscriptbytecode")
		return
	end
	if writeFile == nil then
		note("[error] this executor has no writefile")
		return
	end
	setStatus("scanning scripts...")
	local items = collectScripts()
	if #items == 0 then
		setStatus("nothing found to decompile")
		note("[scan] no LuaSourceContainer outside CoreGui")
		return
	end
	local root = "Oracle/" .. safeName(gameName())
	ensureFolder(root)
	local saved, failed = 0, 0
	for _, item in ipairs(items) do
		local ok, err = pcall(function()
			local rel = item.path:gsub("[^/]+", function(seg) return safeName(seg) end)
			local dir = rel:match("^(.*)/[^/]+$")
			if dir then
				ensureFolder(root .. "/" .. dir)
			end
			local bc = getBytecode(item.instance)
			if type(bc) ~= "string" or bc == "" then
				failed = failed + 1
				writeFile(root .. "/" .. rel .. ".lua",
					STAMP .. "\n\n-- Oracle: this script had no code in the file\n")
				note("[kept] " .. item.path .. " - no bytecode in the slot")
				return
			end
			local text, derr = engineDecompile(bc, item.path .. ".luac")
			if text == nil then
				failed = failed + 1
				writeFile(root .. "/" .. rel .. ".lua",
					STAMP .. "\n\n-- Oracle: the engine could not decompile this script (" .. tostring(derr) .. ")\n")
				note("[fail] " .. item.path .. " - " .. tostring(derr))
				return
			end
			saved = saved + 1
			writeFile(root .. "/" .. rel .. ".lua", text .. "\n")
			note("[ok] " .. item.path)
		end)
		if not ok then
			failed = failed + 1
			note("[fail] " .. item.path .. " - " .. tostring(err))
		end
	end
	setStatus(string.format("done: %d saved, %d noted - workspace/%s", saved, failed, root))
end

function runSave()
	if saveInstance == nil then
		note("[error] this executor has no saveinstance")
		return
	end
	setStatus("saving place file...")
	local ok, err = pcall(function()
		saveinstance({
			Workspace = workspace,
		})
	end)
	if not ok then
		local ok2, err2 = pcall(saveInstance)
		if not ok2 then
			note("[fail] saveinstance: " .. tostring(err) .. " / " .. tostring(err2))
			setStatus("save failed - see log")
			return
		end
	end
	note("[ok] place file saved by the executor")
	setStatus("place file saved")
end

-- self-test / library export (harnesses load this file and call these)
local LIB = {
	houseStyle = houseStyle,
	styleLine = styleLine,
	charMask = charMask,
	wordTokens = wordTokens,
	refsOk = underscoreRefsOk,
	stripEngineBanner = stripEngineBanner,
	engineDecompile = engineDecompile,
	pureBase64 = pureBase64,
	runDecompile = runDecompile,
	collectScripts = collectScripts,
	STAMP = STAMP,
	ENGINE = ENGINE,
}
if _G.ORACLE_LIB_ONLY then
	return LIB
end

buildGui()
note("[oracle] panel ready - DECOMPILE GAME writes workspace/" .. safeName(gameName()))
return LIB
