// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause
//
// User space access to the jitter_rng kernel module.
//
// Copyright (C) 2026, Stephan Mueller <smueller@chronox.de>
// Copyright (C) 2026, Markus Theil <theil.markus@gmail.com>

const std = @import("std");
const builtin = @import("builtin");
const linux = std.os.linux;

pub const JENT_KERNEL_DEVICE: [:0]const u8 = "/dev/jitterentropy";
pub const JENT_KERNEL_STATUS_LEN: usize = 4096;
pub const JENT_KERNEL_UUID_STRLEN: usize = 37;
pub const JENT_KERNEL_PROC: [:0]const u8 = "/proc/jitterentropy/";

pub const JENT_STATUS_MAX_LEN: usize = 4096;
pub const JENT_UUID_IOCTL_LEN: usize = 37;
pub const JENT_LOOPCNT_MAX: u32 = 1 << 16;
pub const JENT_IOC_MAGIC: u8 = 'J';

comptime {
    std.debug.assert(JENT_KERNEL_UUID_STRLEN == JENT_UUID_IOCTL_LEN);
    std.debug.assert(JENT_KERNEL_STATUS_LEN == JENT_STATUS_MAX_LEN);
}

pub const jent_status_ioctl = extern struct {
    buf: u64 align(8) = 0,
    length: u32 = 0,
};

pub const jent_uuid_ioctl = extern struct {
    uuid: [JENT_UUID_IOCTL_LEN]u8 = @splat(0),
};

pub const jent_output_ioctl = extern struct {
    invocations: u64 = 0,
    bytes: u64 = 0,
};

comptime {
    std.debug.assert(@sizeOf(jent_status_ioctl) == 16);
    std.debug.assert(@sizeOf(jent_uuid_ioctl) == 37);
    std.debug.assert(@sizeOf(jent_output_ioctl) == 16);
}

pub const JENT_IOCSTATUS: u32 = linux.IOCTL.IOWR(JENT_IOC_MAGIC, 0x01, jent_status_ioctl);
pub const JENT_IOCLOOPCNT: u32 = linux.IOCTL.IOW(JENT_IOC_MAGIC, 0x02, u64);
pub const JENT_IOCUUID: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x03, jent_uuid_ioctl);
pub const JENT_IOCVERSION: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x04, u32);
pub const JENT_IOCOSR: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x05, u32);
pub const JENT_IOCFLAGS: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x06, u32);
pub const JENT_IOCHEALTH: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x07, u32);
pub const JENT_IOCOUTPUT: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x08, jent_output_ioctl);
pub const JENT_IOCREINIT: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x09, u32);
pub const JENT_IOCMEMSIZE: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x0a, u64);
pub const JENT_IOCHASHLOOPS: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x0b, u32);
pub const JENT_IOCSELFTEST: u32 = linux.IOCTL.IO(JENT_IOC_MAGIC, 0x0c);

const IoctlRequest = if (builtin.abi.isGnu()) c_ulong else c_int;

extern "c" fn open(path: [*:0]const u8, oflag: c_int, ...) c_int;
extern "c" fn close(fd: c_int) c_int;
extern "c" fn read(fd: c_int, buf: [*]u8, nbytes: usize) isize;
extern "c" fn ioctl(fd: c_int, request: IoctlRequest, ...) c_int;
extern "c" fn __errno_location() *c_int;

inline fn getErrno() c_int {
    return __errno_location().*;
}

fn jent_kernel_ioctl(fd: c_int, request: u32, arg: ?*anyopaque) c_int {
    const req: IoctlRequest = if (builtin.abi.isGnu())
        @as(c_ulong, request)
    else
        @as(c_int, @bitCast(request));
    return if (ioctl(fd, req, arg) != 0) -getErrno() else 0;
}

fn openFlagsReadOnlyCloexec() c_int {
    return @as(c_int, @bitCast(linux.O{ .ACCMODE = .RDONLY, .CLOEXEC = true }));
}

pub export fn jent_kernel_open(path: ?[*:0]const u8) callconv(.c) c_int {
    const p: [*:0]const u8 = path orelse JENT_KERNEL_DEVICE.ptr;
    const fd = open(p, openFlagsReadOnlyCloexec());
    return if (fd < 0) -getErrno() else fd;
}

