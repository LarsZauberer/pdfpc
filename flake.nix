{
  description = "pdfpc: a presenter console with multi-monitor support for PDF files";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      # Tag the version with the commit so the fork is distinguishable from upstream
      releaseVersion = builtins.head (
        builtins.match "v([^\n]*).*" (builtins.readFile ./src/pdfpc.version)
      );
      version = "${releaseVersion}+${self.shortRev or self.dirtyShortRev or "dirty"}";

      # Build the fork from this checkout, reusing the nixpkgs recipe for dependencies
      mkPdfpc =
        pkgs:
        pkgs.pdfpc.overrideAttrs {
          inherit version;
          # Only the files CMake reads, so editing flake or docs does not trigger a rebuild
          src = pkgs.lib.fileset.toSource {
            root = ./.;
            fileset = pkgs.lib.fileset.unions [
              ./CMakeLists.txt
              ./LICENSE.txt
              ./cmake
              ./completions
              ./css
              ./icons
              ./man
              ./rc
              ./src
            ];
          };
        };
    in
    {
      overlays.default = _final: prev: { pdfpc = mkPdfpc prev; };
    }
    // flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        pdfpc = mkPdfpc pkgs;
      in
      {
        packages.default = pdfpc;

        devShells.default = pkgs.mkShell {
          name = "pdfpc-devShell";

          inputsFrom = [ pdfpc ];

          packages = [ pkgs.vala-language-server ];
        };

        formatter = pkgs.nixfmt;
      }
    );
}
