const std = @import("std");
const jent = @import("jent");

/// Exact C header (`jitterentropy.h`) constant definitions for cross-checking
/// public flag bit positions, shifts, masks, and error codes.
const c = struct {
    pub const JENT_DISABLE_STIR: c_uint = 1 << 0;
    pub const JENT_DISABLE_UNBIAS: c_uint = 1 << 1;
    pub const JENT_DISABLE_MEMORY_ACCESS: c_uint = 1 << 2;
    pub const JENT_FORCE_INTERNAL_TIMER: c_uint = 1 << 3;
    pub const JENT_DISABLE_INTERNAL_TIMER: c_uint = 1 << 4;
    pub const JENT_FORCE_FIPS: c_uint = 1 << 5;
    pub const JENT_NTG1: c_uint = 1 << 6;
    pub const JENT_CACHE_ALL: c_uint = 1 << 7;
    pub const JENT_FORCE_SECURE_MEM: c_uint = 1 << 8;
    pub const JENT_INT_MEASURE_CLOCK: c_uint = 1 << 22;

    pub const JENT_MAX_MEMSIZE_OFFSET: c_uint = 9;
    pub const JENT_FLAGS_TO_HASHLOOP_SHIFT: c_uint = 23;
    pub const JENT_FLAGS_TO_MEMSIZE_SHIFT: c_uint = 27;

    pub const JENT_MAX_MEMSIZE_1kB: c_uint = 1 << 27;
    pub const JENT_MAX_MEMSIZE_2kB: c_uint = 2 << 27;
    pub const JENT_MAX_MEMSIZE_4kB: c_uint = 3 << 27;
    pub const JENT_MAX_MEMSIZE_8kB: c_uint = 4 << 27;
    pub const JENT_MAX_MEMSIZE_16kB: c_uint = 5 << 27;
    pub const JENT_MAX_MEMSIZE_32kB: c_uint = 6 << 27;
    pub const JENT_MAX_MEMSIZE_64kB: c_uint = 7 << 27;
    pub const JENT_MAX_MEMSIZE_128kB: c_uint = 8 << 27;
    pub const JENT_MAX_MEMSIZE_256kB: c_uint = 9 << 27;
    pub const JENT_MAX_MEMSIZE_512kB: c_uint = 10 << 27;
    pub const JENT_MAX_MEMSIZE_1MB: c_uint = 11 << 27;
    pub const JENT_MAX_MEMSIZE_2MB: c_uint = 12 << 27;
    pub const JENT_MAX_MEMSIZE_4MB: c_uint = 13 << 27;
    pub const JENT_MAX_MEMSIZE_8MB: c_uint = 14 << 27;
    pub const JENT_MAX_MEMSIZE_16MB: c_uint = 15 << 27;
    pub const JENT_MAX_MEMSIZE_32MB: c_uint = 16 << 27;
    pub const JENT_MAX_MEMSIZE_64MB: c_uint = 17 << 27;
    pub const JENT_MAX_MEMSIZE_128MB: c_uint = 18 << 27;
    pub const JENT_MAX_MEMSIZE_256MB: c_uint = 19 << 27;
    pub const JENT_MAX_MEMSIZE_512MB: c_uint = 20 << 27;
    pub const JENT_MAX_MEMSIZE_MAX: c_uint = JENT_MAX_MEMSIZE_512MB;
    pub const JENT_MAX_MEMSIZE_MASK: c_uint = 0x1f << 27;

    pub const JENT_HASHLOOP_1: c_uint = 1 << 23;
    pub const JENT_HASHLOOP_2: c_uint = 2 << 23;
    pub const JENT_HASHLOOP_4: c_uint = 3 << 23;
    pub const JENT_HASHLOOP_8: c_uint = 4 << 23;
    pub const JENT_HASHLOOP_16: c_uint = 5 << 23;
    pub const JENT_HASHLOOP_32: c_uint = 6 << 23;
    pub const JENT_HASHLOOP_64: c_uint = 7 << 23;
    pub const JENT_HASHLOOP_128: c_uint = 8 << 23;
    pub const JENT_MAX_HASHLOOP: c_uint = JENT_HASHLOOP_128;
    pub const JENT_MAX_HASHLOOP_MASK: c_uint = 0xf << 23;

    pub const JENT_MIN_OSR: c_uint = 3;
    pub const JENT_MAX_OSR: c_uint = 20;
    pub const JENT_UUID_STRLEN: usize = 37;

    pub const JENT_RCT_FAILURE: c_uint = 1 << 0;
    pub const JENT_APT_FAILURE: c_uint = 1 << 1;
    pub const JENT_LAG_FAILURE: c_uint = 1 << 2;
    pub const JENT_RCT_MEM_FAILURE: c_uint = 1 << 3;
    pub const JENT_PERMANENT_FAILURE_SHIFT: c_uint = 16;
    pub const JENT_RCT_FAILURE_PERMANENT: c_uint = 1 << 16;
    pub const JENT_APT_FAILURE_PERMANENT: c_uint = 1 << 17;
    pub const JENT_LAG_FAILURE_PERMANENT: c_uint = 1 << 18;
    pub const JENT_RCT_MEM_FAILURE_PERMANENT: c_uint = 1 << 19;

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

    pub const JENT_ERR_EINVAL: isize = -1;
    pub const JENT_ERR_RCT: isize = -2;
    pub const JENT_ERR_APT: isize = -3;
    pub const JENT_ERR_NOTIME: isize = -4;
    pub const JENT_ERR_LAG: isize = -5;
    pub const JENT_ERR_RCT_PERMANENT: isize = -6;
    pub const JENT_ERR_APT_PERMANENT: isize = -7;
    pub const JENT_ERR_LAG_PERMANENT: isize = -8;
    pub const JENT_ERR_RCT_MEM: isize = -9;
    pub const JENT_ERR_RCT_MEM_PERMANENT: isize = -10;
    pub const JENT_ERR_SELFTEST: isize = -11;
};

