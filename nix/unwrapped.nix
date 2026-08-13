{
  lib,
  stdenv,
  autoPatchelfHook,
  electron_41,
  fetchPnpmDeps,
  nodejs_22,
  pnpm_10,
  pnpmConfigHook,
  alsa-lib,
  at-spi2-core,
  glib,
  libGL,
  libayatana-appindicator,
  libnotify,
  libsecret,
  libXScrnSaver,
  libXtst,
  nspr,
  nss,
  openssl,
  pkg-config,
  udev,
  src,
  sysproxy,
  country,
  geoip,
  geosite,
  metadb,
  asn,
  subStore,
  subStoreFrontend,
  notoFontsColorEmoji,
  mihomo,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "clash-party-unwrapped";
  version = "2.0.1";
  inherit src;

  patches = [
    ../patches/branding.patch
    ../patches/disable-updater.patch
    ../patches/stable-core-only.patch
    ../patches/nix-tun-wrapper.patch
    ../patches/system-electron-resources.patch
  ];

  pnpmDeps = fetchPnpmDeps {
    pname = finalAttrs.pname;
    version = finalAttrs.version;
    inherit src;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    prePnpmInstall = ''
      pnpm config set fetch-retries 5
      pnpm config set fetch-timeout 120000
      pnpm config set network-concurrency 4
    '';
    hash = "sha256-g6bI798j0ld9jx9ekBcj+mSY6uWyjCWxIytxxgVcDsY=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    nodejs_22
    pkg-config
    pnpmConfigHook
    pnpm_10
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

  env = {
    ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
    npm_config_build_from_source = "true";
  };

  postPatch = ''
    mkdir -p extra/sidecar extra/files
    ln -s ${mihomo}/bin/mihomo extra/sidecar/mihomo
    cp ${sysproxy}/sysproxy.linux-${if stdenv.hostPlatform.isx86_64 then "x64" else "arm64"}-gnu.node \
      extra/sidecar/

    install -Dm444 ${country} extra/files/country.mmdb
    install -Dm444 ${geoip} extra/files/geoip.dat
    install -Dm444 ${geosite} extra/files/geosite.dat
    install -Dm444 ${metadb} extra/files/geoip.metadb
    install -Dm444 ${asn} extra/files/ASN.mmdb
    install -Dm444 ${subStore}/share/sub-store/sub-store.bundle.js \
      extra/files/sub-store.bundle.cjs
    cp -r ${subStoreFrontend} extra/files/sub-store-frontend
    find ${notoFontsColorEmoji} -name NotoColorEmoji.ttf -exec \
      install -Dm444 {} src/renderer/src/assets/NotoColorEmoji.ttf \;
  '';

  buildPhase = ''
    runHook preBuild

    mkdir .electron-dist
    cp -RL ${electron_41.dist}/. .electron-dist/
    chmod -R u+w .electron-dist

    node_modules/.bin/electron-vite build
    npm_config_nodedir=${electron_41.headers} \
      node_modules/.bin/electron-builder --dir \
      --config=electron-builder.yml \
      --config.electronDist=$PWD/.electron-dist \
      --config.electronVersion=${electron_41.version}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/clash-party
    cp -r dist/linux-unpacked/resources $out/lib/clash-party/
    install -Dm644 build/icon.png $out/share/icons/hicolor/512x512/apps/clash-party.png

    runHook postInstall
  '';

})
