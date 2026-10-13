local M = {}

local jobs = {}
local output = {}
local log_buffers = {}
local generation = {}
local namespace = vim.api.nvim_create_namespace("compile")

M.results = {}

local severity = { E = vim.diagnostic.severity.ERROR, W = vim.diagnostic.severity.WARN }

local function show_diagnostics(items, source)
  vim.diagnostic.reset(namespace)
  local grouped = {}
  for _, item in ipairs(items) do
    local target = vim.fn.bufnr(item.filename)
    if target <= 0 or not vim.api.nvim_buf_is_loaded(target) then
      goto continue
    end
    local diagnostics = grouped[target]
    if not diagnostics then
      diagnostics = {}
      grouped[target] = diagnostics
    end
    table.insert(diagnostics, {
      lnum = math.max(item.lnum, 1),
      col = math.max(item.col or 1, 1),
      message = item.text,
      severity = severity[item.type] or vim.diagnostic.severity.ERROR,
      source = source,
    })
    ::continue::
  end
  for target, diagnostics in pairs(grouped) do
    vim.diagnostic.set(namespace, target, diagnostics, { severity_sort = true })
  end
end

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Compile" })
end

local function has(bin)
  return vim.fn.executable(bin) == 1
end

local function odin_root()
  if vim.env.ODIN_ROOT and vim.uv.fs_stat(vim.env.ODIN_ROOT) then
    return vim.env.ODIN_ROOT
  end
  for _, guess in ipairs({
    vim.fs.joinpath(vim.uv.os_homedir(), "Builds", "Odin"),
    vim.fs.joinpath(vim.uv.os_homedir(), ".odin"),
    "/usr/local",
    "/usr",
  }) do
    if vim.uv.fs_stat(vim.fs.joinpath(guess, "core")) then
      vim.env.ODIN_ROOT = guess
      return guess
    end
  end
end

local function parent_with(dir, name)
  local current = dir
  while current and current ~= "" do
    if vim.uv.fs_stat(vim.fs.joinpath(current, name)) then
      return current
    end
    local up = vim.fs.dirname(current)
    if up == current then
      return nil
    end
    current = up
  end
end

local function abs_path(buf)
  local file = vim.api.nvim_buf_get_name(buf)
  if file == "" then
    return nil
  end
  return vim.fs.normalize(vim.fn.fnamemodify(file, ":p"))
end

local function resolve(path, cwd)
  local absolute = path:sub(1, 1) == "/" or path:match("^%a:[/\\]") ~= nil
  if absolute then
    return vim.fs.normalize(path)
  end
  return vim.fs.normalize(vim.fs.joinpath(cwd, (path:gsub("^%./", ""))))
end

local function lines_of(str)
  local lines = {}
  for line in str:gmatch("[^\n]+") do
    table.insert(lines, line)
  end
  return lines
end

local parsers = {}

parsers.rust = function(lines, cwd)
  local items = {}
  local message
  for _, line in ipairs(lines) do
    local head, code = line:match("^(%a+)%[([^%]]*)%]:%s*(.+)$")
    if head and (head == "error" or head == "warning") then
      message = code
    end
    local file, lnum, col, kind, text =
      line:match("^(.-):(%d+):(%d+):%s+(%a+)%[([^%]]*)%]:%s*(.+)$")
    if not file then
      file, lnum, col, kind, text = line:match("^(.-):(%d+):(%d+):%s+(%a+):%s*(.+)$")
    end
    if not file then
      file, lnum, col = line:match("^%s*%-%->%s*(.-):(%d+):(%d+)")
    end
    if file then
      table.insert(items, {
        filename = resolve(file, cwd),
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = text or message or kind or "error",
        type = (kind or head) == "warning" and "W" or "E",
      })
    end
    if not file then
      local plain = line:match("^(%a+):%s*(.+)$")
      if plain and (plain == "error" or plain == "warning") then
        message = plain
      end
    end
  end
  return items
end

parsers.typst = function(lines, cwd)
  local items = {}
  local kind, message
  for _, line in ipairs(lines) do
    local matched, text = line:match("^(%a+):%s+(.+)$")
    if matched == "error" or matched == "warning" then
      kind, message = matched, text
    end
    local file, lnum, col = line:match("([^%s:]+):(%d+):(%d+)%s*$")
    if file then
      table.insert(items, {
        filename = resolve(file, cwd),
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = message or "error",
        type = kind == "warning" and "W" or "E",
      })
      kind, message = nil, nil
    end
  end
  return items
