-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}
local theme_file = vim.fn.expand "~/.cache/current-theme"
local current_theme = vim.fn.filereadable(theme_file) == 1 and vim.fn.readfile(theme_file)[1] or "dark"
local is_dark = current_theme ~= "light"

M.base46 = {
  theme = is_dark and "onedark" or "github_light",
  hl_override = is_dark and {
    Normal = { bg = "#000000" },
    NormalNC = { bg = "#000000" },
    NormalFloat = { bg = "#000000" },
  } or {},
}

-- M.nvdash = { load_on_startup = true }
-- M.ui = {
--       tabufline = {
--          lazyload = false
--      }
-- }

return M
