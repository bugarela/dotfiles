{ config, pkgs, lib, ... }:

let unstable = import <nixpkgs-unstable> { config.allowUnfree = true; };
in {
  programs.vscode = {
    enable = true;
    userSettings = builtins.fromJSON (builtins.readFile ./settings.json);
    # package = unstable.vscode;
    package = (pkgs.vscode.override { isInsiders = true; }).overrideAttrs
      (_: prev: {
        pname = "vscode-insiders";
        postPatch = ''
      # this is a fix for "save as root" functionality
      packed="resources/app/node_modules.asar"
      unpacked="resources/app/node_modules"
      asar extract "$packed" "$unpacked"
      substituteInPlace $unpacked/@vscode/sudo-prompt/index.js \
        --replace "/usr/bin/pkexec" "/run/wrappers/bin/pkexec" \
        --replace "/bin/bash" "${pkgs.bash}/bin/bash"
      rm -rf "$packed"
      # without this symlink loading JsChardet, the library that is used for auto encoding detection when files.autoGuessEncoding is true,
      # fails to load with: electron/js2c/renderer_init: Error: Cannot find module 'jschardet'
      # and the window immediately closes which renders VSCode unusable
      # see https://github.com/NixOS/nixpkgs/issues/152939 for full log
      ln -rs "$unpacked" "$packed"
      # this fixes bundled ripgrep
      chmod +x resources/app/node_modules/@vscode/ripgrep/bin/rg
    '';
        src = (builtins.fetchTarball {
          url =
            "https://code.visualstudio.com/sha/download?build=insider&os=linux-x64";
          sha256 = "1nvmnf4w2894v21zcmh1xzcxzzilc10qsqhz2i5hqvrn2vcw0ivv";
        });
        version = "latest";
      });
    mutableExtensionsDir = true;
    extensions = with pkgs.vscode-extensions;
      [
        scala-lang.scala
        scalameta.metals
        ms-vscode.makefile-tools
        ms-vscode-remote.remote-ssh
        mkhl.direnv
        jnoortheen.nix-ide
        haskell.haskell
        github.vscode-pull-request-github
        esbenp.prettier-vscode
        zhuangtongfa.material-theme
        editorconfig.editorconfig
        davidlday.languagetool-linter
        davidanson.vscode-markdownlint
        brettm12345.nixfmt-vscode
        dbaeumer.vscode-eslint
        justusadam.language-haskell
        tomoki1207.pdf
        stkb.rewrap
        vscodevim.vim
        waderyan.gitblame
        yzhang.markdown-all-in-one
        golang.go
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "vscode-tlaplus";
          publisher = "alygin";
          version = "1.5.4";
          sha256 = "0mf98244z6wzb0vj6qdm3idgr2sr5086x7ss2khaxlrziif395dx";
        }
        {
          name = "codebook";
          publisher = "codebook";
          version = "0.4.3";
          sha256 = "1cacaqh93qgimb14w3k6a8cw9a190sn9r7hn6df162mdbxnkgkxw";
        }
        {
          name = "copilot-nightly";
          publisher = "GitHub";
          version = "1.86.111";
          sha256 = "17wpyxcdb359pf8pnrvz273zd5mz2jj6a9iqy2yv4ldmaggrx95z";
        }
        {
          name = "itf-trace-viewer";
          publisher = "informal";
          version = "0.0.5";
          sha256 = "1znya0phd8j3is1188lxwa90hy8v7bxd95mdzv6d60li5q23rrzp";
        }
        # {
        #   name = "quint-vscode";
        #   publisher = "informal";
        #   version = "0.3.0";
        #   sha256 = "079lynwdwkacpkm0wxjckqjn5afizlykrx6v6dy4pqd3xha1hnxi";
        # }
        {
          name = "fuzzy-search";
          publisher = "jacobdufault";
          version = "0.0.3";
          sha256 = "0hvg4ac4zdxmimfwab1lzqizgq8bjfq6rksc9n7953m9gk6m5pd0";
        }
        {
          name = "vscode-antlr4";
          publisher = "mike-lischke";
          version = "2.3.1";
          sha256 = "1sbkdg2bp0jgihmib36zfcvkcjgh1j3chphhs5ly7754mla09x7a";
        }
        {
          name = "format-code-action";
          publisher = "rohit-gohri";
          version = "0.1.0";
          sha256 = "1b1z49vjmqmpdxpgknp015rir0jnqa6z8nm8h4lxip3wa9jizbcg";
        }
        {
          name = "codetour";
          publisher = "vsls-contrib";
          version = "0.0.59";
          sha256 = "1mp860xsqws4pdy9lc2229iszkd2ri0lzxmwqacba73mw9300rvl";
        }
        {
          name = "pretty-ts-errors";
          publisher = "yoavbls";
          version = "0.3.0";
          sha256 = "1czhfvv5zal27m8krkclh533a1kmg5k7va82qsgjm1bqmsm4baq2";
        }
        {
          name = "vsc-community-material-theme";
          publisher = "Equinusocio";
          version = "1.4.6";
          sha256 = "0v34vm3asnw2maf4yz6lmn9xzv9232lm1a9vayybj1w0s09k4n0d";
        }
      ];
  };

  home.file.".vscode/extensions/.obsolete".text = "";
}
