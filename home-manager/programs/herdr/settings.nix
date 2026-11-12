{ config, lib, pkgs, ... }:
# Herdr has one settings.json and no per-machine override, and the whole
# ~/.config/herdr-app folder is the repo's working tree (see common.nix). So
# the tracked part lives in settings.base.json, and settings.json -- ignored by
# git -- is written on every switch from it plus what differs per machine.
#
# Herdr writes settings.json itself (the zoom keys, Settings), and those
# changes last until the next switch. To keep one, put it in settings.base.json
# or, if it is per machine, here.
let
  cfg = config.herdr;
  dir = "${config.home.homeDirectory}/dotfiles/herdr-app";
  overrides = pkgs.writeText "herdr-settings-overrides.json"
    (builtins.toJSON { inherit (cfg) zoom; });
in
{
  options.herdr.zoom = lib.mkOption {
    type = lib.types.numbers.between 0.5 3;
    default = 1;
    description = "Herdr's zoom on this machine: scales terminals, mods and the layout.";
  };

  config.home.activation.herdrSettings =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -f "${dir}/settings.base.json" ]; then
        # Written aside and renamed, since Herdr reloads it as it changes.
        run ${pkgs.bash}/bin/sh -c '${lib.getExe pkgs.jq} -s ".[0] * .[1]" \
          "${dir}/settings.base.json" ${overrides} > "${dir}/.settings.json.tmp" &&
          mv "${dir}/.settings.json.tmp" "${dir}/settings.json"'
      fi
    '';
}
