{ lib, stdenv, cmake }:

stdenv.mkDerivation {
  pname = "your-project-name";
  version = "1.0";

  src = ./.; # Points to your local source directory

  nativeBuildInputs = [ cmake ];

  # The standard Nix CMake setup hook handles the configure, build, and install phases
  # automatically, so you often don't need to define them explicitly.
  # If you need custom steps, you can override specific phases like buildPhase or installPhase.
}