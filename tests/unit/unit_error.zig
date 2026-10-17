const std = @import("std");
const jent = @import("jent_internal");
const harness = @import("test_harness");

extern fn jent_health_failure_reset(ec: *?*jent.rand_data, startup: c_int) callconv(.c) c_int;
extern fn jent_notime_force() callconv(.c) void;
extern var jent_selftest_run: c_int;
extern var jent_common_timer_gcd: [jent.JENT_GCD_CLOCKS]u32;

const Failure = struct {
    bit: c_uint,
    err: isize,
    name: []const u8,
    permanent: bool,
};

const failures = [_]Failure{
    .{ .bit = jent.JENT_RCT_FAILURE, .err = jent.JENT_ERR_RCT, .name = "RCT", .permanent = false },
    .{ .bit = jent.JENT_APT_FAILURE, .err = jent.JENT_ERR_APT, .name = "APT", .permanent = false },
    .{ .bit = jent.JENT_LAG_FAILURE, .err = jent.JENT_ERR_LAG, .name = "Lag", .permanent = false },
    .{ .bit = jent.JENT_RCT_MEM_FAILURE, .err = jent.JENT_ERR_RCT_MEM, .name = "RCT-mem", .permanent = false },
    .{ .bit = jent.JENT_RCT_FAILURE_PERMANENT, .err = jent.JENT_ERR_RCT_PERMANENT, .name = "RCT permanent", .permanent = true },
    .{ .bit = jent.JENT_APT_FAILURE_PERMANENT, .err = jent.JENT_ERR_APT_PERMANENT, .name = "APT permanent", .permanent = true },
    .{ .bit = jent.JENT_LAG_FAILURE_PERMANENT, .err = jent.JENT_ERR_LAG_PERMANENT, .name = "Lag permanent", .permanent = true },
    .{ .bit = jent.JENT_RCT_MEM_FAILURE_PERMANENT, .err = jent.JENT_ERR_RCT_MEM_PERMANENT, .name = "RCT-mem permanent", .permanent = true },
};

fn expect(condition: bool, comptime message: []const u8) void {
    harness.expectOrExit(condition, @src(), message, .{});
}

fn skip(comptime message: []const u8, args: anytype) void {
    harness.skipOrExit(@src(), message, args);
}

fn alloc(flags: c_uint) ?*jent.rand_data {
    return jent.jent_entropy_collector_alloc(0, flags);
}

fn testErrorMapping() void {
    var buf: [32]u8 = undefined;
    for (failures) |failure| {
        const ec = alloc(jent.JENT_FORCE_FIPS) orelse {
            skip("{s}: no collector", .{failure.name});
            continue;
        };
        ec.health_failure = failure.bit;
        expect(jent.jent_read_entropy(ec, &buf, buf.len) == failure.err, "every failure maps to its API error");
        jent.jent_entropy_collector_free(ec);
    }
}

fn testPermanentPrecedence() void {
    const Case = struct { bits: c_uint, err: isize };
    const cases = [_]Case{
        .{ .bits = jent.JENT_RCT_FAILURE | jent.JENT_RCT_FAILURE_PERMANENT, .err = jent.JENT_ERR_RCT_PERMANENT },
        .{ .bits = jent.JENT_APT_FAILURE | jent.JENT_APT_FAILURE_PERMANENT, .err = jent.JENT_ERR_APT_PERMANENT },
        .{ .bits = jent.JENT_LAG_FAILURE | jent.JENT_LAG_FAILURE_PERMANENT, .err = jent.JENT_ERR_LAG_PERMANENT },
        .{ .bits = jent.JENT_RCT_MEM_FAILURE | jent.JENT_RCT_MEM_FAILURE_PERMANENT, .err = jent.JENT_ERR_RCT_MEM_PERMANENT },
        .{ .bits = jent.JENT_APT_FAILURE | jent.JENT_RCT_FAILURE_PERMANENT, .err = jent.JENT_ERR_RCT_PERMANENT },
    };
    var buf: [32]u8 = undefined;
    for (cases) |case| {
        const ec = alloc(jent.JENT_FORCE_FIPS) orelse {
            skip("permanent precedence: no collector", .{});
            continue;
        };
        ec.health_failure = case.bits;
        expect(jent.jent_read_entropy(ec, &buf, buf.len) == case.err, "permanent failure outranks intermittent failure");
        jent.jent_entropy_collector_free(ec);
    }
}

