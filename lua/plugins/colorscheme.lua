return {
	{
		"uiofgh/sonokai",
		lazy = false,
		priority = 1000,
		config = function()
			vim.g.sonokai_style = "default"
			vim.g.sonokai_disable_italic_comment = 1
			vim.g.sonokai_diagnostic_text_highlight = 1
			vim.g.sonokai_diagnostic_line_highlight = 1
			vim.g.sonokai_diagnostic_virtual_text = "colored"
			vim.g.sonokai_better_performace = 1
		end,
	},
}
