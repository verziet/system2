{ pkgs, settings, ... }:
{
  environment.systemPackages = with pkgs; [
    neofetch
  ];

  time.timeZone = "${settings.timezone}";
}
