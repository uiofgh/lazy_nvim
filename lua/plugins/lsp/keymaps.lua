local M = {}

---@type PluginLspKeys
M._keys = nil

---@return (LazyKeysSpec|{has?:string})[]
function M.get()
	if not M._keys then
		---@class PluginLspKeys
		M._keys = {
			{ "<leader>g?", vim.diagnostic.open_float, desc = "Line Diagnostics" },
			-- { "gd", "<cmd>Telescope lsp_definitions<cr>", desc = "Goto Definition", has = "definition" },
			-- { "gr", "<cmd>Telescope lsp_references<cr>", desc = "References" },
			{ "gd", vim.lsp.buf.definition, desc = "Goto Definition", has = "definition" },
			{ "gr", vim.lsp.buf.references, desc = "References" },
			{ "gD", vim.lsp.buf.declaration, desc = "Goto Declaration" },
			{ "gi", vim.lsp.buf.implementation, desc = "Goto implementation" },
			-- { "gI", "<cmd>Telescope lsp_implementations<cr>", desc = "Goto Implementation" },
			-- { "gy", "<cmd>Telescope lsp_type_definitions<cr>", desc = "Goto T[y]pe Definition" },
			{ "K", vim.lsp.buf.hover, desc = "Hover" },
			{ "gK", vim.lsp.buf.signature_help, desc = "Signature Help", has = "signatureHelp" },
			{
				"<c-k>",
				vim.lsp.buf.signature_help,
				mode = "i",
				desc = "Signature Help",
				has = "signatureHelp",
			},
			{ "]d", M.diagnostic_goto(true), desc = "Next Diagnostic" },
			{ "[d", M.diagnostic_goto(false), desc = "Prev Diagnostic" },
			{ "]e", M.diagnostic_goto(true, "ERROR"), desc = "Next Error" },
			{ "[e", M.diagnostic_goto(false, "ERROR"), desc = "Prev Error" },
			{ "]w", M.diagnostic_goto(true, "WARN"), desc = "Next Warning" },
			{ "[w", M.diagnostic_goto(false, "WARN"), desc = "Prev Warning" },
			-- { "<leader>cf", format, desc = "Format Document", has = "documentFormatting" },
			-- {
			-- 	"<leader>cf",
			-- 	format,
			-- 	desc = "Format Range",
			-- 	mode = "v",
			-- 	has = "documentRangeFormatting",
			-- },
			{
				"<leader>ca",
				vim.lsp.buf.code_action,
				desc = "Code Action",
				mode = { "n", "v" },
				has = "codeAction",
			},
			{
				"<leader>cA",
				function()
					vim.lsp.buf.code_action {
						context = {
							only = {
								"source",
							},
							diagnostics = {},
						},
					}
				end,
				desc = "Source Action",
				has = "codeAction",
			},
		}
		if require("util").has "inc-rename.nvim" then
			M._keys[#M._keys + 1] = {
				"<leader>cr",
				function()
					local inc_rename = require "inc_rename"
					return ":" .. inc_rename.config.cmd_name .. " " .. vim.fn.expand "<cword>"
				end,
				expr = true,
				desc = "Rename",
				has = "rename",
			}
		else
			M._keys[#M._keys + 1] = { "<leader>cr", vim.lsp.buf.rename, desc = "Rename", has = "rename" }
		end
	end
	return M._keys
end

function M.on_attach(client, buffer)
	local Keys = require "lazy.core.handler.keys"
	local keymaps = {} ---@type table<string,LazyKeys|{has?:string}>

	for _, value in ipairs(M.get()) do
		local keys = Keys.parse(value)
		keymaps[keys.id] = keys
	end

	for _, keys in pairs(keymaps) do
		if not keys.has or client.server_capabilities[keys.has .. "Provider"] then
			local opts = Keys.opts(keys)
			---@diagnostic disable-next-line: no-unknown
			opts.has = nil
			opts.silent = opts.silent ~= false
			opts.buffer = buffer
			vim.keymap.set(keys.mode or "n", keys.lhs, keys.rhs, opts)
		end
	end
end

function M.diagnostic_goto(next, severity)
	local go = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
	severity = severity and vim.diagnostic.severity[severity] or nil
	return function() go { severity = severity } end
end

return M
