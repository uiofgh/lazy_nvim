-- lua/svn/highlight.lua
local M = {}

function M.setup()
  vim.api.nvim_set_hl(0, "SvnSignAdd", { link = "DiffAdd" })
  vim.api.nvim_set_hl(0, "SvnSignChange", { link = "DiffChange" })
  vim.api.nvim_set_hl(0, "SvnSignDelete", { link = "DiffDelete" })
  vim.api.nvim_set_hl(0, "SvnBlameVirtText", { link = "Comment" })
end

return M
