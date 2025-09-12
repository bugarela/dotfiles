{ config, pkgs, lib, fetchFromGithub, ... }:

let
  bg = "#3b224c";
  bgFade = "#5A3D6E";
  fg = "#CECECE";
  black = "#281733";
  red = "#D678B5";
  green = "#7FC9AB";
  yellow = "#E3C0A8";
  blue = "#70bad1";
  magenta = "#C78DFC";
  cyan = "#23acdd";
  white = "#f0f0f0";
  orange = "#D678B5";

  pkgs2405 = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.05.tar.gz";
    sha256 = "1lr1h35prqkd1mkmzriwlpvxcb34kmhc9dnr48gkm8hh089hifmx";
  }) {
    config.allowUnfree = true;
  };

  wiremix = import ./programs/wiremix/default.nix {};
in {
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
  home.stateVersion = "23.11";

  imports = [
    ./programs/xmonad/default.nix
    ./programs/vscode/vscode.nix
    ./programs/firefox/firefox.nix
    # ./programs/vim/vim.nix
  ];

  home.username = "gabriela";
  home.homeDirectory = "/home/gabriela";

  home.sessionVariables = {
    PAGER = "less";
    DOOMDIR = "$HOME/dotfiles/doom.d";
    EMACSDIR = "$HOME/.emacs.d";
    # DOOMLOCALDIR = "$HOME/._local";
    DIRENV_ALLOW_NIX = 1;
  };

  # home.activation = {
  #   installDoomEmacs = ''
  #     if [ ! -d "$HOME/emacs" ]; then
  #       git clone --depth=0 --single-branch https://github.com/doomemacs/doomemacs "$EMACSDIR"
  #     fi
  #   '';
  # };

  home.packages = [
    wiremix

    pkgs.ripgrep
    pkgs.bat
    pkgs.jq
    pkgs.autorandr
    pkgs.tree
    pkgs.libgccjit
    pkgs.xorg.xwininfo
    pkgs.xmobar
    pkgs.xdotool
    pkgs.lxrandr
    pkgs.pscircle
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
    pkgs.pulsemixer

    pkgs.vivaldi
    pkgs.vivaldi-ffmpeg-codecs
    pkgs.google-chrome

    pkgs.tdesktop
    pkgs.discord
    pkgs.whatsapp-for-linux
    pkgs.slack
    pkgs.zulip
    pkgs.signal-desktop

    pkgs.flameshot
    pkgs.peek

    pkgs.copyq
    pkgs.libqalculate

    pkgs.sqlite
    pkgs.texlive.combined.scheme-full
    pkgs.nitrogen
    pkgs.nix-prefetch-git

    pkgs.pass
    pkgs.pinentry
    pkgs.gh

    pkgs.megacmd
    pkgs.obs-studio
    pkgs.kdePackages.okular
    pkgs.vlc
    pkgs.mpv
    pkgs.ffmpeg
    # video editor
    pkgs.openshot-qt

    pkgs.zoom-us

    pkgs.pandoc
    pkgs.nixpkgs-fmt

    pkgs.libsecret

    pkgs.ledger-live-desktop

    pkgs.pulseeffects-legacy

    # Required by emacs copilot
    pkgs.nodejs_22
    # Required by treemacs
    pkgs.python3

    pkgs.tree-sitter

    pkgs.betterlockscreen
    pkgs.headsetcontrol

    pkgs.tlaplus18
    pkgs.tlaplusToolbox

    pkgs.imagemagick
    pkgs.pdf2svg
    pkgs.mermaid-cli

    pkgs.brightnessctl
    pkgs.rustc
    pkgs.cargo

    pkgs.zed-editor
    pkgs.openai-whisper
    pkgs.claude-code

    pkgs.parallel
    pkgs.presenterm

    pkgs.element-desktop
    pkgs.element-web

    # Terminal PDF viewer
    pkgs.tdf
  ];

  programs.emacs = {
    enable = true;
  };

  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      editor = {
        cursor-shape = {
          insert = "bar";
          normal = "block";
          select = "underline";
        };
        inline-diagnostics = {
          cursor-line = "error";
        };
      };
      keys.normal = {
        space.space = "file_picker";
        space.w = ":w";
        space.q = ":q";
        esc = [ "collapse_selection" "keep_primary_selection" ];
      };
    };
    # TODO: languages
  };

  home.file.".ssh/config".text = ''
    Host *
        IdentityAgent ~/.1password/agent.sock
  '';

  home.file.".ssh/allowed_signers".text = ''
    gabrielamoreira05@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK9j0vEeUJi5vv++eeMOWkIYjGy8ED7s3M4FHY7YOzXH
  '';

  # My auth token goes in here now, so I'm setting up that manually until I figure a better way
  # home.file.".npmrc".text = ''
  #   prefix=~/.npm
  # '';

  programs.git = {
    enable = true;
    userName = "bugarela";
    userEmail = "gabrielamoreira05@gmail.com";
    signing = {
      key =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK9j0vEeUJi5vv++eeMOWkIYjGy8ED7s3M4FHY7YOzXH";
      signByDefault = true;
      format = "ssh";
      signer = "/run/current-system/sw/bin/op-ssh-sign";
    };
    delta.enable = true;
  };

  programs.jujutsu = {
    enable = true;
    package = pkgs.jujutsu;
    settings = {
      user = {
        name = "Gabriela Moreira";
        email = "gabrielamoreira05@gmail.com";
      };

      git = {
        subprocess = false;
        sign-on-push = true;
      };

      signing = {
        # behavior = "own";
        backend = "ssh";
        key =
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK9j0vEeUJi5vv++eeMOWkIYjGy8ED7s3M4FHY7YOzXH";
        backends.ssh = {
          allowed-signers = "/home/gabriela/.ssh/allowed_signers";
          program = "/run/current-system/sw/bin/op-ssh-sign";
        };
      };

      ui = {
        pager = "${pkgs.delta}/bin/delta";
        # diff-editor = "${pkgs.meld}/bin/meld";
        diff-formatter = ":git";
      };

      aliases = {
        local = ["log" "-r" "remote_bookmarks().."];
        f = ["git" "fetch"];
        push = ["git" "push" "&&" "jj" "new"];
        back = ["edit" "-r" "@-"];
      };
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./programs/fish/config.fish;
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
    ];
  };

  programs.bash = {
    enable = true;
    shellAliases = { ls = "ls --color=auto"; };
  };

  programs.alacritty = {
    enable = true;

    settings = {
      scrolling.history = 10000;

      window = {
        opacity = 1.0;
      };

      font = {
        normal.family = "Iosevka";
        normal.style = "Regular";
        bold.family = "Iosevka";
        bold.style = "Regular";
        italic.family = "Iosevka";
        italic.style = "Regular";
        size = 14.0;
      };

      colors = {
        primary = {
          background = bg;
          foreground = fg;
        };
        cursor = {
          text = "#0E1415";
          cursor = bgFade;
        };
        normal = {
          black = black;
          red = red;
          green = green;
          yellow = yellow;
          blue = blue;
          magenta = magenta;
          cyan = cyan;
          white = white;
        };
        bright = {
          black = "#777777";
          red = "#f36868";
          green = "#88db3f";
          yellow = "#f0bf7a";
          blue = "#6f8fdb";
          magenta = "#e987e9";
          cyan = "#4ac9e2";
          white = "#FFFFFF";
        };
      };
    };
  };

  programs.zellij = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      ui.pane_frames.hide_session_name = true;
      scrollback_editor = "hx";
      show_startup_tips = false;
      keybinds.shared.bind = {
        _args = [ "Alt ;" ];
        ToggleFocusFullscreen = {};
        MoveFocusOrTab = ["Right"];
      }; 
      theme = "booberry";
      themes.booberry = {
          fg = fg;
          bg = bgFade;
          black = black;
          red = red;
          green = green;
          yellow = yellow;
          blue = blue;
          magenta = magenta;
          cyan = cyan;
          white = white;
          orange = orange;
      };
    };
  };

  programs.autorandr.enable = true;

  programs.rofi = {
    enable = true;
    terminal = "${pkgs.alacritty}/bin/alacritty";
    cycle = true;
    theme = let inherit (config.lib.formats.rasi) mkLiteral;
    in {
      "*" = {
        background-color = mkLiteral bg;
        text-color = mkLiteral fg;
        accent = mkLiteral bgFade;
      };

      "window" = {
        border-radius = mkLiteral "5px";
        padding = mkLiteral "30px";
      };

      "prompt, entry" = {
        padding = mkLiteral "3px";
        text-color = mkLiteral fg;
      };

      "element" = { 
        border-radius = mkLiteral "2px";
        padding = mkLiteral "4px";
      };

      "element selected" = {
        background-color = mkLiteral fg;
        text-color = mkLiteral bg;
      };

      "button selected" = {
        background-color = mkLiteral fg;
        text-color = mkLiteral bg;
        border-radius = mkLiteral "2px";
        padding = mkLiteral "3px";
      };
    };  
  };

  services.picom = {
    # package = picom-fork;
    enable = true;
    backend = "glx";
    shadow = true;
    fade = true;
    fadeDelta = 2;
    shadowOpacity = 0.65;
    settings = {
      corner-radius = 10;
      experimentalBackends = true;
      # blur = { method = "dual_kawase"; };
    };
  };

  gtk = {
    enable = true;
    theme = {
      name = "rose-pine";
      package = pkgs.rose-pine-gtk-theme;
    };
    iconTheme = {
      name = "rose-pine";
      package = pkgs.rose-pine-gtk-theme;
    };
  };

  home.pointerCursor = {
    enable = true;
    name = "Vimix-white-cursors";
    package = pkgs.vimix-cursors;
    size = 48;
    gtk.enable = true;
    x11.enable = true;
  };

  # Autoload nix shells
  services.lorri.enable = true;

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

  services.megasync = {
    enable = true;
    package = pkgs2405.megasync;
  };

  programs.nix-index = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv.nix-direnv.enable = true;

  xdg.mimeApps.defaultApplications = {
    "application/pdf" = [
      "okular.desktop"
    ];
    "x-scheme-handler/io.element.desktop" = pkgs.element-desktop.desktopItem.name;
  };
}
