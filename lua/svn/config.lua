-- lua/svn/config.lua
local M = {}

M.defaults = {
  signs = {
    add = { text = "│", hl = "SvnSignAdd" },
    change = { text = "│", hl = "SvnSignChange" },
    delete = { text = "_", hl = "SvnSignDelete" },
  },
  blame = { enabled = true, delay = 300, virt_text_pos = "eol" },
  status = { enabled = true },
  log = { limit = 50 },
  update_interval = 800,
  on_attach = nil,
}

function M.merge(user)
  return vim.tbl_deep_extend("force", {}, M.defaults, user or {})
end

return M
