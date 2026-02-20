{
  description = "Nix flake for interactive-wallpaper with a custom runner script";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        
        # Define the main application package
        interactive-wallpaper-pkg = pkgs.stdenv.mkDerivation {
          pname = "interactive-wallpaper";
          version = "0.1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
            wayland-scanner
          ];

          buildInputs = with pkgs; [
            wayland
            wayland-protocols
            libglvnd # Provides EGL and GLESv2
            libevdev
            glm
            nlohmann_json
          ];

          # CMake configuration based on your CMakeLists.txt [cite: 1]
          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
          ];
        };

        # Create a shell script that runs the binary
        # This script can include environment variables or arguments if needed
        interactive-wall = pkgs.writeShellScriptBin "interactive-wall" (builtins.readFile ./run.sh);

      in
      {
        # The default package includes the original binary AND the runner script
        packages.default = pkgs.symlinkJoin {
          name = "interactive-wall";
          paths = [ interactive-wallpaper-pkg interactive-wall ];
        };

        # Development shell for local building
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            cmake
            pkg-config
            wayland
            wayland-protocols
            libglvnd
            libevdev
            glm
            nlohmann_json
            wayland-scanner
          ];
        };
      });
}