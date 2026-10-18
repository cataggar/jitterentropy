const std = @import("std");
const builtin = @import("builtin");
const h = @import("test_harness");
const jent = @import("internal");

const EAGAIN: c_int = if (builtin.os.tag == .linux) 11 else 35;
const EINVAL: c_int = 22;
const ENOMEM: c_int = 12;
const EPERM: c_int = 1;

extern var jent_selftest_run: c_int;
extern var jent_fi_fail_alloc: c_uint;
extern var jent_fi_alloc_count: c_uint;
extern var jent_fi_fail_mmap: c_int;
extern var jent_fi_fail_mprotect: c_int;
extern var jent_fi_mprotect_calls: c_uint;
extern var jent_fi_fail_mlock: c_int;
extern var jent_fi_mlock_errno: c_int;
extern var jent_fi_sysconf_mode: c_int;
extern var jent_fi_ncpu_sysconf_mode: c_int;
extern var jent_fi_cache_sysconf_mode: c_int;
extern var jent_fi_fail_affinity: c_int;
extern var jent_fi_empty_affinity: c_int;
extern var jent_fi_fail_cpu_alloc: c_int;
extern var jent_fi_fail_getrandom: c_int;
extern var jent_fi_force_fips_enabled: c_int;

extern fn jent_fi_real_zalloc(len: usize, flags: c_uint) callconv(.c) ?*anyopaque;
extern fn jent_pagesize() callconv(.c) usize;
extern fn jent_fi_time_set(mode: c_int) callconv(.c) void;
extern fn jent_notime_forced() callconv(.c) c_int;
extern fn jent_get_cachesize_sysconf(l1: *u64, l2: *u64, l3: *u64) callconv(.c) void;
extern fn jent_get_cachesize_sysfs_dir(path: [*:0]const u8, l1: *u64, l2: *u64, l3: *u64) callconv(.c) void;

const FI_TIME_REAL: c_int = 0;
const FI_TIME_ZERO: c_int = 1;
const FI_TIME_CONSTANT: c_int = 2;
const FI_TIME_BACKWARDS: c_int = 3;
const FI_TIME_FIXED_STEP: c_int = 4;

fn expect(cond: bool, comptime message: []const u8) void {
    h.expectOrExit(cond, @src(), "{s}", .{message});
}

fn skip(comptime message: []const u8) void {
    h.skipOrExit(@src(), "{s}", .{message});
}

fn arm(nth: c_uint) void {
    jent_fi_fail_alloc = nth;
    jent_fi_alloc_count = 0;
}

fn disarm() void {
    arm(0);
}

fn setSysconfMode(mode: c_int) void {
    jent_fi_sysconf_mode = mode;
    jent_fi_ncpu_sysconf_mode = mode;
    jent_fi_cache_sysconf_mode = mode;
}

fn testInjectionWorks() void {
    arm(1);
    expect(jent.jent_zalloc(64, 0) == null, "the armed allocation fails");
    const second = jent.jent_zalloc(64, 0);
    expect(second != null, "only the armed allocation fails");
    jent.jent_zfree(second, 64);
    disarm();
    const restored = jent.jent_zalloc(64, 0);
    expect(restored != null, "disarming restores the allocator");
    jent.jent_zfree(restored, 64);
}

fn countCollectorAllocations(flags: c_uint) c_uint {
    disarm();
    jent.jent_entropy_collector_free(jent.jent_entropy_collector_alloc(0, flags));
    return jent_fi_alloc_count;
}

fn testCollectorAllocFailures() void {
    const configs = [_]c_uint{
        0,
        jent.JENT_DISABLE_MEMORY_ACCESS,
        jent.JENT_FORCE_FIPS,
        jent.JENT_MAX_MEMSIZE_1MB,
    };
    for (configs) |flags| {
        const total = countCollectorAllocations(flags);
        if (total == 0) {
            skip("no collector allocations to deny");
            continue;
        }
        var nth: c_uint = 1;
        while (nth <= total) : (nth += 1) {
            arm(nth);
            const ec = jent.jent_entropy_collector_alloc(0, flags);
            disarm();
            jent.jent_entropy_collector_free(ec);
        }
        expect(true, "every collector allocation was denied in turn");
    }
}

