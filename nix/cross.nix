{ pkgs, crane, workspaceDir, crossSystem }:
let
  rustToolchain = pkgs.pkgsBuildHost.rust-bin.stable.latest.default.override {
    targets = [ "aarch64-unknown-linux-gnu" ];
  };

  envVariables = {
    CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER = "${pkgs.stdenv.cc}/bin/${pkgs.stdenv.cc.targetPrefix}cc";
    HOST_CC = "${pkgs.stdenv.cc.nativePrefix}cc";
    CARGO_BUILD_TARGET = "aarch64-unknown-linux-gnu";
  };

  buildLib = import ./build.nix {
    inherit pkgs crane rustToolchain workspaceDir;
    extraBuildArgs = (envVariables // {
      # Set C flags for Rust's bindgen program. Unlike ordinary C compilation,
      # bindgen does not invoke $CC directly. Instead it uses LLVM's libclang. To
      # make sure all necessary flags are included we need to look in a few
      # places.
      preBuild =
        let
          inherit (pkgs) stdenv lib;
        in
        ''
          export BINDGEN_EXTRA_CLANG_ARGS="
            $(< ${stdenv.cc}/nix-support/libc-crt1-cflags) \
            $(< ${stdenv.cc}/nix-support/libc-cflags) \
            $(< ${stdenv.cc}/nix-support/cc-cflags) \
            $(< ${stdenv.cc}/nix-support/libcxx-cxxflags) \
            ${lib.optionalString stdenv.cc.isClang "-idirafter ${stdenv.cc.cc}/lib/clang/${lib.getVersion stdenv.cc.cc}/include"} \
            ${lib.optionalString stdenv.cc.isGNU "-isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc} -isystem ${stdenv.cc.cc}/include/c++/${lib.getVersion stdenv.cc.cc}/${stdenv.hostPlatform.config} -idirafter ${stdenv.cc.cc}/lib/gcc/${stdenv.hostPlatform.config}/${lib.getVersion stdenv.cc.cc}/include"}
          "
        '';
    });
  };
in
{
  shell = pkgs.mkShell (buildLib.buildArgs // envVariables);

  packages = {
    mycrate-cross = (buildLib.buildCrate { crate = ../mycrate; }).bin;
  };
}
