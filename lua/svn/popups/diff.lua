-- lua/svn/popups/diff.lua
local popup = require("svn.lib.popup")
local builder = require("svn.lib.popup.builder")

return function()
  local spec = builder.builder()
    :name("Diff")
    :action("d", "Show Diff", function() end)
    :action("q", "Close", function() end)
    :build()
  popup.open(spec)
end
