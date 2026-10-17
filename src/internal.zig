const std = @import("std");
const builtin = @import("builtin");
pub const build_options = @import("build_options");

// ============================================================================
// Version Constants (jitterentropy.h)
// ============================================================================

pub const JENT_MAJVERSION: c_uint = 3;
pub const JENT_MINVERSION: c_uint = 8;
pub const JENT_PATCHLEVEL: c_uint = 0;
pub const JENT_VERSION: c_uint = JENT_MAJVERSION * 1000000 + JENT_MINVERSION * 10000 + JENT_PATCHLEVEL * 100;

// ============================================================================
// Initialization Flags & Bitfield Encodings (jitterentropy.h & internal.h)
// ============================================================================

pub const JENT_DISABLE_STIR: c_uint = 1 << 0;
pub const JENT_DISABLE_UNBIAS: c_uint = 1 << 1;
pub const JENT_DISABLE_MEMORY_ACCESS: c_uint = 1 << 2;
pub const JENT_FORCE_INTERNAL_TIMER: c_uint = 1 << 3;
pub const JENT_DISABLE_INTERNAL_TIMER: c_uint = 1 << 4;
pub const JENT_FORCE_FIPS: c_uint = 1 << 5;
pub const JENT_NTG1: c_uint = 1 << 6;
pub const JENT_CACHE_ALL: c_uint = 1 << 7;
pub const JENT_FORCE_SECURE_MEM: c_uint = 1 << 8;

/// Internal flag: collector measures a clock rather than generating entropy.
pub const JENT_INT_MEASURE_CLOCK: c_uint = 1 << 22;

pub const JENT_FLAGS_TO_MEMSIZE_SHIFT: u5 = 27;

pub inline fn jent_flags_to_max_memsize(val: c_uint) c_uint {
    return val >> JENT_FLAGS_TO_MEMSIZE_SHIFT;
}

pub inline fn jent_max_memsize_to_flags(val: c_uint) c_uint {
    return val << JENT_FLAGS_TO_MEMSIZE_SHIFT;
}

pub const JENT_FLAGS_TO_MAX_MEMSIZE = jent_flags_to_max_memsize;
pub const JENT_MAX_MEMSIZE_TO_FLAGS = jent_max_memsize_to_flags;

pub const JENT_MAX_MEMSIZE_1kB: c_uint = jent_max_memsize_to_flags(1);
pub const JENT_MAX_MEMSIZE_2kB: c_uint = jent_max_memsize_to_flags(2);
pub const JENT_MAX_MEMSIZE_4kB: c_uint = jent_max_memsize_to_flags(3);
pub const JENT_MAX_MEMSIZE_8kB: c_uint = jent_max_memsize_to_flags(4);
pub const JENT_MAX_MEMSIZE_16kB: c_uint = jent_max_memsize_to_flags(5);
pub const JENT_MAX_MEMSIZE_32kB: c_uint = jent_max_memsize_to_flags(6);
pub const JENT_MAX_MEMSIZE_64kB: c_uint = jent_max_memsize_to_flags(7);
pub const JENT_MAX_MEMSIZE_128kB: c_uint = jent_max_memsize_to_flags(8);
pub const JENT_MAX_MEMSIZE_256kB: c_uint = jent_max_memsize_to_flags(9);
pub const JENT_MAX_MEMSIZE_512kB: c_uint = jent_max_memsize_to_flags(10);
pub const JENT_MAX_MEMSIZE_1MB: c_uint = jent_max_memsize_to_flags(11);
pub const JENT_MAX_MEMSIZE_2MB: c_uint = jent_max_memsize_to_flags(12);
pub const JENT_MAX_MEMSIZE_4MB: c_uint = jent_max_memsize_to_flags(13);
pub const JENT_MAX_MEMSIZE_8MB: c_uint = jent_max_memsize_to_flags(14);
pub const JENT_MAX_MEMSIZE_16MB: c_uint = jent_max_memsize_to_flags(15);
pub const JENT_MAX_MEMSIZE_32MB: c_uint = jent_max_memsize_to_flags(16);
pub const JENT_MAX_MEMSIZE_64MB: c_uint = jent_max_memsize_to_flags(17);
pub const JENT_MAX_MEMSIZE_128MB: c_uint = jent_max_memsize_to_flags(18);
pub const JENT_MAX_MEMSIZE_256MB: c_uint = jent_max_memsize_to_flags(19);
pub const JENT_MAX_MEMSIZE_512MB: c_uint = jent_max_memsize_to_flags(20);
pub const JENT_MAX_MEMSIZE_MAX: c_uint = JENT_MAX_MEMSIZE_512MB;
pub const JENT_MAX_MEMSIZE_MASK: c_uint = jent_max_memsize_to_flags(0xffffffff);
pub const JENT_MAX_MEMSIZE_OFFSET: c_uint = 9;

pub const JENT_FLAGS_TO_HASHLOOP_SHIFT: u5 = 23;

pub inline fn jent_hashloop_to_flags(val: c_uint) c_uint {
    return val << JENT_FLAGS_TO_HASHLOOP_SHIFT;
}

pub inline fn jent_flags_to_hashloop(val: c_uint) c_uint {
    return (val >> JENT_FLAGS_TO_HASHLOOP_SHIFT) & 0xf;
}

pub const JENT_HASHLOOP_TO_FLAGS = jent_hashloop_to_flags;
pub const JENT_FLAGS_TO_HASHLOOP = jent_flags_to_hashloop;

pub const JENT_MAX_HASHLOOP_MASK: c_uint = jent_hashloop_to_flags(0xf);
pub const JENT_HASHLOOP_1: c_uint = jent_hashloop_to_flags(1);
pub const JENT_HASHLOOP_2: c_uint = jent_hashloop_to_flags(2);
pub const JENT_HASHLOOP_4: c_uint = jent_hashloop_to_flags(3);
pub const JENT_HASHLOOP_8: c_uint = jent_hashloop_to_flags(4);
pub const JENT_HASHLOOP_16: c_uint = jent_hashloop_to_flags(5);
pub const JENT_HASHLOOP_32: c_uint = jent_hashloop_to_flags(6);
pub const JENT_HASHLOOP_64: c_uint = jent_hashloop_to_flags(7);
pub const JENT_HASHLOOP_128: c_uint = jent_hashloop_to_flags(8);
pub const JENT_MAX_HASHLOOP: c_uint = JENT_HASHLOOP_128;

pub const JENT_MIN_OSR: c_uint = 3;
pub const JENT_MAX_OSR: c_uint = 20;

pub const JENT_UUID_STRLEN: usize = 37;

// ============================================================================
// Error Codes & Health Failure Masks (jitterentropy.h)
// ============================================================================

pub const ENOTIME: c_int = 1;
pub const ECOARSETIME: c_int = 2;
pub const ENOMONOTONIC: c_int = 3;
pub const EMINVARIATION: c_int = 4;
pub const EVARVAR: c_int = 5;
pub const EMINVARVAR: c_int = 6;
pub const EPROGERR: c_int = 7;
pub const ESTUCK: c_int = 8;
pub const EHEALTH: c_int = 9;
pub const ERCT: c_int = 10;
pub const EHASH: c_int = 11;
pub const EMEM: c_int = 12;
pub const EGCD: c_int = 13;

