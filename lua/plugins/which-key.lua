return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    preset = "modern",
    delay = 300,
    spec = {
      { "<leader>c", group = "compile" },
      { "<leader>d", group = "diagnostics" },
      { "<leader>p", group = "preview" },
      { "<leader>q", group = "quickfix" },
      { "<leader>w", group = "write" },
    },  },
  keys = {
    { "<leader>?", function() require("which-key").show({ global = false }) end, desc = "Buffer local keymaps" },
  },
}
