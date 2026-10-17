const std = @import("std");
pub const internal = @import("internal.zig");
pub const build_options = internal.build_options;
pub const base = @import("base.zig");
pub const status = @import("status.zig");

comptime {
    _ = base.jent_selftest_run;
    _ = base.ensure_osr_is_at_least_minimal;
    _ = base.jent_version;
    _ = base.jent_read_entropy;
    _ = base.jent_health_failure_reset;
    _ = base.jent_read_entropy_safe;
    _ = base.jent_memsize;
    _ = base.jent_hashloop_cnt;
    _ = base.jent_entropy_collector_alloc_internal;
    _ = base.jent_entropy_collector_alloc;
    _ = base.jent_raw_selftest;
    _ = base.jent_entropy_collector_alloc_raw;
    _ = base.jent_entropy_collector_free;
    _ = base.jent_time_entropy_init;
    _ = base.jent_selftest;
    _ = base.jent_entropy_init;
    _ = base.jent_entropy_init_ex;
    _ = base.jent_entropy_switch_notime_impl;
    _ = base.jent_entropy_set_notime_cpu;
    _ = base.jent_set_fips_failure_callback;

    _ = status.jent_status;
    _ = status.jent_entropy_collector_uuid;
    _ = status.jent_entropy_collector_osr;
    _ = status.jent_entropy_collector_flags;
    _ = status.jent_entropy_collector_memsize;
    _ = status.jent_entropy_collector_health_failure;
    _ = status.jent_entropy_collector_reinitializations;
    _ = status.jent_entropy_collector_read_invocations;
    _ = status.jent_entropy_collector_bytes_output;
    _ = status.jent_entropy_collector_hashloops;
}

// ============================================================================
// Re-exported Public & Internal Constants, Flags, Error Codes, and Types
// ============================================================================

pub const JENT_MAJVERSION = internal.JENT_MAJVERSION;
pub const JENT_MINVERSION = internal.JENT_MINVERSION;
pub const JENT_PATCHLEVEL = internal.JENT_PATCHLEVEL;
pub const JENT_VERSION = internal.JENT_VERSION;

pub const JENT_DISABLE_STIR = internal.JENT_DISABLE_STIR;
pub const JENT_DISABLE_UNBIAS = internal.JENT_DISABLE_UNBIAS;
pub const JENT_DISABLE_MEMORY_ACCESS = internal.JENT_DISABLE_MEMORY_ACCESS;
pub const JENT_FORCE_INTERNAL_TIMER = internal.JENT_FORCE_INTERNAL_TIMER;
pub const JENT_DISABLE_INTERNAL_TIMER = internal.JENT_DISABLE_INTERNAL_TIMER;
pub const JENT_FORCE_FIPS = internal.JENT_FORCE_FIPS;
pub const JENT_NTG1 = internal.JENT_NTG1;
pub const JENT_CACHE_ALL = internal.JENT_CACHE_ALL;
pub const JENT_FORCE_SECURE_MEM = internal.JENT_FORCE_SECURE_MEM;
pub const JENT_INT_MEASURE_CLOCK = internal.JENT_INT_MEASURE_CLOCK;

pub const JENT_FLAGS_TO_MEMSIZE_SHIFT = internal.JENT_FLAGS_TO_MEMSIZE_SHIFT;
pub const jent_flags_to_max_memsize = internal.jent_flags_to_max_memsize;
pub const jent_max_memsize_to_flags = internal.jent_max_memsize_to_flags;
pub const JENT_FLAGS_TO_MAX_MEMSIZE = internal.JENT_FLAGS_TO_MAX_MEMSIZE;
pub const JENT_MAX_MEMSIZE_TO_FLAGS = internal.JENT_MAX_MEMSIZE_TO_FLAGS;

