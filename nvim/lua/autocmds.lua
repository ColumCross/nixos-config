require "nvchad.autocmds"

local uv = vim.uv or vim.loop
local theme_file = vim.fn.expand("~/.cache/current-theme")
local last_theme = nil
local dark_overrides = {
  Normal = { bg = "#000000" },
  NormalNC = { bg = "#000000" },
  NormalFloat = { bg = "#000000" },
}

local function check_theme()
  local f = io.open(theme_file, "r")
  if f then
    local theme = f:read("*a"):gsub("%s+", "")
    f:close()
    if theme ~= last_theme and (theme == "dark" or theme == "light") then
      last_theme = theme
      local nvim_theme = theme == "light" and "github_light" or "onedark"

       local nvconfig = require "nvconfig"
       nvconfig.base46.theme = nvim_theme
       nvconfig.base46.hl_override = theme == "dark" and dark_overrides or {}

       local base46 = require "base46"
      base46.load_all_highlights()
    end
  end
end

uv.new_timer():start(2000, 2000, function()
  vim.schedule(check_theme)
end)
