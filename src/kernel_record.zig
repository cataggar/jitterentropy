// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const i = @import("internal.zig");

const RandData = i.rand_data;
const Measure = *const fn (*RandData, u64, ?*u64, c_int) callconv(.c) c_uint;

const Record = extern struct {
    ec: *RandData,
    measure: Measure,
};

const JENT_RECORD_COMMON = 0;
const JENT_RECORD_HASHLOOP = 1;
const JENT_RECORD_MEMACCESS = 2;
const JENT_RECORD_OK = 0;
const JENT_RECORD_EINVAL = 1;
const JENT_RECORD_ENOMEM = 2;
const JENT_RECORD_ECOLLECTOR = 3;
const JENT_RECORD_ESELFTEST = 5;

extern fn jent_entropy_collector_alloc_raw(osr: c_uint, flags: c_uint) callconv(.c) ?*RandData;
extern fn jent_entropy_collector_free(ec: ?*RandData) callconv(.c) void;
extern fn jent_raw_selftest(flags: c_uint) callconv(.c) c_int;
extern fn jent_notime_unsettick(ec: *RandData) callconv(.c) void;

fn measurement(source: c_uint, flags: c_uint) ?Measure {
    return switch (source) {
        JENT_RECORD_COMMON => &i.jent_measure_jitter,
        JENT_RECORD_HASHLOOP => &i.jent_measure_jitter_ntg1_sha3,
        JENT_RECORD_MEMACCESS => if (flags & i.JENT_DISABLE_MEMORY_ACCESS == 0)
            &i.jent_measure_jitter_ntg1_memaccess
        else
            null,
        else => null,
    };
}

pub export fn jent_record_alloc(
    out: *?*Record,
    osr: c_uint,
    flags: c_uint,
    source: c_uint,
) callconv(.c) c_int {
    out.* = null;
    const measure = measurement(source, flags) orelse return JENT_RECORD_EINVAL;
    if (osr > i.JENT_MAX_OSR) return JENT_RECORD_EINVAL;

    const mem = i.jent_zalloc_unlocked(@sizeOf(Record)) orelse return JENT_RECORD_ENOMEM;
    const rec: *Record = @ptrCast(@alignCast(mem));
    const ec = jent_entropy_collector_alloc_raw(osr, flags) orelse {
        const ret = jent_raw_selftest(flags);
        i.jent_zfree(rec, @sizeOf(Record));
        return if (ret != 0 and ret != i.EMEM) JENT_RECORD_ESELFTEST else JENT_RECORD_ECOLLECTOR;
    };
    ec.setIsFipsEnabled(1);
    rec.* = .{ .ec = ec, .measure = measure };
    out.* = rec;
    return JENT_RECORD_OK;
}

pub export fn jent_record_free(rec_opt: ?*Record) callconv(.c) void {
    const rec = rec_opt orelse return;
    jent_notime_unsettick(rec.ec);
    jent_entropy_collector_free(rec.ec);
    i.jent_zfree(rec, @sizeOf(Record));
}

pub export fn jent_record_prime(rec: *Record, loop_count: c_uint) callconv(.c) void {
    if (rec.measure == &i.jent_measure_jitter)
        _ = i.jent_measure_jitter(rec.ec, loop_count, null, 0);
}

pub export fn jent_record_sample(rec: *Record, loop_count: c_uint) callconv(.c) u64 {
    var delta: u64 = 0;
    _ = rec.measure(rec.ec, loop_count, &delta, 1);
    return delta;
}

pub export fn jent_record_collector(rec: *Record) callconv(.c) *RandData {
    return rec.ec;
}
