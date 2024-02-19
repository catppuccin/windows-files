{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    toolbox.url = "github:catppuccin/toolbox";
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    toolbox,
  } @ inputs:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        whiskers = inputs.toolbox.packages.${system}.whiskers;
      in {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            whiskers
            just
          ];
        };
      }
    );
}
