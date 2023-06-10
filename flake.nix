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

        native = pkgs.callPackage ./nix/native.nix {
          inherit crane pkgs;
          workspaceDir = ./.;
        };
      in
      {
        devShells.default = native.shell;

        packages = native.packages;
      }
    );
}
