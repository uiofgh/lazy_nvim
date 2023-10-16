local Util = require "util"

return {
	-- auto change nvim root directory
	{
		"notjedi/nvim-rooter.lua",
		opts = {
			rooter_patterns = { ".vimrc.lua", ".git", ".local.vimrc", ".git/" },
			trigger_patterns = { "*" },
			manual = false,
		},
	},
	{
		"nvim-telescope/telescope.nvim",
		cmd = "Telescope",
		keys = {
			{ "<leader>f", Util.telescope "files", desc = "Find Files (root dir)" },
			{
				"<leader>a",
				Util.telescope("live_grep", {
					additional_args = function(opts) return Util.is_gbk(opts.cwd) and { "-E gbk" } or {} end,
				}),
				desc = "Grep (root dir)",
			},
			{
				"<leader>s",
				Util.telescope("grep_string", {
					additional_args = function(opts)
						return Util.is_gbk(vim.api.nvim_buf_get_name(opts.bufnr)) and { "-E gbk" } or {}
					end,
				}),
				desc = "Fuzzy find (root dir)",
			},
			{ "<leader>h", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
			{ "<leader>r", "<cmd>Telescope resume<cr>", desc = "Resume" },
			{ "<leader>t", "<cmd>Telescope builtin include_extensions=true<cr>", desc = "Resume" },
		},
		opts = {
			defaults = {
				prompt_prefix = " ",
				selection_caret = " ",
				mappings = {
					i = {
						["<C-Down>"] = function(...) return require("telescope.actions").cycle_history_next(...) end,
						["<C-Up>"] = function(...) return require("telescope.actions").cycle_history_prev(...) end,
						["<C-f>"] = function(...) return require("telescope.actions").preview_scrolling_down(...) end,
						["<C-b>"] = function(...) return require("telescope.actions").preview_scrolling_up(...) end,
						["<esc>"] = function(...) return require("telescope.actions").close(...) end,
						["<C-h>"] = "which_key",
					},
				},
				buffer_previewer_maker = function(filepath, bufnr, opts)
					if opts.bufname ~= filepath and Util.is_gbk(filepath) then
						local ori_callback = opts.callback
						opts.callback = function(bufnr2)
							local content =
								vim.api.nvim_buf_get_lines(bufnr2, 0, vim.api.nvim_buf_line_count(bufnr2), false)
							if not content or #content < 1 then return end
							for index, data in ipairs(content) do
								local function _convert()
									if type(data) == "string" then
										content[index] = vim.fn.iconv(data, "gbk", "utf-8")
									end
								end
								pcall(_convert)
							end
							pcall(vim.api.nvim_buf_set_lines, bufnr2, 0, -1, false, content)
							if type(ori_callback) == "function" then ori_callback(bufnr2) end
						end
					end
					require("telescope.previewers.buffer_previewer").file_maker(filepath, bufnr, opts)
				end,
				preview = {
					check_mime_type = false,
					filetype_hook = function(filepath, bufnr, opts)
						local putils = require "telescope.previewers.utils"
						local excluded = vim.tbl_filter(function(ending) return filepath:match(ending .. "$") end, {
							".*%.so",
							".*%.a",
							".*%.lib",
							".*%.dll",
							".*%.bin",
							".*%.sql",
							".*%.hqx",
							".*%.blk",
							".*%.7z",
							".*%.zip",
							".*%.o",
							".*%.ttf",
						})
						if not vim.tbl_isempty(excluded) then
							putils.set_preview_message(
								bufnr,
								opts.winid,
								string.format("I don't like %s files!", excluded[1]:sub(5, -1))
							)
							return false
						end
						return true
					end,
				},
			},
			pickers = {
				builtin = {
					use_default_opts = true,
				},
			},
		},
		config = function(cfg)
			local telescope = require "telescope"
			telescope.setup(cfg.opts)
			local exts = {
				"aerial",
				"fzf",
				"workspaces",
				"neoclip",
				"rsync",
				"undo",
				"notify",
			}
			for _, module in ipairs(exts) do
				pcall(telescope.load_extension, module)
			end
		end,
	},
	-- better quickfix window
	{
		"kevinhwang91/nvim-bqf",
		event = "VeryLazy",
		config = function()
			local fn = vim.fn

			function _G.qftf(info)
				local items
				local ret = {}
				-- The name of item in list is based on the directory of quickfix window.
				-- Change the directory for quickfix window make the name of item shorter.
				-- It's a good opportunity to change current directory in quickfixtextfunc :)
				--
				-- local alterBufnr = fn.bufname('#') -- alternative buffer is the buffer before enter qf window
				-- local root = getRootByAlterBufnr(alterBufnr)
				-- vim.cmd(('noa lcd %s'):format(fn.fnameescape(root)))
				--
				if info.quickfix == 1 then
					items = fn.getqflist({ id = info.id, items = 0 }).items
				else
					items = fn.getloclist(info.winid, { id = info.id, items = 0 }).items
				end
				local limit = 31
				local fnameFmt1, fnameFmt2 = "%-" .. limit .. "s", "…%." .. (limit - 1) .. "s"
				local validFmt = "%s │%5d:%-3d│%s %s"
				for i = info.start_idx, info.end_idx do
					local e = items[i]
					local fname = ""
					local str
					if e.valid == 1 then
						if e.bufnr > 0 then
							fname = fn.bufname(e.bufnr)
							if fname == "" then
								fname = "[No Name]"
							else
								fname = fname:gsub("^" .. vim.env.HOME, "~")
							end
							-- char in fname may occur more than 1 width, ignore this issue in order to keep performance
							if #fname <= limit then
								fname = fnameFmt1:format(fname)
							else
								fname = fnameFmt2:format(fname:sub(1 - limit))
							end
						end
						local lnum = e.lnum > 99999 and -1 or e.lnum
						local col = e.col > 999 and -1 or e.col
						local qtype = e.type == "" and "" or " " .. e.type:sub(1, 1):upper()
						str = validFmt:format(fname, lnum, col, qtype, e.text)
					else
						str = e.text
					end
					table.insert(ret, str)
				end
				return ret
			end

			vim.o.qftf = "{info -> v:lua._G.qftf(info)}"
			vim.cmd [[
				hi BqfPreviewBorder guifg=#50a14f ctermfg=71
				hi link BqfPreviewRange Search
			]]
			require("bqf").setup {
				auto_enable = true,
				auto_resize_height = false,
				preview = {
					win_height = 12,
					win_vheight = 12,
					delay_syntax = 80,
					border_chars = { "┃", "┃", "━", "━", "┏", "┓", "┗", "┛", "█" },
					show_title = true,
					should_preview_cb = function(bufnr, winid)
						local ret = true
						local bufname = vim.api.nvim_buf_get_name(bufnr)
						local fsize = vim.fn.getfsize(bufname)
						if fsize > 100 * 1024 then
							-- skip file size greater than 100k
							ret = false
						elseif bufname:match "^fugitive://" then
							-- skip fugitive buffer
							ret = false
						end
						return ret
					end,
				},
				-- make `drop` and `tab drop` to become preferred
				func_map = {
					drop = "o",
					openc = "O",
					split = "<C-x>",
					tabdrop = "<C-t>",
					-- set to empty string to disable
					tabc = "",
				},
				filter = {
					fzf = {
						action_for = { ["ctrl-x"] = "split", ["ctrl-t"] = "tab drop" },
						extra_opts = { "--bind", "ctrl-o:toggle-all", "--prompt", "> " },
					},
				},
			}
		end,
	},
	-- better folding
	{
		"kevinhwang91/nvim-ufo",
		lazy = false,
		opts = {
			provider_selector = function(bufnr, filetype, buftype) return { "treesitter", "indent" } end,
		},
		keys = {
			{ "zR", function() require("ufo").openAllFolds() end, desc = "Open all folds" },
			{ "zM", function() require("ufo").closeAllFolds() end, desc = "Close all folds" },
		},
	},
	-- quick add surround character
	{
		"tpope/vim-surround",
		event = "VeryLazy",
	},
	-- multi cursor
	{
		"terryma/vim-multiple-cursors",
		event = "VeryLazy",
	},
	-- jump around with s key
	{
		"ggandor/lightspeed.nvim",
		event = "VeryLazy",
		opts = {
			ignore_case = true,
			special_keys = {
				next_match_group = "<tab>",
				prev_match_group = "<S-tab>",
			},
			repeat_ft_with_target_char = true,
		},
	},
	-- show color under hex/rgb text
	{
		"NvChad/nvim-colorizer.lua",
		event = "VeryLazy",
		opts = {
			filetypes = {
				"*",
				"!dapui*",
			},
			user_default_options = {
				names = false,
				always_update = true,
			},
		},
	},
	-- rsync file to remote
	{
		"uiofgh/rsync.nvim",
		event = { "BufWritePost", "FileWritePost" },
	},
	-- workspace config file
	{
		"klen/nvim-config-local",
		event = "VeryLazy",
		opts = {
			silent = true,
			lookup_parents = true,
		},
	},
	-- clipboard manage
	{
		"AckslD/nvim-neoclip.lua",
		event = "VeryLazy",
	},
	-- undo tree
	{
		"debugloop/telescope-undo.nvim",
		event = "VeryLazy",
	},
	-- fully integrated terminal
	{
		"akinsho/toggleterm.nvim",
		event = "VeryLazy",
		config = function()
			require("toggleterm").setup {
				insert_mappings = false,
				env = {
					MANPAGER = "less -X",
				},
				terminal_mappings = false,
				start_in_insert = true,
				persist_mode = true,
				open_mapping = [[<C-\>]],
				highlights = {
					CursorLineSign = { link = "DarkenedPanel" },
				},
				direction = "float",
			}

			function _G.set_terminal_keymaps()
				local opts = { buffer = 0 }
				local map = vim.keymap.set
				map("t", "<C-h>", [[<Cmd>wincmd h<CR>]], opts)
				map("t", "<C-j>", [[<Cmd>wincmd j<CR>]], opts)
				map("t", "<C-k>", [[<Cmd>wincmd k<CR>]], opts)
				map("t", "<C-l>", [[<Cmd>wincmd l<CR>]], opts)
				map("t", "<C-w>", [[<C-\><C-n><C-w>]], opts)
			end

			-- if you only want these mappings for toggle term use term://*toggleterm#* instead
			vim.cmd "autocmd! TermOpen term://* lua set_terminal_keymaps()"
		end,
	},
	-- file system explorer
	{
		"nvim-tree/nvim-tree.lua",
		keys = {
			{ "<F3>", function() require("nvim-tree.api").tree.toggle() end },
		},
		opts = function()
			local icons = require "config.icon"
			local function on_attach(bufnr)
				local api = require "nvim-tree.api"
				local function opts(desc)
					return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
				end

				api.config.mappings.default_on_attach(bufnr)

				vim.keymap.set("n", "h", api.node.navigate.parent_close, opts "Close Directory")
				vim.keymap.set("n", "v", api.node.open.vertical, opts "Open: Vertical Split")
				vim.keymap.set("n", "l", api.node.open.edit, opts "Open")
				vim.keymap.set("n", "<CR>", api.node.open.edit, opts "Open")
			end
			return {
				hijack_directories = {
					enable = false,
				},
				-- update_to_buf_dir = {
				--   enable = false,
				-- },
				-- disable_netrw = true,
				-- hijack_netrw = true,
				filters = {
					custom = { "^\\.git, ^\\.svn, ^\\.idea, ^\\.vs, ^\\.vscode" },
					exclude = {},
				},
				-- auto_close = true,
				-- open_on_tab = false,
				-- hijack_cursor = false,
				update_cwd = true,
				-- update_to_buf_dir = {
				--   enable = true,
				--   auto_open = true,
				-- },
				-- --   error
				-- --   info
				-- --   question
				-- --   warning
				-- --   lightbulb
				renderer = {
					add_trailing = false,
					group_empty = false,
					highlight_git = false,
					highlight_opened_files = "none",
					root_folder_modifier = ":t",
					indent_markers = {
						enable = false,
						icons = {
							corner = "└ ",
							edge = "│ ",
							none = "  ",
						},
					},
					icons = {
						webdev_colors = true,
						git_placement = "before",
						padding = " ",
						symlink_arrow = " ➛ ",
						show = {
							file = true,
							folder = true,
							folder_arrow = true,
							git = true,
						},
						glyphs = {
							default = "",
							symlink = "",
							folder = {
								arrow_open = icons.ui.ArrowOpen,
								arrow_closed = icons.ui.ArrowClosed,
								default = "",
								open = "",
								empty = "",
								empty_open = "",
								symlink = "",
								symlink_open = "",
							},
							git = {
								unstaged = "",
								staged = "S",
								unmerged = "",
								renamed = "➜",
								untracked = "U",
								deleted = "",
								ignored = "◌",
							},
						},
					},
				},
				diagnostics = {
					enable = true,
					icons = {
						hint = "",
						info = "",
						warning = "",
						error = "",
					},
				},
				update_focused_file = {
					enable = false,
					update_cwd = true,
					ignore_list = {},
				},
				-- system_open = {
				--   cmd = nil,
				--   args = {},
				-- },
				-- filters = {
				--   dotfiles = false,
				--   custom = {},
				-- },
				git = {
					enable = true,
					ignore = true,
					timeout = 500,
				},
				view = {
					width = 30,
					side = "left",
					-- auto_resize = true,
					number = false,
					relativenumber = false,
				},
				on_attach = on_attach,
			}
		end,
	},
	-- startup screen
	{
		"uiofgh/dashboard-nvim",
		event = "VimEnter",
		opts = {
			theme = "hyper",
			config = {
				week_header = {
					enable = true,
				},
				shortcut = {
					{
						icon = " ",
						desc = "Workspace",
						action = "Telescope workspaces",
						key = "a",
					},
					{
						icon = " ",
						desc = "New File",
						action = function() require("dashboard"):new_file() end,
						key = "e",
					},
					{
						icon = " ",
						desc = "Exit",
						action = "qa",
						key = "q",
					},
				},
				project = {
					enable = false,
				},
			},
		},
	},
	-- mapping filetype
	{
		"nathom/filetype.nvim",
		event = "VeryLazy",
		opts = {
			overrides = {
				extensions = {
					pto = "lua",
					tbl = "lua",
				},
			},
		},
	},
	-- manage workspace and project
	{
		"natecraddock/workspaces.nvim",
		event = "VeryLazy",
		config = function()
			local workspaces = require "workspaces"
			local sessions = require "sessions"
			workspaces.setup {
				hooks = {
					open = function(name, path, state)
						local fencs = "utf-8,gbk"
						if Util.is_gbk(path) then fencs = "gbk,utf-8" end
						vim.o.fencs = fencs

						local ffs = "unix,dos"
						if Util.is_dos(path) then ffs = "dos,unix" end
						vim.o.ffs = ffs

						local buffers = vim.fn.getbufinfo { buflisted = 1 }
						for _, buf in pairs(buffers) do
							if vim.api.nvim_buf_get_option(buf.bufnr, "modified") then
								vim.notify(
									vim.api.nvim_buf_get_name(buf.bufnr) .. " has unsaved changes!!",
									vim.log.levels.WARN,
									{ title = "Load workspace fail" }
								)
								return
							end
						end
						for _, buf in pairs(buffers) do
							local bufnr = buf.bufnr
							vim.api.nvim_buf_delete(bufnr, { force = false, unload = false })
						end
						for _, client in pairs(vim.lsp.get_active_clients()) do
							if client.name ~= "null-ls" then client:stop() end
						end
						sessions.load(nil, { silent = true })
					end,
				},
			}
			vim.api.nvim_create_user_command("SaveProject", function()
				sessions.save(nil, {})
				workspaces.add_swap()
			end, { desc = "Add current directory as workspace and create session." })
		end,
		dependencies = {
			{
				"natecraddock/sessions.nvim",
				opts = {
					events = { "WinEnter", "VimLeavePre" },
					session_filepath = vim.fn.stdpath "data" .. "/sessions",
					absolute = true,
				},
			},
		},
	},
	-- speical word mode
	{
		"nvim-neorg/neorg",
		-- lazy-load on filetype
		ft = "norg",
		-- options for neorg. This will automatically call `require("neorg").setup(opts)`
		opts = {
			load = {
				["core.defaults"] = {}, -- Loads default behaviour
				["core.norg.concealer"] = {}, -- Adds pretty icons to your documents
				["core.norg.dirman"] = { -- Manages Neorg workspaces
					config = {
						workspaces = {
							notes = "~/notes",
						},
					},
				},
			},
		},
	},
	-- telescope fuzzy finding
	{
		"nvim-telescope/telescope-fzf-native.nvim",
		event = "VeryLazy",
		build = "make",
		enabled = vim.fn.executable "make",
	},
	-- Adds better text object to operate such as ci, cA,
	{
		"wellle/targets.vim",
		event = "VeryLazy",
	},
	--
	{
		"RRethy/vim-illuminate",
		opts = {
			delay = 50,
		},
		config = function(_, opts)
			require("illuminate").configure(opts)
			vim.cmd [[
augroup illuminate_augroup
    autocmd!
    autocmd VimEnter * hi illuminatedWord cterm=underline gui=underline
    autocmd VimEnter * hi illuminatedWordRead cterm=underline gui=underline
    autocmd VimEnter * hi illuminatedWordWrite cterm=underline gui=underline
    autocmd VimEnter * hi illuminatedWordText cterm=underline gui=underline
augroup END
			]]
		end,
	},
}
