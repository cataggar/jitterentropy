#!/usr/bin/env bash

set -euxo pipefail

# Directory where to store the measurements
OUTDIR=${OUTDIR:-"../results-measurements"}

# Maximum number of entries to be extracted from the original file
NUM_EVENTS=${NUM_EVENTS:-1000000}

# Number of restart tests
NUM_EVENTS_RESTART=${NUM_EVENTS_RESTART:-1000}
NUM_RESTART=${NUM_RESTART:-1000}

NONIID_RESTART_DATA="jent-raw-noise-restart"
NONIID_DATA="jent-raw-noise"
NONIID_HASH_DATA="jent-raw-noise_hashloop"
NONIID_HASH_RESTART_DATA="jent-raw-noise-hashloop-restart"
NONIID_MEMLOOP_DATA="jent-raw-noise_memaccloop"
NONIID_MEMLOOP_RESTART_DATA="jent-raw-noise-memaccloop-restart"
IID_DATA="jent-conditioned.data"

ROOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
BINDIR=${BINDIR:-"$ROOTDIR/zig-out/bin"}
JENT_RNG=${JENT_RNG:-"$BINDIR/jitterentropy-rng"}
JENT_HASHTIME=${JENT_HASHTIME:-"$BINDIR/jitterentropy-hashtime"}

build_tools()
{
	(cd "$ROOTDIR" && zig build -Dtools=true "$@")
}

# Define the maximum memory size
# 0 -> use default
# 1 -> JENT_MAX_MEMSIZE_1kB
# ...
# 20 -> JENT_MAX_MEMSIZE_512MB
MAX_MEMORY_SIZE=0

# If this variable is set to any value, the timer-less entropy source
# is forced and tested
FORCE_NOTIME_NOISE_SOURCE=""

initialization()
{
	if [ ! -d $OUTDIR ]
	then
		if ! mkdir $OUTDIR
		then
			echo "Creation of $OUTDIR failed"
			exit 1
		fi
	fi
}

lfsroutput()
{
	echo "Obtaining $NUM_EVENTS blocks of output from Jitter RNG"

	build_tools

	local cmdopts="--max-mem $MAX_MEMORY_SIZE"

	if [ -n "$FORCE_NOTIME_NOISE_SOURCE" ]
	then
		cmdopts="$cmdopts --disable-internal-timer"
	fi

	$JENT_RNG $NUM_EVENTS $cmdopts > $OUTDIR/$IID_DATA
}

raw_entropy_restart()
{
	echo "Obtaining $NUM_RESTART raw entropy measurement with $NUM_EVENTS_RESTART restarts from Jitter RNG"

	build_tools

	local cmdopts="--max-mem $MAX_MEMORY_SIZE $@"

	if [ -n "$FORCE_NOTIME_NOISE_SOURCE" ]
	then
		cmdopts="$cmdopts --disable-internal-timer"
	fi

	$JENT_HASHTIME $NUM_EVENTS_RESTART $NUM_RESTART $OUTDIR/$NONIID_RESTART_DATA $cmdopts
}

raw_entropy()
{
	echo "Obtaining $NUM_EVENTS raw entropy measurement from Jitter RNG"

	build_tools

	local cmdopts="--max-mem $MAX_MEMORY_SIZE $@"

	if [ -n "$FORCE_NOTIME_NOISE_SOURCE" ]
	then
		cmdopts="$cmdopts --disable-internal-timer"
	fi

	$JENT_HASHTIME $NUM_EVENTS 1 $OUTDIR/$NONIID_DATA $cmdopts
}


raw_entropy_ntg1_hash()
{
	echo "Obtaining $NUM_EVENTS raw entropy measurement from Jitter RNG"

	build_tools

	local cmdopts="--max-mem $MAX_MEMORY_SIZE --hashloop $@"

	if [ -n "$FORCE_NOTIME_NOISE_SOURCE" ]
	then
		cmdopts="$cmdopts --disable-internal-timer"
	fi

	$JENT_HASHTIME $NUM_EVENTS 1 $OUTDIR/$NONIID_HASH_DATA $cmdopts
}

raw_entropy_ntg1_hash_restart()
{
	echo "Obtaining $NUM_RESTART raw entropy measurement with $NUM_EVENTS_RESTART restarts from Jitter RNG"

	build_tools

	local cmdopts="--max-mem $MAX_MEMORY_SIZE --hashloop $@"

	if [ -n "$FORCE_NOTIME_NOISE_SOURCE" ]
	then
		cmdopts="$cmdopts --disable-internal-timer"
	fi

	$JENT_HASHTIME $NUM_EVENTS_RESTART $NUM_RESTART $OUTDIR/$NONIID_HASH_RESTART_DATA $cmdopts
}

raw_entropy_ntg1_memacc()
{
	echo "Obtaining $NUM_EVENTS raw entropy measurement from Jitter RNG"

	build_tools

	local cmdopts="--max-mem $MAX_MEMORY_SIZE --memaccess $@"

	if [ -n "$FORCE_NOTIME_NOISE_SOURCE" ]
	then
		cmdopts="$cmdopts --disable-internal-timer"
	fi

	$JENT_HASHTIME $NUM_EVENTS 1 $OUTDIR/$NONIID_MEMLOOP_DATA $cmdopts
}

raw_entropy_ntg1_memacc_restart()
{
	echo "Obtaining $NUM_RESTART raw entropy measurement with $NUM_EVENTS_RESTART restarts from Jitter RNG"

	build_tools

	local cmdopts="--max-mem $MAX_MEMORY_SIZE --memaccess $@"

	if [ -n "$FORCE_NOTIME_NOISE_SOURCE" ]
	then
		cmdopts="$cmdopts --disable-internal-timer"
	fi

	$JENT_HASHTIME $NUM_EVENTS_RESTART $NUM_RESTART $OUTDIR/$NONIID_MEMLOOP_RESTART_DATA $cmdopts
}
