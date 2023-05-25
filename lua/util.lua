local Util = require "lazy.core.util"

local M = {}

M.root_patterns = { ".vimrc.lua", ".git", ".local.vimrc", ".git/" }
M.lsp_root_patterns = { ".vimrc.lua", ".git", ".local.vimrc", ".git/", "lua" }
M.CUSTOM_LSP = {
	XY3_LUA = "luahelper-xy3",
}

---@param on_attach fun(client, buffer)
function M.on_attach(on_attach)
	vim.api.nvim_create_autocmd("LspAttach", {
		callback = function(args)
			local buffer = args.buf
			local client = vim.lsp.get_client_by_id(args.data.client_id)
			on_attach(client, buffer)
		end,
	})
end

---@param plugin string
function M.has(plugin) return require("lazy.core.config").plugins[plugin] ~= nil end

function M.fg(name)
	---@type {foreground?:number}?
	local hl = vim.api.nvim_get_hl and vim.api.nvim_get_hl(0, { name = name })
		or vim.api.nvim_get_hl_by_name(name, true)
	local fg = hl and hl.fg or hl.foreground
	return fg and { fg = string.format("#%06x", fg) }
end

---@param fn fun()
function M.on_very_lazy(fn)
	vim.api.nvim_create_autocmd("User", {
		pattern = "VeryLazy",
		callback = function() fn() end,
	})
end

---@param name string
function M.opts(name)
	local plugin = require("lazy.core.config").plugins[name]
	if not plugin then return {} end
	local Plugin = require "lazy.core.plugin"
	return Plugin.values(plugin, "opts", false)
end

