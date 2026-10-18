// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const std = @import("std");
const builtin = @import("builtin");
const internal = @import("../internal.zig");

const hosted = builtin.os.tag != .freestanding and builtin.os.tag != .uefi;
const windows = builtin.os.tag == .windows;
const pthread_backend = hosted and !windows;

const Handle = ?*anyopaque;
const GroupAffinity = extern struct {
    Mask: usize,
    Group: c_ushort,
    Reserved: [3]c_ushort,
};
const ThreadAffinityPolicy = extern struct {
    affinity_tag: c_int,
};

extern "c" fn __error() *c_int;
extern "c" fn sched_setaffinity(pid: c_int, size: usize, set: *const anyopaque) c_int;
extern "c" fn pthread_attr_init(attr: *std.c.pthread_attr_t) c_int;
extern "c" fn pthread_attr_destroy(attr: *std.c.pthread_attr_t) c_int;
extern "c" fn pthread_create(
    thread: *std.c.pthread_t,
    attr: *const std.c.pthread_attr_t,
    routine: internal.jent_notime_start_routine,
    arg: ?*anyopaque,
) c_int;
extern "c" fn pthread_join(thread: std.c.pthread_t, value: ?*?*anyopaque) c_int;
extern "c" fn pthread_self() std.c.pthread_t;
extern "c" fn pthread_mach_thread_np(thread: std.c.pthread_t) c_uint;
extern "c" fn thread_policy_set(thread: c_uint, flavor: c_int, info: *const c_int, count: c_uint) c_int;
extern "c" fn cpuset_setaffinity(level: c_int, which: c_int, id: isize, size: usize, set: *const anyopaque) c_int;
extern "c" fn _cpuset_create() ?*anyopaque;
extern "c" fn _cpuset_destroy(set: *anyopaque) void;
extern "c" fn _cpuset_zero(set: *anyopaque) void;
extern "c" fn _cpuset_set(cpu: c_uint, set: *anyopaque) c_int;
extern "c" fn _cpuset_size(set: *const anyopaque) usize;
extern "c" fn pthread_setaffinity_np(thread: std.c.pthread_t, size: usize, set: *const anyopaque) c_int;

const jent_cpu_to_group = @import("ncpu.zig").jent_cpu_to_group;
extern "kernel32" fn GetCurrentThread() callconv(.winapi) Handle;
extern "kernel32" fn GetThreadGroupAffinity(thread: Handle, affinity: *GroupAffinity) callconv(.winapi) c_int;
extern "kernel32" fn SetThreadGroupAffinity(thread: Handle, affinity: *const GroupAffinity, previous: ?*GroupAffinity) callconv(.winapi) c_int;
extern "kernel32" fn WaitForSingleObject(handle: Handle, milliseconds: u32) callconv(.winapi) u32;
extern "kernel32" fn CloseHandle(handle: Handle) callconv(.winapi) c_int;
extern "c" fn _beginthreadex(
    security: ?*anyopaque,
    stack_size: c_uint,
    start: *const fn (?*anyopaque) callconv(.winapi) c_uint,
    arg: ?*anyopaque,
    initflag: c_uint,
    thread_address: ?*c_uint,
) usize;

const Err = enum { again, nomem, fault, inval, nosys, notsup };

fn errnoValue(err: Err) c_int {
    return switch (builtin.os.tag) {
        .macos, .ios, .tvos, .watchos, .visionos, .freebsd, .netbsd, .openbsd, .dragonfly => switch (err) {
            .again => 35,
            .nomem => 12,
            .fault => 14,
            .inval => 22,
            .nosys => 78,
            .notsup => if (builtin.os.tag == .netbsd) 86 else 45,
        },
        else => switch (err) {
            .again => 11,
            .nomem => 12,
            .fault => 14,
            .inval => 22,
            .nosys => 38,
            .notsup => 95,
        },
    };
}

fn negErr(err: Err) c_int {
    return -errnoValue(err);
}

fn errnoPtr() *c_int {
    if (builtin.os.tag == .dragonfly) return __error();
    return std.c._errno();
}

fn setBit(bytes: []u8, cpu: usize) void {
    @memset(bytes, 0);
    bytes[cpu / 8] |= @as(u8, 1) << @intCast(cpu % 8);
}

pub var jent_fi_fail_thread_create: c_int = 0;
pub var jent_fi_fail_pthread_create: c_int = 0;
pub var jent_fi_fail_pthread_attr: c_int = 0;
pub var jent_fi_fail_thread_start: c_int = 0;

