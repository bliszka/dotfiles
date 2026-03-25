return {
  "nvim-neotest/neotest",
  dependencies = {
    "nvim-neotest/nvim-nio",
    "olimorris/neotest-phpunit",
  },
  opts = function()
    return {
      adapters = {
        require("neotest-phpunit")({
          phpunit_cmd = function()
            return vim.g.phpunit_cmd or "vendor/bin/phpunit"
          end,
        }),
      },
    }
  end,
}
