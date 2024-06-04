local function augroup(name) return vim.api.nvim_create_augroup("config_" .. name, { clear = true }) end

-- remember folds
vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
	group = augroup "RememberFoldsLeave",
	pattern = "*.*",
	command = "mkview",
})
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
	group = augroup "RememberFoldsEnter",
	pattern = "*.*",
	command = "silent! loadview",
})

-- set program title
vim.api.nvim_create_autocmd({ "BufEnter" }, {
	group = augroup "SetTitleName",
	callback = function()
		local cwd = vim.loop.cwd()
		local title = vim.fn.fnamemodify(cwd, ":t")
		if not title or title == "" or title == vim.opt.titlestring then return end
		vim.opt.titlestring = title
	end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = augroup "resize_splits",
	callback = function() vim.cmd "tabdo wincmd =" end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
	group = augroup "close_with_q",
	pattern = {
		"PlenaryTestPopup",
		"help",
		"lspinfo",
		"man",
		"notify",
		"qf",
		"spectre_panel",
		"startuptime",
		"tsplayground",
		"checkhealth",
		"grug-far",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
	end,
})

-- help enhance
vim.api.nvim_create_autocmd("FileType", {
	group = augroup "help_key",
	pattern = {
		"help",
	},
	callback = function(event)
		vim.keymap.set("n", "<CR>", "<C-]>", { buffer = 0 })
		vim.keymap.set("n", "<BS>", "<C-T>", { buffer = 0 })
	end,
})

-- python
vim.api.nvim_create_autocmd("FileType", {
	group = augroup "python",
	pattern = {
		"python",
	},
	callback = function(event)
		vim.bo.shiftwidth = 4
		vim.bo.softtabstop = 4
		vim.bo.expandtab = false
	end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = augroup "auto_create_dir",
	callback = function(event)
		if event.match:match "^%w%w+://" then return end
		local file = vim.loop.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup "highlight_yank",
	callback = function() vim.highlight.on_yank() end,
})

local function buffer_cleaner()
	local timer = vim.loop.new_timer()
	if not timer then return end

	local bufOpt = vim.api.nvim_buf_get_option

	local retirementAgeMins = 10
	local ignoredFiletypes = { "NvimTree", "qf", "toggleterm", "Mundo", "MundoDiff", "dbui", "vista", "noice" }

	local function clean_buffer()
		local openBuffers = vim.fn.getbufinfo { buflisted = 1 }
		local cur_time = os.time()
		for _, buf in pairs(openBuffers) do
			local bufnr = buf.bufnr
			local usedSecsAgo = cur_time - buf.lastused
			local recentlyUsed = usedSecsAgo < retirementAgeMins * 60
			local bufFt = bufOpt(bufnr, "filetype")
			local isIgnoredFt = vim.tbl_contains(ignoredFiletypes, bufFt)
			local isIgnoredSpecialBuffer = bufOpt(buf.bufnr, "buftype") ~= ""
			local isIgnoredAltFile = buf.name == vim.fn.expand "#:p"
			local isModified = bufOpt(bufnr, "modified")
			local isSelected = not vim.tbl_isempty(vim.fn.win_findbuf(bufnr))
			if
				not (
					recentlyUsed
					or isIgnoredFt
					or isIgnoredSpecialBuffer
					or isIgnoredAltFile
					or isModified
					or isSelected
				)
			then
				vim.api.nvim_buf_delete(bufnr, { force = false, unload = false })
			end
		end
	end

	timer:start(0, 10000, vim.schedule_wrap(clean_buffer))
end

buffer_cleaner()