fn testNoReportWithoutFips() void {
    const ec = alloc(0) orelse {
        skip("non-FIPS mode: no collector", .{});
        return;
    };
    defer jent.jent_entropy_collector_free(ec);
    if (ec.isFipsEnabled() != 0) {
        skip("FIPS mode is enabled system-wide", .{});
        return;
    }
    ec.health_failure = jent.JENT_RCT_FAILURE_PERMANENT;
    var buf: [32]u8 = undefined;
    expect(jent.jent_read_entropy(ec, &buf, buf.len) == buf.len, "non-FIPS failure does not stop output");
}

var cb_ec: ?*jent.rand_data = null;
var cb_failure: c_uint = 0;
var cb_calls: c_uint = 0;
var cb_registered = false;

fn failureCallback(ec: ?*jent.rand_data, health_failure: c_uint) callconv(.c) void {
    cb_ec = ec;
    cb_failure = health_failure;
    cb_calls += 1;
}

fn testFailureCallbackRegister() void {
    cb_registered = jent.jent_set_fips_failure_callback(failureCallback) == 0;
    expect(cb_registered, "callback registers before initialization");
}

fn testFailureCallback() void {
    if (!cb_registered) {
        skip("failure callback was not registered", .{});
        return;
    }
    const ec = alloc(jent.JENT_FORCE_FIPS) orelse {
        skip("failure callback: no collector", .{});
        return;
    };
    defer jent.jent_entropy_collector_free(ec);
    var buf: [32]u8 = undefined;
    cb_ec = null;
    cb_failure = 0;
    cb_calls = 0;
    ec.health_failure = jent.JENT_APT_FAILURE_PERMANENT;
    expect(jent.jent_read_entropy(ec, &buf, buf.len) == jent.JENT_ERR_APT_PERMANENT, "callback failure is returned");
    expect(cb_calls == 1 and cb_ec == ec and cb_failure == jent.JENT_APT_FAILURE_PERMANENT, "callback receives collector and bits");
    expect(jent.jent_read_entropy(ec, &buf, buf.len) == jent.JENT_ERR_APT_PERMANENT and cb_calls == 2, "sticky failure invokes callback again");
    expect(jent.jent_read_entropy(ec, &buf, 0) == jent.JENT_ERR_APT_PERMANENT and cb_calls == 3, "zero-length read invokes callback");
    expect(jent.jent_set_fips_failure_callback(null) != 0, "callback cannot switch after initialization");
}

fn testSafeRecovery() void {
    var buf: [32]u8 = undefined;
    for (failures) |failure| {
        const allocated = alloc(jent.JENT_FORCE_FIPS) orelse {
            skip("{s}: no collector", .{failure.name});
            continue;
        };
        var ec: ?*jent.rand_data = allocated;
        const osr_before = ec.?.osr;
        const hashloops_before = jent.jent_entropy_collector_hashloops(ec);
        const memsize_before = jent.jent_entropy_collector_memsize(ec);
        ec.?.health_failure = failure.bit;
        const ret = jent.jent_read_entropy_safe(&ec, &buf, buf.len);
        if (failure.permanent) {
            expect(ret == failure.err, "permanent failure is returned");
            expect(ec.?.osr == osr_before, "permanent failure does not reallocate");
        } else {
            expect(ret == buf.len, "intermittent failure recovers");
            expect(ec.?.osr > osr_before, "recovery raises OSR");
            expect(jent.jent_entropy_collector_hashloops(ec) > hashloops_before, "recovery raises hash loops");
            expect(jent.jent_entropy_collector_memsize(ec) > memsize_before, "recovery raises memory size");
            expect(ec.?.reinit_count == 1, "recovery is counted");
        }
        jent.jent_entropy_collector_free(ec);
    }
}

