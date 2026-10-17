# Downstream consumers and the external crypto backends.
ctx:
let
  inherit (ctx) consumersFor cryptoFor lib self toolsFor;
in
{
  # rng-tools and ESDM built against this tree. A build of this repository
  # alone cannot see what breaks a consumer: a header that stops declaring
  # something, a symbol that stops being exported, a link dependency missing
  # from the .pc file.
  #
  # nixpkgs' own derivation with src and build steps replaced, not toolsFor,
  # so what is tested is the library as a distribution installs it - the
  # dev/out split included - and the swap stays source-only. Compile and
  # link only; behaviour is what the tool runs and the VM tests cover.
  consumersFor = pkgs:
    let
      # internal-timer decides which symbols are exported, and rng-tools'
      # configure probes for jent_notime_settick(): off, rngd_jitter.c
      # compiles without the tick handling; on, it drives the timer thread.
      # Two different compilations, hence both - off is what nixpkgs and so
      # the distributions build, on is this repository's default.
      #
      # ESDM compiles the same either way but gates much of esdm_es_jent.c
      # on JENT_VERSION, which makes it the consumer pinning the widest
      # part of the API.
      libFor = timer:
        pkgs.jitterentropy.overrideAttrs (_: {
          version = "3.8.0";
          src = self;
          nativeBuildInputs = [ pkgs.zig ];
          dontConfigure = true;
          buildPhase = ''
            runHook preBuild
            export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
            zig build --prefix "$out" -Dtools=false -Dinternal-timer=${if timer then "true" else "false"}
            runHook postBuild
          '';
          dontInstall = true;
        });
      notimer = libFor false;
      timer = libFor true;
      buildOnly = drv:
        drv.overrideAttrs (_: {
          doCheck = false;
          doInstallCheck = false;
        });
    in {
      consumer-rng-tools =
        buildOnly (pkgs.rng-tools.override { jitterentropy = notimer; });
      consumer-rng-tools-timer =
        buildOnly (pkgs.rng-tools.override { jitterentropy = timer; });
      consumer-esdm =
        buildOnly (pkgs.esdm.override { jitterentropy = notimer; });
      consumer-esdm-timer =
        buildOnly (pkgs.esdm.override { jitterentropy = timer; });
    };

  # The external-crypto backends. Set, the library calls the named library
  # instead of its own SHA-3 and secure memory, reaching the halves of the
  # memory and FIPS backends the default build never compiles: libgcrypt's
  # secmem pool, OpenSSL's secure heap, and AWS-LC's OPENSSL_malloc(), which
  # is wiped but not locked and so reports itself as not secure.
  #
  # The unit tests are built and run as well: they absorb the backends
  # themselves, so the configuration they compile in is the one the
  # library is built with, and this is the only place that compiles them
  # with an external crypto library.
  cryptoFor = pkgs:
    let
      backendFor = { name, external, deps }:
        let
          incDirs = lib.concatMapStringsSep ":" (d: "${lib.getDev d}/include") deps;
          libDirs = lib.concatMapStringsSep ":" (d: "${lib.getLib d}/lib") deps;
        in
        (toolsFor pkgs).overrideAttrs (old: {
          pname = "jitterentropy-tools-${name}";
          buildInputs = (old.buildInputs or [ ]) ++ deps;
          zigFlags = (old.zigFlags or [ ]) ++ [
            "-Dexternal-crypto=${external}"
            "-Dlinkage=dynamic"
            "-Dinclude-dirs=${incDirs}"
            "-Dlib-dirs=${libDirs}"
          ];
          doCheck = true;
          checkPhase = ''
            runHook preCheck
            zig build $zigFlags test
            runHook postCheck
          '';
        });
    in {
      crypto-openssl = backendFor {
        name = "openssl";
        external = "openssl";
        deps = [ pkgs.openssl ];
      };
      crypto-awslc = backendFor {
        name = "awslc";
        external = "awslc";
        deps = [ pkgs.aws-lc ];
      };
      # <gpg-error.h> arrives through libgcrypt's propagated input.
      crypto-libgcrypt = backendFor {
        name = "libgcrypt";
        external = "libgcrypt";
        deps = [ pkgs.libgcrypt pkgs.libgpg-error ];
      };
    };
}
