{ ... }: {
  imports = [ ./common.nix ];

  # For X-spawned applications like Doom Emacs
  xsession.profileExtra = ''
    export DOOM_FONT_SIZE=36
    export DOOM_BIG_FONT_SIZE=48
    export POLYBAR_DPI=180
    export POLYBAR_PADDING_RIGHT=40
    export QT_SCALE_FACTOR=1.5
    export QT_AUTO_SCREEN_SCALE_FACTOR=1
    export GDK_SCALE=1.5
    export GDK_DPI_SCALE=1.0
  '';

  # For shell-spawned applications like Polybar
  home.sessionVariables.POLYBAR_DPI = "180";
  home.sessionVariables.POLYBAR_PADDING_RIGHT = "40";
  home.sessionVariables.QT_SCALE_FACTOR = "1.5";
  home.sessionVariables.QT_AUTO_SCREEN_SCALE_FACTOR = "1";
  home.sessionVariables.GDK_SCALE = "1.5";
  home.sessionVariables.GDK_DPI_SCALE = "1.0";

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
