{ pkgs ? import <nixpkgs> { } }:
pkgs.rustPlatform.buildRustPackage rec {
  pname = "wiremix";
  version = "v0.1.1";

  nativeBuildInputs = [
    # pkgs.rust
    pkgs.pkg-config
    pkgs.clang
  ];

  buildInputs = [
    pkgs.pipewire
  ];

  LIBCLANG_PATH = "${pkgs.llvmPackages.libclang.lib}/lib";

  src = pkgs.fetchFromGitHub {
    owner = "tsowell";
    repo = pname;
    rev = version;
    hash = "sha256-AjF65hpnpRQqhMUdQ+eAaajegwg9uG1sTLhYozWXN8c=";
  };

  cargoHash = "sha256-3zQ1lKdtmYRy84+Jg878QToUqqMVZ1hAer8i5a2ItCg=";

  meta = with pkgs.lib; {
    description =
      "A simple TUI audio mixer for PipeWire ";
    homepage = "https://github.com/tsowell/wiremix";
    license = licenses.mit;
    maintainers = [ ];
  };
}
