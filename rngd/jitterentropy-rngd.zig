// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause
//
// Copyright (C) 2017 - 2026, Stephan Mueller <smueller@chronox.de>
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// 1. Redistributions of source code must retain the above copyright
//    notice, and the entire permission notice in its entirety,
//    including the disclaimer of warranties.
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote
//    products derived from this software without specific prior
//    written permission.
//
// ALTERNATIVELY, this product may be distributed under the terms of
// the GNU General Public License, in which case the provisions of the GPL are
// required INSTEAD OF the above restrictions.  (This clause is
// necessary due to a potential bad interaction between the GPL and
// the restrictions contained in a BSD-style copyright notice.)
//
// THIS SOFTWARE IS PROVIDED ``AS IS'' AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
// OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, ALL OF
// WHICH ARE HEREBY DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
// OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
// USE OF THIS SOFTWARE, EVEN IF NOT ADVISED OF THE POSSIBILITY OF SUCH
// DAMAGE.

const std = @import("std");
const c = std.c;
const linux = std.os.linux;

fn trapPanic(_: []const u8, _: ?usize) noreturn {
    @trap();
}
pub const panic = std.debug.FullPanic(trapPanic);

extern fn strtoul(value: [*c]const u8, end: *[*:0]u8, base: c_int) callconv(.c) c_ulong;

fn enumInt(value: anytype) @typeInfo(@TypeOf(value)).@"enum".tag_type {
    return @as(*const @typeInfo(@TypeOf(value)).@"enum".tag_type, @ptrCast(&value)).*;
}

const MAJVERSION: c_uint = 3; // API / ABI incompatible changes, functional changes that require consumer to be updated
const MINVERSION: c_uint = 8; // API compatible, ABI may change, functional enhancements only, consumer can be left unchanged
const PATCHLEVEL: c_uint = 0; // API / ABI compatible, no functional changes, no enhancements, bug fixes only

/// The easiest way to ensure locking of the memory would be tracking it
/// inside the entropy collector via `JENT_FORCE_SECURE_MEM`. The allocation,
/// however, could exceed the maximum standard lockable memory amount
/// (`ulimit -l`, suele ser 64kB). Until the operational memory and the buffer
/// of the entropy collector are split so only the latter gets placed in locked
/// memory, we stick to default flags.
const JENT_FLAGS: c_uint = 0;

/// With safety factor of 2 in EntropyBytes -> default OSR can be 1
const JENT_OSR: c_uint = 1;

/// Entropy bytes: Size of output block of SHA-256 -- value in bytes
const ENTROPYBYTES: usize = 32;

/// Oversampling factor matching the random.c behavior where the the incoming
/// data is multiplied by the oversampling factor to obtain data matching this
/// structure. Before kernel 5.18 the factor was 3, in 5.18 it became 2 and in
/// 5.19 it was eliminated. However, the jitterentropy library performs its own
/// oversampling; an additional factor of 2 serves as safety margin only.
const OVERSAMPLINGFACTOR: usize = 2;

/// After the insertion of (ENTROPYBYTES * OVERSAMPLINGFACTOR) bytes formatting
/// a block, the kernel should be awakened to process the entropy. Notice that
/// the threshold is set in bits.
const ENTROPYTHRESH: c_uint = 1024;

const ENTROPYAVAIL: [*:0]const u8 = "/proc/sys/kernel/random/entropy_avail";
const LRNG_FILE: [*:0]const u8 = "/proc/lrng_type";
const RANDOMDEV: [*:0]const u8 = "/dev/random";
const URANDOMDEV: [*:0]const u8 = "/dev/urandom";

const FORCE_RESEED_WAKEUP: c_uint = 300; // Wakeup time: 5 minutes

// Jitterentropy library flags
const JENT_FORCE_INTERNAL_TIMER: c_uint = 1 << 2;
const JENT_DISABLE_INTERNAL_TIMER: c_uint = 1 << 3;
const JENT_FORCE_FIPS: c_uint = 1 << 4;
const JENT_NTG1: c_uint = 1 << 7;

// Linux random ioctls (<linux/random.h>)
const RNDADDENTROPY: u32 = linux.IOCTL.IOW('R', 0x03, [2]c_int);
const RNDRESEEDCRNG: u32 = linux.IOCTL.IO('R', 0x07);

// POSIX lockf commands
const F_TLOCK: c_int = 2;

// Signal mask commands
const SIG_BLOCK: c_int = @intCast(linux.SIG.BLOCK);
const SIG_SETMASK: c_int = @intCast(linux.SIG.SETMASK);

// Socket constants
const AF_UNIX: c_uint = linux.AF.UNIX;
const SOCK_DGRAM: c_uint = linux.SOCK.DGRAM;
const SOCK_CLOEXEC: c_uint = linux.SOCK.CLOEXEC;
const MSG_NOSIGNAL: u32 = linux.MSG.NOSIGNAL;

// Syslog constants
const LOG_PID: c_int = 0x01;
const LOG_DAEMON: c_int = 3 << 3;
const LOG_ERR: c_int = 3;
const LOG_WARNING: c_int = 4;
const LOG_INFO: c_int = 6;
const LOG_DEBUG: c_int = 7;

pub const rand_data = opaque {};

extern fn jent_version() callconv(.c) c_uint;
extern fn jent_entropy_init_ex(osr: c_uint, flags: c_uint) callconv(.c) c_int;
extern fn jent_entropy_collector_alloc(osr: c_uint, flags: c_uint) callconv(.c) ?*rand_data;
extern fn jent_entropy_collector_free(entropy_collector: ?*rand_data) callconv(.c) void;
extern fn jent_read_entropy(entropy_collector: ?*rand_data, data: [*]u8, len: usize) callconv(.c) isize;
extern fn jent_read_entropy_safe(entropy_collector: *?*rand_data, data: [*]u8, len: usize) callconv(.c) isize;
extern fn jent_status(entropy_collector: *const rand_data, buf: [*]u8, buflen: usize) callconv(.c) c_int;

const Option = extern struct {
    name: ?[*:0]const u8,
    has_arg: c_int,
    flag: ?*c_int,
    val: c_int,
};

extern var optarg: ?[*:0]u8;
extern var optind: c_int;
extern var stdout: *c.FILE;
extern var stderr: *c.FILE;
extern var stdin: *c.FILE;

