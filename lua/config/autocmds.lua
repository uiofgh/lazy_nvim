local function augroup(name) return vim.api.nvim_create_augroup("config_" .. name, { clear = true }) end

-- remember folds
vim.api.nvim_create_autocmd({ "BufWinLeave" }, {
	group = augroup "RememberFoldsLeave",
	pattern = "*.*",
	command = "mkview",
})
vim.api.nvim_create_autocmd({ "BufWinEnter" }, {
	group = augroup "RememberFoldsEnter",
	pattern = "*.*",
	command = "silent! loadview",
})

-- set program title
vim.api.nvim_create_autocmd({ "BufEnter" }, {
	group = augroup "SetTitleName",
	callback = function()
		local cwd = vim.loop.cwd()
		local title = vim.fn.fnamemodify(cwd, ":t")
		if not title or title == "" or title == vim.opt.titlestring then return end
		vim.opt.titlestring = title
	end,
})

-- resize splits if window got resized
vim.api.nvim_create_autocmd({ "VimResized" }, {
	group = augroup "resize_splits",
	callback = function() vim.cmd "tabdo wincmd =" end,
})

-- close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
	group = augroup "close_with_q",
	pattern = {
		"PlenaryTestPopup",
		"help",
		"lspinfo",
		"man",
		"notify",
		"qf",
		"spectre_panel",
		"startuptime",
		"tsplayground",
		"checkhealth",
		"grug-far",
		"OverseerList",
		"cmake_tools_terminal",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
	end,
})

-- help enhance
vim.api.nvim_create_autocmd("FileType", {
	group = augroup "help_key",
	pattern = {
		"help",
	},
	callback = function(event)
		vim.keymap.set("n", "<CR>", "<C-]>", { buffer = 0 })
		vim.keymap.set("n", "<BS>", "<C-T>", { buffer = 0 })
	end,
})

-- python
vim.api.nvim_create_autocmd("FileType", {
	group = augroup "python",
	pattern = {
		"python",
	},
	callback = function(event)
		vim.bo.shiftwidth = 4
		vim.bo.softtabstop = 4
		vim.bo.expandtab = false
	end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = augroup "auto_create_dir",
	callback = function(event)
		if event.match:match "^%w%w+://" then return end
		local file = vim.loop.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup "highlight_yank",
	callback = function() vim.highlight.on_yank() end,
})

local function buffer_cleaner()
	local timer = vim.loop.new_timer()
	if not timer then return end

	local bufOpt = vim.api.nvim_buf_get_option

	local retirementAgeMins = 10
	local ignoredFiletypes = { "NvimTree", "qf", "toggleterm", "Mundo", "MundoDiff", "dbui", "vista", "noice" }

	local function clean_buffer()
		local openBuffers = vim.fn.getbufinfo { buflisted = 1 }
		local cur_time = os.time()
		for _, buf in pairs(openBuffers) do
			local bufnr = buf.bufnr
			local usedSecsAgo = cur_time - buf.lastused
			local recentlyUsed = usedSecsAgo < retirementAgeMins * 60
			local bufFt = bufOpt(bufnr, "filetype")
			local isIgnoredFt = vim.tbl_contains(ignoredFiletypes, bufFt)
			local isIgnoredSpecialBuffer = bufOpt(buf.bufnr, "buftype") ~= ""
			local isIgnoredAltFile = buf.name == vim.fn.expand "#:p"
			local isModified = bufOpt(bufnr, "modified")
			local isSelected = not vim.tbl_isempty(vim.fn.win_findbuf(bufnr))
			if
				not (
					recentlyUsed
					or isIgnoredFt
					or isIgnoredSpecialBuffer
					or isIgnoredAltFile
					or isModified
					or isSelected
				)
			then
				vim.api.nvim_buf_delete(bufnr, { force = false, unload = false })
			end
		end
	end

	timer:start(0, 10000, vim.schedule_wrap(clean_buffer))
end