// JENT_E* prefixed aliases
pub const JENT_ENOTIME: c_int = ENOTIME;
pub const JENT_ECOARSETIME: c_int = ECOARSETIME;
pub const JENT_ENOMONOTONIC: c_int = ENOMONOTONIC;
pub const JENT_EMINVARIATION: c_int = EMINVARIATION;
pub const JENT_EVARVAR: c_int = EVARVAR;
pub const JENT_EMINVARVAR: c_int = EMINVARVAR;
pub const JENT_EPROGERR: c_int = EPROGERR;
pub const JENT_ESTUCK: c_int = ESTUCK;
pub const JENT_EHEALTH: c_int = EHEALTH;
pub const JENT_ERCT: c_int = ERCT;
pub const JENT_EHASH: c_int = EHASH;
pub const JENT_EMEM: c_int = EMEM;
pub const JENT_EGCD: c_int = EGCD;
pub const JENT_EAPT: c_int = 14;
pub const JENT_ECALLBACK: c_int = 15;
pub const JENT_ECTX: c_int = 16;
pub const JENT_EDIV: c_int = 17;
pub const JENT_EENTROPY: c_int = 18;
pub const JENT_ELAG: c_int = 19;
pub const JENT_ERCT_MEM: c_int = 20;
pub const JENT_ESELFTEST: c_int = 21;
pub const JENT_ERECORD: c_int = 22;

// Error codes for jent_read_entropy / jent_read_entropy_safe
pub const JENT_ERR_EINVAL: c_int = -1;
pub const JENT_ERR_RCT: c_int = -2;
pub const JENT_ERR_APT: c_int = -3;
pub const JENT_ERR_NOTIME: c_int = -4;
pub const JENT_ERR_LAG: c_int = -5;
pub const JENT_ERR_RCT_PERMANENT: c_int = -6;
pub const JENT_ERR_APT_PERMANENT: c_int = -7;
pub const JENT_ERR_LAG_PERMANENT: c_int = -8;
pub const JENT_ERR_RCT_MEM: c_int = -9;
pub const JENT_ERR_RCT_MEM_PERMANENT: c_int = -10;
pub const JENT_ERR_SELFTEST: c_int = -11;

// Health test failure bitmasks
pub const JENT_RCT_FAILURE: c_uint = 1;
pub const JENT_APT_FAILURE: c_uint = 2;
pub const JENT_LAG_FAILURE: c_uint = 4;
pub const JENT_RCT_MEM_FAILURE: c_uint = 8;
pub const JENT_PERMANENT_FAILURE_SHIFT: u5 = 16;

pub inline fn jent_permanent_failure(x: c_uint) c_uint {
    return x << JENT_PERMANENT_FAILURE_SHIFT;
}

pub const JENT_PERMANENT_FAILURE = jent_permanent_failure;
pub const JENT_RCT_FAILURE_PERMANENT: c_uint = jent_permanent_failure(JENT_RCT_FAILURE);
pub const JENT_APT_FAILURE_PERMANENT: c_uint = jent_permanent_failure(JENT_APT_FAILURE);
pub const JENT_LAG_FAILURE_PERMANENT: c_uint = jent_permanent_failure(JENT_LAG_FAILURE);
pub const JENT_RCT_MEM_FAILURE_PERMANENT: c_uint = jent_permanent_failure(JENT_RCT_MEM_FAILURE);

// ============================================================================
// Internal Configuration & Algorithm Constants (src/jitterentropy-*.h)
// ============================================================================

pub const JENT_APT_MASK: u64 = 0xffffffffffffffff;
pub const JENT_DEFAULT_MEMORY_BITS: u5 = 18;
pub const JENT_CACHE_SHIFT_BITS: u5 = 0;

pub const JENT_MAX_AUTO_MEMSIZE: c_uint = if (@sizeOf(usize) <= 4)
    jent_flags_to_max_memsize(JENT_MAX_MEMSIZE_64MB)
else
    jent_flags_to_max_memsize(JENT_MAX_MEMSIZE_MAX);

pub const JENT_MEM_ACC_LOOP_DEFAULT: c_uint = 128;
pub const JENT_MEM_ACC_LOOP_INIT: c_uint = 3;
pub const JENT_HASH_LOOP_DEFAULT: c_uint = 1;
pub const JENT_HASH_LOOP_INIT: c_uint = 3;

pub const JENT_SHA3_256_SIZE_DIGEST_BITS: usize = 256;
pub const JENT_SHA3_256_SIZE_DIGEST: usize = JENT_SHA3_256_SIZE_DIGEST_BITS >> 3;

pub inline fn jent_sha3_size_block(bits: usize) usize {
    return (1600 - 2 * bits) >> 3;
}

pub const JENT_SHA3_256_SIZE_BLOCK: usize = jent_sha3_size_block(JENT_SHA3_256_SIZE_DIGEST_BITS);
pub const JENT_XDRBG_SIZE_STATE: usize = 64;
pub const ENTROPY_SAFETY_FACTOR: usize = 64 + 1;
pub const DATA_SIZE_BITS: usize = JENT_SHA3_256_SIZE_DIGEST_BITS;

pub const JENT_MEMORY_BLOCKSIZE: u32 = 128;
pub const JENT_APT_WINDOW_SIZE: c_uint = 512;
pub const JENT_LAG_WINDOW_SIZE: c_uint = 1 << 17;
pub const JENT_LAG_HISTORY_SIZE: usize = 8;
pub const JENT_LAG_MASK: usize = JENT_LAG_HISTORY_SIZE - 1;

pub const JENT_STUCK_PRIME: u2 = 2;

pub const JENT_GCD_CLOCK_PLATFORM: c_uint = 0;
pub const JENT_GCD_CLOCK_NOTIME: c_uint = 1;
pub const JENT_GCD_CLOCKS: usize = 2;

pub const JENT_NCPU_SET_MAX: c_uint = 1 << 16;
pub const enable_random_memaccess = !build_options.raw_memory_access;

// ============================================================================
// Inline Helpers (src/jitterentropy-internal.h, sha3.h, health.h, gcd.h)
// ============================================================================

pub inline fn jent_udiv64(dividend: u64, divisor: u64) u64 {
    return dividend / divisor;
}

pub inline fn jent_umod64(dividend: u64, divisor: u64) u64 {
    return dividend % divisor;
}

pub inline fn jent_stuck_init_thres(x: anytype) @TypeOf(x) {
    return (x * 9) / 10;
}

pub inline fn jent_memory_blocks(ec: *const rand_data) u32 {
    return (ec.memmask + 1) / JENT_MEMORY_BLOCKSIZE;
}

pub inline fn jent_sha3_rate(hash_state: *const jent_sha_ctx) c_uint {
    return hash_state.r;
}

pub inline fn jent_shake256_set_digestsize(ctx: *jent_sha_ctx, digestsize: c_uint) void {
    ctx.digestsize = @truncate(digestsize);
}

pub inline fn jent_delta(prev: u64, next: u64) u64 {
    return next -% prev;
}

pub inline fn jent_health_rct_intermittent_cutoff(x: anytype) @TypeOf(x) {
    return x * 30;
}

pub inline fn jent_health_rct_permanent_cutoff(x: anytype) @TypeOf(x) {
    return x * 60;
}

pub inline fn jent_gcd_add_value(delta_history: [*]u64, delta: u64, idx: usize) void {
    delta_history[idx] = delta;
}