extern fn getopt_long(
    argc: c_int,
    argv: [*]?[*:0]u8,
    optstring: [*:0]const u8,
    longopts: [*]const Option,
    longindex: ?*c_int,
) callconv(.c) c_int;

extern fn strerror(errnum: c_int) callconv(.c) [*:0]u8;
extern fn fprintf(stream: *c.FILE, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn fflush(stream: ?*c.FILE) callconv(.c) c_int;
extern fn freopen(filename: [*:0]const u8, mode: [*:0]const u8, stream: *c.FILE) callconv(.c) ?*c.FILE;
extern fn lockf(fd: c_int, cmd: c_int, len: c.off_t) callconv(.c) c_int;
extern fn pselect(
    nfds: c_int,
    readfds: ?*anyopaque,
    writefds: ?*anyopaque,
    exceptfds: ?*anyopaque,
    timeout: ?*const c.timespec,
    sigmask: ?*const c.sigset_t,
) callconv(.c) c_int;

const Tm = extern struct {
    tm_sec: c_int,
    tm_min: c_int,
    tm_hour: c_int,
    tm_mday: c_int,
    tm_mon: c_int,
    tm_year: c_int,
    tm_wday: c_int,
    tm_yday: c_int,
    tm_isdst: c_int,
    tm_gmtoff: c_long,
    tm_zone: ?[*:0]const u8,
};

extern fn localtime_r(timer: *const isize, tp: *Tm) callconv(.c) ?*Tm;
extern fn strftime(s: [*]u8, maxsize: usize, format: [*:0]const u8, tp: *const Tm) callconv(.c) usize;

const RandPoolInfo = extern struct {
    entropy_count: c_int,
    buf_size: c_int,
    buf: [ENTROPYBYTES * OVERSAMPLINGFACTOR]u8,
};

const RngCtx = struct {
    cfd: c_int = -1,
    rfd: c_int = -1,
    ufd: c_int = -1,
    entropy_collector: ?*rand_data = null,
    rnd: ?*RandPoolInfo = null,
    sp800_90b: bool = true,
    flags: c_uint = JENT_FLAGS,
    osr: c_uint = JENT_OSR,
    status: bool = false,
    exit_on_error: bool = false,
    pidfile: ?[*:0]const u8 = null,
    pidfile_fd: c_int = -1,
    daemonize_flag: bool = true,
    phase1_runs: c_uint = 10,
    phase1_sleep: c_uint = 5,
    phase2_sleep: c_uint = 60,
    oneshot: bool = false,
};

var ctx: RngCtx = .{};

const RED: [*:0]const u8 = "\x1b[0;31m";
const YELLOW: [*:0]const u8 = "\x1b[0;33m";
const NC: [*:0]const u8 = "\x1b[0m";

var Use_color: bool = false;
var Use_syslog: bool = false;
var Verbosity: c_uint = 0;

const JENT_LOG_ERR: c_uint = 0;
const JENT_LOG_WARN: c_uint = 1;
const JENT_LOG_INFO: c_uint = 2;
const JENT_LOG_DEBUG: c_uint = 3;

fn currentErrno() c_int {
    return c._errno().*;
}

fn setErrno(val: c_int) void {
    c._errno().* = val;
}

fn strerrorSlice(errnum: c_int) []const u8 {
    return std.mem.span(strerror(errnum));
}

fn detect_color() void {
    if (c.isatty(c.STDOUT_FILENO) != 1) {
        Use_color = false;
        return;
    }

    // Respect NO_COLOR convention (https://no-color.org/)
    if (c.getenv("NO_COLOR") != null) {
        Use_color = false;
        return;
    }

    const term = c.getenv("TERM");
    if (term != null and std.mem.orderZ(u8, term.?, "dumb") == .eq) {
        Use_color = false;
        return;
    }

    Use_color = true;
}

fn logtime(buf: []u8) void {
    var ts: c.timespec = undefined;
    var tm: Tm = undefined;

    if (c.clock_gettime(c.CLOCK.REALTIME, &ts) != 0) {
        buf[0] = 0;
        return;
    }

    const sec: isize = @intCast(ts.sec);
    if (localtime_r(&sec, &tm) == null) {
        buf[0] = 0;
        return;
    }

    const n = strftime(buf.ptr, buf.len, "%Y-%m-%d %H:%M:%S", &tm);
    if (n == 0 or n >= buf.len) {
        buf[0] = 0;
        return;
    }

    const ms: c_long = @intCast(@divTrunc(ts.nsec, 1_000_000));
    const rem = buf[n..];
    if (rem.len > 1) {
        const formatted = std.fmt.bufPrint(rem[0 .. rem.len - 1], ".{d:0>3}", .{@as(u64, @intCast(@max(0, ms)))}) catch {
            buf[n] = 0;
            return;
        };
        rem[formatted.len] = 0;
    } else {
        buf[n] = 0;
    }
}

fn dolog(severity: c_uint, comptime fmt: []const u8, args: anytype) void {
    var msg_buf: [2048]u8 = undefined;
    const msg: [:0]const u8 = blk: {
        const s = std.fmt.bufPrint(msg_buf[0 .. msg_buf.len - 1], fmt, args) catch {
            msg_buf[msg_buf.len - 1] = 0;
            break :blk msg_buf[0 .. msg_buf.len - 1 :0];
        };
        msg_buf[s.len] = 0;
        break :blk msg_buf[0..s.len :0];
    };

    if (severity <= Verbosity) {
        if (Use_syslog) {
            const prio: c_int = switch (severity) {
                JENT_LOG_ERR => LOG_ERR,
                JENT_LOG_WARN => LOG_WARNING,
                JENT_LOG_INFO => LOG_INFO,
                else => LOG_DEBUG,
            };
            c.syslog(prio, "%s", msg.ptr);
        } else {
            var sev: [*:0]const u8 = "DEBUG";
            var col: [*:0]const u8 = "";
            const nc: [*:0]const u8 = if (Use_color) NC else "";
            var timebuf: [32]u8 = undefined;

            switch (severity) {
                JENT_LOG_INFO => {
                    sev = "INFO";
                },
                JENT_LOG_WARN => {
                    sev = "WARN";
                    if (Use_color) col = YELLOW;
                },
                JENT_LOG_ERR => {
                    sev = "ERR";
                    if (Use_color) col = RED;
                },
                else => {},
            }

            logtime(&timebuf);
            _ = c.printf("%s[%s] %s: %s%s\n", col, @as([*:0]const u8, @ptrCast(&timebuf)), sev, msg.ptr, nc);
        }
    }

    if (severity == JENT_LOG_ERR) {
        dealloc();
        c.exit(1);
    }
}

inline fn memset_secure(s: []u8) void {
    @memset(s, 0);
    asm volatile (""
        :
        : [p] "r" (s.ptr),
        : .{ .memory = true });
}

// ===========================================================================
// Service manager notification (sd_notify protocol)
//
// Self-contained implementation of the sd_notify(3) datagram protocol so we
// do not need to link against libsystemd. If $NOTIFY_SOCKET is not set or
// unsupported, this is a no-op.
// ===========================================================================
fn notify_service_manager(state: ?[*:0]const u8) void {
    const sock_path_ptr = c.getenv("NOTIFY_SOCKET") orelse return;
    const sock_path = std.mem.span(sock_path_ptr);
    if (sock_path.len == 0) return;
    const st = state orelse return;
    const st_slice = std.mem.span(st);
    if (st_slice.len == 0) return;

    // Only AF_UNIX paths ('/') and abstract sockets ('@') are supported
    if (sock_path[0] != '/' and sock_path[0] != '@') return;

    var addr: linux.sockaddr.un = std.mem.zeroes(linux.sockaddr.un);
    addr.family = linux.AF.UNIX;
    if (sock_path.len >= addr.path.len) return;

    @memcpy(addr.path[0..sock_path.len], sock_path);
    var addrlen: c.socklen_t = @intCast(@offsetOf(linux.sockaddr.un, "path") + sock_path.len);
    if (addr.path[0] == '@') {
        addr.path[0] = 0; // Linux abstract socket namespace
    } else {
        addrlen += 1; // Include trailing NUL for filesystem paths
    }

    const fd = c.socket(AF_UNIX, SOCK_DGRAM | SOCK_CLOEXEC, 0);
    if (fd < 0) return;
    defer _ = c.close(fd);

    _ = c.sendto(fd, st_slice.ptr, st_slice.len, MSG_NOSIGNAL, @ptrCast(&addr), addrlen);
}

fn notify_ready() void {
    notify_service_manager("READY=1\n");
}

// ===========================================================================
// Entropy gathering and writing functions
// ===========================================================================

/// Verify whether LRNG is present
fn lrng_present() bool {
    var stx: linux.Statx = undefined;
    const rc = linux.statx(linux.AT.FDCWD, LRNG_FILE, 0, .{}, &stx);
    if (linux.errno(rc) == .NOENT)
        return false;
    return true;
}

fn get_kernver(maj: *c_uint, minor: *c_uint, patchlevel: *c_uint) void {
    var kernel: c.utsname = undefined;
    var saveptr: [*:0]u8 = undefined;

    if (c.uname(&kernel) < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_ERR, "Cannot obtain Linux kernel version ({s})", .{strerrorSlice(err)});
    }

    // Format of release is <MAJ>.<MIN>.<PATCHLEVEL><ADDITIONAL TEXT>
    setErrno(0);
    const rel_ptr: [*:0]const u8 = @ptrCast(&kernel.release);
    var res = strtoul(rel_ptr, &saveptr, 10);
    if ((res == std.math.maxInt(c_ulong) and currentErrno() == enumInt(linux.E.RANGE)) or
        res > std.math.maxInt(c_uint) or saveptr == rel_ptr or saveptr[0] == 0)
    {
        dolog(JENT_LOG_ERR, "Cannot parse kernel major version", .{});
    }
    maj.* = @intCast(res);
    saveptr += 1;

    setErrno(0);
    var cur: [*:0]const u8 = saveptr;
    res = strtoul(cur, &saveptr, 10);
    if ((res == std.math.maxInt(c_ulong) and currentErrno() == enumInt(linux.E.RANGE)) or
        res > std.math.maxInt(c_uint) or saveptr == cur or saveptr[0] == 0)
    {
        dolog(JENT_LOG_ERR, "Cannot parse kernel minor version", .{});
    }
    minor.* = @intCast(res);
    saveptr += 1;

    setErrno(0);
    cur = saveptr;
    res = strtoul(cur, &saveptr, 10);
    if ((res == std.math.maxInt(c_ulong) and currentErrno() == enumInt(linux.E.RANGE)) or
        res > std.math.maxInt(c_uint) or saveptr == cur)
    {
        dolog(JENT_LOG_ERR, "Cannot parse kernel patchlevel version", .{});
    }
    patchlevel.* = @intCast(res);

    dolog(JENT_LOG_DEBUG, "Detected kernel version {d}.{d}.{d}", .{ maj.*, minor.*, patchlevel.* });
}

