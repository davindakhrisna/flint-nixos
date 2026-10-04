{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  libx11,
  libxi,
  libxkbcommon,
}:
stdenv.mkDerivation {
  pname = "cua-driver";
  version = "0.21.0";
  src = fetchurl {
    url = "https://github.com/trycua/cua/releases/download/cua-driver-rs-v0.21.0/cua-driver-rs-0.21.0-linux-x86_64-binary.tar.gz";
    sha256 = "cf29bfaad16737e31e72f38dad2a6424f24b21a4ac2edea885e83cb9d5034135";
  };
  sourceRoot = ".";
  nativeBuildInputs = [autoPatchelfHook];
  buildInputs = [libx11 libxi libxkbcommon stdenv.cc.cc.lib];
  installPhase = ''
    runHook preInstall
    install -Dm755 cua-driver "$out/bin/cua-driver"
    runHook postInstall
  '';
  meta = {
    description = "Local computer automation driver for Hermes";
    homepage = "https://github.com/trycua/cua";
    license = lib.licenses.mit;
    platforms = ["x86_64-linux"];
    mainProgram = "cua-driver";
  };
}
