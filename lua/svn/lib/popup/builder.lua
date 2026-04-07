-- lua/svn/lib/popup/builder.lua
local Builder = {}
Builder.__index = Builder

function Builder.new()
  return setmetatable({ popup_name = "", switches = {}, actions = {}, headings = {} }, Builder)
end

function Builder:name(n) self.popup_name = n; return self end
function Builder:switch(key, flag, label) table.insert(self.switches, {key=key, flag=flag, label=label}); return self end
function Builder:group_heading(label) table.insert(self.headings, label); return self end
function Builder:action(key, label, fn) table.insert(self.actions, {key=key, label=label, fn=fn}); return self end
function Builder:build() return {name=self.popup_name, switches=self.switches, actions=self.actions, headings=self.headings} end

return { builder = function() return Builder.new() end }
