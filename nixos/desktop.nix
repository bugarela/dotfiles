{ config, lib, pkgs, ... }:
{
  imports = [ ./hardware/desktop.nix ];

  networking.hostName = "gabriela-nixos"; # Define your hostname.

  environment.systemPackages = with pkgs; [
    vulkan-tools
    dxvk
  ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      vulkan-loader
      vulkan-validation-layers
      vulkan-extension-layer
      # amdvlk   # AMD's official Vulkan driver, commented out because of conflicts with RADV
      rocmPackages.clr.icd
      mesa
    ];
    # extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
  };

  # hardware.firmware = with pkgs; [
  #   (linux-firmware.overrideAttrs (old: {
  #     src = builtins.fetchGit {
  #       url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
  #       # rev = "de78f0aaafb96b3a47c92e9a47485a9509c51093"; # --impure gets the latest
  #     };
  #   }))
  # ];

  # Xserver basic
  services.xserver = {
    dpi = 160;
    videoDrivers = [ "amdgpu" ];
    deviceSection = ''Option "TearFree" "true"'';
    upscaleDefaultCursor = true;
  };

  hardware.amdgpu = {
    # amdvlk = {
    #   enable = true;
    #   support32Bit.enable = true;
    # };
    opencl.enable = true;  
  };


  # The desktop's USB fingerprint reader is a Chipsailing CS9711 (2541:0236),
  # which stock libfprint does not support (fprintd reports NoSuchDevice).
  # Override libfprint with the community fork that adds a match-on-host driver
  # for this chip. Scoped to the desktop so the laptop keeps its stock, fully
  # supported libfprint. Note: enrollment needs ~15 touches and the driver is
  # experimental — see https://github.com/archeYR/libfprint-CS9711
  # Use the archeYR cs9711-rebase branch: the CS9711 driver rebased onto
  # libfprint 1.94.10, which matches the stock nixpkgs version and the API the
  # current fprintd expects (so no version or dependency hacks are needed beyond
  # the sigfm build deps below).
  nixpkgs.overlays = [
    (final: prev: {
      libfprint = prev.libfprint.overrideAttrs (oldAttrs: {
        version = "1.94.10-cs9711";
        src = final.fetchFromGitHub {
          owner = "archeYR";
          repo = "libfprint-CS9711";
          rev = "02b285c9703c38d308fbe47a3c566ef1e7f883ca"; # cs9711-rebase
          sha256 = "sha256-QGrBNqbRNqLZIURI66xkenlQamNW+DQU4WS+CLN4zM8=";
        };
        # The sigfm matcher (match-on-host) pulls in opencv; doctest/cmake are
        # needed for its build configuration.
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [
          final.opencv
          final.cmake
          final.doctest
        ];
        # The sigfm test binary links against -ldoctest, but nixpkgs' doctest is
        # header-only and ships no link library, so the build fails at link time.
        # Drop the test executable — only the driver itself is needed.
        postPatch = (oldAttrs.postPatch or "") + ''
          substituteInPlace libfprint/sigfm/meson.build \
            --replace-fail "sigfm_tests = executable('sigfm-tests', ['./tests.cpp'], dependencies: [doctest, opencv], link_with: [libsigfm])" ""
        '';
        # The suite runs post-install via ninjaCheckPhase, which calls `meson test`
        # with meson's 30s default timeout and no way to pass flags through. Several
        # driver and virtual-device tests exceed that on a loaded builder (they fail
        # as TIMEOUT, never as Fail), so call meson test directly with more headroom.
        installCheckPhase = ''
          runHook preInstallCheck

          meson test --no-rebuild --print-errorlogs --timeout-multiplier 10

          runHook postInstallCheck
        '';
      });
    })
  ];

  # The CS9711 reader is unreliable under USB autosuspend (default 2s timeout),
  # which causes "Open failed: USB error ... Input/Output Error" when fprintd
  # tries to claim it, plus occasional "can't set config #1, error -71" on
  # enumeration. Pin the device powered-on so it stays claimable.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="2541", ATTR{idProduct}=="0236", ATTR{power/control}="on", ATTR{power/autosuspend}="-1"
  '';

  hardware.xpadneo.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall =
      true; # Open ports in the firewall for Steam Remote Play
    dedicatedServer.openFirewall =
      true; # Open ports in the firewall for Source Dedicated Server
    package = pkgs.steam.override {
      extraEnv = {
        GDK_SCALE = "2";
        GDK_DPI_SCALE = "0.75";
      };
    };
  };
}
