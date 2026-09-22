{
  description = "NestDAQ Nix package";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    # Boost 1.85.0
    boost-pin.url = "github:nixos/nixpkgs/nixos-24.11";

    # FairLogger
    fairloggerSrc = {
      url = "github:FairRootGroup/FairLogger/v2.3.0";
      flake = false;
    };

    # FairMQ
    fairmqSrc = {
      url = "git+https://github.com/FairRootGroup/FairMQ.git?ref=refs/tags/v1.4.55&submodules=1";
      flake = false;
    };

    # Redis
    redisSrc = {
      url = "github:redis/redis/7.4.0";
      flake = false;
    };
    
    # Redis Time Series
    redistimeseriesSrc = {
      url = "git+https://github.com/RedisTimeSeries/RedisTimeSeries.git?ref=refs/tags/v1.12.2&submodules=1";
      flake = false;
    };

    # NestDAQ
    nestdaqSrc = {
      url = "github:spadi-alliance/nestdaq";
      flake = false;
    };
  };

  outputs = {
    self,
    nixpkgs,
    boost-pin,
    flake-utils,
    fairloggerSrc,
    fairmqSrc,
    redisSrc,
    redistimeseriesSrc,
    nestdaqSrc,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        boostPkgs = import boost-pin {
          inherit system;
        };
        
        boost185 =
          assert boostPkgs ? boost185;
          assert boostPkgs.boost185.version == "1.85.0";
          boostPkgs.boost185;

        # FairLogger
        fairlogger = pkgs.callPackage ./pkgs/fairlogger.nix {
          src = fairloggerSrc;
        };

        # FairMQ
        fairmq = pkgs.callPackage ./pkgs/fairmq.nix {
          inherit fairlogger;
	  boost = boost185;
          src = fairmqSrc;
        };

        # Redis
        redis = pkgs.callPackage ./pkgs/redis.nix {
          src = redisSrc;
        };
        
	# Redis Time Series
        redistimeseries = pkgs.callPackage ./pkgs/redistimeseries.nix {
          src = redistimeseriesSrc;
        };

        # NestDAQ
        nestdaq = pkgs.callPackage ./pkgs/nestdaq.nix {
          inherit fairlogger fairmq;
	  boost = boost185;
          src = nestdaqSrc;
        };

      in
      {
        # Nix packages
        packages = {
          inherit 
	    fairlogger
	    fairmq
	    redis
	    redistimeseries
	    nestdaq
	    ;

          default = nestdaq;
        };

        # Development environment
        devShells.default = pkgs.mkShell {
          name = "nestdaq-env";

          inputsFrom = [
            nestdaq
          ];

          packages = with pkgs; [
            cmake
            pkg-config
            git
          ];
        };
      }
    );
}
