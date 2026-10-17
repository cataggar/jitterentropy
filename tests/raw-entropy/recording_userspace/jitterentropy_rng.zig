const std = @import("std");
const builtin = @import("builtin");
const options = @import("options.zig");

const Collector = opaque {};

const c = struct {
    extern fn fprintf(stream: *anyopaque, format: [*:0]const u8, ...) callconv(.c) c_int;
    extern fn fwrite(
        ptr: *const anyopaque,
        size: usize,
        count: usize,
        stream: *anyopaque,
    ) callconv(.c) usize;
    extern fn fflush(stream: *anyopaque) callconv(.c) c_int;

    extern fn _setmode(fd: c_int, mode: c_int) callconv(.c) c_int;
    extern fn _fileno(stream: *anyopaque) callconv(.c) c_int;
};

extern fn jent_entropy_init_ex(osr: c_uint, flags: c_uint) callconv(.c) c_int;
extern fn jent_entropy_collector_alloc(osr: c_uint, flags: c_uint) callconv(.c) ?*Collector;
extern fn jent_entropy_collector_free(ec: ?*Collector) callconv(.c) void;
extern fn jent_read_entropy_safe(
    ec: *?*Collector,
    data: [*]u8,
    len: usize,
) callconv(.c) isize;
extern fn jent_set_fips_failure_callback(
    callback: ?*const fn (?*Collector, c_uint) callconv(.c) void,
) callconv(.c) c_int;
extern fn jent_status(ec: ?*const Collector, buf: [*]u8, len: usize) callconv(.c) c_int;
extern fn jent_entropy_collector_uuid(
    ec: ?*const Collector,
    buf: [*]u8,
    len: usize,
) callconv(.c) c_int;
extern fn jent_entropy_collector_osr(ec: ?*const Collector) callconv(.c) c_uint;
extern fn jent_entropy_collector_memsize(ec: ?*const Collector) callconv(.c) usize;
extern fn jent_entropy_collector_reinitializations(ec: ?*const Collector) callconv(.c) c_uint;
extern fn jent_entropy_collector_hashloops(ec: ?*const Collector) callconv(.c) c_uint;

const JENT_RCT_FAILURE: c_uint = 1;
const JENT_APT_FAILURE: c_uint = 2;
const JENT_LAG_FAILURE: c_uint = 4;
const JENT_RCT_MEM_FAILURE: c_uint = 8;
const JENT_PERMANENT_FAILURE_SHIFT: u5 = 16;
const JENT_UUID_STRLEN: usize = 37;

fn healthFailure(ec: ?*Collector, health_failure: c_uint) callconv(.c) void {
    const bits = health_failure | (health_failure >> JENT_PERMANENT_FAILURE_SHIFT);
    var uuid: [JENT_UUID_STRLEN]u8 = undefined;
    if (jent_entropy_collector_uuid(ec, &uuid, uuid.len) != 0) {
        const unknown = "(unknown)";
        @memcpy(uuid[0..unknown.len], unknown);
        uuid[unknown.len] = 0;
    }
    _ = c.fprintf(
        options.stderr(),
        "%s health test failure 0x%x:%s%s%s%s, instance %s, reinit %u, osr %u, hashloop %u, memsize %u\n",
        @as([*:0]const u8, if (health_failure >> JENT_PERMANENT_FAILURE_SHIFT != 0) "permanent" else "intermittent"),
        health_failure,
        @as([*:0]const u8, if (bits & JENT_RCT_FAILURE != 0) " RCT" else ""),
        @as([*:0]const u8, if (bits & JENT_APT_FAILURE != 0) " APT" else ""),
        @as([*:0]const u8, if (bits & JENT_LAG_FAILURE != 0) " lag" else ""),
        @as([*:0]const u8, if (bits & JENT_RCT_MEM_FAILURE != 0) " RCT-mem" else ""),
        &uuid,
        jent_entropy_collector_reinitializations(ec),
        jent_entropy_collector_osr(ec),
        jent_entropy_collector_hashloops(ec),
        @as(c_uint, @intCast(jent_entropy_collector_memsize(ec))),
    );
}

