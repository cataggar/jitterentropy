const builtin = @import("builtin");
const internal = @import("internal.zig");

const rand_data = internal.rand_data;
const jent_notime_ctx = internal.jent_notime_ctx;
const jent_notime_thread = internal.jent_notime_thread;
const jent_notime_start_routine = internal.jent_notime_start_routine;

const EAGAIN: c_int = 11;
const EINVAL: c_int = 22;
const ENOENT: c_int = 2;
const ENOMEM: c_int = 12;
const EOPNOTSUPP: c_int = switch (builtin.os.tag) {
    .macos, .ios, .tvos, .watchos, .visionos => 102,
    .freebsd, .netbsd, .openbsd => 45,
    .windows => 130,
    .linux => switch (builtin.cpu.arch) {
        .mips, .mipsel, .mips64, .mips64el => 122,
        else => 95,
    },
    else => 95,
};
const JENT_NOTIME_CPU_DEFAULT: c_ulong = ~@as(c_ulong, 0);
const builtin_backend = !internal.is_freestanding;

var jent_notime_cpu_configured: c_int = 0;
var jent_notime_cpu: c_ulong = 0;
var jent_force_internal_timer: c_int = 0;
var jent_notime_switch_blocked: c_int = 0;
var jent_notime_thread_external: jent_notime_thread = .{};

fn ctxCast(ctx: ?*anyopaque) ?*jent_notime_ctx {
    const ptr = ctx orelse return null;
    return @ptrCast(@alignCast(ptr));
}

fn jent_notime_init_flags(ctx: *?*anyopaque, flags: c_uint) c_int {
    if (!internal.build_options.internal_timer) return 0;

    const ncpu = internal.jent_ncpu();
    if (ncpu < 0) return @intCast(ncpu);
    if (ncpu < 2 or !builtin_backend) return -ENOENT;

    const raw = internal.jent_zalloc(@sizeOf(jent_notime_ctx), flags) orelse return -ENOMEM;
    const thread_ctx: *jent_notime_ctx = @ptrCast(@alignCast(raw));
    thread_ctx.notime_cpu = if (jent_notime_cpu_configured != 0)
        jent_notime_cpu
    else
        JENT_NOTIME_CPU_DEFAULT;
    ctx.* = raw;
    return 0;
}

pub fn jent_notime_init(ctx: *?*anyopaque) callconv(.c) c_int {
    return jent_notime_init_flags(ctx, 0);
}

pub fn jent_notime_fini(ctx: ?*anyopaque) callconv(.c) void {
    if (!internal.build_options.internal_timer) return;
    if (ctx != null) internal.jent_zfree(ctx, @sizeOf(jent_notime_ctx));
}

fn jent_notime_start(
    ctx: ?*anyopaque,
    start_routine: jent_notime_start_routine,
    arg: ?*anyopaque,
) callconv(.c) c_int {
    if (!internal.build_options.internal_timer) return -EOPNOTSUPP;
    const thread_ctx = ctxCast(ctx) orelse return -EINVAL;
    return internal.jent_notime_thread_create(thread_ctx, start_routine, arg);
}

fn jent_notime_stop(ctx: ?*anyopaque) callconv(.c) void {
    if (!internal.build_options.internal_timer) return;
    const thread_ctx = ctxCast(ctx) orelse return;
    internal.jent_notime_thread_join(thread_ctx);
}

pub var jent_notime_thread_builtin: jent_notime_thread = .{
    .jent_notime_init = &jent_notime_init,
    .jent_notime_fini = &jent_notime_fini,
    .jent_notime_start = &jent_notime_start,
    .jent_notime_stop = &jent_notime_stop,
};

var notime_thread: ?*jent_notime_thread = &jent_notime_thread_builtin;

pub fn jent_notime_block_switch() callconv(.c) void {
    if (internal.build_options.internal_timer) {
        internal.jent_atomic_store_int(&jent_notime_switch_blocked, 1);
    }
}

pub fn jent_notime_set_cpu(cpu: c_ulong) callconv(.c) c_int {
    if (!internal.build_options.internal_timer) return -EOPNOTSUPP;
    if (internal.jent_atomic_load_int(&jent_notime_switch_blocked) != 0) return -EAGAIN;

    jent_notime_cpu = cpu;
    jent_notime_cpu_configured = 1;
    return 0;
}

const SampleReturn = if (internal.is_pthread) ?*anyopaque else c_int;

fn jent_notime_sample_timer_enabled(arg: ?*anyopaque) SampleReturn {
    const ec: *rand_data = @ptrCast(@alignCast(arg.?));
    const thread_ctx = ctxCast(ec.notime_thread_ctx);

    if (thread_ctx != null and notime_thread == &jent_notime_thread_builtin) {
        const cpu = thread_ctx.?.notime_cpu;
        if (cpu == JENT_NOTIME_CPU_DEFAULT) {
            const highest = internal.jent_cpu_highest();
            if (highest >= 0) {
                _ = internal.jent_thread_pin_to_cpu(@intCast(highest));
            }
        } else {
            _ = internal.jent_thread_pin_to_cpu(cpu);
        }
    }

    ec.setNotimeTimer(0);
    while (true) {
        if (ec.getNotimeInterrupt() != 0) break;
        ec.setNotimeTimer(ec.getNotimeTimer() +% 1);
    }

    return if (internal.is_pthread) null else 0;
}

pub fn jent_notime_sample_timer(arg: ?*anyopaque) callconv(.c) SampleReturn {
    if (comptime internal.build_options.internal_timer) {
        return jent_notime_sample_timer_enabled(arg);
    }
    return if (internal.is_pthread) null else 0;
}

