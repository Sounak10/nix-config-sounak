# GPG CLI, managed by home-manager
# https://nixos.asia/en/gpg
{ pkgs, ... }:
{
  programs.gpg.enable = true;

  # The gpg agent, for caching passphrase and ssh keys
  services.gpg-agent = {
    enable = true;
    # Cache passphrases for 1 hour
    defaultCacheTtl = 3600;
    maxCacheTtl = 3600;
    enableSshSupport = true;
    pinentry.package = pkgs.pinentry-curses;
  };
}