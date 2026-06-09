{
  description = "Cia unix full";

  inputs.nixpkgs.url = "nixpkgs/nixos-26.05";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      lib = nixpkgs.lib;
      mkPkgs = system: nixpkgs.legacyPackages.${system};
      eachSupportedSystem = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      packages = eachSupportedSystem (
        system:
        let
          pkgs = mkPkgs system;
          libcia = self.packages.${system}.libcia;
        in
        {
          default = pkgs.stdenv.mkDerivation {
            name = "cia-unix";
            version = "0.1.3";
            src = ./.; # or ./src

            nativeBuildInputs = with pkgs; [
              makeWrapper
            ];

            buildInputs = with pkgs; [
              crystal
              libcia
            ];

            buildPhase = ''
              crystal build cia-unix.cr
            '';

            installPhase = ''
              mkdir -p $out/bin
              mv cia-unix $out/bin/

              wrapProgram $out/bin/cia-unix \
                --prefix PATH : ${libcia}/bin \
                --prefix PATH : ${libcia}/lib
            '';


            meta.mainProgram = "cia-unix"; # name of an executable file in $out/bin
          };

          libcia = pkgs.stdenv.mkDerivation {
            pname = "libcia";
            version = "0.1.3";
            src = ./.;

            installPhase = ''
              mkdir -p $out/{bin,lib}
              cp ctrdecrypt ctrtool makerom $out/bin/
              chmod +x $out/bin/*
              cp seeddb.bin $out/lib
            '';
          };
        }
      );
    };
}
