-- lua/svn/buffers/log/init.lua
local Buffer = require("svn.lib.buffer")

local M = {}

function M.open(lines)
  local buf = Buffer.new({ name = "SVNLog", render = function(b)
    vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
  end })
  buf:open({ filetype = "svnlog", win = { relative="editor", width=90, height=25, row=2, col=4, border="rounded" } })
  buf:redraw()
end

return M