// ============================================================================
// C-ABI Types & Structs (jitterentropy.h & src/jitterentropy-internal.h)
// ============================================================================

pub const is_freestanding = (builtin.os.tag == .freestanding or builtin.os.tag == .uefi);
pub const is_pthread = (builtin.os.tag != .windows and !is_freestanding);

pub const jent_notime_start_routine = if (is_pthread)
    ?*const fn (?*anyopaque) callconv(.c) ?*anyopaque
else
    ?*const fn (?*anyopaque) callconv(.c) c_int;

pub const jent_notime_thread = extern struct {
    jent_notime_init: ?*const fn (*?*anyopaque) callconv(.c) c_int = null,
    jent_notime_fini: ?*const fn (?*anyopaque) callconv(.c) void = null,
    jent_notime_start: ?*const fn (?*anyopaque, jent_notime_start_routine, ?*anyopaque) callconv(.c) c_int = null,
    jent_notime_stop: ?*const fn (?*anyopaque) callconv(.c) void = null,
};

pub const jent_notime_ctx = if (is_freestanding) extern struct {
    notime_cpu: c_ulong = 0,
} else if (builtin.os.tag == .windows) extern struct {
    notime_thread_id: ?*anyopaque = null,
    notime_routine: jent_notime_start_routine = null,
    notime_arg: ?*anyopaque = null,
    notime_cpu: c_ulong = 0,
    notime_thread_started: c_int = 0,
} else extern struct {
    notime_pthread_attr: std.c.pthread_attr_t = std.mem.zeroes(std.c.pthread_attr_t),
    notime_thread_id: ?std.c.pthread_t = null,
    notime_cpu: c_ulong = 0,
    notime_thread_started: c_int = 0,
};

pub const jent_startup_state = enum(c_uint) {
    jent_startup_completed = 0,
    jent_startup_sha3 = 1,
    jent_startup_memory = 2,
};

pub const jent_health_init_type = enum(c_uint) {
    jent_health_init_type_common = 0,
    jent_health_init_type_ntg1 = 1,
};

/// Packed storage unit matching `uint8_t initially_seeded:1` in `struct jent_sha_ctx`.
pub const ShaBitfields = switch (builtin.cpu.arch.endian()) {
    .little => packed struct(u8) {
        initially_seeded: u1 = 0,
        _pad: u7 = 0,
    },
    .big => packed struct(u8) {
        _pad: u7 = 0,
        initially_seeded: u1 = 0,
    },
};

pub const jent_sha_ctx = extern struct {
    state: [25]u64 = @splat(0),
    msg_len: usize = 0,
    partial: [JENT_SHA3_256_SIZE_BLOCK]u8 = @splat(0),
    xdrbg_block: [JENT_XDRBG_SIZE_STATE + JENT_SHA3_256_SIZE_DIGEST]u8 = @splat(0),
    r: u8 = 0,
    rword: u8 = 0,
    digestsize: u8 = 0,
    padding: u8 = 0,
    bitfields: ShaBitfields = .{},

    pub inline fn initiallySeeded(self: *const jent_sha_ctx) u1 {
        return self.bitfields.initially_seeded;
    }

    pub inline fn setInitiallySeeded(self: *jent_sha_ctx, val: u1) void {
        self.bitfields.initially_seeded = val;
    }
};

pub const JENT_SHA_MAX_CTX_SIZE: usize = @sizeOf(jent_sha_ctx);

/// Packed storage unit matching the `unsigned int` bitfields in `struct rand_data`:
///   unsigned int apt_base_set:1;
///   unsigned int is_fips_enabled:1;
///   unsigned int enable_notime:1;
///   unsigned int max_mem_set:1;
///   unsigned int in_recovery:1;
///   unsigned int stuck_prime:2;
///   unsigned int notime_running:1; (when JENT_CONF_ENABLE_INTERNAL_TIMER is enabled)
///
/// On SysV ABI (non-Windows), these <= 8 bits occupy a single byte at offset 612,
/// allowing `uint8_t notime_interrupt` to pack at offset 613 inside the same 4-byte word.
/// On Windows (MS bitfield layout), `unsigned int` bitfields allocate a full 4-byte
/// `c_uint` storage unit at offset 612..616, placing `notime_interrupt` at offset 616.
pub const RandBitfieldsBacking = if (builtin.os.tag == .windows) c_uint else u8;

pub const RandBitfields = switch (builtin.cpu.arch.endian()) {
    .little => if (builtin.os.tag == .windows) packed struct(c_uint) {
        apt_base_set: u1 = 0,
        is_fips_enabled: u1 = 0,
        enable_notime: u1 = 0,
        max_mem_set: u1 = 0,
        in_recovery: u1 = 0,
        stuck_prime: u2 = 0,
        notime_running: u1 = 0,
        _pad: u24 = 0,
    } else packed struct(u8) {
        apt_base_set: u1 = 0,
        is_fips_enabled: u1 = 0,
        enable_notime: u1 = 0,
        max_mem_set: u1 = 0,
        in_recovery: u1 = 0,
        stuck_prime: u2 = 0,
        notime_running: u1 = 0,
    },
    .big => packed struct(u8) {
        notime_running: u1 = 0,
        stuck_prime: u2 = 0,
        in_recovery: u1 = 0,
        max_mem_set: u1 = 0,
        enable_notime: u1 = 0,
        is_fips_enabled: u1 = 0,
        apt_base_set: u1 = 0,
    },
};

