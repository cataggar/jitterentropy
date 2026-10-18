// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");

const root = @import("root");
const is_linux_kernel = @hasDecl(root, "is_linux_kernel") and root.is_linux_kernel;
const enable_test_hooks = (@hasDecl(build_options, "export_internals") and build_options.export_internals) or builtin.is_test;

extern fn jent_kshim_get_random_bytes(buf: [*]u8, len: usize) callconv(.c) void;

pub var jent_fi_fail_getrandom: c_int = 0;

pub fn jent_os_random_supported() callconv(.c) c_int {
    return if (hasRandomBackend()) 1 else 0;
}

pub fn jent_os_random_bytes(buf: [*]u8, len: usize) callconv(.c) c_int {
    if (is_linux_kernel) {
        jent_kshim_get_random_bytes(buf, len);
        return 0;
    }
    const os = builtin.os.tag;
    if (comptime os == .windows) return windowsRandom(buf, len);
    if (comptime usesArc4Random(os)) {
        arc4random_buf(buf, len);
        return 0;
    }
    if (comptime os == .linux) {
        if (comptime hasLibcGetrandom()) {
            const fail_getrandom = if (comptime enable_test_hooks)
                @atomicLoad(c_int, &jent_fi_fail_getrandom, .seq_cst) != 0
            else
                false;
            if (!fail_getrandom) {
                var offset: usize = 0;
                while (offset < len) {
                    const result = getrandom(buf + offset, len - offset, GRND_NONBLOCK);
                    if (result < 0) {
                        switch (std.posix.errno(result)) {
                            .INTR => continue,
                            .AGAIN => return -1,
                            else => break,
                        }
                        break;
                    }
                    if (result == 0) break;
                    offset += @intCast(result);
                }
                if (offset == len) return 0;
            }
        }
        return jent_random_dev_urandom(buf, len);
    }
    if (comptime usesDevUrandom(os)) return jent_random_dev_urandom(buf, len);
    return -1;
}

pub fn jent_random_read_file(path: [*:0]const u8, buf: [*]u8, len: usize) callconv(.c) c_int {
    if (comptime !usesDevUrandom(builtin.os.tag) and builtin.os.tag != .linux) return -1;

    const fd = open(path, O_RDONLY | cloexecFlag(), @as(c_uint, 0));
    if (fd < 0) return -1;
    defer _ = close(fd);

    var offset: usize = 0;
    while (offset < len) {
        const result = read(fd, buf + offset, len - offset);
        if (result < 0) {
            if (std.posix.errno(result) == .INTR) continue;
            break;
        }
        if (result == 0) break;
        offset += @intCast(result);
    }
    return if (offset == len) 0 else -1;
}

pub fn jent_random_dev_urandom(buf: [*]u8, len: usize) callconv(.c) c_int {
    return jent_random_read_file("/dev/urandom", buf, len);
}

fn hasRandomBackend() bool {
    if (is_linux_kernel) return true;
    const os = builtin.os.tag;
    return os == .windows or os == .linux or usesArc4Random(os) or usesDevUrandom(os);
}

fn hasLibcGetrandom() bool {
    if (builtin.os.tag != .linux) return false;
    if (builtin.target.isGnuLibC()) {
        return builtin.os.version_range.linux.glibc.order(.{ .major = 2, .minor = 25, .patch = 0 }) != .lt;
    }
    if (builtin.target.abi.isAndroid()) {
        return builtin.os.version_range.linux.android >= 28;
    }
    return true;
}

fn usesArc4Random(os: std.Target.Os.Tag) bool {
    return switch (os) {
        .macos,
        .ios,
        .tvos,
        .watchos,
        .visionos,
        .freebsd,
        .openbsd,
        .netbsd,
        .dragonfly,
        => true,
        else => false,
    };
}

fn usesDevUrandom(os: std.Target.Os.Tag) bool {
    return switch (os) {
        .illumos, .haiku => true,
        else => false,
    };
}

extern fn arc4random_buf(buf: [*]u8, len: usize) callconv(.c) void;
extern fn getrandom(buf: [*]u8, len: usize, flags: c_uint) callconv(.c) isize;
extern fn open(path: [*:0]const u8, flags: c_int, ...) callconv(.c) c_int;
extern fn read(fd: c_int, buf: [*]u8, len: usize) callconv(.c) isize;
extern fn close(fd: c_int) callconv(.c) c_int;

const O_RDONLY: c_int = 0;
const GRND_NONBLOCK: c_uint = 0x0001;

fn cloexecFlag() c_int {
    return switch (builtin.os.tag) {
        .linux, .haiku => 0x00080000,
        .illumos => 0x00800000,
        else => 0,
    };
}

const BCRYPT_USE_SYSTEM_PREFERRED_RNG: c_ulong = 0x00000002;
const ULONG_MAX: usize = std.math.maxInt(c_ulong);

extern "bcrypt" fn BCryptGenRandom(
    algorithm: ?*anyopaque,
    buf: [*]u8,
    len: c_ulong,
    flags: c_ulong,
) callconv(.winapi) c_long;

fn windowsRandom(initial_buf: [*]u8, initial_len: usize) c_int {
    var buf = initial_buf;
    var len = initial_len;
    while (len != 0) {
        const chunk: c_ulong = @intCast(@min(len, ULONG_MAX));
        if (BCryptGenRandom(null, buf, chunk, BCRYPT_USE_SYSTEM_PREFERRED_RNG) != 0) return -1;
        buf += chunk;
        len -= chunk;
    }
    return 0;
}
