// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const std = @import("std");

const RandData = opaque {};
const Mutex = opaque {};
const SeqFile = opaque {};
const SelftestInstance = opaque {};

const EINVAL = 22;
const ENOMEM = 12;
const EFAULT = 14;
const EIO = 5;
const ENODATA = 61;
const ENOTTY = 25;
const EOVERFLOW = 75;
const ERESTARTSYS = 512;

const JENT_DISABLE_STIR: u32 = 1 << 0;
const JENT_DISABLE_UNBIAS: u32 = 1 << 1;
const JENT_DISABLE_MEMORY_ACCESS: u32 = 1 << 2;
const JENT_FORCE_INTERNAL_TIMER: u32 = 1 << 3;
const JENT_DISABLE_INTERNAL_TIMER: u32 = 1 << 4;
const JENT_FORCE_FIPS: u32 = 1 << 5;
const JENT_NTG1: u32 = 1 << 6;
const JENT_CACHE_ALL: u32 = 1 << 7;
const JENT_FORCE_SECURE_MEM: u32 = 1 << 8;
const JENT_MAX_MEMSIZE_MASK: u32 = 0xf8000000;
const JENT_MAX_OSR: u32 = 20;
const JENT_MIN_OSR: u32 = 3;
const JENT_UUID_STRLEN = 37;
const JENT_STATUS_MAX_LEN = 4096;
const JENT_PERMANENT_FAILURE_SHIFT = 16;
const JENT_RCT_FAILURE: u32 = 1;
const JENT_APT_FAILURE: u32 = 2;
const JENT_LAG_FAILURE: u32 = 4;
const JENT_RCT_MEM_FAILURE: u32 = 8;

extern var jent_osr: u32;
extern var jent_flags: u32;
extern var jent_verbose: u32;
extern var jent_kparam_ntg1: bool;
extern var jent_kparam_force_fips: bool;
extern var jent_kparam_cache_all: bool;
extern var jent_kparam_max_memsize: u32;
extern var jent_kparam_selftest_interval: u32;

extern fn jent_version() callconv(.c) u32;
extern fn jent_entropy_init_ex(osr: u32, flags: u32) callconv(.c) c_int;
extern fn jent_set_fips_failure_callback(
    callback: ?*const fn (?*RandData, u32) callconv(.c) void,
) callconv(.c) c_int;
extern fn jent_selftest(ec: ?*RandData) callconv(.c) c_int;
extern fn jent_status(ec: ?*const RandData, buf: ?[*]u8, len: usize) callconv(.c) c_int;
extern fn jent_entropy_collector_uuid(ec: ?*const RandData, buf: ?[*]u8, len: usize) callconv(.c) c_int;
extern fn jent_entropy_collector_osr(ec: ?*const RandData) callconv(.c) u32;
extern fn jent_entropy_collector_flags(ec: ?*const RandData) callconv(.c) u32;
extern fn jent_entropy_collector_health_failure(ec: ?*const RandData) callconv(.c) u32;
extern fn jent_entropy_collector_reinitializations(ec: ?*const RandData) callconv(.c) u32;
extern fn jent_entropy_collector_memsize(ec: ?*const RandData) callconv(.c) usize;
extern fn jent_entropy_collector_hashloops(ec: ?*const RandData) callconv(.c) u32;
extern fn jent_entropy_collector_read_invocations(ec: ?*const RandData) callconv(.c) u64;
extern fn jent_entropy_collector_bytes_output(ec: ?*const RandData) callconv(.c) u64;

