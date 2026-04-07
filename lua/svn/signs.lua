-- lua/svn/signs.lua
local M = {}
local ns = vim.api.nvim_create_namespace("svn-signs")

function M.clear(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

function M.place(bufnr, hunks, cfg)
  M.clear(bufnr)
  for _, h in ipairs(hunks) do
    vim.api.nvim_buf_set_extmark(bufnr, ns, h.start - 1, 0, {
      sign_text = cfg.signs.change.text,
      sign_hl_group = cfg.signs.change.hl,
    })
  end
end

return M
