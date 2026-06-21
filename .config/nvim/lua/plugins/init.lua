return {
  -- Emmet
  {
    "mattn/emmet-vim",
    ft = { "html", "css", "javascript", "javascriptreact", "typescriptreact", "vue", "svelte" }
  },

  -- Surround
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    config = function()
      require("nvim-surround").setup()
    end
  },

  -- Commentary → Comment.nvim
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    config = function()
      require("Comment").setup()
    end
  },

  -- CSS Colors
  {
    "NvChad/nvim-colorizer.lua",
    event = "BufReadPre",
    config = function()
      require("colorizer").setup({
        user_default_options = {
          css = true,
          tailwind = true,
        }
      })
    end
  },

  -- Colorschemes
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme tokyonight]])
    end
  },
  "rafi/awesome-vim-colorschemes",

  -- Dev Icons
  "nvim-tree/nvim-web-devicons",

  -- Multiple Cursors → vim-visual-multi
  {
    "mg979/vim-visual-multi",
    branch = "master",
    event = "VeryLazy",
  },

  -- Tagbar → Aerial
  {
    "stevearc/aerial.nvim",
    keys = {
      { "<F8>", "<cmd>AerialToggle<cr>", desc = "Toggle Aerial" },
    },
    config = function()
      require("aerial").setup({
        on_attach = function(bufnr)
          vim.keymap.set("n", "{", "<cmd>AerialPrev<CR>", { buffer = bufnr })
          vim.keymap.set("n", "}", "<cmd>AerialNext<CR>", { buffer = bufnr })
        end,
      })
    end,
  },

  -- Markdown
  {
    "preservim/vim-markdown",
    ft = "markdown",
  },

  -- VimWiki
  {
    "vimwiki/vimwiki",
    keys = {
      { "<leader>ww", desc = "Open VimWiki" },
    },
  },

  -- LaTeX
  {
    "lervag/vimtex",
    ft = "tex",
    config = function()
      vim.g.vimtex_view_method = 'zathura'
      vim.g.vimtex_compiler_method = 'latexmk'
    end,
  },

  -- Markview
  {
    "OXY2DEV/markview.nvim",
    ft = "markdown",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons"
    },
  },
}
