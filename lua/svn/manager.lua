-- lua/svn/manager.lua
local svn = require("svn.svn")
local diff = require("svn.diff")
local signs = require("svn.signs")

local M = {}

function M.update(bufnr, cfg)
  local file = vim.api.nvim_buf_get_name(bufnr)
  if file == "" then return end
  svn.diff({file = file, cwd = vim.fn.getcwd()}, function(res)
    if res.code ~= 0 then return end
    local hunks = diff.parse_diff(res.stdout)
    signs.place(bufnr, hunks, cfg)
  end)
end

return M
