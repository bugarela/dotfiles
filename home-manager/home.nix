{ config, pkgs, lib, ... }:

let
  picom-fork = pkgs.picom.overrideAttrs (old: {
    src = pkgs.fetchFromGitHub {
      owner = "ibhagwan";
      repo = "picom";
      rev    = "44b4970f70d6b23759a61a2b94d9bfb4351b41b1";
      sha256 = "0iff4bwpc00xbjad0m000midslgx12aihs33mdvfckr75r114ylh";
    };
  });
  unstable = import <nixpkgs-unstable> { config.allowUnfree = true; overlays = [(self: super: { discord = super.discord.overrideAttrs (_: { src = builtins.fetchTarball "https://discord.com/api/download?platform=linux&format=tar.gz"; });})];};
  emacs-overlay = builtins.fetchTarball "https://github.com/nix-community/emacs-overlay/archive/15ed1f372a83ec748ac824bdc5b573039c18b82f.tar.gz";
  omf =  builtins.fetchTarball {
    url = "https://github.com/oh-my-fish/oh-my-fish/archive/refs/tags/v7.tar.gz";
  };
  emacsPkgs = import <nixpkgs> { overlays = [ (import emacs-overlay) ]; };
  mypolybar = (pkgs.polybar.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [
      pkgs.python38Packages.sphinx
    ];
    src = pkgs.fetchFromGitHub {
      owner = old.pname;
      repo = old.pname;
      rev    = "10bbec44515d2479c0dd606ae48a2e0721ad94c0";
      sha256 = "0kzv6crszs0yx70v0n89jvv40155chraw3scqdybibk4n1pmbkzn";
      fetchSubmodules = true;
    };
  })).override {
    i3Support = false;
    i3GapsSupport = false;
    alsaSupport = true;
    iwSupport = false;
    githubSupport = true;
    mpdSupport = true;
    nlSupport = true;
    pulseSupport = false;
  };
  gh-md-toc = pkgs.writeScriptBin "gh-md-toc" "curl https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc -o gh-md-toc && chmod a+x gh-md-toc"
