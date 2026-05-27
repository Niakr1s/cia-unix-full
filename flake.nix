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

        # The actual binaries package
        binaries = pkgs.stdenv.mkDerivation {
          name = "cia-binaries";
          src = ./.;
          installPhase = ''
            mkdir -p $out/bin
            cp cia-unix ctrdecrypt ctrtool makerom $out/bin/
            chmod +x $out/bin/*
          '';
        };
      in
      {

        packages.default = pkgs.symlinkJoin {
          name = "cia-tools";
          paths = [ binaries ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            # Wrap each binary to include our bin in PATH
            for bin in cia-unix ctrtool ctrdecrypt makerom; do
              if [ -f $out/bin/$bin ]; then
                wrapProgram $out/bin/$bin --prefix PATH : $out/bin
              fi
            done
          '';
        };
        # Package the binary files
        # packages.default = pkgs.stdenv.mkDerivation {
        #   pname = "cia-unix";
        #   version = "0.1.3";
        #
        #   src = ./.;
        #
        #   # Install binary files to appropriate locations
        #   installPhase = ''
        #     mkdir -p $out/bin
        #     cp cia-unix ctrdecrypt ctrtool makerom $out/bin/
        #     chmod +x $out/bin/*
        #   '';
        #
        #   # If binaries are for specific architecture
        #   meta = with pkgs.lib; {
        #     description = "Cia unix full";
        #     platforms = platforms.all;
        #   };
        #
        #   postInstall = ''
        #     # Only add to PATH, don't change directory
        #     wrapProgram $out/bin/cia-unix \
        #       --prefix PATH : $out/bin
        #
        #     # Also wrap other binaries if they need each other
        #     wrapProgram $out/bin/ctrtool \
        #       --prefix PATH : $out/bin 2>/dev/null || true
        #   '';
        #
        #   # Add a wrapper that includes PATH to all binaries
        #   # buildInputs = [ pkgs.makeWrapper ];
        #   # postFixup = ''
        #   #   # Wrap the binary to include PATH to its own directory
        #   #   wrapProgram $out/bin/cia-unix \
        #   #     --prefix PATH : $out/bin
        #   # '';
        # };
      }
    );
}