pub fn RandData(comptime enable_internal_timer: bool) type {
    return if (enable_internal_timer) extern struct {
        const Self = @This();

        hash_state: jent_sha_ctx = .{},
        prev_time: u64 = 0,
        flags: c_uint = 0,
        osr: c_uint = 0,
        uuid: [JENT_UUID_STRLEN]u8 = @splat(0),
        reinit_count: c_uint = 0,
        read_invocations: u64 = 0,
        bytes_output: u64 = 0,
        startup_state: jent_startup_state = .jent_startup_completed,
        mem: ?[*]u8 = null,
        memmask: u32 = 0,
        memlocation: c_uint = 0,
        memaccessloops: c_uint = 0,
        hashloopcnt: c_uint = 0,
        rct_count: c_uint = 0,
        rct_cutoff: c_ushort = 0,
        rct_cutoff_permanent: c_ushort = 0,
        apt_cutoff: c_uint = 0,
        apt_cutoff_permanent: c_uint = 0,
        apt_observations: c_uint = 0,
        apt_count: c_uint = 0,
        apt_base: u64 = 0,
        health_failure: c_uint = 0,
        rct_mem_ctr: c_ushort = 0,
        rct_mem_nosr: c_ushort = 0,
        rct_mem_count: c_ushort = 0,
        rct_mem_cutoff: c_ushort = 0,
        rct_mem_cutoff_permanent: c_ushort = 0,
        selftest_failed: c_int = 0,
        bitfields: RandBitfields = .{},
        notime_interrupt: u8 = 0,
        notime_timer: u64 = 0,
        notime_prev_timer: u64 = 0,
        notime_thread_ctx: ?*anyopaque = null,
        jent_common_timer_gcd: u64 = 0,
        lag_global_cutoff: c_uint = 0,
        lag_global_cutoff_permanent: c_uint = 0,
        lag_local_cutoff: c_uint = 0,
        lag_local_cutoff_permanent: c_uint = 0,
        lag_prediction_success_count: c_uint = 0,
        lag_prediction_success_run: c_uint = 0,
        lag_best_predictor: c_uint = 0,
        lag_observations: c_uint = 0,
        lag_delta_history: [JENT_LAG_HISTORY_SIZE]u64 = @splat(0),
        lag_scoreboard: [JENT_LAG_HISTORY_SIZE]c_uint = @splat(0),

        pub inline fn aptBaseSet(self: *const Self) u1 {
            return self.bitfields.apt_base_set;
        }
        pub inline fn setAptBaseSet(self: *Self, val: u1) void {
            self.bitfields.apt_base_set = val;
        }
        pub inline fn isFipsEnabled(self: *const Self) u1 {
            return self.bitfields.is_fips_enabled;
        }
        pub inline fn setIsFipsEnabled(self: *Self, val: u1) void {
            self.bitfields.is_fips_enabled = val;
        }
        pub inline fn enableNotime(self: *const Self) u1 {
            return self.bitfields.enable_notime;
        }
        pub inline fn setEnableNotime(self: *Self, val: u1) void {
            self.bitfields.enable_notime = val;
        }
        pub inline fn maxMemSet(self: *const Self) u1 {
            return self.bitfields.max_mem_set;
        }
        pub inline fn setMaxMemSet(self: *Self, val: u1) void {
            self.bitfields.max_mem_set = val;
        }
        pub inline fn inRecovery(self: *const Self) u1 {
            return self.bitfields.in_recovery;
        }
        pub inline fn setInRecovery(self: *Self, val: u1) void {
            self.bitfields.in_recovery = val;
        }
        pub inline fn stuckPrime(self: *const Self) u2 {
            return self.bitfields.stuck_prime;
        }
        pub inline fn setStuckPrime(self: *Self, val: u2) void {
            self.bitfields.stuck_prime = val;
        }
        pub inline fn notimeRunning(self: *const Self) u1 {
            return self.bitfields.notime_running;
        }
        pub inline fn setNotimeRunning(self: *Self, val: u1) void {
            self.bitfields.notime_running = val;
        }
        pub inline fn getNotimeInterrupt(self: *const Self) u8 {
            return @as(*const volatile u8, &self.notime_interrupt).*;
        }
        pub inline fn setNotimeInterrupt(self: *Self, val: u8) void {
            @as(*volatile u8, &self.notime_interrupt).* = val;
        }
        pub inline fn getNotimeTimer(self: *const Self) u64 {
            return @as(*const volatile u64, &self.notime_timer).*;
        }
        pub inline fn setNotimeTimer(self: *Self, val: u64) void {
            @as(*volatile u64, &self.notime_timer).* = val;
        }
    } else extern struct {
        const Self = @This();

        hash_state: jent_sha_ctx = .{},
        prev_time: u64 = 0,
        flags: c_uint = 0,
        osr: c_uint = 0,
        uuid: [JENT_UUID_STRLEN]u8 = @splat(0),
        reinit_count: c_uint = 0,
        read_invocations: u64 = 0,
        bytes_output: u64 = 0,
        startup_state: jent_startup_state = .jent_startup_completed,
        mem: ?[*]u8 = null,
        memmask: u32 = 0,
        memlocation: c_uint = 0,
        memaccessloops: c_uint = 0,
        hashloopcnt: c_uint = 0,
        rct_count: c_uint = 0,
        rct_cutoff: c_ushort = 0,
        rct_cutoff_permanent: c_ushort = 0,
        apt_cutoff: c_uint = 0,
        apt_cutoff_permanent: c_uint = 0,
        apt_observations: c_uint = 0,
        apt_count: c_uint = 0,
        apt_base: u64 = 0,
        health_failure: c_uint = 0,
        rct_mem_ctr: c_ushort = 0,
        rct_mem_nosr: c_ushort = 0,
        rct_mem_count: c_ushort = 0,
        rct_mem_cutoff: c_ushort = 0,
        rct_mem_cutoff_permanent: c_ushort = 0,
        selftest_failed: c_int = 0,
        bitfields: RandBitfields = .{},
        jent_common_timer_gcd: u64 = 0,
        lag_global_cutoff: c_uint = 0,
        lag_global_cutoff_permanent: c_uint = 0,
        lag_local_cutoff: c_uint = 0,
        lag_local_cutoff_permanent: c_uint = 0,
        lag_prediction_success_count: c_uint = 0,
        lag_prediction_success_run: c_uint = 0,
        lag_best_predictor: c_uint = 0,
        lag_observations: c_uint = 0,
        lag_delta_history: [JENT_LAG_HISTORY_SIZE]u64 = @splat(0),
        lag_scoreboard: [JENT_LAG_HISTORY_SIZE]c_uint = @splat(0),

        pub inline fn aptBaseSet(self: *const Self) u1 {
            return self.bitfields.apt_base_set;
        }
        pub inline fn setAptBaseSet(self: *Self, val: u1) void {
            self.bitfields.apt_base_set = val;
        }
        pub inline fn isFipsEnabled(self: *const Self) u1 {
            return self.bitfields.is_fips_enabled;
        }
        pub inline fn setIsFipsEnabled(self: *Self, val: u1) void {
            self.bitfields.is_fips_enabled = val;
        }
        pub inline fn enableNotime(self: *const Self) u1 {
            return self.bitfields.enable_notime;
        }
        pub inline fn setEnableNotime(self: *Self, val: u1) void {
            self.bitfields.enable_notime = val;
        }
        pub inline fn maxMemSet(self: *const Self) u1 {
            return self.bitfields.max_mem_set;
        }
        pub inline fn setMaxMemSet(self: *Self, val: u1) void {
            self.bitfields.max_mem_set = val;
        }
        pub inline fn inRecovery(self: *const Self) u1 {
            return self.bitfields.in_recovery;
        }
        pub inline fn setInRecovery(self: *Self, val: u1) void {
            self.bitfields.in_recovery = val;
        }
        pub inline fn stuckPrime(self: *const Self) u2 {
            return self.bitfields.stuck_prime;
        }
        pub inline fn setStuckPrime(self: *Self, val: u2) void {
            self.bitfields.stuck_prime = val;
        }
        pub inline fn notimeRunning(self: *const Self) u1 {
            return self.bitfields.notime_running;
        }
        pub inline fn setNotimeRunning(self: *Self, val: u1) void {
            self.bitfields.notime_running = val;
        }
    };
}

pub const rand_data = RandData(build_options.internal_timer);

pub const jent_fips_failure_cb = ?*const fn (?*rand_data, c_uint) callconv(.c) void;
pub const jent_mock_timer_cb = ?*const fn (?*anyopaque, *u64) callconv(.c) void;
pub const jent_measure_jitter_cb = *const fn (*rand_data, u64, ?*u64, c_int) callconv(.c) c_uint;

// ============================================================================
// Extern C Declarations for Incremental C/Zig Interop
// ============================================================================

