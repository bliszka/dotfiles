return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      xml = { lsp_format = "prefer" },
      php = { "php_cs_fixer" },
    },
    formatters = {},
  },
}
