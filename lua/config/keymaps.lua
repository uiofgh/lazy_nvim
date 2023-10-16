local function map(mode, lhs, rhs, opts)
	local keys = require("lazy.core.handler").handlers.keys
	---@cast keys LazyKeysHandler
	-- do not create the keymap if a lazy keys handler exists
	if not keys.active[keys.parse({ lhs, mode = mode }).id] then
		opts = opts or {}
		opts.silent = opts.silent ~= false
		vim.keymap.set(mode, lhs, rhs, opts)
	end
end

-- keymap
map("n", "<leader>w", ":w<CR>", { silent = true, desc = "Save" })
map("n", "<C-c>", '"+y', { desc = "Copy to clipboard" })
map("v", "<C-c>", '"+y', { desc = "Copy to clipboard" })
map("n", "<leader>v", '"+p', { desc = "Paste from clipboard" })
map("v", "<C-v>", '"_d"+p', { desc = "Paste from clipboard" })
map("i", "<C-v>", "<C-r>+", { desc = "Paste from clipboard" })
map("c", "<C-v>", "<C-r>+", { desc = "Paste from clipboard" })
map("v", "<tab>", ">")
map("v", "<S-tab>", "<")
map("v", "//", '"vy/<C-r>v<CR>', { desc = "Search selected text" })
map("v", "p", '_d"0P')
map("n", "<leader>p", '"0p', { desc = "Paste last yanked text" })
map("n", "Y", "y$")
map("n", "gb", "gT")
map("n", "x", '"_x')
map(
	"n",
	"<leader>cf",
	function() vim.fn.setreg("+", vim.fn.expand "%:t:r") end,
	{ desc = "Copy filename without extension" }
)
map("n", "gx", ":tabclose<CR>", { silent = true, desc = "Close tab" })
map("n", "<leader>cl", "<cmd>Lazy<cr>", { silent = true, desc = "Lazy" })
map("n", "*", [[m`:keepjumps normal! *``<CR>]], { noremap = true, silent = true }) -- word boundary search, no autojump

-- delete spell keymap
map("n", "zg", "<nop>")
map("n", "zG", "<nop>")
map("n", "zw", "<nop>")
map("n", "zW", "<nop>")
map("n", "zug", "<nop>")
map("n", "zuG", "<nop>")
map("n", "zuw", "<nop>")
map("n", "zuW", "<nop>")

--quickfix
map("n", "[q", function() vim.cmd "silent! cprevious" end, { silent = true })
map("n", "]q", function() vim.cmd "silent! cnext" end, { silent = true })
map("n", "[Q", function() vim.cmd "silent! cfirst" end, { silent = true })
map("n", "]Q", function() vim.cmd "silent! clast" end, { silent = true })
map("n", "gqq", function() vim.cmd "silent! copen" end, { silent = true })

-- encoding
vim.g.enc_index = 0
local encodings = { "gbk", "utf-8" }
map("n", "<F8>", function()
	local index = vim.g.enc_index
	vim.cmd(string.format("e ++enc=%s %s", encodings[index], vim.api.nvim_buf_get_name(0)))
	index = index + 1
	if index > #encodings then index = 1 end
	vim.g.enc_index = index
end, { silent = true })
