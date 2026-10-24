const std = @import("std");
const builtin = @import("builtin");
const tool_options = @import("tool_options");
const options = @import("options.zig");

pub const std_options_debug_threaded_io: ?*std.Io.Threaded = null;
pub const std_options: std.Options = .{
    .enable_segfault_handler = false,
    .signal_stack_size = null,
    .unexpected_error_tracing = false,
    .allow_stack_tracing = false,
};

const c = struct {
    extern fn fprintf(stream: *anyopaque, format: [*:0]const u8, ...) callconv(.c) c_int;
    extern fn fputs(text: [*:0]const u8, stream: *anyopaque) callconv(.c) c_int;
    extern fn malloc(size: usize) callconv(.c) ?*anyopaque;
    extern fn free(ptr: ?*anyopaque) callconv(.c) void;
};

const JENT_RECORD_COMMON: c_uint = 0;
const JENT_RECORD_HASHLOOP: c_uint = 1;
const JENT_RECORD_MEMACCESS: c_uint = 2;
const JENT_RECORD_CORES_ANY: c_uint = 0;
const JENT_RECORD_CORES_EFFICIENCY: c_uint = 1;
const JENT_RECORD_CORES_PERFORMANCE: c_uint = 2;

const RecordConfig = extern struct {
    file: ?[*:0]const u8 = null,
    rounds: c_ulong = 0,
    repeats: c_ulong = 0,
    flags: c_uint = 0,
    osr: c_uint = 0,
    loopcnt: c_uint = 0,
    source: c_uint = JENT_RECORD_COMMON,
    cpu: c_int = -1,
    cores: c_uint = JENT_RECORD_CORES_ANY,
    status: c_int = 0,
};

extern fn jent_record_report_len(config: *const RecordConfig) callconv(.c) usize;
extern fn jent_record_run(
    config: *const RecordConfig,
    report: [*]u8,
    report_len: usize,
) callconv(.c) c_int;

fn printUsage(program: [*:0]const u8) void {
    const cpu = if (tool_options.cpu_pinning) "|--cpu <NUM>" else "";
    const cores = if (builtin.os.tag == .macos) "|--e-cores|--p-cores" else "";
    _ = c.fprintf(
        options.stdout(),
        "%s <rounds per repeat> <number of repeats> <filename> [" ++
            options.usage ++ "|" ++ options.usage_osr ++
            "|--loopcnt <NUM>|--hashloop|--memaccess%s%s|--status]\n",
        program,
        cpu.ptr,
        cores.ptr,
    );
}

fn parseCount(text: [:0]const u8, what: [*:0]const u8) ?c_ulong {
    const value = options.parseDecimal(text) orelse {
        _ = c.fprintf(options.stderr(), "Invalid %s value %s\n", what, text.ptr);
        return null;
    };
    if (value == 0 or value >= std.math.maxInt(c_uint)) {
        _ = c.fprintf(options.stderr(), "Invalid %s value %s\n", what, text.ptr);
        return null;
    }
    return value;
}

fn trapPanic(_: []const u8, _: ?usize) noreturn {
    @trap();
}
pub const panic = std.debug.FullPanic(trapPanic);

pub fn main(init: std.process.Init.Minimal) u8 {
    var args = std.process.Args.Iterator.initAllocator(init.args, std.heap.c_allocator) catch
        return 1;
    defer args.deinit();
    const program = args.next() orelse "jitterentropy-hashtime";
    const rounds_text = args.next() orelse {
        printUsage(program.ptr);
        return 1;
    };
    const repeats_text = args.next() orelse {
        printUsage(program.ptr);
        return 1;
    };
    const file = args.next() orelse {
        printUsage(program.ptr);
        return 1;
    };

    var config = RecordConfig{
        .rounds = parseCount(rounds_text, "rounds") orelse return 1,
        .repeats = parseCount(repeats_text, "repeats") orelse return 1,
        .file = file.ptr,
    };

    while (args.next()) |arg| {
        switch (options.parse(&args, arg, &config.flags, &config.osr)) {
            .invalid => return 1,
            .recognized => continue,
            .unrecognized => {},
        }
        if (std.mem.startsWith(u8, arg, "--hashloop")) {
            config.source = JENT_RECORD_HASHLOOP;
        } else if (std.mem.startsWith(u8, arg, "--memaccess")) {
            config.source = JENT_RECORD_MEMACCESS;
        } else if (std.mem.startsWith(u8, arg, "--loopcnt")) {
            const value = options.optionValue(&args, "Loop count") orelse return 1;
            if (value >= std.math.maxInt(c_uint)) return 1;
            config.loopcnt = @intCast(value);
        } else if (std.mem.startsWith(u8, arg, "--cpu")) {
            const value = options.optionValue(&args, "CPU") orelse return 1;
            if (value > std.math.maxInt(c_int)) {
                _ = c.fprintf(options.stderr(), "Invalid CPU value %lu\n", value);
                return 1;
            }
            config.cpu = @intCast(value);
        } else if (std.mem.startsWith(u8, arg, "--e-cores")) {
            if (config.cores == JENT_RECORD_CORES_PERFORMANCE) {
                _ = c.fprintf(
                    options.stdout(),
                    "--cpu, --e-cores and --p-cores are mutually exclusive\n",
                );
                return 1;
            }
            config.cores = JENT_RECORD_CORES_EFFICIENCY;
        } else if (std.mem.startsWith(u8, arg, "--p-cores")) {
            if (config.cores == JENT_RECORD_CORES_EFFICIENCY) {
                _ = c.fprintf(
                    options.stdout(),
                    "--cpu, --e-cores and --p-cores are mutually exclusive\n",
                );
                return 1;
            }
            config.cores = JENT_RECORD_CORES_PERFORMANCE;
        } else if (std.mem.startsWith(u8, arg, "--status")) {
            config.status = 1;
        } else {
            _ = c.fprintf(options.stderr(), "Unknown option %s\n", arg.ptr);
            return 1;
        }
    }

    if (!options.raiseMemlockLimit(config.flags)) {
        _ = c.fprintf(
            options.stderr(),
            "Cannot raise the memory lock limit, allocating the entropy collector may fail\n",
        );
    }
    if (!options.initSecureMemory(config.flags)) {
        _ = c.fprintf(
            options.stderr(),
            "Cannot create the secure memory arena, allocating the entropy collector will fail\n",
        );
    }

    const report_len = jent_record_report_len(&config);
    const report_mem = c.malloc(report_len) orelse {
        _ = c.fprintf(options.stderr(), "Cannot allocate the report\n");
        return 1;
    };
    defer c.free(report_mem);
    const report: [*]u8 = @ptrCast(report_mem);
    const ret = jent_record_run(&config, report, report_len);
    _ = c.fputs(@ptrCast(report), options.stdout());
    return @intCast(ret);
}
