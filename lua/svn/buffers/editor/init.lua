-- lua/svn/buffers/editor/init.lua
local M = {}

function M.open()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = "svncommit"
  vim.bo[buf].modifiable = true
  vim.keymap.set("n", "<C-c><C-c>", function() print("submit") end, { buffer = buf })
  vim.keymap.set("n", "<C-c><C-k>", function() vim.api.nvim_buf_delete(buf, {force=true}) end, { buffer = buf })
  vim.api.nvim_open_win(buf, true, { relative="editor", width=80, height=20, row=2, col=4, border="rounded" })
end

return M
