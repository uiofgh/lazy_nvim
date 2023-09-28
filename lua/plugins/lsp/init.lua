local Util = require "util"

return {
	-- lspconfig
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "folke/neoconf.nvim", cmd = "Neoconf", config = true },
			{ "folke/neodev.nvim", opts = { experimental = { pathStrict = true } } },
			"mason.nvim",
			"williamboman/mason-lspconfig.nvim",
			"hrsh7th/cmp-nvim-lsp",
		},
		---@class PluginLspOpts
		opts = {
			-- options for vim.diagnostic.config()
			diagnostics = {
				underline = true,
				update_in_insert = false,
				virtual_text = {
					spacing = 4,
					source = "if_many",
					prefix = "●",
					-- this will set set the prefix to a function that returns the diagnostics icon based on the severity
					-- this only works on a recent 0.10.0 build. Will be set to "●" when not supported
					-- prefix = "icons",
				},
				severity_sort = true,
			},
			-- add any global capabilities here
			capabilities = {},
			-- Automatically format on save
			autoformat = true,
			-- options for vim.lsp.buf.format
			-- `bufnr` and `filter` is handled by the LazyVim formatter,
			-- but can be also overridden when specified
			format = {
				formatting_options = nil,
				timeout_ms = nil,
			},
			-- LSP Server Settings
			---@type lspconfig.options
			servers = {
				jsonls = {},
				lua_ls = {
					settings = {
						Lua = {
							workspace = {
								checkThirdParty = false,
							},
							completion = {
								callSnippet = "Replace",
							},
						},
					},
				},
				[Util.CUSTOM_LSP.XY3_LUA] = {},
				clangd = {
					cmd = {
						"clangd",
						"--background-index",
						"--pch-storage=memory",
						"--clang-tidy",
						"--suggest-missing-includes",
						"--cross-file-rename",
						"--completion-style=detailed",
					},
					init_options = {
						clangdFileStatus = true,
						usePlaceholders = true,
						completeUnimported = true,
						semanticHighlighting = true,
					},
					capabilities = {
						offsetEncoding = { "gbk" },
					},
				},
				html = {},
			},
			-- you can do any additional lsp server setup here
			-- return true if you don't want this server to be setup with lspconfig
			---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
			setup = {
				-- example to setup with typescript.nvim
				-- tsserver = function(_, opts)
				--   require("typescript").setup({ server = opts })
				--   return true
				-- end,
				-- Specify * to use this function as a fallback for any server
				-- ["*"] = function(server, opts) end,
			},
		},
		---@param opts PluginLspOpts
		config = function(_, opts)
			-- setup autoformat
			require("plugins.lsp.format").autoformat = opts.autoformat
			-- setup formatting and keymaps
			Util.on_attach(function(client, buffer)
				require("plugins.lsp.format").on_attach(client, buffer)
				require("plugins.lsp.keymaps").on_attach(client, buffer)
			end)

			-- diagnostics
			for name, icon in pairs(require("config.icon").diagnostics) do
				name = "DiagnosticSign" .. name
				vim.fn.sign_define(name, { text = icon, texthl = name, numhl = "" })
			end

			if type(opts.diagnostics.virtual_text) == "table" and opts.diagnostics.virtual_text.prefix == "icons" then
				opts.diagnostics.virtual_text.prefix = vim.fn.has "nvim-0.10.0" == 0 and "●"
					or function(diagnostic)
						local icons = require("config.icon").diagnostics
						for d, icon in pairs(icons) do
							if diagnostic.severity == vim.diagnostic.severity[d:upper()] then return icon end
						end
					end
			end

			vim.diagnostic.config(vim.deepcopy(opts.diagnostics))

			local servers = opts.servers
			local capabilities = vim.tbl_deep_extend(
				"force",
				{},
				vim.lsp.protocol.make_client_capabilities(),
				require("cmp_nvim_lsp").default_capabilities(),
				opts.capabilities or {}
			)

			vim.lsp.handlers["textDocument/references"] = vim.lsp.with(function(err, result, ctx, config)
				if not result or vim.tbl_isempty(result) then
					vim.notify "No references found"
				else
					local client = vim.lsp.get_client_by_id(ctx.client_id)
					config = config or {}
					local title = "References"
					local items = vim.lsp.util.locations_to_items(result, client.offset_encoding)
					local filepath = vim.api.nvim_buf_get_name(ctx.bufnr)
					local lnum = ctx.params.position.line + 1
					items = vim.tbl_filter(function(v)
						-- Remove current line from result
						return not (v.filename == filepath and v.lnum == lnum)
					end, vim.F.if_nil(items, {}))

					if vim.tbl_isempty(items) then
						vim.notify "No references found"
						return
					end

					if #items == 1 then
						-- jump to location
						local location = items[1]
						local bufnr = ctx.bufnr
						if location.filename then bufnr = vim.uri_to_bufnr(vim.uri_from_fname(location.filename)) end
						vim.api.nvim_win_set_buf(0, bufnr)
						vim.api.nvim_win_set_cursor(0, { location.lnum, location.col - 1 })
						return
					end

					if config.loclist then
						vim.fn.setloclist(0, {}, " ", { title = title, items = items, context = ctx })
						vim.api.nvim_command "lopen"
					elseif config.on_list then
						assert(type(config.on_list) == "function", "on_list is not a function")
						config.on_list { title = title, items = items, context = ctx }
					else
						vim.fn.setqflist({}, " ", { title = title, items = items, context = ctx })
						vim.api.nvim_command "botright copen"
					end
				end
			end, {})

			-- add custom lsp
			local configs = require "lspconfig.configs"
			if not configs[Util.CUSTOM_LSP.XY3_LUA] then
				configs[Util.CUSTOM_LSP.XY3_LUA] = {
					default_config = {
						cmd = { Util.is_win() and "luahelper-lsp.cmd" or "luahelper-lsp", "--mode=1" },
						-- cmd = vim.lsp.rpc.connect("127.0.0.1", 7778),
						filetypes = { "lua", "pto", "tbl" },
						root_dir = require("lspconfig").util.root_pattern(Util.lsp_root_patterns),
						init_options = {
							PluginPath = require("mason-core.path").concat {
								require("mason-core.path").package_prefix(Util.CUSTOM_LSP.XY3_LUA),
							},
						},
					},
					docs = {
						description = [[
							https://github.com/uiofgh/LuaHelper-xy3
							Language Server Protocol for Lua.
						]],
					},
				}
			end

			local function setup(server)
				local server_capabilities = capabilities
				if servers[server] and servers[server].capabilities then
					server_capabilities =
						vim.tbl_deep_extend("force", server_capabilities, servers[server].capabilities)
				end
				local server_opts = vim.tbl_deep_extend("force", {
					capabilities = server_capabilities,
				}, servers[server] or {})

				if opts.setup[server] then
					if opts.setup[server](server, server_opts) then return end
				elseif opts.setup["*"] then
					if opts.setup["*"](server, server_opts) then return end
				else
					require("lspconfig")[server].setup(server_opts)
				end
			end

			-- get all the servers that are available thourgh mason-lspconfig
			local have_mason, mlsp = pcall(require, "mason-lspconfig")
			local all_mslp_servers = {}
			if have_mason then
				local server_mapping = require "mason-lspconfig.mappings.server"
				server_mapping.lspconfig_to_package[Util.CUSTOM_LSP.XY3_LUA] = Util.CUSTOM_LSP.XY3_LUA
				server_mapping.package_to_lspconfig[Util.CUSTOM_LSP.XY3_LUA] = Util.CUSTOM_LSP.XY3_LUA
				all_mslp_servers = vim.tbl_keys(server_mapping.lspconfig_to_package)
			end

			local ensure_installed = {} ---@type string[]
			for server, server_opts in pairs(servers) do
				if server_opts then
					server_opts = server_opts == true and {} or server_opts
					-- run manual setup if mason=false or if this is a server that cannot be installed with mason-lspconfig
					if server_opts.mason == false or not vim.tbl_contains(all_mslp_servers, server) then
						setup(server)
					else
						ensure_installed[#ensure_installed + 1] = server
					end
				end
			end

			if have_mason then
				mlsp.setup { ensure_installed = ensure_installed }
				mlsp.setup_handlers { setup }
			end

			if Util.lsp_get_config "denols" and Util.lsp_get_config "tsserver" then
				local is_deno = require("lspconfig.util").root_pattern("deno.json", "deno.jsonc")
				Util.lsp_disable("tsserver", is_deno)
				Util.lsp_disable("denols", function(root_dir) return not is_deno(root_dir) end)
			end
			if servers[Util.CUSTOM_LSP.XY3_LUA] then
				Util.lsp_disable("lua_ls", function(root_dir, _) return not Util.is_nvim_lua(root_dir) end)
				Util.lsp_disable(Util.CUSTOM_LSP.XY3_LUA, function(root_dir, _) return Util.is_nvim_lua(root_dir) end)
			end
		end,
	},

	-- formatters
	{
		"jose-elias-alvarez/null-ls.nvim",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = { "mason.nvim" },
		opts = function()
			local nls = require "null-ls"
			return {
				root_dir = require("null-ls.utils").root_pattern(unpack(Util.root_patterns)),
				sources = {
					nls.builtins.formatting.stylua,
					nls.builtins.formatting.shfmt,
					nls.builtins.formatting.yapf,
					nls.builtins.formatting.clang_format,
					nls.builtins.formatting.prettier,
					nls.builtins.formatting.rustfmt,
					nls.builtins.formatting.gofumpt,
				},
			}
		end,
	},

	-- cmdline tools and lsp servers
	{
		"williamboman/mason.nvim",
		cmd = "Mason",
		keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
		build = ":MasonUpdate",
		opts = {
			registries = {
				"github:mason-org/mason-registry",
				"lua:plugins.lsp.mason.index",
			},
			ensure_installed = {
				"clang-format",
				"cmake-language-server",
				"go-debug-adapter",
				"gofumpt",
				"gopls",
				"js-debug-adapter",
				"pyright",
				"prettier",
				"rust-analyzer",
				"rustfmt",
				"shfmt",
				"stylua",
				"typescript-language-server",
				"vim-language-server",
				"yamlfmt",
				"yapf",
			},
		},
		---@param opts MasonSettings | {ensure_installed: string[]}
		config = function(_, opts)
			require("mason").setup(opts)
			local mr = require "mason-registry"
			local function ensure_installed()
				for _, tool in ipairs(opts.ensure_installed) do
					local p = mr.get_package(tool)
					if not p:is_installed() then p:install() end
				end
			end
			if mr.refresh then
				mr.refresh(ensure_installed)
			else
				ensure_installed()
			end
		end,
	},

	-- ui for lsp progress
	{
		"j-hui/fidget.nvim",
		event = "LspAttach",
		opts = {},
		tag = "legacy",
	},

	-- preview window for lsp
	{
		"rmagatti/goto-preview",
		opts = {
			default_mappings = true,
		},
	},
	-- A pretty list for showing diagnostics, references, telescope results, quickfix and location lists to help you solve all the trouble your code is causing.
	{
		"folke/trouble.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			mode = "document_diagnostics",
		},
		keys = { { "<leader>ct", "<cmd>TroubleToggle<cr>", desc = "TroubleToggle" } },
	},
}