// Public API (jitterentropy.h)
pub extern fn jent_read_entropy(ec: ?*rand_data, data: ?[*]u8, len: usize) callconv(.c) isize;
pub extern fn jent_read_entropy_safe(ec: ?*?*rand_data, data: ?[*]u8, len: usize) callconv(.c) isize;
pub extern fn jent_entropy_collector_alloc(osr: c_uint, flags: c_uint) callconv(.c) ?*rand_data;
pub extern fn jent_entropy_collector_alloc_internal(osr: c_uint, flags: c_uint) callconv(.c) ?*rand_data;
pub extern fn jent_entropy_collector_free(entropy_collector: ?*rand_data) callconv(.c) void;
pub extern fn jent_entropy_init() callconv(.c) c_int;
pub extern fn jent_entropy_init_ex(osr: c_uint, flags: c_uint) callconv(.c) c_int;
pub extern fn jent_selftest(ec: ?*rand_data) callconv(.c) c_int;
pub extern fn jent_set_fips_failure_callback(cb: jent_fips_failure_cb) callconv(.c) c_int;
pub extern fn jent_version() callconv(.c) c_uint;
pub extern fn jent_status(ec: ?*const rand_data, buf: ?[*]u8, buflen: usize) callconv(.c) c_int;
pub extern fn jent_entropy_collector_uuid(ec: ?*const rand_data, buf: ?[*]u8, buflen: usize) callconv(.c) c_int;
pub extern fn jent_entropy_collector_osr(ec: ?*const rand_data) callconv(.c) c_uint;
pub extern fn jent_entropy_collector_flags(ec: ?*const rand_data) callconv(.c) c_uint;
pub extern fn jent_entropy_collector_memsize(ec: ?*const rand_data) callconv(.c) usize;
pub extern fn jent_entropy_collector_health_failure(ec: ?*const rand_data) callconv(.c) c_uint;
pub extern fn jent_entropy_collector_reinitializations(ec: ?*const rand_data) callconv(.c) c_uint;
pub extern fn jent_entropy_collector_read_invocations(ec: ?*const rand_data) callconv(.c) u64;
pub extern fn jent_entropy_collector_bytes_output(ec: ?*const rand_data) callconv(.c) u64;
pub extern fn jent_entropy_collector_hashloops(ec: ?*const rand_data) callconv(.c) c_uint;
pub extern fn jent_secure_memory_supported() callconv(.c) c_int;
pub extern fn jent_entropy_switch_notime_impl(new_thread: ?*jent_notime_thread) callconv(.c) c_int;
pub extern fn jent_entropy_set_notime_cpu(cpu: c_ulong) callconv(.c) c_int;
pub extern fn jent_notime_init(ctx: *?*anyopaque) callconv(.c) c_int;
pub extern fn jent_notime_fini(ctx: ?*anyopaque) callconv(.c) void;

// Internal src/ declarations
pub extern fn jent_time_entropy_init(osr: c_uint, flags: c_uint) callconv(.c) c_int;
pub extern fn jent_memsize(flags: c_uint) callconv(.c) u32;
pub extern fn jent_hashloop_cnt(flags: c_uint) callconv(.c) c_uint;

pub extern fn jent_sha3_256_init(ctx: *jent_sha_ctx) callconv(.c) void;
pub extern fn jent_sha3_update(ctx: *jent_sha_ctx, in: [*]const u8, inlen: usize) callconv(.c) void;
pub extern fn jent_sha3_final(ctx: *jent_sha_ctx, digest: [*]u8) callconv(.c) void;
pub extern fn jent_sha3_tester() callconv(.c) c_int;
pub extern fn jent_shake256_init(ctx: *jent_sha_ctx) callconv(.c) void;
pub extern fn jent_drbg_generate_block(ctx: *jent_sha_ctx, dst: [*]u8, dst_len: usize) callconv(.c) void;

pub extern fn jent_gcd_analyze(delta_history: [*]u64, nelem: usize, osr: usize, notime: c_uint) callconv(.c) c_int;
pub extern fn jent_gcd_verdict(delta_history: [*]u64, nelem: usize, osr: usize, gcd: *u64) callconv(.c) c_int;
pub extern fn jent_gcd_store(gcd: u64, notime: c_uint) callconv(.c) void;
pub extern fn jent_gcd_init(nelem: usize, flags: c_uint) callconv(.c) ?[*]u64;
pub extern fn jent_gcd_fini(delta_history: ?[*]u64, nelem: usize) callconv(.c) void;
pub extern fn jent_gcd_get(value: *u64, notime: c_uint) callconv(.c) c_int;
pub extern fn jent_gcd_selftest(flags: c_uint) callconv(.c) c_int;

pub extern fn jent_health_cb_block_switch() callconv(.c) void;
pub extern fn jent_set_fips_failure_callback_internal(cb: jent_fips_failure_cb) callconv(.c) c_int;
pub extern fn jent_lag_duplicate(new_ec: *rand_data, old_ec: *rand_data) callconv(.c) void;
pub extern fn jent_apt_duplicate(new_ec: *rand_data, old_ec: *rand_data) callconv(.c) void;
pub extern fn jent_rct_duplicate(new_ec: *rand_data) callconv(.c) void;
pub extern fn jent_rct_mem_duplicate(new_ec: *rand_data, old_ec: *rand_data) callconv(.c) void;
pub extern fn jent_health_duplicate(new_ec: *rand_data, old_ec: *rand_data) callconv(.c) void;
pub extern fn jent_stuck(ec: *rand_data, current_delta: u64) callconv(.c) c_uint;
pub extern fn jent_health_insert_timestamp(ec: *rand_data, timestamp: u64) callconv(.c) c_uint;
pub extern fn jent_health_failure_query(ec: *const rand_data) callconv(.c) c_uint;
pub extern fn jent_health_failure(ec: *rand_data) callconv(.c) c_uint;
pub extern fn jent_health_init(ec: *rand_data, inittype: jent_health_init_type) callconv(.c) c_int;

pub extern fn jent_get_nstime_internal(ec: *rand_data, out: *u64) callconv(.c) void;
pub extern fn jent_measure_jitter_ntg1_memaccess(ec: *rand_data, loop_cnt: u64, ret_current_delta: ?*u64, health: c_int) callconv(.c) c_uint;
pub extern fn jent_measure_jitter_ntg1_sha3(ec: *rand_data, loop_cnt: u64, ret_current_delta: ?*u64, health: c_int) callconv(.c) c_uint;
pub extern fn jent_measure_jitter(ec: *rand_data, loop_cnt: u64, ret_current_delta: ?*u64, health: c_int) callconv(.c) c_uint;
pub extern fn jent_random_data_one(ec: *rand_data, measure_jitter: jent_measure_jitter_cb) callconv(.c) void;
pub extern fn jent_random_data(ec: *rand_data) callconv(.c) void;
pub extern fn jent_read_random_block(ec: *rand_data, dst: [*]u8, dst_len: usize) callconv(.c) void;

pub extern fn jent_uuid_generate(out: [*]u8) callconv(.c) void;

// Internal arch/ declarations
pub extern fn jent_atomic_load_int(ptr: *const c_int) callconv(.c) c_int;
pub extern fn jent_atomic_store_int(ptr: *c_int, val: c_int) callconv(.c) void;
pub extern fn jent_atomic_load_u32(ptr: *const u32) callconv(.c) u32;
pub extern fn jent_atomic_inc_u32(ptr: *u32) callconv(.c) u32;
pub extern fn jent_atomic_cmpxchg_u32(ptr: *u32, old: u32, val: u32) callconv(.c) u32;
pub extern fn jent_atomic_store_u32(ptr: *u32, val: u32) callconv(.c) void;
pub extern fn jent_atomic_load_fips_cb(ptr: *const jent_fips_failure_cb) callconv(.c) jent_fips_failure_cb;
pub extern fn jent_atomic_store_fips_cb(ptr: *jent_fips_failure_cb, val: jent_fips_failure_cb) callconv(.c) void;

