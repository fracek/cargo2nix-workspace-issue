{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    flake-utils.url = "github:numtide/flake-utils";
    cargo2nix.url = "github:cargo2nix/cargo2nix/unstable";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, cargo2nix, ... }: 
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [
          cargo2nix.overlays.default
          (import rust-overlay)
        ];

        pkgs = import nixpkgs {
          inherit system overlays;
        };

        rustVersion = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" ];
        };

        rustPkgs = pkgs.rustBuilder.makePackageSet {
          packageFun = import ./Cargo.nix;
          rustToolchain = rustVersion;
        };
      in
      {
        devShells.default = rustPkgs.workspaceShell {
        };

        packages.default = rustPkgs.workspace.mycrate { };
      }
    );
}
