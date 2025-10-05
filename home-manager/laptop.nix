{ ... }: {
  imports = [ ./common.nix ];

  # For X-spawned applications like Doom Emacs
  xsession.profileExtra = ''
    export DOOM_FONT_SIZE=24
    export DOOM_BIG_FONT_SIZE=36
    export POLYBAR_DPI=160
    export POLYBAR_PADDING_RIGHT=30
  '';

  # For shell-spawned applications like Polybar
  home.sessionVariables.POLYBAR_DPI = "160";
  home.sessionVariables.POLYBAR_PADDING_RIGHT = "30";

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

  home.pointerCursor.size = 42;
}
