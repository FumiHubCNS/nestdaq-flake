{
  stdenv,
  lib,
  cmake,
  pkg-config,
  boost,
  zeromq,
  hiredis,
  redis-plus-plus,
  fairlogger,
  fairmq,
  src,
}:

stdenv.mkDerivation {
  pname = "nestdaq";
  version = "unstable";

  inherit src;

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    boost
    zeromq
    hiredis
    redis-plus-plus
    fairlogger
    fairmq
  ];

  # NestDAQを利用する側にも必要になる公開依存
  propagatedBuildInputs = [
    fairmq
    fairlogger
  ];

  cmakeFlags = [
    "-DCMAKE_BUILD_TYPE=Release"
    "-DCMAKE_CXX_STANDARD=17"
    "-DCMAKE_PREFIX_PATH=${lib.makeSearchPathOutput "dev" "" [
      fairlogger
      fairmq
      redis-plus-plus
    ]}"
  ];
}
