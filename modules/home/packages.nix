{ flake, pkgs, lib, ... }:
let
  # `nixpkgs.*` options are disabled in home-manager when `useGlobalPkgs` is set,
  # so unfree packages come from their own nixpkgs instance.
  unfreePkgs = import flake.inputs.nixpkgs {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
      "claude-code"
    ];
  };
in
{
  # Nix packages to install to $HOME
  #
  # Search for packages here: https://search.nixos.org/packages
  home.packages = with pkgs; [
    omnix

    # Unix tools
    ripgrep # Better `grep`
    fd
    sd
    tree
    gnumake

    # Nix dev
    cachix
    nil # Nix language server
    nix-info
    nixpkgs-fmt


    # Cloud
    awscli2
    ssm-session-manager-plugin

    # On ubuntu, we need this less for `man home-configuration.nix`'s pager to
    # work.
    less
  ];

  # Programs natively supported by home-manager.
  # They can be configured in `programs.*` instead of using home.packages.
  programs = {
    # Better `cat`
    bat.enable = true;
    # Type `<ctrl> + r` to fuzzy search your shell history
    fzf.enable = true;
    jq.enable = true;
    # Install btop https://github.com/aristocratos/btop
    btop.enable = true;
    # Claude Code CLI https://github.com/anthropics/claude-code
    claude-code = {
      enable = true;
      package = unfreePkgs.claude-code;
    };
  };
}