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

  hardware.firmware = with pkgs; [
    (linux-firmware.overrideAttrs (old: {
      src = builtins.fetchGit {
        url = "https://git.kernel.org/pub/scm/linux/kernel/git/firmware/linux-firmware.git";
        # rev = "de78f0aaafb96b3a47c92e9a47485a9509c51093"; # --impure gets the latest
      };
    }))
  ];

  # Xserver basic
  services.xserver = {
    dpi = 160;
    videoDrivers = [ "amdgpu" ];
    deviceSection = ''Option "TearFree" "true"'';
  };

  hardware.amdgpu = {
    amdvlk = {
      enable = true;
      support32Bit.enable = true;
    };
    opencl.enable = true;  
  };

  services.picom.vSync = true;

  hardware.xpadneo.enable = true;
}
