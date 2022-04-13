{
    description = "reload program when file changes detected";

    inputs.flake-utils.url = "github:numtide/flake-utils";

    outputs = { self, nixpkgs, flake-utils }:
      flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          my-name = "reloader";
          my-build-inputs = with pkgs; [ fswatch ];
          my-src = builtins.readFile ./reloader.sh;
          my-script = (pkgs.writeShellScriptBin my-name my-src).overrideAttrs(old: {
            buildCommand = "${old.buildCommand}\n patchShebangs $out";
          });
        in rec {
          defaultPackage = packages.my-script;
          packages.my-script = pkgs.symlinkJoin {
            name = my-name;
            paths = [ my-script ] ++ my-build-inputs;
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = "wrapProgram $out/bin/${my-name} --prefix PATH : $out/bin";
          };
        }
    );
}
