return {
  "Myriad-Dreamin/tinymist",
  ft = "typst",
  build = false,
  module = false,
  init = function()
    vim.lsp.config("tinymist", {
      cmd = { "tinymist", "lsp" },
      filetypes = { "typst" },
      root_dir = function(bufnr, on_dir)
        local file = vim.api.nvim_buf_get_name(bufnr)
        local dir = file ~= "" and vim.fs.dirname(vim.fs.normalize(file)) or vim.uv.cwd()
        on_dir(vim.fs.root(dir, { "typst.toml", ".git" }) or dir)
      end,
    })
    vim.lsp.enable("tinymist")
  end,
}