end

parsers.odin = function(lines, cwd)
  local items = {}
  for _, line in ipairs(lines) do
    local file, lnum, col, text = line:match("^(.-)%((%d+):(%d+)%)%s+(.+)$")
    if file and vim.endswith(file, ".odin") then
      local kind, rest = text:match("^(%a+):%s*(.*)$")
      table.insert(items, {
        filename = resolve(file, cwd),
        lnum = tonumber(lnum),
        col = tonumber(col),
        text = rest ~= "" and rest or text,
        type = kind == "Warning" and "W" or "E",
      })
    end
  end
  return items
end

parsers.latex = function(lines, cwd)
  local items = {}
  for _, line in ipairs(lines) do
    local file, lnum, text = line:match("^(.-%.tex):(%d+):%s+(.+)$")
    if file then
      table.insert(items, {
        filename = resolve(file, cwd),
        lnum = tonumber(lnum),
        col = 1,
        text = text,
        type = vim.startswith(text, "LaTeX Warning") and "W" or "E",
      })
    end
  end
  return items
end

local builders = {}

builders.rust = function(ctx)
  if not has("cargo") then
    return nil, "cargo not found in $PATH"
  end
  local project = parent_with(vim.fs.dirname(ctx.file), "Cargo.toml")
  if project then
    return {
      name = "cargo check",
      cmd = { "cargo", "check", "--quiet", "--color", "never", "--message-format=short" },
      cwd = project,
      parse = parsers.rust,
    }
  end
  if not has("rustc") then
    return nil, "rustc not found in $PATH"
  end
  local outdir = vim.fn.tempname()
  vim.fn.mkdir(outdir, "p")
  return {
    name = "rustc",
    cmd = {
      "rustc",
      "--edition",
      "2021",
      "--crate-type",
      "bin",
      "--emit",
      "metadata",
      "-o",
      vim.fs.joinpath(outdir, (vim.fs.basename(ctx.file):gsub("%.rs$", ".rmeta"))),
      ctx.file,
    },
    cwd = vim.fs.dirname(ctx.file),
    parse = parsers.rust,
  }
end

builders.odin = function(ctx)
  if not has("odin") then
    return nil, "odin not found in $PATH"
  end
  if not odin_root() then
    return nil, "ODIN_ROOT is not set and no Odin core library was found"
  end
  local dir = vim.fs.dirname(ctx.file)
  local is_package = vim.uv.fs_stat(vim.fs.joinpath(dir, "main.odin")) ~= nil
  local outdir = vim.fs.joinpath(dir, "build")
  vim.fn.mkdir(outdir, "p")
  local name = is_package and vim.fs.basename(dir) or (vim.fs.basename(ctx.file):gsub("%.odin$", ""))
  local cmd = { "odin", "build", is_package and dir or ctx.file, "-out:" .. vim.fs.joinpath(outdir, name) }
  if not is_package then
    table.insert(cmd, "-file")
  end
  return {
    name = "odin build",
    cmd = cmd,
    cwd = dir,
    parse = parsers.odin,
  }
end

builders.tex = function(ctx)
  if not has("latexmk") then
    return nil, "latexmk not found in $PATH"
  end
  return {
    name = "latexmk",
    cmd = {
      "latexmk",
      "-pdf",
      "-interaction=nonstopmode",
      "-halt-on-error",
      "-file-line-error",
      "-synctex=1",
      ctx.file,
    },
    cwd = vim.fs.dirname(ctx.file),
    log = (ctx.file:gsub("%.[^.]+$", ".log")),
    parse = parsers.latex,
  }
end

builders.typst = function(ctx)
  if not has("typst") then
    return nil, "typst not found in $PATH"
  end
  return {
    name = "typst compile",
    cmd = { "typst", "compile", "--root", vim.fs.dirname(ctx.file), ctx.file },
    cwd = vim.fs.dirname(ctx.file),
    parse = parsers.typst,
  }
end

