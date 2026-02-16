{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  nativeBuildInputs = with pkgs; [
    cmake
    pkg-config
    gcc
  ];

  buildInputs = with pkgs; [
    wayland
    wayland-scanner
    wayland-protocols
    libglvnd
    glm
    nlohmann_json
    jq
    inotify-tools
    libevdev
  ];

  shellHook = ''
    echo "Welcome to the shader-desk dev environment!"
  '';
}
