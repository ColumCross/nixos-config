local api = vim.api

api.nvim_create_user_command("ColorifyRefresh", function()
  local bufnr = api.nvim_get_current_buf()
  local namespace = require("nvchad.colorify.state").ns

  api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  require("nvchad.colorify").attach(bufnr, "ColorifyRefresh")
  vim.cmd "redraw"
end, {
  desc = "Clear and refresh Colorify highlights",
  force = true,
})
