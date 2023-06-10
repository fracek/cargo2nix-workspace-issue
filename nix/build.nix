{ pkgs, crane, rustToolchain, workspaceDir, extraBuildArgs ? { } }:
let
  craneLib = (crane.mkLib pkgs).overrideToolchain rustToolchain;
in
rec {
  inherit (craneLib) buildPackage;

  src = pkgs.lib.cleanSourceWith {
    src = craneLib.path workspaceDir; # all sources
    filter = path: type:
      (builtins.match ".*proto$" path != null) # include protobufs
      || (builtins.match ".*js$" path != null) # include js (for deno runtime)
      || (craneLib.filterCargoSources path type); # include rust/cargo
  };

  buildArgs = ({
    nativeBuildInputs = with pkgs.pkgsBuildHost; [
      clang
      llvmPackages.libclang.lib
      pkg-config
      protobuf
      rustToolchain
    ] ++ pkgs.lib.optional stdenv.isDarwin (with pkgs.darwin.apple_sdk.frameworks; [
      CoreFoundation
      CoreServices
      Security
    ]);

    buildInputs = with pkgs.pkgsHostHost; [
      librusty_v8
    ];

    RUSTY_V8_ARCHIVE = "${pkgs.pkgsHostHost.librusty_v8}/lib/librusty_v8.a";
    # used by bindgen
    LIBCLANG_PATH = pkgs.lib.makeLibraryPath [
      pkgs.pkgsBuildHost.llvmPackages.libclang.lib
    ];
  } // extraBuildArgs);

  commonArgs = (buildArgs // {
    inherit src;
  });

  cargoArtifacts = craneLib.buildDepsOnly (commonArgs // {
    pname = "my-crate";
    version = "0.0.0";
  });

  buildCrate = { crate }:
    let
      manifest = builtins.fromTOML (builtins.readFile (crate + "/Cargo.toml"));
      pname = manifest.package.name;
      version = manifest.package.version;
      bin = craneLib.buildPackage (commonArgs // {
        inherit pname version cargoArtifacts;

        cargoExtraArgs = "--package ${pname}";
        doCheck = false;
      });
    in
    {
      inherit pname version bin;
    };
}

