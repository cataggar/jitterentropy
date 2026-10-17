const std = @import("std");
const builtin = @import("builtin");
const tool_options = @import("tool_options");

pub const usage =
    "--ntg1|--force-fips|--disable-memory-access|" ++
    "--disable-internal-timer|--force-internal-timer|--all-caches|" ++
    "--max-mem <NUM>|--hloopcnt <NUM>";
pub const usage_osr = "--osr <OSR>";

pub const JENT_DISABLE_MEMORY_ACCESS: c_uint = 1 << 2;
pub const JENT_FORCE_INTERNAL_TIMER: c_uint = 1 << 3;
pub const JENT_DISABLE_INTERNAL_TIMER: c_uint = 1 << 4;
pub const JENT_FORCE_FIPS: c_uint = 1 << 5;
pub const JENT_NTG1: c_uint = 1 << 6;
pub const JENT_CACHE_ALL: c_uint = 1 << 7;
pub const JENT_FORCE_SECURE_MEM: c_uint = 1 << 8;
pub const JENT_MAX_HASHLOOP_MASK: c_uint = 0xf << 23;
pub const JENT_MAX_MEMSIZE_MASK: c_uint = 0x1f << 27;

const c = struct {
    extern fn fprintf(stream: *anyopaque, format: [*:0]const u8, ...) callconv(.c) c_int;
    extern fn fdopen(fd: c_int, mode: [*:0]const u8) callconv(.c) ?*anyopaque;
    extern fn _fdopen(fd: c_int, mode: [*:0]const u8) callconv(.c) ?*anyopaque;
    extern fn strtoul(
        str: [*:0]const u8,
        end: *[*:0]u8,
        base: c_int,
    ) callconv(.c) c_ulong;

    extern fn __errno_location() callconv(.c) *c_int;
    extern fn __error() callconv(.c) *c_int;
    extern fn _errno() callconv(.c) *c_int;
};

var stdout_stream: ?*anyopaque = null;
var stderr_stream: ?*anyopaque = null;

fn openStream(fd: c_int) *anyopaque {
    const stream = if (builtin.os.tag == .windows)
        c._fdopen(fd, "w")
    else
        c.fdopen(fd, "w");
    return stream orelse @panic("standard stream is unavailable");
}

pub fn stdout() *anyopaque {
    if (stdout_stream == null) stdout_stream = openStream(1);
    return stdout_stream.?;
}

pub fn stderr() *anyopaque {
    if (stderr_stream == null) stderr_stream = openStream(2);
    return stderr_stream.?;
}

fn errnoPtr() *c_int {
    return switch (builtin.os.tag) {
        .windows => c._errno(),
        .macos, .ios, .tvos, .watchos, .visionos, .freebsd, .netbsd, .openbsd, .dragonfly => c.__error(),
        else => c.__errno_location(),
    };
}

pub fn parseUnsigned(text: [:0]const u8, base: c_int) ?c_ulong {
    var end: [*:0]u8 = undefined;
    errnoPtr().* = 0;
    const value = c.strtoul(text.ptr, &end, base);
    if (end == text.ptr or end[0] != 0 or errnoPtr().* != 0) return null;
    return value;
}

pub fn parseDecimal(text: [:0]const u8) ?c_ulong {
    return parseUnsigned(text, 10);
}

pub fn optionValue(
    args: *std.process.Args.Iterator,
    what: [*:0]const u8,
) ?c_ulong {
    const text = args.next() orelse {
        _ = c.fprintf(stderr(), "%s value missing\n", what);
        return null;
    };
    return parseDecimal(text) orelse {
        _ = c.fprintf(stderr(), "Invalid numeric value \"%s\"\n", text.ptr);
        return null;
    };
}

pub const ParseResult = enum {
    unrecognized,
    recognized,
    invalid,
};

fn startsWith(arg: []const u8, prefix: []const u8) bool {
    return std.mem.startsWith(u8, arg, prefix);
}

