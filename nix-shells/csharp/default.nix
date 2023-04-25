with (import <nixpkgs> {});
let
  shell = mkShell {
    name = "csharp-env";
    buildInputs = [
      pkgs.dotnetPackages.NUnit3
      pkgs.dotnetPackages.NUnit2
      pkgs.dotnetPackages.NUnitConsole
      pkgs.dotnetPackages.StyleCopMSBuild
      pkgs.dotnetPackages.StyleCopPlusMSBuild
      pkgs.dotnetPackages.Boogie
      pkgs.dotnetPackages.Dafny
      pkgs.dotnetPackages.Nuget
      pkgs.dotnetPackages.Paket
      pkgs.omnisharp-roslyn
      (with dotnetCorePackages; combinePackages [
        sdk_5_0
        sdk_3_1
        sdk_3_0
        sdk_2_1
      ])
    ];
  };
in
shell
