-- lua/svn/lib/popup/ui.lua
local Ui = require("svn.lib.ui")

local M = {}

function M.render(spec)
  local lines = { Ui.text(spec.name) }
  for _, s in ipairs(spec.switches) do
    table.insert(lines, Ui.text(string.format("  -%s  %s", s.key, s.label)))
  end
  for _, a in ipairs(spec.actions) do
    table.insert(lines, Ui.text(string.format("  %s  %s", a.key, a.label)))
  end
  return Ui.col(lines)
end

return M