fn kernver_ge(req_maj: c_uint, req_minor: c_uint, req_patchlevel: c_uint) bool {
    const State = struct {
        var maj: c_uint = 0;
        var minor: c_uint = 0;
        var patchlevel: c_uint = 0;
        var parsed: bool = false;
    };

    if (!State.parsed) {
        get_kernver(&State.maj, &State.minor, &State.patchlevel);
        State.parsed = true;
    }

    if (req_maj < State.maj) return true;
    if (req_maj == State.maj) {
        if (req_minor < State.minor) return true;
        if (req_minor == State.minor) {
            if (req_patchlevel <= State.patchlevel) return true;
        }
    }

    return false;
}

fn write_random(buf: [*]u8, buflen: usize, entropy_bytes: usize, force_reseed: bool) usize {
    var written: usize = 0;
    var ret: isize = 0;

    // Value is in bits.
    const rnd = ctx.rnd.?;
    rnd.entropy_count = @intCast(entropy_bytes * 8);
    rnd.buf_size = @intCast(buflen);
    @memcpy(rnd.buf[0..buflen], buf[0..buflen]);

    ret = c.ioctl(ctx.rfd, @bitCast(RNDADDENTROPY), rnd);
    if (ret < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_WARN, "Error injecting entropy: {s}", .{strerrorSlice(err)});
    } else {
        dolog(JENT_LOG_DEBUG, "Injected {d} bytes with an entropy count of {d} bytes of entropy", .{ buflen, entropy_bytes });
        written = buflen;
    }
    rnd.entropy_count = 0;
    rnd.buf_size = 0;
    memset_secure(&rnd.buf);

    // Tell the kernel to blocking-reseed the ChaCha20 DRBG if force_reseed
    // is set or Kernel is at least 5.18 which takes the automatic trigger
    // logic away!
    if (force_reseed or kernver_ge(5, 18, 0)) {
        dolog(JENT_LOG_DEBUG, "Triggeringblocking reseed of kernel CRNG", .{});
        ret = c.ioctl(ctx.rfd, @bitCast(RNDRESEEDCRNG), @as(c_int, 0));
        if (ret < 0 and currentErrno() != enumInt(linux.E.INVAL)) {
            const err = currentErrno();
            dolog(JENT_LOG_WARN, "Error triggering blocking reseed of CRNG: {s}", .{strerrorSlice(err)});
        }
    }

    return written;
}

