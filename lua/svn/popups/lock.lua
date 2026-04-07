-- lua/svn/popups/lock.lua
local popup = require("svn.lib.popup")
local builder = require("svn.lib.popup.builder")

return function()
  local spec = builder.builder()
    :name("Lock")
    :action("l", "Lock", function() end)
    :action("u", "Unlock", function() end)
    :action("q", "Close", function() end)
    :build()
  popup.open(spec)
end