pub export fn jent_kernel_close(fd: c_int) callconv(.c) c_int {
    return if (close(fd) != 0) -getErrno() else 0;
}

pub export fn jent_kernel_read(fd: c_int, buf: ?*anyopaque, len: usize) callconv(.c) isize {
    if ((buf == null and len != 0) or len > @as(usize, @intCast(std.math.maxInt(isize))))
        return -@as(isize, @intFromEnum(linux.E.INVAL));

    var done: usize = 0;
    const base: [*]u8 = if (buf) |b| @ptrCast(b) else undefined;
    while (done < len) {
        const r = read(fd, base + done, len - done);
        if (r < 0) {
            const err = getErrno();
            if (err == @intFromEnum(linux.E.INTR))
                continue;
            // What was read is delivered; the error comes next.
            return if (done != 0) @intCast(done) else -@as(isize, err);
        }
        if (r == 0)
            break;
        done += @intCast(r);
    }

    return @intCast(done);
}

pub export fn jent_kernel_status(fd: c_int, buf: ?[*]u8, buflen: usize) callconv(.c) c_int {
    const b = buf orelse return -@as(c_int, @intFromEnum(linux.E.INVAL));
    if (buflen == 0 or buflen > std.math.maxInt(u32))
        return -@as(c_int, @intFromEnum(linux.E.INVAL));

    var arg: jent_status_ioctl = undefined;
    @memset(std.mem.asBytes(&arg), 0);
    arg.buf = @intFromPtr(b);
    arg.length = @intCast(buflen);
    return jent_kernel_ioctl(fd, JENT_IOCSTATUS, &arg);
}

pub export fn jent_kernel_uuid(fd: c_int, buf: ?[*]u8, buflen: usize) callconv(.c) c_int {
    const b = buf orelse return -@as(c_int, @intFromEnum(linux.E.INVAL));
    if (buflen < JENT_KERNEL_UUID_STRLEN)
        return -@as(c_int, @intFromEnum(linux.E.INVAL));

    var arg: jent_uuid_ioctl = undefined;
    @memset(std.mem.asBytes(&arg), 0);
    const ret = jent_kernel_ioctl(fd, JENT_IOCUUID, &arg);
    if (ret != 0)
        return ret;

    // Terminated here as well: the string is the kernel's.
    arg.uuid[arg.uuid.len - 1] = 0;
    @memcpy(b[0..arg.uuid.len], &arg.uuid);
    return 0;
}

// The ioctls that answer with one __u32.
fn jent_kernel_u32(fd: c_int, request: u32, val: ?*c_uint) c_int {
    const out = val orelse return -@as(c_int, @intFromEnum(linux.E.INVAL));
    var v: u32 = 0;
    const ret = jent_kernel_ioctl(fd, request, &v);
    if (ret != 0)
        return ret;

    out.* = v;
    return 0;
}

pub export fn jent_kernel_version(fd: c_int, version: ?*c_uint) callconv(.c) c_int {
    return jent_kernel_u32(fd, JENT_IOCVERSION, version);
}

pub export fn jent_kernel_osr(fd: c_int, osr: ?*c_uint) callconv(.c) c_int {
    return jent_kernel_u32(fd, JENT_IOCOSR, osr);
}

pub export fn jent_kernel_flags(fd: c_int, flags: ?*c_uint) callconv(.c) c_int {
    return jent_kernel_u32(fd, JENT_IOCFLAGS, flags);
}

pub export fn jent_kernel_health_failure(fd: c_int, health_failure: ?*c_uint) callconv(.c) c_int {
    return jent_kernel_u32(fd, JENT_IOCHEALTH, health_failure);
}

pub export fn jent_kernel_reinitializations(fd: c_int, reinitializations: ?*c_uint) callconv(.c) c_int {
    return jent_kernel_u32(fd, JENT_IOCREINIT, reinitializations);
}

pub export fn jent_kernel_hashloops(fd: c_int, hashloops: ?*c_uint) callconv(.c) c_int {
    return jent_kernel_u32(fd, JENT_IOCHASHLOOPS, hashloops);
}

