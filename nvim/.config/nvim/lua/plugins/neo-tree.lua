return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      filtered_items = {
        visible = false,
        show_hidden_count = true,
        hide_dotfiles = true,
        always_show = {
          ".gitignore",
          ".editorconfig",
        },
        always_show_by_pattern = {
          ".env*",
          ".phpcs*",
          ".php-cs-fixer*.php",
        },
        hide_by_pattern = {
          ".php-cs-fixer.cache",
        },
      },
      follow_current_file = {
        leave_dirs_open = true,
      },
    },
  },
}
