-- plugin/svn.lua
if vim.g.loaded_svn_nvim then return end
vim.g.loaded_svn_nvim = 1

vim.api.nvim_create_user_command("SvnSetup", function(opts)
  require("svn").setup()
end, {})
