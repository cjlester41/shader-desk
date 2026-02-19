{
  description = "Interactive wallpaper and evdev-pointer-daemon";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = pkgs.stdenv.mkDerivation {
          pname = "shader-desk";
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
            libGL
            # libegl-gles
            libevdev
            glm
            nlohmann_json
            libffi
            # sed
          ];

          # Matches CMake project name and target requirements [cite: 1]
          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
          ];
        };

        devShells.default = pkgs.mkShell {
          name = "shader-desk-dev";
          
          # Includes all tools needed for compilation 
          nativeBuildInputs = with pkgs; [
            cmake
            pkg-config
            wayland-scanner
            gdb
          ];

          # Libraries required by the project [cite: 15]
          buildInputs = with pkgs; [
            wayland
            wayland-protocols
            libGL
            # libegl-gles
            libevdev
            glm
            nlohmann_json
          ];

          shellHook = ''
            echo "Shader-desk development environment loaded."
            echo "Run 'cmake -B build && cmake --build build' to compile."
          '';
        };
      }
    );
}