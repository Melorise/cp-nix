{
  lib,
  callPackage,
  stdenv,
  electron_41,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  wrapGAppsHook3,
  autoPatchelfHook,
  alsa-lib,
  at-spi2-core,
  glib,
  libGL,
  libayatana-appindicator,
  libsecret,
  libnotify,
  libXScrnSaver,
  libXtst,
  nspr,
  nss,
  openssl,
  udev,
  src,
  sysproxySrc,
  country,
  geoip,
  geosite,
  metadb,
  asn,
  subStore,
  subStoreFrontend,
  notoFontsColorEmoji,
  mihomo,
  commandLineArgs ? [ ],
}:

let
  sysproxy = callPackage ./sysproxy.nix { inherit sysproxySrc; };

  unwrapped = callPackage ./unwrapped.nix {
    inherit
      src
      sysproxy
      country
      geoip
      geosite
      metadb
      asn
      subStore
      subStoreFrontend
      notoFontsColorEmoji
      mihomo
      ;
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "clash-party";
  version = "2.0.1";

  dontUnpack = true;

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    at-spi2-core
    glib
    libGL
    libayatana-appindicator
    libnotify
    libsecret
    libXScrnSaver
    libXtst
    nspr
    nss
    openssl
    stdenv.cc.cc.lib
    udev
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/clash-party
    cp -r ${unwrapped}/lib/clash-party/resources $out/lib/clash-party/
    cp -r ${unwrapped}/share $out/
    chmod -R u+w $out/share

    makeWrapper ${lib.getExe electron_41} $out/bin/clash-party \
      --inherit-argv0 \
      --add-flags "$out/lib/clash-party/resources/app.asar" \
      --add-flags ${lib.escapeShellArg (lib.escapeShellArgs commandLineArgs)} \
      --set-default ELECTRON_OZONE_PLATFORM_HINT auto

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "clash-party";
      desktopName = "Clash Party";
      genericName = "Proxy Client";
      comment = "A GUI client based on Mihomo";
      exec = "clash-party %U";
      icon = "clash-party";
      startupWMClass = "clash-party";
      categories = [ "Utility" ];
      mimeTypes = [
        "x-scheme-handler/clash"
        "x-scheme-handler/mihomo"
      ];
    })
  ];

  passthru = {
    inherit mihomo sysproxy unwrapped;
  };

  meta = {
    description = "Clash Party desktop client built from source";
    homepage = "https://github.com/mihomo-party-org/clash-party";
    license = lib.licenses.gpl3Only;
    mainProgram = "clash-party";
    platforms = lib.platforms.linux;
  };
})
