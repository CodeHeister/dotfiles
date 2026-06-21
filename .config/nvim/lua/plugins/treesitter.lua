return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    require('nvim-treesitter').setup {
      ensure_installed = { "c", "lua", "vim", "vimdoc", "query", "just", "bash", "aws", "ini", "glsl", "asm", "dockerfile", "cmake", "cpp", "csv", "cuda", "css", "desktop", "editorconfig", "gpg", "http", "html", "ini", "kitty", "latex", "make", "nginx", "objdump", "nix", "proto", "python", "sql", "tmux", "typescript", "yaml", "zathurarc", "xml", "zsh" },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
    }
  end
}