fn read_jent(buf: [*]u8, buflen: usize) isize {
    if (ctx.sp800_90b) {
        return jent_read_entropy_safe(&ctx.entropy_collector, buf, buflen);
    } else {
        return jent_read_entropy(ctx.entropy_collector, buf, buflen);
    }
}

fn gather_entropy(force_reseed: bool) isize {
    var sigset: c.sigset_t = undefined;
    var oldset: c.sigset_t = undefined;
    var buf: [ENTROPYBYTES * OVERSAMPLINGFACTOR]u8 = undefined;
    var buflen: usize = ENTROPYBYTES * OVERSAMPLINGFACTOR;
    var ret: usize = 0;
    var rc: isize = 0;

    _ = c.sigemptyset(&sigset);
    _ = c.sigaddset(&sigset, c.SIG.ALRM);
    _ = c.sigprocmask(SIG_BLOCK, &sigset, &oldset);

    if (lrng_present() or kernver_ge(5, 19, 0))
        buflen = ENTROPYBYTES;

    dolog(JENT_LOG_DEBUG, "Gathering {d} bytes of entropy", .{buflen});

    rc = read_jent(&buf, buflen);
    if (rc < 0) {
        dolog(JENT_LOG_WARN, "Cannot read entropy (error {d})", .{rc});
        _ = c.sigprocmask(SIG_SETMASK, &oldset, null);
        return -1;
    }

    if (ctx.status) {
        var state: [500]u8 = undefined;
        @memset(&state, 0);
        if (ctx.entropy_collector) |ec| {
            _ = jent_status(ec, &state, state.len - 1);
            state[state.len - 1] = 0;
            const state_cstr: [*:0]const u8 = state[0 .. state.len - 1 :0];
            dolog(JENT_LOG_INFO, "Jitter RNG status:\n{s}", .{std.mem.span(state_cstr)});
        }
    }

    ret = write_random(&buf, buflen, ENTROPYBYTES, force_reseed);
    memset_secure(buf[0..buflen]);
    if (buflen != ret) {
        dolog(JENT_LOG_WARN, "Injected {d} bytes into {s}, expected {d}", .{ ret, std.mem.span(RANDOMDEV), buflen });
        ret = 0;
    }

    _ = c.sigprocmask(SIG_SETMASK, &oldset, null);

    return @intCast(ret);
}

fn realloc_jent() bool {
    jent_entropy_collector_free(ctx.entropy_collector);
    ctx.entropy_collector = jent_entropy_collector_alloc(ctx.osr, ctx.flags);
    if (ctx.entropy_collector == null) {
        dolog(JENT_LOG_WARN, "Allocation of entropy collector failed", .{});
        return false;
    }
    return true;
}

/// Draw entropy from the Jitter RNG and inject it into the kernel.
///
/// Even though `read_jent()` uses `jent_read_entropy_safe()` by default, that
/// routine can still fail if a permanent health test error occurs, or if the
/// internal reallocation bumps the OSR past `JENT_MAX_OSR`. In such cases we
/// attempt to tear down and reallocate a fresh collector with our configured
/// baseline parameters (`ctx.osr`, `ctx.flags`).
fn gather_entropy_retry(force_reseed: bool) void {
    const max_ATTEMPTS: usize = 3;
    const backoff_ns: c_long = 100 * 1000 * 1000; // 100 ms

    for (0..max_ATTEMPTS) |attempt| {
        if (ctx.entropy_collector != null or realloc_jent()) {
            if (gather_entropy(force_reseed) > 0)
                return;
        }

        if (ctx.exit_on_error) {
            dolog(JENT_LOG_ERR, "Entropy collection failed and --exit-on-error is set", .{});
        }

        const ts = c.timespec{
            .sec = 0,
            .nsec = backoff_ns,
        };
        _ = c.nanosleep(&ts, null);

        dolog(JENT_LOG_WARN, "Retrying entropy collection (attempt {d}/{d}) with fresh collector", .{ attempt + 1, max_ATTEMPTS });
        _ = realloc_jent();
    }

    dolog(JENT_LOG_ERR, "Cannot collect entropy after {d} attempts, aborting", .{max_ATTEMPTS});
}

fn read_entropy_value(fd: c_int) c_uint {
    var buf: [24]u8 = undefined;

    if (c.lseek64(fd, 0, c.SEEK.SET) < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_WARN, "Error seeking to start of file: {s}", .{strerrorSlice(err)});
        return 0;
    }

    const data = c.read(fd, &buf, buf.len - 1);
    if (data <= 0) {
        const err = currentErrno();
        dolog(JENT_LOG_WARN, "Error reading entropy value: {s}", .{strerrorSlice(err)});
        return 0;
    }
    const read_len: usize = @intCast(data);
    buf[read_len] = 0;

    setErrno(0);
    var endptr: [*:0]u8 = undefined;
    const buf_ptr: [*:0]const u8 = buf[0..read_len :0];
    const val = strtoul(buf_ptr, &endptr, 10);
    if ((val == std.math.maxInt(c_ulong) and currentErrno() == enumInt(linux.E.RANGE)) or
        val > std.math.maxInt(c_uint) or endptr == buf_ptr)
    {
        dolog(JENT_LOG_WARN, "Error converting read entropy value", .{});
        return 0;
    }

    return @intCast(val);
}

// ===========================================================================
// Signal handling functions
// ===========================================================================
var Alarm_pending: c.sig_atomic_t = 0;
var Term_pending: c.sig_atomic_t = 0;

