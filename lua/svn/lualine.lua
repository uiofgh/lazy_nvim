-- lua/svn/lualine.lua
local M = {}

function M.component()
  return function()
    return "SVN" .. "@" .. (vim.b.svn_rev or "-")
  end
end

return M
