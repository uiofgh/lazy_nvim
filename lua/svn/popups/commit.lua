-- lua/svn/popups/commit.lua
local popup = require("svn.lib.popup")
local builder = require("svn.lib.popup.builder")
local editor = require("svn.buffers.editor.init")

return function()
  local spec = builder.builder()
    :name("Commit")
    :switch("a", "--include-unversioned", "All")
    :switch("k", "--keep-locks", "Keep locks")
    :group_heading("Actions")
    :action("c", "Commit", function() editor.open() end)
    :action("q", "Cancel", function() end)
    :build()
  popup.open(spec)
end
