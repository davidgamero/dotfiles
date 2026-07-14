-- lazy.nvim
return {
  "folke/snacks.nvim",
  opts = {
    explorer = {
      -- your explorer configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
    },
    picker = {
      sources = {
        explorer = {
          -- your explorer picker configuration comes here
          -- or leave it empty to use the default settings
          hidden = true,
          ignored = true,
          win = {
            list = {
              keys = {
                ["o"] = "confirm",
                ["O"] = "explorer_open", -- open with system application
              },
            },
          },
        },
      },
    },
  },
}
