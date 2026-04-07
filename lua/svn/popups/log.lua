-- lua/svn/popups/log.lua
local popup = require("svn.lib.popup")
local builder = require("svn.lib.popup.builder")

return function()
  local spec = builder.builder()
    :name("Log")
    :action("o", "Open Log Viewer", function() end)
    :action("q", "Close", function() end)
    :build()
  popup.open(spec)
end
