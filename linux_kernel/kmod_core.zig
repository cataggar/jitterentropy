// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const std = @import("std");
const build_options = @import("kmod_build_options");

const RandData = opaque {};
const Mutex = opaque {};
const SeqFile = opaque {};
const SelftestInstance = opaque {};
const File = opaque {};
const ChardevCtx = opaque {};
const HwrngCtx = opaque {};
const KcapiCtx = opaque {};
const TestingCtx = opaque {};
const Record = opaque {};

const EINVAL = 22;
const ENOMEM = 12;
const EFAULT = 14;
const EIO = 5;
const ENODATA = 61;
const ENOTTY = 25;
const EOVERFLOW = 75;
const ERESTARTSYS = 512;
const EAGAIN = 11;
const ENFILE = 23;
const EPERM = 1;

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
extern fn jent_entropy_collector_alloc(osr: u32, flags: u32) callconv(.c) ?*RandData;
extern fn jent_entropy_collector_free(ec: ?*RandData) callconv(.c) void;
extern fn jent_read_entropy(ec: ?*RandData, data: ?[*]u8, len: usize) callconv(.c) isize;
extern fn jent_read_entropy_safe(ec: *?*RandData, data: ?[*]u8, len: usize) callconv(.c) isize;

extern var jent_kparam_max_instances: u32;
extern var jent_kparam_hwrng_quality: u32;
extern var jent_kparam_testing_osr: u32;
extern var jent_kparam_testing_flags: u32;

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

    if (build_options.hwrng) {
        ret = hwrngInit();
        if (ret != 0) {
            jent_proc_exit();
            return ret;
        }
    }
    if (build_options.kcapi) {
        ret = jent_kshim_kcapi_register();
        if (ret != 0) {
            if (build_options.hwrng) hwrngExit();
            jent_proc_exit();
            return ret;
        }
    }
    if (build_options.chardev and jent_kshim_chardev_register() != 0)
        log(2, "jitterentropy: character device unavailable, continuing without it\n", .{});
    if (build_options.testinterface and jent_kshim_testing_register() != 0)
        log(2, "jitterentropy: raw entropy test interface unavailable, continuing without it\n", .{});
    return 0;
}

