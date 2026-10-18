const std = @import("std");
const builtin = @import("builtin");
const options = @import("options.zig");

const Collector = opaque {};

const c = struct {
    extern fn fprintf(stream: *anyopaque, format: [*:0]const u8, ...) callconv(.c) c_int;
    extern fn strtod(text: [*:0]const u8, end: *[*:0]u8) callconv(.c) f64;
};

const windows = struct {
    const LargeInteger = extern union {
        quad_part: i64,
    };
    extern "kernel32" fn QueryPerformanceFrequency(value: *LargeInteger) callconv(.winapi) c_int;
    extern "kernel32" fn QueryPerformanceCounter(value: *LargeInteger) callconv(.winapi) c_int;
};

extern fn jent_entropy_init_ex(osr: c_uint, flags: c_uint) callconv(.c) c_int;
extern fn jent_entropy_collector_alloc(osr: c_uint, flags: c_uint) callconv(.c) ?*Collector;
extern fn jent_entropy_collector_free(ec: ?*Collector) callconv(.c) void;
extern fn jent_read_entropy_safe(
    ec: *?*Collector,
    data: [*]u8,
    len: usize,
) callconv(.c) isize;

const JENT_MIN_OSR: c_uint = 3;
const JENT_MAX_OSR: c_uint = 20;

fn monotonicNs() ?u64 {
    if (builtin.os.tag == .windows) {
        var frequency: windows.LargeInteger = undefined;
        var ticks: windows.LargeInteger = undefined;
        if (windows.QueryPerformanceFrequency(&frequency) == 0 or
            frequency.quad_part <= 0 or
            windows.QueryPerformanceCounter(&ticks) == 0 or
            ticks.quad_part < 0)
        {
            return null;
        }
        const freq: u64 = @intCast(frequency.quad_part);
        const value: u64 = @intCast(ticks.quad_part);
        return value / freq * 1_000_000_000 +
            value % freq * 1_000_000_000 / freq;
    }
    var time: std.c.timespec = undefined;
    if (std.c.clock_gettime(.MONOTONIC, &time) != 0) return null;
    return @as(u64, @intCast(time.sec)) * 1_000_000_000 +
        @as(u64, @intCast(time.nsec));
}

fn linearInverse(y: f64, x1: f64, y1: f64, x2: f64, y2: f64) f64 {
    if (@abs(y1 - y2) < std.math.floatEps(f64)) return x2;
    return (y - y1) * ((x2 - x1) / (y2 - y1)) + x1;
}

fn clampOsr(value: f64, high: c_uint) c_uint {
    if (!(value >= @as(f64, @floatFromInt(JENT_MIN_OSR)))) return JENT_MIN_OSR;
    if (value >= @as(f64, @floatFromInt(high))) return high;
    return @intFromFloat(value);
}

fn outputTime(rounds: c_ulong, osr: c_uint, flags: c_uint) ?u64 {
    const ret = jent_entropy_init_ex(osr, flags);
    if (ret != 0) {
        if (osr > JENT_MAX_OSR) {
            _ = c.fprintf(
                options.stderr(),
                "The initialization failed with error code %d due to selected OSR %u too high (max %u)\n",
                ret,
                osr,
                JENT_MAX_OSR,
            );
        } else {
            _ = c.fprintf(
                options.stderr(),
                "The initialization failed with error code %d\n",
                ret,
            );
        }
        return null;
    }
    var ec = jent_entropy_collector_alloc(osr, flags);
    if (ec == null) {
        _ = c.fprintf(options.stderr(), "Jitter RNG handle cannot be allocated\n");
        return null;
    }
    defer jent_entropy_collector_free(ec);

    const start = monotonicNs() orelse {
        _ = c.fprintf(options.stderr(), "Unable to get start time\n");
        return null;
    };
    var i: c_ulong = 0;
    while (i < rounds) : (i += 1) {
        var data: [32]u8 = undefined;
        if (jent_read_entropy_safe(&ec, &data, data.len) < 0) {
            _ = c.fprintf(options.stderr(), "FIPS 140-2 continuous test failed\n");
            return null;
        }
    }
    const finish = monotonicNs() orelse {
        _ = c.fprintf(options.stderr(), "Unable to get finish time\n");
        return null;
    };
    return (finish - start) / rounds;
}

