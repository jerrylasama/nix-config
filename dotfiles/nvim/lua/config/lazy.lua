local ok, lazy = pcall(require, "lazy")
if not ok then
  return
end

local lockfile = vim.fn.stdpath("state") .. "/lazy-lock.json"
local config_lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"

-- Home Manager deploys the config directory read-only. Seed a writable lockfile
-- once, then let Lazy update the copy in Neovim's state directory.
if vim.fn.filereadable(lockfile) == 0 and vim.fn.filereadable(config_lockfile) == 1 then
  vim.fn.mkdir(vim.fn.fnamemodify(lockfile, ":h"), "p")
  vim.fn.writefile(vim.fn.readfile(config_lockfile), lockfile)
end

lazy.setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
  lockfile = lockfile,
  defaults = {
    lazy = true,
    version = false,
  },
  install = {
    missing = true,
    colorscheme = { "tokyonight", "habamax" },
  },
  checker = { enabled = false },
  change_detection = { notify = false },
})
