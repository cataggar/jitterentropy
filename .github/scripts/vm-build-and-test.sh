#!/usr/bin/env bash
# Build and test where there is no hosted GitHub runner: the VM and container
# jobs of .github/workflows/*.yml. Both Zig linkages run in one boot.
#
# bash, which those jobs install on the guests that lack it.

set -euxo pipefail

os=$(uname -s)

echo "==> $(uname -a)"
echo "==> zig: $(zig version)"

# ---------------------------------------------------------------------------
# Zig build, static and dynamic
# ---------------------------------------------------------------------------
for linkage in static dynamic; do
	build="build-$linkage"
	echo "==> Zig build (-Dlinkage=$linkage)"

	rm -rf "$build"
	zig build -Dlinkage="$linkage" --prefix "$PWD/$build" "$@"

	# Not on the guests' default search path.
	LD_LIBRARY_PATH="$PWD/$build/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
	export LD_LIBRARY_PATH

	# Windows/Cygwin resolves its DLL through PATH, not LD_LIBRARY_PATH.
	PATH="$PWD/$build/bin:$PATH"
	export PATH

	# The deterministic half of the suite, so gated on.
	zig build -Dlinkage="$linkage" "$@" test

	# These guests are what compiles the generic CPU information backend at
	# all, so a failure here is a defect in it.
	echo "==> jitterentropy-cpuinfo"
	cpuinfo="$build/bin/jitterentropy-cpuinfo"
	"$cpuinfo"
	# Only that the JSON form runs: no guest is guaranteed a parser, so
	# Linux is where the output is validated.
	"$cpuinfo" --json > /dev/null

	rng="$build/bin/jitterentropy-rng"
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
