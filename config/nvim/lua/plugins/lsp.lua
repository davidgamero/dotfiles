return {
  -- configure nvim-lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- HTML/CSS
        html = {},
        cssls = {},

        -- Go
        gopls = {},

        -- TypeScript
        ts_ls = {},
      },
    },
  },
}