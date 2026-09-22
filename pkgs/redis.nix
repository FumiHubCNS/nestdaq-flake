{
  stdenv,
  src,
}:

stdenv.mkDerivation {
  pname = "redis";
  version = "7.4.0";

  inherit src;

  # RedisはCMakeではなくGNU Makeでビルドする。
  dontConfigure = true;

  # jemallocなどの追加ビルドを避けるため、
  # まずは標準のlibc allocatorを使用する。
  makeFlags = [
    "MALLOC=libc"
    "BUILD_TLS=no"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    make install PREFIX="$out" MALLOC=libc BUILD_TLS=no

    runHook postInstall
  '';

  doCheck = false;
}
