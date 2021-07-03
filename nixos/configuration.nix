# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      <home-manager/nixos>
    ];

  environment.pathsToLink = [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw

  hardware.bluetooth.enable = true;

  nix.autoOptimiseStore = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = false;

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.efi.efiSysMountPoint = "/boot";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub = {
    device = "nodev"; # or "nodev" for efi only
    useOSProber = true;
    extraEntries = ''
        menuentry "Windows" {
          insmod part_gpt
          insmod fat
          insmod search_fs_uuid
          insmod chain
          search --fs-uuid --set=root $FS_UUID
          chainloader /efi/Microsoft/Boot/bootmgfw.efi
        }'';
  };

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


  # Enable the Plasma 5 Desktop Environment.
  # services.xserver.displayManager.lightdm.enable = true;
  # services.xserver.desktopManager.plasma5.enable = true;

  services = {
    upower.enable = true;

    dbus = {
      enable = true;
      packages = [ pkgs.gnome3.dconf ];
    };
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

    deviceSection = ''
      Identifier     "Device0"
      Driver         "nvidia"
      VendorName     "NVIDIA Corporation"
      BoardName      "GeForce GTX 1660 Ti"
    '';

    screenSection = ''
      Identifier     "Screen0"
      Device         "Device0"
      Monitor        "Monitor0"
      DefaultDepth    24
      Option         "Stereo" "0"
      Option         "nvidiaXineramaInfoOrder" "DFP-6"
      Option         "metamodes" "DP-5: nvidia-auto-select +0+220 {viewportin=2880x1620, ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}, HDMI-0: nvidia-auto-select +2880+0 {ForceCompositionPipeline=On, ForceFullCompositionPipeline=On}"
      Option         "SLI" "Off"
      Option         "MultiGPU" "Off"
      Option         "BaseMosaic" "off"
      SubSection     "Display"
          Depth       24
      EndSubSection
    '';
  };

  services.pantheon.apps.enable = false;

  # Bluetooth service
  services.blueman.enable = true;

  # Configure keymap in X11
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  services.printing.enable = true;

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
  nix.trustedUsers = [ "root" "gabriela" ];

  users.extraUsers.gabriela = {
    shell = pkgs.fish;
  };

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

  # nixpkgs.overlays = [
  #   (import (builtins.fetchTarball https://github.com/nix-community/emacs-overlay/archive/master.tar.gz))
  # ];

  # To Flatpak
  # services.flatpak.enable = true;
  # xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
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
}
