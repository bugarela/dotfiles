{ pkgs }:
# Herdr desktop app (herdr-app) and its terminal core (herdr-core / hc), both
# from nixpkgs. herdr-desktop finds hc on its own; herdr-core is joined in so
# hc and its agent skill are on PATH too.
pkgs.symlinkJoin {
  name = "herdr-${pkgs.herdr-desktop.version}";
  paths = [ pkgs.herdr-desktop pkgs.herdr-core ];
}
