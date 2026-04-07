-- lua/svn/init.lua
local config = require("svn.config")
local highlight = require("svn.highlight")
local attach = require("svn.attach")

local M = {}

function M.setup(user_cfg)
  M.config = config.merge(user_cfg)
  highlight.setup()
  attach.setup(M.config)
end

return M
