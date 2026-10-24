const std = @import("std");
const builtin = @import("builtin");
const h = @import("test_harness");
const jent = @import("internal");

const EAGAIN: c_int = 11;
const EINVAL: c_int = 22;
const ENODEV: c_int = if (builtin.os.tag == .linux) 19 else 6;
const ENOMEM: c_int = 12;

extern var jent_notime_thread_builtin: jent.jent_notime_thread;
extern var jent_fi_ncpu: c_long;
extern var jent_fi_fail_alloc: c_uint;
extern var jent_fi_alloc_count: c_uint;
extern var jent_fi_fail_thread_create: c_int;
extern var jent_fi_fail_pthread_create: c_int;
extern var jent_fi_fail_pthread_attr: c_int;
extern var jent_fi_fail_thread_start: c_int;

extern fn jent_notime_settick(ec: *jent.rand_data) callconv(.c) c_int;
extern fn jent_notime_unsettick(ec: *jent.rand_data) callconv(.c) void;
const SampleReturn = if (jent.is_pthread) ?*anyopaque else c_int;
extern fn jent_notime_sample_timer(arg: ?*anyopaque) callconv(.c) SampleReturn;
extern fn jent_fi_real_thread_create(
    ctx: *jent.jent_notime_ctx,
    routine: jent.jent_notime_start_routine,
    arg: ?*anyopaque,
) callconv(.c) c_int;
extern fn jent_notime_thread_join(ctx: *jent.jent_notime_ctx) callconv(.c) void;

fn expect(cond: bool, comptime message: []const u8) void {
    h.expectOrExit(cond, @src(), "{s}", .{message});
}

fn skip(comptime message: []const u8) void {
    h.skipOrExit(@src(), "{s}", .{message});
}

fn arm(nth: c_uint) void {
    jent_fi_fail_alloc = nth;
    jent_fi_alloc_count = 0;
}

fn disarm() void {
    arm(0);
}

var custom_init_calls: c_uint = 0;
var custom_fini_calls: c_uint = 0;

fn customInit(ctx: *?*anyopaque) callconv(.c) c_int {
    custom_init_calls += 1;
    return jent_notime_thread_builtin.jent_notime_init.?(ctx);
}

fn customFini(ctx: ?*anyopaque) callconv(.c) void {
    custom_fini_calls += 1;
    jent_notime_thread_builtin.jent_notime_fini.?(ctx);
}

fn customStart(
    ctx: ?*anyopaque,
    routine: jent.jent_notime_start_routine,
    arg: ?*anyopaque,
) callconv(.c) c_int {
    return jent_notime_thread_builtin.jent_notime_start.?(ctx, routine, arg);
}

fn customStop(ctx: ?*anyopaque) callconv(.c) void {
    jent_notime_thread_builtin.jent_notime_stop.?(ctx);
}

var custom_thread: jent.jent_notime_thread = .{
    .jent_notime_init = &customInit,
    .jent_notime_fini = &customFini,
    .jent_notime_start = &customStart,
    .jent_notime_stop = &customStop,
};

fn testImplSwitch() void {
    if (!jent.build_options.internal_timer) {
        skip("the timer-less back end is not compiled in");
        return;
    }

    expect(jent.jent_entropy_switch_notime_impl(null) == -EINVAL, "no implementation is refused");

    var partial = custom_thread;
    partial.jent_notime_init = null;
    expect(jent.jent_entropy_switch_notime_impl(&partial) == -EINVAL, "missing init is refused");
    partial = custom_thread;
    partial.jent_notime_fini = null;
    expect(jent.jent_entropy_switch_notime_impl(&partial) == -EINVAL, "missing fini is refused");
    partial = custom_thread;
    partial.jent_notime_start = null;
    expect(jent.jent_entropy_switch_notime_impl(&partial) == -EINVAL, "missing start is refused");
    partial = custom_thread;
    partial.jent_notime_stop = null;
    expect(jent.jent_entropy_switch_notime_impl(&partial) == -EINVAL, "missing stop is refused");

    expect(jent.jent_entropy_switch_notime_impl(&custom_thread) == 0, "complete implementation is accepted");
    expect(jent.jent_entropy_set_notime_cpu(1) == 0, "timer CPU is configurable before initialization");

    const ec = jent.jent_entropy_collector_alloc(0, jent.JENT_FORCE_INTERNAL_TIMER);
    if (ec) |collector| {
        var buf: [32]u8 = undefined;
        expect(custom_init_calls != 0, "registered implementation is used");
        expect(jent.jent_read_entropy(collector, &buf, buf.len) == buf.len, "custom timer produces entropy");
        jent.jent_entropy_collector_free(collector);
        expect(custom_fini_calls != 0, "registered implementation is finalized");
    } else {
        skip("the registered implementation cannot start here");
    }

    expect(
        jent.jent_entropy_switch_notime_impl(&jent_notime_thread_builtin) == -EAGAIN,
        "switching after initialization is denied",
    );
    expect(jent.jent_entropy_set_notime_cpu(0) == -EAGAIN, "moving the timer thread afterwards is denied");
}

