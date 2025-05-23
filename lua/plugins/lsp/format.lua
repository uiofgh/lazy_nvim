local Util = require "lazy.core.util"

local M = {}

M.autoformat = false
M.format_path = {
	"~/shells",
	vim.fn.fnamemodify(require("util").get_plugin_path "rsync.nvim", ":~"),
	"~/Documents/GitHub/toolbox",
	"~/Documents/GitHub/DearPyGuiApp",
	"~/.config",
}

function M.toggle()
	if vim.b.autoformat == false then
		vim.b.autoformat = nil
		M.autoformat = true
	else
		M.autoformat = not M.autoformat
	end
	if M.autoformat then
		Util.info("Enabled format on save", { title = "Format" })
	else
		Util.warn("Disabled format on save", { title = "Format" })
	end
end

function M.is_auto_format(path)
	local lib = require "util"
	if lib.is_nvim(path) then return true end
	path = vim.fn.fnamemodify(path, ":p:h")
	path = vim.fn.fnamemodify(path, ":~")
	path = lib.root_dir(path) or path
	for _, s in ipairs(M.format_path) do
		if path == s or path:match(s) then return true end
	end
end

---@param opts? {force?:boolean}
function M.format(opts)
	local buf = vim.api.nvim_get_current_buf()
	if vim.b.autoformat == false and not (opts and opts.force) then return end
	if not M.is_auto_format(vim.api.nvim_buf_get_name(buf)) then return end
	local ft = vim.bo[buf].filetype
	local have_nls = package.loaded["null-ls"]
		and (#require("null-ls.sources").get_available(ft, "NULL_LS_FORMATTING") > 0)

	vim.lsp.buf.format(vim.tbl_deep_extend("force", {
		bufnr = buf,
		filter = function(client)
			if have_nls then return client.name == "null-ls" end
			return client.name ~= "null-ls"
		end,
	}, require("util").opts("nvim-lspconfig").format or {}))
end

function M.on_attach(client, buf)
	-- dont format if client disabled it
	if
		client.config
		and client.config.capabilities
		and client.config.capabilities.documentFormattingProvider == false
	then
		return
	end

	if client:supports_method "textDocument/formatting" then
		vim.api.nvim_create_autocmd("BufWritePre", {
			group = vim.api.nvim_create_augroup("LspFormat." .. buf, {}),
			buffer = buf,
			callback = function()
				if M.autoformat then M.format() end
			end,
		})
	end
end

return M
