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

-- return the next character without incrementing pos
function lexer:peek()
	return self.s:sub(self.pos, self.pos)
end

-- get the string for line n, excluding newline
-- (does not modify lexer state)
function lexer:get_line(n)
	local l = 1
	local buf = ''
	for c in self.s:gmatch('.*') do
		if l == n then
			buf = buf .. c
		end

		if c == '\n' then
			l = l + 1
			if l - 1 == n then break end
		end
	end

	return buf
end

-- a nice lexer error.
function lexer:errorf(s, ...)
	local buf = "line " .. tonumber(self.line) .. "," .. '\n'
	buf = buf .. self:get_line(self.line) .. '\n'
	buf = buf .. '^ '
	buf = buf .. s:format(...)

	error(buf)
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
	if self.pos < 1 then
		self:errorf("[lexer bug] self.pos (%d) must be greater then zero", self.pos)
	end
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
	bool  = 6, -- #t/#f
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
function is.lit_ending(c)
	return is.ws(c) or is.eof(c) or ({
		['('] = true,
		[')'] = true,
	})[c]
end

-- lex an ident, buf contains the first character
-- of the ident, for example 'a' in the ident 'apple'.
function lexer:lex_ident(buf)
	-- record the start of this token.
	-- this is our current pos - 1 (because we get passed 1 char in buf)
	local start = self.pos - 1

	while true do
		local c = self:next()
		if is.lit_ending(c) then
			-- don't /consume/ the ending character
			self:backup()
			break
		end

		buf = buf .. c
	end

	return {
		pos = start,
		typ = lexer.tt.ident,
		v = buf,
	}
end

-- buf contains the first character of the digit.
function lexer:lex_number(buf)
	-- record the start of this token.
	-- this is our current pos - 1 (because we get passed 1 char in buf)
	local start = self.pos - 1

	while true do
		local c = self:next()
		if is.eof(c) then break end

		if is.lit_ending(c) then
			-- don't /consume/ the ending character
			self:backup()
			break
		end

		if not is.digit(c) then
			-- TODO: Better errors
			error(("invalid digit with ending %q (%q)"):format(c, buf .. c))
		end

		buf = buf .. c
	end

	return {
		pos = start,
		typ = lexer.tt.num,
		-- This should never fail. If it does it is a bug in the lexer.
		v = assert(tonumber(buf)),
	}
end

function lexer:lex_string()
	local buf = ''
	local start = self.pos
	while true do
		local c = self:next()
		if is.eof(c) then
			self:errorf('no ending doublequote (")')
		end

		if c == '"' then
			break
		end

		buf = buf .. c
	end

	return {
		pos = start - 1,
		typ = lexer.tt.str,
		v = buf,
	}
end

function lexer:lex_bool()
	local c = self:next()
	local b
	if     c == 't' then b = true
	elseif c == 'f' then b = false
	else                 self:errorf('expected #t/#f, got #%s', c)
	end

	local p = self:peek()
	if is.ws(p) or is.eof(p) then
		return {
			pos = self.pos - 2, -- minus 2 because we consumed #f/#t (2 chars)
			typ = lexer.tt.bool,
			v = b,
		}
	else
		self:errorf("expected whitespace or eof, got %q", p)
	end
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
		if is.eof(c) then break end

		local t = cases[c]
		if t ~= nil then
			return {pos = self.pos - 1, typ = t, v = c}
		end

		if is.digit(c) or c == '-' then
			-- number
			return self:lex_number(c)
		elseif c == '#' then
			return self:lex_bool()
		elseif c == '"' then
			return self:lex_string()
		elseif not is.ws(c) then
			-- ident
			return self:lex_ident(c)
		end
	end
end

return lexer
