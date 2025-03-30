{ config, pkgs, lib, ... }:

let
  fromGitHub = ref: repo:
    pkgs.vimUtils.buildVimPlugin {
      pname = "${lib.strings.sanitizeDerivationName repo}";
      version = ref;
      src = builtins.fetchGit {
        url = "https://github.com/${repo}.git";
        ref = ref;
      };
    };
in {
  programs.neovim = {
    enable = true;
    vimAlias = true;
    extraLuaConfig = builtins.readFile ./programs/vim/extraLuaConfig.lua;
    extraConfig = ''
      autocmd FileType quint lua vim.treesitter.start()
      autocmd FileType quint lua vim.lsp.start({name = 'quint', cmd = {'quint-language-server', '--stdio'}, root_dir = vim.fs.dirname()})
      au BufRead,BufNewFile *.qnt  setfiletype quint

      let g:tlaplus_mappings_enable = 1
    '';

    plugins = with pkgs.vimPlugins; [
      # Syntax / Language Support ##########################
      vim-nix
      zig-vim
      nvim-lspconfig

      # UI #################################################
      nord-vim # colorscheme
      vim-gitgutter # status in gutter
      # vim-devicons
      vim-airline

      # Editor Features ####################################
      vim-surround # cs"'
      vim-repeat # cs"'...
      vim-commentary # gcap
      # vim-ripgrep
      vim-indent-object # >aI
      vim-easy-align # vipga
      vim-eunuch # :Rename foo.rb
      vim-sneak
      supertab
      ale # linting
      nerdtree
      neosnippet-snippets

      # Buffer / Pane / File Management ####################
      fzf-vim # all the things

      # Panes / Larger features ############################
      tagbar # <leader>5
      vim-fugitive # Gblame

      copilot-vim
      (nvim-treesitter.withPlugins (_:
        nvim-treesitter.allGrammars ++ [
          (pkgs.tree-sitter.buildGrammar {
            language = "quint";
            version = "7c51ff7";
            src = ./programs/tree-sitter-quint;
          })
        ]))
      (fromGitHub "HEAD" "tlaplus-community/tlaplus-nvim-plugin")
    ];
  };
}
