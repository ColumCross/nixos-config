{ config, lib, pkgs, profile, ... }:

let
  mailRoot = "${profile.homeDirectory}/Mail";
  stateRoot = "${profile.homeDirectory}/.local/state/mail";
  mail-configure = pkgs.writeShellApplication {
    name = "mail-configure";
    runtimeInputs = [ pkgs.python3 ];
    text = ''
      exec python3 ${../mail/bin/mail-configure.py}
    '';
  };
  mail-refresh-folders = pkgs.writeShellApplication {
    name = "mail-refresh-folders";
    runtimeInputs = [ pkgs.lieer pkgs.python3 ];
    text = ''
      exec python3 ${../mail/bin/mail-refresh-folders.py} "$@"
    '';
  };
  mail-setup = pkgs.writeShellApplication {
    name = "mail-setup";
    runtimeInputs = [ pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.lieer pkgs.notmuch pkgs.python3 pkgs.util-linux mail-refresh-folders ];
    text = builtins.readFile ../mail/bin/mail-setup.sh;
  };
  mail-sync = pkgs.writeShellApplication {
    name = "mail-sync";
    runtimeInputs = [ pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.lieer pkgs.notmuch pkgs.util-linux mail-refresh-folders ];
    text = builtins.readFile ../mail/bin/mail-sync.sh;
  };
  mail-status = pkgs.writeShellApplication {
    name = "mail-status";
    runtimeInputs = [ pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.notmuch ];
    text = builtins.readFile ../mail/bin/mail-status.sh;
  };
  mail-tag-local = pkgs.writeShellApplication {
    name = "mail-tag-local";
    runtimeInputs = [ pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.notmuch ];
    text = builtins.readFile ../mail/bin/mail-tag-local.sh;
  };
  mail-send = pkgs.writeShellApplication {
    name = "mail-send";
    runtimeInputs = [ pkgs.coreutils pkgs.gawk pkgs.gnugrep pkgs.lieer ];
    text = builtins.readFile ../mail/bin/mail-send.sh;
  };
  mail-assistant = pkgs.writeShellApplication {
    name = "mail-assistant";
    runtimeInputs = [ pkgs.opencode ];
    text = builtins.readFile ../mail/bin/mail-assistant.sh;
  };
in
{
  home.packages = [ pkgs.w3m mail-configure mail-refresh-folders mail-setup mail-sync mail-status mail-tag-local mail-send mail-assistant ];

  home.file = {
    "Mail/AGENTS.md".source = ../mail/AGENTS.md;
    "Mail/opencode.json".source = ../mail/opencode.json;
    "Mail/.opencode/agents/email.md".source = ../mail/.opencode/agents/email.md;
    "Mail/.opencode/tools/mail.ts".text = builtins.replaceStrings
      [ "\"@opencode-ai/plugin\"" ]
      [ "\"${mailRoot}/.opencode/node_modules/@opencode-ai/plugin/dist/tool.js\"" ]
      (builtins.readFile ../mail/.opencode/tools/mail.ts);
  };

  home.activation.mailDirectories = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${mailRoot}/notes ${stateRoot}/credentials ${stateRoot}/initialized ${stateRoot}/status ${stateRoot}/locks
    $DRY_RUN_CMD ${pkgs.coreutils}/bin/chmod 700 ${mailRoot} ${mailRoot}/notes ${stateRoot} ${stateRoot}/credentials ${stateRoot}/initialized ${stateRoot}/status ${stateRoot}/locks
  '';

  home.activation.mailConfiguration = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    $DRY_RUN_CMD ${mail-configure}/bin/mail-configure
  '';

  systemd.user.services.mail-sync = {
    Unit = {
      Description = "Synchronize configured Gmail accounts with Lieer";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${mail-sync}/bin/mail-sync all";
      TimeoutStartSec = "30min";
      UMask = "0077";
    };
  };

  systemd.user.timers.mail-sync = {
    Unit.Description = "Schedule Gmail synchronization";
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "5min";
      Persistent = false;
      Unit = "mail-sync.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };
}
