return {
  "owallb/mason-auto-install.nvim",
  dependencies = {
    "mason-org/mason.nvim",
    "neovim/nvim-lspconfig",
  },
  opts = {
    packages = {
      "intelephense",
      "php-debug-adapter",
      "php-cs-fixer",
      "phpstan",
      "phpcs",
      "eslint_d",
      "prettier",
      "xmlformatter",
    },
    post_install_hooks = {
      function()
        vim.cmd("MasonInstalli ilntelephense")
      end,
    },
  },
}
