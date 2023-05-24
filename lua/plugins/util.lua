return {
	-- library used by other plugins
	{ "nvim-lua/plenary.nvim", lazy = true },
	{ "kevinhwang91/promise-async", lazy = true },

	-- makes some plugins dot-repeatable like leap
	{ "tpope/vim-repeat", event = "VeryLazy" },

	-- add icons for ui display
	{ "nvim-tree/nvim-web-devicons" },
}
