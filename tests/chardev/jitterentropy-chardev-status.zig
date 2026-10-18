// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause
//
// Test tool for the /dev/jitterentropy ioctl interface.
//
// Copyright (C) 2026, Stephan Mueller <smueller@chronox.de>
//
// Fetches the JSON status string of the Jitter RNG instance bound to the
// open file description via JENT_IOCSTATUS and prints it to stdout. The
// required buffer size is probed with a zero-length buffer first, which
// exercises the EOVERFLOW path of the ioctl and its length report.
//
// Usage: jitterentropy-chardev-status [<device file>]

const std = @import("std");
const builtin = @import("builtin");
const linux = std.os.linux;

const JENT_STATUS_MAX_LEN: u32 = 4096;
const JENT_IOC_MAGIC: u8 = 'J';

const jent_status_ioctl = extern struct {
    buf: u64 align(8) = 0,
    length: u32 = 0,
};

const JENT_IOCSTATUS: u32 = linux.IOCTL.IOWR(JENT_IOC_MAGIC, 0x01, jent_status_ioctl);

const IoctlRequest = if (builtin.abi.isGnu()) c_ulong else c_int;

const FILE = opaque {};
extern "c" var stderr: *FILE;
extern "c" fn open(path: [*:0]const u8, oflag: c_int, ...) c_int;
extern "c" fn close(fd: c_int) c_int;
extern "c" fn ioctl(fd: c_int, request: IoctlRequest, ...) c_int;
extern "c" fn calloc(nmemb: usize, size: usize) ?[*]u8;
extern "c" fn free(ptr: ?*anyopaque) void;
extern "c" fn perror(s: [*:0]const u8) void;
extern "c" fn fprintf(stream: *FILE, fmt: [*:0]const u8, ...) c_int;
extern "c" fn puts(s: [*:0]const u8) c_int;
extern "c" fn strnlen(s: [*]const u8, maxlen: usize) usize;
extern "c" fn __errno_location() *c_int;

fn callIoctl(fd: c_int, request: u32, arg: ?*anyopaque) c_int {
    const req: IoctlRequest = if (builtin.abi.isGnu())
        @as(c_ulong, request)
    else
        @as(c_int, @bitCast(request));
    return ioctl(fd, req, arg);
}

pub export fn main(argc: c_int, argv: [*]const [*:0]const u8) callconv(.c) c_int {
    const devfile: [*:0]const u8 = if (argc > 1) argv[1] else "/dev/jitterentropy";
    var status = jent_status_ioctl{ .buf = 0, .length = 0 };

    const fd = open(devfile, @as(c_int, @bitCast(linux.O{ .ACCMODE = .RDONLY })));
    if (fd < 0) {
        perror(devfile);
        return 1;
    }
    defer _ = close(fd);

    // A zero-length buffer must fail with EOVERFLOW ...
    if (callIoctl(fd, JENT_IOCSTATUS, &status) == 0) {
        _ = fprintf(stderr, "JENT_IOCSTATUS with zero-length buffer succeeded\n");
        return 1;
    }
    if (__errno_location().* != 75) {
        perror("JENT_IOCSTATUS (probe)");
        return 1;
    }

    // ... and report the required size including the terminating NUL.
    const required = status.length;
    if (required == 0 or required > JENT_STATUS_MAX_LEN) {
        _ = fprintf(stderr, "implausible required length %u\n", required);
        return 1;
    }

    const buf = calloc(1, required) orelse {
        perror("calloc");
        return 1;
    };
    defer free(buf);

    status.buf = @intFromPtr(buf);
    status.length = required;
    if (callIoctl(fd, JENT_IOCSTATUS, &status) != 0) {
        perror("JENT_IOCSTATUS");
        return 1;
    }

    if (status.length != required or strnlen(buf, required) != @as(usize, required) - 1) {
        _ = fprintf(
            stderr,
            "inconsistent status length %u (probed %u)\n",
            status.length,
            required,
        );
        return 1;
    }

    _ = puts(@ptrCast(buf));
    return 0;
}
