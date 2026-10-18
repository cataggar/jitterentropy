// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause
//
// jitter_rng: information about the jitter_rng kernel module, and random
// bytes from it, through libjitterentropy-kernel.
//
// Copyright (C) 2026, Stephan Mueller <smueller@chronox.de>
// Copyright (C) 2026, Markus Theil <theil.markus@gmail.com>

const std = @import("std");

fn trapPanic(_: []const u8, _: ?usize) noreturn {
    @trap();
}
pub const panic = std.debug.FullPanic(trapPanic);

const JENT_KERNEL_DEVICE: [:0]const u8 = "/dev/jitterentropy";
const JENT_KERNEL_STATUS_LEN: usize = 4096;
const JENT_KERNEL_UUID_STRLEN: usize = 37;

extern "c" fn jent_kernel_open(path: ?[*:0]const u8) c_int;
extern "c" fn jent_kernel_close(fd: c_int) c_int;
extern "c" fn jent_kernel_read(fd: c_int, buf: ?*anyopaque, len: usize) isize;
extern "c" fn jent_kernel_status(fd: c_int, buf: [*]u8, buflen: usize) c_int;
extern "c" fn jent_kernel_uuid(fd: c_int, buf: [*]u8, buflen: usize) c_int;
extern "c" fn jent_kernel_version(fd: c_int, version: *c_uint) c_int;
extern "c" fn jent_kernel_osr(fd: c_int, osr: *c_uint) c_int;
extern "c" fn jent_kernel_flags(fd: c_int, flags: *c_uint) c_int;
extern "c" fn jent_kernel_health_failure(fd: c_int, health_failure: *c_uint) c_int;
extern "c" fn jent_kernel_output(fd: c_int, read_invocations: ?*u64, bytes_output: ?*u64) c_int;
extern "c" fn jent_kernel_reinitializations(fd: c_int, reinitializations: *c_uint) c_int;
extern "c" fn jent_kernel_memsize(fd: c_int, memsize: *usize) c_int;
extern "c" fn jent_kernel_hashloops(fd: c_int, hashloops: *c_uint) c_int;
extern "c" fn jent_kernel_selftest(fd: c_int) c_int;
extern "c" fn jent_kernel_proc(name: [*:0]const u8, buf: [*]u8, buflen: usize) c_int;

const FILE = opaque {};
extern "c" var stdout: *FILE;
extern "c" var stderr: *FILE;
extern "c" fn printf(fmt: [*:0]const u8, ...) c_int;
extern "c" fn fprintf(stream: *FILE, fmt: [*:0]const u8, ...) c_int;
extern "c" fn fputs(s: [*:0]const u8, stream: *FILE) c_int;
extern "c" fn puts(s: [*:0]const u8) c_int;
extern "c" fn putchar(c: c_int) c_int;
extern "c" fn fwrite(ptr: *const anyopaque, size: usize, nmemb: usize, stream: *FILE) usize;
extern "c" fn ferror(stream: *FILE) c_int;
extern "c" fn fflush(stream: ?*FILE) c_int;
extern "c" fn strerror(errnum: c_int) [*:0]const u8;
extern "c" fn strtoull(nptr: [*:0]const u8, endptr: ?*[*:0]u8, base: c_int) c_ulonglong;
extern "c" fn __errno_location() *c_int;

const Option = extern struct {
    name: ?[*:0]const u8,
    has_arg: c_int,
    flag: ?*c_int,
    val: c_int,
};

extern "c" var optarg: ?[*:0]const u8;
extern "c" var optind: c_int;
extern "c" fn getopt_long(
    argc: c_int,
    argv: [*]?[*:0]u8,
    optstring: [*:0]const u8,
    longopts: [*]const Option,
    longindex: ?*c_int,
) c_int;

fn usage(prog: [*:0]const u8) void {
    _ = fprintf(
        stderr,
        "%s [-d <device>] [-i|-s|-t|-r <bytes> [-x]]\n" ++
            "  -i, --info            the module and an instance of it (default)\n" ++
            "  -s, --status          the JSON status document of an instance\n" ++
            "  -r, --random <bytes>  write random bytes to stdout\n" ++
            "  -x, --hex             as hexadecimal digits\n" ++
            "  -t, --selftest        run the cryptographic self test\n" ++
            "  -d, --device <device> instead of " ++ JENT_KERNEL_DEVICE ++ "\n",
        prog,
    );
}