fn jent_notime_settick_enabled(ec: *rand_data) c_int {
    const thread = notime_thread orelse return 0;
    if (ec.enableNotime() == 0) return 0;

    ec.setNotimeInterrupt(0);
    ec.notime_prev_timer = 0;
    ec.setNotimeTimer(0);

    const ret = thread.jent_notime_start.?(
        ec.notime_thread_ctx,
        &jent_notime_sample_timer,
        ec,
    );
    if (ret == 0) ec.setNotimeRunning(1);
    return ret;
}

pub fn jent_notime_settick(ec: *rand_data) callconv(.c) c_int {
    if (comptime internal.build_options.internal_timer) {
        return jent_notime_settick_enabled(ec);
    }
    return 0;
}

fn jent_notime_unsettick_enabled(ec: *rand_data) void {
    const thread = notime_thread orelse return;
    if (ec.enableNotime() == 0 or ec.notimeRunning() == 0) return;

    ec.setNotimeInterrupt(1);
    thread.jent_notime_stop.?(ec.notime_thread_ctx);
    ec.setNotimeRunning(0);
}

pub fn jent_notime_unsettick(ec: *rand_data) callconv(.c) void {
    if (comptime internal.build_options.internal_timer) {
        jent_notime_unsettick_enabled(ec);
    }
}

fn jent_notime_read(ec: *rand_data) u64 {
    if (@sizeOf(usize) >= @sizeOf(u64)) return ec.getNotimeTimer();

    while (true) {
        const a = ec.getNotimeTimer();
        const b = ec.getNotimeTimer();
        if (b < a or b - a > 0x80000000) continue;
        if (b & 0xffffffff == 0xffffffff) {
            internal.jent_yield();
            continue;
        }
        return b;
    }
}

fn jent_get_nstime_internal_enabled(ec: *rand_data, out: *u64) void {
    if (ec.enableNotime() != 0) {
        var now: u64 = 0;
        while (true) {
            now = jent_notime_read(ec);
            if (now > ec.notime_prev_timer) break;
            internal.jent_yield();
        }
        ec.notime_prev_timer = now;
        out.* = now;
    } else {
        internal.jent_get_nstime(out);
    }
}

pub fn jent_get_nstime_internal(ec: *rand_data, out: *u64) callconv(.c) void {
    if (comptime internal.build_options.internal_timer) {
        jent_get_nstime_internal_enabled(ec, out);
    } else {
        internal.jent_get_nstime(out);
    }
}

fn jent_notime_enable_thread(ec: *rand_data, flags: c_uint) c_int {
    const thread = notime_thread orelse return 0;
    const ret = if (thread == &jent_notime_thread_builtin)
        jent_notime_init_flags(&ec.notime_thread_ctx, flags)
    else
        thread.jent_notime_init.?(&ec.notime_thread_ctx);

    if (ret != 0) ec.notime_thread_ctx = null;
    return ret;
}

fn jent_notime_disable_enabled(ec: *rand_data) void {
    if (notime_thread) |thread| {
        if (ec.notime_thread_ctx) |ctx| {
            thread.jent_notime_fini.?(ctx);
            ec.notime_thread_ctx = null;
        }
    }
}

pub fn jent_notime_disable(ec: *rand_data) callconv(.c) void {
    if (comptime internal.build_options.internal_timer) {
        jent_notime_disable_enabled(ec);
    }
}

fn jent_notime_enable_enabled(ec: *rand_data, flags: c_uint) c_int {
    const forced = internal.jent_atomic_load_int(&jent_force_internal_timer);
    if (forced != 0 or flags & internal.JENT_FORCE_INTERNAL_TIMER != 0) {
        if (forced == 0 and
            internal.jent_time_entropy_init(
                ec.osr,
                flags | internal.JENT_FORCE_INTERNAL_TIMER,
            ) != 0)
        {
            return internal.EHEALTH;
        }

        ec.setEnableNotime(1);
        return jent_notime_enable_thread(ec, flags);
    }
    return 0;
}

pub fn jent_notime_enable(ec: *rand_data, flags: c_uint) callconv(.c) c_int {
    if (comptime internal.build_options.internal_timer) {
        return jent_notime_enable_enabled(ec, flags);
    }
    return if (flags & internal.JENT_FORCE_INTERNAL_TIMER != 0) internal.EHEALTH else 0;
}

pub fn jent_notime_switch(new_thread: ?*jent_notime_thread) callconv(.c) c_int {
    if (!internal.build_options.internal_timer) return -EOPNOTSUPP;
    if (internal.jent_atomic_load_int(&jent_notime_switch_blocked) != 0) return -EAGAIN;

    const thread = new_thread orelse return -EINVAL;
    if (thread.jent_notime_init == null or
        thread.jent_notime_fini == null or
        thread.jent_notime_start == null or
        thread.jent_notime_stop == null)
    {
        return -EINVAL;
    }

    if (thread == &jent_notime_thread_builtin) {
        notime_thread = &jent_notime_thread_builtin;
    } else {
        jent_notime_thread_external = thread.*;
        notime_thread = &jent_notime_thread_external;
    }
    return 0;
}

pub fn jent_notime_force() callconv(.c) void {
    if (internal.build_options.internal_timer) {
        internal.jent_atomic_store_int(&jent_force_internal_timer, 1);
    }
}

pub fn jent_notime_forced() callconv(.c) c_int {
    if (!internal.build_options.internal_timer) return 0;
    return internal.jent_atomic_load_int(&jent_force_internal_timer);
}