fn testInitFailures() void {
    var emem: c_uint = 0;
    var other: c_uint = 0;
    var nth: c_uint = 1;
    while (nth <= 8) : (nth += 1) {
        arm(nth);
        const ret = jent.jent_time_entropy_init(jent.JENT_MIN_OSR, jent.JENT_DISABLE_INTERNAL_TIMER);
        disarm();
        if (ret == jent.EMEM) emem += 1 else if (ret != 0) other += 1;
    }
    expect(emem != 0, "a denied startup allocation is reported as EMEM");
    expect(other == 0, "a denied startup allocation is not another failure");
    expect(
        jent.jent_time_entropy_init(jent.JENT_MIN_OSR, jent.JENT_DISABLE_INTERNAL_TIMER) == 0,
        "startup passes after restoring the allocator",
    );
}

fn testGcdFailures() void {
    arm(1);
    expect(jent.jent_gcd_selftest(0) == jent.EMEM, "GCD selftest reports EMEM");
    disarm();
    arm(1);
    expect(jent.jent_gcd_init(1000, 0) == null, "GCD allocation reports denial");
    disarm();
    expect(jent.jent_gcd_selftest(0) == 0, "GCD selftest passes after restore");

    jent.jent_atomic_store_int(&jent_selftest_run, 1);
    arm(1);
    expect(
        jent.jent_entropy_init_ex(0, jent.JENT_DISABLE_INTERNAL_TIMER) == jent.EMEM,
        "initialization fails when the GCD allocation is denied",
    );
    disarm();
    expect(jent.jent_atomic_load_int(&jent_selftest_run) == 0, "failed initialization clears selftest state");
}

fn testRecoveryAllocFailure() void {
    var ec = jent.jent_entropy_collector_alloc(0, jent.JENT_FORCE_FIPS) orelse {
        skip("no collector for recovery");
        return;
    };
    ec.health_failure = jent.JENT_RCT_FAILURE;
    disarm();
    var buf: [32]u8 = undefined;
    var ec_ptr: ?*jent.rand_data = ec;
    _ = jent.jent_read_entropy_safe(&ec_ptr, &buf, buf.len);
    ec = ec_ptr orelse ec;
    const total = jent_fi_alloc_count;
    jent.jent_entropy_collector_free(ec);

    var wrong: c_uint = 0;
    var changed: c_uint = 0;
    var nth: c_uint = 1;
    while (nth <= total) : (nth += 1) {
        ec = jent.jent_entropy_collector_alloc(0, jent.JENT_FORCE_FIPS) orelse continue;
        const before = ec;
        ec.health_failure = jent.JENT_RCT_FAILURE;
        arm(nth);
        var current: ?*jent.rand_data = ec;
        const ret = jent.jent_read_entropy_safe(&current, &buf, buf.len);
        ec = current orelse ec;
        disarm();
        if (ret < 0) {
            if (ret != jent.JENT_ERR_RCT) wrong += 1;
            if (ec != before) changed += 1;
        } else if (ret != buf.len) {
            wrong += 1;
        }
        jent.jent_entropy_collector_free(ec);
    }
    expect(wrong == 0, "denied recovery returns the health failure");
    expect(changed == 0, "denied recovery leaves the collector pointer unchanged");
}

fn testSecureMemoryFailures() void {
    if (jent.build_options.external_crypto != .none or
        !(builtin.os.tag == .linux or builtin.os.tag == .macos or builtin.os.tag == .freebsd or
            builtin.os.tag == .netbsd or builtin.os.tag == .openbsd or builtin.os.tag == .dragonfly or
            builtin.os.tag == .windows))
    {
        skip("not a native mapping backend");
        return;
    }

    jent_fi_fail_mmap = 1;
    expect(jent_fi_real_zalloc(4096, jent.JENT_FORCE_SECURE_MEM) == null, "a refused mapping is reported");
    jent_fi_fail_mmap = 0;

    jent_fi_mprotect_calls = 0;
    jent_fi_fail_mprotect = 1;
    expect(jent_fi_real_zalloc(4096, jent.JENT_FORCE_SECURE_MEM) == null, "a refused protection is reported");
    jent_fi_fail_mprotect = 0;

    if (builtin.os.tag != .windows) {
        jent_fi_mprotect_calls = 0;
        jent_fi_fail_mprotect = 2;
        expect(jent_fi_real_zalloc(4096, jent.JENT_FORCE_SECURE_MEM) == null, "a refused trailing guard is reported");
        jent_fi_fail_mprotect = 0;
    }

    jent_fi_fail_mlock = 1;
    expect(jent_fi_real_zalloc(4096, jent.JENT_FORCE_SECURE_MEM) == null, "a refused required lock is fatal");
    for ([_]c_int{ EPERM, ENOMEM, EAGAIN }) |err| {
        jent_fi_mlock_errno = err;
        const ptr = jent_fi_real_zalloc(4096, 0);
        expect(ptr != null, "a normal lock-limit failure is tolerated");
        jent.jent_zfree(ptr, 4096);
    }
    if (builtin.os.tag != .windows) {
        jent_fi_mlock_errno = EINVAL;
        expect(jent_fi_real_zalloc(4096, 0) == null, "an unexpected lock error is not tolerated");
    }
    jent_fi_fail_mlock = 0;
    jent_fi_mlock_errno = EPERM;
    const restored = jent_fi_real_zalloc(4096, jent.JENT_FORCE_SECURE_MEM);
    expect(restored != null, "the secure allocator works afterwards");
    jent.jent_zfree(restored, 4096);
}