pub fn jent_thread_pin_to_cpu(cpu: c_ulong) callconv(.c) c_int {
    if (!internal.build_options.internal_timer or !hosted) return -1;

    if (windows) {
        var group: c_ushort = 0;
        var bit: c_uint = 0;
        const mapped = jent_cpu_to_group(cpu, &group, &bit);
        if (mapped != 0) return mapped;

        var current: GroupAffinity = std.mem.zeroes(GroupAffinity);
        if (GetThreadGroupAffinity(GetCurrentThread(), &current) == 0) return negErr(.fault);
        const mask = @as(usize, 1) << @intCast(bit);
        if (current.Group != group or (current.Mask & mask) == 0) return negErr(.inval);

        var requested: GroupAffinity = std.mem.zeroes(GroupAffinity);
        requested.Group = group;
        requested.Mask = mask;
        return if (SetThreadGroupAffinity(GetCurrentThread(), &requested, null) != 0) 0 else negErr(.fault);
    }

    if (builtin.os.tag == .linux) {
        if (cpu >= internal.JENT_NCPU_SET_MAX) return negErr(.inval);
        var fixed: [128]u8 align(@alignOf(usize)) = @splat(0);
        if (cpu < fixed.len * 8) {
            setBit(&fixed, @intCast(cpu));
            if (sched_setaffinity(0, fixed.len, &fixed) != 0) return -errnoPtr().*;
            return 0;
        }

        var ncpu_set: usize = fixed.len * 8;
        while (ncpu_set <= cpu) ncpu_set *= 2;
        const size = (ncpu_set + 7) / 8;
        const raw = std.c.malloc(size) orelse return negErr(.nomem);
        defer std.c.free(raw);
        const bytes = @as([*]u8, @ptrCast(raw))[0..size];
        setBit(bytes, @intCast(cpu));
        if (sched_setaffinity(0, size, raw) != 0) return -errnoPtr().*;
        return 0;
    }

    if (builtin.os.tag.isDarwin()) {
        if (cpu >= std.math.maxInt(i32)) return negErr(.inval);
        var policy = ThreadAffinityPolicy{ .affinity_tag = @intCast(cpu + 1) };
        const result = thread_policy_set(
            pthread_mach_thread_np(pthread_self()),
            4,
            @ptrCast(&policy),
            1,
        );
        if (result == 46) return negErr(.notsup);
        return if (result == 0) 0 else negErr(.fault);
    }

    if (builtin.os.tag == .freebsd) {
        var set: [128]u8 align(@alignOf(usize)) = @splat(0);
        if (cpu >= set.len * 8) return negErr(.inval);
        setBit(&set, @intCast(cpu));
        if (cpuset_setaffinity(3, 1, -1, set.len, &set) != 0) return -errnoPtr().*;
        return 0;
    }

    if (builtin.os.tag == .netbsd) {
        const set = _cpuset_create() orelse return negErr(.nomem);
        defer _cpuset_destroy(set);
        _cpuset_zero(set);
        if (_cpuset_set(@intCast(cpu), set) != 0) return negErr(.inval);
        const ret = pthread_setaffinity_np(pthread_self(), _cpuset_size(set), set);
        return if (ret == 0) 0 else -ret;
    }

    if (builtin.os.tag == .openbsd) return negErr(.notsup);
    return negErr(.nosys);
}

fn windowsThreadStart(arg: ?*anyopaque) callconv(.winapi) c_uint {
    const ctx: *internal.jent_notime_ctx = @ptrCast(@alignCast(arg.?));
    const routine = ctx.notime_routine orelse return 0;
    return @intCast(routine(ctx.notime_arg));
}

pub fn jent_fi_real_thread_create(
    ctx: *internal.jent_notime_ctx,
    start_routine: internal.jent_notime_start_routine,
    arg: ?*anyopaque,
) callconv(.c) c_int {
    if (!internal.build_options.internal_timer or !hosted) return -1;

    if (pthread_backend) {
        if (comptime internal.enable_test_hooks) {
            if (jent_fi_fail_pthread_attr != 0) return negErr(.nomem);
        }
        var ret = pthread_attr_init(@ptrCast(&ctx.notime_pthread_attr));
        if (ret != 0) return -ret;
        if (comptime internal.enable_test_hooks) {
            if (jent_fi_fail_pthread_create != 0) {
                ret = errnoValue(.again);
            } else {
                ret = pthread_create(
                    @ptrCast(&ctx.notime_thread_id),
                    @ptrCast(&ctx.notime_pthread_attr),
                    start_routine,
                    arg,
                );
            }
        } else {
            ret = pthread_create(
                @ptrCast(&ctx.notime_thread_id),
                @ptrCast(&ctx.notime_pthread_attr),
                start_routine,
                arg,
            );
        }
        if (ret != 0) {
            _ = pthread_attr_destroy(@ptrCast(&ctx.notime_pthread_attr));
            return -ret;
        }
        ctx.notime_thread_started = 1;
        return 0;
    }

    ctx.notime_routine = start_routine;
    ctx.notime_arg = arg;
    if (comptime internal.enable_test_hooks) {
        if (jent_fi_fail_thread_start != 0) return negErr(.again);
    }
    errnoPtr().* = 0;
    const handle = _beginthreadex(null, 0, windowsThreadStart, ctx, 0, null);
    if (handle == 0) {
        const err = errnoPtr().*;
        return if (err != 0) -err else negErr(.again);
    }
    ctx.notime_thread_id = @ptrFromInt(handle);
    ctx.notime_thread_started = 1;
    return 0;
}

pub fn jent_notime_thread_create(
    ctx: *internal.jent_notime_ctx,
    start_routine: internal.jent_notime_start_routine,
    arg: ?*anyopaque,
) callconv(.c) c_int {
    if (comptime internal.enable_test_hooks) {
        if (jent_fi_fail_thread_create != 0) {
            return if (internal.build_options.internal_timer and hosted) negErr(.again) else -1;
        }
    }
    return jent_fi_real_thread_create(ctx, start_routine, arg);
}

pub fn jent_notime_thread_join(ctx: *internal.jent_notime_ctx) callconv(.c) void {
    if (!internal.build_options.internal_timer or !hosted) return;
    if (ctx.notime_thread_started == 0) return;

    if (pthread_backend) {
        _ = pthread_join(ctx.notime_thread_id.?, null);
        _ = pthread_attr_destroy(@ptrCast(&ctx.notime_pthread_attr));
    } else {
        _ = WaitForSingleObject(ctx.notime_thread_id, 0xffffffff);
        _ = CloseHandle(ctx.notime_thread_id);
        ctx.notime_thread_id = null;
    }
    ctx.notime_thread_started = 0;
}
