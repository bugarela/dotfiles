{ config, pkgs, lib, ... }:

{
  programs.vscode = {
    enable = true;
    profiles.default.userSettings = builtins.fromJSON (builtins.readFile ./settings.json);
    package = pkgs.vscode;
    mutableExtensionsDir = true;
    profiles.default.extensions = with pkgs.vscode-extensions;
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
        ms-vsliveshare.vsliveshare
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
        # https://marketplace.visualstudio.com/_apis/public/gallery/publishers/GitHub/vsextensions/copilot/1.95.243/vspackage
        {
          name = "copilot";
          publisher = "GitHub";
          version = "1.208.0";
          sha256 = "sha256-b04sl9WPrv/OilKEeK5u0STj8EqrHBiJA73B2REz8oo=";
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
        # This was deleted from the marketplace :(
        # {
        #   name = "vsc-community-material-theme";
        #   publisher = "Equinusocio";
        #   version = "1.4.6";
        #   sha256 = "0v34vm3asnw2maf4yz6lmn9xzv9232lm1a9vayybj1w0s09k4n0d";
        # }
        {
          name = "material-deep-ocean-theme";
          publisher = "KYDronePilot";
          version = "0.0.4";
          sha256 = "sha256-7SJCa81CXDUC1dItApQ9ST5seRa9Ddz4qW7RlonoCCI=";
        }
        {
          name = "remote-explorer";
          publisher = "ms-vscode";
          version = "0.5.2023062609";
          sha256 = "1zvxmqhnacpa8zz8b0s45ra8q9qcznpabpnd235pn8gs3c6bjqc4";
        }
        # {
        #   name = "vsliveshare";
        #   publisher = "ms-vsliveshare";
        #   version = "1.0.5873";
        #   sha256 = "1c5bqz267va6lkg2zrz99drypdskrhyq0573gpy06icfj5pdl1m7";
        # }
        {
          name = "chronicler";
          publisher = "arcsine";
          version = "0.1.16";
          sha256 = "sha256-R/+nMfyD6dv+jMMbg0/Acoaciqbp3qym7Xw8R0/z/KQ=";
        }
      ];
  };

  home.file.".vscode/extensions/.obsolete".text = "";
  home.file.".vscode/extensions/.obsolete".executable = false;
}