/// Signal handlers must only set a flag and return. All actual work
/// (entropy collection, logging, cleanup) is performed from the main loop
/// where non-async-signal-safe functions are legal.
fn sig_entropy_avail(sig: c.SIG) callconv(.c) void {
    _ = sig;
    @atomicStore(c.sig_atomic_t, &Alarm_pending, 1, .seq_cst);
}

fn sig_term(sig: c.SIG) callconv(.c) void {
    @atomicStore(c.sig_atomic_t, &Term_pending, @intCast(enumInt(sig)), .seq_cst);
}

fn process_alarm() void {
    var avail: c_uint = 0;

    @atomicStore(c.sig_atomic_t, &Alarm_pending, 0, .seq_cst);

    dolog(JENT_LOG_DEBUG, "Wakeup call for alarm on {s}", .{std.mem.span(ENTROPYAVAIL)});

    avail = read_entropy_value(ctx.cfd);
    dolog(JENT_LOG_DEBUG, "Read {d} bits of entropy from {s}", .{ avail, std.mem.span(ENTROPYAVAIL) });

    if (avail == 0 or avail < ENTROPYTHRESH) {
        dolog(JENT_LOG_DEBUG, "Threshold of {d} bits not reached (available: {d}), gathering entropy", .{ ENTROPYTHRESH, avail });
        gather_entropy_retry(false);
    } else {
        dolog(JENT_LOG_DEBUG, "Sufficient entropy available ({d} > {d})", .{ avail, ENTROPYTHRESH });
    }
    // Always re-arm the alarm so periodic checks continue
    _ = c.alarm(5);
}

fn process_term() void {
    const sig = @atomicLoad(c.sig_atomic_t, &Term_pending, .seq_cst);
    // Revert to non-colored standard output for shutdown message? No, dolog handles it.
    dolog(JENT_LOG_INFO, "Shutting down cleanly on signal {d}", .{sig});
    dealloc();
    c.exit(0);
}

const FdSet = extern struct {
    fds_bits: [16]c_ulong = @splat(0),

    fn set(self: *FdSet, fd: c_int) void {
        const ufd: usize = @intCast(fd);
        const bits_per_word = @bitSizeOf(c_ulong);
        self.fds_bits[ufd / bits_per_word] |= @as(c_ulong, 1) << @intCast(ufd % bits_per_word);
    }
};

fn select_fd() void {
    var fds: FdSet = .{};
    var nfds: c_int = 0;
    var ret: c_int = 0;
    var timeout: c.timespec = .{
        .sec = FORCE_RESEED_WAKEUP,
        .nsec = 0,
    };
    var block_mask: c.sigset_t = undefined;
    var orig_mask: c.sigset_t = undefined;

    // Block delivered signals before checking the pending flags so that a
    // signal arriving between the check and pselect() cannot be lost:
    // pselect() atomically restores orig_mask and sleeps.
    _ = c.sigemptyset(&block_mask);
    _ = c.sigaddset(&block_mask, c.SIG.ALRM);
    _ = c.sigaddset(&block_mask, c.SIG.HUP);
    _ = c.sigaddset(&block_mask, c.SIG.INT);
    _ = c.sigaddset(&block_mask, c.SIG.QUIT);
    _ = c.sigaddset(&block_mask, c.SIG.TERM);
    _ = c.sigprocmask(SIG_BLOCK, &block_mask, &orig_mask);

    while (true) {
        // Service any signals that arrived before or during pselect().
        if (@atomicLoad(c.sig_atomic_t, &Term_pending, .seq_cst) != 0) {
            _ = c.sigprocmask(SIG_SETMASK, &orig_mask, null);
            process_term();
        }
        if (@atomicLoad(c.sig_atomic_t, &Alarm_pending, .seq_cst) != 0) {
            _ = c.sigprocmask(SIG_SETMASK, &orig_mask, null);
            process_alarm();
            _ = c.sigprocmask(SIG_BLOCK, &block_mask, &orig_mask);
            continue;
        }

        fds = .{};
        dolog(JENT_LOG_DEBUG, "Polling /dev/random and /dev/urandom", .{});

        fds.set(ctx.rfd);
        fds.set(ctx.ufd);
        nfds = @max(ctx.rfd, ctx.ufd);

        // Only timeout on kernels < 5.18; newer kernels handle periodic
        // reseeding internally.
        ret = pselect(
            nfds + 1,
            null,
            &fds,
            null,
            if (kernver_ge(5, 18, 0)) null else &timeout,
            &orig_mask,
        );

        if (ret >= 0) break;

        if (currentErrno() != enumInt(linux.E.INTR)) {
            const err = currentErrno();
            _ = c.sigprocmask(SIG_SETMASK, &orig_mask, null);
            dolog(JENT_LOG_ERR, "Select returned with error {s}", .{strerrorSlice(err)});
        }
    }

    _ = c.sigprocmask(SIG_SETMASK, &orig_mask, null);

    // On wakeup (either fd is writable or timeout expired), inject entropy.
    // Force a blocking CRNG reseed if it was a timeout (ret == 0).
    dolog(JENT_LOG_DEBUG, "Wakeup call from select({d})", .{ret});
    gather_entropy_retry(ret == 0);
}

fn install_handler(sig: c.SIG, handler: *const fn (c.SIG) callconv(.c) void, extra_flags: c_uint) bool {
    var act: c.Sigaction = .{
        .handler = .{ .handler = handler },
        .mask = std.mem.zeroes(c.sigset_t),
        .flags = c.SA.RESTART | extra_flags,
    };
    _ = c.sigemptyset(&act.mask);
    if (c.sigaction(sig, &act, null) < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_WARN, "Cannot install signal handler for signal {d}: {s}", .{ enumInt(sig), strerrorSlice(err) });
        return false;
    }
    return true;
}

/// Normally the polling of `/dev/random` and `/dev/urandom` should suffice as the
/// kernel wakes up wait_queue waiters when the entropy pool drops below the
/// write_wakeup_threshold. Yet, especially on newer kernels, we also install a
/// periodic timer checking `entropy_avail` directly as a fallback.
fn install_alarm() void {
    if (kernver_ge(5, 18, 0))
        return;

    dolog(JENT_LOG_DEBUG, "Install alarm signal handler", .{});
    if (!install_handler(c.SIG.ALRM, sig_entropy_avail, 0))
        return;
    _ = c.alarm(5);
}