pub extern fn jent_cache_size_roundup(all_caches: c_int) callconv(.c) u64;
pub extern fn jent_fips_enabled() callconv(.c) c_int;

pub extern fn jent_memset_secure(s: ?*anyopaque, n: usize) callconv(.c) void;
pub extern fn jent_zalloc(len: usize, flags: c_uint) callconv(.c) ?*anyopaque;
pub extern fn jent_zalloc_unlocked(len: usize) callconv(.c) ?*anyopaque;
pub extern fn jent_zfree(ptr: ?*anyopaque, len: usize) callconv(.c) void;
pub extern fn jent_memory_is_secure(flags: c_uint) callconv(.c) c_int;
pub extern fn jent_memory_backend_name() callconv(.c) [*:0]const u8;

pub extern fn jent_ncpu() callconv(.c) c_long;
pub extern fn jent_cpu_highest() callconv(.c) c_long;
pub extern fn jent_thread_pin_to_cpu(cpu: c_ulong) callconv(.c) c_int;
pub extern fn jent_notime_thread_create(ctx: *jent_notime_ctx, routine: jent_notime_start_routine, arg: ?*anyopaque) callconv(.c) c_int;
pub extern fn jent_notime_thread_join(ctx: *jent_notime_ctx) callconv(.c) void;

pub extern fn jent_os_random_bytes(buf: [*]u8, len: usize) callconv(.c) c_int;
pub extern fn jent_os_random_supported() callconv(.c) c_int;

pub extern fn jent_yield() callconv(.c) void;
pub extern fn jent_get_nstime(out: *u64) callconv(.c) void;
pub extern fn jent_set_mock_timer(cb: jent_mock_timer_cb, arg: ?*anyopaque) callconv(.c) c_int;

// ============================================================================
// Unit Tests: Constants, Inline Helpers, and C-ABI Struct & Bitfield Layout
// ============================================================================

// C helper functions compiled into the test binary from `build.zig` to inspect
// C macro values, inline helpers, `sizeof`, `_Alignof`, `offsetof`, and bitfields
// on `struct jent_notime_thread`, `struct jent_notime_ctx`, `struct jent_sha_ctx`,
// and `struct rand_data`.
const c_abi_test = struct {
    extern fn jent_test_sizeof_sha_ctx() callconv(.c) usize;
    extern fn jent_test_alignof_sha_ctx() callconv(.c) usize;
    extern fn jent_test_offsetof_sha_ctx(field_id: c_int) callconv(.c) usize;
    extern fn jent_test_sizeof_rand_data() callconv(.c) usize;
    extern fn jent_test_alignof_rand_data() callconv(.c) usize;
    extern fn jent_test_offsetof_rand_data(field_id: c_int) callconv(.c) usize;
    extern fn jent_test_sizeof_notime_thread() callconv(.c) usize;
    extern fn jent_test_alignof_notime_thread() callconv(.c) usize;
    extern fn jent_test_offsetof_notime_thread(field_id: c_int) callconv(.c) usize;
    extern fn jent_test_sizeof_notime_ctx() callconv(.c) usize;
    extern fn jent_test_alignof_notime_ctx() callconv(.c) usize;

    extern fn jent_test_c_uint_const(id: c_int) callconv(.c) c_uint;
    extern fn jent_test_c_int_const(id: c_int) callconv(.c) c_int;

    extern fn jent_test_c_max_memsize_to_flags(val: c_uint) callconv(.c) c_uint;
    extern fn jent_test_c_flags_to_max_memsize(flags: c_uint) callconv(.c) c_uint;
    extern fn jent_test_c_hashloop_to_flags(val: c_uint) callconv(.c) c_uint;
    extern fn jent_test_c_flags_to_hashloop(flags: c_uint) callconv(.c) c_uint;
    extern fn jent_test_c_udiv64(dividend: u64, divisor: u64) callconv(.c) u64;
    extern fn jent_test_c_umod64(dividend: u64, divisor: u64) callconv(.c) u64;

    extern fn jent_test_c_set_sha_initially_seeded(ctx: *jent_sha_ctx, val: u8) callconv(.c) void;
    extern fn jent_test_c_get_sha_initially_seeded(ctx: *const jent_sha_ctx) callconv(.c) u8;

    extern fn jent_test_c_set_rand_bitfield(ec: *rand_data, field_id: c_int, val: c_uint) callconv(.c) void;
    extern fn jent_test_c_get_rand_bitfield(ec: *const rand_data, field_id: c_int) callconv(.c) c_uint;
};

