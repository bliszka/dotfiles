return {
  "mfussenegger/nvim-dap",
  opts = function()
    local dap = require("dap")
    dap.set_log_level("TRACE")
    dap.adapters.php = {
      type = "executable",
      command = "php-debug-adapter",
      args = {},
    }

    dap.configurations.php = {
      {
        type = "php",
        request = "launch",
        name = "Listen for Xdebug on Docker",
        port = 9003,
        pathMappings = {
          ["/app/"] = "${workspaceFolder}",
        },
      },
    }
  end,
}