fn install_term() void {
    dolog(JENT_LOG_DEBUG, "Install termination signal handler", .{});
    // Use SA_RESETHAND so a second signal kills the process immediately if
    // it is stuck inside a long blocking operation.
    _ = install_handler(c.SIG.HUP, sig_term, linux.SA.RESETHAND);
    _ = install_handler(c.SIG.INT, sig_term, linux.SA.RESETHAND);
    _ = install_handler(c.SIG.QUIT, sig_term, linux.SA.RESETHAND);
    _ = install_handler(c.SIG.TERM, sig_term, linux.SA.RESETHAND);
}

// ===========================================================================
// Initialization, daemonization and teardown
// ===========================================================================
fn parse_ulong_pair(str: [*:0]const u8, optname: [*:0]const u8, val1: *c_ulong, val2: *c_ulong) void {
    var endptr: [*:0]u8 = undefined;

    setErrno(0);
    val1.* = strtoul(str, &endptr, 0);
    if ((val1.* == std.math.maxInt(c_ulong) and currentErrno() == enumInt(linux.E.RANGE)) or
        endptr == str or endptr[0] != ':')
    {
        dolog(JENT_LOG_ERR, "Invalid argument '{s}' for option {s} (expected <num>:<num>)", .{ std.mem.span(str), std.mem.span(optname) });
    }

    const second: [*:0]const u8 = endptr + 1;
    setErrno(0);
    val2.* = strtoul(second, &endptr, 0);
    if ((val2.* == std.math.maxInt(c_ulong) and currentErrno() == enumInt(linux.E.RANGE)) or
        endptr == second or endptr[0] != 0)
    {
        dolog(JENT_LOG_ERR, "Invalid argument '{s}' for option {s} (expected <num>:<num>)", .{ std.mem.span(str), std.mem.span(optname) });
    }
}

fn parse_uint(str: [*:0]const u8, optname: [*:0]const u8) c_uint {
    var endptr: [*:0]u8 = undefined;

    // Reject negative numbers explicitly since strtoul wraps them
    var p: [*:0]const u8 = str;
    while (p[0] == ' ' or p[0] == '\t') : (p += 1) {}
    if (p[0] == '-') {
        dolog(JENT_LOG_ERR, "Invalid negative argument '{s}' for option {s}", .{ std.mem.span(str), std.mem.span(optname) });
    }

    setErrno(0);
    const val = strtoul(str, &endptr, 0);
    if ((val == std.math.maxInt(c_ulong) and currentErrno() == enumInt(linux.E.RANGE)) or
        val > std.math.maxInt(c_uint) or endptr == str or endptr[0] != 0)
    {
        dolog(JENT_LOG_ERR, "Invalid numerical argument '{s}' for option {s}", .{ std.mem.span(str), std.mem.span(optname) });
    }

    return @intCast(val);
}

fn usage() noreturn {
    const u_str =
        \\jitterentropy-rngd - Jitter RNG Daemon
        \\
        \\Usage: jitterentropy-rngd [OPTION]
        \\
        \\  -v, --verbose                 Increase verbosity (can be specified multiple times)
        \\  -p, --pid [FILE]              Path to PID file
        \\  -F, --foreground              Do not daemonize, run in foreground
        \\  -l, --syslog                  Log messages to syslog instead of stdout
        \\  -s, --sp800-90b               Enable SP800-90B compliance (default: enabled)
        \\  -f, --flags [FLAGS]           Specify flags for allocating the Jitter RNG
        \\  -o, --osr [OSR]               Specify oversampling rate (default: 1)
        \\  -n, --ntg1                    Enable NTG.1 compliance mode
        \\      --fips                    Enable FIPS 140 compliance mode
        \\  -i, --force-internal-timer    Force the use of the internal timer
        \\  -I, --disable-internal-timer  Disable the internal timer
        \\      --status                  Log Jitter RNG status after each collection
        \\      --exit-on-error           Exit immediately if entropy collection fails
        \\      --phase1 [RUNS:SLEEP]     Phase 1 bursts and sleep seconds (default: 10:5)
        \\      --phase2 [SLEEP]          Phase 2 sleep seconds on modern kernels (default: 60)
        \\      --oneshot                 Inject entropy once into the kernel and exit
        \\  -h, --help                    Print this help message
        \\      --version                 Print version information
        \\
    ;
    _ = fprintf(stderr, "%s", u_str.ptr);
    c.exit(1);
}

