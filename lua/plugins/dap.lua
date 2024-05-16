local Util = require "util"

return {
	"mfussenegger/nvim-dap",

	dependencies = {

		-- fancy UI for the debugger
		{
			"rcarriga/nvim-dap-ui",
			dependencies = "nvim-neotest/nvim-nio",
			-- stylua: ignore
			keys = {
				{ "<leader>du", function() require("dapui").toggle({}) end,  desc = "Dap UI" },
				{ "<leader>de", function() require("dapui").eval() end,      desc = "Eval",  mode = { "n", "v" } },
			},
			opts = {},
			config = function(_, opts)
				local dap = require "dap"
				local dapui = require "dapui"
				dapui.setup(opts)
				dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open {} end
				dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close {} end
				dap.listeners.before.event_exited["dapui_config"] = function() dapui.close {} end
			end,
		},

		-- virtual text for the debugger
		{
			"theHamsta/nvim-dap-virtual-text",
			opts = {},
		},

		-- mason.nvim integration
		{
			"jay-babu/mason-nvim-dap.nvim",
			dependencies = "mason.nvim",
			cmd = { "DapInstall", "DapUninstall" },
			opts = {
				-- Makes a best effort to setup the various debuggers with
				-- reasonable debug configurations
				automatic_installation = true,

				-- You can provide additional configuration to the handlers,
				-- see mason-nvim-dap README for more information
				handlers = {},

				-- You'll need to check that you have the required things installed
				-- online, please don't ask me how to install them :)
				ensure_installed = {
					-- Update this to ensure that you have the debuggers for the langs you want
				},
			},
		},

		-- vscode typescript debugger
		{
			"mxsdev/nvim-dap-vscode-js",
			config = function()
				require("dap-vscode-js").setup {
					node_path = "node", -- Path of node executable. Defaults to $NODE_PATH, and then "node"
					debugger_path = Util.get_mason_path("packages", "js-debug-adapter"), -- Path to vscode-js-debug installation.
					debugger_cmd = { "js-debug-adapter" }, -- Command to use to launch the debug server. Takes precedence over `node_path` and `debugger_path`.
					debugger_executable = Util.get_mason_path(
						"packages",
						"js-debug-adapter",
						"js-debug",
						"src",
						"dapDebugServer.js"
					),
					adapters = { "pwa-node" }, -- which adapters to register in nvim-dap
					-- log_file_path = "(stdpath cache)/dap_vscode_js.log" -- Path for file logging
					-- log_file_level = false -- Logging level for output to file. Set to false to disable file logging.
					-- log_console_level = vim.log.levels.ERROR -- Logging level for output to console. Set to false to disable console output.
				}
				local dap = require "dap"
				for _, language in ipairs { "typescript", "javascript" } do
					dap.configurations[language] = {
						{
							type = "pwa-node",
							request = "launch",
							name = "Launch file",
							program = "${file}",
							cwd = "${workspaceFolder}",
						},
						{
							name = "Debug Main Process (Electron)",
							type = "pwa-node",
							request = "launch",
							program = "${workspaceFolder}/app/node_modules/.bin/electron",
							args = {
								".",
							},
							-- outFiles = {
							-- 	"${workspaceFolder}/app/dist/*.js",
							-- },
							resolveSourceMapLocations = {
								"${workspaceFolder}/app/**/*.js",
								"${workspaceFolder}/app/*.js",
							},
							rootPath = "${workspaceFolder}/app",
							cwd = "${workspaceFolder}/app",
							sourceMaps = true,
							skipFiles = { "<node_internals>/**" },
							protocol = "inspector",
							console = "integratedTerminal",
						},
						{
							type = "pwa-node",
							request = "attach",
							name = "Attach",
							processId = require("dap.utils").pick_process,
							cwd = "${workspaceFolder}",
						},
					}
				end
			end,
		},
	},

	-- stylua: ignore
	keys = {
		{ "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input('Breakpoint condition: ')) end,
			                                                                                                      desc =
			"Breakpoint Condition" },
		{ "<leader>db", function() require("dap").toggle_breakpoint() end,                                    desc =
		"Toggle Breakpoint" },
		{ "<leader>dc", function() require("dap").continue() end,                                             desc =
		"Continue" },
		{ "<leader>dC", function() require("dap").run_to_cursor() end,                                        desc =
		"Run to Cursor" },
		{ "<leader>dg", function() require("dap").goto_() end,                                                desc =
		"Go to line (no execute)" },
		{ "<leader>di", function() require("dap").step_into() end,                                            desc =
		"Step Into" },
		{ "<leader>dj", function() require("dap").down() end,                                                 desc =
		"Down" },
		{ "<leader>dk", function() require("dap").up() end,                                                   desc = "Up" },
		{ "<leader>dl", function() require("dap").run_last() end,                                             desc =
		"Run Last" },
		{ "<leader>do", function() require("dap").step_out() end,                                             desc =
		"Step Out" },
		{ "<leader>dO", function() require("dap").step_over() end,                                            desc =
		"Step Over" },
		{ "<leader>dp", function() require("dap").pause() end,                                                desc =
		"Pause" },
		{ "<leader>dr", function() require("dap").repl.toggle() end,                                          desc =
		"Toggle REPL" },
		{ "<leader>ds", function() require("dap").session() end,                                              desc =
		"Session" },
		{ "<leader>dt", function() require("dap").terminate() end,                                            desc =
		"Terminate" },
		{ "<leader>dw", function() require("dap.ui.widgets").hover() end,                                     desc =
		"Widgets" },
	},

	config = function()
		vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

		for name, sign in pairs(require("config.icon").dap) do
			sign = type(sign) == "table" and sign or { sign }
			vim.fn.sign_define(
				"Dap" .. name,
				{ text = sign[1], texthl = sign[2] or "DiagnosticInfo", linehl = sign[3], numhl = sign[3] }
			)
		end
	end,
}
