const std = @import("std");
const h = @import("test_harness.zig");
const c = @import("internal");

const NzClock = extern struct {
    t: u64 = 0,
    last_step: u64 = 0,
    lcg: c_uint = 0,
    served: c_ulong = 0,
    stuck_every: c_uint = 0,
    trip_ec: ?*c.rand_data = null,
    trip_at: c_ulong = 0,
    trip_bit: c_uint = 0,
};

var nz: NzClock = .{};
const NZ_FLAGS = c.JENT_DISABLE_INTERNAL_TIMER;

fn expectEqual(got: anytype, want: @TypeOf(got), what: []const u8) void {
    h.expectOrExit(got == want, @src(), "{s}: got {d}, expected {d}", .{ what, got, want });
}

fn nzClockCb(arg: ?*anyopaque, out: *u64) callconv(.c) void {
    const clock: *NzClock = @ptrCast(@alignCast(arg.?));
    clock.served += 1;

    if (clock.trip_ec != null and clock.served == clock.trip_at) {
        clock.trip_ec.?.health_failure |= clock.trip_bit;
    }

    if (clock.stuck_every == 0 or clock.served % clock.stuck_every != 0) {
        clock.lcg = clock.lcg *% 1103515245 +% 12345;
        clock.last_step = 500 + (clock.lcg >> 22);
    }
    clock.t +%= clock.last_step;
    out.* = clock.t;
}

fn nzClockPlain() void {
    nz.stuck_every = 0;
    nz.trip_ec = null;
}

fn nzAlloc(osr: c_uint, flags: c_uint, what: []const u8) *c.rand_data {
    nzClockPlain();
    const ec = c.jent_entropy_collector_alloc(osr, flags | NZ_FLAGS);
    h.expectOrExit(ec != null, @src(), "{s}: no collector was allocated", .{what});
    return ec.?;
}

fn testLoopCounts() void {
    const Case = struct {
        osr: c_uint,
        flags: c_uint,
        want: c_uint,
        what: []const u8,
    };
    const cases = [_]Case{
        .{
            .osr = 4,
            .flags = 0,
            .want = 1026,
            .what = "256 bits per OSR, rounded up to a multiple of three",
        },
        .{
            .osr = 3,
            .flags = c.JENT_FORCE_FIPS,
            .want = 963,
            .what = "and the safety factor on top in FIPS mode",
        },
    };

    std.debug.print("the measurements of one block\n", .{});
    for (cases) |case| {
        const ec = nzAlloc(case.osr, case.flags, case.what);
        c.jent_random_data(ec);
        expectEqual(@as(c_uint, ec.rct_mem_nosr), case.want, case.what);
        c.jent_entropy_collector_free(ec);
    }
}

fn testStuckMeasurementsRetried() void {
    const ec = nzAlloc(0, c.JENT_DISABLE_MEMORY_ACCESS, "stuck measurements are retried");
    std.debug.print("stuck measurements are taken again\n", .{});

    nz.stuck_every = 4;
    const before = nz.served;
    c.jent_random_data(ec);
    const readings = nz.served - before;
    nzClockPlain();

    std.debug.print("  note: {d} readings for a loop count of {d}\n", .{ readings, ec.rct_mem_nosr });
    const minimum = 1 + @as(c_ulong, ec.rct_mem_nosr) + @as(c_ulong, ec.rct_mem_nosr) / 5;
    h.expectOrExit(
        readings > minimum,
        @src(),
        "a block on a clock with stuck readings takes more of them",
        .{},
    );
    c.jent_entropy_collector_free(ec);
}

