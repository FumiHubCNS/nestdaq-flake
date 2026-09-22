{
  stdenv,
  cmake,
  pkg-config,
  boost,
  zeromq,
  fmt,
  fairlogger,
  src,
}:

stdenv.mkDerivation {
  pname = "fairmq";
  version = "1.4.55";

  inherit src;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    boost
    zeromq
    fmt
    fairlogger
  ];

  propagatedBuildInputs = [
    boost
    zeromq
    fmt
    fairlogger
  ];

  cmakeFlags = [
    "-DCMAKE_CXX_STANDARD=17"
    "-DBUILD_TESTING=OFF"
    "-DBUILD_EXAMPLES=OFF"
  ];
  # Boost.Asioの新しいresolver APIに対応させる
  postPatch = ''
    substituteInPlace fairmq/tools/Network.cxx \
      --replace-fail         'tcp::resolver::query query(hostname, "");'         'auto results = resolver.resolve(hostname, "");' \
      --replace-fail         'tcp::resolver::iterator end;'         'auto end = results.end();' \
      --replace-fail         'static_cast<basic_resolver_iterator<tcp>>(resolver.resolve(query))'         'results.begin()'

    substituteInPlace CMakeLists.txt \
      --replace-fail \
        'get_git_version()' \
        'get_git_version(DEFAULT_VERSION 1.4.55)'
  '';

  # デバッグ用:
  # CMake configureに失敗した場合、
  # FairCMakeModulesの内部ログを標準出力へ表示する。
  configurePhase = ''
    runHook preConfigure

    if cmake -S . -B build \
      -DCMAKE_INSTALL_PREFIX="$out" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_CXX_STANDARD=17 \
      -DBUILD_TESTING=OFF \
      -DBUILD_EXAMPLES=OFF
    then
      echo "CMake configuration succeeded."
    else
      echo "========================================"
      echo "FairMQ CMake configuration failed"
      echo "========================================"

      log="build/extern/FairCMakeModules/build.log"

      if [ -f "$log" ]; then
        echo "===== FairCMakeModules build.log ====="
        cat "$log"
        echo "===== End of build.log ====="
      else
        echo "FairCMakeModules build.log was not found."

        echo "Available log files:"
        find build -type f -name "*.log" -print
      fi

      exit 1
    fi

    cd build

    runHook postConfigure
  '';

  doCheck = false;
}
