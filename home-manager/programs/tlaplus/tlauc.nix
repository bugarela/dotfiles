{ lib, fetchFromGitHub, rustPlatform, ... }:
rustPlatform.buildRustPackage rec {
  pname = "tlauc";
  version = "1.0.1";

  src = fetchFromGitHub {
    owner = "tlaplus-community";
    repo = pname;
    rev = version;
    hash = lib.fakeHash;
  };

  cargoHash = lib.fakeHash;

  meta = with lib; {
    description =
      "Rewrites TLA⁺ specs to use Unicode symbols instead of ASCII, and vice-versa ";
    homepage = "https://github.com/tlaplus-community/tlauc";
    license = licenses.mit;
    maintainers = [ ];
  };
}
