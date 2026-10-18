const std = @import("std");
const options = @import("options.zig");

const c = struct {
    extern fn fprintf(stream: *anyopaque, format: [*:0]const u8, ...) callconv(.c) c_int;
    extern fn fflush(stream: *anyopaque) callconv(.c) c_int;
};

const Flag = struct {
    name: [*:0]const u8,
    value: c_uint,
    note: ?[*:0]const u8 = null,
};

const bits = [_]Flag{
    .{ .name = "JENT_DISABLE_STIR", .value = 1 << 0, .note = "unused" },
    .{ .name = "JENT_DISABLE_UNBIAS", .value = 1 << 1, .note = "unused" },
    .{ .name = "JENT_DISABLE_MEMORY_ACCESS", .value = options.JENT_DISABLE_MEMORY_ACCESS },
    .{ .name = "JENT_FORCE_INTERNAL_TIMER", .value = options.JENT_FORCE_INTERNAL_TIMER },
    .{ .name = "JENT_DISABLE_INTERNAL_TIMER", .value = options.JENT_DISABLE_INTERNAL_TIMER },
    .{ .name = "JENT_FORCE_FIPS", .value = options.JENT_FORCE_FIPS },
    .{ .name = "JENT_NTG1", .value = options.JENT_NTG1 },
    .{ .name = "JENT_CACHE_ALL", .value = options.JENT_CACHE_ALL },
    .{ .name = "JENT_FORCE_SECURE_MEM", .value = options.JENT_FORCE_SECURE_MEM },
};

const memsizes = [_]Flag{
    .{ .name = "JENT_MAX_MEMSIZE_1kB", .value = 1 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_2kB", .value = 2 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_4kB", .value = 3 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_8kB", .value = 4 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_16kB", .value = 5 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_32kB", .value = 6 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_64kB", .value = 7 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_128kB", .value = 8 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_256kB", .value = 9 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_512kB", .value = 10 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_1MB", .value = 11 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_2MB", .value = 12 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_4MB", .value = 13 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_8MB", .value = 14 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_16MB", .value = 15 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_32MB", .value = 16 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_64MB", .value = 17 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_128MB", .value = 18 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_256MB", .value = 19 << 27 },
    .{ .name = "JENT_MAX_MEMSIZE_512MB", .value = 20 << 27 },
};

const hashloops = [_]Flag{
    .{ .name = "JENT_HASHLOOP_1", .value = 1 << 23 },
    .{ .name = "JENT_HASHLOOP_2", .value = 2 << 23 },
    .{ .name = "JENT_HASHLOOP_4", .value = 3 << 23 },
    .{ .name = "JENT_HASHLOOP_8", .value = 4 << 23 },
    .{ .name = "JENT_HASHLOOP_16", .value = 5 << 23 },
    .{ .name = "JENT_HASHLOOP_32", .value = 6 << 23 },
    .{ .name = "JENT_HASHLOOP_64", .value = 7 << 23 },
    .{ .name = "JENT_HASHLOOP_128", .value = 8 << 23 },
};

fn usage(program: [*:0]const u8) void {
    _ = c.fprintf(options.stderr(), "Usage: %s [--hex] FLAG ...\n", program);
    _ = c.fprintf(options.stderr(), "       %s --decode VALUE\n\n", program);
    _ = c.fprintf(
        options.stderr(),
        "FLAG is a JENT_* name, the JENT_ prefix and case optional,\n" ++
            "or one of " ++ options.usage ++ ".\n" ++
            "VALUE is decimal, or hexadecimal with a 0x prefix.\n",
    );
}

fn nameMatches(arg: []const u8, name_z: [*:0]const u8) bool {
    const name = std.mem.span(name_z);
    if (arg.len >= 5 and std.ascii.eqlIgnoreCase(arg[0..5], "JENT_"))
        return std.ascii.eqlIgnoreCase(arg, name);
    return std.ascii.eqlIgnoreCase(arg, name[5..]);
}

