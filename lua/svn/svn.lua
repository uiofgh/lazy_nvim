-- lua/svn/svn.lua
local async = require("svn.async")

local M = {}

local function run(args, opts, cb)
  return async.run({"svn", unpack(args)}, opts, cb)
end

function M.status(opts, cb)
  return run({"status"}, {cwd = opts.cwd}, cb)
end

function M.diff(opts, cb)
  return run({"diff", opts.file}, {cwd = opts.cwd}, cb)
end

function M.blame(opts, cb)
  return run({"blame", opts.file}, {cwd = opts.cwd}, cb)
end

function M.log(opts, cb)
  return run({"log", "-l", tostring(opts.limit or 50), opts.path or ""}, {cwd = opts.cwd}, cb)
end

function M.update(opts, cb)
  return run({"update"}, {cwd = opts.cwd}, cb)
end

function M.commit(opts, cb)
  local args = {"commit", "-m", opts.message}
  if opts.paths then
    for _, p in ipairs(opts.paths) do
      table.insert(args, p)
    end
  end
  return run(args, {cwd = opts.cwd}, cb)
end

function M.add(opts, cb)
  return run({"add", opts.file}, {cwd = opts.cwd}, cb)
end

function M.revert(opts, cb)
  return run({"revert", opts.file}, {cwd = opts.cwd}, cb)
end

function M.info(opts, cb)
  return run({"info", opts.file or ""}, {cwd = opts.cwd}, cb)
end

return M
