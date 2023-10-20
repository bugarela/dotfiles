sudo mkdir -p /mnt/etc/nixos
sudo rm /etc/nixos/configuration.nix
sudo rm /etc/nixos/cachix.nix
sudo rm /etc/nixos/hardware-configuration.nix
sudo ln -s /home/gabriela/nix-configs/nixos/configuration.nix /etc/nixos/
sudo nixos-rebuild switch

mkdir -p /home/gabriela/.config/nixpkgs
sudo nix-channel --add https://channels.nixos.org/nixpkgs-unstable/ nixpkgs-unstable
sudo nix-channel --update
ln -s /home/gabriela/nix-configs/home-manager/home.nix /home/gabriela/.config/nixpkgs/home.nix
ln -s /home/gabriela/nix-configs/home-manager/config.nix /home/gabriela/.config/nixpkgs/config.nix
home-manager switch
