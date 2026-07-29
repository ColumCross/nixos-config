local uv = vim.uv or vim.loop
local theme_file = vim.fn.expand("~/.cache/current-theme")
local last_theme = nil

local function check_theme()
  local file = io.open(theme_file, "r")
  if not file then
    return
  end

  local theme = file:read("*a"):gsub("%s+", "")
  file:close()

  if theme ~= last_theme and (theme == "dark" or theme == "light") then
    last_theme = theme
    local nvconfig = require "nvconfig"
    nvconfig.base46.theme = theme == "light" and "github_light" or "onedark"
    require("base46").load_all_highlights()
  end
end

uv.new_timer():start(2000, 2000, function()
  vim.schedule(check_theme)
end)
