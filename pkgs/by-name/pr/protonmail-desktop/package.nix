{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  dpkg,
  electron,
  unzip,
}:

let
  darwinArch = if stdenv.hostPlatform.system == "x86_64-darwin" then "x64" else "arm64";
  mainProgram = "proton-mail";
  universalDarwinHash = "sha256-JfZwHFp0aZtHcbP7tyG7uqFs2w+LWKfnfyuxxpxDJZ8=";

in
stdenv.mkDerivation rec {
  pname = "protonmail-desktop";
  version = "1.0.5";

  src = fetchurl {
    url =
      if stdenv.isDarwin then
        "https://github.com/ProtonMail/inbox-desktop/releases/download/${version}/Proton.Mail-darwin-${darwinArch}-${version}.zip"
      else
        "https://github.com/ProtonMail/inbox-desktop/releases/download/${version}/proton-mail_${version}_amd64.deb";
    sha256 =
      {
        x86_64-linux = "sha256-En5vkTHYtwN6GMgbtyhzsPqknOPRO9KlTqZfbBFaIFQ=";
        x86_64-darwin = universalDarwinHash;
        aarch64-darwin = universalDarwinHash;
      }
      .${stdenv.hostPlatform.system} or (throw "unsupported system ${stdenv.hostPlatform.system}");
  };

  sourceRoot = lib.optionalString stdenv.isDarwin ".";

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
  ] ++ lib.optional stdenv.isLinux dpkg ++ lib.optional stdenv.isDarwin unzip;

  installPhase =
    let
      darwin = ''
        mkdir -p $out/{Applications,bin}
        cp -r "Proton Mail.app" $out/Applications/
        makeWrapper $out/Applications/"Proton Mail.app"/Contents/MacOS/Proton\ Mail $out/bin/protonmail-desktop
      '';
      linux = ''
        runHook preInstall
        mkdir -p $out
        cp -r usr/share/ $out/
        cp -r usr/lib/proton-mail/resources/app.asar $out/share/
      '';

    in
    ''
      runHook preInstall

      ${if stdenv.isDarwin then darwin else linux}

      runHook postInstall
    '';

  preFixup = lib.optionalString stdenv.isLinux ''
    makeWrapper ${lib.getExe electron} $out/bin/${mainProgram} \
      --add-flags $out/share/app.asar \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
      --set-default ELECTRON_FORCE_IS_PACKAGED 1 \
      --set-default ELECTRON_IS_DEV 0 \
      --inherit-argv0
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Desktop application for Mail and Calendar, made with Electron";
    homepage = "https://github.com/ProtonMail/inbox-desktop";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [
      rsniezek
      sebtm
      matteopacini
    ];
    platforms = [
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    inherit mainProgram;
  };
}