fn parseTarget(text: [:0]const u8) ?u64 {
    var end: [*:0]u8 = undefined;
    const value = c.strtod(text.ptr, &end);
    if (end == text.ptr or end[0] != 0) return null;
    if (!std.math.isFinite(value) or value <= 0.0 or value > 1.8e10) return null;
    return @intFromFloat(@floor(value * 1_000_000_000.0));
}

fn printUsage(program: [*:0]const u8) void {
    _ = c.fprintf(
        options.stderr(),
        "%s <number of measurements> <target time> [" ++ options.usage ++ "]\n",
        program,
    );
}

fn trapPanic(_: []const u8, _: ?usize) noreturn {
    @trap();
}
pub const panic = std.debug.FullPanic(trapPanic);

pub fn main(init: std.process.Init.Minimal) u8 {
    var args = std.process.Args.Iterator.initAllocator(init.args, std.heap.c_allocator) catch
        return 1;
    defer args.deinit();
    const program = args.next() orelse "jitterentropy-osr";
    const rounds_text = args.next() orelse {
        printUsage(program.ptr);
        return 1;
    };
    const target_text = args.next() orelse {
        printUsage(program.ptr);
        return 1;
    };
    const rounds = options.parseDecimal(rounds_text) orelse return 1;
    if (rounds == 0 or rounds >= std.math.maxInt(c_uint)) return 1;
    const time_bound = parseTarget(target_text) orelse return 1;

    var flags: c_uint = 0;
    while (args.next()) |arg| {
        switch (options.parse(&args, arg, &flags, null)) {
            .invalid => return 1,
            .recognized => continue,
            .unrecognized => {
                _ = c.fprintf(options.stderr(), "Unknown option %s\n", arg.ptr);
                return 1;
            },
        }
    }

    if (!options.raiseMemlockLimit(flags)) {
        _ = c.fprintf(
            options.stderr(),
            "Cannot raise the memory lock limit, allocating the entropy collector may fail\n",
        );
    }
    if (!options.initSecureMemory(flags)) {
        _ = c.fprintf(
            options.stderr(),
            "Cannot create the secure memory arena, allocating the entropy collector will fail\n",
        );
    }

    var max_bound: c_uint = 0;
    var max_time: u64 = 0;
    var min_bound: c_uint = JENT_MIN_OSR;
    var min_time = outputTime(rounds, min_bound, flags) orelse return 1;
    if (min_time > time_bound) {
        _ = c.fprintf(
            options.stderr(),
            "Minimum osr %u exceeds the target time. Invariant not met.\n",
            min_bound,
        );
        return 1;
    }
    _ = c.fprintf(
        options.stderr(),
        "A minimum was found: osr upper bound is >= %u.\n",
        min_bound,
    );

    var first_guess = clampOsr(
        @floatFromInt(time_bound / (1 + min_time / min_bound)),
        JENT_MAX_OSR - 1,
    );
    _ = c.fprintf(options.stderr(), "The initial linear estimate is osr=%u\n", first_guess);
    var first_time = outputTime(rounds, first_guess, flags) orelse return 1;
    var second_guess = clampOsr(
        @ceil(linearInverse(
            @floatFromInt(time_bound),
            @floatFromInt(min_bound),
            @floatFromInt(min_time),
            @floatFromInt(first_guess),
            @floatFromInt(first_time),
        )),
        JENT_MAX_OSR,
    );
    _ = c.fprintf(
        options.stderr(),
        "Linear interpolation suggests a cutoff of %u\n",
        second_guess,
    );
    if (second_guess == first_guess) second_guess += 1;
    var second_time = outputTime(rounds, second_guess, flags) orelse return 1;
    if (second_guess < first_guess) {
        std.mem.swap(c_uint, &first_guess, &second_guess);
        std.mem.swap(u64, &first_time, &second_time);
    }
    if (second_time <= first_time) {
        _ = c.fprintf(
            options.stderr(),
            "Note: osr %u did not measure slower than osr %u; the machine is busy.\n",
            second_guess,
            first_guess,
        );
    }

    if (first_time > time_bound) {
        if (first_guess <= min_bound) {
            _ = c.fprintf(
                options.stderr(),
                "The target time is at the edge of JENT_MIN_OSR (%u); no lower rate exists.\n",
                min_bound,
            );
            _ = c.fprintf(options.stdout(), "%u\n", min_bound);
            return 0;
        }
        max_bound = first_guess;
        max_time = first_time;
    } else if (second_time > time_bound) {
        min_bound = first_guess;
        min_time = first_time;
        max_bound = second_guess;
        max_time = second_time;
    } else {
        min_bound = second_guess;
        min_time = second_time;
    }

    if (max_bound == 0) {
        max_bound = clampOsr(@as(f64, @floatFromInt(min_bound)) * 2.0, JENT_MAX_OSR);
        if (max_bound <= min_bound) {
            _ = c.fprintf(
                options.stderr(),
                "The target time is met at JENT_MAX_OSR (%u); no higher rate exists.\n",
                JENT_MAX_OSR,
            );
            _ = c.fprintf(options.stdout(), "%u\n", min_bound);
            return 0;
        }
        _ = c.fprintf(options.stderr(), "Trying to find a maximum: %u", max_bound);
        while (true) {
            max_time = outputTime(rounds, max_bound, flags) orelse return 1;
            if (max_time > time_bound) break;
            min_bound = max_bound;
            min_time = max_time;
            if (max_bound >= JENT_MAX_OSR) {
                _ = c.fprintf(
                    options.stderr(),
                    ".\nThe target time is met at JENT_MAX_OSR (%u); no higher rate exists.\n",
                    JENT_MAX_OSR,
                );
                _ = c.fprintf(options.stdout(), "%u\n", min_bound);
                return 0;
            }
            max_bound = clampOsr(
                @as(f64, @floatFromInt(max_bound)) * 2.0,
                JENT_MAX_OSR,
            );
            _ = c.fprintf(options.stderr(), " %u", max_bound);
        }
        _ = c.fprintf(
            options.stderr(),
            ".\nMaximum found: osr upper bound is < %u.\n",
            max_bound,
        );
    }

    _ = c.fprintf(
        options.stderr(),
        "Desired osr upper bound is in [%u, %u)\n",
        min_bound,
        max_bound,
    );
    std.debug.assert(max_bound > min_bound);
    std.debug.assert(max_time > time_bound);
    std.debug.assert(min_time <= time_bound);

    while (max_bound - min_bound > 1) {
        const current = min_bound + (max_bound - min_bound) / 2;
        _ = c.fprintf(options.stderr(), "Trying osr=%u. ", current);
        const current_time = outputTime(rounds, current, flags) orelse return 1;
        if (current_time <= min_time or current_time >= max_time) {
            _ = c.fprintf(options.stderr(), "(timing out of order, the machine is busy) ");
        }
        if (current_time <= time_bound) {
            _ = c.fprintf(
                options.stderr(),
                "Timing is less than or equal to the target time. ",
            );
            min_bound = current;
            min_time = current_time;
        } else {
            _ = c.fprintf(options.stderr(), "Timing is greater than the target time. ");
            max_bound = current;
            max_time = current_time;
        }
        _ = c.fprintf(
            options.stderr(),
            "Desired osr upper bound is in [%u, %u)\n",
            min_bound,
            max_bound,
        );
        std.debug.assert(max_bound > min_bound);
        std.debug.assert(max_time > time_bound);
        std.debug.assert(min_time <= time_bound);
    }
    _ = c.fprintf(options.stdout(), "%u\n", min_bound);
    return 0;
}
