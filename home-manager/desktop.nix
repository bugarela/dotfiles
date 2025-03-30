{ ... }: {
  imports = [ ./common.nix ];

  programs.mangohud.enable = true;

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
}
