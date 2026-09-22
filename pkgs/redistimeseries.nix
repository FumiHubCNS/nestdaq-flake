{
  stdenv,
  cmake,
  pkg-config,
  python3,
  openssl,
  libevent,
  hiredis,
  src,
  autoconf,
  automake,
  libtool,
}:

stdenv.mkDerivation {
  pname = "redistimeseries";
  version = "1.12.2";

  inherit src;

  nativeBuildInputs = [
    cmake
    pkg-config
    python3
    autoconf
    automake
    libtool
  ];

  buildInputs = [
    openssl
    libevent
    hiredis
  ];

  dontConfigure = true;

  enableParallelBuilding = true;

  postPatch = ''
    patchShebangs --build deps/readies
  
    substituteInPlace deps/readies/mk/main \
      --replace-fail \
        'CHECK=1 VERBOSE=0 $(READIES)/bin/$(MK.getpy)' \
        'command -v python3 >/dev/null 2>&1'
  
    cmakeFile="deps/cpu_features/CMakeLists.txt"
  
    if ! head -n 1 "$cmakeFile" | grep -q 'cmake_minimum_required'; then
      echo "Unexpected cpu_features CMakeLists.txt"
      head -n 10 "$cmakeFile"
      exit 1
    fi
  
    sed -i '1c\cmake_minimum_required(VERSION 3.5)' "$cmakeFile"
  '';

  # Nixのビルド中にgit cloneなどを行わない。
  # 必要な依存ソースはflake input取得時に準備する。
  preBuild = ''
    echo "===== RedisTimeSeries source ====="

    ls -la
    ls -la deps

    if [ ! -d deps/LibMR ]; then
      echo "ERROR: deps/LibMR is missing."
      echo "Check recursive Git submodules."
      exit 1
    fi
  '';

  buildPhase = ''
    runHook preBuild

    # make setup は実行しない。
    # 依存ソースが揃っていることを前提にビルドする。
    make build DEBUG=0 -j"$NIX_BUILD_CORES"

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/lib"

    module="$(
      find bin -type f -name redistimeseries.so -print -quit
    )"

    if [ -z "$module" ]; then
      echo "ERROR: redistimeseries.so not found"
      find bin -maxdepth 5 -type f -print || true
      exit 1
    fi

    install -m 755 "$module" "$out/lib/redistimeseries.so"

    runHook postInstall
  '';

  doCheck = false;
}
