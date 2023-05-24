local Pkg = require "mason-core.package"
local platform = require "mason-core.platform"
local _ = require "mason-core.functional"
local github = require "mason-core.managers.github"

local coalesce, when = _.coalesce, _.when

return Pkg.new {
	name = require("util").CUSTOM_LSP.XY3_LUA,
	desc = [[A language server that offers Lua language support - programmed in Lua.]],
	languages = { Pkg.Lang.Lua },
	categories = { Pkg.Cat.LSP },
	homepage = "https://github.com/uiofgh/LuaHelper-xy3",
	---@async
	---@param ctx InstallContext
	install = function(ctx)
		local repo = "uiofgh/LuaHelper-xy3"
		platform.when {
			unix = function()
				github
					.untargz_release_file({
						repo = repo,
						asset_file = coalesce(
							when(platform.is.mac_x64, _.format "luahelper-xy3-%s-darwin-x64.tar.gz"),
							when(platform.is.mac_arm64, _.format "luahelper-xy3-%s-darwin-arm64.tar.gz"),
							when(platform.is.linux_x64_gnu, _.format "luahelper-xy3-%s-linux-x64.tar.gz"),
							when(platform.is.linux_arm64_gnu, _.format "luahelper-xy3-%s-linux-arm64.tar.gz")
						),
					})
					.with_receipt()

				ctx:link_bin("luahelper-lsp", "luahelper-lsp")
			end,
			win = function()
				github
					.unzip_release_file({
						repo = repo,
						asset_file = coalesce(
							when(platform.is.win_x64, _.format "luahelper-xy3-%s-win32-x64.zip"),
							when(platform.is.win_x86, _.format "luahelper-xy3-%s-win32-ia32.zip")
						),
					})
					.with_receipt()
				ctx:link_bin("luahelper-lsp", "luahelper-lsp.exe")
			end,
		}
	end,
}
