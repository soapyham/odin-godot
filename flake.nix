{
  description = "Development environment for Odin and Godot";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          default = pkgs.mkShell {
            packages = with pkgs; [
              odin
              ols       # Odin Language Server
              godot   # Godot 4 Engine

              # Build tools often required for Odin/GDExtension C bindings
              clang
              llvmPackages.bintools
            ];

            shellHook = ''
              echo "Odin and Godot development environment loaded."
              echo "Odin version: $(odin version)"
              echo "Godot version: $(godot4 --version)"
            '';
          };
        }
      );
    };
}
