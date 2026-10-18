// Jitter RNG: unit tests for libjitterentropy-kernel
//
// Copyright (C) 2026, Stephan Mueller <smueller@chronox.de>
// Copyright (C) 2026, Markus Theil <theil.markus@gmail.com>
//
// License: see LICENSE file in root directory

// The user space library of the kernel module, without the module: what it
// does with its arguments, with a file that ends, and with a descriptor that
// is no Jitter RNG device. The module itself answers in the VM tests, through
// the jitter_rng tool.

const std = @import("std");
const linux = std.os.linux;
const kern = @import("jitterentropy_kernel");

const EBADF: c_int = 9;
const EINVAL: c_int = 22;
const ENAMETOOLONG: c_int = 36;
const ENOENT: c_int = 2;
const ENOTTY: c_int = 25;
const EOVERFLOW: c_int = 75;

const FILE = opaque {};
extern "c" var stdout: *FILE;
extern "c" fn printf(fmt: [*:0]const u8, ...) c_int;
extern "c" fn fflush(stream: ?*FILE) c_int;
extern "c" fn mkstemp(template: [*:0]u8) c_int;
extern "c" fn write(fd: c_int, buf: [*]const u8, n: usize) isize;
extern "c" fn close(fd: c_int) c_int;
extern "c" fn remove(pathname: [*:0]const u8) c_int;
extern "c" fn strcmp(s1: [*:0]const u8, s2: [*:0]const u8) c_int;
extern "c" fn getenv(name: [*:0]const u8) ?[*:0]const u8;

var jent_ut_checks: c_uint = 0;
var jent_ut_failures: c_uint = 0;
var jent_ut_skipped: c_uint = 0;

fn jent_ut_group(name: [*:0]const u8) void {
    _ = printf("%s\n", name);
    _ = fflush(stdout);
}

fn utTrue(cond: bool, what: [*:0]const u8, expr: [*:0]const u8, src: std.builtin.SourceLocation) void {
    jent_ut_checks += 1;
    if (!cond) {
        jent_ut_failures += 1;
        _ = printf("  FAILED %s:%d: %s (%s)\n", src.fn_name.ptr, @as(c_int, @intCast(src.line)), what, expr);
    }
}

fn utEq(got: anytype, want: anytype, what: [*:0]const u8, got_expr: [*:0]const u8, src: std.builtin.SourceLocation) void {
    const g: c_longlong = @intCast(got);
    const w: c_longlong = @intCast(want);
    jent_ut_checks += 1;
    if (g != w) {
        jent_ut_failures += 1;
        _ = printf(
            "  FAILED %s:%d: %s: %s is %lld, expected %lld\n",
            src.fn_name.ptr,
            @as(c_int, @intCast(src.line)),
            what,
            got_expr,
            g,
            w,
        );
    }
}

fn utMemEq(got: []const u8, want: []const u8, what: [*:0]const u8, got_expr: [*:0]const u8, src: std.builtin.SourceLocation) void {
    jent_ut_checks += 1;
    if (!std.mem.eql(u8, got, want)) {
        jent_ut_failures += 1;
        _ = printf(
            "  FAILED %s:%d: %s: %s does not match the expected %zu bytes\n",
            src.fn_name.ptr,
            @as(c_int, @intCast(src.line)),
            what,
            got_expr,
            want.len,
        );
    }
}

fn utSkip(what: [*:0]const u8, why: [*:0]const u8) void {
    jent_ut_skipped += 1;
    _ = printf("  skipped %s: %s\n", what, why);
}

fn jent_ut_report(suite: [*:0]const u8) u8 {
    _ = printf(
        "%s: %u checks, %u failed, %u skipped\n",
        suite,
        jent_ut_checks,
        jent_ut_failures,
        jent_ut_skipped,
    );

    if (jent_ut_failures != 0)
        return 1;
    return 0;
}

