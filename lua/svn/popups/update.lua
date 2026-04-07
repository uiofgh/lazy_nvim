-- lua/svn/popups/update.lua
local popup = require("svn.lib.popup")
local builder = require("svn.lib.popup.builder")

return function()
  local spec = builder.builder()
    :name("Update")
    :action("u", "Update", function() end)
    :action("q", "Close", function() end)
    :build()
  popup.open(spec)
end
