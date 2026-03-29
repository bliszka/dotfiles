return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        transparent_background = true,
        flavour = "mocha",
        color_overrides = {
          -- mocha = {
          --   base = "#000000",
          --   mantle = "#000000",
          --   crust = "#000000",
          -- },
        },
      })

      vim.cmd.colorscheme("catppuccin-mocha")
    end,
  },
}