fn parse_opts(argc: c_int, argv: [*]?[*:0]u8) void {
    var opt_index: c_int = 0;

    const opts = [_]Option{
        .{ .name = "verbose", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = "pid", .has_arg = 1, .flag = null, .val = 0 },
        .{ .name = "help", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = "version", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = "sp800-90b", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = "flags", .has_arg = 1, .flag = null, .val = 0 },
        .{ .name = "osr", .has_arg = 1, .flag = null, .val = 0 },
        .{ .name = "status", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = "exit-on-error", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = "syslog", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = "foreground", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = "ntg1", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = "force-internal-timer", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = "disable-internal-timer", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = "fips", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = "phase1", .has_arg = 1, .flag = null, .val = 0 },
        .{ .name = "phase2", .has_arg = 1, .flag = null, .val = 0 },
        .{ .name = "oneshot", .has_arg = 0, .flag = null, .val = 0 },
        .{ .name = null, .has_arg = 0, .flag = null, .val = 0 },
    };

    while (true) {
        const ch = getopt_long(argc, argv, "svp:hf:o:lFniI", &opts, &opt_index);
        if (ch == -1) break;

        switch (ch) {
            0 => switch (opt_index) {
                0 => Verbosity += 1,
                1 => ctx.pidfile = optarg,
                2 => usage(),
                3 => {
                    _ = fprintf(stderr, "Version jitterentropy-rngd %u.%u.%u\n", MAJVERSION, MINVERSION, PATCHLEVEL);
                    _ = fprintf(stderr, "Version Jitterentropy Core %u\n", jent_version());
                    c.exit(0);
                },
                4 => ctx.sp800_90b = true,
                5 => ctx.flags |= parse_uint(optarg.?, "--flags"),
                6 => ctx.osr = parse_uint(optarg.?, "--osr"),
                7 => ctx.status = true,
                8 => ctx.exit_on_error = true,
                9 => Use_syslog = true,
                10 => ctx.daemonize_flag = false,
                11 => ctx.flags |= JENT_NTG1,
                12 => ctx.flags |= JENT_FORCE_INTERNAL_TIMER,
                13 => ctx.flags |= JENT_DISABLE_INTERNAL_TIMER,
                14 => ctx.flags |= JENT_FORCE_FIPS,
                15 => {
                    var a: c_ulong = 0;
                    var b: c_ulong = 0;
                    parse_ulong_pair(optarg.?, "--phase1", &a, &b);
                    if (a > std.math.maxInt(c_uint) or b < 1 or b > std.math.maxInt(c_uint))
                        usage();
                    ctx.phase1_runs = @intCast(a);
                    ctx.phase1_sleep = @intCast(b);
                },
                16 => {
                    ctx.phase2_sleep = parse_uint(optarg.?, "--phase2");
                    if (ctx.phase2_sleep < 1)
                        usage();
                },
                17 => {
                    ctx.oneshot = true;
                    ctx.daemonize_flag = false;
                },
                else => usage(),
            },
            'v' => Verbosity += 1,
            'p' => ctx.pidfile = optarg,
            'h' => usage(),
            's' => ctx.sp800_90b = true,
            'f' => ctx.flags |= parse_uint(optarg.?, "-f"),
            'o' => ctx.osr = parse_uint(optarg.?, "-o"),
            'l' => Use_syslog = true,
            'F' => ctx.daemonize_flag = false,
            'n' => ctx.flags |= JENT_NTG1,
            'i' => ctx.flags |= JENT_FORCE_INTERNAL_TIMER,
            'I' => ctx.flags |= JENT_DISABLE_INTERNAL_TIMER,
            else => usage(),
        }
    }

    if (optind < argc)
        usage();

    if (Verbosity > JENT_LOG_DEBUG)
        Verbosity = JENT_LOG_DEBUG;

    // Reject contradictory flag combinations early
    if ((ctx.flags & JENT_FORCE_INTERNAL_TIMER) != 0 and
        (ctx.flags & JENT_DISABLE_INTERNAL_TIMER) != 0)
    {
        dolog(JENT_LOG_ERR, "Cannot both force and disable the internal timer", .{});
    }
    if ((ctx.flags & JENT_NTG1) != 0 and
        (ctx.flags & JENT_FORCE_INTERNAL_TIMER) != 0)
    {
        dolog(JENT_LOG_ERR, "Cannot force the internal timer when NTG.1 is enabled", .{});
    }
}

fn alloc_rng() void {
    var ret: c_int = 0;

    ret = jent_entropy_init_ex(ctx.osr, ctx.flags);
    if (ret != 0) {
        dolog(JENT_LOG_ERR, "The initialization of the Jitter RNG failed with error code {d}", .{ret});
    }

    ctx.entropy_collector = jent_entropy_collector_alloc(ctx.osr, ctx.flags);
    if (ctx.entropy_collector == null) {
        dolog(JENT_LOG_ERR, "The allocation of the Jitter RNG entropy collector failed", .{});
    }

    const ptr = c.malloc(@sizeOf(RandPoolInfo));
    if (ptr == null) {
        dolog(JENT_LOG_ERR, "Cannot allocate memory for random pool info", .{});
    }
    const rnd: *RandPoolInfo = @ptrCast(@alignCast(ptr.?));
    rnd.* = std.mem.zeroes(RandPoolInfo);
    ctx.rnd = rnd;
}

fn open_Flags(acc: std.posix.ACCMODE, creat: bool, nofollow: bool, cloexec: bool) c.O {
    return .{
        .ACCMODE = acc,
        .CREAT = creat,
        .NOFOLLOW = nofollow,
        .CLOEXEC = cloexec,
    };
}

fn alloc() void {
    alloc_rng();

    ctx.rfd = c.open64(RANDOMDEV, open_Flags(.WRONLY, false, false, true), @as(c.mode_t, 0));
    if (ctx.rfd < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_ERR, "Cannot open file {s}: {s}", .{ std.mem.span(RANDOMDEV), strerrorSlice(err) });
    }

    if (ctx.oneshot)
        return;

    ctx.cfd = c.open64(ENTROPYAVAIL, open_Flags(.RDONLY, false, false, true), @as(c.mode_t, 0));
    if (ctx.cfd < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_ERR, "Cannot open file {s}: {s}", .{ std.mem.span(ENTROPYAVAIL), strerrorSlice(err) });
    }

    ctx.ufd = c.open64(URANDOMDEV, open_Flags(.WRONLY, false, false, true), @as(c.mode_t, 0));
    if (ctx.ufd < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_ERR, "Cannot open file {s}: {s}", .{ std.mem.span(URANDOMDEV), strerrorSlice(err) });
    }

    // Write some initial entropy to ensure the kernel has something right
    // away before we enter the select() loop.
    gather_entropy_retry(true);
}

fn dealloc_rng() void {
    if (ctx.entropy_collector) |ec| {
        jent_entropy_collector_free(ec);
        ctx.entropy_collector = null;
    }

    if (ctx.rnd) |rnd| {
        const bytes: [*]u8 = @ptrCast(rnd);
        memset_secure(bytes[0..@sizeOf(RandPoolInfo)]);
        c.free(rnd);
        ctx.rnd = null;
    }
}

fn dealloc() void {
    dealloc_rng();

    if (ctx.cfd >= 0) {
        _ = c.close(ctx.cfd);
        ctx.cfd = -1;
    }
    if (ctx.rfd >= 0) {
        _ = c.close(ctx.rfd);
        ctx.rfd = -1;
    }
    if (ctx.ufd >= 0) {
        _ = c.close(ctx.ufd);
        ctx.ufd = -1;
    }

    if (ctx.pidfile_fd >= 0) {
        _ = c.close(ctx.pidfile_fd);
        ctx.pidfile_fd = -1;
        if (ctx.pidfile) |pf| {
            _ = c.unlink(pf);
        }
    }

    if (Use_syslog) {
        c.closelog();
    }
}