pub fn parse(
    args: *std.process.Args.Iterator,
    arg: [:0]const u8,
    flags: *c_uint,
    osr: ?*c_uint,
) ParseResult {
    if (startsWith(arg, "--ntg1")) {
        flags.* |= JENT_NTG1;
    } else if (startsWith(arg, "--force-fips")) {
        flags.* |= JENT_FORCE_FIPS;
    } else if (startsWith(arg, "--disable-memory-access")) {
        flags.* |= JENT_DISABLE_MEMORY_ACCESS;
    } else if (startsWith(arg, "--disable-internal-timer")) {
        flags.* |= JENT_DISABLE_INTERNAL_TIMER;
    } else if (startsWith(arg, "--force-internal-timer")) {
        flags.* |= JENT_FORCE_INTERNAL_TIMER;
    } else if (startsWith(arg, "--all-caches")) {
        flags.* |= JENT_CACHE_ALL;
    } else if (osr != null and startsWith(arg, "--osr")) {
        const value = optionValue(args, "OSR") orelse return .invalid;
        if (value >= std.math.maxInt(c_uint)) return .invalid;
        osr.?.* = @intCast(value);
    } else if (startsWith(arg, "--max-mem")) {
        const value = optionValue(args, "Maximum memory") orelse return .invalid;
        if (value > 20) {
            _ = c.fprintf(stderr(), "Unknown maximum memory value\n");
            return .invalid;
        }
        flags.* &= ~JENT_MAX_MEMSIZE_MASK;
        flags.* |= @as(c_uint, @intCast(value)) << 27;
    } else if (startsWith(arg, "--hloopcnt")) {
        const value = optionValue(args, "Hash loop count") orelse return .invalid;
        if (value > 7) {
            _ = c.fprintf(stderr(), "Unknown hashloop value\n");
            return .invalid;
        }
        flags.* &= ~JENT_MAX_HASHLOOP_MASK;
        flags.* |= (@as(c_uint, @intCast(value)) + 1) << 23;
    } else {
        return .unrecognized;
    }
    return .recognized;
}

const crypto = struct {
    const GCRYCTL_INIT_SECMEM: c_int = 24;
    const GCRYCTL_SUSPEND_SECMEM_WARN: c_int = 28;
    const GCRYCTL_RESUME_SECMEM_WARN: c_int = 29;
    const GCRYCTL_INITIALIZATION_FINISHED: c_int = 38;
    const GCRYCTL_INITIALIZATION_FINISHED_P: c_int = 39;

    extern fn gcry_check_version(required_version: ?[*:0]const u8) callconv(.c) ?[*:0]const u8;
    extern fn gcry_control(command: c_int, ...) callconv(.c) c_uint;

    extern fn CRYPTO_secure_malloc_initialized() callconv(.c) c_int;
    extern fn CRYPTO_secure_malloc_init(size: usize, minimum: usize) callconv(.c) c_int;
    extern fn CRYPTO_secure_malloc_done() callconv(.c) c_int;
};

const JENT_MEMLOCK_SIZE: u64 = 1 << 20;
const JENT_SECMEM_SIZE: u64 = 2 << 20;

fn memlockRequired(flags: c_uint) bool {
    if (tool_options.libgcrypt or tool_options.openssl) return true;
    return flags & (JENT_NTG1 | JENT_FORCE_FIPS | JENT_FORCE_SECURE_MEM) != 0;
}

fn memlockSize() u64 {
    return if (tool_options.libgcrypt or tool_options.openssl)
        JENT_SECMEM_SIZE + JENT_MEMLOCK_SIZE
    else
        JENT_MEMLOCK_SIZE;
}

