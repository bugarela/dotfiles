{ pkgs, inputs, lib, ... }:
let
  # A disconnected SSH tunnel can leave a socket inode behind. Check that it
  # accepts connections, not just that it exists. No signing request is made.
  laptopAgentAvailable = pkgs.writeScript "herdr-laptop-agent-available" ''
    #!${pkgs.python3}/bin/python3
    import socket
    import sys

    with socket.socket(socket.AF_UNIX) as agent:
        agent.settimeout(0.25)
        try:
            agent.connect("/home/gabriela/.ssh/herdr-laptop-agent.sock")
        except OSError:
            sys.exit(1)
  '';
in {
  imports = [ ./common.nix ];

  # Herdr's persistent services do not inherit SSH_AUTH_SOCK from the login.
  # OpenSSH resolves this stable socket on every connection, including Git
  # fetches from terminals that predate the tunnel. First IdentityAgent wins.
  home.file.".ssh/config".text = lib.mkBefore ''
    Match exec "${laptopAgentAvailable}"
        IdentityAgent /home/gabriela/.ssh/herdr-laptop-agent.sock
  '';

  # libgit2 would bypass OpenSSH's IdentityAgent selection.
  programs.jujutsu.settings.git.subprocess = lib.mkForce true;

  # For X-spawned applications like Doom Emacs
  xsession.profileExtra = ''
    export DOOM_FONT_SIZE=32
    export DOOM_BIG_FONT_SIZE=42
    export POLYBAR_DPI=192
    export POLYBAR_PADDING_RIGHT=40
  '';

  # For shell-spawned applications like Polybar
  home.sessionVariables.POLYBAR_DPI = "192";
  home.sessionVariables.POLYBAR_PADDING_RIGHT = "40";

  herdr.zoom = 1.3;

  programs.mangohud.enable = true;

  home.packages = [
    pkgs.lutris
    pkgs.bottles
    pkgs.heroic
    pkgs.wine
    # pkgs.tuxguitar

    inputs.nixpkgs-latest.legacyPackages.${pkgs.stdenv.hostPlatform.system}.opencode
  ];

  services.ollama = {
    enable = false;
    # Gemma 4 is broken on the Vulkan backend (garbled text, missing thinking); ROCm/HIP is the right path for RX 9070 XT.
    # If ROCm does not see the GPU, temporarily use ollama-vulkan with OLLAMA_VULKAN = "0" (CPU-only, correct output).
    package = inputs.nixpkgs-latest.legacyPackages.${pkgs.stdenv.hostPlatform.system}.ollama-rocm;
    environmentVariables = {
      OLLAMA_FLASH_ATTENTION = "1";
      OLLAMA_KV_CACHE_TYPE = "q8_0";
    };
  };

  programs.alacritty = {
    settings = {
      window = {
        padding = {
          x = 30;
          y = 30;
        };
      };

      font = { size = 14.0; };
    };
  };

  home.pointerCursor.size = 48;

  # TearFree is enabled at the X level (nixos/desktop.nix), so picom vSync
  # would conflict. xrender backend needed — glx/egl cause a black screen on RDNA 4.
  services.picom.backend = "xrender";
  services.picom.vSync = false;
}
