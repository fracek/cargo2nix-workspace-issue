# Rust + Nix playground

This repo is used to reproduce issues building Rust projects with Nix.

## Cross compilation

We try to cross compile crates from x86_64 to aarch64.
We do that by adding `-cross` packages, you can see a list of such packages
with `nix flake show`.

## Build with cargo

This works

 - `nix develop`
 - `cargo build`

# Build with nix

This doesn't work

 - `nix build`