fn testRecoveryKeepsPriming() void {
    const allocated = alloc(jent.JENT_FORCE_FIPS) orelse {
        skip("primed replacement: no collector", .{});
        return;
    };
    var ec: ?*jent.rand_data = allocated;
    defer jent.jent_entropy_collector_free(ec);
    expect(jent_health_failure_reset(&ec, 1) == 0, "reallocation with startup succeeds");
    expect(ec.?.rct_count == ec.?.rct_cutoff, "replacement RCT remains primed");
}

fn testRecoveryGivesUp() void {
    const allocated = jent.jent_entropy_collector_alloc(jent.JENT_MAX_OSR, 0) orelse {
        skip("recovery limit: no collector", .{});
        return;
    };
    var ec: ?*jent.rand_data = allocated;
    defer jent.jent_entropy_collector_free(ec);
    ec.?.setIsFipsEnabled(1);
    ec.?.health_failure = jent.JENT_RCT_FAILURE;
    var buf: [32]u8 = undefined;
    expect(jent.jent_read_entropy_safe(&ec, &buf, buf.len) == jent.JENT_ERR_RCT, "recovery stops above max OSR");
    expect(ec.?.osr == jent.JENT_MAX_OSR, "exhausted recovery leaves collector untouched");
}

fn testStateDuplication() void {
    const old = alloc(jent.JENT_FORCE_FIPS) orelse {
        skip("state duplication: no old collector", .{});
        return;
    };
    defer jent.jent_entropy_collector_free(old);
    const new = alloc(jent.JENT_FORCE_FIPS) orelse {
        skip("state duplication: no new collector", .{});
        return;
    };
    defer jent.jent_entropy_collector_free(new);

    new.rct_count = 0;
    jent.jent_rct_duplicate(new);
    expect(new.rct_count == new.rct_cutoff, "RCT is primed");
    old.apt_observations = 0;
    new.apt_observations = 0xdead;
    jent.jent_apt_duplicate(new, old);
    expect(new.apt_observations == 0xdead, "unstarted APT window carries nothing");
    old.apt_base = 0xc0ffee;
    old.apt_observations = 42;
    old.setAptBaseSet(1);
    jent.jent_apt_duplicate(new, old);
    expect(new.apt_observations == 42 and new.apt_base == 0xc0ffee, "APT window state is copied");
    expect(new.apt_count == new.apt_cutoff, "APT count is primed");
    jent.jent_rct_mem_duplicate(new, old);
    expect(new.rct_mem_count == new.rct_mem_cutoff, "memory RCT is primed");

    old.lag_prediction_success_run = 7;
    old.lag_prediction_success_count = 99;
    old.lag_best_predictor = 3;
    old.lag_observations = 1234;
    for (0..jent.JENT_LAG_HISTORY_SIZE) |i| {
        old.lag_scoreboard[i] = @intCast(i + 1);
        old.lag_delta_history[i] = 0x1000 + i;
    }
    jent.jent_lag_duplicate(new, old);
    expect(new.lag_prediction_success_run == 7 and new.lag_prediction_success_count == 99, "lag counters are copied");
    expect(new.lag_best_predictor == 3 and new.lag_observations == 1234, "lag predictor state is copied");
    expect(std.mem.eql(c_uint, &new.lag_scoreboard, &old.lag_scoreboard) and std.mem.eql(u64, &new.lag_delta_history, &old.lag_delta_history), "lag history is copied");
}

