{ config, pkgs, lib, inputs, fetchFromGithub, ... }:

let
  treesit-grammars = pkgs.emacsPackages.treesit-grammars.with-grammars (grammars: with grammars; [
    tree-sitter-typescript
    tree-sitter-tsx
    tree-sitter-javascript
    tree-sitter-typst
  ]);

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
  cursor = "#a586ba";

  # Bleeding-edge nixpkgs, used for the fast-moving agent CLIs below. Imported
  # (rather than taken from legacyPackages) so allowUnfree applies — claude-code
  # and github-copilot-cli are both unfree.
  pkgsLatest = import inputs.nixpkgs-latest {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };

  pkgs2405 = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/24.05.tar.gz";
    sha256 = "1lr1h35prqkd1mkmzriwlpvxcb34kmhc9dnr48gkm8hh089hifmx";
  }) {
    config.allowUnfree = true;
  };

  wiremix = import ./programs/wiremix/default.nix {};
  voice-record = import ./programs/voice-record/default.nix {};
  mic-stream = import ./programs/mic-stream/default.nix {};
  note-taker = import ./programs/note-taker/default.nix {};
  # Pass the system pkgs (useGlobalPkgs) so the WebKitGTK/mesa stack matches the
  # running system — otherwise the GPU/DMABUF render path falls back to slow CPU
  # rendering (laggy webview). See the comment in its default.nix.
  note-taker-gui = import ./programs/note-taker-gui/default.nix { inherit pkgs; };

  # Saver used by xsecurelock: paint the wallpaper into the window xsecurelock
  # hands us ($XSCREENSAVER_WINDOW). mpv renders a still image cleanly into a
  # given window id and is already installed; --panscan=1 fills each monitor
  # while keeping aspect (no distortion), so it adapts to single- and dual-screen
  # without pre-rendering anything.
  lockSaver = pkgs.writeShellScript "lock-saver" ''
    exec ${pkgs.mpv}/bin/mpv \
      --no-config --no-audio --really-quiet --force-window=yes \
      --loop-file=inf --image-display-duration=inf \
      --no-input-default-bindings --input-conf=/dev/null \
      --osc=no --cursor-autohide=no --no-input-cursor \
      --panscan=1.0 --keepaspect=yes \
      --wid="$XSCREENSAVER_WINDOW" \
      /home/gabriela/dotfiles/wallpaper.jpg
  '';

  # xsecurelock locks the *current* X session in place (no VT switch / new X
  # server), so it doesn't cause the GPU context loss that crashed Chrome under
  # the old `dm-tool lock` greeter, and it blocks until the user authenticates so
  # xss-lock holds exactly one instance — no lockfile/sleep hacks, no
  # double-locking. It authenticates through PAM, so the laptop fingerprint
  # (pam_fprintd) works alongside the password.
  #
  # While locked we stop picom (it composited xsecurelock's windows into the
  # blinking we saw) and pause dunst (so notifications don't paint over the lock
  # screen); both are restored on unlock regardless of how the lock ends.
  lockScript = pkgs.writeShellScript "lock-screen" ''
    export PATH=${lib.makeBinPath [
      pkgs.xsecurelock pkgs.systemd pkgs.dunst pkgs.coreutils pkgs.psmisc
    ]}:$PATH

    # Don't lock if camera is in use (Zoom, Google Meet, etc.)
    if fuser /dev/video* > /dev/null 2>&1; then
      exit 0
    fi

    restore() {
      systemctl --user start picom 2>/dev/null || true
      dunstctl set-paused false 2>/dev/null || true
    }
    trap restore EXIT

    dunstctl set-paused true 2>/dev/null || true
    systemctl --user stop picom 2>/dev/null || true

    export XSECURELOCK_SAVER=${lockSaver}
    export XSECURELOCK_BLANK_TIMEOUT=120
    export XSECURELOCK_SHOW_DATETIME=1
    export XSECURELOCK_SHOW_HOSTNAME=0
    export XSECURELOCK_PASSWORD_PROMPT=cursor

    # Run in the background and forward xss-lock's SIGTERM (sent on logind unlock)
    # so the screen always tears down cleanly and `restore` runs.
    xsecurelock & lockpid=$!
    trap 'kill "$lockpid" 2>/dev/null' INT TERM HUP
    wait "$lockpid"
  '';

  # Temporarily hold off the idle auto-lock ("caffeine"). xss-lock locks on the X
  # ScreenSaver "activate" event, which fires from BOTH the screensaver idle timer
  # (xset s, 1800s) AND DPMS blanking (xset dpms, 1800s). Disabling only `xset s`
  # isn't enough — DPMS blanking still trips the lock — so we turn off both, and
  # restore both on the way out. Nothing auto-suspends on idle here (logind
  # IdleAction=ignore), so no logind inhibitor is needed.
  #   caffeine        -> toggle: stay awake, or restore if already on
  #   caffeine off    -> restore the normal timeouts
  #   caffeine 90m    -> stay awake for a fixed span, then restore itself
  # Restore values mirror the baseline: `xset s 1800` (xss-lock.service's
  # ExecStartPre) and DPMS 1800/1800/1800 (set in xmonad's startup hook).
  caffeine = pkgs.writeShellScriptBin "caffeine" ''
    export PATH=${lib.makeBinPath [ pkgs.xorg.xset pkgs.libnotify pkgs.coreutils ]}:$PATH
    state="''${XDG_RUNTIME_DIR:-/tmp}/caffeine.on"

    on()  { xset s off -dpms;                    touch "$state"; notify-send -a caffeine "☕ Caffeine on"  "Auto-lock & screen blanking disabled"; }
    off() { xset s 1800 1800; xset dpms 1800 1800 1800; rm -f "$state"; notify-send -a caffeine "😴 Caffeine off" "Auto-lock restored"; }

    case "''${1:-toggle}" in
      on)     on ;;
      off)    off ;;
      toggle) if [ -e "$state" ]; then off; else on; fi ;;
      *)      on; trap off EXIT INT TERM HUP; sleep "$1" ;;
    esac
  '';
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
    TREESIT_GRAMMAR_PATH = "${treesit-grammars}/lib";
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
    voice-record
    mic-stream
    note-taker
    note-taker-gui
    caffeine

    pkgs.ripgrep
    pkgs.bat
    pkgs.jq
    pkgs.autorandr
    pkgs.tree
    pkgs.libgccjit
    pkgs.xwininfo
    pkgs.xmobar
    pkgs.xdotool
    pkgs.lxrandr
    pkgs.pscircle
    pkgs.fastfetch
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
    pkgs.lm_sensors

    (pkgs.aspellWithDicts (d: [ d.en d.pt_BR ]))
    pkgs.languagetool

    pkgs.networkmanagerapplet

    pkgs.spotify
    pkgs.pulsemixer

    pkgs.vivaldi
    pkgs.vivaldi-ffmpeg-codecs
    pkgs.google-chrome

    pkgs.telegram-desktop
    pkgs.discord
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
    pkgs.pinentry-curses
    pkgs.gh

    pkgs.megacmd
    pkgs.obs-studio
    pkgs.kdePackages.okular
    pkgs.vlc
    pkgs.mpv
    pkgs.ffmpeg
    pkgs.audacity
    # video editor
    pkgs.kdePackages.kdenlive
    # pkgs.openshot-qt
    # raw editor
    pkgs.art

    pkgs.zoom-us

    pkgs.pandoc
    pkgs.nixpkgs-fmt

    pkgs.libsecret

    pkgs.ledger-live-desktop

    # pkgs.pulseeffects-legacy

    # Required by emacs copilot
    pkgs.nodejs_22
    # Required by treemacs
    pkgs.python3

    pkgs.tree-sitter

    pkgs.headsetcontrol

    pkgs.tlaplus18
    pkgs.tlaplusToolbox

    pkgs.imagemagick
    pkgs.pdf2svg
    pkgs.mermaid-cli
    pkgs.rofimoji
    pkgs.xdotool

    pkgs.brightnessctl
    pkgs.rustc
    pkgs.cargo

    pkgs.zed-editor
    pkgs.openai-whisper
    pkgsLatest.claude-code
    pkgsLatest.codex
    # GitHub Copilot CLI, provides `copilot`
    pkgsLatest.github-copilot-cli

    pkgs.parallel
    pkgs.presenterm
    pkgs.typst

    pkgs.element-desktop
    pkgs.element-web
    (pkgs.symlinkJoin {
      name = "cinny-desktop";
      paths = [ pkgsLatest.cinny-desktop ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/cinny \
          --add-flags "--disable-features=AudioServiceSandbox" \
          --prefix GST_PLUGIN_SYSTEM_PATH_1_0 : "${pkgs.lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (with pkgs.gst_all_1; [
            gstreamer
            gst-plugins-base
            gst-plugins-good
            gst-plugins-bad
          ] ++ [ pkgs.pipewire ])}"
      '';
    })

    # Terminal PDF viewer
    pkgs.tdf
    # Integrated language service for Typst
    pkgs.tinymist

    # Tree-sitter grammars for Emacs
    treesit-grammars
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

  home.file.".git/info/exclude".text =''
    .env
    **/.direnv
  '';

  programs.git = {
    enable = true;
    settings.user.name = "bugarela";
    settings.user.email = "gabrielamoreira05@gmail.com";
    settings.url."git@github.com:".insteadOf = "https://github.com/";
    signing = {
      key =
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK9j0vEeUJi5vv++eeMOWkIYjGy8ED7s3M4FHY7YOzXH";
      signByDefault = true;
      format = "ssh";
      signer = "/run/current-system/sw/bin/op-ssh-sign";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
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
        pager = ["${pkgs.delta}/bin/delta" "--navigate"];
        # diff-editor = "${pkgs.meld}/bin/meld";
        diff-formatter = ":git";
        default-command = ["log" "-n" "10"];
      };


      aliases = {
        local = ["log" "-r" "remote_bookmarks().."];
        f = ["git" "fetch"];
        # aliases are argv prefixes, not shell, so chaining needs `util exec`.
        # "$@" forwards any extra flags to the push.
        push = ["util" "exec" "--" "sh" "-c" ''jj git push "$@" && jj new'' "jj-push"];
        back = ["edit" "-r" "@-"];
        d = ["describe" "-m"];
        bd = ["describe" "@-" "-m"];
        md = ["diff" "-f" "trunk()" "-t" "@"];
        rb = ["rebase" "-s" "base" "-d" "trunk()"];
      };
    };
  };

  programs.fish = {
    enable = true;
    interactiveShellInit = builtins.readFile ./programs/fish/config.fish;
    functions = {
      # open files in the running emacs daemon without blocking the shell
      e = ''emacsclient -n -a "" $argv'';
    };
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
      };

      colors = {
        primary = {
          background = bg;
          foreground = fg;
        };
        cursor = {
          text = "#0E1415";
          cursor = cursor;
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

  programs.ghostty = {
    enable = true;

    settings = {
      theme = "booberry";
      font-family = "Iosevka";
      font-size = 18;
      # alacritty pins every face to Regular; match it so bold-heavy TUIs
      # (zellij's frames/tab bar) don't render heavier here than there.
      font-style = "Regular";
      font-style-bold = "Regular";
      font-style-italic = "Regular";
      font-style-bold-italic = "Regular";
      font-synthetic-style = false;
      scrollback-limit = 10000000;
      background-opacity = 1.0;
    };

    # same palette as the alacritty config above
    themes.booberry = {
      background = bg;
      foreground = fg;
      cursor-color = cursor;
      cursor-text = "#0E1415";
      selection-background = bgFade;
      selection-foreground = fg;
      palette = [
        "0=${black}"
        "1=${red}"
        "2=${green}"
        "3=${yellow}"
        "4=${blue}"
        "5=${magenta}"
        "6=${cyan}"
        "7=${white}"
        "8=#777777"
        "9=#f36868"
        "10=#88db3f"
        "11=#f0bf7a"
        "12=#6f8fdb"
        "13=#e987e9"
        "14=#4ac9e2"
        "15=#FFFFFF"
      ];
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
        padding = mkLiteral "4px";
        text-color = mkLiteral fg;
      };

      "element" = { 
        border-radius = mkLiteral "2px";
        padding = mkLiteral "6px";
      };

      "element selected" = {
        background-color = mkLiteral fg;
        text-color = mkLiteral bg;
      };

      "button selected" = {
        background-color = mkLiteral fg;
        text-color = mkLiteral bg;
        border-radius = mkLiteral "2px";
        padding = mkLiteral "4px";
      };
    };  
  };

  services.picom = {
    enable = false;
    shadow = true;
    shadowOpacity = 0.65;
    fade = false;
    settings = {
      corner-radius = 10;
      use-damage = false;
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
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  home.pointerCursor = {
    enable = true;
    name = "Vimix-white-cursors";
    package = pkgs.vimix-cursors;
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
      "zathura.desktop"
    ];
    "x-scheme-handler/io.element.desktop" = pkgs.element-desktop.desktopItem.name;
  };

  systemd.user.services.polkit-agent = {
    Unit = {
      Description = "Polkit authentication agent";
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  services.screen-locker = {
    enable = true;
    lockCmd = "${lockScript}";
    inactiveInterval = 30;
    xautolock.enable = false;
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks."*" = {
      extraOptions = {
        ServerAliveInterval = "60";
        ServerAliveCountMax = "30";
      };
    };
  };

  programs.zathura = {
    enable = true;
    options = {
      font = "monospace normal 14";
      statusbar-h-padding = 12;
      statusbar-v-padding = 4;
      default-bg = bg;
      default-fg = fg;
      statusbar-bg = bg;
      statusbar-fg = fg;
      inputbar-bg = bgFade;
      inputbar-fg = fg;
      highlight-color = "rgba(165, 134, 186, 0.58)";
    };
  };
}
