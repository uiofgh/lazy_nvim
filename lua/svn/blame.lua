-- lua/svn/blame.lua
local svn = require("svn.svn")
local ns = vim.api.nvim_create_namespace("svn-blame")

local M = {}

function M.show_line(bufnr, cfg)
  local file = vim.api.nvim_buf_get_name(bufnr)
  local line = vim.api.nvim_win_get_cursor(0)[1]
  svn.blame({file = file, cwd = vim.fn.getcwd()}, function(res)
    if res.code ~= 0 then return end
    local blame_line = res.stdout:match("^(.*)\n") or ""
    vim.api.nvim_buf_set_extmark(bufnr, ns, line - 1, 0, {
      virt_text = {{ blame_line, "SvnBlameVirtText" }},
      virt_text_pos = cfg.blame.virt_text_pos,
    })
  end)
end

return M
