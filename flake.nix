{ ###
  description = "Nix flake for interactive-wallpaper with a custom runner script";

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
            libglvnd
            libevdev
            glm
            nlohmann_json
          ];

          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DCMAKE_SKIP_BUILD_RPATH=OFF"
            "-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON"
            "-DCMAKE_INSTALL_RPATH=$out/lib"
          ];

          installPhase = ''
            runHook preInstall
            
            # Create all necessary directories in the output
            mkdir -p $out/lib $out/bin $out/share/interactive-wallpaper
            
            # 1. Install Assets and Config
            if [ -d "effects" ]; then
              cp -r effects $out/share/interactive-wallpaper/
            fi
            cp $src/config.json $out/share/interactive-wallpaper/
            
            # 2. Install Shared Libraries
            find . -maxdepth 2 -name "*.so*" -exec cp -t $out/lib {} +
            
            # 3. Install the Compiled Binaries
            # This captures the executable(s) built by CMake
            find . -maxdepth 2 -executable -type f ! -name "*.so*" -exec cp -t $out/bin {} +
            
            # 4. Install the Runner Script
            # We copy your run.sh directly into the same bin folder as 'shader-desk'
            cp ${./run.sh} $out/bin/shader-desk
            chmod +x $out/bin/shader-desk
            
            cp ${./config-manager.sh} $out/bin/config-manager
            chmod +x $out/bin/config-manager
            
            runHook postInstall
          '';

          preFixup = ''
            find $out -type f -exec patchelf --shrink-rpath {} \;
          '';
        };

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
            jq
          ];
        };
      });
}