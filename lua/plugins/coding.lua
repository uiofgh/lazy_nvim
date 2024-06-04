local Util = require "util"

return {
	-- comment code
	{
		"numToStr/Comment.nvim",
		opts = { mappings = false },
		keys = {
			{
				"gcc",
				function()
					return vim.v.count == 0 and "<Plug>(comment_toggle_linewise_current)"
						or "<Plug>(comment_toggle_linewise_count)"
				end,
				expr = true,
			},
			{ "gc", "<Plug>(comment_toggle_linewise)" },
			{ "gc", "<Plug>(comment_toggle_linewise_visual)", mode = "x" },
		},
	},
	-- auto close ([{
	{
		"windwp/nvim-autopairs",
		event = "VeryLazy",
		opts = { map_cr = false },
	},

	-- auto completion
	{
		"hrsh7th/nvim-cmp",
		version = false, -- last release is way too old
		event = "InsertEnter",
		dependencies = {
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/cmp-buffer",
			"hrsh7th/cmp-path",
			"saadparwaiz1/cmp_luasnip",
			"lukas-reineke/cmp-rg",
			"hrsh7th/cmp-cmdline",
			"dmitmel/cmp-cmdline-history",
			"rcarriga/cmp-dap",
			"hrsh7th/cmp-nvim-lsp-signature-help",
			"L3MON4D3/LuaSnip",
		},
		opts = function()
			local cmp = require "cmp"
			local luasnip = require "luasnip"
			return {
				completion = {
					completeopt = "menu,menuone,noselect",
				},
				snippet = {
					expand = function(args) require("luasnip").lsp_expand(args.body) end,
				},
				mapping = cmp.mapping.preset.insert {
					["<C-n>"] = cmp.mapping.select_next_item { behavior = cmp.SelectBehavior.Insert },
					["<C-p>"] = cmp.mapping.select_prev_item { behavior = cmp.SelectBehavior.Insert },
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping {
						i = function(fallback)
							if cmp.visible() and cmp.get_active_entry() then
								cmp.confirm { behavior = cmp.ConfirmBehavior.Replace, select = false }
							else
								fallback()
							end
						end,
						s = cmp.mapping.confirm { select = true },
						-- c = cmp.mapping.confirm { behavior = cmp.ConfirmBehavior.Replace, select = true },
					},
					["<S-CR>"] = cmp.mapping.confirm {
						behavior = cmp.ConfirmBehavior.Replace,
						select = true,
					}, -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
					["<Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
						elseif luasnip.expand_or_jumpable() then
							luasnip.expand_or_jump()
						else
							fallback()
						end
					end, { "i", "s", "c" }),
					["<S-Tab>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
						elseif luasnip.jumpable(-1) then
							luasnip.jump(-1)
						else
							fallback()
						end
					end, { "i", "s", "c" }),
				},
				sources = cmp.config.sources {
					{ name = "nvim_lsp" },
					{ name = "nvim_lsp_signature_help" },
					{ name = "luasnip" },
					{ name = "calc" },
					{
						name = "rg",
						keyword_length = 4,
						max_item_count = 20,
					},
					{
						name = "buffer",
						option = {
							get_bufnrs = function() return vim.api.nvim_list_bufs() end,
						},
						max_item_count = 20,
					},
					{ name = "path" },
				},
				formatting = {
					format = function(_, item)
						local icons = require("config.icon").kinds
						if icons[item.kind] then item.kind = icons[item.kind] .. item.kind end
						return item
					end,
				},
				experimental = {
					ghost_text = {
						hl_group = "LspCodeLens",
					},
				},
			}
		end,
		config = function(opts)
			local cmp = require "cmp"
			cmp.setup(opts.opts())
			cmp.setup.cmdline({ "/", "?" }, {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" },
					{
						name = "cmdline_history",
						max_item_count = 20,
					},
				},
			})

			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources {
					{
						name = "cmdline_history",
						max_item_count = 20,
					},
					{ name = "async_path" },
					{ name = "cmdline" },
				},
			})

			local ok, cmp_autopairs = pcall(require, "nvim-autopairs.completion.cmp")
			if ok then cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done()) end
		end,
	},

	-- show code structure tree
	{
		"stevearc/aerial.nvim",
		keys = {
			{ "<F4>", "<cmd>AerialToggle<CR>" },
		},
		opts = {
			layout = {
				width = 40,
				default_direction = "right",
				placement = "edge",
			},
		},
	},
}
