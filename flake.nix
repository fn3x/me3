{
  description = "me3 — a modding framework for FROMSOFTWARE games";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };

        me3 = pkgs.callPackage ./package.nix { };
      in
      {
        packages = {
          default = me3;
          inherit me3;
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            rustup
            pkgsCross.mingwW64.stdenv.cc
            pkgsCross.mingwW64.buildPackages.binutils
            taplo
            cargo-release
            pre-commit
          ];

          shellHook = ''
            rustup target add x86_64-unknown-linux-gnu x86_64-pc-windows-gnu
            echo "me3 dev shell ready"
            echo "  native:  cargo build --package me3-cli"
            echo "  windows: CARGO_BUILD_TARGET=x86_64-pc-windows-gnu \\"
            echo "             cargo build --package me3-launcher --package me3-mod-host"
          '';
        };
      });
}
