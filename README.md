# Cargo2nix + Workspaces

This repo tries to use cargo workspace dependencies and packages with cargo2nix.

## Build with cargo

This works

 - `nix develop`
 - `cargo build`

# Build with nix

This doesn't work

 - `nix build`

Looks like the root manifest is missing

```txt
mycrate-0.1.0.drv
@nix { "action": "setPhase", "phase": "unpackPhase" }
unpacking sources
unpacking source archive /nix/store/68x7iz3qxvcl6m8jvzhw06whzmw9hq5p-mycrate
source root is mycrate
@nix { "action": "setPhase", "phase": "patchPhase" }
patching sources
@nix { "action": "setPhase", "phase": "configurePhase" }
configuring
error: failed to parse manifest at `/build/mycrate/Cargo.toml`

Caused by:
  error inheriting `edition` from workspace root manifest's `workspace.package.edition`

Caused by:
  failed to find a workspace root
error: failed to parse manifest at `/build/mycrate/Cargo.toml`

Caused by:
  error inheriting `edition` from workspace root manifest's `workspace.package.edition`

Caused by:
  failed to find a workspace root
/nix/store/pgf87rgkzdbqhhsddpligy8xiwar63w8-stdenv-linux/setup: line 123: [: !=: unary operator expected
@nix { "action": "setPhase", "phase": "buildPhase" }
building
error: failed to parse manifest at `/build/mycrate/Cargo.toml`

Caused by:
  error inheriting `edition` from workspace root manifest's `workspace.package.edition`

Caused by:
  failed to find a workspace root
/nix/store/pgf87rgkzdbqhhsddpligy8xiwar63w8-stdenv-linux/setup: line 136: pop_var_context: head of shell_variab>
```