fn printUsage(program: [*:0]const u8) void {
    _ = c.fprintf(
        options.stderr(),
        "%s <number of measurements> [" ++ options.usage ++ "|" ++
            options.usage_osr ++ "|--hex]\n",
        program,
    );
}

fn parseRounds(text_value: []const u8) ?u64 {
    var text = text_value;
    while (text.len != 0 and (text[0] == ' ' or text[0] == '\t')) text = text[1..];
    if (text.len == 0 or text[0] == '-' or text[0] == '+') return null;
    const rounds = std.fmt.parseInt(u64, text, 10) catch return null;
    if (rounds == std.math.maxInt(u64)) return null;
    return rounds;
}

fn outputHex(data: *const [32]u8) bool {
    const digits = "0123456789ABCDEF";
    var encoded: [64]u8 = undefined;
    for (data, 0..) |byte, i| {
        encoded[i * 2] = digits[byte >> 4];
        encoded[i * 2 + 1] = digits[byte & 0xf];
    }
    return c.fwrite(&encoded, encoded.len, 1, options.stdout()) == 1;
}

pub fn main(init: std.process.Init) u8 {
    var args = std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa) catch
        return 1;
    defer args.deinit();
    const program = args.next() orelse "jitterentropy-rng";
    const rounds_text = args.next() orelse {
        printUsage(program.ptr);
        return 1;
    };
    const rounds = parseRounds(rounds_text) orelse {
        _ = c.fprintf(options.stderr(), "Invalid rounds value %s\n", rounds_text.ptr);
        return 1;
    };

    var flags: c_uint = 0;
    var osr: c_uint = 0;
    var hex = false;
    while (args.next()) |arg| {
        switch (options.parse(&args, arg, &flags, &osr)) {
            .invalid => return 1,
            .recognized => continue,
            .unrecognized => {},
        }
        if (std.mem.startsWith(u8, arg, "--hex")) {
            hex = true;
        } else {
            _ = c.fprintf(options.stderr(), "Unknown option %s\n", arg.ptr);
            return 1;
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

    var ret = jent_set_fips_failure_callback(healthFailure);
    if (ret != 0) {
        _ = c.fprintf(
            options.stderr(),
            "Cannot register the health failure callback: %d\n",
            ret,
        );
        return 1;
    }
    ret = jent_entropy_init_ex(osr, flags);
    if (ret != 0) {
        _ = c.fprintf(
            options.stderr(),
            "The initialization failed with error code %d\n",
            ret,
        );
        return @intCast(ret);
    }

    var ec = jent_entropy_collector_alloc(osr, flags);
    if (ec == null) {
        _ = c.fprintf(options.stderr(), "Jitter RNG handle cannot be allocated\n");
        return 1;
    }
    defer jent_entropy_collector_free(ec);

    var status: [4096]u8 = undefined;
    if (jent_status(ec, &status, status.len) != 0) {
        _ = c.fprintf(options.stderr(), "Cannot obtain status information\n");
        return 1;
    }
    _ = c.fprintf(options.stderr(), "%s", &status);

    if (builtin.os.tag == .windows and !hex) {
        const O_BINARY = 0x8000;
        if (c._setmode(c._fileno(options.stdout()), O_BINARY) == -1) {
            _ = c.fprintf(options.stderr(), "Cannot switch stdout to binary mode\n");
            return 1;
        }
    }

    var block: u64 = 0;
    while (block < rounds) : (block += 1) {
        var data: [32]u8 = undefined;
        const rc = jent_read_entropy_safe(&ec, &data, data.len);
        if (rc < 0) {
            _ = c.fprintf(
                options.stderr(),
                "Reading random data failed with error code %zd\n",
                rc,
            );
            return 1;
        }
        const success = if (hex)
            outputHex(&data)
        else
            c.fwrite(&data, data.len, 1, options.stdout()) == 1;
        if (!success) {
            _ = c.fprintf(options.stderr(), "Can't output data\n");
            return 1;
        }
    }
    if (c.fflush(options.stdout()) != 0) {
        _ = c.fprintf(options.stderr(), "Can't output data\n");
        return 1;
    }
    return 0;
}
