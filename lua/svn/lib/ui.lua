-- lua/svn/lib/ui.lua
local Ui = {}

function Ui.text(str, opts)
  return { type = "text", value = str, hl = opts and opts.hl }
end

function Ui.row(children)
  return { type = "row", children = children }
end

function Ui.col(children)
  return { type = "col", children = children }
end

return Ui
