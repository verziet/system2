# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).
{
  pkgs,
  lib,
  config,
  inputs,
  settings,
  ...
}: {
  imports = [
    ./${settings.hostname}/hardware-configuration.nix # Generated hardware configuration
    ./${settings.hostname}/configuration.nix # Host specific configuration
  ];

  # Bootloader/grub configuration
  boot.loader = {
    timeout = 20;
    efi.canTouchEfiVariables = true;

    grub = {
      enable = true;
      useOSProber = true;
      efiSupport = true;
      devices = ["nodev"];

      backgroundColor = "#00000";
      splashImage = null;
    };
  };

  networking.hostName = "${settings.hostname}"; # Define hostname
  networking.networkmanager.enable = true; # Network manager

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  services.kanata.enable = true;
  # Setting up the uinput group, required for kanata
  services.udev.extraRules = ''
    KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
  '';


  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    channel.enable = false; # No point in using channels with flakes enabled

    settings = {
      experimental-features = ["flakes" "nix-command"]; # Enable flakes and nix commmands
      # nix-path = config.nix.nixPath;
      # flake-registry = null;
    };

    #registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
    #nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    # TODO learn more about nixpath and registries, wont touch them for now
  };

  time.timeZone = "${settings.timezone}"; # Set timezone

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  i18n.defaultLocale = "${settings.locale}"; # Set locale
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  # services.xserver.enable = true;

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Audio/pipewire configuration
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    audio.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  services.libinput.enable = true; # Touchpad support

  # Automatic login for the user on tty1
  systemd.services."getty@tty1" = {
    overrideStrategy = "asDropin";
    serviceConfig.ExecStart = ["" "@${pkgs.util-linux}/sbin/agetty agetty --login-program ${config.services.getty.loginProgram} --autologin ${settings.username} --noclear --keep-baud %I 115200,38400,9600 $TERM"];
  };

  # Creating groups
  users.groups.uinput = {};

  # Default user account configuration
  users.users.${settings.username} = {
    shell = pkgs.zsh;
    initialPassword = "${settings.username}"; # Initial password set to username
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "audio" "input" "uinput"]; # Groups
  };

  # System packages
  environment.systemPackages = with pkgs; [
    # Essentials
    home-manager
    git
    htop
    fzf

    # Basic text editors
    nano
    vim
    emacs-nox

    # Desktop manager
    hyprland
    gnome-control-center # Easy wifi connection
    pavucontrol # Easy sound control
    kitty
    wofi

    # Nix utilities
    nh
    nix-output-monitor
    nvd
    alejandra
  ];

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # force electron apps to use Wayland, fractional scaling
    FLAKE = "${settings.flakePath}"; # flake.nix path for nix helper
  };

  programs.hyprland.enable = true; # Enable Hyprland
  programs.zsh.enable = true; # Enable Zsh

  xdg.portal.enable = true;
  #xdg.portal.config.common.default = "*"; # temp fix later change
  xdg.portal.extraPortals = with inputs.nixpkgs.legacyPackages.${settings.system}; [
    xdg-desktop-portal-gtk
  ];

  services.xserver.enable = true;
  services.xserver.displayManager.startx.enable = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "${settings.stateVersion}"; # Did you read the comment?
}