const windows = struct {
    const Handle = ?*anyopaque;
    const HARDWS_MIN_DISABLE: c_ulong = 0x00000002;
    const HARDWS_MAX_DISABLE: c_ulong = 0x00000008;
    const HEADROOM: usize = 1 << 20;
    const MINIMUM: usize = 1 << 20;

    extern "kernel32" fn GetCurrentProcess() callconv(.winapi) Handle;
    extern "kernel32" fn GetProcessWorkingSetSizeEx(
        process: Handle,
        minimum: *usize,
        maximum: *usize,
        flags: *c_ulong,
    ) callconv(.winapi) c_int;
    extern "kernel32" fn SetProcessWorkingSetSizeEx(
        process: Handle,
        minimum: usize,
        maximum: usize,
        flags: c_ulong,
    ) callconv(.winapi) c_int;

    fn setWorkingSet(want: usize) bool {
        var minimum: usize = 0;
        var maximum: usize = 0;
        var flags: c_ulong = 0;
        if (GetProcessWorkingSetSizeEx(
            GetCurrentProcess(),
            &minimum,
            &maximum,
            &flags,
        ) == 0) return false;
        if (flags == 0) flags = HARDWS_MIN_DISABLE | HARDWS_MAX_DISABLE;
        const wanted_minimum = std.math.add(usize, minimum, want) catch return false;
        const with_headroom = std.math.add(usize, wanted_minimum, HEADROOM) catch return false;
        const wanted_maximum = @max(maximum, with_headroom);
        return SetProcessWorkingSetSizeEx(
            GetCurrentProcess(),
            wanted_minimum,
            wanted_maximum,
            flags,
        ) != 0;
    }
};

pub fn raiseMemlockLimit(flags: c_uint) bool {
    if (!memlockRequired(flags)) return true;
    if (builtin.os.tag == .windows) {
        var want: usize = @intCast(memlockSize());
        if (windows.setWorkingSet(want)) return true;
        want /= 2;
        while (want >= windows.MINIMUM) : (want /= 2) {
            if (windows.setWorkingSet(want)) return true;
        }
        return false;
    }
    if (builtin.os.tag == .freestanding or !builtin.link_libc) return true;
    if (@hasDecl(std.c, "rlimit_resource") and
        @hasDecl(std.c, "getrlimit") and
        @hasDecl(std.c, "setrlimit") and
        @hasField(std.c.rlimit_resource, "MEMLOCK"))
    {
        var limit: std.c.rlimit = undefined;
        if (std.c.getrlimit(.MEMLOCK, &limit) != 0) return false;
        const want: @TypeOf(limit.cur) = @intCast(memlockSize());
        if (limit.cur == std.c.RLIM.INFINITY or limit.cur >= want) return true;
        limit.cur = want;
        if (limit.max != std.c.RLIM.INFINITY and limit.max < want) limit.max = want;
        if (std.c.setrlimit(.MEMLOCK, &limit) == 0) return true;
        if (std.c.getrlimit(.MEMLOCK, &limit) != 0) return false;
        if (limit.cur >= limit.max) return true;
        limit.cur = limit.max;
        return std.c.setrlimit(.MEMLOCK, &limit) == 0;
    }
    return true;
}

pub fn initSecureMemory(flags: c_uint) bool {
    _ = flags;
    if (tool_options.libgcrypt) {
        if (crypto.gcry_check_version(null) == null) return false;
        if (crypto.gcry_control(crypto.GCRYCTL_INITIALIZATION_FINISHED_P) != 0) return true;
        _ = crypto.gcry_control(crypto.GCRYCTL_SUSPEND_SECMEM_WARN);
        if (crypto.gcry_control(
            crypto.GCRYCTL_INIT_SECMEM,
            @as(c_uint, JENT_SECMEM_SIZE),
            @as(c_int, 0),
        ) != 0) {
            _ = crypto.gcry_control(crypto.GCRYCTL_RESUME_SECMEM_WARN);
            return false;
        }
        _ = crypto.gcry_control(crypto.GCRYCTL_RESUME_SECMEM_WARN);
        _ = crypto.gcry_control(
            crypto.GCRYCTL_INITIALIZATION_FINISHED,
            @as(c_int, 0),
        );
        return true;
    }
    if (tool_options.openssl) {
        if (crypto.CRYPTO_secure_malloc_initialized() != 0) return true;
        return switch (crypto.CRYPTO_secure_malloc_init(JENT_SECMEM_SIZE, 32)) {
            1 => true,
            2 => blk: {
                _ = crypto.CRYPTO_secure_malloc_done();
                break :blk false;
            },
            else => false,
        };
    }
    return true;
}
