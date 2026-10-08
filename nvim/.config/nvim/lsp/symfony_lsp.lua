---@brief
---
--- https://github.com/symfony/language-tools
---
--- Symfony-aware completion, navigation, references, diagnostics, code actions,
--- rename support and code lenses alongside a general PHP language server.
---
--- Install the `symfony-lsp` executable from a release, then make it
--- available on `PATH`.
---
--- The server asks before executing application code for runtime indexing. Set
--- `init_options.workspaceTrust` explicitly only for trusted workspaces.

---@type vim.lsp.Config
return {
  cmd = { "symfony-lsp" },
  filetypes = { "php", "twig", "yaml", "json", "xml", "javascript", "typescript", "env" },
  -- Only composer.json: with ".git" it attached to every git repo (incl. pure TS/React projects),
  -- answered textDocument/rename with null and inc-rename reported "Nothing renamed"
  root_markers = { "composer.json" },
  workspace_required = true,
  capabilities = {
    workspace = {
      didChangeWatchedFiles = {
        dynamicRegistration = true,
      },
    },
  },
  init_options = {
    workspaceTrust = true,
  },
  settings = {
    symfonyLsp = {},
  },
  on_init = function(client)
    -- Leave rename to intelephense: inc-rename aborts when any server errors on prepareRename
    -- and sends the rename only to the first capable client, which could be symfony_lsp
    client.server_capabilities.renameProvider = false
  end,
  commands = {
    ["editor.action.showReferences"] = function(command, ctx)
      local client = assert(vim.lsp.get_client_by_id(ctx.client_id))
      local arguments = command.arguments or {}
      local uri = arguments[1]
      local position = arguments[2]
      local references = arguments[3]
      if type(uri) ~= "string" or type(position) ~= "table" or type(references) ~= "table" then
        vim.notify("Symfony Language Tools returned an invalid reference command.", vim.log.levels.ERROR)
        return
      end

      local items = vim.lsp.util.locations_to_items(references, client.offset_encoding)
      vim.fn.setqflist({}, " ", {
        title = command.title,
        items = items,
        context = {
          command = command,
          bufnr = ctx.bufnr,
        },
      })
      vim.lsp.util.show_document({
        uri = uri,
        range = {
          start = position,
          ["end"] = position,
        },
      }, client.offset_encoding)
      vim.cmd("botright copen")
    end,
  },
}