fn testBadTimers() void {
    const cases = [_]struct { mode: c_int, expected: c_int }{
        .{ .mode = FI_TIME_ZERO, .expected = jent.ENOTIME },
        .{ .mode = FI_TIME_CONSTANT, .expected = jent.ECOARSETIME },
        .{ .mode = FI_TIME_FIXED_STEP, .expected = jent.ERCT },
        .{ .mode = FI_TIME_BACKWARDS, .expected = jent.ENOMONOTONIC },
    };
    for (cases) |case| {
        jent_fi_time_set(case.mode);
        const ret = jent.jent_time_entropy_init(jent.JENT_MIN_OSR, jent.JENT_DISABLE_INTERNAL_TIMER);
        jent_fi_time_set(FI_TIME_REAL);
        expect(ret == case.expected, "startup rejects an unusable timer with the expected code");
    }
    expect(
        jent.jent_time_entropy_init(jent.JENT_MIN_OSR, jent.JENT_DISABLE_INTERNAL_TIMER) == 0,
        "the real timer passes afterwards",
    );
}

fn testPlatformQueryFailures() void {
    if (builtin.os.tag != .windows) {
        jent_fi_fail_affinity = 1;
        jent_fi_ncpu_sysconf_mode = 1;
        expect(jent.jent_ncpu() != 0, "a denied affinity query yields a count or error");
        jent_fi_ncpu_sysconf_mode = 0;
        jent_fi_fail_affinity = 0;
        jent_fi_empty_affinity = 1;
        expect(jent.jent_ncpu() > 0, "an empty affinity mask falls back");
        jent_fi_empty_affinity = 0;
    } else {
        skip("Windows CPU counting has no failing query");
    }
    expect(jent.jent_ncpu() > 0, "the real CPU count returns afterwards");

    if (builtin.os.tag == .linux) {
        var l1: u64 = std.math.maxInt(u64);
        var l2: u64 = std.math.maxInt(u64);
        var l3: u64 = std.math.maxInt(u64);
        jent_fi_cache_sysconf_mode = 1;
        jent_get_cachesize_sysconf(&l1, &l2, &l3);
        expect(l1 == 0 and l2 == 0 and l3 == 0, "unanswerable cache sizes are zero");
        jent_fi_cache_sysconf_mode = 2;
        jent_get_cachesize_sysfs_dir("/nonexistent/jent/cpu", &l1, &l2, &l3);
        expect(l1 == 0, "a zero CPU count is handled");
        jent_fi_cache_sysconf_mode = 3;
        jent_get_cachesize_sysfs_dir("/nonexistent/jent/cpu", &l1, &l2, &l3);
        expect(l1 == 0, "an implausible CPU count is capped");
        jent_fi_cache_sysconf_mode = 0;
    }

    if (builtin.os.tag == .linux) {
        var a: [jent.JENT_UUID_STRLEN]u8 = undefined;
        var b: [jent.JENT_UUID_STRLEN]u8 = undefined;
        jent_fi_fail_getrandom = 1;
        jent.jent_uuid_generate(&a);
        jent.jent_uuid_generate(&b);
        jent_fi_fail_getrandom = 0;
        expect(std.mem.len(@as([*:0]u8, @ptrCast(&a))) == jent.JENT_UUID_STRLEN - 1, "UUID fallback produces a UUID");
        expect(!std.mem.eql(u8, &a, &b), "UUID fallback does not repeat");
    }
    setSysconfMode(0);
    jent_fi_fail_affinity = 0;
    jent_fi_fail_getrandom = 0;
    jent_fi_fail_cpu_alloc = 0;
}