fn lookup(table: []const Flag, arg: []const u8) ?Flag {
    for (table) |flag| {
        if (nameMatches(arg, flag.name)) return flag;
    }
    return null;
}

fn add(flags: *c_uint, value: c_uint, arg: [*:0]const u8) bool {
    const fields = [_]c_uint{ options.JENT_MAX_MEMSIZE_MASK, options.JENT_MAX_HASHLOOP_MASK };
    for (fields) |field| {
        const have = flags.* & field;
        const added = value & field;
        if (have != 0 and added != 0 and have != added) {
            _ = c.fprintf(options.stderr(), "%s: field already set\n", arg);
            return false;
        }
    }
    flags.* |= value;
    return true;
}

fn bitsMask() c_uint {
    var mask: c_uint = 0;
    for (bits) |flag| mask |= flag.value;
    return mask;
}

fn reservedMask() c_uint {
    return ((@as(c_uint, 1) << 23) - 1) & ~bitsMask();
}

fn refusals(flags: c_uint) c_int {
    const memsize = flags >> 27;
    const hashloop = (flags >> 23) & 0xf;
    var count: c_int = 0;
    if (flags & reservedMask() != 0) {
        _ = c.fprintf(
            options.stderr(),
            "refused: reserved bits 0x%08x set\n",
            flags & reservedMask(),
        );
        count += 1;
    }
    if (memsize > memsizes.len) {
        _ = c.fprintf(
            options.stderr(),
            "refused: memory size field %u above %u\n",
            memsize,
            @as(c_uint, memsizes.len),
        );
        count += 1;
    }
    if (hashloop > hashloops.len) {
        _ = c.fprintf(
            options.stderr(),
            "refused: hash loop field %u above %u\n",
            hashloop,
            @as(c_uint, hashloops.len),
        );
        count += 1;
    }
    if (flags & options.JENT_FORCE_INTERNAL_TIMER != 0 and
        flags & options.JENT_DISABLE_INTERNAL_TIMER != 0)
    {
        _ = c.fprintf(
            options.stderr(),
            "refused: JENT_FORCE_INTERNAL_TIMER with JENT_DISABLE_INTERNAL_TIMER\n",
        );
        count += 1;
    }
    if (flags & options.JENT_FORCE_INTERNAL_TIMER != 0 and
        flags & options.JENT_NTG1 != 0)
    {
        _ = c.fprintf(
            options.stderr(),
            "refused: JENT_FORCE_INTERNAL_TIMER with JENT_NTG1\n",
        );
        count += 1;
    }
    if (flags & options.JENT_DISABLE_MEMORY_ACCESS != 0 and
        flags & (options.JENT_FORCE_FIPS | options.JENT_NTG1) != 0)
    {
        _ = c.fprintf(
            options.stderr(),
            "refused: JENT_DISABLE_MEMORY_ACCESS with JENT_FORCE_FIPS or JENT_NTG1\n",
        );
        count += 1;
    }
    return count;
}

fn printField(
    what: [*:0]const u8,
    mask: c_uint,
    field: c_uint,
    table: []const Flag,
) void {
    _ = c.fprintf(options.stdout(), "%-28s 0x%08x  ", what, mask);
    if (field == 0) {
        _ = c.fprintf(options.stdout(), "default\n");
    } else if (field <= table.len) {
        const flag = table[field - 1];
        _ = c.fprintf(options.stdout(), "%s (0x%08x)\n", flag.name, flag.value);
    } else {
        _ = c.fprintf(options.stdout(), "invalid value %u\n", field);
    }
}

