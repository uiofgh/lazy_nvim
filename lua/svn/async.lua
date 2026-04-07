-- lua/svn/async.lua
local M = {}

function M.run(cmd, opts, cb)
  return vim.system(cmd, { text = true, cwd = opts.cwd }, function(result)
    vim.schedule(function()
      cb(result)
    end)
  end)
end

return M
