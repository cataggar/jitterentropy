// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause
//
// Test tool for the single-field ioctls of the Jitter RNG kernel interfaces.
//
// Copyright (C) 2026, Stephan Mueller <smueller@chronox.de>
// Copyright (C) 2026, Markus Theil <theil.markus@gmail.com>
//
// Calls all seven single-field ioctls and checks each answer against the same
// field of the JENT_IOCSTATUS document. They are two spellings of one state,
// so a disagreement is the defect this looks for.
//
// Serves both interfaces: an empty "uuid" in the document is what selects the
// -ENODATA expectation for JENT_IOCUUID on a raw test instance.
//
// Usage: jitterentropy-chardev-fields [<device file>]

const std = @import("std");
const builtin = @import("builtin");
const linux = std.os.linux;

fn trapPanic(_: []const u8, _: ?usize) noreturn {
    @trap();
}
pub const panic = std.debug.FullPanic(trapPanic);

const JENT_STATUS_MAX_LEN: u32 = 4096;
const JENT_UUID_IOCTL_LEN: usize = 37;
const JENT_IOC_MAGIC: u8 = 'J';

const JENT_DISABLE_MEMORY_ACCESS: u32 = 1 << 2;
const JENT_FORCE_INTERNAL_TIMER: u32 = 1 << 3;
const JENT_DISABLE_INTERNAL_TIMER: u32 = 1 << 4;
const JENT_FORCE_FIPS: u32 = 1 << 5;
const JENT_NTG1: u32 = 1 << 6;
const JENT_CACHE_ALL: u32 = 1 << 7;
const JENT_FORCE_SECURE_MEM: u32 = 1 << 8;

const JENT_RCT_FAILURE: u32 = 1;
const JENT_APT_FAILURE: u32 = 2;
const JENT_LAG_FAILURE: u32 = 4;
const JENT_RCT_MEM_FAILURE: u32 = 8;
const JENT_PERMANENT_FAILURE_SHIFT: u5 = 16;

fn jentPermanentFailure(x: u32) u32 {
    return x << JENT_PERMANENT_FAILURE_SHIFT;
}

const jent_status_ioctl = extern struct {
    buf: u64 align(8) = 0,
    length: u32 = 0,
};

const jent_uuid_ioctl = extern struct {
    uuid: [JENT_UUID_IOCTL_LEN]u8 = @splat(0),
};

const jent_output_ioctl = extern struct {
    invocations: u64 = 0,
    bytes: u64 = 0,
};

const JENT_IOCSTATUS: u32 = linux.IOCTL.IOWR(JENT_IOC_MAGIC, 0x01, jent_status_ioctl);
const JENT_IOCUUID: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x03, jent_uuid_ioctl);
const JENT_IOCVERSION: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x04, u32);
const JENT_IOCOSR: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x05, u32);
const JENT_IOCFLAGS: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x06, u32);
const JENT_IOCHEALTH: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x07, u32);
const JENT_IOCOUTPUT: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x08, jent_output_ioctl);
const JENT_IOCREINIT: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x09, u32);
const JENT_IOCMEMSIZE: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x0a, u64);
const JENT_IOCHASHLOOPS: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x0b, u32);
const JENT_IOCSELFTEST: u32 = linux.IOCTL.IO(JENT_IOC_MAGIC, 0x0c);
const JENT_IOC_UNIMPLEMENTED: u32 = linux.IOCTL.IOR(JENT_IOC_MAGIC, 0x7f, u32);

const IoctlRequest = if (builtin.abi.isGnu()) c_ulong else c_int;