// A temporary file holding @data; the path in @path.
fn ut_file(path: *[512]u8, data: ?[]const u8) c_int {
    const tmpdir_z = getenv("TMPDIR");
    const tmpdir = if (tmpdir_z) |t| std.mem.span(t) else ".";
    const dir = if (tmpdir.len > 0) tmpdir else ".";
    const slice = std.fmt.bufPrint(path[0 .. path.len - 1], "{s}/jent-kernel-XXXXXX", .{dir}) catch return -1;
    path[slice.len] = 0;

    const fd = mkstemp(@ptrCast(path));
    if (fd < 0)
        return -1;
    if (data) |d| {
        if (d.len > 0 and write(fd, d.ptr, d.len) != @as(isize, @intCast(d.len))) {
            _ = close(fd);
            _ = remove(@ptrCast(path));
            return -1;
        }
    }
    _ = close(fd);
    return 0;
}

fn test_open_read() void {
    var path: [512]u8 = undefined;
    var data: [100]u8 = undefined;
    var buf: [100]u8 = undefined;

    jent_ut_group("opening and reading");

    utEq(
        kern.jent_kernel_open("/nonexistent/jent/device"),
        -ENOENT,
        "a device that is not there is reported",
        "jent_kernel_open(\"/nonexistent/jent/device\")",
        @src(),
    );

    for (&data, 0..) |*b, i| {
        b.* = @intCast(i);
    }
    if (ut_file(&path, &data) != 0) {
        utSkip("reading", "no temporary file");
        return;
    }

    const fd = kern.jent_kernel_open(@ptrCast(&path));
    utTrue(fd >= 0, "a file opens", "fd >= 0", @src());

    utEq(
        kern.jent_kernel_read(fd, &buf, 40),
        40,
        "a read delivers what was asked for",
        "jent_kernel_read(fd, buf, 40)",
        @src(),
    );
    utMemEq(buf[0..40], data[0..40], "and it is the data", "buf", @src());
    utEq(
        kern.jent_kernel_read(fd, &buf, buf.len),
        60,
        "a read across the end is short",
        "jent_kernel_read(fd, buf, sizeof(buf))",
        @src(),
    );
    utMemEq(buf[0..60], data[40..100], "and carries what was left", "buf", @src());
    utEq(
        kern.jent_kernel_read(fd, &buf, 10),
        0,
        "a read at the end delivers nothing",
        "jent_kernel_read(fd, buf, 10)",
        @src(),
    );

    utEq(
        kern.jent_kernel_read(fd, null, 10),
        -EINVAL,
        "no buffer for a length is refused",
        "jent_kernel_read(fd, NULL, 10)",
        @src(),
    );
    utEq(
        kern.jent_kernel_read(fd, null, 0),
        0,
        "no buffer for no length is nothing to do",
        "jent_kernel_read(fd, NULL, 0)",
        @src(),
    );
    utEq(
        kern.jent_kernel_read(-1, &buf, 10),
        -EBADF,
        "an error before the first byte is returned",
        "jent_kernel_read(-1, buf, 10)",
        @src(),
    );

    utEq(
        kern.jent_kernel_close(fd),
        0,
        "the descriptor closes",
        "jent_kernel_close(fd)",
        @src(),
    );
    utEq(
        kern.jent_kernel_close(fd),
        -EBADF,
        "and only once",
        "jent_kernel_close(fd)",
        @src(),
    );

    _ = remove(@ptrCast(&path));
}