test "public constants, flags, error codes, and inline helpers match C headers" {
    const testing = std.testing;

    // Version constants
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(0), JENT_MAJVERSION);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(1), JENT_MINVERSION);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(2), JENT_PATCHLEVEL);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(3), JENT_VERSION);
    try testing.expectEqual(JENT_VERSION, jent_version());

    // Flags
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(4), JENT_DISABLE_STIR);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(5), JENT_DISABLE_UNBIAS);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(6), JENT_DISABLE_MEMORY_ACCESS);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(7), JENT_FORCE_INTERNAL_TIMER);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(8), JENT_DISABLE_INTERNAL_TIMER);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(9), JENT_FORCE_FIPS);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(10), JENT_NTG1);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(11), JENT_CACHE_ALL);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(12), JENT_FORCE_SECURE_MEM);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(13), JENT_INT_MEASURE_CLOCK);

    // Memory size flags & helpers
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(14), JENT_MAX_MEMSIZE_1kB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(15), JENT_MAX_MEMSIZE_2kB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(16), JENT_MAX_MEMSIZE_4kB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(17), JENT_MAX_MEMSIZE_8kB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(18), JENT_MAX_MEMSIZE_16kB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(19), JENT_MAX_MEMSIZE_32kB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(20), JENT_MAX_MEMSIZE_64kB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(21), JENT_MAX_MEMSIZE_128kB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(22), JENT_MAX_MEMSIZE_256kB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(23), JENT_MAX_MEMSIZE_512kB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(24), JENT_MAX_MEMSIZE_1MB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(25), JENT_MAX_MEMSIZE_2MB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(26), JENT_MAX_MEMSIZE_4MB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(27), JENT_MAX_MEMSIZE_8MB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(28), JENT_MAX_MEMSIZE_16MB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(29), JENT_MAX_MEMSIZE_32MB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(30), JENT_MAX_MEMSIZE_64MB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(31), JENT_MAX_MEMSIZE_128MB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(32), JENT_MAX_MEMSIZE_256MB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(33), JENT_MAX_MEMSIZE_512MB);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(34), JENT_MAX_MEMSIZE_MAX);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(35), JENT_MAX_MEMSIZE_MASK);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(36), JENT_MAX_MEMSIZE_OFFSET);

    for (1..21) |i| {
        const val: c_uint = @intCast(i);
        const encoded = jent_max_memsize_to_flags(val);
        try testing.expectEqual(c_abi_test.jent_test_c_max_memsize_to_flags(val), encoded);
        try testing.expectEqual(val, jent_flags_to_max_memsize(encoded));
        try testing.expectEqual(c_abi_test.jent_test_c_flags_to_max_memsize(encoded), jent_flags_to_max_memsize(encoded));
    }

    // Hashloop flags & helpers
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(37), JENT_MAX_HASHLOOP_MASK);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(38), JENT_HASHLOOP_1);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(39), JENT_HASHLOOP_2);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(40), JENT_HASHLOOP_4);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(41), JENT_HASHLOOP_8);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(42), JENT_HASHLOOP_16);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(43), JENT_HASHLOOP_32);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(44), JENT_HASHLOOP_64);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(45), JENT_HASHLOOP_128);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(46), JENT_MAX_HASHLOOP);

    for (1..9) |i| {
        const val: c_uint = @intCast(i);
        const encoded = jent_hashloop_to_flags(val);
        try testing.expectEqual(c_abi_test.jent_test_c_hashloop_to_flags(val), encoded);
        const combined = encoded | JENT_MAX_MEMSIZE_1MB | JENT_NTG1;
        try testing.expectEqual(val, jent_flags_to_hashloop(combined));
        try testing.expectEqual(c_abi_test.jent_test_c_flags_to_hashloop(combined), jent_flags_to_hashloop(combined));
    }

    // Error codes
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(0), ENOTIME);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(1), ECOARSETIME);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(2), ENOMONOTONIC);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(3), EMINVARIATION);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(4), EVARVAR);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(5), EMINVARVAR);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(6), EPROGERR);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(7), ESTUCK);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(8), EHEALTH);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(9), ERCT);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(10), EHASH);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(11), EMEM);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(12), EGCD);

    try testing.expectEqual(c_abi_test.jent_test_c_int_const(13), JENT_ERR_EINVAL);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(14), JENT_ERR_RCT);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(15), JENT_ERR_APT);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(16), JENT_ERR_NOTIME);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(17), JENT_ERR_LAG);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(18), JENT_ERR_RCT_PERMANENT);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(19), JENT_ERR_APT_PERMANENT);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(20), JENT_ERR_LAG_PERMANENT);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(21), JENT_ERR_RCT_MEM);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(22), JENT_ERR_RCT_MEM_PERMANENT);
    try testing.expectEqual(c_abi_test.jent_test_c_int_const(23), JENT_ERR_SELFTEST);

    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(47), JENT_RCT_FAILURE);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(48), JENT_APT_FAILURE);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(49), JENT_LAG_FAILURE);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(50), JENT_RCT_MEM_FAILURE);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(51), JENT_RCT_FAILURE_PERMANENT);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(52), JENT_APT_FAILURE_PERMANENT);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(53), JENT_LAG_FAILURE_PERMANENT);
    try testing.expectEqual(c_abi_test.jent_test_c_uint_const(54), JENT_RCT_MEM_FAILURE_PERMANENT);

    // Alias error constants
    try testing.expectEqual(ENOTIME, JENT_ENOTIME);
    try testing.expectEqual(ECOARSETIME, JENT_ECOARSETIME);
    try testing.expectEqual(ENOMONOTONIC, JENT_ENOMONOTONIC);
    try testing.expectEqual(EMINVARIATION, JENT_EMINVARIATION);
    try testing.expectEqual(ESTUCK, JENT_ESTUCK);
    try testing.expectEqual(EHEALTH, JENT_EHEALTH);
    try testing.expectEqual(ERCT, JENT_ERCT);
    try testing.expectEqual(EHASH, JENT_EHASH);
    try testing.expectEqual(EMEM, JENT_EMEM);
    try testing.expectEqual(EGCD, JENT_EGCD);

    // 64-bit div/mod helpers
    try testing.expectEqual(@as(u64, 142857), jent_udiv64(999999, 7));
    try testing.expectEqual(@as(u64, 0), jent_umod64(999999, 7));
    try testing.expectEqual(c_abi_test.jent_test_c_udiv64(0x123456789abcdef0, 0x13579bdf), jent_udiv64(0x123456789abcdef0, 0x13579bdf));
    try testing.expectEqual(c_abi_test.jent_test_c_umod64(0x123456789abcdef0, 0x13579bdf), jent_umod64(0x123456789abcdef0, 0x13579bdf));
}

