local parsers = {
  "odin",
  "typst",
  "latex",
  "bibtex",
  "rust",
  "markdown",
  "markdown_inline",
  "vimdoc",
  "query",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("nvim-treesitter").install(parsers):wait(300000)

    vim.treesitter.language.register("latex", { "plaintex" })

    local group = vim.api.nvim_create_augroup("TreesitterHighlight", { clear = true })

    vim.api.nvim_create_autocmd("FileType", {
      group = group,
      callback = function(ev)
        if not vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype) then
          return
        end
        if pcall(vim.treesitter.start, ev.buf) then
          vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
