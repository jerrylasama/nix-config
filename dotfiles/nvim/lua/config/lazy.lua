local ok, lazy = pcall(require, "lazy")
if not ok then
  return
end

lazy.setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    { import = "plugins" },
  },
  defaults = {
    lazy = true,
    version = false,
  },
  install = {
    missing = false,
    colorscheme = { "tokyonight", "habamax" },
  },
  checker = { enabled = false },
  change_detection = { notify = false },
})