// A regular file is no Jitter RNG device: every ioctl says so.
fn test_ioctls() void {
    var path: [512]u8 = undefined;
    var buf: [kern.JENT_KERNEL_STATUS_LEN]u8 = undefined;
    var a: u64 = 0;
    var b: u64 = 0;
    var val: c_uint = 0;
    var size: usize = 0;

    jent_ut_group("the ioctls");

    if (ut_file(&path, "x") != 0) {
        utSkip("the ioctls", "no temporary file");
        return;
    }
    const fd = kern.jent_kernel_open(@ptrCast(&path));
    utTrue(fd >= 0, "a file opens", "fd >= 0", @src());

    utEq(
        kern.jent_kernel_status(fd, &buf, buf.len),
        -ENOTTY,
        "the status of a file that is no device",
        "jent_kernel_status(fd, buf, sizeof(buf))",
        @src(),
    );
    utEq(
        kern.jent_kernel_uuid(fd, &buf, buf.len),
        -ENOTTY,
        "its identifier",
        "jent_kernel_uuid(fd, buf, sizeof(buf))",
        @src(),
    );
    utEq(
        kern.jent_kernel_version(fd, &val),
        -ENOTTY,
        "its version",
        "jent_kernel_version(fd, &val)",
        @src(),
    );
    utEq(
        kern.jent_kernel_osr(fd, &val),
        -ENOTTY,
        "its oversampling rate",
        "jent_kernel_osr(fd, &val)",
        @src(),
    );
    utEq(
        kern.jent_kernel_flags(fd, &val),
        -ENOTTY,
        "its flags",
        "jent_kernel_flags(fd, &val)",
        @src(),
    );
    utEq(
        kern.jent_kernel_health_failure(fd, &val),
        -ENOTTY,
        "its health failures",
        "jent_kernel_health_failure(fd, &val)",
        @src(),
    );
    utEq(
        kern.jent_kernel_reinitializations(fd, &val),
        -ENOTTY,
        "its reinitializations",
        "jent_kernel_reinitializations(fd, &val)",
        @src(),
    );
    utEq(
        kern.jent_kernel_memsize(fd, &size),
        -ENOTTY,
        "its memory size",
        "jent_kernel_memsize(fd, &size)",
        @src(),
    );
    utEq(
        kern.jent_kernel_hashloops(fd, &val),
        -ENOTTY,
        "its hash loop count",
        "jent_kernel_hashloops(fd, &val)",
        @src(),
    );
    utEq(
        kern.jent_kernel_output(fd, &a, &b),
        -ENOTTY,
        "its output",
        "jent_kernel_output(fd, &a, &b)",
        @src(),
    );
    utEq(
        kern.jent_kernel_selftest(fd),
        -ENOTTY,
        "its self test",
        "jent_kernel_selftest(fd)",
        @src(),
    );

    utEq(
        kern.jent_kernel_status(fd, null, buf.len),
        -EINVAL,
        "a status without a buffer is refused",
        "jent_kernel_status(fd, NULL, sizeof(buf))",
        @src(),
    );
    utEq(
        kern.jent_kernel_status(fd, &buf, 0),
        -EINVAL,
        "and one without a length",
        "jent_kernel_status(fd, buf, 0)",
        @src(),
    );
    utEq(
        kern.jent_kernel_uuid(fd, &buf, kern.JENT_KERNEL_UUID_STRLEN - 1),
        -EINVAL,
        "a buffer too small for a UUID is refused",
        "jent_kernel_uuid(fd, buf, JENT_KERNEL_UUID_STRLEN - 1)",
        @src(),
    );
    utEq(
        kern.jent_kernel_uuid(fd, null, buf.len),
        -EINVAL,
        "and none at all",
        "jent_kernel_uuid(fd, NULL, sizeof(buf))",
        @src(),
    );
    utEq(
        kern.jent_kernel_version(fd, null),
        -EINVAL,
        "a value with nowhere to go is refused",
        "jent_kernel_version(fd, NULL)",
        @src(),
    );
    utEq(
        kern.jent_kernel_memsize(fd, null),
        -EINVAL,
        "whatever its width",
        "jent_kernel_memsize(fd, NULL)",
        @src(),
    );

    _ = kern.jent_kernel_close(fd);
    _ = remove(@ptrCast(&path));
}

