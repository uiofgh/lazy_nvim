-- lua/svn/buffers/status/ui.lua
local Ui = require("svn.lib.ui")

local M = {}

function M.render(state)
  return Ui.col({
    Ui.text("Head: " .. state.head),
    Ui.text("URL:  " .. state.url),
    Ui.text(""),
    Ui.text("Unversioned files ("..#state.unversioned..")"),
    Ui.text("Modified files ("..#state.modified..")"),
    Ui.text("Conflicted files ("..#state.conflicted..")"),
    Ui.text("Recent commits ("..state.recent..")"),
  })
end

return M
