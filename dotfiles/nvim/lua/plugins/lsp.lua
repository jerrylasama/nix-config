return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nixd = {},
        clangd = {},
        gopls = {},
        rust_analyzer = {},
        vtsls = {},
        jdtls = {},
        kotlin_language_server = {},
        basedpyright = {},
        perlnavigator = {},
        csharp_ls = {},
      },
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        nix = { "nixfmt" },
        lua = { "stylua" },
        python = { "ruff_format" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        go = { "gofmt" },
        rust = { "rustfmt" },
      },
    },
  },
}
