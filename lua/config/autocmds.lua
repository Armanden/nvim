local group = vim.api.nvim_create_augroup("UserCompile", { clear = true })

vim.api.nvim_create_autocmd("BufWritePost", {
  group = group,
  pattern = { "*.rs", "*.odin", "*.tex", "*.ltx", "*.sty", "*.typ" },
  callback = function(ev)
    require("config.compile").build(nil, ev.buf)
  end,
})
