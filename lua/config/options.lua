local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.termguicolors = true

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.smartindent = true
opt.softtabstop = 2
opt.shiftround = true

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

opt.scrolloff = 8
opt.sidescrolloff = 8

opt.splitbelow = true
opt.splitright = true

opt.undofile = true
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.updatetime = 250
opt.timeoutlen = 400

opt.completeopt = { "menu", "menuone", "noselect" }
opt.confirm = true
opt.clipboard = "unnamedplus"

opt.wrap = false
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --smart-case"
end
opt.grepformat = "%f:%l:%c:%m"

vim.o.shortmess = vim.o.shortmess .. "I"

vim.diagnostic.config({
  severity_sort = true,
  float = { border = "rounded", source = true },
})

vim.fn.sign_define("DiagnosticError", { text = "●", texthl = "DiagnosticError" })
vim.fn.sign_define("DiagnosticWarn", { text = "▲", texthl = "DiagnosticWarn" })
vim.fn.sign_define("DiagnosticHint", { text = "󰌵", texthl = "DiagnosticHint" })
vim.fn.sign_define("DiagnosticInfo", { text = "󰋽", texthl = "DiagnosticInfo" })
