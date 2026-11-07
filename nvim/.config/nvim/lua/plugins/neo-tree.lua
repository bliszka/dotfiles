-- neo-tree: on test instead of the Snacks explorer (LazyVim extra
-- "editor.neo-tree" in lazyvim.json).
return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    filesystem = {
      -- Follow the current buffer: expand the tree to its file and highlight it,
      -- but keep every other open folder open (no auto-collapse).
      follow_current_file = { enabled = true, leave_dirs_open = true },
    },
  },
}
