-- lua/svn/diff.lua
local M = {}

function M.parse_diff(diff_text)
  local hunks = {}
  for header in diff_text:gmatch("@@.-@@") do
    local start, count = header:match("%+(%d+),?(%d*)")
    table.insert(hunks, {start = tonumber(start), count = tonumber(count) or 1})
  end
  return hunks
end

return M
