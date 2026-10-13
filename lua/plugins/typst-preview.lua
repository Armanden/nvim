local tinymist = vim.fn.exepath("tinymist")

return {
  "chomosuke/typst-preview.nvim",
  version = "1.*",
  ft = "typst",
  dependencies = { "Myriad-Dreamin/tinymist" },
  opts = {
    dependencies_bin = { tinymist = tinymist ~= "" and tinymist or nil },
  },
  keys = {
    { "<leader>pv", "<cmd>TypstPreviewToggle<cr>", desc = "Toggle typst preview" },
    { "<leader>ps", "<cmd>TypstPreviewSyncCursor<cr>", desc = "Sync preview with cursor" },
    { "<leader>pf", "<cmd>TypstPreviewFollowCursorToggle<cr>", desc = "Toggle preview follow cursor" },
  },
}