fn decode(text_value: [:0]const u8) u8 {
    var text = text_value;
    var base: c_int = 10;
    if (std.mem.startsWith(u8, text, "0x") or std.mem.startsWith(u8, text, "0X")) {
        text = text[2..];
        base = 16;
    }
    if (text.len == 0 or !std.ascii.isHex(text[0])) {
        _ = c.fprintf(options.stderr(), "Invalid value\n");
        return 1;
    }
    const value = options.parseUnsigned(text, base) orelse {
        _ = c.fprintf(options.stderr(), "Invalid value\n");
        return 1;
    };
    if (value > std.math.maxInt(c_uint)) {
        _ = c.fprintf(options.stderr(), "Invalid value\n");
        return 1;
    }
    const flags: c_uint = @intCast(value);

    _ = c.fprintf(options.stdout(), "0x%08x = %u\n", flags, flags);
    for (bits) |flag| {
        var state: [*:0]const u8 = if (flags & flag.value != 0) "set" else "-";
        if (flag.value == options.JENT_FORCE_SECURE_MEM and
            flags & flag.value == 0 and
            flags & (options.JENT_FORCE_FIPS | options.JENT_NTG1) != 0)
        {
            state = "implied";
        }
        _ = c.fprintf(options.stdout(), "%-28s 0x%08x  %s", flag.name, flag.value, state);
        if (flag.note) |note| _ = c.fprintf(options.stdout(), " (%s)", note);
        _ = c.fprintf(options.stdout(), "\n");
    }
    _ = c.fprintf(
        options.stdout(),
        "%-28s 0x%08x  %s\n",
        "reserved",
        reservedMask(),
        @as([*:0]const u8, if (flags & reservedMask() != 0) "set" else "-"),
    );
    printField("hash loop field", options.JENT_MAX_HASHLOOP_MASK, (flags >> 23) & 0xf, &hashloops);
    printField("memory size field", options.JENT_MAX_MEMSIZE_MASK, flags >> 27, &memsizes);
    _ = c.fflush(options.stdout());
    return if (refusals(flags) != 0) 1 else 0;
}

fn trapPanic(_: []const u8, _: ?usize) noreturn {
    @trap();
}
pub const panic = std.debug.FullPanic(trapPanic);

pub fn main(init: std.process.Init.Minimal) u8 {
    var args = std.process.Args.Iterator.initAllocator(init.args, std.heap.c_allocator) catch
        return 1;
    defer args.deinit();
    const program = args.next() orelse "jitterentropy-flags";
    const first = args.next() orelse {
        usage(program.ptr);
        return 1;
    };
    if (std.mem.eql(u8, first, "--decode")) {
        const value = args.next() orelse {
            usage(program.ptr);
            return 1;
        };
        if (args.next() != null) {
            usage(program.ptr);
            return 1;
        }
        return decode(value);
    }

    var flags: c_uint = 0;
    var hex = false;
    var current: ?[:0]const u8 = first;
    while (current) |arg| : (current = args.next()) {
        if (std.mem.eql(u8, arg, "--hex")) {
            hex = true;
            continue;
        }
        if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            usage(program.ptr);
            return 0;
        }
        if (std.mem.eql(u8, arg, "--decode")) {
            usage(program.ptr);
            return 1;
        }

        var parsed_flags: c_uint = 0;
        switch (options.parse(&args, arg, &parsed_flags, null)) {
            .invalid => return 1,
            .recognized => {
                if (!add(&flags, parsed_flags, arg.ptr)) return 1;
                continue;
            },
            .unrecognized => {},
        }

        const flag = lookup(&bits, arg) orelse
            lookup(&memsizes, arg) orelse
            lookup(&hashloops, arg) orelse {
            _ = c.fprintf(options.stderr(), "Unknown flag %s\n", arg.ptr);
            usage(program.ptr);
            return 1;
        };
        if (!add(&flags, flag.value, arg.ptr)) return 1;
    }

    if (hex)
        _ = c.fprintf(options.stdout(), "0x%08x\n", flags)
    else
        _ = c.fprintf(options.stdout(), "%u\n", flags);
    _ = c.fflush(options.stdout());
    return if (refusals(flags) != 0) 1 else 0;
}
