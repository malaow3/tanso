{ pkgs ? import <nixpkgs> {} }:

let
  unstableTarball =
    fetchTarball
      https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz;
  unstable = import unstableTarball { };
in
pkgs.mkShell {
  buildInputs = with unstable; [
    pkg-config
   unstable.zig
    pnpm
  ];
  shellHook = ''
    export PKG_CONFIG_PATH="${unstable.pkg-config}/lib/pkgconfig:$PKG_CONFIG_PATH"
  '';
}