M.target_for = function(ft)
  return ({ rust = "rust", odin = "odin", tex = "tex", plaintex = "tex", typst = "typst" })[ft]
end

M.pdf_for = function(buf)
  local file = abs_path(buf or 0)
  if not file then
    return nil
  end
  return vim.fs.normalize((file:gsub("%.[^.]+$", ".pdf")))
end

local viewers = { "sioyek", "xdg-open" }

local function viewer()
  for _, candidate in ipairs(viewers) do
    if has(candidate) then
      return candidate
    end
  end
end

M.open_pdf = function(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local pdf = M.pdf_for(buf)
  local program = viewer()
  if not pdf or not vim.uv.fs_stat(pdf) then
    notify("no PDF next to the source file", vim.log.levels.WARN)
    return
  end
  if not program then
    notify("no PDF viewer found (looked for " .. table.concat(viewers, ", ") .. ")", vim.log.levels.WARN)
    return
  end
  vim.fn.jobstart({ program, pdf }, { detach = true })
end

M.forward_search = function(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if M.target_for(vim.bo[buf].filetype) ~= "tex" then
    notify("forward search needs a LaTeX document compiled with synctex", vim.log.levels.WARN)
    return
  end
  local file = abs_path(buf)
  local pdf = M.pdf_for(buf)
  if not (file and pdf and vim.uv.fs_stat(pdf)) then
    notify("no PDF next to the source file", vim.log.levels.WARN)
    return
  end
  if not has("sioyek") then
    notify("sioyek not found in $PATH", vim.log.levels.WARN)
    return
  end
  vim.fn.jobstart({
    "sioyek",
    "--nofocus",
    "--forward-search-file",
    file,
    "--forward-search-line",
    tostring(vim.fn.line(".")),
    "--forward-search-column",
    tostring(vim.fn.col(".")),
    pdf,
  }, { detach = true })
end

M.open_log = function(target)
  target = target or M.target_for(vim.bo.filetype)
  if not target then
    return
  end
  local bufnr = log_buffers[target]
  if not (bufnr and vim.api.nvim_buf_is_valid(bufnr)) then
    bufnr = vim.api.nvim_create_buf(false, true)
    vim.bo[bufnr].buftype = "nofile"
    vim.bo[bufnr].swapfile = false
    vim.bo[bufnr].filetype = "log"
    log_buffers[target] = bufnr
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines_of(output[target] or ""))
  vim.api.nvim_set_current_buf(bufnr)
end

M.build = function(target, buf)
  buf = buf or vim.api.nvim_get_current_buf()
  target = target or M.target_for(vim.bo[buf].filetype)
  if not target then
    return
  end

  local file = abs_path(buf)
  if not file then
    return
  end

  local job, err = builders[target]({ file = file, buf = buf })
  if not job then
    notify(err, vim.log.levels.ERROR)
    return
  end

  if jobs[target] then
    jobs[target]:kill(15)
  end

  generation[target] = (generation[target] or 0) + 1
  local current = generation[target]
  M.results[target] = nil
  output[target] = ""

  local collect = function(_, data)
    if data then
      output[target] = output[target] .. data
    end
  end

  jobs[target] = vim.system(job.cmd, {
    cwd = job.cwd,
    text = true,
    stdout = collect,
    stderr = collect,
  }, function(result)
    jobs[target] = nil
    vim.schedule(function()
      if generation[target] ~= current then
        return
      end
      local items = job.parse(lines_of(output[target]), job.cwd)
      if #items == 0 and result.code ~= 0 and job.log and vim.uv.fs_stat(job.log) then
        local handle = io.open(job.log, "r")
        if handle then
          items = job.parse(lines_of(handle:read("*a")), job.cwd)
          handle:close()
        end
      end
      vim.fn.setqflist({}, "r", { title = job.name, items = items })
      show_diagnostics(items, job.name)
      if result.code == 0 then
        vim.api.nvim_echo({ { string.format(" %s: ok", job.name), "Comment" } }, false, {})
      else
        local first = items[1] and items[1].text or string.format("exit %d", result.code)
        notify(string.format("%s: %s", job.name, first), vim.log.levels.ERROR)
      end
      M.results[target] = { code = result.code, items = items, name = job.name }
    end)
  end)
end

return M
