{ lib, stdenv, fetchFromGitHub, nodejs, rustPlatform, makeWrapper, jre, fetchurl, buildNpmPackage, pkgs }:

let
  quintVersion = "0.24.0";
  apalacheVersion = "0.47.2";
  evaluatorVersion = "0.1.0";

  quintSrc = fetchFromGitHub {
    owner = "informalsystems";
    repo = "quint";
    # rev = "v${quintVersion}";
    # FIXME: Using a temp revision now that has Cargo.lock and QUINT_HOME
    rev = "879a91d04428eaeb9975bad1696a98db7d8c599f";
    sha256 = "sha256-VZqu009otqgrOwU7l4LS8yHxeDI2/+JKAL+9L96j9/s=";
    fetchSubmodules = true;
  };

  # Build the Quint CLI from source
  quintCLI = buildNpmPackage {
    name = "Quint CLI";

    buildInputs = with pkgs; [
      nodejs_18
    ];

    src = "${quintSrc}/quint";
    npmDepsHash = "sha256-3IX0OeM9V+33kIDjjOSeIHVjpmGloeH++6xnz2msCQk=";
    npmBuildScript = "compile";

    # dontNpmBuild = true;
    dontNpmPrune = true;
    installPhase = ''
      mkdir -p $out/share/quint
      cp -r node_modules $out/share/quint/
      cp -r dist $out/share/quint/
    '';
  };

  # Build the Rust evaluator from source
  rustEvaluator = rustPlatform.buildRustPackage {
    pname = "quint-evaluator";
    version = evaluatorVersion;
    src = "${quintSrc}/evaluator";

    # Skip tests during build, as many rust tests rely on the Quint CLI
    doCheck = false;

    useFetchCargoVendor = true;
    cargoHash = "sha256-KxJTfG9ptS+jU/QicM/dx5kMZaBQ/JzR7kSpzxhrNBU="; 
  };

  # Download Apalache. It runs on the JVM, so no need to build it from source.
  apalacheDist = fetchurl {
    url = "https://github.com/apalache-mc/apalache/releases/download/v${apalacheVersion}/apalache.tgz";
    sha256 = "sha256-2uQlLspS+8UXz3uwJEv768thXqpcmDPCff3WMCXqI6o=";
  };

in stdenv.mkDerivation rec {
  pname = "quint";
  version = quintVersion;

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ jre ];

  src = quintSrc;

  # Disable standard build phases
  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    # Create executable wrapper for the CLI
    makeWrapper ${nodejs}/bin/node $out/bin/quint \
      --add-flags "${quintCLI}/share/quint/dist/src/cli.js" \
      --set QUINT_HOME "$out/.quint" \
      --prefix PATH : ${lib.makeBinPath [ jre ]}

    # Install evaluator
    mkdir -p $out/.quint/rust-evaluator-v${evaluatorVersion}
    install -Dm755 ${rustEvaluator}/bin/quint_evaluator $out/.quint/rust-evaluator-v${evaluatorVersion}/

    # Install Apalache
    mkdir -p $out/.quint/apalache-dist-${apalacheVersion}
    tar xzf ${apalacheDist} -C $out/.quint/apalache-dist-${apalacheVersion}
    chmod +x $out/.quint/apalache-dist-${apalacheVersion}/apalache/bin/apalache-mc

    runHook postInstall
  '';

  meta = with lib; {
    description = "A modern executable specification language based on TLA+";
    homepage = "https://quint-lang.org";
    license = licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = [ bugarela ];
  };
}
