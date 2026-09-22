{
  stdenv,
  cmake,
  pkg-config,
  fmt,
  src,
}:

stdenv.mkDerivation {
  pname = "fairlogger";
  version = "2.3.0";

  inherit src;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    fmt
  ];

  postPatch = ''
    cat > logger/nix-localtime.h <<'EOF'
  #pragma once
  
  #include <ctime>
  #include <stdexcept>
  #include <fmt/chrono.h>
  
  inline std::tm nix_localtime(std::time_t timestamp) {
      std::tm result{};
  
      if (::localtime_r(&timestamp, &result) == nullptr) {
          throw std::runtime_error("localtime_r failed");
      }
  
      return result;
  }
  EOF
  
    sed -i '1i#include "nix-localtime.h"' logger/Logger.cxx
  
    substituteInPlace logger/Logger.cxx \
      --replace-fail 'fmt::localtime(' 'nix_localtime('
  '';

  postInstall = ''
    oldDir="$out/lib/cmake/FairLogger-0.0.0.0"
    newDir="$out/lib/cmake/FairLogger-2.3.0"
  
    if [ ! -d "$oldDir" ]; then
      echo "FairLogger CMake directory not found"
      find "$out" -name '*FairLogger*' -print
      exit 1
    fi
  
    find "$oldDir" -type f -name '*.cmake' -exec \
      sed -i 's/0\.0\.0\.0/2.3.0/g' {} +
  
    mv "$oldDir" "$newDir"
  
    config="$newDir/FairLoggerConfig.cmake"
  
    if [ ! -f "$config" ]; then
      echo "FairLoggerConfig.cmake not found"
      exit 1
    fi
  
    sed -i "s|$out/||g" "$config"
  
    echo "===== FairLogger CMake paths ====="
    grep -E 'FairLogger_(BINDIR|INCDIR|INCDIRS|LIBDIR)|FairLoggerTargets.cmake' "$config"

    targets="$newDir/FairLoggerTargets-release.cmake"
  
    if [ ! -f "$targets" ]; then
      echo "FairLoggerTargets-release.cmake not found"
      exit 1
    fi
  
    substituteInPlace "$targets" \
      --replace-fail \
        'libFairLogger.so.2.3.0' \
        'libFairLogger.so.0.0.0.0'
  
    test -f "$out/lib/libFairLogger.so.0.0.0.0"
  
    echo "===== FairLogger target ====="
    grep -n 'IMPORTED_LOCATION_RELEASE' "$targets"
  '';

  cmakeFlags = [
    "-DCMAKE_CXX_STANDARD=17"
    "-DUSE_EXTERNAL_FMT=ON"
    "-DBUILD_TESTING=OFF"
  ];
}
