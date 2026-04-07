-- lua/svn/buffers/status/init.lua
local Buffer = require("svn.lib.buffer")
local StatusUi = require("svn.buffers.status.ui")

local M = {}

function M.open(state)
  local buf = Buffer.new({
    name = "SVNStatus",
    render = function(b)
      local tree = StatusUi.render(state)
      local lines = {}
      for _, node in ipairs(tree.children) do table.insert(lines, node.value or "") end
      vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
    end,
    keymaps = {
      q = function() vim.api.nvim_buf_delete(0, {force=true}) end,
      g = function() M.refresh() end,
    },
  })
  buf:open({ filetype = "svnstatus", win = { relative="editor", width=90, height=30, row=1, col=2, border="rounded" } })
  buf:redraw()
  return buf
end

return M
