local tl = require("tl")

local cmd = vim.api.nvim_command

local function getLines(buf)
   return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end
local function setLines(buf, lines)
   vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

local function compileBuffer(tealBuf, luaBuf)
   local lines = getLines(tealBuf)

   local i = 0
   while lines[i] == "\n" do
      i = i + 1
   end
   local leadingNewlines = i

   local result = tl.process_string(table.concat(lines, "\n") .. "\n")
   if #result.syntax_errors > 0 then
      print("Syntax errors")
      return
   end
   local output = tl.pretty_print_ast(result.ast) .. "\n"
   local compiledLines = {}
   for line in output:gmatch("[^\n]-\n") do
      table.insert(compiledLines, (line:gsub("\n", "")))
   end



   for i = 1, leadingNewlines do
      table.insert(compiledLines, 1, "")
   end
   setLines(luaBuf, compiledLines)
end

local function syncCursor(src, dest)
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

   cmd(("    autocmd BufUnload,BufWipeout,BufDelete,WinClosed <buffer=%d> autocmd! teal-interactive"):format(tealBuf))
   cmd(("    autocmd BufUnload,BufWipeout,BufDelete,WinClosed <buffer=%d> autocmd! teal-interactive"):format(luaBuf))


   cmd(("    autocmd CursorMoved <buffer=%d> lua require'teal-interactive'.syncCursor(%d, %d)"):format(tealBuf, tealWin, luaWin))
   cmd(("    autocmd CursorMoved <buffer=%d> lua require'teal-interactive'.syncCursor(%d, %d)"):format(luaBuf, luaWin, tealWin))


   cmd(("    autocmd BufWritePost,InsertLeave <buffer=%d> lua require'teal-interactive'.compileBuffer(%d, %d)"):format(tealBuf, tealBuf, luaBuf))
   cmd("augroup END")
end

return {
   initialize = initialize,
   compileBuffer = compileBuffer,
   syncCursor = syncCursor,
}