/// Create and lock a PID file. We keep the file descriptor open for the
/// lifetime of the daemon so the `lockf()` advisory lock stays held.
fn create_pid_file(pid_file: ?[*:0]const u8) void {
    const pf = pid_file orelse return;
    var pid_str: [12]u8 = undefined;

    // Ensure only one instance is running by acquiring an exclusive lock
    // on the PID file. Do not follow symlinks.
    ctx.pidfile_fd = c.open64(pf, open_Flags(.RDWR, true, true, true), @as(c.mode_t, 0o644));
    if (ctx.pidfile_fd < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_ERR, "Cannot open PID file {s}: {s}", .{ std.mem.span(pf), strerrorSlice(err) });
    }

    if (lockf(ctx.pidfile_fd, F_TLOCK, 0) < 0) {
        if (currentErrno() == enumInt(linux.E.ACCES) or currentErrno() == enumInt(linux.E.AGAIN)) {
            dolog(JENT_LOG_ERR, "PID file {s} is already locked by another process", .{std.mem.span(pf)});
        } else {
            const err = currentErrno();
            dolog(JENT_LOG_ERR, "Cannot lock PID file {s}: {s}", .{ std.mem.span(pf), strerrorSlice(err) });
        }
    }

    if (c.ftruncate64(ctx.pidfile_fd, 0) < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_ERR, "Cannot truncate PID file {s}: {s}", .{ std.mem.span(pf), strerrorSlice(err) });
    }

    // Write the PID into the file
    @memset(&pid_str, 0);
    const formatted = std.fmt.bufPrint(&pid_str, "{d}\n", .{c.getpid()}) catch {
        dolog(JENT_LOG_ERR, "Cannot format PID", .{});
        unreachable;
    };
    if (c.write(ctx.pidfile_fd, formatted.ptr, formatted.len) != @as(isize, @intCast(formatted.len))) {
        const err = currentErrno();
        dolog(JENT_LOG_ERR, "Cannot write to PID file {s}: {s}", .{ std.mem.span(pf), strerrorSlice(err) });
    }
}

/// Daemonize the process using a readiness pipe so the parent only exits
/// after the child has written the PID file and completed initial setup.
fn daemonize() void {
    var pipefd: [2]c_int = .{ -1, -1 };

    // Already a daemon (parent is init)
    if (c.getppid() == 1)
        return;

    if (c.pipe(&pipefd) < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_ERR, "Cannot create readiness pipe: {s}", .{strerrorSlice(err)});
    }

    // Flush stdio buffers before forking so buffered output is not duplicated
    _ = fflush(null);

    const pid = c.fork();
    if (pid < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_ERR, "Cannot fork daemon process: {s}", .{strerrorSlice(err)});
    }

    // Parent process: wait for the child to signal readiness via the pipe,
    // then exit with the appropriate status code.
    if (pid > 0) {
        var status_byte: u8 = 1;
        _ = c.close(pipefd[1]);
        const r = c.read(pipefd[0], @ptrCast(&status_byte), 1);
        _ = c.close(pipefd[0]);
        // Do not call dealloc() in parent -- the child owns the resources
        c._exit(if (r == 1 and status_byte == 0) 0 else 1);
    }

    _ = c.close(pipefd[0]);

    // Create a new SID for the child process
    if (c.setsid() < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_ERR, "Cannot assign new session ID to child process: {s}", .{strerrorSlice(err)});
    }

    // Change the current working directory to root so we do not prevent
    // filesystems from being unmounted.
    if (c.chdir("/") < 0) {
        const err = currentErrno();
        dolog(JENT_LOG_ERR, "Cannot change directory: {s}", .{strerrorSlice(err)});
    }

    create_pid_file(ctx.pidfile);

    // Redirect standard file descriptors to /dev/null
    _ = freopen("/dev/null", "r", stdin);
    _ = freopen("/dev/null", "w", stdout);
    _ = freopen("/dev/null", "w", stderr);

    // Signal readiness to the parent process
    const ok: u8 = 0;
    _ = c.write(pipefd[1], @ptrCast(&ok), 1);
    _ = c.close(pipefd[1]);

    // Refresh color detection since stdout is now /dev/null
    detect_color();
}

pub export fn main(argc: c_int, argv: [*]?[*:0]u8) callconv(.c) c_int {
    detect_color();

    parse_opts(argc, argv);

    if (Use_syslog) {
        c.openlog("jitterentropy-rngd", LOG_PID, LOG_DAEMON);
    }

    if (c.geteuid() != 0) {
        dolog(JENT_LOG_ERR, "Program must be started as root", .{});
    }

    alloc();

    if (ctx.oneshot) {
        gather_entropy_retry(true);
        notify_ready();
        dealloc();
        return 0;
    }

    if (ctx.daemonize_flag) {
        // Reallocate Jitter RNG after fork if internal timer is used because
        // pthreads do not survive fork()!
        dealloc_rng();
        daemonize();
        alloc_rng();
    } else {
        create_pid_file(ctx.pidfile);
    }

    install_term();
    install_alarm();

    notify_ready();

    if (kernver_ge(5, 18, 0)) {
        // Kernel 5.18+ reworked the `/dev/random` subsystem so `select()` on
        // `/dev/random` or `/dev/urandom` returns immediately as writable once
        // the CRNG is initialized. Polling with `select()` would spin in a
        // tight loop! Instead, use a two-phase sleep loop:
        //   Phase 1: `phase1_runs` bursts separated by `phase1_sleep` seconds
        //            to quickly seed the pool after boot.
        //   Phase 2: steady-state injection every `phase2_sleep` seconds.
        var phase1: c_uint = ctx.phase1_runs;

        while (true) {
            var rem: c.timespec = .{
                .sec = if (phase1 > 0) @intCast(ctx.phase1_sleep) else @intCast(ctx.phase2_sleep),
                .nsec = 0,
            };

            if (phase1 > 0)
                phase1 -= 1;

            while (c.nanosleep(&rem, &rem) < 0) {
                if (currentErrno() != enumInt(linux.E.INTR)) break;
                if (@atomicLoad(c.sig_atomic_t, &Term_pending, .seq_cst) != 0)
                    process_term();
            }

            if (@atomicLoad(c.sig_atomic_t, &Term_pending, .seq_cst) != 0)
                process_term();

            gather_entropy_retry(true);
        }
    } else {
        while (true) {
            select_fd();
        }
    }

    dealloc();
    return 0;
}
