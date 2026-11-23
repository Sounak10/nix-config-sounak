# Declarative Homebrew via nix-homebrew + nix-darwin's `homebrew` module.
{ flake, config, lib, ... }:
let
  inherit (flake) inputs;
in
{
  imports = [
    inputs.nix-homebrew.darwinModules.nix-homebrew
  ];

  # Installs/owns the Homebrew prefix itself (/opt/homebrew)
  nix-homebrew = {
    enable = true;
    user = config.system.primaryUser;

    # Take over the already-existing Homebrew installation
    autoMigrate = true;

    # Taps are pinned via flake inputs; `brew tap` is disabled
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = false;
  };

  # Which packages Homebrew should have installed
  homebrew = {
    enable = true;

    # Keep nix-darwin's tap list in sync with nix-homebrew's
    taps = builtins.attrNames config.nix-homebrew.taps;

    brews = [ ];
    casks = [
      "pmg"
      "claude-code"
    ];

    onActivation = {
      autoUpdate = false;
      upgrade = false;
      # "none" leaves unlisted packages alone; switch to "zap" for full
      # declarative control (uninstalls anything not listed above).
      cleanup = "none";
    };
  };

  # nix-homebrew doesn't link brew's own zsh completion, and `brew completions
  # link` is a no-op under it. Link through Library/Homebrew (repointed by
  # nix-homebrew on each brew update) so it survives version bumps.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    mkdir -p ${config.homebrew.prefix}/share/zsh/site-functions
    ln -sfn ${config.homebrew.prefix}/Library/Homebrew/../../completions/zsh/_brew \
      ${config.homebrew.prefix}/share/zsh/site-functions/_brew
  '';

  # Prune the Homebrew download cache and old versions daily at 12:00.
  # launchd runs missed jobs on wake if the Mac was asleep.
  launchd.user.agents.brew-cleanup = {
    command = "${config.homebrew.prefix}/bin/brew cleanup --prune=all";
    serviceConfig = {
      StartCalendarInterval = [ { Hour = 12; Minute = 0; } ];
      EnvironmentVariables.HOMEBREW_NO_AUTO_UPDATE = "1";
      StandardOutPath = "/tmp/brew-cleanup.log";
      StandardErrorPath = "/tmp/brew-cleanup.log";
    };
  };
}
