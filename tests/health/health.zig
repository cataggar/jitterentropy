const std = @import("std");
const builtin = @import("builtin");
const health = @import("jent").health;
const internal = health.internal;

const FILE = opaque {};
extern fn printf(format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn fopen(path: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*FILE;
extern fn fclose(stream: *FILE) callconv(.c) c_int;
extern fn fflush(stream: ?*FILE) callconv(.c) c_int;
extern fn fgets(buffer: [*c]u8, size: c_int, stream: *FILE) callconv(.c) [*c]u8;
extern fn strtoull(string: [*c]const u8, end: [*c][*c]u8, base: c_int) callconv(.c) c_ulonglong;
extern fn __errno_location() callconv(.c) *c_int;
extern fn __error() callconv(.c) *c_int;
extern fn _errno() callconv(.c) *c_int;

const rand_data = internal.rand_data;
const InitType = internal.jent_health_init_type;

const TestBit = struct {
    bit: c_uint,
    name: [*:0]const u8,
};

const test_bits = [_]TestBit{
    .{ .bit = internal.JENT_RCT_FAILURE, .name = "RCT" },
    .{ .bit = internal.JENT_APT_FAILURE, .name = "APT" },
    .{ .bit = internal.JENT_LAG_FAILURE, .name = "Lag" },
    .{ .bit = internal.JENT_RCT_MEM_FAILURE, .name = "RCT-mem" },
    .{ .bit = internal.JENT_RCT_FAILURE_PERMANENT, .name = "RCT-permanent" },
    .{ .bit = internal.JENT_APT_FAILURE_PERMANENT, .name = "APT-permanent" },
    .{ .bit = internal.JENT_LAG_FAILURE_PERMANENT, .name = "Lag-permanent" },
    .{ .bit = internal.JENT_RCT_MEM_FAILURE_PERMANENT, .name = "RCT-mem-permanent" },
};

var failures: c_uint = 0;
var skipped: c_uint = 0;

fn errnoPointer() *c_int {
    if (builtin.os.tag == .dragonfly) return __error();
    return std.c._errno();
}

pub export fn jent_random_data(ec: *rand_data) callconv(.c) void {
    _ = ec;
}

fn rctMemNosr(osr: c_uint) c_ushort {
    var nosr: c_uint = @intCast((internal.DATA_SIZE_BITS + internal.ENTROPY_SAFETY_FACTOR) * osr);
    nosr = ((nosr + 2) / 3) * 3;
    return @intCast(nosr);
}

fn rctMemSamples(count: c_uint) c_uint {
    return if (count != 0) 3 * count - 2 else 0;
}

fn printMask(initial_mask: c_uint) void {
    var mask = initial_mask;
    var first = true;
    if (mask == 0) {
        _ = printf("none");
        return;
    }
    for (test_bits) |entry| {
        if (mask & entry.bit == 0) continue;
        const separator: [*:0]const u8 = if (first) "" else "|";
        _ = printf("%s%s", separator, entry.name);
        first = false;
        mask &= ~entry.bit;
    }
    if (mask != 0) {
        const separator: [*:0]const u8 = if (first) "" else "|";
        _ = printf("%sunknown(0x%x)", separator, mask);
    }
}

fn printFailures(mask: c_uint) void {
    const Entry = struct {
        intermittent: c_uint,
        permanent: c_uint,
        name: [*:0]const u8,
    };
    const entries = [_]Entry{
        .{ .intermittent = internal.JENT_RCT_FAILURE, .permanent = internal.JENT_RCT_FAILURE_PERMANENT, .name = "repetition count test (RCT)" },
        .{ .intermittent = internal.JENT_APT_FAILURE, .permanent = internal.JENT_APT_FAILURE_PERMANENT, .name = "adaptive proportion test (APT)" },
        .{ .intermittent = internal.JENT_LAG_FAILURE, .permanent = internal.JENT_LAG_FAILURE_PERMANENT, .name = "lag predictor test" },
        .{ .intermittent = internal.JENT_RCT_MEM_FAILURE, .permanent = internal.JENT_RCT_MEM_FAILURE_PERMANENT, .name = "repetition count test with memory" },
    };
    if (mask == 0) {
        _ = printf("  no health test fired\n");
        return;
    }
    _ = printf("  health tests that fired:\n");
    var named: c_uint = 0;
    for (entries) |entry| {
        const intermittent = mask & entry.intermittent != 0;
        const permanent = mask & entry.permanent != 0;
        const intermittent_name: [*:0]const u8 = if (intermittent) "intermittent" else "";
        const conjunction: [*:0]const u8 = if (intermittent and permanent) " and " else "";
        const permanent_name: [*:0]const u8 = if (permanent) "permanent" else "";
        named |= entry.intermittent | entry.permanent;
        if (!intermittent and !permanent) continue;
        _ = printf(
            "    %-34s %s%s%s\n",
            entry.name,
            intermittent_name,
            conjunction,
            permanent_name,
        );
    }
    if (mask & ~named != 0)
        _ = printf("    %-34s 0x%x\n", "unknown failure bits", mask & ~named);
}

fn verify(name: [*:0]const u8, ec: *rand_data, samples: c_uint, expect: c_uint, testmask: c_uint) void {
    const mask = health.jent_health_failure(ec);
    const result: [*:0]const u8 = if (mask & expect == 0)
        "FAILED (expected error not reported)"
    else if (mask & ~testmask != 0)
        "FAILED (unrelated health test reported an error)"
    else
        "passed";
    _ = printf("  %-34s %6u samples -> ", name, samples);
    printMask(mask);
    _ = printf(" : %s\n", result);
    if (result[0] == 'F') failures += 1;
}

fn verifyClean(name: [*:0]const u8, ec: *rand_data, samples: c_uint) void {
    const mask = health.jent_health_failure(ec);
    const result: [*:0]const u8 = if (mask != 0) "FAILED (an error was reported)" else "passed";
    _ = printf("  %-34s %6u samples -> ", name, samples);
    printMask(mask);
    _ = printf(" : %s\n", result);
    if (mask != 0) failures += 1;
}

fn verifyQuiet(name: [*:0]const u8, ec: *rand_data, samples: c_uint, absent: c_uint) void {
    const mask = health.jent_health_failure(ec);
    const result: [*:0]const u8 = if (mask & absent != 0) "FAILED (reported before its cutoff)" else "passed";
    _ = printf("  %-34s %6u samples -> ", name, samples);
    printMask(mask);
    _ = printf(" : %s\n", result);
    if (mask & absent != 0) failures += 1;
}

fn verifyCutoff(name: [*:0]const u8, got: c_uint, want: c_uint) void {
    const result: [*:0]const u8 = if (got == want) "passed" else "FAILED (wrong cutoff)";
    _ = printf(
        "  %-34s %6u cutoff  -> expected %u : %s\n",
        name,
        got,
        want,
        result,
    );
    if (got != want) failures += 1;
}

fn skip(name: [*:0]const u8, reason: [*:0]const u8) void {
    _ = printf("  %-34s %6s    -> skipped: %s\n", name, "-", reason);
    skipped += 1;
}

fn init(ec: *rand_data, osr: c_uint, init_type: InitType) void {
    ec.* = .{};
    ec.osr = osr;
    ec.setIsFipsEnabled(1);
    _ = health.jent_health_init(ec, init_type);
    ec.rct_mem_nosr = rctMemNosr(osr);
    ec.setStuckPrime(0);
}

fn testRct(osr: c_uint, init_type: InitType) void {
    var ec: rand_data = .{};
    const testmask = internal.JENT_RCT_FAILURE | internal.JENT_RCT_FAILURE_PERMANENT;
    init(&ec, osr, init_type);
    var want = internal.jent_health_rct_intermittent_cutoff(osr);
    var want_permanent = internal.jent_health_rct_permanent_cutoff(osr);
    if (init_type == .jent_health_init_type_ntg1) {
        want = (want + 7) / 8;
        want_permanent = (want_permanent + 7) / 8;
    }
    verifyCutoff("RCT intermittent cutoff", ec.rct_cutoff, want);
    verifyCutoff("RCT permanent cutoff", ec.rct_cutoff_permanent, want_permanent);

    var cutoff: c_uint = ec.rct_cutoff;
    for (0..cutoff - 1) |_| health.jent_rct_insert(&ec, 1);
    verifyQuiet("RCT intermittent, one before", &ec, cutoff - 1, testmask);
    health.jent_rct_insert(&ec, 1);
    verify("RCT intermittent", &ec, cutoff, internal.JENT_RCT_FAILURE, testmask);

    init(&ec, osr, init_type);
    cutoff = ec.rct_cutoff_permanent;
    for (0..cutoff - 1) |_| health.jent_rct_insert(&ec, 1);
    verifyQuiet("RCT permanent, one before", &ec, cutoff - 1, internal.JENT_RCT_FAILURE_PERMANENT);
    health.jent_rct_insert(&ec, 1);
    verify("RCT permanent", &ec, cutoff, internal.JENT_RCT_FAILURE_PERMANENT, testmask);
}

fn testApt(osr: c_uint, init_type: InitType) void {
    var ec: rand_data = .{};
    const testmask = internal.JENT_APT_FAILURE | internal.JENT_APT_FAILURE_PERMANENT;
    init(&ec, osr, init_type);
    var cutoff = ec.apt_cutoff;
    if (cutoff >= ec.apt_cutoff_permanent) {
        skip("APT intermittent", "cutoff coincides with the permanent cutoff");
    } else {
        for (0..cutoff - 1) |_| health.jent_apt_insert(&ec, 0xc0ffee);
        verifyQuiet("APT intermittent, one before", &ec, cutoff - 1, testmask);
        health.jent_apt_insert(&ec, 0xc0ffee);
        verify("APT intermittent", &ec, cutoff, internal.JENT_APT_FAILURE, testmask);
    }

    init(&ec, osr, init_type);
    cutoff = ec.apt_cutoff_permanent;
    for (0..cutoff - 1) |_| health.jent_apt_insert(&ec, 0xc0ffee);
    verifyQuiet("APT permanent, one before", &ec, cutoff - 1, internal.JENT_APT_FAILURE_PERMANENT);
    health.jent_apt_insert(&ec, 0xc0ffee);
    verify("APT permanent", &ec, cutoff, internal.JENT_APT_FAILURE_PERMANENT, testmask);
}

fn testLag(osr: c_uint, init_type: InitType) void {
    var ec: rand_data = .{};
    const testmask = internal.JENT_LAG_FAILURE | internal.JENT_LAG_FAILURE_PERMANENT;
    init(&ec, osr, init_type);
    var samples: c_uint = @intCast(internal.JENT_LAG_HISTORY_SIZE);
    samples += ec.lag_local_cutoff;
    for (0..samples - 1) |_| health.jent_lag_insert(&ec, 0xc0ffee);
    verifyQuiet("Lag local intermittent, one before", &ec, samples - 1, testmask);
    health.jent_lag_insert(&ec, 0xc0ffee);
    verify("Lag local intermittent", &ec, samples, internal.JENT_LAG_FAILURE, testmask);

    init(&ec, osr, init_type);
    samples = @intCast(internal.JENT_LAG_HISTORY_SIZE);
    samples += ec.lag_local_cutoff_permanent;
    for (0..samples - 1) |_| health.jent_lag_insert(&ec, 0xc0ffee);
    verifyQuiet("Lag local permanent, one before", &ec, samples - 1, internal.JENT_LAG_FAILURE_PERMANENT);
    health.jent_lag_insert(&ec, 0xc0ffee);
    verify("Lag local permanent", &ec, samples, internal.JENT_LAG_FAILURE_PERMANENT, testmask);

    init(&ec, osr, init_type);
    for (0..internal.JENT_LAG_HISTORY_SIZE) |_| health.jent_lag_insert(&ec, 0xc0ffee);
    ec.lag_prediction_success_count = ec.lag_global_cutoff - 1;
    health.jent_lag_insert(&ec, 0xc0ffee);
    verify("Lag global intermittent (primed)", &ec, internal.JENT_LAG_HISTORY_SIZE + 1, internal.JENT_LAG_FAILURE, testmask);

    init(&ec, osr, init_type);
    for (0..internal.JENT_LAG_HISTORY_SIZE) |_| health.jent_lag_insert(&ec, 0xc0ffee);
    ec.lag_prediction_success_count = ec.lag_global_cutoff_permanent - 1;
    health.jent_lag_insert(&ec, 0xc0ffee);
    verify("Lag global permanent (primed)", &ec, internal.JENT_LAG_HISTORY_SIZE + 1, internal.JENT_LAG_FAILURE_PERMANENT, testmask);
}

fn testRctMem(osr: c_uint, init_type: InitType) void {
    var ec: rand_data = .{};
    const testmask = internal.JENT_RCT_MEM_FAILURE | internal.JENT_RCT_MEM_FAILURE_PERMANENT;

    init(&ec, osr, init_type);
    var samples = rctMemSamples(ec.rct_mem_cutoff);
    if (samples > ec.rct_mem_nosr) {
        skip("RCT-mem intermittent", "cutoff is not reachable within the window");
    } else {
        ec.setInRecovery(1);
        for (0..samples) |_| health.jent_rct_mem_insert(&ec, 1);
        verify("RCT-mem intermittent", &ec, samples, internal.JENT_RCT_MEM_FAILURE, testmask);
    }

    init(&ec, osr, init_type);
    samples = rctMemSamples(ec.rct_mem_cutoff);
    if (samples > ec.rct_mem_nosr) {
        skip("RCT-mem recovery loop", "cutoff is not reachable within the window");
    } else {
        for (0..samples) |_| health.jent_rct_mem_insert(&ec, 1);
        verifyClean("RCT-mem recovery loop", &ec, samples);
    }

    init(&ec, osr, init_type);
    samples = rctMemSamples(ec.rct_mem_cutoff);
    if (samples > ec.rct_mem_nosr) {
        skip("RCT-mem outside its window", "cutoff is not reachable within the window");
    } else {
        ec.setInRecovery(1);
        for (0..samples) |_| {
            ec.rct_mem_ctr = ec.rct_mem_nosr;
            health.jent_rct_mem_insert(&ec, 1);
        }
        verifyClean("RCT-mem outside its window", &ec, samples);
    }

    init(&ec, osr, init_type);
    samples = rctMemSamples(ec.rct_mem_cutoff_permanent);
    if (samples > ec.rct_mem_nosr) {
        skip("RCT-mem permanent", "cutoff is not reachable within the window");
    } else {
        ec.setInRecovery(1);
        for (0..samples) |_| health.jent_rct_mem_insert(&ec, 1);
        verify("RCT-mem permanent", &ec, samples, internal.JENT_RCT_MEM_FAILURE_PERMANENT, testmask);
    }
}

fn testOsrBounds(init_type: InitType) void {
    var ec: rand_data = .{};
    ec.setIsFipsEnabled(1);
    ec.osr = internal.JENT_MAX_OSR + 1;
    var ok = health.jent_health_init(&ec, init_type) != 0;
    ec = .{};
    ec.setIsFipsEnabled(1);
    ok = ok and health.jent_health_init(&ec, init_type) != 0;
    const result: [*:0]const u8 = if (ok) "passed" else "FAILED";
    _ = printf("  %-34s %6s    -> %s\n", "osr outside the tables refused", "-", result);
    if (!ok) failures += 1;
}

fn runTests(osr: c_uint, init_type: InitType) void {
    var ec: rand_data = .{};
    const config_name: [*:0]const u8 = if (init_type == .jent_health_init_type_ntg1) "NTG.1" else "common";
    init(&ec, osr, init_type);
    _ = printf(
        "Induced failure tests with osr %u, %s configuration\n",
        osr,
        config_name,
    );
    _ = printf(
        "  cutoffs: RCT %u/%u, APT %u/%u, RCT-mem %u/%u, Lag local %u/%u, Lag global %u/%u (intermittent/permanent)\n",
        ec.rct_cutoff,
        ec.rct_cutoff_permanent,
        ec.apt_cutoff,
        ec.apt_cutoff_permanent,
        ec.rct_mem_cutoff,
        ec.rct_mem_cutoff_permanent,
        ec.lag_local_cutoff,
        ec.lag_local_cutoff_permanent,
        ec.lag_global_cutoff,
        ec.lag_global_cutoff_permanent,
    );
    testRct(osr, init_type);
    testApt(osr, init_type);
    testLag(osr, init_type);
    testRctMem(osr, init_type);
    testOsrBounds(init_type);
    _ = printf("\n");
}

fn replay(file: [:0]const u8, osr: c_uint, init_type: InitType) u8 {
    var ec: rand_data = .{};
    const config_name: [*:0]const u8 = if (init_type == .jent_health_init_type_ntg1) "NTG.1" else "common";
    const stream = if (std.mem.eql(u8, file, "-"))
        fopen(if (builtin.os.tag == .windows) "CONIN$" else "/dev/stdin", "r")
    else
        fopen(file.ptr, "r");
    if (stream == null) {
        _ = printf("Cannot open %s\n", file.ptr);
        return 2;
    }
    const input = stream.?;
    defer _ = fclose(input);

    init(&ec, osr, init_type);
    _ = printf(
        "Replaying %s with osr %u, %s configuration\n",
        file.ptr,
        osr,
        config_name,
    );
    _ = fflush(null);

    var line: [128]u8 = undefined;
    var line_number: c_ulong = 0;
    var stamps: c_ulonglong = 0;
    var stuck: c_ulonglong = 0;
    var primed = false;
    while (fgets(&line, @intCast(line.len), input) != null) {
        line_number += 1;
        var p: [*c]u8 = &line;
        while (p[0] == ' ' or p[0] == '\t') p += 1;
        if (p[0] == '#' or p[0] == '\n' or p[0] == '\r' or p[0] == 0) continue;
        var end: [*c]u8 = null;
        const errno_ptr = errnoPointer();
        errno_ptr.* = 0;
        const value = if (p[0] == '0' and (p[1] == 'x' or p[1] == 'X'))
            strtoull(p + 2, &end, 16)
        else
            strtoull(p, &end, 10);
        if (errno_ptr.* != 0 or end == p) {
            _ = printf("%s:%lu: not a time stamp: %s", file.ptr, line_number, p);
            return 2;
        }
        const stamp: u64 = @intCast(value);
        if (!primed) {
            _ = health.jent_health_insert_timestamp(&ec, stamp);
            primed = true;
        }
        stuck += health.jent_health_insert_timestamp(&ec, stamp);
        stamps += 1;
    }
    if (stamps == 0) {
        _ = printf("%s holds no time stamps\n", file.ptr);
        return 2;
    }
    const mask = health.jent_health_failure(&ec);
    _ = printf("  %llu time stamps, %llu stuck measurement(s)\n", stamps, stuck);
    printFailures(mask);
    _ = printf("  note: no common timer divisor is applied to the deltas\n");
    return if (mask != 0) 1 else 0;
}

fn usage(name: [*:0]const u8) void {
    _ = printf("Usage: %s [osr]\n", name);
    _ = printf("       %s --replay FILE [osr] [--ntg1]\n", name);
}

pub fn main(init_context: std.process.Init.Minimal) u8 {
    var args = std.process.Args.Iterator.initAllocator(init_context.args, std.heap.c_allocator) catch return 1;
    defer args.deinit();
    const name = args.next() orelse "jitterentropy-health";
    var osr: c_uint = internal.JENT_MIN_OSR;
    var replay_file: ?[:0]const u8 = null;
    var init_type: InitType = .jent_health_init_type_common;
    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            usage(name.ptr);
            return 0;
        }
        if (std.mem.eql(u8, arg, "--replay")) {
            replay_file = args.next() orelse {
                _ = printf("--replay needs a file\n");
                return 1;
            };
            continue;
        }
        if (std.mem.eql(u8, arg, "--ntg1")) {
            init_type = .jent_health_init_type_ntg1;
            continue;
        }
        osr = std.fmt.parseInt(c_uint, arg, 10) catch {
            _ = printf("Oversampling rate must be in the range of %u - %u\n", internal.JENT_MIN_OSR, internal.JENT_MAX_OSR);
            return 1;
        };
        if (osr < internal.JENT_MIN_OSR or osr > internal.JENT_MAX_OSR) {
            _ = printf("Oversampling rate must be in the range of %u - %u\n", internal.JENT_MIN_OSR, internal.JENT_MAX_OSR);
            return 1;
        }
    }
    if (replay_file) |file| return replay(file, osr, init_type);
    runTests(osr, .jent_health_init_type_common);
    runTests(osr, .jent_health_init_type_ntg1);
    _ = printf("%u induced failure test(s) failed, %u skipped\n", failures, skipped);
    return if (failures != 0) 1 else 0;
}