extern fn jent_kshim_fips_enabled() callconv(.c) c_int;
extern fn jent_kshim_max_memsize_kb() callconv(.c) u32;
extern fn jent_kshim_mutex_lock_interruptible(lock: *Mutex) callconv(.c) c_int;
extern fn jent_kshim_mutex_lock(lock: *Mutex) callconv(.c) void;
extern fn jent_kshim_mutex_unlock(lock: *Mutex) callconv(.c) void;
extern fn jent_kshim_copy_from_user(dst: *anyopaque, src: *const anyopaque, len: usize) callconv(.c) c_int;
extern fn jent_kshim_copy_to_user(dst: *anyopaque, src: *const anyopaque, len: usize) callconv(.c) c_int;
extern fn jent_kshim_kvzalloc(len: usize) callconv(.c) ?*anyopaque;
extern fn jent_kshim_kvfree_sensitive(ptr: ?*anyopaque, len: usize) callconv(.c) void;
extern fn jent_kshim_seq_write(seq: *SeqFile, data: [*]const u8, len: usize) callconv(.c) c_int;
extern fn jent_kshim_log(level: c_int, data: [*]const u8, len: usize) callconv(.c) void;
extern fn jent_kshim_panic_init(ret: c_int) callconv(.c) noreturn;
extern fn jent_kshim_panic_selftest(ret: c_int) callconv(.c) noreturn;
extern fn jent_kshim_ioctl_kind(cmd: c_uint) callconv(.c) c_int;
extern fn jent_kshim_proc_create() callconv(.c) c_int;
extern fn jent_kshim_proc_remove() callconv(.c) void;
extern fn jent_kshim_interface_enabled(which: c_uint) callconv(.c) c_uint;
extern fn jent_kshim_selftest_setup(
    st: *SelftestInstance,
    lock: *Mutex,
    ec: *?*RandData,
) callconv(.c) void;
extern fn jent_kshim_selftest_lock(st: *SelftestInstance) callconv(.c) *Mutex;
extern fn jent_kshim_selftest_ec(st: *SelftestInstance) callconv(.c) *?*RandData;
extern fn jent_kshim_selftest_failed(st: *SelftestInstance) callconv(.c) bool;
extern fn jent_kshim_selftest_set_failed(st: *SelftestInstance, failed: bool) callconv(.c) void;
extern fn jent_kshim_selftest_schedule(st: *SelftestInstance, seconds: u32) callconv(.c) void;
extern fn jent_kshim_selftest_cancel(st: *SelftestInstance) callconv(.c) void;
extern fn jent_kshim_selftest_interval_max() callconv(.c) u32;
extern fn jent_kshim_chardev_init() callconv(.c) c_int;
extern fn jent_kshim_chardev_exit() callconv(.c) void;
extern fn jent_kshim_hwrng_init() callconv(.c) c_int;
extern fn jent_kshim_hwrng_exit() callconv(.c) void;
extern fn jent_kshim_kcapi_init() callconv(.c) c_int;
extern fn jent_kshim_kcapi_exit() callconv(.c) void;
extern fn jent_kshim_testing_init() callconv(.c) c_int;
extern fn jent_kshim_testing_exit() callconv(.c) void;

fn log(comptime level: c_int, comptime fmt: []const u8, args: anytype) void {
    var buf: [768]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, fmt, args) catch return;
    jent_kshim_log(level, text.ptr, text.len);
}

fn seqPrint(seq: *SeqFile, comptime fmt: []const u8, args: anytype) c_int {
    var buf: [1024]u8 = undefined;
    const text = std.fmt.bufPrint(&buf, fmt, args) catch return -ENOMEM;
    return jent_kshim_seq_write(seq, text.ptr, text.len);
}

fn flagsMaxMemsize(flags: u32) u32 {
    return flags >> 27;
}

fn maxMemsizeFlags(field: u32) u32 {
    return field << 27;
}

fn flagsHashloop(flags: u32) u32 {
    return (flags >> 23) & 0xf;
}

fn ilog2(value_arg: u32) u32 {
    var value = value_arg;
    var result: u32 = 0;
    while (value > 1) : (value >>= 1) result += 1;
    return result;
}