;
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.stateVersion = "21.03";

  imports = [
    ./programs/xmonad/default.nix
  ];

  home.username = "gabriela";
  home.homeDirectory = "/home/gabriela";

  home.sessionVariables = {
    PAGER = "less";
    EDITOR = "vim";
    DOOMDIR = "$HOME/nix-configs/doom.d";
    EMACSDIR = "$HOME/.emacs.d";
    DOOMLOCALDIR = "$HOME/.doom_local";
    DIRENV_ALLOW_NIX = 1;
  };

  home.file.".rd-docker-installer" = {
    source =  builtins.fetchGit {
      url = "ssh://git@github.com/ResultadosDigitais/rd-docker.git";
      rev = "cf1aeca3e9a5588d26360f3bb2618977cdceb247";
    };
    onChange =  "${pkgs.writeShellScript "rd-docker-change" ''
      cd ~/.rd-docker-installer
      cp rd-docker-install /tmp/rd-docker-install
      sed 's/sudo ln/# sudo ln/' -i /tmp/rd-docker-install
      cat /tmp/rd-docker-install | bash
    ''}";
  };

  home.file.".doom.d" = {
    source = builtins.toPath "/home/gabriela/nix-configs/doom.d";
    onChange = "${pkgs.writeShellScript "doom-change" ''
      EMACSDIR=/home/gabriela/.emacs.d
      DOOMBIN="$EMACSDIR"/bin/doom
      DOOMLOCALDIR=/home/gabriela/.doom_local
      mkdir -p "$DOOMLOCALDIR"
      mkdir -p /home/gabriela/org/roam
      if [ ! -f "$DOOMBIN" ]; then
        echo "-------------> Installing DOOM EMACS"
        mv "$EMACSDIR" "$EMACSDIR".bk
        git clone --depth 1 https://github.com/hlissner/doom-emacs.git "$EMACSDIR"
        "$DOOMBIN" -y install
      else
        echo "-------------> Syncing DOOM EMACS"
        "$DOOMBIN" -y sync
      fi
    ''}";
  };

  home.file.".google-cloud-sdk-installer.tar.gz" = {
    source =  pkgs.fetchurl {
      url = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-350.0.0-linux-x86_64.tar.gz";
      sha256 =  "1vlcwab68d8rpzkjcwj83qn35bq0awsl15p35x5qpsymmvf046l6";
    };
    onChange =  "${pkgs.writeShellScript "google-cloud-sdk-change" ''
      tar xf ~/.google-cloud-sdk-installer.tar.gz
      ~/google-cloud-sdk/bin/gcloud components install cbt
    ''}";
  };

  nixpkgs.config.allowUnfree = true;

  home.packages = [
    pkgs.ripgrep
    pkgs.jq
    pkgs.autorandr
    pkgs.tree
    pkgs.rnix-lsp
    pkgs.lazydocker
    pkgs.libgccjit
    pkgs.xorg.xwininfo
    pkgs.xmobar
    pkgs.xdotool
    pkgs.lxrandr
    pkgs.pscircle
    pkgs.gpicview
    pkgs.feh
    pkgs.neofetch
    pkgs.lxappearance
    pkgs.evince
    pkgs.gimp
    pkgs.inxi
    pkgs.pciutils
    pkgs.glxinfo
    pkgs.lm_sensors
    (pkgs.aspellWithDicts (d: [d.en d.pt_BR]))
    pkgs.languagetool

    pkgs.networkmanagerapplet

    pkgs.qbittorrent
    pkgs.spotify
    pkgs.pcmanfm
    unstable.vivaldi
    pkgs.synergy
    pkgs.tdesktop
    unstable.discord
    pkgs.slack
    pkgs.flameshot
    pkgs.copyq

    # emacsPkgs.emacsGcc
    pkgs.emacs

    pkgs.tlaplus
    pkgs.tlaplusToolbox

    pkgs.megasync
    pkgs.sqlite
    pkgs.texlive.combined.scheme-full
    pkgs.nitrogen
    pkgs.killall
    omf
    pkgs.fzf
    pkgs.nix-prefetch-git
    pkgs.arandr
    pkgs.pass
    pkgs.openfortivpn
    pkgs.pinentry
    pkgs.libnotify

    pkgs.valgrind
    pkgs.irony-server
    pkgs.stdenv
    pkgs.zip
    pkgs.unzip
    pkgs.steam
    pkgs.steam-tui
    pkgs.lutris
    pkgs.obs-studio
    pkgs.okular
    pkgs.vlc
    pkgs.mpv
    pkgs.zoom-us
    pkgs.teams

    pkgs.xf86_input_wacom

    pkgs.kubectl
    pkgs.k9s

    pkgs.mu
    pkgs.isync

    pkgs.graphviz
    pkgs.tuxguitar
    pkgs.gtk3
    pkgs.direnv

    pkgs.insomnia
    pkgs.pandoc
    pkgs.pgformatter

    pkgs.python3
  ];

  programs.git = {
    enable = true;
    userName = "gabrielamafra";
    userEmail = "gabrielamoreiramafra@gmail.com";
    signing = {
      key = "19A375EC9AEB17EA";
      signByDefault = true;
    };
    delta.enable = true;
  };

  programs.fish = {
    enable = true;
    shellInit = builtins.readFile ./programs/fish/config.fish;
    plugins = [
      {
        name = "fzf";
        src = pkgs.fetchFromGitHub {
          owner = "jethrokuan";
          repo = "fzf";
          rev = "ac01d96fc6344ebeb48c03f2c9c0be5bf3b20f1c";
          sha256 = "1h97zh3ghcvvn2x9rj51frhhi85nf7wa072g9mm2pc6sg71ijw4k";
        };
      }
      {
        name = "plugin-git";
        src = pkgs.fetchFromGitHub {
          owner = "jhillyerd";
          repo = "plugin-git";
          rev = "e8da507732c8e2aa0bd6487cea800f7e3ab4bb3b";
          sha256 = "0z36z1chiyv2m0iwa90brz6bf7wlvsibq1y3ldmsiqb8gqh80nrj";
        };
      }

    ];

      # sessionVariables = rec {
      #   EDITOR = "vim";
      #   VISUAL = EDITOR;
      #   GIT_EDITOR = EDITOR;
      #   DOOMLOCALDIR = "$HOME/.doom_local";
      #   DOOMDIR = "$HOME/nix-configs/doom.d";
      #   DIRENV_ALLOW_NIX = 1;
      # };
    };

    programs.bash = {
      enable = true;
      shellAliases = {
        ls = "ls --color=auto";
        rd-docker= "~/.rd-docker/rd-docker-cli";
      };
    };

    programs.neovim = {
      enable = true;
      vimAlias = true;
      extraConfig = builtins.readFile ./programs/vim/extraConfig.vim;

      plugins = with pkgs.vimPlugins; [
        # Syntax / Language Support ##########################
        vim-nix
        vim-ruby # ruby
        vim-go # go
        # vim-fish # fish
        # vim-toml           # toml
        # vim-gvpr           # gvpr
        # rust-vim # rust
        zig-vim
        vim-pandoc # pandoc (1/2)
        vim-pandoc-syntax # pandoc (2/2)
        # yajs.vim           # JS syntax
        # es.next.syntax.vim # ES7 syntax

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
      # vim-endwise        # add end, } after opening block
      # gitv
      # tabnine-vim
      ale # linting
      nerdtree
      # vim-toggle-quickfix
      # neosnippet.vim
      neosnippet-snippets
      # splitjoin.vim
      nerdtree

      # Buffer / Pane / File Management ####################
      fzf-vim # all the things

      # Panes / Larger features ############################
      tagbar # <leader>5
      vim-fugitive # Gblame
    ];
  };

  programs.alacritty = {
    enable = true;

    settings = {
      scrolling.history = 10000;
      TERM = "xterm-256color";

      window = {
        padding = {
          x = 5;
          y = 5;
        };
      };

      draw_bold_text_with_bright_colors = true;
      font = {
        normal.family = "Iosevka";
        normal.style = "Regular";
        bold.family = "Iosevka";
        bold.style = "Regular";
        italic.family = "Iosevka";
        italic.style = "Regular";
        blod_italic.family = "Iosevka";
        blod_italic.style = "Regular";
        size = 14.0;
      };

      colors = {
        primary = {
          background = "0x1d071f";
          foreground = "0xbbc2cf";
        };

        cursor = {
          background = "0xFFFFFF";
          foreground = "0x222222";
        };

        vi_mode_cursor = {
          background = "0xFFFFFF";
          foreground = "0xbbc2cf";
        };

        selection= {
          text = "0x000000";
          background = "0x44475a";
        };

        normal = {
          black   = "0x000000";
          red     = "0xff6c6b";
          green   = "0x98be65";
          yellow  = "0xecbe7b";
          blue    = "0x596889";
          magenta = "0xc678dd";
          cyan    = "0x46d9ff";
          white   = "0xdfdfdf";
        };

        bright = {
          black   = "0x3f444a";
          red     = "0xff6c6b";
          green   = "0x98be65";
          yellow  = "0xecbe7b";
          blue    = "0x51afef";
          magenta = "0xc678dd";
          cyan    = "0x46d9ff";
          white   = "0x9ca0a4";
        };
      };
    };
  };

  programs.autorandr.enable = true;

  programs.rofi = {
    enable = true;
    terminal = "${pkgs.alacritty}/bin/alacritty";
    theme = ./programs/rofi/theme.slate;
    cycle = true;
  };

  programs.rofi.pass = {
    enable = true;
  };

  services.picom = {
    enable = false;
    # experimentalBackends = true;
    # backend = "glx";
    package = picom-fork;
    blur = false;
    shadow = true;
    shadowOpacity = "0.65";
    extraOptions = ''
      corner-radius = 10;
    '';
  };

  gtk = {
    enable = true;
    theme.package = pkgs.qogir-theme;
    # theme.name = "Adwaita-dark";
    theme.name = "Qogir-dark";
    iconTheme = {
      name = "Zafiro-icons";
      package = pkgs.zafiro-icons;
    };
  };

  xsession.pointerCursor = {
    package = pkgs.qogir-icon-theme;
    name = "Qogir-dark";
    size = 28;
  };

  # Autoload nix shells
  # services.lorri.enable = true;

  services.polybar = {
    enable = true;
    package = mypolybar;
    config = ./programs/polybar/config.ini;
    script = ''
    '';
  };

  services.udiskie = {
    enable = true;
    tray = "always";
  };

  services.dunst = {
    enable = true;
    settings = {
      global = {
        font = "Iosevka Fixed SS12 10";
        geometry = "300x5-25+25";
        padding = 15;
        horizontal_padding = 15;
        monitor = 1;
        word_wrap = true;
      };
      frame = {
        background = "#111111";
        foreground = "#EEEEEE";
      };
      urgency_low = {
        background = "#111111";
        foreground = "#EEEEEE";
      };
      urgency_normal = {
        background = "#111111";
        foreground = "#EEEEEE";
      };
      urgency_critical = {
        background = "#111111";
        foreground = "#EEEEEE";
      };
    };
  };

  programs.direnv.nix-direnv.enable = true;


}
