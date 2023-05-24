local Util = require "util"

return {
	-- statusline
	{
		"nvim-lualine/lualine.nvim",
		opts = function()
			local function normal_path(path) return string.gsub(path, "\\", "/") end

			local function project_root() return Util.root_dir(vim.api.nvim_buf_get_name(0)) end

			local function project_name() return vim.fn.fnamemodify(project_root(), ":t") end

			local function is_project() return project_root() ~= nil end

			local function rel_fn()
				local root = project_root()
				local fname = vim.api.nvim_buf_get_name(0)
				if not root or root == "" then return normal_path(fname) end
				return normal_path(Util.rel_path(fname, root))
			end
			return {
				options = {
					icons_enabled = true,
					theme = "auto",
					component_separators = { left = "", right = "" },
					section_separators = { left = "", right = "" },
					disabled_filetypes = {
						statusline = {},
						winbar = {
							"aerial",
							"NvimTree",
							"qf",
							"Mundo",
							"MundoDiff",
							"dbui",
							"vista",
							"dashboard",
							"noice",
							"dapui_breakpoints",
							"dapui_scopes",
							"dapui_stacks",
							"dapui_watches",
							"dapui-repl",
							"dapui-console",
						},
					},
					ignore_focus = {},
					always_divide_middle = true,
					globalstatus = false,
					refresh = {
						statusline = 1000,
						tabline = 1000,
						winbar = 1000,
					},
				},
				sections = {
					lualine_a = { "mode" },
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { "filename" },
					lualine_x = {
						"encoding",
						{
							"fileformat",
							symbols = {
								unix = "UNIX",
								dos = "DOS",
								mac = "MAC",
							},
						},
						{
							"filetype",
							icons_enabled = false,
						},
					},
					lualine_y = { "progress" },
					lualine_z = { "location" },
				},
				inactive_sections = {
					lualine_a = {},
					lualine_b = { "branch", "diff", "diagnostics" },
					lualine_c = { { "filename", path = 2 } },
					lualine_x = {
						"encoding",
						{
							"fileformat",
							symbols = {
								unix = "UNIX",
								dos = "DOS",
								mac = "MAC",
							},
						},
						{
							"filetype",
							icons_enabled = false,
						},
					},
					lualine_y = {},
					lualine_z = {},
				},
				tabline = {},
				winbar = {
					lualine_a = { { project_name, cond = is_project } },
					lualine_c = { { rel_fn } },
				},
				inactive_winbar = {
					lualine_a = { { project_name, cond = is_project } },
					lualine_c = { rel_fn },
				},
				extensions = {
					"man",
					"nvim-tree",
					"nvim-dap-ui",
					"quickfix",
					"toggleterm",
				},
			}
		end,
	},
	-- better interactive ui
	{ "stevearc/dressing.nvim", opts = {} },
	-- message window
	{
		"rcarriga/nvim-notify",
		opts = {
			background_colour = "#27292d",
		},
	},
	-- bufferline
	{
		"akinsho/bufferline.nvim",
		opts = {
			options = {
				mode = "tabs",
				show_duplicate_prefix = false,
			},
		},
	},
}
