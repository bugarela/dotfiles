{ ... }: {
  imports = [ ./common.nix ];

  programs.alacritty = {
    settings = {
      window = {
        padding = {
          x = 30;
          y = 30;
        };
        opacity = 1;
      };

      font = {
        size = 14.0;
      };
    };
  };
}
