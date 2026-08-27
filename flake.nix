{
  description = "Clash Party, built from source with a reproducible Nix flake";

  inputs = {
    nixpkgs.url = "github:Melorise/nixpkgs/nixos-unstable";

    clash-party = {
      url = "github:mihomo-party-org/clash-party/v2.0.2";
      flake = false;
    };

    sysproxy = {
      url = "github:mihomo-party-org/sysproxy-rs-opti/main";
      flake = false;
    };

    country = {
      url = "file+https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/country-lite.mmdb";
      flake = false;
    };

    geoip = {
      url = "file+https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.dat";
      flake = false;
    };

    geosite = {
      url = "file+https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geosite.dat";
      flake = false;
    };

    metadb = {
      url = "file+https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/geoip.metadb";
      flake = false;
    };

    asn = {
      url = "file+https://github.com/MetaCubeX/meta-rules-dat/releases/download/latest/GeoLite2-ASN.mmdb";
      flake = false;
    };
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forEachSystem = nixpkgs.lib.genAttrs systems;
      mkPkgs =
        system:
        import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };
      mkPackage =
        system:
        let
          pkgs = mkPkgs system;
        in
        pkgs.callPackage ./nix/package.nix {
          src = inputs.clash-party;
          sysproxySrc = inputs.sysproxy;
          inherit (inputs)
            country
            geoip
            geosite
            metadb
            asn
            ;
          subStore = pkgs.sub-store;
          subStoreFrontend = pkgs.sub-store-frontend;
          notoFontsColorEmoji = pkgs.noto-fonts-color-emoji;
        };
    in
    {
      packages = forEachSystem (
        system:
        let
          package = mkPackage system;
        in
        {
          clash-party = package;
          default = package;
          inherit (package) sysproxy unwrapped;
        }
      );

      apps = forEachSystem (system: {
        clash-party = {
          type = "app";
          program = "${self.packages.${system}.clash-party}/bin/clash-party";
        };
        default = self.apps.${system}.clash-party;
      });

      nixosModules = {
        clash-party = import ./nix/module.nix { inherit self; };
        default = self.nixosModules.clash-party;
      };
    };
}
