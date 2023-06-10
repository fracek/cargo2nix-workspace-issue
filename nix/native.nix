{ pkgs, crane, workspaceDir }:
let
  rustToolchain = pkgs.rust-bin.stable.latest.default.override {
    extensions = [ "rust-src" ];
  };

  buildLib = import ./build.nix { inherit pkgs crane rustToolchain workspaceDir; };
in
{
  shell = pkgs.mkShell (buildLib.buildArgs // { });
  packages = {
    mycrate = (buildLib.buildCrate { crate = ../mycrate; }).bin;
  };
}