const FILE = opaque {};
extern "c" var stderr: *FILE;
extern "c" fn open(path: [*:0]const u8, oflag: c_int, ...) c_int;
extern "c" fn close(fd: c_int) c_int;
extern "c" fn ioctl(fd: c_int, request: IoctlRequest, ...) c_int;
extern "c" fn calloc(nmemb: usize, size: usize) ?[*]u8;
extern "c" fn free(ptr: ?*anyopaque) void;
extern "c" fn perror(s: [*:0]const u8) void;
extern "c" fn printf(fmt: [*:0]const u8, ...) c_int;
extern "c" fn fprintf(stream: *FILE, fmt: [*:0]const u8, ...) c_int;
extern "c" fn puts(s: [*:0]const u8) c_int;
extern "c" fn strerror(errnum: c_int) [*:0]const u8;
extern "c" fn strtoull(nptr: [*:0]const u8, endptr: ?*[*:0]u8, base: c_int) c_ulonglong;
extern "c" fn sscanf(str: [*:0]const u8, format: [*:0]const u8, ...) c_int;
extern "c" fn geteuid() c_uint;
extern "c" fn __errno_location() *c_int;

var failures: c_int = 0;

fn callIoctl(fd: c_int, request: u32, arg: ?*anyopaque) c_int {
    const req: IoctlRequest = if (builtin.abi.isGnu())
        @as(c_ulong, request)
    else
        @as(c_int, @bitCast(request));
    return ioctl(fd, req, arg);
}

fn callIoctlNoArg(fd: c_int, request: u32) c_int {
    const req: IoctlRequest = if (builtin.abi.isGnu())
        @as(c_ulong, request)
    else
        @as(c_int, @bitCast(request));
    return ioctl(fd, req);
}

fn failMsg(comptime fmt: []const u8, args: anytype) void {
    var buf: [512]u8 = undefined;
    if (std.fmt.bufPrint(buf[0 .. buf.len - 1], fmt, args)) |slice| {
        buf[slice.len] = 0;
        _ = fprintf(stderr, "FAIL: %s\n", @as([*:0]const u8, @ptrCast(&buf)));
    } else |_| {
        _ = fprintf(stderr, "FAIL: formatting failure\n");
    }
    failures += 1;
}

// The text after "<key>": within hay, or null.
fn find_value(hay: []const u8, key: []const u8) ?[]const u8 {
    var pattern_buf: [64]u8 = undefined;
    const pattern = std.fmt.bufPrint(&pattern_buf, "\"{s}\":", .{key}) catch return null;
    const idx = std.mem.indexOf(u8, hay, pattern) orelse return null;
    var p = hay[idx + pattern.len ..];
    while (p.len > 0 and (p[0] == ' ' or p[0] == '\t')) {
        p = p[1..];
    }
    return p;
}

// The body of the object "<key>": { ... }, as a slice.
fn find_object(hay: []const u8, key: []const u8) ?[]const u8 {
    const p = find_value(hay, key) orelse return null;
    if (p.len == 0 or p[0] != '{')
        return null;

    var depth: usize = 0;
    for (p, 0..) |ch, i| {
        if (ch == '{') {
            depth += 1;
        } else if (ch == '}') {
            depth -= 1;
            if (depth == 0)
                return p[0..i];
        }
    }
    return null;
}

fn json_u64(hay: []const u8, key: []const u8, out: *u64) bool {
    const p = find_value(hay, key) orelse return false;
    if (p.len == 0 or p[0] < '0' or p[0] > '9')
        return false;
    var end: usize = 0;
    while (end < p.len and p[end] >= '0' and p[end] <= '9') : (end += 1) {}
    out.* = std.fmt.parseInt(u64, p[0..end], 10) catch return false;
    return true;
}

fn json_bool(hay: []const u8, key: []const u8, out: *bool) bool {
    const p = find_value(hay, key) orelse return false;
    if (std.mem.startsWith(u8, p, "true")) {
        out.* = true;
        return true;
    } else if (std.mem.startsWith(u8, p, "false")) {
        out.* = false;
        return true;
    }
    return false;
}

fn json_str(hay: []const u8, key: []const u8, buf: []u8) ?[]const u8 {
    const p = find_value(hay, key) orelse return null;
    if (p.len == 0 or p[0] != '"')
        return null;
    const rest = p[1..];
    const end = std.mem.indexOfScalar(u8, rest, '"') orelse return null;
    if (end >= buf.len)
        return null;
    @memcpy(buf[0..end], rest[0..end]);
    buf[end] = 0;
    return buf[0..end];
}

