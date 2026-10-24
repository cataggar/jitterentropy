// SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0-only

const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");
const internal = @import("../internal.zig");
const is_linux_kernel = @hasDecl(root, "is_linux_kernel") and root.is_linux_kernel;
const external_crypto = internal.build_options.external_crypto;

extern fn jent_kshim_fips_enabled() callconv(.c) c_int;
extern fn gcry_control(cmd: c_uint, ...) callconv(.c) c_int;
extern fn FIPS_mode() callconv(.c) c_int;
extern fn EVP_default_properties_is_fips_enabled(libctx: ?*anyopaque) callconv(.c) c_int;
extern "c" fn getenv(name: [*:0]const u8) ?[*:0]const u8;
extern "c" fn access(path: [*:0]const u8, mode: c_int) c_int;
extern "c" fn _access(path: [*:0]const u8, mode: c_int) c_int;
extern "bcrypt" fn BCryptGetFipsAlgorithmMode(pfEnabled: *u8) callconv(.winapi) i32;

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
    if (is_linux_kernel) return jent_kshim_fips_enabled();
    if (comptime external_crypto == .libgcrypt) {
        const GCRYCTL_ANY_INITIALIZATION_P: c_uint = 38;
        const GCRYCTL_FIPS_MODE_P: c_uint = 55;
        if (gcry_control(GCRYCTL_ANY_INITIALIZATION_P, @as(c_int, 0)) != 0) {
            return if (gcry_control(GCRYCTL_FIPS_MODE_P, @as(c_int, 0)) != 0) 1 else 0;
        }
        if (getenv("LIBGCRYPT_FORCE_FIPS_MODE") != null) return 1;
        if (comptime builtin.os.tag == .windows) {
            if (_access("/etc/gcrypt/fips_enabled", 0) == 0) return 1;
        } else {
            if (access("/etc/gcrypt/fips_enabled", 0) == 0) return 1;
        }
        if (comptime builtin.os.tag == .linux and builtin.link_libc) {
            return jent_fips_enabled_file("/proc/sys/crypto/fips_enabled");
        }
        return 0;
    }
    if (comptime external_crypto == .awslc) {
        return if (FIPS_mode() != 0) 1 else 0;
    }
    if (comptime external_crypto == .openssl) {
        return if (EVP_default_properties_is_fips_enabled(null) != 0) 1 else 0;
    }
    if (comptime builtin.os.tag == .linux and builtin.link_libc) {
        return jent_fips_enabled_file("/proc/sys/crypto/fips_enabled");
    }
    if (comptime builtin.os.tag == .windows and builtin.link_libc) {
        var enabled: u8 = 0;
        if (BCryptGetFipsAlgorithmMode(&enabled) < 0) return 0;
        return if (enabled != 0) 1 else 0;
    }
    return 0;
}

pub fn jent_fips_enabled() callconv(.c) c_int {
    if (comptime internal.enable_test_hooks) {
        if (@atomicLoad(c_int, &jent_fi_force_fips_enabled, .seq_cst) != 0) return 1;
    }
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