fn healthFailure(ec: ?*RandData, failure: u32) callconv(.c) void {
    const bits = failure | (failure >> JENT_PERMANENT_FAILURE_SHIFT);
    var uuid: [JENT_UUID_STRLEN]u8 = @splat(0);
    if (ec) |collector| {
        if (jent_entropy_collector_uuid(collector, &uuid, uuid.len) != 0) uuid[0] = 0;
    }
    const name = if (uuid[0] != 0) std.mem.sliceTo(&uuid, 0) else "(starting)";
    log(2, "jitterentropy: {s} health test failure 0x{x}:{s}{s}{s}{s}, instance {s}\n", .{
        if (failure >> JENT_PERMANENT_FAILURE_SHIFT != 0) "permanent" else "intermittent",
        failure,
        if (bits & JENT_RCT_FAILURE != 0) " RCT" else "",
        if (bits & JENT_APT_FAILURE != 0) " APT" else "",
        if (bits & JENT_LAG_FAILURE != 0) " lag" else "",
        if (bits & JENT_RCT_MEM_FAILURE != 0) " RCT-mem" else "",
        name,
    });
}

pub export fn jent_mod_check_config(osr: u32, flags: u32, prefix: [*:0]const u8) callconv(.c) c_int {
    const p = std.mem.span(prefix);
    if (osr > JENT_MAX_OSR) {
        log(3, "jitterentropy: {s}osr {d} is above the maximum of {d}\n", .{ p, osr, JENT_MAX_OSR });
        return -EINVAL;
    }
    if (flags & JENT_FORCE_INTERNAL_TIMER != 0) {
        log(3, "jitterentropy: {s}flags force the internal timer, which is not available in the kernel\n", .{p});
        return -EINVAL;
    }
    if (flags & JENT_DISABLE_MEMORY_ACCESS != 0 and
        (flags & (JENT_NTG1 | JENT_FORCE_FIPS) != 0 or jent_kshim_fips_enabled() != 0))
    {
        log(3, "jitterentropy: {s}flags disable memory access, which FIPS and NTG.1 mode need\n", .{p});
        return -EINVAL;
    }
    return 0;
}

pub export fn jent_zig_mod_init() linksection(".init.text") callconv(.c) c_int {
    if (jent_kparam_ntg1) jent_flags |= JENT_NTG1;
    if (jent_kparam_force_fips) jent_flags |= JENT_FORCE_FIPS;
    if (jent_kparam_cache_all) jent_flags |= JENT_CACHE_ALL;

    var ret = jent_mod_check_config(jent_osr, jent_flags, "");
    if (ret != 0) return ret;

    const max_kb = jent_kshim_max_memsize_kb();
    if (jent_kparam_max_memsize != 0) {
        const size = jent_kparam_max_memsize;
        if (size & (size - 1) != 0 or size > max_kb) {
            log(3, "jitterentropy: max_memsize {d} kB is not a power of two of at most {d} kB\n", .{ size, max_kb });
            return -EINVAL;
        }
        jent_flags &= ~JENT_MAX_MEMSIZE_MASK;
        jent_flags |= maxMemsizeFlags(ilog2(size) + 1);
    } else if (flagsMaxMemsize(jent_flags) > ilog2(max_kb) + 1) {
        log(3, "jitterentropy: flags select a memory size above {d} kB\n", .{max_kb});
        return -EINVAL;
    }

    ret = jent_set_fips_failure_callback(&healthFailure);
    if (ret != 0) return if (ret < 0) ret else -EINVAL;
    ret = jent_entropy_init_ex(jent_osr, jent_flags);
    if (ret != 0) {
        if (jent_kshim_fips_enabled() != 0) jent_kshim_panic_init(ret);
        log(1, "jitterentropy: initialization failed with host not compliant with requirements: {d}\n", .{ret});
        return -EFAULT;
    }

    jent_selftest_init();
    ret = jent_proc_init();
    if (ret != 0) return ret;

    ret = jent_kshim_hwrng_init();
    if (ret != 0) {
        jent_proc_exit();
        return ret;
    }
    ret = jent_kshim_kcapi_init();
    if (ret != 0) {
        jent_kshim_hwrng_exit();
        jent_proc_exit();
        return ret;
    }
    if (jent_kshim_chardev_init() != 0)
        log(2, "jitterentropy: character device unavailable, continuing without it\n", .{});
    if (jent_kshim_testing_init() != 0)
        log(2, "jitterentropy: raw entropy test interface unavailable, continuing without it\n", .{});
    return 0;
}

