-- lua/svn/lib/buffer.lua
local Buffer = {}
Buffer.__index = Buffer

function Buffer.new(opts)
  local buf = vim.api.nvim_create_buf(false, true)
  return setmetatable({
    bufnr = buf,
    name = opts.name,
    keymaps = opts.keymaps or {},
    render = opts.render,
  }, Buffer)
end

function Buffer:open(opts)
  vim.api.nvim_buf_set_name(self.bufnr, self.name)
  vim.bo[self.bufnr].buftype = "nofile"
  vim.bo[self.bufnr].modifiable = false
  vim.bo[self.bufnr].filetype = opts.filetype or "svn"
  vim.api.nvim_open_win(self.bufnr, true, opts.win)
  for k, fn in pairs(self.keymaps) do
    vim.keymap.set("n", k, fn, { buffer = self.bufnr, nowait = true })
  end
end

function Buffer:redraw()
  vim.bo[self.bufnr].modifiable = true
  self.render(self.bufnr)
  vim.bo[self.bufnr].modifiable = false
end

return Buffer
