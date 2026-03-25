return {
  "gbprod/phpactor.nvim",
  ft = "php",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    install = {
      bin = vim.fn.stdpath("data") .. "/mason/packages/phpactor/phpactor.phar",
    },
    lspconfig = {
      enabled = false, -- LSP is configured in different place
    },
  },
  keys = {
    {
      "<leader>cM",
      function()
        require("phpactor").rpc("move_class", {})
      end,
      ft = "php",
      desc = "Move class",
    },
    {
      "<leader>cC",
      function()
        require("phpactor").rpc("copy_class", {})
      end,
      ft = "php",
      desc = "Copy class",
    },
    {
      "<leader>cg",
      function()
        require("phpactor").rpc("new_class", {})
      end,
      ft = "php",
      desc = "Generate class",
    },
    {
      "<leader>cI",
      function()
        require("phpactor").rpc("import_missing_classes", {})
      end,
      ft = "php",
      desc = "Import missing classes",
    },
    {
      "<leader>ci",
      function()
        require("phpactor").rpc("import_class", {})
      end,
      ft = "php",
      desc = "Import class",
    },
    {
      "<leader>cz",
      function()
        require("phpactor").rpc("context_menu", {})
      end,
      ft = "php",
      desc = "Phpactor context menu",
    },
  },
}
