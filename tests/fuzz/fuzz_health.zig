const std = @import("std");
const health = @import("health");
const internal = health.internal;

const max_stamps = 4096;
const guard_size = 32;
const fill = 0xa5;
const failure_mask = internal.JENT_RCT_FAILURE |
    internal.JENT_APT_FAILURE |
    internal.JENT_LAG_FAILURE |
    internal.JENT_RCT_MEM_FAILURE |
    internal.JENT_RCT_FAILURE_PERMANENT |
    internal.JENT_APT_FAILURE_PERMANENT |
    internal.JENT_LAG_FAILURE_PERMANENT |
    internal.JENT_RCT_MEM_FAILURE_PERMANENT;

const State = struct {
    data: []const u8,
    position: usize = 0,

    fn eof(self: *const State) bool {
        return self.position >= self.data.len;
    }

    fn nextU8(self: *State) u8 {
        if (self.eof()) return 0;
        const value = self.data[self.position];
        self.position += 1;
        return value;
    }

    fn nextU64(self: *State) u64 {
        var value: u64 = 0;
        for (0..8) |_|
            value = (value << 8) | self.nextU8();
        return value;
    }
};

const Collector = extern struct {
    front: [guard_size]u8,
    ec: internal.rand_data,
    back: [guard_size]u8,
};

const Config = struct {
    osr: c_uint,
    init_type: internal.jent_health_init_type,
    fips: bool,
    gcd: u64,
};

pub export fn jent_random_data(ec: *internal.rand_data) callconv(.c) void {
    _ = ec;
}

fn rctMemNosr(osr: c_uint) c_ushort {
    var nosr: c_uint = @intCast((internal.DATA_SIZE_BITS + internal.ENTROPY_SAFETY_FACTOR) * osr);
    nosr = ((nosr + 2) / 3) * 3;
    return @intCast(nosr);
}

fn drawConfig(state: *State) Config {
    var pick = state.nextU8();
    const osr = internal.JENT_MIN_OSR + pick % (internal.JENT_MAX_OSR - internal.JENT_MIN_OSR + 1);
    pick = state.nextU8();
    const init_type: internal.jent_health_init_type = if (pick & 1 != 0)
        .jent_health_init_type_ntg1
    else
        .jent_health_init_type_common;
    const fips = pick & 0x7e != 0;
    const gcd = switch (state.nextU8() % 6) {
        0 => 0,
        1 => 1,
        2 => 2,
        3 => 100,
        4 => std.math.maxInt(u64),
        else => state.nextU64(),
    };
    return .{ .osr = osr, .init_type = init_type, .fips = fips, .gcd = gcd };
}

fn initialize(collector: *Collector, config: *const Config) void {
    @memset(std.mem.asBytes(collector), fill);
    @memset(std.mem.asBytes(&collector.ec), 0);
    collector.ec.osr = config.osr;
    collector.ec.jent_common_timer_gcd = config.gcd;
    if (config.fips) collector.ec.setIsFipsEnabled(1);
    _ = health.jent_health_init(&collector.ec, config.init_type);
    collector.ec.rct_mem_nosr = rctMemNosr(config.osr);
}

fn nextStamp(state: *State, previous: u64, step: *u64) u64 {
    const pick = state.nextU8();
    return switch (pick % 8) {
        0 => previous,
        1 => previous +% step.*,
        2 => blk: {
            step.* = @as(u64, state.nextU8()) + 1;
            break :blk previous +% step.*;
        },
        3 => previous +% (pick % 4),
        4 => previous -% state.nextU8(),
        5 => std.math.maxInt(u64) - @as(u64, pick),
        6 => 0,
        else => state.nextU64(),
    };
}

fn delta(previous: u64, stamp: u64, gcd: u64) u64 {
    return internal.jent_udiv64(internal.jent_delta(previous, stamp), if (gcd != 0) gcd else 1);
}

fn checkGuards(collector: *const Collector) void {
    for (collector.front) |byte| std.debug.assert(byte == fill);
    for (collector.back) |byte| std.debug.assert(byte == fill);
}

fn checkInvariants(collector: *const Collector, config: *const Config, failure: c_uint) void {
    const ec = &collector.ec;
    checkGuards(collector);
    std.debug.assert(failure & ~@as(c_uint, failure_mask) == 0);
    if (!config.fips) std.debug.assert(failure == 0);
    std.debug.assert(ec.apt_observations <= internal.JENT_APT_WINDOW_SIZE);
    std.debug.assert(ec.apt_count <= internal.JENT_APT_WINDOW_SIZE);
    std.debug.assert(ec.rct_mem_ctr <= ec.rct_mem_nosr);
    std.debug.assert(ec.rct_mem_count <= ec.rct_mem_nosr);
    std.debug.assert(ec.lag_observations <= internal.JENT_LAG_WINDOW_SIZE);
    std.debug.assert(ec.lag_best_predictor < internal.JENT_LAG_HISTORY_SIZE);
    std.debug.assert(ec.lag_prediction_success_run <= ec.lag_prediction_success_count);
}

pub export fn LLVMFuzzerTestOneInput(data: [*]const u8, size: usize) callconv(.c) c_int {
    var state = State{ .data = data[0..size] };
    const config = drawConfig(&state);
    var stamps: Collector = undefined;
    var deltas: Collector = undefined;
    initialize(&stamps, &config);
    initialize(&deltas, &config);

    var previous: u64 = 0;
    var step: u64 = 1;
    var seen: c_uint = 0;
    var count: usize = 0;
    while (count < max_stamps and !state.eof()) : (count += 1) {
        const stamp = nextStamp(&state, previous, &step);
        const stuck_delta = health.jent_stuck(&deltas.ec, delta(previous, stamp, config.gcd));
        const stuck_stamp = health.jent_health_insert_timestamp(&stamps.ec, stamp);
        previous = stamp;

        std.debug.assert(stuck_stamp <= 1);
        std.debug.assert(stuck_stamp == stuck_delta);
        const failure = health.jent_health_failure(&stamps.ec);
        std.debug.assert(failure == health.jent_health_failure(&deltas.ec));
        std.debug.assert(failure & seen == seen);
        seen = failure;
        checkInvariants(&stamps, &config, failure);
        checkInvariants(&deltas, &config, health.jent_health_failure(&deltas.ec));
    }

    deltas.ec.prev_time = stamps.ec.prev_time;
    std.debug.assert(std.mem.eql(u8, std.mem.asBytes(&stamps.ec), std.mem.asBytes(&deltas.ec)));
    return 0;
}