// One line of /proc/jitterentropy/@name, or why there is none.
fn info_proc(label: [*:0]const u8, name: [*:0]const u8) void {
    var buf: [128]u8 = undefined;
    const ret = jent_kernel_proc(name, &buf, buf.len);

    if (ret != 0) {
        _ = printf("  %-19s unavailable (%s)\n", label, strerror(-ret));
        return;
    }
    const str = std.mem.sliceTo(&buf, 0);
    if (std.mem.indexOfScalar(u8, str, '\n')) |nl| {
        buf[nl] = 0;
    }
    _ = printf("  %-19s %s\n", label, @as([*:0]const u8, @ptrCast(&buf)));
}

fn info_u32(label: [*:0]const u8, fmt: [*:0]const u8, ret: c_int, val: c_uint) void {
    _ = printf("  %-19s ", label);
    if (ret != 0) {
        _ = printf("unavailable (%s)", strerror(-ret));
    } else {
        _ = printf(fmt, val);
    }
    _ = putchar('\n');
}

fn info(device: ?[*:0]const u8) c_int {
    const interfaces = [_][:0]const u8{
        "kcapi",
        "hwrng",
        "chardev",
        "testing",
    };
    var buf: [JENT_KERNEL_UUID_STRLEN]u8 = undefined;
    var reads: u64 = 0;
    var bytes: u64 = 0;
    var val: c_uint = 0;
    var memsize: usize = 0;

    _ = printf("Module\n");
    info_proc("version:", "version");
    info_proc("oversampling rate:", "config/osr");
    info_proc("flags:", "config/flags_raw");
    info_proc("NTG.1 mode:", "config/ntg1");
    info_proc("FIPS mode:", "config/fips");
    _ = printf("  %-19s", @as([*:0]const u8, "interfaces:"));
    for (interfaces) |iface| {
        var name_buf: [32]u8 = undefined;
        var on: [8]u8 = undefined;
        const slice = std.fmt.bufPrint(name_buf[0 .. name_buf.len - 1], "interfaces/{s}", .{iface}) catch continue;
        name_buf[slice.len] = 0;
        if (jent_kernel_proc(@ptrCast(&name_buf), &on, on.len) == 0 and on[0] == '1') {
            _ = printf(" %s", iface.ptr);
        }
    }
    _ = putchar('\n');

    const fd = jent_kernel_open(device);
    if (fd < 0) {
        _ = fprintf(
            stderr,
            "Cannot open %s: %s\n",
            device orelse JENT_KERNEL_DEVICE.ptr,
            strerror(-fd),
        );
        return 1;
    }

    _ = printf("Instance\n");
    var ret = jent_kernel_uuid(fd, &buf, buf.len);
    _ = printf(
        "  %-19s %s\n",
        @as([*:0]const u8, "uuid:"),
        if (ret != 0) strerror(-ret) else @as([*:0]const u8, @ptrCast(&buf)),
    );
    ret = jent_kernel_version(fd, &val);
    _ = printf("  %-19s ", @as([*:0]const u8, "version:"));
    if (ret != 0) {
        _ = printf("unavailable (%s)\n", strerror(-ret));
    } else {
        _ = printf("%u.%u.%u\n", val / 1000000, val / 10000 % 100, val / 100 % 100);
    }
    ret = jent_kernel_osr(fd, &val);
    info_u32("oversampling rate:", "%u", ret, val);
    ret = jent_kernel_flags(fd, &val);
    info_u32("flags:", "0x%08x", ret, val);
    ret = jent_kernel_memsize(fd, &memsize);
    _ = printf("  %-19s ", @as([*:0]const u8, "memory size:"));
    if (ret != 0) {
        _ = printf("unavailable (%s)\n", strerror(-ret));
    } else {
        _ = printf("%zu bytes\n", memsize);
    }
    ret = jent_kernel_hashloops(fd, &val);
    info_u32("hash loops:", "%u", ret, val);
    ret = jent_kernel_health_failure(fd, &val);
    info_u32("health failure:", "0x%x", ret, val);
    ret = jent_kernel_reinitializations(fd, &val);
    info_u32("reinitializations:", "%u", ret, val);
    ret = jent_kernel_output(fd, &reads, &bytes);
    _ = printf("  %-19s ", @as([*:0]const u8, "output:"));
    if (ret != 0) {
        _ = printf("unavailable (%s)\n", strerror(-ret));
    } else {
        _ = printf("%llu reads, %llu bytes\n", @as(c_ulonglong, reads), @as(c_ulonglong, bytes));
    }

    _ = jent_kernel_close(fd);
    return 0;
}

