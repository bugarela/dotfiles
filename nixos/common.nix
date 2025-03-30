# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ inputs, outputs, config, pkgs, lib, ... }:

{
  imports = [
    # Bring in home manager
    inputs.home-manager.nixosModules.home-manager
  ];

  environment.pathsToLink =
    [ "/libexec" ]; # links /libexec from derivations to /run/current-system/sw

  hardware.bluetooth.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.networkmanager.enable = true;
  networking.nameservers = [ "8.8.8.8" "8.8.4.4" ];

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

  # Xserver basic
  services.xserver = {
    enable = true;
    exportConfiguration = true;
    xkb = {
      layout = "us";
      variant = "altgr-intl";
      options = "caps:swapescape";
    };
    desktopManager = {
      xfce.enable = true;
      xterm.enable = false;
    };
    displayManager.lightdm.enable = true;
  };

  services.displayManager = { defaultSession = "xfce"; };

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
  };

  services.pantheon.apps.enable = false;

  # Bluetooth service
  services.blueman.enable = true;

  # Configure keymap in X11
  # services.xserver.xkbOptions = "eurosign:e";

  # Enable CUPS to print documents.
  services.printing.enable = false;

  # Enable sound.
  # sound.enable = true;
  services.pulseaudio = {
    enable = true;
    package = pkgs.pulseaudioFull;
  };

  services.pipewire = {
    enable = false;
    # audio.enable = true;
    # pulse.enable = true;
    # alsa = {
    #   enable = true;
    #   support32Bit = true;
    # };
    # jack.enable = true;
  };


  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

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
    description = "Gabriela Moreira";
    home = "/home/gabriela";
    extraGroups = [ "wheel" "networkmanager" "docker" "video" "plugdev" "render" ];
  };

  users.extraUsers.gabriela = { shell = pkgs.fish; };

  programs.fish.enable = true;

  # Automount ecrypts
  security.pam.enableEcryptfs = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wget
    git
    htop
    gparted
    terminator
    fish
    vim
    helix
    helix-gpt
    xclip
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
    cachix
    gnutar
    gzip
    gnumake

    jre

    cheese
    mlt

    headsetcontrol
    alsa-utils

    gsmartcontrol
  ];

  # Fonts
  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
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
    etBook
    emacs-all-the-icons-fonts

    nerd-fonts.droid-sans-mono
    nerd-fonts.mononoki
    paratype-pt-sans
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    # pinentryPackage = "curses";
  };

  programs.steam = {
    enable = true;
    remotePlay.openFirewall =
      true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall =
      true; # Open ports in the firewall for Source Dedicated Server
  };

  # Some programs need SUID wrappers, can be configured further or are started
  # in user sessions. programs.mtr.enable = true; programs.gnupg.agent = {
  # enable = true; enableSSHSupport = true; };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  networking.firewall = {
    allowedTCPPorts = [ 443 4443 17500 ];
    allowedUDPPorts = [ 17500 ];
  };
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

  nixpkgs = {
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
      permittedInsecurePackages = [ "python-2.7.18.7" "python-2.7.18.8" ];
    };
  };

  nix.registry = (lib.mapAttrs (_: flake: { inherit flake; }))
    ((lib.filterAttrs (_: lib.isType "flake")) inputs);

  nix.settings = {
    # Enable flakes and new 'nix' command
    experimental-features = "nix-command flakes";
    # Deduplicate and optimize nix store
    auto-optimise-store = true;
    # Allow me to specify additional substituters
    trusted-users = [ "gabriela" ];
    # List of substituters
    substituters =
      [ "https://cache.nixos.org" "https://nix-community.cachix.org" ];
    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
  # # Solution to VSCode server from https://nixos.wiki/wiki/Visual_Studio_Code
  # programs.nix-ld.enable = true;
  # environment.variables = {
  #   NIX_LD_LIBRARY_PATH = lib.makeLibraryPath [
  #     pkgs.stdenv.cc.cc
  #   ];
  #   NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
  # };

  # {imported to configuration.nix direct as home-manager does not support 1password
  programs._1password = { enable = true; };

  # Enable the 1Passsword GUI with myself as an authorized user for polkit
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "gabriela" ];
  };
  security.polkit.enable = true;

  services.udev.packages = [ pkgs.headsetcontrol ];

  systemd.services.nix-daemon.serviceConfig.EnvironmentFile = "/etc/nixos/nix-daemon-environment";

  # https://nixos.wiki/wiki/Dropbox
  # systemd.user.services.dropbox = {
  #   description = "Dropbox";
  #   wantedBy = [ "graphical-session.target" ];
  #   environment = {
  #     QT_PLUGIN_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtPluginPrefix;
  #     QML2_IMPORT_PATH = "/run/current-system/sw/" + pkgs.qt5.qtbase.qtQmlPrefix;
  #   };
  #   serviceConfig = {
  #     ExecStart = "${lib.getBin pkgs.dropbox}/bin/dropbox";
  #     ExecReload = "${lib.getBin pkgs.coreutils}/bin/kill -HUP $MAINPID";
  #     KillMode = "control-group"; # upstream recommends process
  #     Restart = "on-failure";
  #     PrivateTmp = true;
  #     ProtectSystem = "full";
  #     Nice = 10;
  #   };
  # };
}