buffer_cleaner()

local FileWatcher = {
	watchers = {},
	config = {
		ext_whitelist = { ".lua", ".pto", ".py" },
		dir_blacklist = { ".svn", ".git", ".temp", ".cache", "node_modules" },
		debounce_ms = 300,
	},
}

local function notify(msg, level)
	level = level or vim.log.levels.INFO
	vim.schedule(function() vim.notify(msg, level, { title = "FileWatcher" }) end)
end

function FileWatcher.should_sync(relpath)
	for _, dir in ipairs(FileWatcher.config.dir_blacklist) do
		if relpath:find(dir, 1, true) then return false end
	end
	local ext = relpath:match "%.[^./\\]+$"
	if not ext then return false end
	return vim.tbl_contains(FileWatcher.config.ext_whitelist, ext)
end

local function load_rsync_cfg(path)
	local cfg = {}
	local f = loadfile(path .. "/.rsync.lua", nil, cfg)
	if not f then return nil end
	f()
	local defaults = { binPath = "rsync", options = { "-r" } }
	return vim.tbl_deep_extend("keep", cfg, defaults)
end

local function run_rsync(bin, args, cb)
	local stderr_chunks = {}
	local stdout = vim.uv.new_pipe()
	local stderr = vim.uv.new_pipe()

	local handle
	handle = vim.uv.spawn(bin, {
		args = args,
		stdio = { nil, stdout, stderr },
	}, function(code)
		stdout:close()
		stderr:close()
		handle:close()
		local err_msg = table.concat(stderr_chunks)
		if cb then cb(code, err_msg) end
	end)

	stderr:read_start(function(err, data)
		if data then stderr_chunks[#stderr_chunks + 1] = data end
	end)
end

local function sync_files(project_path, files, opts)
	opts = opts or {}
	local cfg = load_rsync_cfg(project_path)
	if not cfg or not cfg.remotePath then
		notify("No .rsync.lua or remotePath not set", vim.log.levels.WARN)
		return
	end

	local tmpfile = vim.fn.tempname()
	vim.fn.writefile(files, tmpfile)

	local projectName = cfg.projectName or vim.fn.fnamemodify(project_path, ":t")
	local remaining = 0
	local success_count = 0

	for i = 1, 10 do
		local remoteKey = i == 1 and "remotePath" or ("remotePath" .. i)
		if not cfg[remoteKey] then break end
		remaining = remaining + 1
	end

	for i = 1, 10 do
		local sshKey = i == 1 and "sshArgs" or ("sshArgs" .. i)
		local remoteKey = i == 1 and "remotePath" or ("remotePath" .. i)
		if not cfg[remoteKey] then break end

		local args = {}
		for _, opt in ipairs(cfg.options) do
			if opt ~= "-R" and opt ~= "--relative" then args[#args + 1] = opt end
		end
		if cfg[sshKey] then args[#args + 1] = cfg[sshKey] end
		args[#args + 1] = "--files-from=" .. tmpfile
		args[#args + 1] = project_path .. "/"
		args[#args + 1] = cfg[remoteKey] .. projectName .. "/"

		run_rsync(cfg.binPath or "rsync", args, function(code, err_msg)
			remaining = remaining - 1
			if code == 0 then success_count = success_count + 1 end
			if remaining == 0 then
				vim.schedule(function()
					vim.fn.delete(tmpfile)
					local title = opts.title or "FileWatcher"
					if success_count > 0 then
						vim.notify(
							"Synced " .. #files .. " files to " .. success_count .. " target(s)",
							vim.log.levels.INFO,
							{ title = title }
						)
					end
				end)
			end
			if code ~= 0 then notify("Sync error: " .. err_msg, vim.log.levels.ERROR) end
		end)
	end
end

function FileWatcher.start(path)
	if FileWatcher.watchers[path] then return end

	local handle = vim.uv.new_fs_event()
	if not handle then return end

	local pending = {}
	local timer = vim.uv.new_timer()

	local function flush()
		local files = {}
		for f in pairs(pending) do
			if vim.uv.fs_stat(path .. "/" .. f) then files[#files + 1] = f end
		end
		pending = {}
		if #files == 0 then return end
		vim.schedule(function() sync_files(path, files) end)
	end

	handle:start(path, { recursive = true }, function(err, filename)
		if err or not filename then return end
		if not FileWatcher.should_sync(filename) then return end
		pending[filename] = true
		timer:stop()
		timer:start(FileWatcher.config.debounce_ms, 0, flush)
	end)

	FileWatcher.watchers[path] = { handle = handle, timer = timer }
end

function FileWatcher.stop(path)
	local w = FileWatcher.watchers[path]
	if not w then return end
	w.handle:stop()
	w.timer:stop()
	FileWatcher.watchers[path] = nil
end

function FileWatcher.stop_all()
	for path in pairs(FileWatcher.watchers) do
		FileWatcher.stop(path)
	end
end

vim.api.nvim_create_user_command("WatchStart", function()
	local path = vim.fn.getcwd()
	FileWatcher.start(path)
	notify("Started: " .. path)
end, {})

vim.api.nvim_create_user_command("WatchStop", function()
	local path = vim.fn.getcwd()
	FileWatcher.stop(path)
	notify("Stopped: " .. path)
end, {})

vim.api.nvim_create_user_command("WatchStatus", function()
	local paths = vim.tbl_keys(FileWatcher.watchers)
	if #paths == 0 then
		notify "No active watchers"
	else
		notify("Active:\n" .. table.concat(paths, "\n"))
	end
end, {})

local function svn_sync_picker()
	local ok_pickers, pickers = pcall(require, "telescope.pickers")
	local ok_finders, finders = pcall(require, "telescope.finders")
	local ok_conf, conf = pcall(require, "telescope.config")
	local ok_actions, actions = pcall(require, "telescope.actions")
	local ok_state, action_state = pcall(require, "telescope.actions.state")
	if not (ok_pickers and ok_finders and ok_conf and ok_actions and ok_state) then
		vim.notify("Telescope not available", vim.log.levels.ERROR, { title = "SvnSync" })
		return
	end

	local project_path = vim.fn.getcwd()
	local cfg = load_rsync_cfg(project_path)
	if not cfg or not cfg.remotePath then
		vim.notify("No .rsync.lua or remotePath not set", vim.log.levels.WARN, { title = "SvnSync" })
		return
	end

	local output = vim.fn.systemlist "svn status"
	if vim.v.shell_error ~= 0 then
		vim.notify("svn status failed:\n" .. table.concat(output, "\n"), vim.log.levels.ERROR, { title = "SvnSync" })
		return
	end

	local entries = {}
	for _, line in ipairs(output) do
		-- svn status format: "X       path" where X is status char(s), then spaces, then path
		local status, filepath = line:match "^(%S+)%s+(.+)$"
		if status and filepath and status ~= "D" then
			entries[#entries + 1] = {
				status = status,
				path = filepath,
				display = string.format("[%s] %s", status, filepath),
			}
		end
	end

	if #entries == 0 then
		vim.notify("No changed files from svn status", vim.log.levels.INFO, { title = "SvnSync" })
		return
	end

	pickers
		.new({}, {
			prompt_title = "SVN Changed Files → Sync",
			finder = finders.new_table {
				results = entries,
				entry_maker = function(entry)
					return {
						value = entry,
						display = entry.display,
						ordinal = entry.path,
						path = project_path .. "/" .. entry.path,
					}
				end,
			},
			sorter = conf.values.generic_sorter {},
			attach_mappings = function(prompt_bufnr, map)
				local function sync_selected()
					local picker = action_state.get_current_picker(prompt_bufnr)
					local selections = picker:get_multi_selection()
					if #selections == 0 then
						local entry = action_state.get_selected_entry()
						if entry then selections = { entry } end
					end
					actions.close(prompt_bufnr)

					if #selections == 0 then return end

					local files = {}
					for _, sel in ipairs(selections) do
						files[#files + 1] = sel.value.path
					end

					sync_files(project_path, files, { title = "SvnSync" })
				end

				actions.select_default:replace(sync_selected)
				return true
			end,
		})
		:find()
end

vim.api.nvim_create_user_command("SyncSvnChanges", svn_sync_picker, {})

vim.api.nvim_create_user_command("SyncCurrentFile", function()
	local bufpath = vim.api.nvim_buf_get_name(0)
	if bufpath == "" then
		notify("No file in current buffer", vim.log.levels.WARN)
		return
	end
	bufpath = vim.uv.fs_realpath(bufpath)
	if not bufpath then
		notify("Cannot resolve file path", vim.log.levels.WARN)
		return
	end

	local project_path = vim.fn.getcwd()
	local cfg = load_rsync_cfg(project_path)
	if not cfg or not cfg.remotePath then
		notify("No .rsync.lua or remotePath not set in " .. project_path, vim.log.levels.WARN)
		return
	end

	local prefix = project_path .. "/"
	if bufpath:sub(1, #prefix) == prefix then
		sync_files(project_path, { bufpath:sub(#prefix + 1) }, { title = "SyncCurrentFile" })
		return
	end

	local projectName = cfg.projectName or vim.fn.fnamemodify(project_path, ":t")
	local relpath = require("util").rel_path(bufpath, project_path)
	local remote_subdir = vim.fn.fnamemodify(relpath, ":h")

	local remaining = 0
	local success_count = 0

	for i = 1, 10 do
		local remoteKey = i == 1 and "remotePath" or ("remotePath" .. i)
		if not cfg[remoteKey] then break end
		remaining = remaining + 1
	end

	for i = 1, 10 do
		local sshKey = i == 1 and "sshArgs" or ("sshArgs" .. i)
		local remoteKey = i == 1 and "remotePath" or ("remotePath" .. i)
		if not cfg[remoteKey] then break end

		local args = {}
		for _, opt in ipairs(cfg.options) do
			if opt ~= "-R" and opt ~= "--relative" then args[#args + 1] = opt end
		end
		if cfg[sshKey] then args[#args + 1] = cfg[sshKey] end
		args[#args + 1] = bufpath
		args[#args + 1] = cfg[remoteKey] .. projectName .. "/" .. remote_subdir .. "/"

		run_rsync(cfg.binPath or "rsync", args, function(code, err_msg)
			remaining = remaining - 1
			if code == 0 then success_count = success_count + 1 end
			if remaining == 0 then
				vim.schedule(function()
					if success_count > 0 then
						vim.notify(
							"Synced " .. vim.fn.fnamemodify(bufpath, ":t") .. " to " .. success_count .. " target(s)",
							vim.log.levels.INFO,
							{ title = "SyncCurrentFile" }
						)
					end
				end)
			end
			if code ~= 0 then notify("Sync error: " .. err_msg, vim.log.levels.ERROR) end
		end)
	end
end, {})

vim.api.nvim_create_autocmd("VimLeavePre", {
	group = augroup "file_watcher_cleanup",
	callback = FileWatcher.stop_all,
})

vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
	group = augroup "file_watcher_autostart",
	callback = function()
		local path = vim.fn.getcwd()
		if vim.uv.fs_stat(path .. "/.rsync.lua") then FileWatcher.start(path) end
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	callback = function(args)
		local treesitter = require "nvim-treesitter"
		local lang = vim.treesitter.language.get_lang(args.match)
		if vim.list_contains(treesitter.get_available(), lang) then
			if not vim.list_contains(treesitter.get_installed(), lang) then treesitter.install(lang):wait() end
			vim.treesitter.start(args.buf)
		end
	end,
	desc = "Enable nvim-treesitter and install parser if not installed",
})