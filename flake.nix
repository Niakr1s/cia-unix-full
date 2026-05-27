{
  description = "Cia unix full";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        additional = pkgs.stdenv.mkDerivation {
          pname = "cia-tools-additional";
          version = "0.1.3";
          src = ./.;

          installPhase = ''
            mkdir -p $out/{bin,lib}
            cp ctrdecrypt ctrtool makerom $out/bin/
            chmod +x $out/bin/*
            cp seeddb.bin $out/lib 
          '';
        };
      in
      {

        packages = {
          inherit additional;

          default = pkgs.writeShellScriptBin "cia-unix" ''

          '';
        };
      }
    );
}
