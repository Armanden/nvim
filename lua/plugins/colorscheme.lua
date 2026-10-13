return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  opts = {
    style = "night",
    transparent = false,
    styles = {
      comments = { italic = true },
      keywords = { italic = true },
    },
  },
  config = function(_, opts)
    require("tokyonight").setup(opts)
    vim.o.background = "dark"
    vim.cmd.colorscheme("tokyonight")
  end,
}
