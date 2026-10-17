#!/usr/bin/env bash
# Build and test where there is no hosted GitHub runner: the VM and container
# jobs of .github/workflows/*.yml. Both CMake linkages run in one boot.
#
# bash, which those jobs install on the guests that lack it.

set -euxo pipefail

os=$(uname -s)

# Neither spelling is universal, and an empty answer would leave a bare
# "-j" - unlimited parallelism, enough to wedge a small guest.
ncpu=$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)
case "$ncpu" in
''|*[!0-9]*) ncpu=$(sysctl -n hw.ncpu 2>/dev/null || true) ;;
esac
case "$ncpu" in
''|*[!0-9]*) ncpu=2 ;;
esac

if [ -z "${CC:-}" ]; then
	for c in cc gcc clang; do
		if command -v "$c" > /dev/null 2>&1; then CC=$c; break; fi
	done
fi
if [ -z "${CC:-}" ]; then
	echo "no C compiler found (looked for cc, gcc, clang)" >&2
	exit 1
fi
export CC

echo "==> $(uname -a)"
echo "==> cc: $($CC --version 2>&1 | head -n 1)"
echo "==> using CC=$CC ncpu=$ncpu"

# ---------------------------------------------------------------------------
# CMake, static and shared
# ---------------------------------------------------------------------------
for shared in OFF ON; do
	build="build-shared-$shared"
	echo "==> CMake build (BUILD_SHARED_LIBS=$shared)"

	rm -rf "$build"
	cmake -S . -B "$build" -DBUILD_SHARED_LIBS="$shared"
	cmake --build "$build" -j "$ncpu"

	# Not on the guests' default search path.
	LD_LIBRARY_PATH="$PWD/$build${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
	export LD_LIBRARY_PATH

	# Cygwin resolves its DLL through PATH, not LD_LIBRARY_PATH.
	PATH="$PWD/$build:$PATH"
	export PATH

	# The deterministic half of the suite, so gated on.
	ctest --test-dir "$build" --output-on-failure -LE unreliable

	# These guests are what compiles the generic CPU information backend at
	# all, so a failure here is a defect in it.
	echo "==> jitterentropy-cpuinfo"
	cpuinfo="$build/tests/raw-entropy/recording_userspace/jitterentropy-cpuinfo"
	"$cpuinfo"
	# Only that the JSON form runs: no guest is guaranteed a parser, so
	# Linux is where the output is validated.
	"$cpuinfo" --json > /dev/null

	rng="$build/tests/raw-entropy/recording_userspace/jitterentropy-rng"
	for opt in "" --all-caches --force-internal-timer; do
		echo "==> jitterentropy-rng 256 $opt"
		# Unquoted on purpose: the empty case must expand to no argument.
		"$rng" 256 $opt > /dev/null
	done

	# The compliance modes, not gated on: on these emulated CPUs they can
	# fail on the memory lock limit or on health tests that do not converge.
	for opt in --force-fips --ntg1; do
		echo "==> jitterentropy-rng 256 $opt"
		"$rng" 256 $opt > /dev/null ||
			echo "::warning::jitterentropy-rng $opt failed in $os"
	done
done