// One JSON boolean against one bit of a mask the ioctl reported.
fn check_bit(json_region: []const u8, key: []const u8, mask: u32, bit: u32, what: []const u8) void {
    var json_set: bool = false;
    if (!json_bool(json_region, key, &json_set)) {
        failMsg("{s}: no \"{s}\" in the status document", .{ what, key });
        return;
    }
    const mask_set = (mask & bit) != 0;
    if (json_set != mask_set) {
        failMsg(
            "{s}: {s} is {s} in the status document but {s} in the ioctl",
            .{
                what,
                key,
                if (json_set) "true" else "false",
                if (mask_set) "set" else "clear",
            },
        );
    }
}

// Fetch the status document; the caller frees it.
fn get_status(fd: c_int) ?[:0]u8 {
    var status = jent_status_ioctl{ .buf = 0, .length = 0 };

    if (callIoctl(fd, JENT_IOCSTATUS, &status) == 0 or
        __errno_location().* != 75)
    {
        perror("JENT_IOCSTATUS (probe)");
        return null;
    }
    if (status.length == 0 or status.length > JENT_STATUS_MAX_LEN) {
        _ = fprintf(stderr, "implausible required length %u\n", status.length);
        return null;
    }

    const buf = calloc(1, status.length) orelse {
        perror("calloc");
        return null;
    };

    status.buf = @intFromPtr(buf);
    if (callIoctl(fd, JENT_IOCSTATUS, &status) != 0) {
        perror("JENT_IOCSTATUS");
        free(buf);
        return null;
    }
    const len = std.mem.indexOfScalar(u8, buf[0..status.length], 0) orelse (status.length - 1);
    buf[len] = 0;
    return buf[0..len :0];
}