pub export fn jent_zig_mod_exit() linksection(".exit.text") callconv(.c) void {
    jent_kshim_chardev_exit();
    jent_kshim_kcapi_exit();
    jent_kshim_testing_exit();
    jent_kshim_hwrng_exit();
    jent_proc_exit();
}

pub export fn jent_ioctl_is_field(cmd: c_uint) callconv(.c) bool {
    return jent_kshim_ioctl_kind(cmd) != 0;
}

const IoctlValue = extern union {
    u32_value: u32,
    u64_value: u64,
    uuid: [JENT_UUID_STRLEN]u8,
    output: extern struct { invocations: u64, bytes: u64 },
};

pub export fn jent_ioctl_field_to_user(
    lock: *Mutex,
    ec_ptr: *?*RandData,
    cmd: c_uint,
    arg: *anyopaque,
) callconv(.c) c_long {
    var value: IoctlValue = std.mem.zeroes(IoctlValue);
    var size: usize = 0;
    const kind = jent_kshim_ioctl_kind(cmd);
    if (kind == 0) return -ENOTTY;
    if (jent_kshim_mutex_lock_interruptible(lock) != 0) return -ERESTARTSYS;

    const ec = ec_ptr.*;
    if (kind == 2) {
        value.u32_value = jent_version();
        size = @sizeOf(u32);
    } else {
        const collector = ec orelse {
            jent_kshim_mutex_unlock(lock);
            return -ENODATA;
        };
        switch (kind) {
            1 => {
                if (jent_entropy_collector_uuid(collector, &value.uuid, value.uuid.len) != 0) {
                    jent_kshim_mutex_unlock(lock);
                    return -EIO;
                }
                if (value.uuid[0] == 0) {
                    jent_kshim_mutex_unlock(lock);
                    return -ENODATA;
                }
                size = value.uuid.len;
            },
            3 => {
                value.u32_value = jent_entropy_collector_osr(collector);
                size = @sizeOf(u32);
            },
            4 => {
                value.u32_value = jent_entropy_collector_flags(collector);
                size = @sizeOf(u32);
            },
            5 => {
                value.u32_value = jent_entropy_collector_health_failure(collector);
                size = @sizeOf(u32);
            },
            6 => {
                value.output = .{
                    .invocations = jent_entropy_collector_read_invocations(collector),
                    .bytes = jent_entropy_collector_bytes_output(collector),
                };
                size = @sizeOf(@TypeOf(value.output));
            },
            7 => {
                value.u32_value = jent_entropy_collector_reinitializations(collector);
                size = @sizeOf(u32);
            },
            8 => {
                value.u64_value = jent_entropy_collector_memsize(collector);
                size = @sizeOf(u64);
            },
            9 => {
                value.u32_value = jent_entropy_collector_hashloops(collector);
                size = @sizeOf(u32);
            },
            else => {
                jent_kshim_mutex_unlock(lock);
                return -ENOTTY;
            },
        }
    }
    jent_kshim_mutex_unlock(lock);
    if (jent_kshim_copy_to_user(arg, &value, size) != 0) return -EFAULT;
    return 0;
}

const StatusIoctl = extern struct {
    buf: u64,
    length: u32,
};

fn statusRender(lock: *Mutex, ec_ptr: *?*RandData, buf: [*]u8) c_int {
    if (jent_kshim_mutex_lock_interruptible(lock) != 0) return -ERESTARTSYS;
    const ret = if (ec_ptr.*) |ec| jent_status(ec, buf, JENT_STATUS_MAX_LEN) else -1;
    jent_kshim_mutex_unlock(lock);
    return if (ret != 0) -EIO else 0;
}