fn testNotimeFailures() void {
    if (!jent.build_options.internal_timer) {
        skip("the internal timer is not compiled in");
        return;
    }

    var ctx: ?*anyopaque = null;
    jent_fi_ncpu = 1;
    expect(jent.jent_notime_init(&ctx) != 0, "a single CPU is declined");
    jent_fi_ncpu = -ENODEV;
    expect(jent.jent_notime_init(&ctx) == -ENODEV, "an undiscoverable CPU count is passed through");
    jent_fi_ncpu = 0;

    arm(1);
    expect(jent.jent_notime_init(&ctx) == -ENOMEM, "a denied context allocation is reported");
    disarm();

    jent_fi_fail_thread_create = 1;
    const ec = jent.jent_entropy_collector_alloc(0, jent.JENT_FORCE_INTERNAL_TIMER);
    if (ec) |collector| {
        var buf: [32]u8 = undefined;
        expect(jent.jent_read_entropy(collector, &buf, buf.len) == jent.JENT_ERR_NOTIME, "a read with no timer thread is reported");
        jent.jent_entropy_collector_free(collector);
    } else {
        expect(true, "the collector is declined outright");
    }
    jent_fi_fail_thread_create = 0;

    ctx = null;
    if (jent.jent_notime_init(&ctx) == 0) {
        expect(ctx != null, "the timer initializes again");
        jent.jent_notime_fini(ctx);
    } else {
        skip("the internal timer does not initialize on this machine");
    }
}

fn testThreadCreateFailures() void {
    if (!jent.build_options.internal_timer) {
        skip("no thread backend is compiled in");
        return;
    }
    var raw: ?*anyopaque = null;
    if (jent.jent_notime_init(&raw) != 0) {
        skip("the internal timer does not initialize here");
        return;
    }
    defer jent.jent_notime_fini(raw);
    const ctx: *jent.jent_notime_ctx = @ptrCast(@alignCast(raw.?));

    if (jent.is_pthread) {
        jent_fi_fail_pthread_attr = 1;
        expect(jent_fi_real_thread_create(ctx, &jent_notime_sample_timer, null) != 0, "refused thread attributes are reported");
        jent_fi_fail_pthread_attr = 0;
        jent_fi_fail_pthread_create = 1;
        expect(jent_fi_real_thread_create(ctx, &jent_notime_sample_timer, null) != 0, "a refused thread is reported");
        jent_fi_fail_pthread_create = 0;
    } else if (builtin.os.tag == .windows) {
        jent_fi_fail_thread_start = 1;
        expect(jent_fi_real_thread_create(ctx, &jent_notime_sample_timer, null) != 0, "a refused thread is reported");
        jent_fi_fail_thread_start = 0;
    } else {
        skip("no supported thread backend is compiled in");
        return;
    }

    jent_notime_thread_join(ctx);
    expect(true, "teardown after a refusal is safe");
}

fn testEntryGuards() void {
    if (!jent.build_options.internal_timer) {
        skip("the timer-less entry points are not compiled in");
        return;
    }

    expect(
        jent_notime_thread_builtin.jent_notime_start.?(null, &jent_notime_sample_timer, null) == -EINVAL,
        "starting with no context is refused",
    );
    jent_notime_thread_builtin.jent_notime_stop.?(null);
    expect(true, "stopping with no context is a no-op");

    var ec: jent.rand_data = std.mem.zeroes(jent.rand_data);
    ec.setNotimeInterrupt(1);
    _ = jent_notime_sample_timer(&ec);
    expect(true, "the counting routine returns when interrupted");

    ec = std.mem.zeroes(jent.rand_data);
    ec.setEnableNotime(0);
    expect(jent_notime_settick(&ec) == 0, "ticking a collector without the timer is a no-op");
    jent_notime_unsettick(&ec);
    expect(true, "unticking it is a no-op");

    var ctx: ?*anyopaque = null;
    if (jent.jent_notime_init(&ctx) == 0) {
        expect(ctx != null, "a context is allocated");
        jent.jent_notime_fini(ctx);
    } else {
        skip("the internal timer does not initialize here");
    }
    jent.jent_notime_fini(null);
}

pub fn main() u8 {
    h.resetCounters();
    testImplSwitch();
    testNotimeFailures();
    testThreadCreateFailures();
    testEntryGuards();
    return h.finish("unit-notime");
}
