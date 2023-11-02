if vim.fn.has "win32" == 1 then
	vim.g.python3_host_prog = "~/.pyenv/pyenv-win/versions/nvim/scripts/python.exe"
else
	vim.g.python3_host_prog = "~/.pyenv/versions/nvim/bin/python"
end
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local opt = vim.opt

opt.fencs = "utf-8,gbk"

opt.timeout = false
opt.timeoutlen = 300
opt.ttimeout = true
opt.updatetime = 100

opt.shortmess:append "c"

opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4

opt.termguicolors = true

opt.laststatus = 2

opt.autoindent = true
opt.expandtab = false
opt.cindent = true
opt.linespace = 1
opt.number = true
opt.showmatch = true
opt.hlsearch = true
opt.incsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.swapfile = false
opt.cursorline = true
opt.wildmenu = true
opt.autoread = true
opt.fixendofline = false
opt.splitright = true
opt.splitbelow = true
opt.undofile = true
opt.scrolloff = 5
opt.signcolumn = "yes"
opt.title = true
opt.jumpoptions = { "stack", "view" }

-- fold
opt.foldcolumn = "1" -- '0' is not bad
opt.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
opt.foldlevelstart = 99
opt.foldenable = true
opt.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

-- opt.foldmethod = "expr"
-- opt.foldexpr = "nvim_treesitter#foldexpr()"
--
opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal"
opt.wildignore:append {
	"*.pyc",
	"node_modules",
	".svn",
	".git",
	".vs",
	".vscode",
	".idea",
	".cache",
	"Temp",
	".log",
	"log",
}