pub export fn jent_status_to_user(
    lock: *Mutex,
    ec_ptr: *?*RandData,
    arg: *anyopaque,
) callconv(.c) c_long {
    var status: StatusIoctl = undefined;
    if (jent_kshim_copy_from_user(&status, arg, @sizeOf(StatusIoctl)) != 0) return -EFAULT;
    const raw = jent_kshim_kvzalloc(JENT_STATUS_MAX_LEN) orelse return -ENOMEM;
    const buf: [*]u8 = @ptrCast(raw);
    defer jent_kshim_kvfree_sensitive(raw, JENT_STATUS_MAX_LEN);
    const rendered = statusRender(lock, ec_ptr, buf);
    if (rendered != 0) return rendered;
    const len = std.mem.len(@as([*:0]u8, @ptrCast(buf))) + 1;
    if (status.length < len) {
        status.length = @intCast(len);
        if (jent_kshim_copy_to_user(arg, &status, @sizeOf(StatusIoctl)) != 0) return -EFAULT;
        return -EOVERFLOW;
    }
    const user_buf: *anyopaque = @ptrFromInt(status.buf);
    if (jent_kshim_copy_to_user(user_buf, buf, len) != 0) return -EFAULT;
    status.length = @intCast(len);
    if (jent_kshim_copy_to_user(arg, &status, @sizeOf(StatusIoctl)) != 0) return -EFAULT;
    return 0;
}

pub export fn jent_status_seq_show(
    seq: *SeqFile,
    lock: *Mutex,
    ec_ptr: *?*RandData,
) callconv(.c) c_int {
    const raw = jent_kshim_kvzalloc(JENT_STATUS_MAX_LEN) orelse return -ENOMEM;
    const buf: [*]u8 = @ptrCast(raw);
    defer jent_kshim_kvfree_sensitive(raw, JENT_STATUS_MAX_LEN);
    const ret = statusRender(lock, ec_ptr, buf);
    if (ret != 0) return ret;
    return jent_kshim_seq_write(seq, buf, std.mem.len(@as([*:0]u8, @ptrCast(buf))));
}

pub export fn jent_status_to_log(
    lock: ?*Mutex,
    ec_ptr: *?*RandData,
) callconv(.c) c_int {
    const raw = jent_kshim_kvzalloc(JENT_STATUS_MAX_LEN) orelse return -ENOMEM;
    const buf: [*]u8 = @ptrCast(raw);
    defer jent_kshim_kvfree_sensitive(raw, JENT_STATUS_MAX_LEN);
    if (lock) |held| jent_kshim_mutex_lock(held);
    const ret = if (ec_ptr.*) |ec| jent_status(ec, buf, JENT_STATUS_MAX_LEN) else 0;
    if (lock) |held| jent_kshim_mutex_unlock(held);
    if (ret != 0 or buf[0] == 0) return ret;
    const text = std.mem.span(@as([*:0]u8, @ptrCast(buf)));
    var lines = std.mem.splitScalar(u8, text, '\n');
    while (lines.next()) |line| {
        if (line.len != 0) jent_kshim_log(0, line.ptr, line.len);
    }
    return ret;
}

var selftest_runs: u64 = 0;
var selftest_failures: u64 = 0;

fn selftestExecute(ec: ?*RandData) c_int {
    const ret = jent_selftest(ec);
    _ = @atomicRmw(u64, &selftest_runs, .Add, 1, .seq_cst);
    if (ret == 0) {
        if (jent_verbose != 0) log(1, "jitterentropy: cryptographic self test passed\n", .{});
        return 0;
    }
    _ = @atomicRmw(u64, &selftest_failures, .Add, 1, .seq_cst);
    if (jent_kshim_fips_enabled() != 0) jent_kshim_panic_selftest(ret);
    log(3, "jitterentropy: cryptographic self test failed: {d}\n", .{ret});
    return -EFAULT;
}

pub export fn jent_selftest_instance_init(
    st: *SelftestInstance,
    lock: *Mutex,
    ec: *?*RandData,
) callconv(.c) void {
    jent_kshim_selftest_setup(st, lock, ec);
    if (jent_kparam_selftest_interval != 0)
        jent_kshim_selftest_schedule(st, jent_kparam_selftest_interval);
}

pub export fn jent_selftest_instance_exit(st: *SelftestInstance) callconv(.c) void {
    jent_kshim_selftest_cancel(st);
}

pub export fn jent_zig_selftest_work(st: *SelftestInstance) callconv(.c) void {
    const lock = jent_kshim_selftest_lock(st);
    jent_kshim_mutex_lock(lock);
    if (!jent_kshim_selftest_failed(st) and selftestExecute(jent_kshim_selftest_ec(st).*) != 0)
        jent_kshim_selftest_set_failed(st, true);
    const failed = jent_kshim_selftest_failed(st);
    jent_kshim_mutex_unlock(lock);
    if (!failed) jent_kshim_selftest_schedule(st, jent_kparam_selftest_interval);
}

