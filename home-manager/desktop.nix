{ pkgs, ... }: {
  imports = [ ./common.nix ];

  programs.mangohud.enable = true;

  home.packages = [
    pkgs.lutris
    pkgs.bottles
    pkgs.heroic
    pkgs.wine
    # pkgs.tuxguitar
  ];

  programs.alacritty = {
    settings = {
      window = {
        padding = {
          x = 30;
          y = 30;
        };
      };

      font = { size = 14.0; };
    };
  };

  home.pointerCursor.size = 48;
}
