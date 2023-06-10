{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils = {
      url = "github:numtide/flake-utils";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    crane = {
      url = "github:ipetkov/crane";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, crane, ... }: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [
          (import rust-overlay)
          (import ./nix/overlay.nix)
        ];

        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustVersion = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" ];
        };

        craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;
        src = craneLib.cleanCargoSource (craneLib.path ./.);

        commonArgs = {
          inherit src;

          version = "0.0.0";
          pname = "mycrate-workspace";

          buildInputs = with pkgs; [
            librusty_v8
            libffi
          ];

          RUSTY_V8_ARCHIVE = "${pkgs.librusty_v8}/lib/librusty_v8.a";
        };

        cargoArtifacts = craneLib.buildDepsOnly commonArgs;

        mycrate =
          let
            manifest = craneLib.crateNameFromCargoToml {
              cargoToml = ./mycrate/Cargo.toml;
            };
          in
          craneLib.buildPackage (commonArgs // {
            inherit cargoArtifacts;
            inherit (manifest) pname version;
            cargoExtraArgs = "-p ${manifest.pname}";
        });
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            rustVersion
            librusty_v8
          ];

          RUSTY_V8_ARCHIVE = "${pkgs.librusty_v8}/lib/librusty_v8.a";
        };

        packages = {
          inherit cargoArtifacts;
          default = mycrate;
        };
      }
    );
}
