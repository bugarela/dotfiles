# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      <home-manager/nixos>
    ];

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw

  hardware.bluetooth.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "gabriela-nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;

  boot.kernel.sysctl."net.ipv6.conf.all.disable_ipv6" = true;
  boot.kernel.sysctl."net.ipv6.conf.default.disable_ipv6" = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  # };

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    settings = {
      trusted-users = [ "root" "gabriela" ];

      # Binary Cache for Haskell.nix
      trusted-public-keys = [
        "hydra.iohk.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
      ];
      substituters = [
        "https://hydra.iohk.io"
      ];

      auto-optimise-store = true;
    };
   };

  # Enable the Plasma 5 Desktop Environment.
  # services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  services = {
    upower.enable = true;

    dbus = {
      enable = true;
      packages = [ pkgs.dconf ];
    };

    gnome.gnome-keyring.enable = true;
    bloop.install = true;
  };

  # Xserver basic
  services.xserver = {
    enable = true;
    exportConfiguration = true;
    layout = "us";
    xkbVariant = "altgr-intl";
    xkbOptions = "caps:swapescape";
    dpi = 141;
    videoDrivers = [ "nvidia" ];
    modules = [ pkgs.xf86_input_wacom ];

    desktopManager = {
      xfce.enable = true;
      xterm.enable = false;
    };

    displayManager = {
      lightdm.enable = true;
      defaultSession = "xfce";
    };

#    deviceSection = ''
#      Identifier     "Device0"
#      Driver         "nvidia"
#      VendorName     "NVIDIA Corporation"
#      BoardName      "NVIDIA GeForce RTX 3080"
#    '';

#    screenSection = ''
#      Identifier     "Screen0"
#      Device         "Device0"
#      Monitor        "Monitor0"
#      DefaultDepth    24
#      Option         "Stereo" "0"
#      Option         "nvidiaXineramaInfoOrder" "DFP-0"
#      Option         "metamodes" "HDMI-0: nvidia-auto-select +3840+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}, DP-3: 1920x1080 +7680+0 {rotation=right, ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}, DP-0: 3840x2160 +0+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
#      Option         "SLI" "Off"
#      Option         "MultiGPU" "Off"
#      Option         "BaseMosaic" "off"
#      SubSection     "Display"
#          Depth       24
#      EndSubSection
#    '';
  };

  services.pantheon.apps.enable = false;

  # Bluetooth service
  services.blueman.enable = true;

  # Configure keymap in X11
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  services.printing.enable = false;

  # Enable sound.
  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.xserver.libinput.enable = true;


  # Disables mouse acceleration
  services.xserver.config = ''
    Section "InputClass"
      Identifier "mouse accel"
      Driver "libinput"
      MatchIsPointer "on"
      Option "AccelProfile" "flat"
      Option "AccelSpeed" "0"
    EndSection
  '';
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.gabriela = {
    isNormalUser = true;
    home = "/home/gabriela";
    extraGroups = [ "wheel" "networkmanager" "docker" "video" ];
  };


  users.extraUsers.gabriela = {
    shell = pkgs.fish;
  };

  programs.fish.enable = true;

  # Automount ecrypts
  security.pam.enableEcryptfs = true;

  nixpkgs.config.allowUnfree = true;
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    git
    htop
    gparted
    firefox
    terminator
    fish
    vim
    home-manager
    gnupg
    gcc
    binutils

    ecryptfs
    ecryptfs-helper
    utillinux
    hicolor-icon-theme
    ripgrep
    coreutils
    fd
    docker-compose
    rnix-lsp
    cachix
    gnutar gzip gnumake

    jre

    gnome.cheese
    mlt
    libsForQt5.mlt
    # libnotify
    # libdbusmenu
  ];

  # Fonts
  fonts.fonts = with pkgs; [
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    liberation_ttf
    fira-code
    fira-code-symbols
    dina-font
    proggyfonts
    mononoki
    font-awesome_4
    font-awesome_5
    papirus-icon-theme
    iosevka
    emacs-all-the-icons-fonts
    (nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" "Mononoki" ]; })
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryFlavor = "curses";
  };

  programs.steam.enable = true;

  # Some programs need SUID wrappers, can be configured further or are started
  # in user sessions. programs.mtr.enable = true; programs.gnupg.agent = {
  # enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?

  # Docker config
  virtualisation.docker.enable = true;

  nixpkgs.config.permittedInsecurePackages = [
    "python-2.7.18.6"
  ];

  # # Solution to VSCode server from https://nixos.wiki/wiki/Visual_Studio_Code
  # programs.nix-ld.enable = true;
  # environment.variables = {
  #   NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
  #     pkgs.stdenv.cc.cc
  #   ];
  #   NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
  # };
}
