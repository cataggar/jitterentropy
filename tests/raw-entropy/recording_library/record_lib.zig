const std = @import("std");
const builtin = @import("builtin");
const core = @import("jent");
const record_options = @import("record_options");
const internal = core.internal;

fn trapPanic(_: []const u8, _: ?usize) noreturn {
    @trap();
}

pub const panic = std.debug.FullPanic(trapPanic);

const c = struct {
    const FILE = opaque {};

    extern fn calloc(count: usize, size: usize) callconv(.c) ?*anyopaque;
    extern fn free(ptr: ?*anyopaque) callconv(.c) void;
    extern fn fopen(path: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*FILE;
    extern fn fclose(stream: *FILE) callconv(.c) c_int;
    extern fn fprintf(stream: *FILE, format: [*:0]const u8, ...) callconv(.c) c_int;
    extern fn remove(path: [*:0]const u8) callconv(.c) c_int;
    extern fn strerror(errnum: c_int) callconv(.c) [*:0]const u8;
    extern fn snprintf(
        buf: [*]u8,
        size: usize,
        format: [*:0]const u8,
        ...,
    ) callconv(.c) c_int;
};

const JENT_RECORD_COMMON: c_uint = 0;
const JENT_RECORD_HASHLOOP: c_uint = 1;
const JENT_RECORD_MEMACCESS: c_uint = 2;

const JENT_RECORD_OK: c_int = 0;
const JENT_RECORD_EINVAL: c_int = 1;
const JENT_RECORD_ENOMEM: c_int = 2;
const JENT_RECORD_ECOLLECTOR: c_int = 3;
const JENT_RECORD_EIO: c_int = 4;
const JENT_RECORD_ESELFTEST: c_int = 5;

const JENT_RECORD_CORES_ANY: c_uint = 0;
const JENT_RECORD_CORES_EFFICIENCY: c_uint = 1;
const JENT_RECORD_CORES_PERFORMANCE: c_uint = 2;

const JENT_DISABLE_MEMORY_ACCESS: c_uint = 1 << 2;
const JENT_MAX_OSR: c_uint = 20;
const JENT_HASH_LOOP_INIT: c_uint = 3;
const JENT_RECORD_STATUS_LEN: usize = 4096;

const EHASH: c_int = 11;
const EMEM: c_int = 12;
const EGCD: c_int = 13;

const JENT_RCT_FAILURE: c_uint = 1;
const JENT_APT_FAILURE: c_uint = 2;
const JENT_LAG_FAILURE: c_uint = 4;
const JENT_RCT_MEM_FAILURE: c_uint = 8;
const JENT_RCT_FAILURE_PERMANENT: c_uint = 1 << 16;
const JENT_APT_FAILURE_PERMANENT: c_uint = 2 << 16;
const JENT_LAG_FAILURE_PERMANENT: c_uint = 4 << 16;
const JENT_RCT_MEM_FAILURE_PERMANENT: c_uint = 8 << 16;

const Measure = *const fn (*internal.rand_data, u64, ?*u64, c_int) callconv(.c) c_uint;

const RecordResult = extern struct {
    health_failure: c_uint,
    memsize: c_uint,
    hashloopcnt: c_uint,
    internal_timer: c_uint,
};

const RecordConfig = extern struct {
    file: ?[*:0]const u8,
    rounds: c_ulong,
    repeats: c_ulong,
    flags: c_uint,
    osr: c_uint,
    loopcnt: c_uint,
    source: c_uint,
    cpu: c_int,
    cores: c_uint,
    status: c_int,
};

extern fn __errno_location() callconv(.c) *c_int;
extern fn __error() callconv(.c) *c_int;
extern fn _errno() callconv(.c) *c_int;

fn errnoPtr() *c_int {
    if (builtin.os.tag == .dragonfly) return __error();
    return std.c._errno();
}

const core_api = struct {
    const raw_selftest = core.base.jent_raw_selftest;
    const collector_alloc_raw = core.base.jent_entropy_collector_alloc_raw;
    const collector_free = core.base.jent_entropy_collector_free;
    const notime_settick = core.timer.jent_notime_settick;
    const notime_unsettick = core.timer.jent_notime_unsettick;
    const status = core.status.jent_status;
    const health_failure = core.health.jent_health_failure;
    const measure_common = core.noise.jent_measure_jitter;
    const measure_hashloop = core.noise.jent_measure_jitter_ntg1_sha3;
    const measure_memaccess = core.noise.jent_measure_jitter_ntg1_memaccess;
    const zalloc_unlocked = core.arch_memory.jent_zalloc_unlocked;
    const zfree = core.arch_memory.jent_zfree;

    fn enable_notime(ec: ?*const internal.rand_data) callconv(.c) c_int {
        return if (ec) |value| value.enableNotime() else 0;
    }

    fn set_fips_enabled(ec: ?*internal.rand_data) callconv(.c) void {
        if (ec) |value| value.setIsFipsEnabled(1);
    }

    fn set_common_timer_gcd(ec: ?*internal.rand_data, gcd: u64) callconv(.c) void {
        if (ec) |value| value.jent_common_timer_gcd = gcd;
    }

    fn result(ec: ?*const internal.rand_data, out: *RecordResult) callconv(.c) void {
        const value = ec orelse return;
        out.* = .{
            .health_failure = 0,
            .memsize = if (value.mem != null) value.memmask + 1 else 0,
            .hashloopcnt = value.hashloopcnt,
            .internal_timer = @intCast(value.enableNotime()),
        };
    }

    fn pin_cpu(cpu: c_ulong) callconv(.c) c_int {
        return core.arch_thread.jent_thread_pin_to_cpu(cpu);
    }

    fn select_cores(performance: c_int) callconv(.c) c_int {
        _ = performance;
        return -38;
    }

    fn get_errno() callconv(.c) c_int {
        return errnoPtr().*;
    }

    fn set_errno(err: c_int) callconv(.c) void {
        errnoPtr().* = err;
    }

    fn error_string(err: c_int) callconv(.c) [*:0]const u8 {
        return c.strerror(err);
    }
};

const Record = extern struct {
    ec: *internal.rand_data,
    measure: Measure,
    source: c_uint,
};

const Text = struct {
    buf: ?[*]u8,
    len: usize,
    used: usize = 0,

    fn terminate(self: *Text) void {
        if (self.buf) |buf| {
            if (self.len != 0) {
                buf[@min(self.used, self.len - 1)] = 0;
            }
        }
    }

    fn append(self: *Text, value: []const u8) void {
        if (self.buf) |buf| {
            if (self.len > 1 and self.used < self.len - 1) {
                const amount = @min(value.len, self.len - 1 - self.used);
                @memcpy(buf[self.used..][0..amount], value[0..amount]);
            }
        }
        self.used +|= value.len;
        self.terminate();
    }

    fn appendZ(self: *Text, value: [*:0]const u8) void {
        self.append(std.mem.span(value));
    }

    fn appendFmt(self: *Text, comptime fmt: []const u8, args: anytype) void {
        var tmp: [8192]u8 = undefined;
        const rendered = std.fmt.bufPrint(&tmp, fmt, args) catch return;
        self.append(rendered);
    }
};

fn measureFor(source: c_uint, flags: c_uint) ?Measure {
    return switch (source) {
        JENT_RECORD_COMMON => core_api.measure_common,
        JENT_RECORD_HASHLOOP => core_api.measure_hashloop,
        JENT_RECORD_MEMACCESS => if (flags & JENT_DISABLE_MEMORY_ACCESS != 0)
            null
        else
            core_api.measure_memaccess,
        else => null,
    };
}

export fn jent_record_alloc(
    rec_out: ?*?*Record,
    osr: c_uint,
    flags: c_uint,
    source: c_uint,
) callconv(.c) c_int {
    const out = rec_out orelse return JENT_RECORD_EINVAL;
    out.* = null;
    const measure = measureFor(source, flags) orelse return JENT_RECORD_EINVAL;
    if (osr > JENT_MAX_OSR) return JENT_RECORD_EINVAL;

    const memory = core_api.zalloc_unlocked(@sizeOf(Record)) orelse
        return JENT_RECORD_ENOMEM;
    const rec: *Record = @ptrCast(@alignCast(memory));
    rec.* = .{ .ec = undefined, .measure = measure, .source = source };

    rec.ec = core_api.collector_alloc_raw(osr, flags) orelse {
        const selftest = core_api.raw_selftest(flags);
        core_api.zfree(rec, @sizeOf(Record));
        return if (selftest != 0 and selftest != EMEM)
            JENT_RECORD_ESELFTEST
        else
            JENT_RECORD_ECOLLECTOR;
    };

    if (core_api.enable_notime(rec.ec) != 0 and
        core_api.notime_settick(rec.ec) != 0)
    {
        core_api.collector_free(rec.ec);
        core_api.zfree(rec, @sizeOf(Record));
        return JENT_RECORD_ECOLLECTOR;
    }

    core_api.set_fips_enabled(rec.ec);
    out.* = rec;
    return JENT_RECORD_OK;
}

export fn jent_record_free(rec: ?*Record) callconv(.c) void {
    const value = rec orelse return;
    core_api.notime_unsettick(value.ec);
    core_api.collector_free(value.ec);
    core_api.zfree(value, @sizeOf(Record));
}

export fn jent_record_prime(rec: *Record, loopcnt: c_uint) callconv(.c) void {
    if (rec.source == JENT_RECORD_COMMON) {
        _ = rec.measure(rec.ec, loopcnt, null, 0);
    }
}

export fn jent_record_sample(rec: *Record, loopcnt: c_uint) callconv(.c) u64 {
    var delta: u64 = 0;
    _ = rec.measure(rec.ec, loopcnt, &delta, 1);
    return delta;
}

export fn jent_record_raw(
    pathname: ?[*:0]const u8,
    rounds: c_uint,
    osr: c_uint,
    flags: c_uint,
    source: c_uint,
    loopcnt: c_uint,
    result: ?*RecordResult,
    status: ?[*]u8,
    statuslen: usize,
) callconv(.c) c_int {
    if (status) |buf| {
        if (statuslen != 0) buf[0] = 0;
    }

    const path = pathname orelse return JENT_RECORD_EINVAL;
    const measure = measureFor(source, flags) orelse return JENT_RECORD_EINVAL;
    if (rounds == 0) return JENT_RECORD_EINVAL;

    const duration_mem = c.calloc(rounds, @sizeOf(u64)) orelse
        return JENT_RECORD_ENOMEM;
    const duration: [*]u64 = @ptrCast(@alignCast(duration_mem));
    defer c.free(duration_mem);

    const ec = core_api.collector_alloc_raw(osr, flags) orelse
        return JENT_RECORD_ECOLLECTOR;
    defer {
        core_api.notime_unsettick(ec);
        core_api.collector_free(ec);
    }

    if (result) |out| core_api.result(ec, out);
    if (status != null and statuslen != 0 and
        core_api.status(ec, status, statuslen) != 0)
    {
        status.?[0] = 0;
    }

    core_api.set_common_timer_gcd(ec, 1);
    if (core_api.enable_notime(ec) != 0 and
        core_api.notime_settick(ec) != 0)
    {
        return JENT_RECORD_ECOLLECTOR;
    }

    const out = c.fopen(path, "w") orelse return JENT_RECORD_EIO;
    var output_open = true;
    var ret: c_int = JENT_RECORD_OK;
    var saved_errno: c_int = 0;

    core_api.set_fips_enabled(ec);
    if (source == JENT_RECORD_COMMON) {
        _ = core_api.measure_common(ec, loopcnt, null, 0);
    }
    for (0..rounds) |i| {
        _ = measure(ec, loopcnt, &duration[i], 1);
    }

    if (result) |record_result| {
        record_result.health_failure = core_api.health_failure(ec);
    }

    for (0..rounds) |i| {
        if (c.fprintf(out, "%llu\n", @as(c_ulonglong, duration[i])) < 0) {
            saved_errno = core_api.get_errno();
            ret = JENT_RECORD_EIO;
            break;
        }
    }
    if (c.fclose(out) != 0 and ret == JENT_RECORD_OK) {
        saved_errno = core_api.get_errno();
        ret = JENT_RECORD_EIO;
    }
    output_open = false;

    if (ret != JENT_RECORD_OK) {
        _ = c.remove(path);
    }
    if (output_open) _ = c.fclose(out);
    if (saved_errno != 0) core_api.set_errno(saved_errno);
    return ret;
}

export fn jent_record_health_names(
    health_failure: c_uint,
    buf: ?[*]u8,
    len: usize,
) callconv(.c) usize {
    const TestName = struct { bit: c_uint, name: []const u8 };
    const tests = [_]TestName{
        .{ .bit = JENT_RCT_FAILURE, .name = "RCT" },
        .{ .bit = JENT_APT_FAILURE, .name = "APT" },
        .{ .bit = JENT_LAG_FAILURE, .name = "Lag" },
        .{ .bit = JENT_RCT_MEM_FAILURE, .name = "RCT-mem" },
        .{ .bit = JENT_RCT_FAILURE_PERMANENT, .name = "RCT-permanent" },
        .{ .bit = JENT_APT_FAILURE_PERMANENT, .name = "APT-permanent" },
        .{ .bit = JENT_LAG_FAILURE_PERMANENT, .name = "Lag-permanent" },
        .{ .bit = JENT_RCT_MEM_FAILURE_PERMANENT, .name = "RCT-mem-permanent" },
    };

    var text = Text{ .buf = buf, .len = len };
    text.terminate();
    var known: c_uint = 0;
    for (tests) |test_name| {
        known |= test_name.bit;
        if (health_failure & test_name.bit == 0) continue;
        if (text.used != 0) text.append(" ");
        text.append(test_name.name);
    }
    const unknown = health_failure & ~known;
    if (unknown != 0) {
        if (text.used != 0) text.append(" ");
        text.appendFmt("(unknown 0x{x})", .{unknown});
    }
    return text.used;
}

fn oneTest(config: *const RecordConfig, pathname: [*:0]const u8, report: *Text) c_int {
    var result: RecordResult = undefined;
    var names: [160]u8 = undefined;

    const selftest = core_api.raw_selftest(config.flags);
    if (selftest != 0) {
        const reason = if (selftest == EHASH)
            "SHA-3 known answer test"
        else if (selftest == EGCD)
            "GCD known answer test"
        else
            "unexpected startup failure";
        report.appendFmt(
            "The conditioning self test failed with error code {d} ({s})\n",
            .{ selftest, reason },
        );
        return 1;
    }

    if (config.status != 0) {
        const ec = core_api.collector_alloc_raw(config.osr, config.flags) orelse {
            report.append("Allocation of the entropy collector failed\n");
            return 1;
        };
        defer core_api.collector_free(ec);
        var status_buf: [JENT_RECORD_STATUS_LEN]u8 = undefined;
        const ret = core_api.status(ec, &status_buf, status_buf.len);
        if (ret != 0)
            report.appendFmt("Fetching jent status failed with code: {d}\n", .{ret})
        else
            report.appendZ(@ptrCast(&status_buf));
        return if (ret != 0) 1 else 0;
    }

    report.appendFmt("Processing {s}\n", .{std.mem.span(pathname)});
    const ret = jent_record_raw(
        pathname,
        @intCast(config.rounds),
        config.osr,
        config.flags,
        config.source,
        config.loopcnt,
        &result,
        null,
        0,
    );
    const saved_errno = core_api.get_errno();
    switch (ret) {
        JENT_RECORD_OK, JENT_RECORD_EIO => {},
        JENT_RECORD_ECOLLECTOR => {
            report.append("Allocation of the entropy collector failed\n");
            if (config.cpu >= 0) {
                report.append(
                    "Note: --cpu leaves one CPU in the affinity mask, which rules out the internal timer\n",
                );
            }
            return 1;
        },
        JENT_RECORD_EINVAL => {
            if (config.source == JENT_RECORD_MEMACCESS and
                config.flags & JENT_DISABLE_MEMORY_ACCESS != 0)
            {
                report.append(
                    "The memory access loop cannot be recorded with memory access disabled\n",
                );
            } else {
                report.append("Invalid recording arguments\n");
            }
            return 1;
        },
        JENT_RECORD_ENOMEM => {
            report.appendFmt(
                "No memory for the {d} samples to be recorded\n",
                .{config.rounds},
            );
            return 1;
        },
        else => {
            report.appendFmt("Recording failed with code {d}\n", .{ret});
            return 1;
        },
    }

    const hashloops: c_uint = if (config.source == JENT_RECORD_MEMACCESS)
        0
    else if (config.loopcnt != 0)
        config.loopcnt
    else if (config.source == JENT_RECORD_HASHLOOP)
        result.hashloopcnt * JENT_HASH_LOOP_INIT
    else
        result.hashloopcnt;

    report.appendFmt(
        "{s} memory access - Memory size: {d} - Hashloop count: {d}\n",
        .{
            if (record_options.raw_memory_access) "Random" else "Deterministic",
            result.memsize,
            hashloops,
        },
    );

    if (result.health_failure != 0) {
        _ = jent_record_health_names(result.health_failure, &names, names.len);
        report.appendFmt(
            "The main context encountered the following health testing failure(s): {s}\n",
            .{std.mem.sliceTo(&names, 0)},
        );
    }

    if (ret == JENT_RECORD_EIO) {
        report.appendFmt(
            "Can't output data: {s}\n",
            .{std.mem.span(core_api.error_string(saved_errno))},
        );
        return 1;
    }
    return 0;
}

export fn jent_record_report_len(config: *const RecordConfig) callconv(.c) usize {
    const file_len = if (config.file) |file| std.mem.len(file) else 0;
    const per_repeat = 1024 + file_len +
        (if (config.status != 0) JENT_RECORD_STATUS_LEN else 0);
    return 1024 + per_repeat * (if (config.repeats != 0) config.repeats else 1);
}

export fn jent_record_run(
    config: *const RecordConfig,
    report_buf: ?[*]u8,
    reportlen: usize,
) callconv(.c) c_int {
    var report = Text{ .buf = report_buf, .len = reportlen };
    report.terminate();

    if (config.file == null or config.rounds == 0 or
        config.rounds >= std.math.maxInt(c_uint) or config.repeats == 0)
    {
        report.append("Invalid recording configuration\n");
        return 1;
    }
    if (config.cpu >= 0 and config.cores != JENT_RECORD_CORES_ANY) {
        report.append("--cpu, --e-cores and --p-cores are mutually exclusive\n");
        return 1;
    }

    if (config.cpu >= 0) {
        const ret = core_api.pin_cpu(@intCast(config.cpu));
        if (ret != 0) {
            report.appendFmt(
                "Cannot pin the measurement to CPU {d}: {s}\n",
                .{
                    config.cpu,
                    std.mem.span(core_api.error_string(-ret)),
                },
            );
            return 1;
        }
        report.appendFmt("Measurement pinned to CPU {d}\n", .{config.cpu});
    }

    if (config.cores != JENT_RECORD_CORES_ANY) {
        const performance = config.cores == JENT_RECORD_CORES_PERFORMANCE;
        const ret = core_api.select_cores(if (performance) 1 else 0);
        if (ret != 0) {
            report.appendFmt(
                "Cannot ask for the {s} cores: {s}\n",
                .{
                    if (performance) "performance" else "efficiency",
                    std.mem.span(core_api.error_string(-ret)),
                },
            );
            return 1;
        }
        report.append(if (performance)
            "Measurement asked for the performance cores\n"
        else
            "Measurement confined to the efficiency cores\n");
    }

    var pathname: [4096]u8 = undefined;
    var repeat: c_ulong = 1;
    while (repeat <= config.repeats) : (repeat += 1) {
        const len = c.snprintf(
            &pathname,
            pathname.len,
            "%s-%.4lu.data",
            config.file.?,
            repeat,
        );
        if (len < 0 or @as(usize, @intCast(len)) >= pathname.len) {
            report.append("Output file path too long\n");
            return 1;
        }
        const ret = oneTest(config, @ptrCast(&pathname), &report);
        if (ret != 0 or config.status != 0) return ret;
    }
    return 0;
}
