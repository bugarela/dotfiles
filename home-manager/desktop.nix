{ pkgs, inputs, ... }: {
  imports = [ ./common.nix ];

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
