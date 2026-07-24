{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.clash-party;
  system = pkgs.stdenv.hostPlatform.system;
  package = cfg.package.override {
    commandLineArgs = cfg.extraArgs;
  };
in
{
  options.programs.clash-party = {
    enable = lib.mkEnableOption "Clash Party";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${system}.clash-party;
      defaultText = lib.literalExpression "clash-party-flake.packages.${system}.clash-party";
      description = "Clash Party package to install.";
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Start Clash Party automatically in graphical sessions.";
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "--ozone-platform-hint=auto" ];
      description = "Additional command-line arguments passed to Electron.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ package ];

    security.wrappers.clash-party-mihomo = {
      source = lib.getExe package.mihomo;
      owner = "root";
      group = "root";
      capabilities = "cap_net_admin,cap_net_raw,cap_net_bind_service=+ep";
    };

    environment.etc."xdg/autostart/clash-party.desktop" = lib.mkIf cfg.autoStart {
      source = "${package}/share/applications/clash-party.desktop";
    };
  };
}
