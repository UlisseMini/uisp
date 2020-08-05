-- package.path comes after because if it comes before
-- this file (lexer.lua) will match before ../src/lexer.lua
package.path = '../src/?.lua;./deps/?.lua;' .. package.path

local lexer = require('lexer')
local inspect = require('inspect')

----------------------------
--         Tests          --
----------------------------

local l = lexer.new("(a 3 c)")

local tests = {
	{'lex single ident', 'a', {
		{pos = 1, typ = lexer.tt.ident, v = 'a'}
	}},

	{'lex single digit', '5', {
		{pos = 1, typ = lexer.tt.num, v = 5}
	}},

	{'lex multi digit', '55', {
		{pos = 1, typ = lexer.tt.num, v = 55}
	}},

	{'lex negative', '-5', {
		{pos = 1, typ = lexer.tt.num, v = -5}
	}},

	{'lex oparen', '(', {
		{pos = 1, typ = lexer.tt.op, v = '('}
	}},

	{'lex cparen', ')', {
		{pos = 1, typ = lexer.tt.cp, v = ')'}
	}},

	{'lex string', '"foo"', {
		{pos = 1, typ = lexer.tt.str, v = 'foo'}
	}},

	{'lex true', '#t', {
		{pos = 1, typ = lexer.tt.bool, v = true}
	}},

	{'lex false', '#f', {
		{pos = 1, typ = lexer.tt.bool, v = false}
	}},

	{'lex string fail', '"foo', fail = true},
	{'lex number fail', '13c', fail = true},
	{'lex hex fail', '0x1', fail = true}, -- hex not supported, yet

	{'lex list', '(a b c)', {
		{pos = 1, typ = lexer.tt.op, v = '('},
		{pos = 2, typ = lexer.tt.ident, v = 'a'},
		{pos = 4, typ = lexer.tt.ident, v = 'b'},
		{pos = 6, typ = lexer.tt.ident, v = 'c'},
		{pos = 7, typ = lexer.tt.cp, v = ')'},
	}},

	{'lex number list', '(1 2 3)', {
		{pos = 1, typ = lexer.tt.op, v = '('},
		{pos = 2, typ = lexer.tt.num, v = 1},
		{pos = 4, typ = lexer.tt.num, v = 2},
		{pos = 6, typ = lexer.tt.num, v = 3},
		{pos = 7, typ = lexer.tt.cp, v = ')'},
	}},
}

for _, test in pairs(tests) do
	local name   = test[1]
	local input  = test[2]
	local want   = test[3]

	print(name .. ': ' .. input)

	if test.fail then
		local ok, err = pcall(function()
			local got = {}
			for token in lexer.new(input) do
				table.insert(got, token)
			end
		end)

		if ok then
			error(("%s should have failed, but did not"):format(name))
		end
	else
		local got = {}
		for token in lexer.new(input) do
			table.insert(got, token)
		end

		assert(inspect(got) == inspect(want),
			("--- WANT\n%s\n\n--- GOT\n%s\n"):format(inspect(want), inspect(got)))
	end
end

