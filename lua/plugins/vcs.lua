return {
	-- show git line status
	{
		"lewis6991/gitsigns.nvim",
		event = "VeryLazy",
	},
	-- show svn line status
	{
		"mhinz/vim-signify",
		event = "VeryLazy",
		config = function()
			vim.cmd [[
				let g:signify_skip = { 'vcs': { 'allow': ['svn'] } }
				let g:signify_sign_add = '│'
				let g:signify_sign_change = '│'
				let g:signify_sign_change_delete = '~'
				let g:signify_priority = 6
			]]
		end,
	},
	-- git tui + diffview
	{
		"TimUntersberger/neogit",
		event = "VeryLazy",
		opts = {
			integrations = {
				diffview = true,
			},
		},
		dependencies = {
			{ "sindrets/diffview.nvim" },
		},
		keys = {
			{ "<leader>gs", function() require("neogit").open() end },
			{ "<leader>gd", function() require("diffview").open() end },
		},
	},
	-- integrate github issues and pull requests
	{
		"pwntester/octo.nvim",
		dependencies = "nvim-telescope/telescope.nvim",
		opts = {},
		cmd = "Octo",
		enabled = false,
	},
}
