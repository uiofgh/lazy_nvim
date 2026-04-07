-- lua/svn/lib/popup/init.lua
local Buffer = require("svn.lib.buffer")
local PopupUi = require("svn.lib.popup.ui")

local M = {}

function M.open(spec)
  local buf = Buffer.new({ name = "SVNPopup", render = function(b)
    local tree = PopupUi.render(spec)
    vim.api.nvim_buf_set_lines(b, 0, -1, false, { tree.children[1].value })
  end })
  buf:open({ win = { relative="cursor", width=40, height=10, row=1, col=1, border="rounded" } })
  buf:redraw()
  return buf
end

return M
