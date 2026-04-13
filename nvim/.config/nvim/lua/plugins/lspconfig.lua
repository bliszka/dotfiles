local license_path = os.getenv("INTELEPHENSE_LICENSE_KEY") or ""
local licence_key = ""

if vim.fn.filereadable(license_path) == 1 then
  licence_key = vim.fn.readfile(license_path)[1]
end

return {
  "neovim/nvim-lspconfig",
  init = function()
    -- intelephense uses VS Code-specific command for codelens, redirect to Snacks picker
    vim.lsp.commands["editor.action.peekLocations"] = function(command)
      local locations = command.arguments and command.arguments[3] or {}
      if #locations == 0 then
        vim.notify("No locations found", vim.log.levels.INFO)
        return
      end
      local qf_items = vim.lsp.util.locations_to_items(locations, "utf-8")
      local items = vim.tbl_map(function(loc)
        return {
          file = loc.filename,
          text = loc.filename .. " " .. loc.text,
          pos = { loc.lnum, loc.col - 1 },
        }
      end, qf_items)
      Snacks.picker.pick({ items = items, title = "Codelens" })
    end
  end,
  opts = {
    codelens = {
      enabled = false,
    },
    servers = {
      intelephense = {
        enabled = true,
        init_options = {
          licenceKey = licence_key,
        },
        before_init = function(_, config)
          local intelephenseConfig = vim.g.lsp_config and vim.g.lsp_config.intelephense
          if intelephenseConfig then
            config.settings.intelephense =
              vim.tbl_deep_extend("force", config.settings.intelephense, intelephenseConfig)
          end
        end,

        settings = {
          intelephense = {
            environment = {
              phpVersion = 8.5,
            },
            format = {
              enable = false,
            },
            codeLens = {
              references = {
                enable = true,
              },
              implementations = {
                enable = false,
              },
            },
          },
        },
      },

      phpactor = {
        enabled = true,
        settings = {
          ["phpactor.diagnostics.enable"] = false,
        },
        handlers = {
          -- Overwrite phpactor diagnostic to do nothing. The intelephense diagnostic is prefered
          ["textDocument/publishDiagnostics"] = function() end,
        },
        on_attach = function(client)
          client.server_capabilities.definitionProvider = false
          client.server_capabilities.referencesProvider = false
          client.server_capabilities.hoverProvider = false
          client.server_capabilities.completionProvider = false
          client.server_capabilities.documentFormattingProvider = false
          client.server_capabilities.documentRangeFormattingProvider = false
          client.server_capabilities.signatureHelpProvider = false
          client.server_capabilities.documentSymbolProvider = false
        end,
      },
    },
  },
}
