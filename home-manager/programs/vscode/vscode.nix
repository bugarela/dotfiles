{ pkgs, ...}:

let
  unstable = import <nixpkgs-unstable> { config.allowUnfree = true; };
in
{
  programs.vscode = {
    enable = true;
    userSettings = builtins.fromJSON (builtins.readFile ./settings.json);
    package = unstable.vscode;
    extensions = [
      pkgs.vscode-extensions.scala-lang.scala
      pkgs.vscode-extensions.scalameta.metals
      pkgs.vscode-extensions.ms-vscode.makefile-tools
      pkgs.vscode-extensions.ms-vscode.cpptools
      pkgs.vscode-extensions.ms-vscode-remote.remote-ssh
      pkgs.vscode-extensions.mkhl.direnv
      pkgs.vscode-extensions.jnoortheen.nix-ide
      pkgs.vscode-extensions.haskell.haskell
      pkgs.vscode-extensions.github.vscode-pull-request-github
      # pkgs.vscode-extensions.github.vscode-github-actions
      pkgs.vscode-extensions.esbenp.prettier-vscode
      pkgs.vscode-extensions.zhuangtongfa.material-theme
      pkgs.vscode-extensions.editorconfig.editorconfig
      pkgs.vscode-extensions.davidlday.languagetool-linter
      pkgs.vscode-extensions.davidanson.vscode-markdownlint
      pkgs.vscode-extensions.brettm12345.nixfmt-vscode
      pkgs.vscode-extensions.dbaeumer.vscode-eslint
      pkgs.vscode-extensions.justusadam.language-haskell
      pkgs.vscode-extensions.tomoki1207.pdf
      pkgs.vscode-extensions.stkb.rewrap
      pkgs.vscode-extensions.vscodevim.vim
      pkgs.vscode-extensions.waderyan.gitblame
      # pkgs.vscode-extensions.wakatime.vscode-wakatime
      pkgs.vscode-extensions.yzhang.markdown-all-in-one
    ] ++ map
      (extension: pkgs.vscode-utils.buildVscodeMarketplaceExtension {
        mktplcRef = {
         inherit (extension) name publisher version sha256;
        };
      })[
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
        version = "1.84.53";
        sha256 = "17wpyxcdb359pf8pnrvz273zd5mz2jj6a9iqy2yv4ldmaggrx95z";
      }
      {
        name = "itf-trace-viewer";
        publisher = "informal";
        version = "0.0.5";
        sha256 = "1znya0phd8j3is1188lxwa90hy8v7bxd95mdzv6d60li5q23rrzp";
      }
      {
        name = "quint-vscode";
        publisher = "informal";
        version = "0.3.0";
        sha256 = "079lynwdwkacpkm0wxjckqjn5afizlykrx6v6dy4pqd3xha1hnxi";
      }
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
}