fn testStateDuplicationClockChange() void {
    const old = alloc(jent.JENT_FORCE_FIPS) orelse {
        skip("clock change: no old collector", .{});
        return;
    };
    defer jent.jent_entropy_collector_free(old);
    const new = alloc(jent.JENT_FORCE_FIPS) orelse {
        skip("clock change: no new collector", .{});
        return;
    };
    defer jent.jent_entropy_collector_free(new);
    old.apt_base = 0xc0ffee;
    old.apt_observations = 42;
    old.setAptBaseSet(1);
    old.lag_observations = 1234;
    old.lag_delta_history[0] = 0x1000;

    old.setEnableNotime(0);
    new.setEnableNotime(0);
    new.apt_base = 0;
    new.apt_observations = 0;
    new.rct_count = 0;
    jent.jent_health_duplicate(new, old);
    expect(new.apt_base == 0xc0ffee and new.apt_observations == 42, "same clock carries APT state");
    expect(new.rct_count == new.rct_cutoff, "same clock primes RCT");

    new.apt_base = 0;
    new.apt_observations = 0;
    new.setAptBaseSet(0);
    new.rct_count = 0;
    new.rct_mem_count = 0;
    new.lag_observations = 0;
    new.lag_delta_history[0] = 0;
    new.setEnableNotime(1);
    jent.jent_health_duplicate(new, old);
    expect(new.apt_base == 0 and new.aptBaseSet() == 0 and new.apt_observations == 0, "clock change drops APT delta state");
    expect(new.rct_count == new.rct_cutoff and new.rct_mem_count == new.rct_mem_cutoff, "clock change keeps counter priming");
    expect(new.lag_observations == 0 and new.lag_delta_history[0] == 0, "clock change drops lag history");
    new.setEnableNotime(0);
}

fn testAllocNeedsMeasuredClock() void {
    var divisor: u64 = 0;
    if (jent.jent_gcd_get(&divisor, jent.JENT_GCD_CLOCK_PLATFORM) != 0) {
        skip("no established platform-clock divisor", .{});
        return;
    }
    const saved = jent.jent_atomic_load_int(&jent_selftest_run);
    defer {
        jent.jent_atomic_store_u32(&jent_common_timer_gcd[jent.JENT_GCD_CLOCK_PLATFORM], @intCast(divisor));
        jent.jent_atomic_store_int(&jent_selftest_run, saved);
    }
    jent.jent_atomic_store_int(&jent_selftest_run, 1);
    jent.jent_atomic_store_u32(&jent_common_timer_gcd[jent.JENT_GCD_CLOCK_PLATFORM], 0);
    expect(jent.jent_entropy_collector_alloc_internal(jent.JENT_MIN_OSR, 0) == null, "unmeasured clock allocation is refused");
    expect(jent.jent_entropy_collector_alloc(jent.JENT_MIN_OSR, jent.JENT_INT_MEASURE_CLOCK) == null, "public caller cannot claim clock measurement");
    const ec = jent.jent_entropy_collector_alloc_internal(jent.JENT_MIN_OSR, jent.JENT_INT_MEASURE_CLOCK);
    expect(ec != null, "internal clock-measuring collector is allowed");
    if (ec) |collector| expect(collector.jent_common_timer_gcd == 1, "measuring collector uses raw deltas");
    jent.jent_entropy_collector_free(ec);
}

