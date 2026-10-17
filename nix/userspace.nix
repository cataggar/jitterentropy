# The userspace library and tools: native, musl and cross builds.
ctx:
let
  inherit (ctx) crossFor crossTargets lib muslFor muslStaticFor self toolsFor;
in
{
  # The Zig build: the library plus its tools in bin.
  toolsFor = pkgs:
    pkgs.stdenv.mkDerivation {
      pname = "jitterentropy-tools";
      version = "3.8.0";
      src = self;
      nativeBuildInputs = [ pkgs.zig ];
      dontConfigure = true;
      zigFlags = [ ];
      hardeningDisable = [ "fortify" "fortify3" ];
      buildPhase = ''
        runHook preBuild
        export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
        zig build --prefix "$out" $zigFlags
        runHook postBuild
      '';
      dontInstall = true;
      meta = {
        description = "Jitter RNG userspace library and validation tools";
        license = lib.licenses.bsd3;
      };
    };

  # The same tools against musl, which disagrees with glibc about much the
  # library uses: the CPU_SET pinning, the mlock/getrlimit handling, and
  # clock_gettime(), which it keeps in libc.
  muslFor = pkgs:
    let
      arch = pkgs.stdenv.hostPlatform.parsed.cpu.name;
    in
    (toolsFor pkgs).overrideAttrs (old: {
      pname = "jitterentropy-tools-musl";
      dontPatchELF = true;
      zigFlags = (old.zigFlags or [ ]) ++ [
        "-Dtarget=${arch}-linux-musl"
        "-Dlinkage=dynamic"
      ];
    });

  # The same libc with static linkage: static is where the use of
  # pthreads and clock_gettime() has to hold up with no dynamic loader.
  muslStaticFor = pkgs:
    let
      arch = pkgs.stdenv.hostPlatform.parsed.cpu.name;
    in
    (toolsFor pkgs).overrideAttrs (old: {
      pname = "jitterentropy-tools-musl-static";
      dontPatchELF = true;
      zigFlags = (old.zigFlags or [ ]) ++ [
        "-Dtarget=${arch}-linux-musl"
        "-Dlinkage=static"
      ];
    });

  # Compile-and-link smoke builds for the targets nothing else here
  # evaluates - the ones whose arch/ backends are selected by preprocessor
  # conditions. Not run, which still catches the breakage that occurs: a
  # missing declaration, an absent header, inline asm that does not
  # assemble.
  crossFor = { pkgs, target, timer ? true, shared ? false }:
    pkgs.stdenv.mkDerivation {
      pname = "jitterentropy-cross-${target}";
      version = "3.8.0";
      src = self;
      nativeBuildInputs = [ pkgs.zig ];
      dontConfigure = true;
      dontStrip = true;
      dontPatchELF = true;
      hardeningDisable = [ "fortify" "fortify3" ];
      buildPhase = ''
        runHook preBuild
        export ZIG_GLOBAL_CACHE_DIR="$TMPDIR/zig-cache"
        zig build --prefix "$out" \
          -Dtarget=${target} \
          -Dinternal-timer=${if timer then "true" else "false"} \
          -Dlinkage=${if shared then "dynamic" else "static"} \
          -Dinstall-tests=true
        runHook postBuild
      '';
      dontInstall = true;
      meta = {
        description = "Jitter RNG cross-compilation smoke build";
        license = lib.licenses.bsd3;
      };
    };

  crossTargets = pkgs: {
    # The dedicated jent_get_nstime() backends: stcke, the PowerPC
    # timebase, rdtime, rdtime.d. armv7 covers the clock_gettime()
    # fallback and the 32-bit paths.
    cross-s390x = crossFor { inherit pkgs; target = "s390x-linux-gnu"; };
    cross-ppc64 = crossFor { inherit pkgs; target = "powerpc64le-linux-gnu"; };
    cross-riscv64 = crossFor { inherit pkgs; target = "riscv64-linux-gnu"; };
    cross-loongarch64 = crossFor { inherit pkgs; target = "loongarch64-linux-gnu"; };
    cross-armv7 = crossFor { inherit pkgs; target = "arm-linux-gnueabihf"; };

    # Both link widths, plus shared - the only configuration exercising
    # the dllexport/dllimport split and the bcrypt import library. The
    # internal timer builds despite mingw-w64 shipping no <pthread.h>:
    # the Win32 back-end needs only the CRT and kernel32, which is what
    # this target proves.
    cross-mingwW64 = crossFor { inherit pkgs; target = "x86_64-windows-gnu"; };
    cross-mingwW64-shared = crossFor { inherit pkgs; target = "x86_64-windows-gnu"; shared = true; };
    cross-mingw32 = crossFor { inherit pkgs; target = "x86-windows-gnu"; };
  };
}
