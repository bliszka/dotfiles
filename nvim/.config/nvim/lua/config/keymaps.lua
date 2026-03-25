-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps herei
vim.keymap.set(
  "n",
  "<leader>o",
  "i<CR><Esc>",
  { noremap = true, silent = true, desc = "Insert line below without moving cursor" }
)
