{
  lib,
  rustPlatform,
  fetchPnpmDeps,
  nodejs_22,
  pnpm_10,
  pnpmConfigHook,
  sysproxySrc,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "clash-party-sysproxy";
  version = "0.5.1";
  src = sysproxySrc;

  cargoLock.lockFile = ./sysproxy-Cargo.lock;

  pnpmDeps = fetchPnpmDeps {
    pname = finalAttrs.pname;
    version = finalAttrs.version;
    src = sysproxySrc;
    pnpm = pnpm_10;
    fetcherVersion = 4;
    prePnpmInstall = ''
      pnpm config set fetch-retries 5
      pnpm config set fetch-timeout 120000
      pnpm config set network-concurrency 4
    '';
    hash = "sha256-n/unBCkpSSShYliEeeWOAjM7r7ZUdfROBYyqzw8JLB0=";
  };

  nativeBuildInputs = [
    nodejs_22
    pnpmConfigHook
    pnpm_10
  ];

  postPatch = ''
    rm -f .cargo/config.toml
    cp ${./sysproxy-Cargo.lock} Cargo.lock
    chmod u+w Cargo.lock
  '';

  buildPhase = ''
    runHook preBuild
    pnpm exec napi build --platform --release
    runHook postBuild
  '';

  # N-API symbols are supplied by Node/Electron when the module is loaded, so
  # Cargo's standalone test-link step cannot resolve them.
  doCheck = false;

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp sysproxy.*.node $out/
    runHook postInstall
  '';
})
