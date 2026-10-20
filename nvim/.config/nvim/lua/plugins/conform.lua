local oxfmt_filetypes = {
  "javascript",
  "javascriptreact",
  "typescript",
  "typescriptreact",
  "json",
  "jsonc",
  "css",
  "markdown",
}

return {
  "stevearc/conform.nvim",
  opts = function(_, opts)
    opts.formatters_by_ft = opts.formatters_by_ft or {}
    opts.formatters_by_ft.xml = { lsp_format = "prefer" }
    opts.formatters_by_ft.php = { "php_cs_fixer" }

    -- oxfmt tylko w projektach z .oxfmtrc.json; gdzie indziej zostają formattery z LazyVim
    for _, ft in ipairs(oxfmt_filetypes) do
      local fallback = opts.formatters_by_ft[ft] or {}
      opts.formatters_by_ft[ft] = function(bufnr)
        if require("conform").get_formatter_info("oxfmt", bufnr).available then
          return { "oxfmt" }
        end
        return type(fallback) == "function" and fallback(bufnr) or fallback
      end
    end

    opts.formatters = opts.formatters or {}
    opts.formatters.oxfmt = {
      cwd = function(self, ctx)
        return require("conform.util").root_file({ ".oxfmtrc.json", ".oxfmtrc.jsonc" })(self, ctx)
      end,
      require_cwd = true,
    }
  end,
}
