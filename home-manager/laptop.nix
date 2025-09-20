{ ... }: {
  imports = [ ./common.nix ];

  programs.alacritty = {
    settings = {
      window = {
        padding = {
          x = 10;
          y = 10;
        };
      };

      font = {
        size = 10.0;
      };
    };
  };

  home.pointerCursor.size = 36;
}