pub export fn jent_kernel_memsize(fd: c_int, memsize: ?*usize) callconv(.c) c_int {
    const out = memsize orelse return -@as(c_int, @intFromEnum(linux.E.INVAL));
    var v: u64 = 0;
    const ret = jent_kernel_ioctl(fd, JENT_IOCMEMSIZE, &v);
    if (ret != 0)
        return ret;
    if (v > std.math.maxInt(usize))
        return -@as(c_int, @intFromEnum(linux.E.OVERFLOW));

    out.* = @intCast(v);
    return 0;
}

pub export fn jent_kernel_output(
    fd: c_int,
    read_invocations: ?*u64,
    bytes_output: ?*u64,
) callconv(.c) c_int {
    var arg: jent_output_ioctl = undefined;
    @memset(std.mem.asBytes(&arg), 0);
    const ret = jent_kernel_ioctl(fd, JENT_IOCOUTPUT, &arg);
    if (ret != 0)
        return ret;

    if (read_invocations) |ri|
        ri.* = arg.invocations;
    if (bytes_output) |bo|
        bo.* = arg.bytes;
    return 0;
}

pub export fn jent_kernel_selftest(fd: c_int) callconv(.c) c_int {
    return jent_kernel_ioctl(fd, JENT_IOCSELFTEST, null);
}

// The whole of the file @path into @buf, NUL terminated. The path is a
// parameter so that what this has to handle - a file filling the buffer, one
// larger than it, none at all - can be produced from a file the caller made.
pub fn jent_kernel_file(path: [*:0]const u8, buf: [*]u8, buflen: usize) c_int {
    var done: usize = 0;
    var ret: c_int = 0;

    const fd = open(path, openFlagsReadOnlyCloexec());
    if (fd < 0)
        return -getErrno();

    // One byte is kept for the NUL.
    while (done < buflen - 1) {
        const r = read(fd, buf + done, buflen - 1 - done);
        if (r < 0) {
            const err = getErrno();
            if (err == @intFromEnum(linux.E.INTR))
                continue;
            ret = -err;
            break;
        }
        if (r == 0)
            break;
        done += @intCast(r);
    }

    // Full: complete only if the file ends here.
    if (ret == 0 and done == buflen - 1) {
        var more: [1]u8 = undefined;
        var r: isize = undefined;
        while (true) {
            r = read(fd, &more, 1);
            if (!(r < 0 and getErrno() == @intFromEnum(linux.E.INTR)))
                break;
        }
        if (r < 0) {
            ret = -getErrno();
        } else if (r > 0) {
            ret = -@as(c_int, @intFromEnum(linux.E.OVERFLOW));
        }
    }
    _ = close(fd);

    buf[if (ret != 0) 0 else done] = 0;
    return ret;
}

pub export fn jent_kernel_proc(name: ?[*:0]const u8, buf: ?[*]u8, buflen: usize) callconv(.c) c_int {
    const n = name orelse return -@as(c_int, @intFromEnum(linux.E.INVAL));
    const b = buf orelse return -@as(c_int, @intFromEnum(linux.E.INVAL));
    if (buflen == 0)
        return -@as(c_int, @intFromEnum(linux.E.INVAL));

    const name_slice = std.mem.span(n);
    // A name below the directory: nothing leading out of it.
    if (name_slice.len == 0 or name_slice[0] == '/' or std.mem.indexOf(u8, name_slice, "..") != null)
        return -@as(c_int, @intFromEnum(linux.E.INVAL));

    var path: [JENT_KERNEL_PROC.len + 1 + 64]u8 = undefined;
    if (JENT_KERNEL_PROC.len + name_slice.len >= path.len)
        return -@as(c_int, @intFromEnum(linux.E.NAMETOOLONG));

    @memcpy(path[0..JENT_KERNEL_PROC.len], JENT_KERNEL_PROC);
    @memcpy(path[JENT_KERNEL_PROC.len .. JENT_KERNEL_PROC.len + name_slice.len], name_slice);
    path[JENT_KERNEL_PROC.len + name_slice.len] = 0;

    return jent_kernel_file(@ptrCast(&path), b, buflen);
}
