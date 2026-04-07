-- lua/svn/attach.lua
local blame = require("svn.blame")

local M = {}

function M.setup(cfg)
  vim.api.nvim_create_autocmd("CursorHold", {
    callback = function(args)
      if cfg.blame.enabled then blame.show_line(args.buf, cfg) end
    end,
  })
end

return M