pub export fn main(argc: c_int, argv: [*]const [*:0]const u8) callconv(.c) c_int {
    const devfile: [*:0]const u8 = if (argc > 1) argv[1] else "/dev/jitterentropy";

    const fd = open(devfile, @as(c_int, @bitCast(linux.O{ .ACCMODE = .RDONLY })));
    if (fd < 0) {
        perror(devfile);
        return 1;
    }
    defer _ = close(fd);

    const json_z = get_status(fd) orelse return 1;
    defer free(json_z.ptr);
    const json: []const u8 = json_z;

    var val: u32 = 0;
    var n: u64 = 0;

    // A property of the library; the document spells it out with dots.
    if (callIoctl(fd, JENT_IOCVERSION, &val) != 0) {
        failMsg("JENT_IOCVERSION: {s}", .{std.mem.span(strerror(__errno_location().*))});
    } else {
        var ver_buf: [32]u8 = undefined;
        var maj: c_uint = 0;
        var min: c_uint = 0;
        var patch: c_uint = 0;

        _ = printf("version:          %u\n", val);
        const ver_slice = json_str(json, "version", &ver_buf);
        if (ver_slice == null or sscanf(@ptrCast(&ver_buf), "%u.%u.%u", &maj, &min, &patch) != 3) {
            failMsg("no usable \"version\" in the status document", .{});
        } else if (val != maj * 1000000 + min * 10000 + patch * 100) {
            failMsg("version: ioctl says {d}, status document says {s}", .{ val, ver_slice.? });
        }
    }

    // Present exactly when the instance went through startup.
    var json_uuid_buf: [JENT_UUID_IOCTL_LEN]u8 = undefined;
    const json_uuid_opt = json_str(json, "uuid", &json_uuid_buf);
    const have_uuid = if (json_uuid_opt) |u| u.len > 0 else false;
    var uuid = jent_uuid_ioctl{};
    if (callIoctl(fd, JENT_IOCUUID, &uuid) != 0) {
        const err = __errno_location().*;
        if (have_uuid) {
            failMsg(
                "JENT_IOCUUID: {s}, but the status document has \"{s}\"",
                .{ std.mem.span(strerror(err)), json_uuid_opt.? },
            );
        } else if (err != 61) {
            failMsg(
                "JENT_IOCUUID on an instance with no UUID: expected ENODATA, got {s}",
                .{std.mem.span(strerror(err))},
            );
        } else {
            _ = printf("uuid:             none (ENODATA, as expected for a raw instance)\n");
        }
    } else {
        const ioctl_uuid = std.mem.sliceTo(&uuid.uuid, 0);
        _ = printf("uuid:             %.*s\n", @as(c_int, JENT_UUID_IOCTL_LEN), @as([*]const u8, &uuid.uuid));
        if (!have_uuid) {
            failMsg("JENT_IOCUUID answered but the status document carries no UUID", .{});
        } else if (!std.mem.eql(u8, ioctl_uuid, json_uuid_opt.?)) {
            failMsg(
                "uuid: ioctl says \"{s}\", status document says \"{s}\"",
                .{ ioctl_uuid, json_uuid_opt.? },
            );
        }
    }

    // JENT_IOCOSR against configuration.osr.
    if (callIoctl(fd, JENT_IOCOSR, &val) != 0) {
        failMsg("JENT_IOCOSR: {s}", .{std.mem.span(strerror(__errno_location().*))});
    } else {
        _ = printf("osr:              %u\n", val);
        if (!json_u64(json, "osr", &n)) {
            failMsg("no \"osr\" in the status document", .{});
        } else if (n != val) {
            failMsg("osr: ioctl says {d}, status document says {d}", .{ val, n });
        }
    }

    // JENT_IOCREINIT against reinitializations.
    if (callIoctl(fd, JENT_IOCREINIT, &val) != 0) {
        failMsg("JENT_IOCREINIT: {s}", .{std.mem.span(strerror(__errno_location().*))});
    } else {
        _ = printf("reinitializations: %u\n", val);
        if (!json_u64(json, "reinitializations", &n)) {
            failMsg("no \"reinitializations\" in the status document", .{});
        } else if (n != val) {
            failMsg("reinitializations: ioctl says {d}, status document says {d}", .{ val, n });
        }
    }

    // JENT_IOCMEMSIZE against configuration.memoryBlockSizeBytes.
    var memsize: u64 = 0;
    if (callIoctl(fd, JENT_IOCMEMSIZE, &memsize) != 0) {
        failMsg("JENT_IOCMEMSIZE: {s}", .{std.mem.span(strerror(__errno_location().*))});
    } else {
        _ = printf("memory size:      %llu\n", @as(c_ulonglong, memsize));
        if (!json_u64(json, "memoryBlockSizeBytes", &n)) {
            failMsg("no \"memoryBlockSizeBytes\" in the status document", .{});
        } else if (n != memsize) {
            failMsg("memory size: ioctl says {d}, status document says {d}", .{ memsize, n });
        }
    }

    // JENT_IOCHASHLOOPS against configuration.hashLoopCount.runtime.
    if (callIoctl(fd, JENT_IOCHASHLOOPS, &val) != 0) {
        failMsg("JENT_IOCHASHLOOPS: {s}", .{std.mem.span(strerror(__errno_location().*))});
    } else {
        _ = printf("hash loops:       %u\n", val);
        if (find_object(json, "hashLoopCount")) |obj| {
            if (!json_u64(obj, "runtime", &n) or n != val) {
                failMsg("hash loops: ioctl says {d}", .{val});
            }
        } else {
            failMsg("no \"hashLoopCount\" object in the status document", .{});
        }
    }

    // configuration.flags reports the same value one bit at a time.
    if (callIoctl(fd, JENT_IOCFLAGS, &val) != 0) {
        failMsg("JENT_IOCFLAGS: {s}", .{std.mem.span(strerror(__errno_location().*))});
    } else {
        _ = printf("flags:            0x%08x\n", val);
        if (find_object(json, "flags")) |obj| {
            check_bit(obj, "JENT_DISABLE_MEMORY_ACCESS", val, JENT_DISABLE_MEMORY_ACCESS, "flags");
            check_bit(obj, "JENT_FORCE_INTERNAL_TIMER", val, JENT_FORCE_INTERNAL_TIMER, "flags");
            check_bit(obj, "JENT_DISABLE_INTERNAL_TIMER", val, JENT_DISABLE_INTERNAL_TIMER, "flags");
            check_bit(obj, "JENT_FORCE_FIPS", val, JENT_FORCE_FIPS, "flags");
            check_bit(obj, "JENT_NTG1", val, JENT_NTG1, "flags");
            check_bit(obj, "JENT_CACHE_ALL", val, JENT_CACHE_ALL, "flags");
            check_bit(obj, "JENT_FORCE_SECURE_MEM", val, JENT_FORCE_SECURE_MEM, "flags");
        } else {
            failMsg("no \"flags\" object in the status document", .{});
        }
    }

    // healthFailure's per-test booleans are the same bits.
    if (callIoctl(fd, JENT_IOCHEALTH, &val) != 0) {
        failMsg("JENT_IOCHEALTH: {s}", .{std.mem.span(strerror(__errno_location().*))});
    } else {
        const HealthTest = struct {
            object: []const u8,
            bit: u32,
        };
        const tests = [_]HealthTest{
            .{ .object = "apt", .bit = JENT_APT_FAILURE },
            .{ .object = "rct", .bit = JENT_RCT_FAILURE },
            .{ .object = "rctMemory", .bit = JENT_RCT_MEM_FAILURE },
            .{ .object = "lag", .bit = JENT_LAG_FAILURE },
        };

        _ = printf("healthFailure:    0x%08x\n", val);
        for (tests) |t| {
            if (find_object(json, t.object)) |obj| {
                check_bit(obj, "intermittent", val, t.bit, t.object);
                check_bit(obj, "permanent", val, jentPermanentFailure(t.bit), t.object);
            } else {
                // The lag predictor is compiled out of some builds.
                if (t.bit != JENT_LAG_FAILURE) {
                    failMsg("no \"{s}\" object in the status document", .{t.object});
                }
            }
        }
    }

    // Nothing is read in between, so the two must agree exactly.
    var output = jent_output_ioctl{};
    if (callIoctl(fd, JENT_IOCOUTPUT, &output) != 0) {
        failMsg("JENT_IOCOUTPUT: {s}", .{std.mem.span(strerror(__errno_location().*))});
    } else {
        _ = printf(
            "output:           %llu invocations, %llu bytes\n",
            @as(c_ulonglong, output.invocations),
            @as(c_ulonglong, output.bytes),
        );
        if (find_object(json, "output")) |obj| {
            if (!json_u64(obj, "invocations", &n) or n != output.invocations) {
                failMsg("output.invocations: ioctl says {d}", .{output.invocations});
            }
            if (!json_u64(obj, "bytes", &n) or n != output.bytes) {
                failMsg("output.bytes: ioctl says {d}", .{output.bytes});
            }
        } else {
            failMsg("no \"output\" object in the status document", .{});
        }
    }

    // The self test is module-wide rather than a field of this instance,
    // so the status document has nothing to compare it against. What is
    // checked is the privilege rule: it runs for a caller holding
    // CAP_SYS_ADMIN and is refused to one without it.
    if (geteuid() != 0) {
        if (callIoctlNoArg(fd, JENT_IOCSELFTEST) != -1 or
            __errno_location().* != 1)
        {
            failMsg("JENT_IOCSELFTEST: not refused with EPERM although unprivileged", .{});
        } else {
            _ = puts("selfTest:         refused without CAP_SYS_ADMIN");
        }
    } else if (callIoctlNoArg(fd, JENT_IOCSELFTEST) != 0) {
        failMsg("JENT_IOCSELFTEST: {s}", .{std.mem.span(strerror(__errno_location().*))});
    } else {
        _ = puts("selfTest:         passed");
    }

    // An unimplemented command of the same magic must be rejected.
    if (callIoctl(fd, JENT_IOC_UNIMPLEMENTED, &val) != -1 or
        __errno_location().* != 25)
    {
        failMsg("an unimplemented ioctl was not rejected with ENOTTY", .{});
    }

    if (failures != 0) {
        _ = fprintf(stderr, "%d check(s) failed\n", failures);
        return 1;
    }
    _ = puts("all fields agree with the status document");
    return 0;
}
