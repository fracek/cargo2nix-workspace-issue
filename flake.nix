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

        aarch64Linux =
          let
            crossSystem = "aarch64-linux";
            crossPkgs = import nixpkgs {
              inherit overlays crossSystem;
              localSystem = system;
            };
          in
          pkgs.callPackage ./nix/cross.nix {
            inherit crane crossSystem;
            pkgs = crossPkgs;
            workspaceDir = ./.;
          };

        crosses = {
          "x86_64-linux" = aarch64Linux;
          "x86_64-darwin" = { packages = { }; };
          "aarch64-linux" = { packages = { }; };
          "aarch64-darwin" = { packages = { }; };
        };

        cross = crosses.${system};

      in
      {
        formatter = pkgs.nixpkgs-fmt;
        devShells = {
          default = native.shell;
          cross = cross.shell;
        };

        packages = (native.packages // cross.packages);
      }
    );
}
