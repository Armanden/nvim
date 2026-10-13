local settings = {
  rust = { expandtab = true, shiftwidth = 4, tabstop = 4, softtabstop = 4 },
  odin = { expandtab = false, shiftwidth = 8, tabstop = 8, softtabstop = 0 },
  tex = { expandtab = true, shiftwidth = 2, tabstop = 2, softtabstop = 2 },
  plaintex = { expandtab = true, shiftwidth = 2, tabstop = 2, softtabstop = 2 },
  typst = { expandtab = true, shiftwidth = 2, tabstop = 2, softtabstop = 2 },
}

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserIndent", { clear = true }),
  callback = function(ev)
    local opts = settings[vim.bo[ev.buf].filetype]
    if opts then
      for key, value in pairs(opts) do
        vim.bo[ev.buf][key] = value
      end
    end
  end,
})
