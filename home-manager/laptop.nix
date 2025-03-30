{ ... }: {
  imports = [ ./common.nix ];

  programs.alacritty = {
    settings = {
      window = {
        padding = {
          x = 10;
          y = 10;
        };
        opacity = 1;
      };

      font = {
        size = 10.0;
      };
    };
  };
}