pub const JENT_MAX_MEMSIZE_1kB = internal.JENT_MAX_MEMSIZE_1kB;
pub const JENT_MAX_MEMSIZE_2kB = internal.JENT_MAX_MEMSIZE_2kB;
pub const JENT_MAX_MEMSIZE_4kB = internal.JENT_MAX_MEMSIZE_4kB;
pub const JENT_MAX_MEMSIZE_8kB = internal.JENT_MAX_MEMSIZE_8kB;
pub const JENT_MAX_MEMSIZE_16kB = internal.JENT_MAX_MEMSIZE_16kB;
pub const JENT_MAX_MEMSIZE_32kB = internal.JENT_MAX_MEMSIZE_32kB;
pub const JENT_MAX_MEMSIZE_64kB = internal.JENT_MAX_MEMSIZE_64kB;
pub const JENT_MAX_MEMSIZE_128kB = internal.JENT_MAX_MEMSIZE_128kB;
pub const JENT_MAX_MEMSIZE_256kB = internal.JENT_MAX_MEMSIZE_256kB;
pub const JENT_MAX_MEMSIZE_512kB = internal.JENT_MAX_MEMSIZE_512kB;
pub const JENT_MAX_MEMSIZE_1MB = internal.JENT_MAX_MEMSIZE_1MB;
pub const JENT_MAX_MEMSIZE_2MB = internal.JENT_MAX_MEMSIZE_2MB;
pub const JENT_MAX_MEMSIZE_4MB = internal.JENT_MAX_MEMSIZE_4MB;
pub const JENT_MAX_MEMSIZE_8MB = internal.JENT_MAX_MEMSIZE_8MB;
pub const JENT_MAX_MEMSIZE_16MB = internal.JENT_MAX_MEMSIZE_16MB;
pub const JENT_MAX_MEMSIZE_32MB = internal.JENT_MAX_MEMSIZE_32MB;
pub const JENT_MAX_MEMSIZE_64MB = internal.JENT_MAX_MEMSIZE_64MB;
pub const JENT_MAX_MEMSIZE_128MB = internal.JENT_MAX_MEMSIZE_128MB;
pub const JENT_MAX_MEMSIZE_256MB = internal.JENT_MAX_MEMSIZE_256MB;
pub const JENT_MAX_MEMSIZE_512MB = internal.JENT_MAX_MEMSIZE_512MB;
pub const JENT_MAX_MEMSIZE_MAX = internal.JENT_MAX_MEMSIZE_MAX;
pub const JENT_MAX_MEMSIZE_MASK = internal.JENT_MAX_MEMSIZE_MASK;
pub const JENT_MAX_MEMSIZE_OFFSET = internal.JENT_MAX_MEMSIZE_OFFSET;

pub const JENT_FLAGS_TO_HASHLOOP_SHIFT = internal.JENT_FLAGS_TO_HASHLOOP_SHIFT;
pub const jent_hashloop_to_flags = internal.jent_hashloop_to_flags;
pub const jent_flags_to_hashloop = internal.jent_flags_to_hashloop;
pub const JENT_HASHLOOP_TO_FLAGS = internal.JENT_HASHLOOP_TO_FLAGS;
pub const JENT_FLAGS_TO_HASHLOOP = internal.JENT_FLAGS_TO_HASHLOOP;
pub const JENT_MAX_HASHLOOP_MASK = internal.JENT_MAX_HASHLOOP_MASK;
pub const JENT_HASHLOOP_1 = internal.JENT_HASHLOOP_1;
pub const JENT_HASHLOOP_2 = internal.JENT_HASHLOOP_2;
pub const JENT_HASHLOOP_4 = internal.JENT_HASHLOOP_4;
pub const JENT_HASHLOOP_8 = internal.JENT_HASHLOOP_8;
pub const JENT_HASHLOOP_16 = internal.JENT_HASHLOOP_16;
pub const JENT_HASHLOOP_32 = internal.JENT_HASHLOOP_32;
pub const JENT_HASHLOOP_64 = internal.JENT_HASHLOOP_64;
pub const JENT_HASHLOOP_128 = internal.JENT_HASHLOOP_128;
pub const JENT_MAX_HASHLOOP = internal.JENT_MAX_HASHLOOP;

pub const JENT_MIN_OSR = internal.JENT_MIN_OSR;
pub const JENT_MAX_OSR = internal.JENT_MAX_OSR;
pub const JENT_UUID_STRLEN = internal.JENT_UUID_STRLEN;

pub const ENOTIME = internal.ENOTIME;
pub const ECOARSETIME = internal.ECOARSETIME;
pub const ENOMONOTONIC = internal.ENOMONOTONIC;
pub const EMINVARIATION = internal.EMINVARIATION;
pub const EVARVAR = internal.EVARVAR;
pub const EMINVARVAR = internal.EMINVARVAR;
pub const EPROGERR = internal.EPROGERR;
pub const ESTUCK = internal.ESTUCK;
pub const EHEALTH = internal.EHEALTH;
pub const ERCT = internal.ERCT;
pub const EHASH = internal.EHASH;
pub const EMEM = internal.EMEM;
pub const EGCD = internal.EGCD;

