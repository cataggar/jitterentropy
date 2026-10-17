// SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0-only

const std = @import("std");
const builtin = @import("builtin");

const linux = struct {
    const O_RDONLY: c_int = 0;
    const O_CLOEXEC: c_int = 0x80000;
    const EINTR: c_int = 4;

    extern "c" fn open(path: [*:0]const u8, flags: c_int, ...) c_int;
    extern "c" fn read(fd: c_int, buf: [*]u8, count: usize) isize;
    extern "c" fn close(fd: c_int) c_int;
    extern "c" fn __errno_location() *c_int;
};

pub var jent_fi_force_fips_enabled: c_int = 0;

fn fipsByteEnabled(value: u8) c_int {
    return if (value == '1') 1 else 0;
}

pub fn jent_fips_enabled_file(file: [*:0]const u8) callconv(.c) c_int {
    if (comptime builtin.os.tag != .linux or !builtin.link_libc) return 0;

    const fd = linux.open(file, linux.O_RDONLY | linux.O_CLOEXEC, @as(c_uint, 0));
    if (fd < 0) return 0;
    defer _ = linux.close(fd);

    var buf: [2]u8 = .{ '0', 0 };
    var len: isize = undefined;
    while (true) {
        len = linux.read(fd, &buf, buf.len);
        if (len >= 0 or linux.__errno_location().* != linux.EINTR) break;
    }
    if (len <= 0) return 0;
    return fipsByteEnabled(buf[0]);
}

pub fn jent_fi_real_fips_enabled() callconv(.c) c_int {
    if (comptime builtin.os.tag == .linux and builtin.link_libc) {
        return jent_fips_enabled_file("/proc/sys/crypto/fips_enabled");
    }
    return 0;
}

pub fn jent_fips_enabled() callconv(.c) c_int {
    if (@atomicLoad(c_int, &jent_fi_force_fips_enabled, .seq_cst) != 0) return 1;
    return jent_fi_real_fips_enabled();
}

test "FIPS indicator accepts only one" {
    try std.testing.expectEqual(@as(c_int, 1), fipsByteEnabled('1'));
    try std.testing.expectEqual(@as(c_int, 0), fipsByteEnabled('0'));
    try std.testing.expectEqual(@as(c_int, 0), fipsByteEnabled('2'));
}

test "FIPS fault injection overrides platform detection" {
    const saved = jent_fi_force_fips_enabled;
    defer jent_fi_force_fips_enabled = saved;

    jent_fi_force_fips_enabled = 1;
    try std.testing.expectEqual(@as(c_int, 1), jent_fips_enabled());
}