pub export fn jent_selftest_instance_run(st: *SelftestInstance) callconv(.c) c_int {
    const lock = jent_kshim_selftest_lock(st);
    if (jent_kshim_mutex_lock_interruptible(lock) != 0) return -ERESTARTSYS;
    defer jent_kshim_mutex_unlock(lock);
    if (jent_kshim_selftest_failed(st)) return -EFAULT;
    const ret = selftestExecute(jent_kshim_selftest_ec(st).*);
    if (ret != 0) jent_kshim_selftest_set_failed(st, true);
    return ret;
}

pub export fn jent_selftest_run_now() callconv(.c) c_int {
    return selftestExecute(null);
}

pub export fn jent_selftest_init() callconv(.c) void {
    if (jent_kparam_selftest_interval == 0) {
        log(1, "jitterentropy: periodic cryptographic self test disabled\n", .{});
        return;
    }
    const max = jent_kshim_selftest_interval_max();
    if (jent_kparam_selftest_interval > max) {
        log(2, "jitterentropy: selftest_interval {d} too large, using {d} seconds\n", .{ jent_kparam_selftest_interval, max });
        jent_kparam_selftest_interval = max;
    }
    log(1, "jitterentropy: cryptographic self test scheduled every {d} seconds for every instance\n", .{jent_kparam_selftest_interval});
}

const SelftestStats = extern struct {
    interval: u32,
    runs: u64,
    failures: u64,
};

pub export fn jent_selftest_get_stats(stats: *SelftestStats) callconv(.c) void {
    stats.* = .{
        .interval = jent_kparam_selftest_interval,
        .runs = @atomicLoad(u64, &selftest_runs, .seq_cst),
        .failures = @atomicLoad(u64, &selftest_failures, .seq_cst),
    };
}

var open_instances: c_int = 0;
var cumulative_opens: u64 = 0;

pub export fn jent_proc_instance_inc(max: u32) callconv(.c) bool {
    var current = @atomicLoad(c_int, &open_instances, .seq_cst);
    while (true) {
        if (max != 0 and @as(u32, @intCast(@max(current, 0))) >= @min(max, std.math.maxInt(c_int)))
            return false;
        if (@cmpxchgWeak(c_int, &open_instances, current, current + 1, .seq_cst, .seq_cst)) |observed| {
            current = observed;
        } else break;
    }
    _ = @atomicRmw(u64, &cumulative_opens, .Add, 1, .seq_cst);
    return true;
}

pub export fn jent_proc_instance_dec() callconv(.c) void {
    _ = @atomicRmw(c_int, &open_instances, .Sub, 1, .seq_cst);
}

pub export fn jent_proc_init() callconv(.c) c_int {
    return jent_kshim_proc_create();
}

pub export fn jent_proc_exit() callconv(.c) void {
    jent_kshim_proc_remove();
}

pub export fn jent_zig_proc_statistics_show(seq: *SeqFile) callconv(.c) c_int {
    return seqPrint(seq, "{{\n\t\"charDevice\": {{\n\t\t\"openInstances\": {d},\n\t\t\"cumulativeOpens\": {d}\n\t}},\n\t\"selfTest\": {{\n\t\t\"intervalSeconds\": {d},\n\t\t\"runs\": {d},\n\t\t\"failures\": {d}\n\t}}\n}}\n", .{
        @atomicLoad(c_int, &open_instances, .seq_cst),
        @atomicLoad(u64, &cumulative_opens, .seq_cst),
        jent_kparam_selftest_interval,
        @atomicLoad(u64, &selftest_runs, .seq_cst),
        @atomicLoad(u64, &selftest_failures, .seq_cst),
    });
}

pub export fn jent_zig_proc_version_show(seq: *SeqFile) callconv(.c) c_int {
    return seqPrint(seq, "3.8.0\n", .{});
}

