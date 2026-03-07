{
  fetchFromGitHub,
  lib,
  makeWrapper,
  pkgsCross,
  rustPlatform,
  symlinkJoin,
}:

let
  version = "0.11.0";

  src = fetchFromGitHub {
    owner = "garyttierney";
    repo = "me3";
    rev = "v${version}";
    sha256 = "sha256-XyeMVPGzNF2syipLz9HPtUg7lhxcEq434FnRH3Ax+HM=";
  };

  cargoHash = "sha256-T1HeYe9FUC5oy/SDeEd6vV4D9YIGIXMkbzf43gRNyt8=";

  me3-cli = rustPlatform.buildRustPackage (final: {
    inherit cargoHash version src;
    pname = "me3-cli";

    cargoBuildFlags = [
      "--package"
      "me3-cli"
    ];

    cargoTestFlags = final.cargoBuildFlags;

    postInstall = ''
      install -Dm644 ${final.src}/distribution/linux/me3-launch.desktop \
        $out/share/applications/me3-launch.desktop
      install -Dm644 ${final.src}/distribution/linux/me3.xml \
        $out/share/mime/packages/me3.xml
      install -Dm644 ${final.src}/distribution/assets/me3.png \
        $out/share/icons/hicolor/128x128/apps/me3.png
    '';
  });

  me3-windows = pkgsCross.mingwW64.rustPlatform.buildRustPackage (final: {
    inherit cargoHash version src;
    pname = "me3-windows";

    RUSTC_BOOTSTRAP = 1;

    # Call SetDllDirectoryW in the game process before LoadLibraryW so
    # the bundled GCC runtime DLLs are found during DLL injection.
    patches = [ ./set-dll-directory.patch ];

    CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS = "-Clink-arg=-lmcfgthread";

    cargoBuildFlags = [
      "--package"
      "me3-launcher"
      "--package"
      "me3-mod-host"
    ];

    cargoTestFlags = final.cargoBuildFlags;
  });
in
symlinkJoin {
  inherit version;
  name = "me3";

  paths = [
    me3-cli
    me3-windows
  ];

  nativeBuildInputs = [ makeWrapper ];

  postBuild = ''
    # Wrap the binary so --windows-binaries-dir always points at the
    # correct absolute store path
    wrapProgram $out/bin/me3 \
      --add-flags "--windows-binaries-dir $out/bin"
  '';

  meta = {
    description = "A tool that extends the functionality of FROMSOFTWARE games running on Windows and Linux via Proton.";
    homepage = "https://github.com/garyttierney/me3";
    license = lib.licenses.mit;
  };
}