fn status(fd: c_int) c_int {
    var buf: [JENT_KERNEL_STATUS_LEN]u8 = undefined;
    const ret = jent_kernel_status(fd, &buf, buf.len);

    if (ret != 0) {
        _ = fprintf(stderr, "Cannot obtain the status: %s\n", strerror(-ret));
        return 1;
    }
    _ = fputs(@ptrCast(&buf), stdout);
    return 0;
}

fn selftest(fd: c_int) c_int {
    const ret = jent_kernel_selftest(fd);

    if (ret != 0) {
        _ = fprintf(stderr, "Cryptographic self test: %s\n", strerror(-ret));
        return 1;
    }
    _ = puts("cryptographic self test passed");
    return 0;
}

fn random_bytes(fd: c_int, initial_len: c_ulonglong, hex: bool) c_int {
    var len = initial_len;
    var buf: [4096]u8 = undefined;

    while (len != 0) {
        const want: usize = if (len < buf.len) @intCast(len) else buf.len;
        const got = jent_kernel_read(fd, &buf, want);

        if (got <= 0) {
            _ = fprintf(
                stderr,
                "Reading random data failed: %s\n",
                if (got != 0) strerror(@intCast(-got)) else @as([*:0]const u8, "end of file"),
            );
            return 1;
        }
        const got_usize: usize = @intCast(got);
        if (hex) {
            for (buf[0..got_usize]) |b| {
                _ = printf("%02x", @as(c_uint, b));
            }
        } else if (fwrite(&buf, 1, got_usize, stdout) != got_usize) {
            break;
        }
        len -= got_usize;
    }
    if (hex and ferror(stdout) == 0) {
        _ = putchar('\n');
    }

    // A truncated stream must not exit with 0.
    if (ferror(stdout) != 0 or fflush(stdout) != 0) {
        _ = fprintf(stderr, "Cannot write the random data\n");
        return 1;
    }
    return 0;
}

pub export fn main(argc: c_int, argv: [*]?[*:0]u8) callconv(.c) c_int {
    const opts = [_]Option{
        .{ .name = "info", .has_arg = 0, .flag = null, .val = 'i' },
        .{ .name = "status", .has_arg = 0, .flag = null, .val = 's' },
        .{ .name = "random", .has_arg = 1, .flag = null, .val = 'r' },
        .{ .name = "hex", .has_arg = 0, .flag = null, .val = 'x' },
        .{ .name = "selftest", .has_arg = 0, .flag = null, .val = 't' },
        .{ .name = "device", .has_arg = 1, .flag = null, .val = 'd' },
        .{ .name = "help", .has_arg = 0, .flag = null, .val = 'h' },
        .{ .name = null, .has_arg = 0, .flag = null, .val = 0 },
    };
    var device: ?[*:0]const u8 = null;
    var len: c_ulonglong = 0;
    var mode: c_int = 'i';
    var hex: bool = false;
    const prog: [*:0]const u8 = argv[0] orelse "jitter_rng";

    while (true) {
        const c = getopt_long(argc, argv, "isr:xtd:h", &opts, null);
        if (c == -1)
            break;

        switch (c) {
            'i', 's', 't' => {
                mode = c;
            },
            'r' => {
                mode = c;
                const arg = optarg orelse {
                    usage(prog);
                    return 1;
                };
                var end: [*:0]u8 = undefined;
                __errno_location().* = 0;
                len = strtoull(arg, &end, 10);
                if (__errno_location().* != 0 or @intFromPtr(end) == @intFromPtr(arg) or end[0] != 0 or arg[0] == '-') {
                    _ = fprintf(stderr, "Invalid byte count %s\n", arg);
                    return 1;
                }
            },
            'x' => {
                hex = true;
            },
            'd' => {
                device = optarg;
            },
            'h' => {
                usage(prog);
                return 0;
            },
            else => {
                usage(prog);
                return 1;
            },
        }
    }
    if (optind < argc) {
        usage(prog);
        return 1;
    }

    if (mode == 'i')
        return info(device);

    const fd = jent_kernel_open(device);
    if (fd < 0) {
        _ = fprintf(
            stderr,
            "Cannot open %s: %s\n",
            device orelse JENT_KERNEL_DEVICE.ptr,
            strerror(-fd),
        );
        return 1;
    }

    const ret = if (mode == 's')
        status(fd)
    else if (mode == 't')
        selftest(fd)
    else
        random_bytes(fd, len, hex);

    _ = jent_kernel_close(fd);
    return ret;
}