pub export fn jent_zig_proc_flags_raw_show(seq: *SeqFile) callconv(.c) c_int {
    return seqPrint(seq, "0x{x:0>8}\n", .{jent_flags});
}

pub export fn jent_zig_proc_osr_show(seq: *SeqFile) callconv(.c) c_int {
    return seqPrint(seq, "{d}\n", .{if (jent_osr < JENT_MIN_OSR) JENT_MIN_OSR else jent_osr});
}

pub export fn jent_zig_proc_ntg1_show(seq: *SeqFile) callconv(.c) c_int {
    return seqPrint(seq, "{d}\n", .{@intFromBool(jent_flags & JENT_NTG1 != 0)});
}

pub export fn jent_zig_proc_fips_show(seq: *SeqFile) callconv(.c) c_int {
    return seqPrint(seq, "{d}\n", .{@intFromBool(jent_flags & (JENT_FORCE_FIPS | JENT_NTG1) != 0 or jent_kshim_fips_enabled() != 0)});
}

pub export fn jent_zig_proc_interface_show(seq: *SeqFile, which: c_uint) callconv(.c) c_int {
    return seqPrint(seq, "{d}\n", .{jent_kshim_interface_enabled(which)});
}

pub export fn jent_zig_proc_flags_show(seq: *SeqFile) callconv(.c) c_int {
    var ret = seqPrint(seq, "{s:<29}0x{x:0>8}\n", .{ "flags:", jent_flags });
    if (ret != 0) return ret;
    const bits = [_]struct { bit: u32, label: []const u8, unused: bool }{
        .{ .bit = JENT_DISABLE_STIR, .label = "JENT_DISABLE_STIR:", .unused = true },
        .{ .bit = JENT_DISABLE_UNBIAS, .label = "JENT_DISABLE_UNBIAS:", .unused = true },
        .{ .bit = JENT_DISABLE_MEMORY_ACCESS, .label = "JENT_DISABLE_MEMORY_ACCESS:", .unused = false },
        .{ .bit = JENT_DISABLE_INTERNAL_TIMER, .label = "JENT_DISABLE_INTERNAL_TIMER:", .unused = false },
        .{ .bit = JENT_FORCE_FIPS, .label = "JENT_FORCE_FIPS:", .unused = false },
        .{ .bit = JENT_NTG1, .label = "JENT_NTG1:", .unused = false },
        .{ .bit = JENT_CACHE_ALL, .label = "JENT_CACHE_ALL:", .unused = false },
        .{ .bit = JENT_FORCE_SECURE_MEM, .label = "JENT_FORCE_SECURE_MEM:", .unused = false },
    };
    for (bits) |entry| {
        ret = seqPrint(seq, "{s:<29}{s}\n", .{
            entry.label,
            if (jent_flags & entry.bit == 0) "off" else if (entry.unused) "on (no effect)" else "on",
        });
        if (ret != 0) return ret;
    }
    const memsize = flagsMaxMemsize(jent_flags);
    if (memsize == 0)
        ret = seqPrint(seq, "{s:<29}auto (derived from cache size)\n", .{"max memory size:"})
    else if (memsize <= 10)
        ret = seqPrint(seq, "{s:<29}{d} kB\n", .{ "max memory size:", @as(u32, 1) << @intCast(memsize - 1) })
    else if (memsize <= 20)
        ret = seqPrint(seq, "{s:<29}{d} MB\n", .{ "max memory size:", @as(u32, 1) << @intCast(memsize - 11) })
    else
        ret = seqPrint(seq, "{s:<29}invalid ({d})\n", .{ "max memory size:", memsize });
    if (ret != 0) return ret;
    const hashloop = flagsHashloop(jent_flags);
    if (hashloop == 0)
        return seqPrint(seq, "{s:<29}default\n", .{"hash loop count:"});
    if (hashloop <= 8)
        return seqPrint(seq, "{s:<29}{d}\n", .{ "hash loop count:", @as(u32, 1) << @intCast(hashloop - 1) });
    return seqPrint(seq, "{s:<29}invalid ({d})\n", .{ "hash loop count:", hashloop });
}
