/*       .             .'|.                   ..|''||    .|'''.|
 ....  .||.    ....  .||.    ....   .. ...   .|'    ||   ||..  '
||. '   ||   .|...||  ||    '' .||   ||  ||  ||      ||   ''|||.
. '|..  ||   ||       ||    .|' ||   ||  ||  '|.     || .     '||
|'..|'  '|.'  '|...' .||.   '|..'|' .||. ||.  ''|...|'  |'....|'
stefanOS v0.0 Howling Hyrax 2025-10-25

This is your SYSTEM/host level nix config
It should be present at `~/nix-config/hosts/howlinghyrax.nix`
Installs NVIDIA proprietary GPU driver
*/

{ config, pkgs, lib, ... }:

{
  #--- FONTS ---#
    fonts = {
    enableDefaultPackages = false;
    packages = with pkgs; [
      corefonts dejavu_fonts gyre-fonts liberation_ttf unifont noto-fonts-emoji
      figlet cozette dina-font
      nerd-fonts.iosevka-term nerd-fonts.zed-mono nerd-fonts.meslo-lg
    ];
  };

  #--- NIXOS CONFIG ---#
  nixpkgs.config.allowUnfree = true;
  # services.mullvad-vpn.enable = true;
  imports = [
    ../hardware-configuration.nix
  ];

  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/nvme0n1";
  boot.loader.grub.useOSProber = true;
  services.xserver.enable = true;
  services.displayManager.ly.enable = true; # displayManager
  services.displayManager.ly.settings = {
    theme = "ColorMix";    # not effective ?????????? TODO: FIX
    };
  networking.hostName = "howlinghyrax";
  swapDevices = [
    {
      device = "/swapfile";
      size = 8192; # MBs
            }
          ];
 # services.displayManager.sddm.enable = true;
 # services.displayManager.sddm.wayland.enable = true;
 # services.xserver.displayManager.startx.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.defaultSession = "plasma";

  #--- STEAM ---#
  programs.steam = {
  enable = true;
  remotePlay.openFirewall = true;
  dedicatedServer.openFirewall = true;
  localNetworkGameTransfers.openFirewall = true;
  };

  #--- USERS ---#
  programs.zsh.enable = true;
  users.users.stefan = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [ "wheel" ];  # for sudo privledge
  };


  #--- SYS PKGS ---#
  environment.systemPackages = with pkgs; [
    #docker
    nano                    # text editor (terminal)
    vim                     # an advanced text editor (terminal)
    retroarchFull           # Add for N64 emulation (or use mupen64plus)
    steam protonup-qt       # steam and WIN compatibilty layer
    wineWowPackages.stable  # Wine Is Not An Emulator (for running windows software)
    winetricks              # For additional Wine configuration

    #-- KDE/PLASMA --#
    /* KDE is your desktop environment */
    kdePackages.sddm kdePackages.partitionmanager kdePackages.plasma-workspace qt6.qtbase qt6.qtwayland
    #noip                    # noip DDNS update daemon
    #jellyfin jellyfin-web jellyfin-ffmpeg
    #virtualbox              # VM
    #vnstat                  # network usage monitor
    # vmware-workstation
  ];

  #--- NVIDIA ---#
  /* proprietary GPU driver */
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
  };
  hardware.graphics.enable = true;


  #--- NETWORK ---#
  networking.networkmanager.enable = true;
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 80 443 8000 53 5300 ];
    allowedUDPPorts = [ 53 5300 ];
  };

  boot.kernel.sysctl = {
    "net.ipv4.conf.eth0.forwarding" = 1;    # enable port forwarding
  };

  networking = {
    firewall.extraCommands = ''
      iptables -A PREROUTING -t nat -i eth0 -p TCP --dport 80 -j REDIRECT --to-port 8000
      iptables -A PREROUTING -t nat -i eth0 -p TCP --dport 53 -j REDIRECT --to-port 5300
      iptables -A PREROUTING -t nat -i eth0 -p UDP --dport 53 -j REDIRECT --to-port 5300
    '';
  };

  #--- AUDIO ---#
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  #--- MISC ---#
  nix.extraOptions = "experimental-features = nix-command flakes";
  system.stateVersion = "23.11";
}