pub const JENT_ENOTIME = internal.JENT_ENOTIME;
pub const JENT_ECOARSETIME = internal.JENT_ECOARSETIME;
pub const JENT_ENOMONOTONIC = internal.JENT_ENOMONOTONIC;
pub const JENT_EMINVARIATION = internal.JENT_EMINVARIATION;
pub const JENT_EVARVAR = internal.JENT_EVARVAR;
pub const JENT_EMINVARVAR = internal.JENT_EMINVARVAR;
pub const JENT_EPROGERR = internal.JENT_EPROGERR;
pub const JENT_ESTUCK = internal.JENT_ESTUCK;
pub const JENT_EHEALTH = internal.JENT_EHEALTH;
pub const JENT_ERCT = internal.JENT_ERCT;
pub const JENT_EHASH = internal.JENT_EHASH;
pub const JENT_EMEM = internal.JENT_EMEM;
pub const JENT_EGCD = internal.JENT_EGCD;
pub const JENT_EAPT = internal.JENT_EAPT;
pub const JENT_ECALLBACK = internal.JENT_ECALLBACK;
pub const JENT_ECTX = internal.JENT_ECTX;
pub const JENT_EDIV = internal.JENT_EDIV;
pub const JENT_EENTROPY = internal.JENT_EENTROPY;
pub const JENT_ELAG = internal.JENT_ELAG;
pub const JENT_ERCT_MEM = internal.JENT_ERCT_MEM;
pub const JENT_ESELFTEST = internal.JENT_ESELFTEST;
pub const JENT_ERECORD = internal.JENT_ERECORD;

pub const JENT_ERR_EINVAL = internal.JENT_ERR_EINVAL;
pub const JENT_ERR_RCT = internal.JENT_ERR_RCT;
pub const JENT_ERR_APT = internal.JENT_ERR_APT;
pub const JENT_ERR_NOTIME = internal.JENT_ERR_NOTIME;
pub const JENT_ERR_LAG = internal.JENT_ERR_LAG;
pub const JENT_ERR_RCT_PERMANENT = internal.JENT_ERR_RCT_PERMANENT;
pub const JENT_ERR_APT_PERMANENT = internal.JENT_ERR_APT_PERMANENT;
pub const JENT_ERR_LAG_PERMANENT = internal.JENT_ERR_LAG_PERMANENT;
pub const JENT_ERR_RCT_MEM = internal.JENT_ERR_RCT_MEM;
pub const JENT_ERR_RCT_MEM_PERMANENT = internal.JENT_ERR_RCT_MEM_PERMANENT;
pub const JENT_ERR_SELFTEST = internal.JENT_ERR_SELFTEST;

pub const JENT_RCT_FAILURE = internal.JENT_RCT_FAILURE;
pub const JENT_APT_FAILURE = internal.JENT_APT_FAILURE;
pub const JENT_LAG_FAILURE = internal.JENT_LAG_FAILURE;
pub const JENT_RCT_MEM_FAILURE = internal.JENT_RCT_MEM_FAILURE;
pub const JENT_PERMANENT_FAILURE_SHIFT = internal.JENT_PERMANENT_FAILURE_SHIFT;
pub const jent_permanent_failure = internal.jent_permanent_failure;
pub const JENT_PERMANENT_FAILURE = internal.JENT_PERMANENT_FAILURE;
pub const JENT_RCT_FAILURE_PERMANENT = internal.JENT_RCT_FAILURE_PERMANENT;
pub const JENT_APT_FAILURE_PERMANENT = internal.JENT_APT_FAILURE_PERMANENT;
pub const JENT_LAG_FAILURE_PERMANENT = internal.JENT_LAG_FAILURE_PERMANENT;
pub const JENT_RCT_MEM_FAILURE_PERMANENT = internal.JENT_RCT_MEM_FAILURE_PERMANENT;

pub const jent_udiv64 = internal.jent_udiv64;
pub const jent_umod64 = internal.jent_umod64;

pub const jent_fips_failure_cb = internal.jent_fips_failure_cb;
pub const jent_notime_start_routine = internal.jent_notime_start_routine;
pub const jent_notime_thread = internal.jent_notime_thread;
pub const jent_notime_ctx = internal.jent_notime_ctx;
pub const jent_startup_state = internal.jent_startup_state;
pub const jent_health_init_type = internal.jent_health_init_type;
pub const jent_sha_ctx = internal.jent_sha_ctx;
pub const rand_data = internal.rand_data;

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(internal);
    std.testing.refAllDecls(base);
    std.testing.refAllDecls(status);
}