fn test_proc() void {
    const version: [:0]const u8 = "4.0.0\n";
    var path: [512]u8 = undefined;
    var buf: [64]u8 = undefined;
    var name: [128]u8 = undefined;

    jent_ut_group("the files in /proc/jitterentropy");

    utEq(
        kern.jent_kernel_proc(null, &buf, buf.len),
        -EINVAL,
        "no name is refused",
        "jent_kernel_proc(NULL, buf, sizeof(buf))",
        @src(),
    );
    utEq(
        kern.jent_kernel_proc("", &buf, buf.len),
        -EINVAL,
        "an empty one",
        "jent_kernel_proc(\"\", buf, sizeof(buf))",
        @src(),
    );
    utEq(
        kern.jent_kernel_proc("/etc/passwd", &buf, buf.len),
        -EINVAL,
        "an absolute one",
        "jent_kernel_proc(\"/etc/passwd\", buf, sizeof(buf))",
        @src(),
    );
    utEq(
        kern.jent_kernel_proc("../version", &buf, buf.len),
        -EINVAL,
        "one leading out of the directory",
        "jent_kernel_proc(\"../version\", buf, sizeof(buf))",
        @src(),
    );
    utEq(
        kern.jent_kernel_proc("config/../../x", &buf, buf.len),
        -EINVAL,
        "also from below it",
        "jent_kernel_proc(\"config/../../x\", buf, sizeof(buf))",
        @src(),
    );
    utEq(
        kern.jent_kernel_proc("version", null, buf.len),
        -EINVAL,
        "no buffer",
        "jent_kernel_proc(\"version\", NULL, sizeof(buf))",
        @src(),
    );
    utEq(
        kern.jent_kernel_proc("version", &buf, 0),
        -EINVAL,
        "and no room in it",
        "jent_kernel_proc(\"version\", buf, 0)",
        @src(),
    );

    @memset(name[0 .. name.len - 1], 'a');
    name[name.len - 1] = 0;
    utEq(
        kern.jent_kernel_proc(@ptrCast(&name), &buf, buf.len),
        -ENAMETOOLONG,
        "a name too long is refused",
        "jent_kernel_proc(name, buf, sizeof(buf))",
        @src(),
    );
    utEq(
        kern.jent_kernel_proc("no/such/file", &buf, buf.len),
        -ENOENT,
        "a file that is not there is reported",
        "jent_kernel_proc(\"no/such/file\", buf, sizeof(buf))",
        @src(),
    );

    // The reading of a file, against ones made here.
    if (ut_file(&path, version) != 0) {
        utSkip("reading a file", "no temporary file");
        return;
    }
    utEq(
        kern.jent_kernel_file(@ptrCast(&path), &buf, buf.len),
        0,
        "a file is read",
        "jent_kernel_file(path, buf, sizeof(buf))",
        @src(),
    );
    utTrue(
        strcmp(@ptrCast(&buf), version.ptr) == 0,
        "whole, and terminated",
        "!strcmp(buf, version)",
        @src(),
    );
    utEq(
        kern.jent_kernel_file(@ptrCast(&path), &buf, version.len + 1),
        0,
        "a buffer it just fits is enough",
        "jent_kernel_file(path, buf, sizeof(version))",
        @src(),
    );
    utTrue(
        strcmp(@ptrCast(&buf), version.ptr) == 0,
        "and holds all of it",
        "!strcmp(buf, version)",
        @src(),
    );
    buf[0] = 'x';
    utEq(
        kern.jent_kernel_file(@ptrCast(&path), &buf, version.len),
        -EOVERFLOW,
        "a buffer one byte short is not",
        "jent_kernel_file(path, buf, sizeof(version) - 1)",
        @src(),
    );
    utEq(
        buf[0],
        0,
        "and is left empty rather than cut short",
        "buf[0]",
        @src(),
    );
    _ = remove(@ptrCast(&path));

    if (ut_file(&path, null) != 0) {
        utSkip("reading an empty file", "no temporary file");
        return;
    }
    buf[0] = 'x';
    utEq(
        kern.jent_kernel_file(@ptrCast(&path), &buf, buf.len),
        0,
        "an empty file is read",
        "jent_kernel_file(path, buf, sizeof(buf))",
        @src(),
    );
    utEq(
        buf[0],
        0,
        "as an empty string",
        "buf[0]",
        @src(),
    );
    _ = remove(@ptrCast(&path));
}

pub fn main() u8 {
    test_open_read();
    test_ioctls();
    test_proc();

    return jent_ut_report("unit-kernel-lib");
}
