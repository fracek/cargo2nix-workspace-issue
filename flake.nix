{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils = {
      url = "github:numtide/flake-utils";
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
        overlays = [(import rust-overlay)];

        pkgs = import nixpkgs {
          inherit system overlays;
        };

        inherit (pkgs) lib;

        rustVersion = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" ];
        };

        craneLib = (crane.mkLib pkgs).overrideToolchain rustVersion;
        src = craneLib.cleanCargoSource (craneLib.path ./.);

        commonArgs = {
          inherit src;

          version = "0.0.0";
          pname = "mycrate-workspace";

          buildInputs = [];
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
            cargoExtraArgs = "-p mycrate";
        });
      in
      {
        packages = {
          default = mycrate;
        };
      }
    );
}
