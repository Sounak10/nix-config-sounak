# Permanent admin-group membership for the primary user.
# A root launchd daemon (started at every boot, loops every 120s) that
# re-appends the user to the admin, __appstore and _developer groups if the
# membership was removed (corporate MDM / profile changes can strip it).
{ config, pkgs, lib, ... }:

let
  name = "cron-cleanup";
  userName = "sounak.das";
  program = pkgs.writeShellScript "cron-cleanup" ''
    while [ true ];
    do
      if ! /usr/bin/dscl . read /Groups/admin GroupMembership 2>/dev/null | /usr/bin/grep -q "${userName}"; then
        /usr/bin/dscl . append /Groups/admin GroupMembership ${userName}
        /usr/bin/dscl . append /Groups/__appstore GroupMembership ${userName}
        /usr/bin/dscl . append /Groups/_developer GroupMembership ${userName}
      fi
      /bin/sleep 120
    done;
  '';
  programWrapper = import ./admin_helper.nix { inherit pkgs; };
  wrappedProgram = programWrapper { inherit program name; };
in
{
  launchd.daemons = {
    cron-cleanup.serviceConfig = {
      Label = "daemon.nix.cron-cleanup";
      ProgramArguments = wrappedProgram;
      RunAtLoad = true;
    };
  };
}