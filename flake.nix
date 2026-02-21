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
            libglvnd
            libevdev
            glm
            nlohmann_json
          ];

          # These flags prevent CMake from hardcoding the /build directory 
          cmakeFlags = [
            "-DCMAKE_BUILD_TYPE=Release"
            "-DCMAKE_SKIP_BUILD_RPATH=OFF" 
            "-DCMAKE_BUILD_WITH_INSTALL_RPATH=ON"
            "-DCMAKE_INSTALL_RPATH=$out/lib"
          ]; 

          installPhase = ''
            runHook preInstall
            
            # Create the output directories in the Nix store [cite: 6]
            mkdir -p $out/lib $out/bin $out/share/interactive-wallpaper
            
            if [ -d "effects" ]; then
                          cp -r effects $out/share/interactive-wallpaper/
                        fi

            # Copy all shared libraries (.so files) 
            find . -name "*.so*" -exec cp -t $out/lib {} +
            
            # Copy the executable(s) [cite: 7, 9]
            find . -maxdepth 1 -executable -type f -exec cp -t $out/bin {} +
            
            runHook postInstall
          '';
      
          # This is the 'magic' that removes the forbidden /build/ references [cite: 1]
          preFixup = ''
            find $out -type f -exec patchelf --shrink-rpath {} \;
          '';
        };

        # Create a shell script that runs the binary
        # This script can include environment variables or arguments if needed
        interactive-wall = pkgs.writeShellScriptBin "iwp" (builtins.readFile ./run.sh);

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