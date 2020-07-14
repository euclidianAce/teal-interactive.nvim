
local tl = require("tl")

local cmd = vim.api.nvim_command

local function setLines(buf: number, lines: {string})
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

local function compileBuffer(tealBuf: number, luaBuf: number)
	local lines = vim.api.nvim_buf_get_lines(tealBuf, 0, -1, false)
	-- count leading newlines because they get dropped for some reason
	local i = 0
	while lines[i] == "\n" do
		i = i + 1
	end
	local leadingNewlines = i
	print("Compiling...")
	local result = tl.process_string(table.concat(lines, "\n") .. "\n")
	local output = tl.pretty_print_ast(result.ast) .. "\n"
	local compiledLines: {string} = {}
	for line in output:gmatch("[^\n]-\n") do
		table.insert(compiledLines, (line:gsub("\n", "")))
	end
	-- This is a hack since table.concat with \n apparently has some weird behavior
	-- table.concat({'a','','b'}, ',') = 'a,,b'
	-- table.concat({'a','','b'}, '\n') = 'a\nb' -- the space gets dropped
	for i = 1, leadingNewlines do
		table.insert(compiledLines, 1, "")
	end
	setLines(luaBuf, compiledLines)
	print("Done!")
end

local function syncCursor(src: number, dest: number)
	local cursor = vim.api.nvim_win_get_cursor(src)
	pcall(vim.api.nvim_win_set_cursor, dest, cursor)
end

local function initialize()
	local tealBuf = vim.api.nvim_get_current_buf()
	local tealWin = vim.api.nvim_get_current_win()
	local luaBuf = vim.api.nvim_create_buf(true, true)
	compileBuffer(tealBuf, luaBuf)
	cmd("vs")
	local luaWin = vim.api.nvim_get_current_win()

	cmd("buffer " .. luaBuf)
	cmd("set ft=lua")
	cmd("augroup teal-interactive")
	cmd("     au!")
	cmd(("    autocmd BufUnload,BufWipeout,BufDelete,WinClosed <buffer=%d> autocmd! teal-interactive"):format(tealBuf))
	cmd(("    autocmd BufUnload,BufWipeout,BufDelete,WinClosed <buffer=%d> autocmd! teal-interactive"):format(luaBuf))
	cmd(("    autocmd CursorMoved <buffer=%d> lua require'teal-interactive'.syncCursor(%d, %d)"):format(tealBuf, tealWin, luaWin))
	cmd(("    autocmd CursorMoved <buffer=%d> lua require'teal-interactive'.syncCursor(%d, %d)"):format(luaBuf, luaWin, tealWin))
	cmd(("    autocmd BufWritePost <buffer=%d> lua require'teal-interactive'.compileBuffer(%d, %d)"):format(tealBuf, tealBuf, luaBuf))
	cmd("augroup END")
end

return {
	initialize = initialize,
	compileBuffer = compileBuffer,
	syncCursor = syncCursor,
}