pub export fn jent_zig_mod_exit() linksection(".exit.text") callconv(.c) void {
    if (build_options.chardev) jent_kshim_chardev_unregister();
    if (build_options.kcapi) jent_kshim_kcapi_unregister();
    if (build_options.testinterface) jent_kshim_testing_unregister();
    if (build_options.hwrng) hwrngExit();
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

extern fn jent_kshim_mutex_init(lock: *Mutex) callconv(.c) void;
extern fn jent_kshim_mutex_destroy(lock: *Mutex) callconv(.c) void;
extern fn jent_kshim_mutex_trylock(lock: *Mutex) callconv(.c) bool;
extern fn jent_kshim_signal_pending() callconv(.c) bool;
extern fn jent_kshim_need_resched() callconv(.c) bool;
extern fn jent_kshim_cond_resched() callconv(.c) void;
extern fn jent_kshim_capable_admin() callconv(.c) bool;
extern fn jent_kshim_capable_resource() callconv(.c) bool;
extern fn jent_kshim_map_read_error(ret: isize, user: bool) callconv(.c) c_int;
extern fn jent_kshim_memzero(ptr: *anyopaque, len: usize) callconv(.c) void;
extern fn jent_kshim_copy_to_user_count(dst: *anyopaque, src: *const anyopaque, len: usize) callconv(.c) usize;

extern fn jent_kshim_chardev_ctx_alloc() callconv(.c) ?*ChardevCtx;
extern fn jent_kshim_chardev_ctx_free(ctx: *ChardevCtx) callconv(.c) void;
extern fn jent_kshim_chardev_lock(ctx: *ChardevCtx) callconv(.c) *Mutex;
extern fn jent_kshim_chardev_ec(ctx: *ChardevCtx) callconv(.c) *?*RandData;
extern fn jent_kshim_chardev_selftest(ctx: *ChardevCtx) callconv(.c) *SelftestInstance;
extern fn jent_kshim_chardev_file_ctx(file: *File) callconv(.c) ?*ChardevCtx;
extern fn jent_kshim_chardev_file_set_ctx(file: *File, ctx: ?*ChardevCtx) callconv(.c) void;
extern fn jent_kshim_file_nonblock(file: *File) callconv(.c) bool;
extern fn jent_kshim_chardev_proc_create(ctx: *ChardevCtx, name: [*:0]const u8) callconv(.c) void;
extern fn jent_kshim_chardev_proc_remove(ctx: *ChardevCtx) callconv(.c) void;
extern fn jent_kshim_chardev_register() callconv(.c) c_int;
extern fn jent_kshim_chardev_unregister() callconv(.c) void;

pub export fn jent_zig_chardev_open(file: *File) callconv(.c) c_int {
    if (!build_options.chardev) return -ENOTTY;
    if (!jent_proc_instance_inc(jent_kparam_max_instances) and
        (!jent_kshim_capable_resource() or !jent_proc_instance_inc(0)))
        return -ENFILE;
    const ctx = jent_kshim_chardev_ctx_alloc() orelse {
        jent_proc_instance_dec();
        return -ENOMEM;
    };
    const ec = jent_kshim_chardev_ec(ctx);
    ec.* = jent_entropy_collector_alloc(jent_osr, jent_flags) orelse {
        jent_kshim_chardev_ctx_free(ctx);
        jent_proc_instance_dec();
        return -ENOMEM;
    };
    jent_kshim_chardev_file_set_ctx(file, ctx);
    jent_selftest_instance_init(jent_kshim_chardev_selftest(ctx), jent_kshim_chardev_lock(ctx), ec);
    var uuid: [JENT_UUID_STRLEN]u8 = @splat(0);
    if (jent_entropy_collector_uuid(ec.*, &uuid, uuid.len) == 0)
        jent_kshim_chardev_proc_create(ctx, @ptrCast(&uuid));
    return 0;
}

pub export fn jent_zig_chardev_release(file: *File) callconv(.c) c_int {
    if (!build_options.chardev) return 0;
    const ctx = jent_kshim_chardev_file_ctx(file) orelse return 0;
    jent_kshim_chardev_proc_remove(ctx);
    jent_selftest_instance_exit(jent_kshim_chardev_selftest(ctx));
    jent_entropy_collector_free(jent_kshim_chardev_ec(ctx).*);
    jent_kshim_chardev_file_set_ctx(file, null);
    jent_kshim_chardev_ctx_free(ctx);
    jent_proc_instance_dec();
    return 0;
}

pub export fn jent_zig_chardev_read(file: *File, user_buf: *anyopaque, requested: usize) callconv(.c) isize {
    if (!build_options.chardev) return -ENOTTY;
    const ctx = jent_kshim_chardev_file_ctx(file) orelse return -EFAULT;
    if (requested == 0) return 0;
    var tmp: [32]u8 = undefined;
    defer jent_kshim_memzero(&tmp, tmp.len);
    var remaining = if (jent_kshim_file_nonblock(file)) @min(requested, tmp.len) else requested;
    var done: isize = 0;
    var dst: [*]u8 = @ptrCast(user_buf);
    while (remaining != 0) {
        const count = @min(remaining, tmp.len);
        const nonblock = jent_kshim_file_nonblock(file);
        const lock = jent_kshim_chardev_lock(ctx);
        if (nonblock) {
            if (!jent_kshim_mutex_trylock(lock)) return if (done == 0) -EAGAIN else done;
        } else if (jent_kshim_mutex_lock_interruptible(lock) != 0) {
            return if (done == 0) -ERESTARTSYS else done;
        }
        const rc = if (nonblock)
            jent_read_entropy(jent_kshim_chardev_ec(ctx).*, &tmp, count)
        else
            jent_read_entropy_safe(jent_kshim_chardev_ec(ctx), &tmp, count);
        jent_kshim_mutex_unlock(lock);
        if (rc < 0) return if (done == 0) jent_kshim_map_read_error(rc, true) else done;
        if (jent_kshim_copy_to_user(dst, &tmp, @intCast(rc)) != 0)
            return if (done == 0) -EFAULT else done;
        const generated: usize = @intCast(rc);
        remaining -= generated;
        dst += generated;
        done += rc;
        if (jent_kshim_signal_pending()) return if (done == 0) -ERESTARTSYS else done;
        if (jent_kshim_need_resched()) jent_kshim_cond_resched();
    }
    return done;
}

pub export fn jent_zig_chardev_ioctl(file: *File, cmd: c_uint, arg: *anyopaque) callconv(.c) c_long {
    if (!build_options.chardev) return -ENOTTY;
    const ctx = jent_kshim_chardev_file_ctx(file) orelse return -EFAULT;
    const kind = jent_kshim_ioctl_kind(cmd);
    if (kind == 10) return jent_status_to_user(jent_kshim_chardev_lock(ctx), jent_kshim_chardev_ec(ctx), arg);
    if (kind == 12) {
        if (!jent_kshim_capable_admin()) return -EPERM;
        return jent_selftest_instance_run(jent_kshim_chardev_selftest(ctx));
    }
    if (kind >= 1 and kind <= 9)
        return jent_ioctl_field_to_user(jent_kshim_chardev_lock(ctx), jent_kshim_chardev_ec(ctx), cmd, arg);
    return -ENOTTY;
}

extern fn jent_kshim_hwrng_ctx() callconv(.c) *HwrngCtx;
extern fn jent_kshim_hwrng_lock(ctx: *HwrngCtx) callconv(.c) *Mutex;
extern fn jent_kshim_hwrng_ec(ctx: *HwrngCtx) callconv(.c) *?*RandData;
extern fn jent_kshim_hwrng_selftest(ctx: *HwrngCtx) callconv(.c) *SelftestInstance;
extern fn jent_kshim_hwrng_register(quality: u32) callconv(.c) c_int;
extern fn jent_kshim_hwrng_unregister() callconv(.c) void;
extern fn jent_kshim_hwrng_report_promotion() callconv(.c) void;

fn hwrngInit() c_int {
    const ctx = jent_kshim_hwrng_ctx();
    const lock = jent_kshim_hwrng_lock(ctx);
    jent_kshim_mutex_init(lock);
    const ec = jent_kshim_hwrng_ec(ctx);
    ec.* = jent_entropy_collector_alloc(jent_osr, jent_flags) orelse {
        jent_kshim_mutex_destroy(lock);
        return -ENOMEM;
    };
    jent_selftest_instance_init(jent_kshim_hwrng_selftest(ctx), lock, ec);
    const ret = jent_kshim_hwrng_register(jent_kparam_hwrng_quality);
    if (ret != 0) {
        jent_selftest_instance_exit(jent_kshim_hwrng_selftest(ctx));
        jent_entropy_collector_free(ec.*);
        ec.* = null;
        jent_kshim_mutex_destroy(lock);
    } else {
        jent_kshim_mutex_lock(lock);
        jent_kshim_hwrng_report_promotion();
        jent_kshim_mutex_unlock(lock);
    }
    return ret;
}

fn hwrngExit() void {
    const ctx = jent_kshim_hwrng_ctx();
    jent_kshim_hwrng_unregister();
    jent_selftest_instance_exit(jent_kshim_hwrng_selftest(ctx));
    jent_entropy_collector_free(jent_kshim_hwrng_ec(ctx).*);
    jent_kshim_hwrng_ec(ctx).* = null;
    jent_kshim_mutex_destroy(jent_kshim_hwrng_lock(ctx));
}

pub export fn jent_zig_hwrng_read(ctx: *HwrngCtx, data: [*]u8, max: usize, wait: bool) callconv(.c) c_int {
    if (!build_options.hwrng) return -ENOTTY;
    if (max == 0) return 0;
    const lock = jent_kshim_hwrng_lock(ctx);
    if (!wait) {
        if (!jent_kshim_mutex_trylock(lock)) return 0;
    } else if (jent_kshim_mutex_lock_interruptible(lock) != 0) return -ERESTARTSYS;
    jent_kshim_hwrng_report_promotion();
    const rc = if (wait)
        jent_read_entropy_safe(jent_kshim_hwrng_ec(ctx), data, max)
    else
        jent_read_entropy(jent_kshim_hwrng_ec(ctx).*, data, max);
    jent_kshim_mutex_unlock(lock);
    return if (rc < 0) jent_kshim_map_read_error(rc, true) else @intCast(rc);
}

extern fn jent_kshim_kcapi_lock(ctx: *KcapiCtx) callconv(.c) *Mutex;
extern fn jent_kshim_kcapi_ec(ctx: *KcapiCtx) callconv(.c) *?*RandData;
extern fn jent_kshim_kcapi_selftest(ctx: *KcapiCtx) callconv(.c) *SelftestInstance;
extern fn jent_kshim_kcapi_log_allowed() callconv(.c) bool;
extern fn jent_kshim_kcapi_register() callconv(.c) c_int;
extern fn jent_kshim_kcapi_unregister() callconv(.c) void;

fn kcapiLog(ctx: *KcapiCtx) void {
    if (jent_verbose != 0 and jent_kshim_kcapi_log_allowed())
        _ = jent_status_to_log(jent_kshim_kcapi_lock(ctx), jent_kshim_kcapi_ec(ctx));
}

pub export fn jent_zig_kcapi_tfm_init(ctx: *KcapiCtx) callconv(.c) c_int {
    if (!build_options.kcapi) return -ENOTTY;
    const ec = jent_kshim_kcapi_ec(ctx);
    ec.* = jent_entropy_collector_alloc(jent_osr, jent_flags) orelse return -ENOMEM;
    jent_selftest_instance_init(jent_kshim_kcapi_selftest(ctx), jent_kshim_kcapi_lock(ctx), ec);
    kcapiLog(ctx);
    return 0;
}

pub export fn jent_zig_kcapi_tfm_cleanup(ctx: *KcapiCtx) callconv(.c) void {
    if (!build_options.kcapi) return;
    jent_selftest_instance_exit(jent_kshim_kcapi_selftest(ctx));
    const lock = jent_kshim_kcapi_lock(ctx);
    jent_kshim_mutex_lock(lock);
    jent_entropy_collector_free(jent_kshim_kcapi_ec(ctx).*);
    jent_kshim_kcapi_ec(ctx).* = null;
    jent_kshim_mutex_unlock(lock);
}

pub export fn jent_zig_kcapi_random(ctx: *KcapiCtx, data: [*]u8, len: c_uint) callconv(.c) c_int {
    if (!build_options.kcapi) return -ENOTTY;
    const lock = jent_kshim_kcapi_lock(ctx);
    jent_kshim_mutex_lock(lock);
    const before = jent_kshim_kcapi_ec(ctx).*;
    const rc = jent_read_entropy_safe(jent_kshim_kcapi_ec(ctx), data, len);
    const reallocated = before != jent_kshim_kcapi_ec(ctx).*;
    jent_kshim_mutex_unlock(lock);
    if (jent_verbose != 0 and reallocated) kcapiLog(ctx);
    return if (rc < 0) jent_kshim_map_read_error(rc, false) else 0;
}

extern fn jent_kshim_testing_lock() callconv(.c) *Mutex;
extern fn jent_kshim_testing_locked_down() callconv(.c) bool;
extern fn jent_kshim_testing_ctx_alloc() callconv(.c) ?*TestingCtx;
extern fn jent_kshim_testing_ctx_free(ctx: *TestingCtx) callconv(.c) void;
extern fn jent_kshim_testing_file_ctx(file: *File) callconv(.c) ?*TestingCtx;
extern fn jent_kshim_testing_file_set_ctx(file: *File, ctx: ?*TestingCtx) callconv(.c) void;
extern fn jent_kshim_testing_record(ctx: *TestingCtx) callconv(.c) *?*Record;
extern fn jent_kshim_testing_ec(ctx: *TestingCtx) callconv(.c) *?*RandData;
extern fn jent_kshim_testing_loop_count(ctx: *TestingCtx) callconv(.c) *u64;
extern fn jent_kshim_testing_register() callconv(.c) c_int;
extern fn jent_kshim_testing_unregister() callconv(.c) void;
extern fn jent_record_alloc(out: *?*Record, osr: u32, flags: u32, source: u32) callconv(.c) c_int;
extern fn jent_record_free(rec: ?*Record) callconv(.c) void;
extern fn jent_record_prime(rec: *Record, loop_count: u32) callconv(.c) void;
extern fn jent_record_sample(rec: *Record, loop_count: u32) callconv(.c) u64;
extern fn jent_record_collector(rec: *Record) callconv(.c) *RandData;

var testing_logged_osr: u32 = std.math.maxInt(u32);
var testing_logged_flags: u32 = std.math.maxInt(u32);

pub export fn jent_zig_testing_open(file: *File) callconv(.c) c_int {
    if (!build_options.testinterface) return -ENOTTY;
    if (jent_kshim_testing_locked_down()) return -EPERM;
    const ctx = jent_kshim_testing_ctx_alloc() orelse return -ENOMEM;
    const flags = jent_kparam_testing_flags;
    const osr = jent_kparam_testing_osr;
    const lib_flags = flags & ~(@as(u32, 1) << 15 | @as(u32, 1) << 16);
    const source: u32 = if (flags & (@as(u32, 1) << 15) != 0) 1 else if (flags & (@as(u32, 1) << 16) != 0) 2 else 0;
    const config = jent_mod_check_config(osr, lib_flags, "testing_");
    if (config != 0) {
        jent_kshim_testing_ctx_free(ctx);
        return config;
    }
    const rc = jent_record_alloc(jent_kshim_testing_record(ctx), osr, lib_flags, source);
    if (rc != 0) {
        jent_kshim_testing_ctx_free(ctx);
        return if (rc == 1) -EINVAL else if (rc == 5) -EIO else -ENOMEM;
    }
    jent_kshim_testing_ec(ctx).* = jent_record_collector(jent_kshim_testing_record(ctx).* orelse unreachable);
    if (jent_verbose != 0) {
        const lock = jent_kshim_testing_lock();
        if (jent_kshim_mutex_lock_interruptible(lock) != 0) {
            jent_record_free(jent_kshim_testing_record(ctx).*);
            jent_kshim_testing_ctx_free(ctx);
            return -ERESTARTSYS;
        }
        if (testing_logged_osr != osr or testing_logged_flags != flags) {
            testing_logged_osr = osr;
            testing_logged_flags = flags;
            _ = jent_status_to_log(null, jent_kshim_testing_ec(ctx));
        }
        jent_kshim_mutex_unlock(lock);
    }
    jent_kshim_testing_file_set_ctx(file, ctx);
    return 0;
}

pub export fn jent_zig_testing_release(file: *File) callconv(.c) c_int {
    if (!build_options.testinterface) return 0;
    const ctx = jent_kshim_testing_file_ctx(file) orelse return 0;
    jent_record_free(jent_kshim_testing_record(ctx).*);
    jent_kshim_testing_file_set_ctx(file, null);
    jent_kshim_testing_ctx_free(ctx);
    return 0;
}

pub export fn jent_zig_testing_read(file: *File, user_buf: *anyopaque, requested: usize, pos: *i64) callconv(.c) isize {
    if (!build_options.testinterface) return -ENOTTY;
    const ctx = jent_kshim_testing_file_ctx(file) orelse return -EFAULT;
    if (requested == 0) return 0;
    if (requested % @sizeOf(u64) != 0) return -EINVAL;
    const bytes = 1000 * @sizeOf(u64);
    const raw = jent_kshim_kvzalloc(bytes) orelse return -ENOMEM;
    defer jent_kshim_kvfree_sensitive(raw, bytes);
    const samples_buf: [*]u64 = @ptrCast(@alignCast(raw));
    const lock = jent_kshim_testing_lock();
    if (jent_kshim_mutex_lock_interruptible(lock) != 0) return -ERESTARTSYS;
    const loop_count: u32 = @intCast(jent_kshim_testing_loop_count(ctx).*);
    jent_kshim_mutex_unlock(lock);
    var remaining = requested;
    var done: isize = 0;
    var dst: [*]u8 = @ptrCast(user_buf);
    while (remaining >= @sizeOf(u64)) {
        if (jent_kshim_signal_pending()) break;
        var count: u32 = @intCast(@min(remaining / @sizeOf(u64), 1000));
        if (jent_kshim_mutex_lock_interruptible(lock) != 0) break;
        var primed = false;
        var i: u32 = 0;
        while (i < count) : (i += 1) {
            if (jent_kshim_need_resched()) {
                jent_kshim_cond_resched();
                primed = false;
            }
            if (jent_kshim_signal_pending()) break;
            const rec = jent_kshim_testing_record(ctx).* orelse unreachable;
            if (!primed) {
                jent_record_prime(rec, loop_count);
                primed = true;
            }
            samples_buf[i] = jent_record_sample(rec, loop_count);
        }
        jent_kshim_mutex_unlock(lock);
        count = i;
        const len = @as(usize, count) * @sizeOf(u64);
        if (len == 0) break;
        const missed = jent_kshim_copy_to_user_count(dst, samples_buf, len);
        const copied = len - missed;
        remaining -= copied;
        dst += copied;
        done += @intCast(copied);
        if (missed != 0) return if (done == 0) -EFAULT else done;
    }
    if (done == 0 and jent_kshim_signal_pending()) return -ERESTARTSYS;
    pos.* += done;
    return done;
}

pub export fn jent_zig_testing_ioctl(file: *File, cmd: c_uint, arg: *anyopaque) callconv(.c) c_long {
    if (!build_options.testinterface) return -ENOTTY;
    const ctx = jent_kshim_testing_file_ctx(file) orelse return -EFAULT;
    const kind = jent_kshim_ioctl_kind(cmd);
    const lock = jent_kshim_testing_lock();
    if (kind == 10) return jent_status_to_user(lock, jent_kshim_testing_ec(ctx), arg);
    if (kind == 11) {
        var loop_count: u64 = 0;
        if (jent_kshim_copy_from_user(&loop_count, arg, @sizeOf(u64)) != 0) return -EFAULT;
        if (loop_count > 1 << 16) return -EINVAL;
        if (jent_kshim_mutex_lock_interruptible(lock) != 0) return -ERESTARTSYS;
        jent_kshim_testing_loop_count(ctx).* = loop_count;
        jent_kshim_mutex_unlock(lock);
        return 0;
    }
    if (kind == 12) {
        if (!jent_kshim_capable_admin()) return -EPERM;
        return jent_selftest_run_now();
    }
    if (kind >= 1 and kind <= 9)
        return jent_ioctl_field_to_user(lock, jent_kshim_testing_ec(ctx), cmd, arg);
    return -ENOTTY;
}
