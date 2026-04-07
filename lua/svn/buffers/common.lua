-- lua/svn/buffers/common.lua
local M = {}

function M.FileItem(opts)
  return { status = opts.status, filename = opts.filename, diff = opts.diff }
end

function M.CommitItem(opts)
  return { rev = opts.rev, author = opts.author, date = opts.date, message = opts.message }
end

return M
