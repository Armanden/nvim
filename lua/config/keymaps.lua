local map = vim.keymap.set

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Write buffer" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
map("n", "<leader>W", "<cmd>write | quit<cr>", { desc = "Write and quit" })

map("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })
map("n", "<leader>tn", "<cmd>tabnew<cr>", { desc = "New tab" })
map("n", "<leader>tc", "<cmd>tabclose<cr>", { desc = "Close tab" })
map("n", "<leader>tt", "<cmd>tabnext<cr>", { desc = "Next tab" })
map("n", "<leader>tp", "<cmd>tabprevious<cr>", { desc = "Previous tab" })

map("n", "<C-h>", "<C-w>h", { desc = "Win left" })
map("n", "<C-j>", "<C-w>j", { desc = "Win down" })
map("n", "<C-k>", "<C-w>k", { desc = "Win up" })
map("n", "<C-l>", "<C-w>l", { desc = "Win right" })

map("v", "<", "<gv", { desc = "Outdent and keep selection" })
map("v", ">", ">gv", { desc = "Indent and keep selection" })

map("n", "[q", "]q", { desc = "Cycle quickfix list" })
map("n", "<leader>qn", "<cmd>copen<cr>", { desc = "Open quickfix" })
map("n", "<leader>qc", "<cmd>cclose<cr>", { desc = "Close quickfix" })

map("n", "<leader>c", function() require("config.compile").build() end, { desc = "Compile file" })
map("n", "<leader>cr", function() require("config.compile").build("rust") end, { desc = "Compile rust" })
map("n", "<leader>co", function() require("config.compile").build("odin") end, { desc = "Compile odin" })
map("n", "<leader>ct", function() require("config.compile").build("tex") end, { desc = "Compile latex" })
map("n", "<leader>cy", function() require("config.compile").build("typst") end, { desc = "Compile typst" })
map("n", "<leader>cp", function() require("config.compile").open_pdf() end, { desc = "Open PDF in sioyek" })
map("n", "<leader>cf", function() require("config.compile").forward_search() end, { desc = "Forward search PDF (synctex)" })
map("n", "<leader>cl", function() require("config.compile").open_log() end, { desc = "Open compiler output" })

map("n", "<leader>d", vim.diagnostic.open_float, { desc = "Diagnostics float" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev diagnostic" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
