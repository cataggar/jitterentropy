const internal = @import("internal.zig");

// build.zig keeps this module in Debug mode so the self-test loop is not
// optimized; Zig 0.16/0.17 have no per-function @setOptimizeMode builtin.

const selftest_elements: usize = 10;
const selftest_expected: u64 = 3;

pub export var jent_common_timer_gcd: [internal.JENT_GCD_CLOCKS]u32 = @splat(0);

fn clockIndex(notime: c_uint) usize {
    return if (notime != 0) internal.JENT_GCD_CLOCK_NOTIME else internal.JENT_GCD_CLOCK_PLATFORM;
}

pub export fn jent_gcd64(a_arg: u64, b_arg: u64) callconv(.c) u64 {
    var a = a_arg;
    var b = b_arg;
    if (a < b) {
        const swap = a;
        a = b;
        b = swap;
    }
    while (b != 0) {
        const remainder = a % b;
        a = b;
        b = remainder;
    }
    return a;
}

pub export fn jent_gcd_analyze_internal(
    delta_history: ?[*]u64,
    nelem: usize,
    running_gcd_out: *u64,
    delta_sum_out: *u64,
) callconv(.c) c_int {
    const eagain: c_int = 11;
    const history = delta_history orelse return -eagain;
    if (nelem == 0) return -eagain;

    var running_gcd = history[0];
    var delta_sum: u64 = 0;
    var i: usize = 1;
    while (i < nelem) : (i += 1) {
        delta_sum +%= if (history[i] >= history[i - 1])
            history[i] - history[i - 1]
        else
            history[i - 1] - history[i];
        running_gcd = jent_gcd64(history[i], running_gcd);
    }
    running_gcd_out.* = running_gcd;
    delta_sum_out.* = delta_sum;
    return 0;
}

pub export fn jent_gcd_verdict(
    delta_history: ?[*]u64,
    nelem: usize,
    osr: usize,
    gcd: *u64,
) callconv(.c) c_int {
    var running_gcd: u64 = undefined;
    var delta_sum: u64 = undefined;
    var result = jent_gcd_analyze_internal(delta_history, nelem, &running_gcd, &delta_sum);
    if (result != 0) return internal.ENOMONOTONIC;
    if (running_gcd != 0) delta_sum /= running_gcd;
    if (delta_sum *% osr < nelem) {
        result = internal.EMINVARVAR;
    } else if (running_gcd >= @as(u64, 0xffffffff) / 2) {
        result = internal.ECOARSETIME;
    } else {
        gcd.* = running_gcd;
    }
    return result;
}

pub export fn jent_gcd_store(gcd: u64, notime: c_uint) callconv(.c) void {
    if (gcd != 0) {
        const index = clockIndex(notime);
        _ = internal.jent_atomic_cmpxchg_u32(&jent_common_timer_gcd[index], 0, @truncate(gcd));
    }
}

pub export fn jent_gcd_analyze(
    delta_history: ?[*]u64,
    nelem: usize,
    osr: usize,
    notime: c_uint,
) callconv(.c) c_int {
    var gcd: u64 = undefined;
    const result = jent_gcd_verdict(delta_history, nelem, osr, &gcd);
    if (result == 0) jent_gcd_store(gcd, notime);
    return result;
}

pub export fn jent_gcd_init(nelem: usize, flags: c_uint) callconv(.c) ?[*]u64 {
    const memory = internal.jent_zalloc(nelem *% @sizeOf(u64), flags) orelse return null;
    return @ptrCast(@alignCast(memory));
}

pub export fn jent_gcd_fini(delta_history: ?[*]u64, nelem: usize) callconv(.c) void {
    if (delta_history) |history| internal.jent_zfree(history, nelem *% @sizeOf(u64));
}

pub export fn jent_gcd_get(value: *u64, notime: c_uint) callconv(.c) c_int {
    const index = clockIndex(notime);
    const gcd = internal.jent_atomic_load_u32(&jent_common_timer_gcd[index]);
    if (gcd == 0) return 1;
    value.* = gcd;
    return 0;
}

pub export fn jent_gcd_selftest(flags: c_uint) callconv(.c) c_int {
    const history = jent_gcd_init(selftest_elements, flags) orelse return internal.EMEM;
    defer jent_gcd_fini(history, selftest_elements);

    var i: usize = 0;
    while (i < selftest_elements) : (i += 1) {
        history[i] = i * selftest_expected;
    }
    var running_gcd: u64 = undefined;
    var delta_sum: u64 = undefined;
    if (jent_gcd_analyze_internal(history, selftest_elements, &running_gcd, &delta_sum) != 0)
        return internal.EGCD;
    return if (running_gcd == selftest_expected) 0 else internal.EGCD;
}