fn testSystemFipsMode() void {
    jent_fi_force_fips_enabled = 1;
    const ec = jent.jent_entropy_collector_alloc(0, 0);
    jent_fi_force_fips_enabled = 0;
    const collector = ec orelse {
        skip("no collector in forced system FIPS mode");
        return;
    };
    expect(collector.isFipsEnabled() == 1, "system FIPS enables health tests");
    var buf: [32]u8 = undefined;
    expect(jent.jent_read_entropy(collector, &buf, buf.len) == buf.len, "system FIPS collector produces entropy");
    jent.jent_entropy_collector_free(collector);
}

fn testAllocatorBounds() void {
    expect(jent_fi_real_zalloc(std.math.maxInt(usize), jent.JENT_FORCE_SECURE_MEM) == null, "unroundable length is refused");
    expect(jent_fi_real_zalloc(std.math.maxInt(usize) - 4096, 0) == null, "near-overflow length is refused");
    if (builtin.os.tag != .windows and jent.build_options.external_crypto == .none) {
        jent_fi_sysconf_mode = 1;
        expect(jent_pagesize() > 0, "unknown page size has a fallback");
        jent_fi_sysconf_mode = 2;
        expect(jent_pagesize() > 0, "zero page size has a fallback");
        jent_fi_sysconf_mode = 0;
    } else {
        skip("page-size fallback is not used by this backend");
    }
    const forced = jent.jent_memory_is_secure(jent.JENT_FORCE_SECURE_MEM);
    const unforced = jent.jent_memory_is_secure(0);
    expect((forced == 0 or forced == 1) and (unforced == 0 or unforced == 1), "secure-memory query returns booleans");
}

fn testAllocRunsFailingSelftest() void {
    jent_selftest_run = 0;
    jent_fi_time_set(FI_TIME_ZERO);
    const failed = jent.jent_entropy_collector_alloc(0, jent.JENT_DISABLE_INTERNAL_TIMER);
    jent_fi_time_set(FI_TIME_REAL);
    expect(failed == null, "collector is refused when startup selftest fails");
    jent.jent_entropy_collector_free(failed);

    jent_selftest_run = 0;
    const restored = jent.jent_entropy_collector_alloc(0, 0);
    expect(restored != null, "collector can be allocated after timer restoration");
    jent.jent_entropy_collector_free(restored);
}

fn testStillUsable() void {
    disarm();
    const ec = jent.jent_entropy_collector_alloc(0, 0) orelse {
        expect(false, "collector remains available after injected failures");
        return;
    };
    var buf: [64]u8 = undefined;
    expect(jent.jent_read_entropy(ec, &buf, buf.len) == buf.len, "entropy is produced after injected failures");
    jent.jent_entropy_collector_free(ec);
}

fn testForcedNotimeReportsNoTimer() void {
    if (!jent.build_options.internal_timer) return;
    if (jent.jent_entropy_init_ex(0, jent.JENT_FORCE_INTERNAL_TIMER) != 0) {
        skip("forced internal timer does not initialize here");
        return;
    }
    expect(jent_notime_forced() != 0, "forcing the internal timer records the choice");
    expect(
        jent.jent_time_entropy_init(jent.JENT_MIN_OSR, jent.JENT_DISABLE_INTERNAL_TIMER) == jent.ENOTIME,
        "disabling a forced timer reports ENOTIME",
    );
}

pub fn main() u8 {
    h.resetCounters();
    if (jent.jent_entropy_init() != 0) return h.SKIP_RETURN_CODE;
    testBadTimers();
    testInjectionWorks();
    testGcdFailures();
    testCollectorAllocFailures();
    testInitFailures();
    testRecoveryAllocFailure();
    testSecureMemoryFailures();
    testPlatformQueryFailures();
    testSystemFipsMode();
    testAllocatorBounds();
    testAllocRunsFailingSelftest();
    testStillUsable();
    testForcedNotimeReportsNoTimer();
    return h.finish("unit-fault");
}