comptime {
    std.debug.assert(jent.JENT_DISABLE_STIR == (1 << 0));
    std.debug.assert(jent.JENT_DISABLE_UNBIAS == (1 << 1));
    std.debug.assert(jent.JENT_DISABLE_MEMORY_ACCESS == (1 << 2));
    std.debug.assert(jent.JENT_FORCE_INTERNAL_TIMER == (1 << 3));
    std.debug.assert(jent.JENT_DISABLE_INTERNAL_TIMER == (1 << 4));
    std.debug.assert(jent.JENT_FORCE_FIPS == (1 << 5));
    std.debug.assert(jent.JENT_NTG1 == (1 << 6));
    std.debug.assert(jent.JENT_CACHE_ALL == (1 << 7));
    std.debug.assert(jent.JENT_FORCE_SECURE_MEM == (1 << 8));
    std.debug.assert(jent.JENT_INT_MEASURE_CLOCK == (1 << 22));
}

fn verifyPublicFlagsAndAbiLayout() !void {
    try std.testing.expectEqual(@as(c_uint, 1 << 0), jent.JENT_DISABLE_STIR);
    try std.testing.expectEqual(@as(c_uint, 1 << 1), jent.JENT_DISABLE_UNBIAS);
    try std.testing.expectEqual(@as(c_uint, 1 << 2), jent.JENT_DISABLE_MEMORY_ACCESS);
    try std.testing.expectEqual(@as(c_uint, 1 << 3), jent.JENT_FORCE_INTERNAL_TIMER);
    try std.testing.expectEqual(@as(c_uint, 1 << 4), jent.JENT_DISABLE_INTERNAL_TIMER);
    try std.testing.expectEqual(@as(c_uint, 1 << 5), jent.JENT_FORCE_FIPS);
    try std.testing.expectEqual(@as(c_uint, 1 << 6), jent.JENT_NTG1);
    try std.testing.expectEqual(@as(c_uint, 1 << 7), jent.JENT_CACHE_ALL);
    try std.testing.expectEqual(@as(c_uint, 1 << 8), jent.JENT_FORCE_SECURE_MEM);
    try std.testing.expectEqual(@as(c_uint, 1 << 22), jent.JENT_INT_MEASURE_CLOCK);

    try std.testing.expectEqual(c.JENT_DISABLE_STIR, jent.JENT_DISABLE_STIR);
    try std.testing.expectEqual(c.JENT_DISABLE_UNBIAS, jent.JENT_DISABLE_UNBIAS);
    try std.testing.expectEqual(c.JENT_DISABLE_MEMORY_ACCESS, jent.JENT_DISABLE_MEMORY_ACCESS);
    try std.testing.expectEqual(c.JENT_FORCE_INTERNAL_TIMER, jent.JENT_FORCE_INTERNAL_TIMER);
    try std.testing.expectEqual(c.JENT_DISABLE_INTERNAL_TIMER, jent.JENT_DISABLE_INTERNAL_TIMER);
    try std.testing.expectEqual(c.JENT_FORCE_FIPS, jent.JENT_FORCE_FIPS);
    try std.testing.expectEqual(c.JENT_NTG1, jent.JENT_NTG1);
    try std.testing.expectEqual(c.JENT_CACHE_ALL, jent.JENT_CACHE_ALL);
    try std.testing.expectEqual(c.JENT_FORCE_SECURE_MEM, jent.JENT_FORCE_SECURE_MEM);
    try std.testing.expectEqual(c.JENT_INT_MEASURE_CLOCK, jent.JENT_INT_MEASURE_CLOCK);

    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_OFFSET, jent.JENT_MAX_MEMSIZE_OFFSET);
    try std.testing.expectEqual(c.JENT_FLAGS_TO_HASHLOOP_SHIFT, @as(c_uint, jent.JENT_FLAGS_TO_HASHLOOP_SHIFT));
    try std.testing.expectEqual(c.JENT_FLAGS_TO_MEMSIZE_SHIFT, @as(c_uint, jent.JENT_FLAGS_TO_MEMSIZE_SHIFT));

    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_1kB, jent.JENT_MAX_MEMSIZE_1kB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_2kB, jent.JENT_MAX_MEMSIZE_2kB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_4kB, jent.JENT_MAX_MEMSIZE_4kB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_8kB, jent.JENT_MAX_MEMSIZE_8kB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_16kB, jent.JENT_MAX_MEMSIZE_16kB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_32kB, jent.JENT_MAX_MEMSIZE_32kB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_64kB, jent.JENT_MAX_MEMSIZE_64kB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_128kB, jent.JENT_MAX_MEMSIZE_128kB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_256kB, jent.JENT_MAX_MEMSIZE_256kB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_512kB, jent.JENT_MAX_MEMSIZE_512kB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_1MB, jent.JENT_MAX_MEMSIZE_1MB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_2MB, jent.JENT_MAX_MEMSIZE_2MB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_4MB, jent.JENT_MAX_MEMSIZE_4MB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_8MB, jent.JENT_MAX_MEMSIZE_8MB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_16MB, jent.JENT_MAX_MEMSIZE_16MB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_32MB, jent.JENT_MAX_MEMSIZE_32MB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_64MB, jent.JENT_MAX_MEMSIZE_64MB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_128MB, jent.JENT_MAX_MEMSIZE_128MB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_256MB, jent.JENT_MAX_MEMSIZE_256MB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_512MB, jent.JENT_MAX_MEMSIZE_512MB);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_MAX, jent.JENT_MAX_MEMSIZE_MAX);
    try std.testing.expectEqual(c.JENT_MAX_MEMSIZE_MASK, jent.JENT_MAX_MEMSIZE_MASK);

    try std.testing.expectEqual(c.JENT_HASHLOOP_1, jent.JENT_HASHLOOP_1);
    try std.testing.expectEqual(c.JENT_HASHLOOP_2, jent.JENT_HASHLOOP_2);
    try std.testing.expectEqual(c.JENT_HASHLOOP_4, jent.JENT_HASHLOOP_4);
    try std.testing.expectEqual(c.JENT_HASHLOOP_8, jent.JENT_HASHLOOP_8);
    try std.testing.expectEqual(c.JENT_HASHLOOP_16, jent.JENT_HASHLOOP_16);
    try std.testing.expectEqual(c.JENT_HASHLOOP_32, jent.JENT_HASHLOOP_32);
    try std.testing.expectEqual(c.JENT_HASHLOOP_64, jent.JENT_HASHLOOP_64);
    try std.testing.expectEqual(c.JENT_HASHLOOP_128, jent.JENT_HASHLOOP_128);
    try std.testing.expectEqual(c.JENT_MAX_HASHLOOP, jent.JENT_MAX_HASHLOOP);
    try std.testing.expectEqual(c.JENT_MAX_HASHLOOP_MASK, jent.JENT_MAX_HASHLOOP_MASK);

    try std.testing.expectEqual(c.JENT_MIN_OSR, jent.JENT_MIN_OSR);
    try std.testing.expectEqual(c.JENT_MAX_OSR, jent.JENT_MAX_OSR);
    try std.testing.expectEqual(c.JENT_UUID_STRLEN, jent.JENT_UUID_STRLEN);

    try std.testing.expectEqual(c.JENT_RCT_FAILURE, jent.JENT_RCT_FAILURE);
    try std.testing.expectEqual(c.JENT_APT_FAILURE, jent.JENT_APT_FAILURE);
    try std.testing.expectEqual(c.JENT_LAG_FAILURE, jent.JENT_LAG_FAILURE);
    try std.testing.expectEqual(c.JENT_RCT_MEM_FAILURE, jent.JENT_RCT_MEM_FAILURE);
    try std.testing.expectEqual(c.JENT_PERMANENT_FAILURE_SHIFT, @as(c_uint, jent.JENT_PERMANENT_FAILURE_SHIFT));
    try std.testing.expectEqual(c.JENT_RCT_FAILURE_PERMANENT, jent.JENT_RCT_FAILURE_PERMANENT);
    try std.testing.expectEqual(c.JENT_APT_FAILURE_PERMANENT, jent.JENT_APT_FAILURE_PERMANENT);
    try std.testing.expectEqual(c.JENT_LAG_FAILURE_PERMANENT, jent.JENT_LAG_FAILURE_PERMANENT);
    try std.testing.expectEqual(c.JENT_RCT_MEM_FAILURE_PERMANENT, jent.JENT_RCT_MEM_FAILURE_PERMANENT);

    try std.testing.expectEqual(c.ENOTIME, jent.ENOTIME);
    try std.testing.expectEqual(c.ECOARSETIME, jent.ECOARSETIME);
    try std.testing.expectEqual(c.ENOMONOTONIC, jent.ENOMONOTONIC);
    try std.testing.expectEqual(c.EMINVARIATION, jent.EMINVARIATION);
    try std.testing.expectEqual(c.EVARVAR, jent.EVARVAR);
    try std.testing.expectEqual(c.EMINVARVAR, jent.EMINVARVAR);
    try std.testing.expectEqual(c.EPROGERR, jent.EPROGERR);
    try std.testing.expectEqual(c.ESTUCK, jent.ESTUCK);
    try std.testing.expectEqual(c.EHEALTH, jent.EHEALTH);
    try std.testing.expectEqual(c.ERCT, jent.ERCT);
    try std.testing.expectEqual(c.EHASH, jent.EHASH);
    try std.testing.expectEqual(c.EMEM, jent.EMEM);
    try std.testing.expectEqual(c.EGCD, jent.EGCD);

    try std.testing.expectEqual(c.JENT_ERR_EINVAL, jent.JENT_ERR_EINVAL);
    try std.testing.expectEqual(c.JENT_ERR_RCT, jent.JENT_ERR_RCT);
    try std.testing.expectEqual(c.JENT_ERR_APT, jent.JENT_ERR_APT);
    try std.testing.expectEqual(c.JENT_ERR_NOTIME, jent.JENT_ERR_NOTIME);
    try std.testing.expectEqual(c.JENT_ERR_LAG, jent.JENT_ERR_LAG);
    try std.testing.expectEqual(c.JENT_ERR_RCT_PERMANENT, jent.JENT_ERR_RCT_PERMANENT);
    try std.testing.expectEqual(c.JENT_ERR_APT_PERMANENT, jent.JENT_ERR_APT_PERMANENT);
    try std.testing.expectEqual(c.JENT_ERR_LAG_PERMANENT, jent.JENT_ERR_LAG_PERMANENT);
    try std.testing.expectEqual(c.JENT_ERR_RCT_MEM, jent.JENT_ERR_RCT_MEM);
    try std.testing.expectEqual(c.JENT_ERR_RCT_MEM_PERMANENT, jent.JENT_ERR_RCT_MEM_PERMANENT);
    try std.testing.expectEqual(c.JENT_ERR_SELFTEST, jent.JENT_ERR_SELFTEST);

    // Struct layout invariants for C ABI structs
    try std.testing.expectEqual(@as(usize, 4 * @sizeOf(*const anyopaque)), @sizeOf(jent.jent_notime_thread));
    try std.testing.expectEqual(@as(usize, @alignOf(*const anyopaque)), @alignOf(jent.jent_notime_thread));
    try std.testing.expectEqual(@as(usize, 0 * @sizeOf(*const anyopaque)), @offsetOf(jent.jent_notime_thread, "jent_notime_init"));
    try std.testing.expectEqual(@as(usize, 1 * @sizeOf(*const anyopaque)), @offsetOf(jent.jent_notime_thread, "jent_notime_fini"));
    try std.testing.expectEqual(@as(usize, 2 * @sizeOf(*const anyopaque)), @offsetOf(jent.jent_notime_thread, "jent_notime_start"));
    try std.testing.expectEqual(@as(usize, 3 * @sizeOf(*const anyopaque)), @offsetOf(jent.jent_notime_thread, "jent_notime_stop"));
}

test "JENT_* public flag constants match jitterentropy.h bit values" {
    try verifyPublicFlagsAndAbiLayout();
}

pub fn main() !void {
    try verifyPublicFlagsAndAbiLayout();
}
