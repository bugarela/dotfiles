{ config, pkgs, lib, ...}:

let
  unstable = import <nixpkgs-unstable> { config.allowUnfree = true; };
in
{
  programs.vscode = {
    enable = true;
    userSettings = builtins.fromJSON (builtins.readFile ./settings.json);
    package = unstable.vscode;
    mutableExtensionsDir = true;
    extensions = with pkgs.vscode-extensions; [
      scala-lang.scala
      scalameta.metals
      ms-vscode.makefile-tools
      # ms-vscode.cpptools
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
      # github.vscode-github-actions
      # wakatime.vscode-wakatime
    # ] ++ [
    #   (pkgs.vscode-utils.buildVscodeExtension {
    #     name = "quint-vscode";
    #     vscodeExtName = "quint-vscode";
    #     vscodeExtPublisher = "informal";
    #     vscodeExtUniqueId = "informal.quint-vscode";
    #     version = "0.3.0";
    #     src = /home/gabriela/projects/quint/vscode/quint-vscode;
    #   })
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
        version = "1.84.53";
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

  # Adapted from # https://github.com/Sciencentistguy/nixfiles/commit/e9eb884cce63ffc41147d1ecfd0569910a3909c9
  # home.file = let
  #   inherit (lib) mkMerge concatMap;
  #   cfg = config.programs.vscode;
  #   subDir = "share/vscode/extensions";
  #   extensionPath = ".vscode/extensions";

  #   # Adapted from https://discourse.nixos.org/t/vscode-extensions-setup/1801/2
  #   toPaths = ext:
  #     map (k: {"${extensionPath}/${k}".source = "${ext}/${subDir}/${k}";})
  #     (
  #       if ext ? vscodeExtUniqueId
  #       then [ext.vscodeExtUniqueId]
  #       else builtins.attrNames (builtins.readDir (ext + "/${subDir}"))
  #     );
  # in (mkMerge ((concatMap toPaths cfg.extensions)
  #   ++ [
  #     {
  #       ".vscode/extensions/.obsolete".text = "";
  #       ".vscode/extensions/extensions.json".text = let
  #         toExtensionJsonEntry = drv: rec {
  #           identifier = {
  #             id = "${drv.vscodeExtPublisher}.${drv.vscodeExtName} ";
  #             uuid = "";
  #           };

  #           version = drv.version;

  #           location = {
  #             "$mid" = 1;
  #             fsPath = drv.outPath + "/share/vscode/extensions/${drv.vscodeExtUniqueId}";
  #             path = location.fsPath;
  #             scheme = "file";
  #           };

  #           metadata = {
  #             id = identifier.uuid;
  #             publisherId = "";
  #             publisherDisplayName = drv.vscodeExtPublisher;
  #             targetPlatform = "undefined";
  #             isApplicationScoped = false;
  #             updated = false;
  #             isPreReleaseVersion = false;
  #             installedTimestamp = 0;
  #             preRelease = false;
  #           };
  #         };
  #         x = builtins.toJSON (map toExtensionJsonEntry config.programs.vscode.extensions);
  #       in
  #         builtins.trace x x;
  #     }
  #   ]));
  home.file.".vscode/extensions/.obsolete".text = "";
  # home.file.".vscode/extensions/extensions.json".text = let
  #   toExtensionJsonEntry = drv: rec {
  #     identifier = {
  #       id = "${drv.vscodeExtPublisher}.${drv.vscodeExtName} ";
  #       uuid = "";
  #     };

  #     version = drv.version;

  #     location = {
  #       "$mid" = 1;
  #       fsPath = config.home.homeDirectory + "/.vscode/extensions/${drv.vscodeExtUniqueId}";
  #       path = builtins.trace drv location.fsPath;
  #       scheme = "file";
  #     };

  #     metadata = {
  #       id = identifier.uuid;
  #       publisherId = "";
  #       publisherDisplayName = drv.vscodeExtPublisher;
  #       targetPlatform = "undefined";
  #       isApplicationScoped = false;
  #       updated = false;
  #       isPreReleaseVersion = false;
  #       installedTimestamp = 0;
  #       preRelease = false;
  #     };
  #   };
  #   x = builtins.toJSON (map toExtensionJsonEntry config.programs.vscode.extensions);
  # in
  #   builtins.trace x x;
}





# [
#       (pkgs.vscode-utils.buildVscodeExtension {
#         name = "quint-vscode";
#         vscodeExtName = "quint-vscode";
#         vscodeExtPublisher = "informal";
#         vscodeExtUniqueId = "informal.quint-vscode";
#         version = "0.3.0";
#         src = pkgs.fetchFromGitHub {
#           owner = "informalsystems";
#           repo = "quint";
#           rev = "main";
#           sha256 = "sha256-73tIQgE/0mxCbUfYhpNuCjRVaR1vZbsUQS/rKd9333U=";
#         } + "/vscode/quint-vscode";
#         unpackPhase = ":";
#       })
#     ] ++