test "C-ABI layout of jent_notime_thread and jent_notime_ctx matches C" {
    const testing = std.testing;

    try testing.expectEqual(c_abi_test.jent_test_sizeof_notime_thread(), @sizeOf(jent_notime_thread));
    try testing.expectEqual(c_abi_test.jent_test_alignof_notime_thread(), @alignOf(jent_notime_thread));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_notime_thread(0), @offsetOf(jent_notime_thread, "jent_notime_init"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_notime_thread(1), @offsetOf(jent_notime_thread, "jent_notime_fini"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_notime_thread(2), @offsetOf(jent_notime_thread, "jent_notime_start"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_notime_thread(3), @offsetOf(jent_notime_thread, "jent_notime_stop"));

    if (build_options.internal_timer) {
        try testing.expectEqual(c_abi_test.jent_test_sizeof_notime_ctx(), @sizeOf(jent_notime_ctx));
        try testing.expectEqual(c_abi_test.jent_test_alignof_notime_ctx(), @alignOf(jent_notime_ctx));
    }
}

test "C-ABI layout and bitfields of jent_sha_ctx match struct jent_sha_ctx" {
    const testing = std.testing;

    try testing.expectEqual(c_abi_test.jent_test_sizeof_sha_ctx(), @sizeOf(jent_sha_ctx));
    try testing.expectEqual(c_abi_test.jent_test_alignof_sha_ctx(), @alignOf(jent_sha_ctx));

    try testing.expectEqual(c_abi_test.jent_test_offsetof_sha_ctx(0), @offsetOf(jent_sha_ctx, "state"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_sha_ctx(1), @offsetOf(jent_sha_ctx, "msg_len"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_sha_ctx(2), @offsetOf(jent_sha_ctx, "partial"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_sha_ctx(3), @offsetOf(jent_sha_ctx, "xdrbg_block"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_sha_ctx(4), @offsetOf(jent_sha_ctx, "r"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_sha_ctx(5), @offsetOf(jent_sha_ctx, "rword"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_sha_ctx(6), @offsetOf(jent_sha_ctx, "digestsize"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_sha_ctx(7), @offsetOf(jent_sha_ctx, "padding"));

    // Verify bitfield `initially_seeded:1` interoperability between C and Zig
    var ctx: jent_sha_ctx = .{};
    ctx.padding = 0x5a;
    try testing.expectEqual(@as(u1, 0), ctx.initiallySeeded());
    try testing.expectEqual(@as(u8, 0), c_abi_test.jent_test_c_get_sha_initially_seeded(&ctx));

    // Mutate in C, read in Zig
    c_abi_test.jent_test_c_set_sha_initially_seeded(&ctx, 1);
    try testing.expectEqual(@as(u1, 1), ctx.initiallySeeded());
    try testing.expectEqual(@as(u1, 1), ctx.bitfields.initially_seeded);
    try testing.expectEqual(@as(u8, 0x5a), ctx.padding);

    c_abi_test.jent_test_c_set_sha_initially_seeded(&ctx, 0);
    try testing.expectEqual(@as(u1, 0), ctx.initiallySeeded());
    try testing.expectEqual(@as(u8, 0x5a), ctx.padding);

    // Mutate in Zig, read in C
    ctx.setInitiallySeeded(1);
    try testing.expectEqual(@as(u8, 1), c_abi_test.jent_test_c_get_sha_initially_seeded(&ctx));
    try testing.expectEqual(@as(u8, 0x5a), ctx.padding);
}

test "C-ABI layout and bitfields of rand_data match struct rand_data" {
    const testing = std.testing;

    try testing.expectEqual(c_abi_test.jent_test_sizeof_rand_data(), @sizeOf(rand_data));
    try testing.expectEqual(c_abi_test.jent_test_alignof_rand_data(), @alignOf(rand_data));

    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(0), @offsetOf(rand_data, "hash_state"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(1), @offsetOf(rand_data, "prev_time"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(2), @offsetOf(rand_data, "flags"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(3), @offsetOf(rand_data, "osr"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(4), @offsetOf(rand_data, "uuid"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(5), @offsetOf(rand_data, "reinit_count"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(6), @offsetOf(rand_data, "read_invocations"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(7), @offsetOf(rand_data, "bytes_output"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(8), @offsetOf(rand_data, "startup_state"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(9), @offsetOf(rand_data, "mem"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(10), @offsetOf(rand_data, "memmask"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(11), @offsetOf(rand_data, "memlocation"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(12), @offsetOf(rand_data, "memaccessloops"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(13), @offsetOf(rand_data, "hashloopcnt"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(14), @offsetOf(rand_data, "rct_count"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(15), @offsetOf(rand_data, "rct_cutoff"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(16), @offsetOf(rand_data, "rct_cutoff_permanent"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(17), @offsetOf(rand_data, "apt_cutoff"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(18), @offsetOf(rand_data, "apt_cutoff_permanent"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(19), @offsetOf(rand_data, "apt_observations"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(20), @offsetOf(rand_data, "apt_count"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(21), @offsetOf(rand_data, "apt_base"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(22), @offsetOf(rand_data, "health_failure"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(23), @offsetOf(rand_data, "rct_mem_ctr"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(24), @offsetOf(rand_data, "rct_mem_nosr"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(25), @offsetOf(rand_data, "rct_mem_count"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(26), @offsetOf(rand_data, "rct_mem_cutoff"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(27), @offsetOf(rand_data, "rct_mem_cutoff_permanent"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(28), @offsetOf(rand_data, "selftest_failed"));

    if (build_options.internal_timer) {
        try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(29), @offsetOf(rand_data, "notime_interrupt"));
        try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(30), @offsetOf(rand_data, "notime_timer"));
        try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(31), @offsetOf(rand_data, "notime_prev_timer"));
        try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(32), @offsetOf(rand_data, "notime_thread_ctx"));
    }

    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(33), @offsetOf(rand_data, "jent_common_timer_gcd"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(34), @offsetOf(rand_data, "lag_global_cutoff"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(35), @offsetOf(rand_data, "lag_global_cutoff_permanent"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(36), @offsetOf(rand_data, "lag_local_cutoff"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(37), @offsetOf(rand_data, "lag_local_cutoff_permanent"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(38), @offsetOf(rand_data, "lag_prediction_success_count"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(39), @offsetOf(rand_data, "lag_prediction_success_run"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(40), @offsetOf(rand_data, "lag_best_predictor"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(41), @offsetOf(rand_data, "lag_observations"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(42), @offsetOf(rand_data, "lag_delta_history"));
    try testing.expectEqual(c_abi_test.jent_test_offsetof_rand_data(43), @offsetOf(rand_data, "lag_scoreboard"));

    // Verify every bitfield in `struct rand_data` by mutating in C and reading in Zig,
    // and mutating in Zig and reading in C, while ensuring neighbor fields are untouched.
    var ec: rand_data = .{};
    ec.selftest_failed = 0x13572468;
    ec.jent_common_timer_gcd = 0xdeadbeefcafebabe;
    if (build_options.internal_timer) {
        ec.setNotimeInterrupt(0xa5);
    }

    // 0: apt_base_set:1
    c_abi_test.jent_test_c_set_rand_bitfield(&ec, 0, 1);
    try testing.expectEqual(@as(u1, 1), ec.aptBaseSet());
    try testing.expectEqual(@as(u1, 0), ec.isFipsEnabled());
    ec.setAptBaseSet(0);
    try testing.expectEqual(@as(c_uint, 0), c_abi_test.jent_test_c_get_rand_bitfield(&ec, 0));

    // 1: is_fips_enabled:1
    c_abi_test.jent_test_c_set_rand_bitfield(&ec, 1, 1);
    try testing.expectEqual(@as(u1, 1), ec.isFipsEnabled());
    try testing.expectEqual(@as(u1, 0), ec.aptBaseSet());
    ec.setIsFipsEnabled(0);
    try testing.expectEqual(@as(c_uint, 0), c_abi_test.jent_test_c_get_rand_bitfield(&ec, 1));

    // 2: enable_notime:1
    c_abi_test.jent_test_c_set_rand_bitfield(&ec, 2, 1);
    try testing.expectEqual(@as(u1, 1), ec.enableNotime());
    ec.setEnableNotime(0);
    try testing.expectEqual(@as(c_uint, 0), c_abi_test.jent_test_c_get_rand_bitfield(&ec, 2));

    // 3: max_mem_set:1
    c_abi_test.jent_test_c_set_rand_bitfield(&ec, 3, 1);
    try testing.expectEqual(@as(u1, 1), ec.maxMemSet());
    ec.setMaxMemSet(0);
    try testing.expectEqual(@as(c_uint, 0), c_abi_test.jent_test_c_get_rand_bitfield(&ec, 3));

    // 4: in_recovery:1
    c_abi_test.jent_test_c_set_rand_bitfield(&ec, 4, 1);
    try testing.expectEqual(@as(u1, 1), ec.inRecovery());
    ec.setInRecovery(0);
    try testing.expectEqual(@as(c_uint, 0), c_abi_test.jent_test_c_get_rand_bitfield(&ec, 4));

    // 5: stuck_prime:2 (test values 1, 2, 3)
    for ([_]u2{ 1, 2, 3 }) |sp| {
        c_abi_test.jent_test_c_set_rand_bitfield(&ec, 5, sp);
        try testing.expectEqual(sp, ec.stuckPrime());
        try testing.expectEqual(@as(u1, 0), ec.inRecovery());
        try testing.expectEqual(@as(u1, 0), ec.notimeRunning());
    }
    ec.setStuckPrime(2);
    try testing.expectEqual(@as(c_uint, 2), c_abi_test.jent_test_c_get_rand_bitfield(&ec, 5));
    ec.setStuckPrime(0);
    try testing.expectEqual(@as(c_uint, 0), c_abi_test.jent_test_c_get_rand_bitfield(&ec, 5));

    // 6: notime_running:1 (when internal_timer is enabled)
    if (build_options.internal_timer) {
        c_abi_test.jent_test_c_set_rand_bitfield(&ec, 6, 1);
        try testing.expectEqual(@as(u1, 1), ec.notimeRunning());
        try testing.expectEqual(@as(u8, 0xa5), ec.getNotimeInterrupt());
        ec.setNotimeRunning(0);
        try testing.expectEqual(@as(c_uint, 0), c_abi_test.jent_test_c_get_rand_bitfield(&ec, 6));
        try testing.expectEqual(@as(u8, 0xa5), ec.getNotimeInterrupt());
    }

    // Verify neighbor fields were never clobbered
    try testing.expectEqual(@as(c_int, 0x13572468), ec.selftest_failed);
    try testing.expectEqual(@as(u64, 0xdeadbeefcafebabe), ec.jent_common_timer_gcd);
}