fn testNtg1StartupStages() void {
    const ec = nzAlloc(0, c.JENT_NTG1, "the NTG.1 startup stages");
    std.debug.print("the NTG.1 startup stages\n", .{});

    const fresh = c.jent_entropy_collector_alloc_internal(0, c.JENT_NTG1 | NZ_FLAGS);
    h.expectOrExit(fresh != null, @src(), "no NTG.1 collector without its startup", .{});
    h.expectOrExit(
        fresh.?.startup_state == .jent_startup_memory,
        @src(),
        "an NTG.1 collector starts with the memory stage",
        .{},
    );
    c.jent_entropy_collector_free(fresh);

    ec.startup_state = .jent_startup_memory;
    const before = nz.served;
    c.jent_random_data(ec);
    const readings = nz.served - before;

    h.expectOrExit(
        ec.startup_state == .jent_startup_completed,
        @src(),
        "the stages end in the completed state",
        .{},
    );
    expectEqual(ec.health_failure, @as(c_uint, 0), "without a health test failure");
    std.debug.print("  note: {d} readings for a loop count of {d}\n", .{ readings, ec.rct_mem_nosr });
    h.expectOrExit(
        readings >= 4 * @as(c_ulong, ec.rct_mem_nosr),
        @src(),
        "both stages took a full loop count of measurements",
        .{},
    );
    c.jent_entropy_collector_free(ec);
}

fn testNtg1StagesFeedThePool() void {
    const Stage = struct {
        measure: c.jent_measure_jitter_cb,
        what: []const u8,
    };
    const stages = [_]Stage{
        .{
            .measure = c.jent_measure_jitter_ntg1_memaccess,
            .what = "the memory access stage feeds the pool",
        },
        .{
            .measure = c.jent_measure_jitter_ntg1_sha3,
            .what = "the hash loop stage feeds the pool",
        },
    };
    const ec = nzAlloc(0, c.JENT_NTG1, "the NTG.1 stages' pool");
    std.debug.print("the NTG.1 stages feed the pool\n", .{});

    for (stages) |stage| {
        var before = ec.hash_state;
        c.jent_random_data_one(ec, stage.measure);
        h.expectOrExit(
            !std.mem.eql(u8, std.mem.asBytes(&before), std.mem.asBytes(&ec.hash_state)),
            @src(),
            "{s}",
            .{stage.what},
        );
        c.jent_memset_secure(&before, @sizeOf(@TypeOf(before)));
    }
    c.jent_entropy_collector_free(ec);
}

fn testFailedReadOutputsNothing() void {
    const ec = nzAlloc(3, c.JENT_FORCE_FIPS, "a failed read outputs nothing");
    var buf: [64]u8 = undefined;
    std.debug.print("a read that fails part-way outputs nothing\n", .{});

    const before = nz.served;
    h.expectOrExit(c.jent_read_entropy(ec, &buf, 32) == 32, @src(), "no block to measure", .{});
    nz.trip_at = nz.served + (nz.served - before) * 3 / 2;
    nz.trip_ec = ec;
    nz.trip_bit = c.JENT_APT_FAILURE_PERMANENT;

    @memset(&buf, 0xa5);
    const ret = c.jent_read_entropy(ec, &buf, buf.len);
    nzClockPlain();

    expectEqual(ret, @as(isize, c.JENT_ERR_APT_PERMANENT), "the failure in the second block is returned");
    var nonzero: usize = 0;
    for (buf[0..32]) |byte| {
        if (byte != 0) nonzero += 1;
    }
    expectEqual(nonzero, @as(usize, 0), "the first block was wiped from the buffer");
    for (buf[32..]) |byte| {
        if (byte != 0xa5) nonzero += 1;
    }
    expectEqual(nonzero, @as(usize, 0), "and nothing was written past it");
    c.jent_entropy_collector_free(ec);
}

pub fn main() void {
    h.resetCounters();
    nz.t = 1;
    nz.lcg = 7;

    if (c.jent_set_mock_timer(&nzClockCb, &nz) != 0) {
        h.skipOrExit(@src(), "the noise source: the clock cannot be mocked", .{});
        h.pass("unit-noise");
    }

    testLoopCounts();
    testStuckMeasurementsRetried();
    testNtg1StartupStages();
    testNtg1StagesFeedThePool();
    testFailedReadOutputsNothing();

    _ = c.jent_set_mock_timer(null, null);
    h.pass("unit-noise");
}