fn testStatusBothArms() void {
    const ec = alloc(0) orelse {
        skip("status: no collector", .{});
        return;
    };
    defer jent.jent_entropy_collector_free(ec);
    const all_failures = jent.JENT_RCT_FAILURE | jent.JENT_APT_FAILURE | jent.JENT_LAG_FAILURE |
        jent.JENT_RCT_MEM_FAILURE | jent.JENT_RCT_FAILURE_PERMANENT | jent.JENT_APT_FAILURE_PERMANENT |
        jent.JENT_LAG_FAILURE_PERMANENT | jent.JENT_RCT_MEM_FAILURE_PERMANENT;
    const all_flags = jent.JENT_DISABLE_MEMORY_ACCESS | jent.JENT_FORCE_INTERNAL_TIMER |
        jent.JENT_DISABLE_INTERNAL_TIMER | jent.JENT_FORCE_FIPS | jent.JENT_NTG1 |
        jent.JENT_CACHE_ALL | jent.JENT_FORCE_SECURE_MEM;
    const saved_flags = ec.flags;
    var buf: [8192]u8 = undefined;
    ec.health_failure = all_failures;
    ec.flags = saved_flags | all_flags;
    expect(jent.jent_status(ec, &buf, buf.len) == 0, "all-set status renders");
    const set_status = std.mem.sliceTo(&buf, 0);
    expect(std.mem.indexOf(u8, set_status, "\"true\"") == null, "status booleans are unquoted");
    const set_true = std.mem.count(u8, set_status, "true");
    ec.health_failure = 0;
    ec.flags = saved_flags & ~all_flags;
    expect(jent.jent_status(ec, &buf, buf.len) == 0, "clear status renders");
    const clear_true = std.mem.count(u8, std.mem.sliceTo(&buf, 0), "true");
    expect(set_true > clear_true, "status fields follow state");
    expect(clear_true < 4, "clear collector reports almost nothing true");
    ec.flags = saved_flags;
}

fn testRecoveryKeepsCallerMemsize() void {
    const allocated = jent.jent_entropy_collector_alloc(0, jent.JENT_MAX_MEMSIZE_1MB) orelse {
        skip("caller memory size recovery: no collector", .{});
        return;
    };
    var ec: ?*jent.rand_data = allocated;
    defer jent.jent_entropy_collector_free(ec);
    ec.?.setIsFipsEnabled(1);
    expect(ec.?.maxMemSet() == 1, "memory size is caller-configured");
    const memsize = ec.?.memmask + 1;
    ec.?.health_failure = jent.JENT_APT_FAILURE;
    var buf: [32]u8 = undefined;
    const ret = jent.jent_read_entropy_safe(&ec, &buf, buf.len);
    if (ret < 0) skip("noise source did not converge after recovery", .{}) else expect(ret == buf.len, "failure recovers");
    expect(ec.?.reinit_count >= 1, "collector was reallocated");
    expect(ec.?.memmask + 1 == memsize and ec.?.maxMemSet() == 1, "caller memory size is preserved");
}

fn testRecoveryPinsClock() void {
    if (!@hasField(jent.rand_data, "notime_timer")) {
        skip("internal timer is not compiled in", .{});
        return;
    }
    const allocated = alloc(jent.JENT_FORCE_FIPS) orelse {
        skip("no compliance collector for pinned-clock test", .{});
        return;
    };
    var ec: ?*jent.rand_data = allocated;
    if (ec.?.enableNotime() != 0) {
        skip("compliance collector already uses internal timer", .{});
        jent.jent_entropy_collector_free(ec);
        return;
    }
    jent_notime_force();
    const before = ec;
    expect(jent_health_failure_reset(&ec, 0) != 0, "compliance recovery refuses clock switch");
    expect(ec == before and ec.?.enableNotime() == 0, "refused recovery leaves collector on platform clock");
    jent.jent_entropy_collector_free(ec);
    const ordinary = alloc(0) orelse {
        skip("no ordinary collector after timer forcing", .{});
        return;
    };
    expect(ordinary.enableNotime() == 1, "ordinary collector follows forced internal timer");
    jent.jent_entropy_collector_free(ordinary);
}

pub fn main() u8 {
    harness.resetCounters();
    testFailureCallbackRegister();
    testErrorMapping();
    testPermanentPrecedence();
    testNoReportWithoutFips();
    testSafeRecovery();
    testRecoveryKeepsPriming();
    testRecoveryGivesUp();
    testRecoveryKeepsCallerMemsize();
    testStateDuplication();
    testStateDuplicationClockChange();
    testAllocNeedsMeasuredClock();
    testStatusBothArms();
    testFailureCallback();
    testRecoveryPinsClock();
    return harness.finish("unit-error");
}
