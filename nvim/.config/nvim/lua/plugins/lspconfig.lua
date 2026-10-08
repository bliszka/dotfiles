local license_path = os.getenv("INTELEPHENSE_LICENSE_KEY") or ""
local licence_key = ""

if vim.fn.filereadable(license_path) == 1 then
  licence_key = vim.fn.readfile(license_path)[1]
end

-- symfony_lsp has renameProvider disabled (see lsp/symfony_lsp.lua) so inc-rename never sends
-- PHP/TS renames to it. Ask it directly first: it only accepts routes, services, parameters
-- and translation keys. Everything else falls back to inc-rename.
local function rename()
  local bufnr = vim.api.nvim_get_current_buf()
  local cword = vim.fn.expand("<cword>")
  local function open_inc_rename()
    vim.api.nvim_feedkeys(":" .. require("inc_rename").config.cmd_name .. " " .. cword, "n", false)
  end

  -- inc-rename silently closes its cmdline when no server can rename at the cursor
  -- (e.g. plain yaml keys like `autowire`), so check with prepareRename first and say why
  local function inc_rename()
    for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/rename" })) do
      if not c:supports_method("textDocument/prepareRename") then
        return open_inc_rename()
      end
    end
    if #vim.lsp.get_clients({ bufnr = bufnr, method = "textDocument/prepareRename" }) == 0 then
      return open_inc_rename()
    end
    vim.lsp.buf_request_all(bufnr, "textDocument/prepareRename", function(c)
      return vim.lsp.util.make_position_params(0, c.offset_encoding)
    end, function(results)
      local reason = "Nothing to rename at cursor"
      for _, res in pairs(results) do
        if res.result then
          return open_inc_rename()
        end
        reason = res.err and res.err.message or reason
      end
      vim.notify("[rename] " .. reason, vim.log.levels.WARN)
    end)
  end

  local client = vim.lsp.get_clients({ bufnr = bufnr, name = "symfony_lsp" })[1]
  if not client then
    return inc_rename()
  end

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding)
  client:request("textDocument/prepareRename", params, function(err, result)
    if err or not result then
      return inc_rename()
    end
    vim.ui.input({ prompt = "Symfony rename", default = result.placeholder or cword }, function(new_name)
      if not new_name or new_name == "" then
        return
      end
      params.newName = new_name
      client:request("textDocument/rename", params, function(rename_err, edit)
        if rename_err or not edit then
          local reason = rename_err and (": " .. rename_err.message) or ""
          vim.notify("[symfony_lsp] Nothing renamed" .. reason, vim.log.levels.WARN)
          return
        end
        vim.lsp.util.apply_workspace_edit(edit, client.offset_encoding)
        local files = vim.tbl_count(edit.changes or {}) + #(edit.documentChanges or {})
        vim.notify(("[symfony_lsp] Renamed in %d file%s"):format(files, files == 1 and "" or "s"))
      end, bufnr)
    end)
  end, bufnr)
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
    -- Off by default, toggle with <leader>uh
    inlay_hints = {
      enabled = false,
    },
    servers = {
      ["*"] = {
        keys = {
          -- No `has = "rename"`: in yaml/twig symfony_lsp may be the only server able to rename
          { "<leader>cr", rename, desc = "Rename (symfony_lsp / inc-rename)" },
        },
      },
      vtsls = {
        settings = {
          typescript = {
            preferences = {
              -- Rename from an importing file renames the original symbol instead of
              -- creating a local alias (`import { foo as bar }`). Copied to javascript by LazyVim.
              useAliasesForRenames = false,
            },
          },
        },
      },
      yamlls = {
        settings = {
          yaml = {
            customTags = {
              "!tagged_iterator scalar",
              "!tagged_locator scalar",
              "!returns_clone scalar",
              "!service mapping",
              "!abstract scalar",
              "!php/const scalar",
            },
          },
        },
      },
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
              phpVersion = "8.5.0",
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