-- returns the root directory based on:
-- * lsp workspace folders
-- * lsp root_dir
-- * root pattern of filename of the current buffer
-- * root pattern of cwd
---@return string
function M.get_root()
	---@type string?
	local path = vim.api.nvim_buf_get_name(0)
	path = path ~= "" and vim.loop.fs_realpath(path) or nil
	---@type string[]
	local roots = {}
	if path then
		for _, client in pairs(vim.lsp.get_active_clients { bufnr = 0 }) do
			local workspace = client.config.workspace_folders
			local paths = workspace and vim.tbl_map(function(ws) return vim.uri_to_fname(ws.uri) end, workspace)
				or client.config.root_dir and { client.config.root_dir }
				or {}
			for _, p in ipairs(paths) do
				local r = vim.loop.fs_realpath(p)
				if path:find(r, 1, true) then roots[#roots + 1] = r end
			end
		end
	end
	table.sort(roots, function(a, b) return #a > #b end)
	---@type string?
	local root = roots[1]
	if not root then
		path = path and vim.fs.dirname(path) or vim.loop.cwd()
		---@type string?
		root = vim.fs.find(M.root_patterns, { path = path, upward = true })[1]
		root = root and vim.fs.dirname(root) or vim.loop.cwd()
	end
	---@cast root string
	return root
end

-- this will return a function that calls telescope.
-- cwd will default to lazyvim.util.get_root
-- for `files`, git_files or find_files will be chosen depending on .git
function M.telescope(builtin, opts)
	local params = { builtin = builtin, opts = opts }
	return function()
		builtin = params.builtin
		opts = params.opts
		opts = vim.tbl_deep_extend("force", { cwd = M.get_root() }, opts or {})
		if builtin == "files" then
			if vim.loop.fs_stat((opts.cwd or vim.loop.cwd()) .. "/.git") then
				opts.show_untracked = true
				builtin = "git_files"
			else
				builtin = "find_files"
			end
		end
		if opts.cwd and opts.cwd ~= vim.loop.cwd() then
			opts.attach_mappings = function(_, map)
				map("i", "<a-c>", function()
					local action_state = require "telescope.actions.state"
					local line = action_state.get_current_line()
					M.telescope(
						params.builtin,
						vim.tbl_deep_extend("force", {}, params.opts or {}, { cwd = false, default_text = line })
					)()
				end)
				return true
			end
		end

		require("telescope.builtin")[builtin](opts)
	end
end

-- Opens a floating terminal (interactive by default)
---@param cmd? string[]|string
---@param opts? LazyCmdOptions|{interactive?:boolean, esc_esc?:false}
function M.float_term(cmd, opts)
	opts = vim.tbl_deep_extend("force", {
		size = { width = 0.9, height = 0.9 },
	}, opts or {})
	local float = require("lazy.util").float_term(cmd, opts)
	if opts.esc_esc == false then vim.keymap.set("t", "<esc>", "<esc>", { buffer = float.buf, nowait = true }) end
end

---@param silent boolean?
---@param values? {[1]:any, [2]:any}
function M.toggle(option, silent, values)
	if values then
		if vim.opt_local[option]:get() == values[1] then
			vim.opt_local[option] = values[2]
		else
			vim.opt_local[option] = values[1]
		end
		return Util.info("Set " .. option .. " to " .. vim.opt_local[option]:get(), { title = "Option" })
	end
	vim.opt_local[option] = not vim.opt_local[option]:get()
	if not silent then
		if vim.opt_local[option]:get() then
			Util.info("Enabled " .. option, { title = "Option" })
		else
			Util.warn("Disabled " .. option, { title = "Option" })
		end
	end
end

local enabled = true
function M.toggle_diagnostics()
	enabled = not enabled
	if enabled then
		vim.diagnostic.enable()
		Util.info("Enabled diagnostics", { title = "Diagnostics" })
	else
		vim.diagnostic.disable()
		Util.warn("Disabled diagnostics", { title = "Diagnostics" })
	end
end

function M.deprecate(old, new)
	Util.warn(("`%s` is deprecated. Please use `%s` instead"):format(old, new), { title = "LazyVim" })
end

-- delay notifications till vim.notify was replaced or after 500ms
function M.lazy_notify()
	local notifs = {}
	local function temp(...) table.insert(notifs, vim.F.pack_len(...)) end

	local orig = vim.notify
	vim.notify = temp

	local timer = vim.loop.new_timer()
	local check = vim.loop.new_check()

	local replay = function()
		timer:stop()
		check:stop()
		if vim.notify == temp then
			vim.notify = orig -- put back the original notify if needed
		end
		vim.schedule(function()
			---@diagnostic disable-next-line: no-unknown
			for _, notif in ipairs(notifs) do
				vim.notify(vim.F.unpack_len(notif))
			end
		end)
	end

	-- wait till vim.notify has been replaced
	check:start(function()
		if vim.notify ~= temp then replay() end
	end)
	-- or if it took more than 500ms, then something went wrong
	timer:start(500, 0, replay)
end

function M.lsp_get_config(server)
	local configs = require "lspconfig.configs"
	return rawget(configs, server)
end

---@param server string
---@param cond fun( root_dir, config): boolean
function M.lsp_disable(server, cond)
	local util = require "lspconfig.util"
	local def = M.lsp_get_config(server)
	def.document_config.on_new_config = util.add_hook_before(
		def.document_config.on_new_config,
		function(config, root_dir)
			if cond(root_dir, config) then config.enabled = false end
		end
	)
end

function M.is_dh3(path)
	if string.find(path, "dh3") or string.find(path, "dh25") then return true end
end

function M.is_gbk(path)
	if path:find "popo_tool" then return end
	return M.is_dh3(path)
end

function M.is_dos(path)
	if M.is_dh3(path) then
		if path:find "server" then return end
	end
	return true
end

function M.rel_root(path) return vim.fn.fnamemodify(M.root_dir(path), ":~") end

function M.is_nvim(path)
	if vim.fn.fnamemodify(M.rel_root(path), ":p:h") == vim.fn.stdpath "config" then return true end
end

function M.is_plugin(path) return vim.fn.fnamemodify(M.rel_root(path), ":p:h:h") == M.get_lazy_path() end

function M.is_nvim_lua(path)
	if M.is_nvim(path) then return true end
	if M.is_plugin(path) then return true end
end

function M.join_paths(...) return table.concat({ ... }, M.get_path_sep()) end

function M.get_mason_path(...) return M.join_paths(vim.fn.stdpath "data", "mason", ...) end

function M.get_lazy_path(...) return M.join_paths(vim.fn.stdpath "data", "lazy", ...) end

function M.get_plugin_path(plugin)
	local data = require("lazy.core.config").plugins[plugin]
	if not data then return end
	return data.dir
end

function P(...)
	local args = { n = select("#", ...), ... }
	for i = 1, args.n do
		args[i] = vim.inspect(args[i])
	end
	print(unpack(args))
end

function M.is_win() return vim.fn.has "win32" == 1 end

function M.get_cur_project() return vim.fn.getcwd() end

function M.get_path_sep() return M.is_win() and "\\" or "/" end

function M.parent_dir(dir) return vim.fn.fnamemodify(dir, ":h") end

function M.match(dir, pattern)
	if string.sub(pattern, 1, 1) == "=" then
		return vim.fn.fnamemodify(dir, ":t") == string.sub(pattern, 2, #pattern)
	else
		return vim.fn.globpath(dir, pattern) ~= ""
	end
end

function M.split(s, re, plain, n)
	local i1, ls = 1, {}
	if not re then re = "%s+" end
	if re == "" then return { s } end
	while true do
		local i2, i3 = string.find(s, re, i1, plain)
		if not i2 then
			local last = string.sub(s, i1)
			if last ~= "" then table.insert(ls, last) end
			if #ls == 1 and ls[1] == "" then
				return {}
			else
				return ls
			end
		end
		table.insert(ls, string.sub(s, i1, i2 - 1))
		if n and #ls == n then
			ls[#ls] = string.sub(s, i1)
			return ls
		end
		i1 = i3 + 1
	end
end

function M.rel_path(P, start)
	local min, append = math.min, table.insert
	local sep = M.get_path_sep()
	start = start or M.get_cur_project()
	local compare
	if M.is_win() then
		P = P:gsub("/", "\\")
		start = start:gsub("/", "\\")
		compare = function(v) return v:lower() end
	else
		compare = function(v) return v end
	end
	local startl, Pl = M.split(start, sep), M.split(P, sep)
	local n = min(#startl, #Pl)
	if M.is_win() and n > 0 and string.sub(Pl[1], 2, 2) == ":" and Pl[1] ~= startl[1] then return P end
	local k = n + 1 -- default value if this loop doesn't bail out!
	for i = 1, n do
		if compare(startl[i]) ~= compare(Pl[i]) then
			k = i
			break
		end
	end
	local rell = {}
	for i = 1, #startl - k + 1 do
		rell[i] = ".."
	end
	if k <= #Pl then
		for i = k, #Pl do
			append(rell, Pl[i])
		end
	end
	return table.concat(rell, sep)
end

function M.root_dir(path)
	local current
	local parent = path

	while 1 do
		for _, pattern in ipairs(M.root_patterns) do
			if M.match(parent, pattern) then return parent end
		end

		current, parent = parent, M.parent_dir(parent)
		if parent == current then break end
	end
end

return M
