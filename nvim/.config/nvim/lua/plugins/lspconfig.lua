local loader = require("utils.settings_loader")

local licence_key = os.getenv("INTELEPHENSE_LICENSE_KEY")

return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      intelephense = {

        on_init = function(client)
          local root_dir = client.config.root_dir or vim.fn.getcwd()
          local workspace_settings = loader.get_workspace_settings(root_dir, "/.nvim/intelephense.json")
          local intelephense_settings = workspace_settings.intelephense or {}

          client.config.settings.intelephense =
            vim.tbl_deep_extend("force", client.config.settings.intelephense, intelephense_settings)
        end,

        settings = {
          intelephense = {},
        },
        init_options = {
          licenceKey = licence_key,
        },
      },
    },
  },
}
