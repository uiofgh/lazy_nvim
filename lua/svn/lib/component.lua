-- lua/svn/lib/component.lua
local Component = {}
Component.__index = Component

function Component.new(opts)
  return setmetatable({
    id = opts.id,
    folded = opts.folded or false,
    on_open = opts.on_open,
    render = opts.render,
  }, Component)
end

function Component:toggle()
  self.folded = not self.folded
  if not self.folded and self.on_open then self.on_open() end
end

return Component
