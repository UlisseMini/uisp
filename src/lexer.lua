local lexer = {}

function lexer.new(s)
	return setmetatable({
			s = s,
			pos = 1,
			line = 1,
		}, {
			__index = lexer,
			__call = lexer.__call
		})
end

-- return the current character
function lexer:cur()
	return self.s:sub(self.pos, self.pos)
end

-- return the next character
function lexer:next()
	local c = self:cur()
	self.pos = self.pos + 1
	if c == '\n' then self.line = self.line + 1 end
	return c
end

-- back up a character
function lexer:backup()
	if self:cur() == '\n' then self.line = self.line - 1 end
	self.pos = self.pos - 1
	if self.pos < 1 then error(("self.pos (%d) must be greater then zero"):format(self.pos)) end
end

function lexer:emit()
end

-- token types enum (numbers for sp33d)
lexer.tt = {
	op    = 0, -- (
	cp    = 1, -- )
	num   = 2, -- 1, 2, 3.6
	str   = 3, -- "foo", "bar\nbaz"
	ident = 4, -- a, b, abc
	sym   = 5, -- 'a, 'b, 'abc
}

-- helper functions
local is = {}

-- is c eof?
function is.eof(c)
	return c == ''
end

-- is c whitespace? (only for single chars!)
function is.ws(c)
	return c == ' ' or c == '\n'
end

-- is c a digit?
function is.digit(c)
	return c:match('%d')
end

-- is c an ident ending character?
-- (EOF, whitespace, close paren, etc)
function is.ident_ending(c)
	return is.ws(c) or is.eof(c) or ({
		['('] = true,
		[')'] = true,
	})[c]
end

-- lex an ident, buf contains the first character
-- of the ident, for example 'a' in the ident 'apple'.
function lexer:lex_ident(buf)
	while true do
		local c = self:next()
		if is.ident_ending(c) then
			-- don't /consume/ the ending character
			self:backup()
			break
		end

		buf = buf .. c
	end

	return {
		pos = self.pos,
		typ = lexer.tt.ident,
		v = buf,
	}
end

-- scan until we find a token, then return it.
-- this is usually called in a loop in client code like this
-- for token in lexer do ... end
function lexer:__call()
	-- simple cases
	local cases = {
		['('] = lexer.tt.op,
		[')'] = lexer.tt.cp,
	}

	-- for multichar tokens
	local buf = ''

	while true do
		local c = self:next()
		if is.eof(c) then break end -- EOF

		local t = cases[c]
		if t ~= nil then
			return {pos = self.pos, typ = t}
		end

		if is.digit(c) then
			-- digit, TODO

		elseif not is.ws(c) then
			-- ident
			return self:lex_ident(c)
		end
	end
end


----------------------------
--         Tests          --
----------------------------

local l = lexer.new("(a (b) c)")
for token in l do
	if token.typ == lexer.tt.ident then
		print(token.v)
	else
		print(token.typ)
	end
end

return lexer
