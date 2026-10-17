const std = @import("std");
const jent = @import("jent");

const elements: usize = 1000;
var checks: usize = 0;
var failures: usize = 0;

fn expect(condition: bool, comptime message: []const u8) void {
    checks += 1;
    if (!condition) {
        failures += 1;
        std.debug.print("  FAILED: {s}\n", .{message});
    }
}

fn testGcd64() void {
    expect(jent.jent_gcd64(12, 18) == 6, "gcd(12, 18)");
    expect(jent.jent_gcd64(18, 12) == 6, "GCD is symmetric");
    expect(jent.jent_gcd64(17, 13) == 1, "coprime GCD");
    expect(jent.jent_gcd64(50, 50) == 50, "equal-value GCD");
    expect(jent.jent_gcd64(0, 7) == 7, "gcd(0, x)");
    expect(jent.jent_gcd64(7, 0) == 7, "gcd(x, 0)");
    expect(jent.jent_gcd64(0, 0) == 0, "gcd(0, 0)");
    expect(jent.jent_gcd64(@as(u64, 1) << 40, @as(u64, 1) << 36) == @as(u64, 1) << 36, "large power-of-two GCD");
}

fn allocate() ?[*]u64 {
    return jent.jent_gcd_init(elements, 0);
}

fn testEstablishAndClocks() void {
    var value: u64 = 0;
    expect(jent.jent_gcd_get(&value, jent.JENT_GCD_CLOCK_PLATFORM) == 1 and value == 0, "platform GCD initially unset");
    expect(jent.jent_gcd_get(&value, jent.JENT_GCD_CLOCK_NOTIME) == 1 and value == 0, "notime GCD initially unset");

    const deltas = allocate() orelse {
        expect(false, "allocate GCD history");
        return;
    };
    defer jent.jent_gcd_fini(deltas, elements);
    for (0..elements) |i| deltas[i] = i * 50;
    expect(jent.jent_gcd_analyze(deltas, elements, jent.JENT_MIN_OSR, jent.JENT_GCD_CLOCK_PLATFORM) == 0, "establish platform GCD");
    expect(jent.jent_gcd_get(&value, jent.JENT_GCD_CLOCK_PLATFORM) == 0 and value == 50, "read platform GCD");

    for (0..elements) |i| deltas[i] = if ((i & 1) != 0) 101 else 100;
    expect(jent.jent_gcd_analyze(deltas, elements, jent.JENT_MIN_OSR, jent.JENT_GCD_CLOCK_PLATFORM) == 0, "second platform history passes");
    expect(jent.jent_gcd_get(&value, jent.JENT_GCD_CLOCK_PLATFORM) == 0 and value == 50, "platform GCD remains sticky");

    for (0..elements) |i| deltas[i] = i * 7;
    expect(jent.jent_gcd_analyze(deltas, elements, jent.JENT_MIN_OSR, jent.JENT_GCD_CLOCK_NOTIME) == 0, "establish notime GCD");
    expect(jent.jent_gcd_get(&value, jent.JENT_GCD_CLOCK_NOTIME) == 0 and value == 7, "read notime GCD");
    expect(jent.jent_gcd_get(&value, jent.JENT_GCD_CLOCK_PLATFORM) == 0 and value == 50, "clock GCDs are independent");
}

fn testAnalyze() void {
    const deltas = allocate() orelse {
        expect(false, "allocate analysis history");
        return;
    };
    defer jent.jent_gcd_fini(deltas, elements);

    for (0..elements) |i| deltas[i] = if ((i & 1) != 0) 101 else 100;
    expect(jent.jent_gcd_analyze(deltas, elements, jent.JENT_MIN_OSR, jent.JENT_GCD_CLOCK_PLATFORM) == 0, "varying history passes");

    @memset(deltas[0..elements], 12345);
    expect(jent.jent_gcd_analyze(deltas, elements, jent.JENT_MIN_OSR, jent.JENT_GCD_CLOCK_PLATFORM) == jent.EMINVARVAR, "constant history rejected");

    for (0..elements) |i| deltas[i] = (i + 1) * (std.math.maxInt(u32) / 2);
    expect(jent.jent_gcd_analyze(deltas, elements, jent.JENT_MIN_OSR, jent.JENT_GCD_CLOCK_PLATFORM) == jent.ECOARSETIME, "coarse timer rejected");
    expect(jent.jent_gcd_analyze(null, elements, jent.JENT_MIN_OSR, jent.JENT_GCD_CLOCK_PLATFORM) == jent.ENOMONOTONIC, "null history rejected");
    expect(jent.jent_gcd_analyze(deltas, 0, jent.JENT_MIN_OSR, jent.JENT_GCD_CLOCK_PLATFORM) == jent.ENOMONOTONIC, "empty history rejected");

    for (0..elements) |i| deltas[i] = if (i == elements - 1) 1001 else 1000;
    expect(jent.jent_gcd_analyze(deltas, elements, 1, jent.JENT_GCD_CLOCK_PLATFORM) == jent.EMINVARVAR, "barely varying history fails at OSR 1");
    expect(jent.jent_gcd_analyze(deltas, elements, elements, jent.JENT_GCD_CLOCK_PLATFORM) == 0, "barely varying history passes at high OSR");
}

fn testSelftest() void {
    expect(jent.jent_gcd_selftest(0) == 0, "GCD self-test");
    var running_gcd: u64 = 0;
    var delta_sum: u64 = 0;
    expect(jent.jent_gcd_analyze_internal(null, 10, &running_gcd, &delta_sum) != 0, "internal analysis rejects null");
    expect(jent.jent_gcd_analyze_internal(@ptrCast(&delta_sum), 0, &running_gcd, &delta_sum) != 0, "internal analysis rejects empty");

    var history: [10]u64 = undefined;
    for (&history, 0..) |*value, i| value.* = i * 7;
    expect(jent.jent_gcd_analyze_internal(&history, history.len, &running_gcd, &delta_sum) == 0, "internal analysis accepts history");
    expect(running_gcd == 7 and running_gcd != 3, "internal analysis reports expected GCD");
    jent.jent_gcd_fini(null, elements);
}

pub fn main() u8 {
    testGcd64();
    testEstablishAndClocks();
    testAnalyze();
    testSelftest();
    std.debug.print("unit-gcd: {d} checks, {d} failed\n", .{ checks, failures });
    return if (failures == 0) 0 else 1;
}
