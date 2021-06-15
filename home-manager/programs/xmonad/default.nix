{ pkgs, ...}:

{
  xsession = {
    enable = true;

    windowManager.xmonad = {
      enable = true;
      enableContribAndExtras = true;
      extraPackages = haskellPackages: [
        haskellPackages.xmonad
        haskellPackages.xmonad-contrib
        haskellPackages.xmonad-extras
      ];
      config = /home/gabriela/nix-configs/home-manager/programs/xmonad/config.hs;
    };

  };
}
