{ config, pkgs, lib, ... }:

let
  nur = import (builtins.fetchTarball
    "https://github.com/nix-community/NUR/archive/master.tar.gz") {
      inherit pkgs;
    };
in {
  programs.firefox = {
    enable = true;
    profiles = {
      bugarela = {
        id = 0;
        name = "bugarela";
        isDefault = true;
        settings = {
          # "browser.startup.homepage" = "https://searx.aicampground.com";
          # "browser.search.defaultenginename" = "Searx";
          # "browser.search.order.1" = "Searx";
        };
        search = {
          force = true;
          default = "DuckDuckGo";
          order = [ "Google" ];
          engines = {
            "Nix Packages" = {
              urls = [{
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }];
              icon =
                "''${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
              definedAliases = [ "@np" ];
            };
            "NixOS Wiki" = {
              urls = [{
                template = "https://nixos.wiki/index.php?search={searchTerms}";
              }];
              iconUpdateURL = "https://nixos.wiki/favicon.png";
              updateInterval = 24 * 60 * 60 * 1000; # every day
              definedAliases = [ "@nw" ];
            };
            "Bing".metaData.hidden = true;
            "Google".metaData.alias =
              "@g"; # builtin engines only support specifying one additional alias
          };
        };
        extensions = with nur.repos.rycee.firefox-addons; [
          ublock-origin
          darkreader
          vimium
          onepassword-password-manager
          metamask
        ];
      };
    };
  };
}
