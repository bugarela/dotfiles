{ config, pkgs, lib, ... }:

let
  unstable = import <nixpkgs-unstable> {
    config.allowUnfree = true;
    overlays = [
      (self: super: {
        discord = super.discord.overrideAttrs (_: {
          src = builtins.fetchTarball
            "https://discord.com/api/download?platform=linux&format=tar.gz";
        });
      })
    ];
  };
  mypolybar = (pkgs.polybar.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs
      ++ [ pkgs.python38Packages.sphinx ];
    src = pkgs.fetchFromGitHub {
      owner = old.pname;
      repo = old.pname;
      rev = "10bbec44515d2479c0dd606ae48a2e0721ad94c0";
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
  gh-md-toc = pkgs.writeScriptBin "gh-md-toc"
    "curl https://raw.githubusercontent.com/ekalinin/github-markdown-toc/master/gh-md-toc -o gh-md-toc && chmod a+x gh-md-toc";
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.stateVersion = "23.05";

  imports = [
    "${
      fetchTarball
      "https://github.com/msteen/nixos-vscode-server/tarball/master"
    }/modules/vscode-server/home.nix"
    ./programs/xmonad/default.nix
    ./programs/vscode/vscode.nix
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

  nixpkgs.config.allowUnfree = true;

  home.packages = [
    pkgs.ripgrep
    pkgs.bat
    pkgs.jq
    pkgs.autorandr
    pkgs.tree
    pkgs.rnix-lsp
    pkgs.libgccjit
    pkgs.xorg.xwininfo
    pkgs.xmobar
    pkgs.xdotool
    pkgs.lxrandr
    pkgs.pscircle
    pkgs.gpicview
    pkgs.neofetch
    pkgs.lxappearance
    pkgs.evince
    pkgs.gimp
    pkgs.killall
    pkgs.fzf
    pkgs.arandr
    pkgs.stdenv
    pkgs.zip
    pkgs.unzip
    pkgs.p7zip
    pkgs.libnotify
    pkgs.direnv

    pkgs.graphviz
    pkgs.gtk3

    pkgs.inxi
    pkgs.pciutils
    pkgs.glxinfo
    pkgs.lm_sensors

    (pkgs.aspellWithDicts (d: [ d.en d.pt_BR ]))
    pkgs.languagetool

    pkgs.networkmanagerapplet

    pkgs.spotify
    pkgs.obsidian

    unstable.vivaldi
    unstable.vivaldi-ffmpeg-codecs
    pkgs.google-chrome

    unstable.tdesktop
    unstable.discord
    pkgs.slack
    pkgs.zulip

    pkgs.flameshot
    pkgs.peek

    pkgs.copyq
    pkgs.libqalculate

    pkgs.sqlite
    # pkgs.texlive.combined.scheme-full
    pkgs.nitrogen
    pkgs.nix-prefetch-git

    pkgs.pass
    pkgs.pinentry
    pkgs.gh

    # pkgs.steam
    # pkgs.lutris
    # pkgs.tuxguitar

    pkgs.megasync
    pkgs.obs-studio
    pkgs.okular
    pkgs.vlc
    pkgs.mpv
    pkgs.ffmpeg
    # video editor
    pkgs.openshot-qt

    pkgs.zoom-us

    pkgs.pandoc
    pkgs.nixfmt
    pkgs.nixpkgs-fmt

    pkgs.libsecret

    pkgs.ledger-live-desktop

    pkgs.pulseeffects-legacy

    # Required by emacs copilot
    pkgs.nodejs-18_x
  ];

  programs.emacs = {
    enable = true;
    package = pkgs.emacs29;
  };

  xdg.mimeApps = {
    enable = true;

    associations.added = { };
    defaultApplications = {
      "text/html" = [ "vivaldi-stable.desktop" ];
      "x-scheme-handler/http" = [ "vivaldi-stable.desktop" ];
      "x-scheme-handler/https" = [ "vivaldi-stable.desktop" ];
      "x-scheme-handler/about" = [ "vivaldi-stable.desktop" ];
      "x-scheme-handler/unknown" = [ "vivaldi-stable.desktop" ];
      "video/mp4" = [ "mpv.desktop" "userapp-vlc-HA5N50.desktop" ];
      "x-scheme-handler/tg" = [ "userapp-Telegram Desktop-E8SX01.desktop" ];
      "image/png" = [ "vivaldi-stable.desktop" ];
      "application/pdf" = [ "okularApplication_pdf.desktop" ];
      "vscode-insiders" = [ "code-insiders.desktop" ];
    };
  };

  programs.git = {
    enable = true;
    userName = "bugarela";
    userEmail = "gabrielamoreira05@gmail.com";
    extraConfig = ''
      [gpg]
        format = ssh
      [gpg "ssh"]
        program = /nix/store/6dhl47wrxgiz94ilrs86iwcxhhgw46qc-1password-8.10.9/bin/op-ssh-sign
    '';
    signing = {
      key =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK9j0vEeUJi5vv++eeMOWkIYjGy8ED7s3M4FHY7YOzXH";
      signByDefault = true;
    };
    delta.enable = true;
  };

  programs.fish = {
    enable = true;
    shellInit = builtins.readFile ./programs/fish/config.fish;
    plugins = [
      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
      {
        name = "colored-man-pages";
        src = pkgs.fishPlugins.colored-man-pages.src;
      }
      {
        name = "done";
        src = pkgs.fishPlugins.done.src;
      }
      {
        name = "fzf";
        src = pkgs.fishPlugins.fzf.src;
      }
      {
        name = "sponge";
        src = pkgs.fishPlugins.sponge.src;
      }
    ];
  };

  programs.bash = {
    enable = true;
    shellAliases = { ls = "ls --color=auto"; };
  };

  programs.neovim = {
    enable = true;
    vimAlias = true;
    extraConfig = builtins.readFile ./programs/vim/extraConfig.vim;
    extraLuaConfig = builtins.readFile ./programs/vim/extraLuaConfig.lua;

    plugins = with pkgs.vimPlugins; [
      # Syntax / Language Support ##########################
      vim-nix
      zig-vim
      nvim-treesitter

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
          x = 20;
          y = 20;
        };
        # opacity = 0.9;
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

      # Colors (Alabaster Dark)
      colors = {
        primary = {
          background = "0x0E1415";
          foreground = "0xCECECE";
        };
        cursor = {
          text = "0x0E1415";
          cursor = "0xCECECE";
        };
        normal = {
          black = "0x0E1415";
          red = "0xe25d56";
          green = "0x73ca50";
          yellow = "0xe9bf57";
          blue = "0x4a88e4";
          magenta = "0x915caf";
          cyan = "0x23acdd";
          white = "0xf0f0f0";
        };
        bright = {
          black = "0x777777";
          red = "0xf36868";
          green = "0x88db3f";
          yellow = "0xf0bf7a";
          blue = "0x6f8fdb";
          magenta = "0xe987e9";
          cyan = "0x4ac9e2";
          white = "0xFFFFFF";
        };
      };

      # white
      # colors = {
      #   # Default colors
      #   primary = {
      #     background = "0xdbd6d1";
      #     foreground = "0x433b32";
      #   };

      #   # Normal colors
      #   normal = {
      #     black = "0x16130f";
      #     red = "0x826d57";
      #     green = "0x57826d";
      #     yellow = "0x6d8257";
      #     blue = "0x6d5782";
      #     magenta = "0x82576d";
      #     cyan = "0x576d82";
      #     white = "0xa39a90";
      #   };

      #   # Bright colors
      #   bright = {
      #     black = "0x5a5047";
      #     red = "0x826d57";
      #     green = "0x57826d";
      #     yellow = "0x6d8257";
      #     blue = "0x6d5782";
      #     magenta = "0x82576d";
      #     cyan = "0x576d82";
      #     white = "0xdbd6d1";
      #   };
      # };

      # colors = {
      #   primary = {
      #     background = "0x000000";
      #     foreground = "0xffffff";
      #   };

      #   cursor = {
      #     background = "0xFFFFFF";
      #     foreground = "0x222222";
      #   };

      #   vi_mode_cursor = {
      #     background = "0xFFFFFF";
      #     foreground = "0xbbc2cf";
      #   };

      #   selection= {
      #     text = "0x000000";
      #     background = "0x44475a";
      #   };

      #   normal = {
      #     black   = "0x757575";
      #     red     = "0xff5f5f";
      #     green   = "0xde8a36";
      #     yellow  = "0xd78787";
      #     blue    = "0xaf5fd7";
      #     magenta = "0xff87d7";
      #     cyan    = "0xdea3e5";
      #     white   = "0xb8b8b8";
      #   };

      #   bright = {
      #     black   = "0xb8b8b8";
      #     red     = "0xd78787";
      #     green   = "0xff9f6f";
      #     yellow  = "0xff5f5f";
      #     blue    = "0xdea3e5";
      #     magenta = "0xd7afaf";
      #     cyan    = "0xaf5fd7";
      #     white   = "0x757575";
      #   };
      # };
    };
  };

  programs.autorandr.enable = true;

  programs.rofi = {
    enable = true;
    terminal = "${pkgs.alacritty}/bin/alacritty";
    theme = ./programs/rofi/theme.slate;
    cycle = true;
  };

  programs.rofi.pass = { enable = true; };

  # services.picom = {
  #   # package = picom-fork;
  #   enable = false;
  #   experimentalBackends = true;
  #   backend = "glx";
  #   # blur = true;
  #   shadow = true;
  #   # activeOpacity = 0.95;
  #   # inactiveOpacity = "0.95";
  #   shadowOpacity = "0.65";
  #   extraOptions = ''
  #     corner-radius = 10;
  #     blur:
  #     {
  #       method = "dual_kawase";
  #     };
  #   '';
  # };

  gtk = {
    enable = true;
    theme = {
      name = "Sweet-Dark";
      package = pkgs.sweet;
    };
    iconTheme = {
      name = "Qogir-ubuntu-dark";
      package = pkgs.qogir-icon-theme;
    };
  };

  home.pointerCursor = {
    package = pkgs.qogir-icon-theme;
    name = "Qogir-dark";
    size = 28;
    x11.enable = true;
  };

  # Autoload nix shells
  # services.lorri.enable = true;

  services.polybar = {
    enable = true;
    config = ./programs/polybar/config.ini;
    script = "";
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
