const std = @import("std");
const builtin = @import("builtin");
const internal = @import("internal.zig");

const rand_data = internal.rand_data;
const JENT_SIZEOF_TIMEDELTA = @sizeOf(u64);
const JENT_SIZEOF_DOMAINSEPARATOR = @sizeOf(u8);
const JENT_SIZEOF_HASH_BLOCK = internal.JENT_SHA3_256_SIZE_DIGEST;
const JENT_SIZEOF_INTERMEDIARY_DATA = JENT_SIZEOF_TIMEDELTA +
    JENT_SIZEOF_DOMAINSEPARATOR +
    JENT_SIZEOF_HASH_BLOCK;
const JENT_SIZEOF_INTERMEDIARY = internal.JENT_SHA3_256_SIZE_BLOCK;
const JENT_OFFSET_TIMEDELTA = 0;
const JENT_OFFSET_DOMAINSEPARATOR = JENT_OFFSET_TIMEDELTA + JENT_SIZEOF_TIMEDELTA;
const JENT_OFFSET_HASH_BLOCK = JENT_OFFSET_DOMAINSEPARATOR + JENT_SIZEOF_DOMAINSEPARATOR;

const MeasureJitter = *const fn (
    *rand_data,
    u64,
    ?*u64,
    c_int,
) callconv(.c) c_uint;

inline fn compilerBarrier() void {
    asm volatile ("" ::: .{ .memory = true });
}

fn fieldBytes(ptr: anytype) [*]const u8 {
    return @ptrCast(ptr);
}

fn jent_hash_insert(
    ec: *rand_data,
    time_delta: u64,
    intermediary: *[JENT_SIZEOF_INTERMEDIARY]u8,
) void {
    comptime {
        if (JENT_SIZEOF_INTERMEDIARY < JENT_SIZEOF_INTERMEDIARY_DATA) {
            @compileError("SHA3 intermediary is too small");
        }
    }

    @memcpy(
        intermediary[JENT_OFFSET_TIMEDELTA .. JENT_OFFSET_TIMEDELTA + @sizeOf(u64)],
        std.mem.asBytes(&time_delta),
    );
    internal.jent_sha3_update(
        &ec.hash_state,
        intermediary,
        internal.jent_sha3_rate(&ec.hash_state),
    );
    internal.jent_memset_secure(intermediary, JENT_SIZEOF_INTERMEDIARY);
}

fn jent_hash_loop(
    ec: *rand_data,
    intermediary: *[JENT_SIZEOF_INTERMEDIARY]u8,
    loop_cnt: u64,
) void {
    var ctx: internal.jent_sha_ctx = undefined;
    const digest: [*]u8 = @ptrCast(&intermediary[JENT_OFFSET_HASH_BLOCK]);
    var j: u64 = 0;
    const hash_loop_cnt: u64 = if (loop_cnt != 0) loop_cnt else ec.hashloopcnt;

    comptime {
        if (internal.JENT_HASH_LOOP_DEFAULT < 1 or internal.JENT_HASH_LOOP_INIT < 1) {
            @compileError("hash loop counts must be positive");
        }
    }

    internal.jent_sha3_256_init(&ctx);
    while (j < hash_loop_cnt) : (j += 1) {
        compilerBarrier();
        internal.jent_sha3_update(&ctx, digest, internal.JENT_SHA3_256_SIZE_DIGEST);
        internal.jent_sha3_update(&ctx, fieldBytes(&ec.rct_count), @sizeOf(c_uint));
        internal.jent_sha3_update(&ctx, fieldBytes(&ec.apt_cutoff), @sizeOf(c_uint));
        internal.jent_sha3_update(&ctx, fieldBytes(&ec.apt_observations), @sizeOf(c_uint));
        internal.jent_sha3_update(&ctx, fieldBytes(&ec.apt_count), @sizeOf(c_uint));
        internal.jent_sha3_update(&ctx, fieldBytes(&ec.apt_base), @sizeOf(u64));
        internal.jent_sha3_update(&ctx, fieldBytes(&ec.rct_mem_count), @sizeOf(c_ushort));
        internal.jent_sha3_update(&ctx, fieldBytes(&j), @sizeOf(u64));
        internal.jent_sha3_final(&ctx, digest);
        compilerBarrier();
    }

    internal.jent_memset_secure(&ctx, internal.JENT_SHA_MAX_CTX_SIZE);
}

inline fn uint32rotl(x: u32, k: u5) u32 {
    return std.math.rotl(u32, x, k);
}

fn xoshiro128starstar(s: *[4]u32) u32 {
    const result = uint32rotl(s[1] *% 5, 7) *% 9;
    const t = s[1] << 9;

    s[2] ^= s[0];
    s[3] ^= s[1];
    s[1] ^= s[2];
    s[0] ^= s[3];
    s[2] ^= t;
    s[3] = uint32rotl(s[3], 11);
    return result;
}

pub export fn jent_memaccess_pseudorandom(
    ec_opt: ?*rand_data,
    loop_cnt: u64,
    current_delta: ?*u64,
) callconv(.c) void {
    const ec = ec_opt orelse return;
    const mem = ec.mem orelse return;
    var time_now_start: u64 = 0;
    var time_now_end: u64 = 0;
    var prng_state = [4]u32{ 0x8e93eec0, 0xce65608a, 0xa8d46b46, 0xe83cef69 };
    const state_bytes = std.mem.asBytes(&prng_state);
    const mem_loop_cnt: u64 = if (loop_cnt != 0) loop_cnt else ec.memaccessloops;

    for (state_bytes) |*byte| {
        internal.jent_get_nstime_internal(ec, &time_now_start);
        byte.* ^= @truncate(time_now_start);
    }

    if (current_delta != null) {
        internal.jent_get_nstime_internal(ec, &time_now_start);
    }

    var i: u64 = 0;
    while (i < mem_loop_cnt) : (i += 1) {
        const offset: usize = @intCast(xoshiro128starstar(&prng_state) & ec.memmask);
        const location: *volatile u8 = @ptrCast(mem + offset);
        compilerBarrier();
        const value = location.*;
        location.* = value +% 1;
        compilerBarrier();
    }

    if (current_delta) |delta| {
        internal.jent_get_nstime_internal(ec, &time_now_end);
        delta.* = internal.jent_udiv64(
            internal.jent_delta(time_now_start, time_now_end),
            ec.jent_common_timer_gcd,
        );
    }
}

pub export fn jent_memaccess_deterministic(
    ec_opt: ?*rand_data,
    loop_cnt: u64,
    current_delta: ?*u64,
) callconv(.c) void {
    const ec = ec_opt orelse return;
    const mem = ec.mem orelse return;
    var time_now_start: u64 = 0;
    var time_now_end: u64 = 0;
    const mem_loop_cnt: u64 = if (loop_cnt != 0) loop_cnt else ec.memaccessloops;
    const wrap = ec.memmask +% 1;

    if (current_delta != null) {
        internal.jent_get_nstime_internal(ec, &time_now_start);
    }

    var i: u64 = 0;
    while (i < mem_loop_cnt) : (i += 1) {
        const location: *volatile u8 = @ptrCast(mem + @as(usize, ec.memlocation));
        compilerBarrier();
        const value = location.*;
        location.* = value +% 1;
        compilerBarrier();

        ec.memlocation +%= internal.JENT_MEMORY_BLOCKSIZE - 1;
        ec.memlocation %= wrap;
    }

    if (current_delta) |delta| {
        internal.jent_get_nstime_internal(ec, &time_now_end);
        delta.* = internal.jent_udiv64(
            internal.jent_delta(time_now_start, time_now_end),
            ec.jent_common_timer_gcd,
        );
    }
}

pub export fn jent_measure_jitter_ntg1_memaccess(
    ec: *rand_data,
    loop_cnt: u64,
    ret_current_delta: ?*u64,
    health: c_int,
) callconv(.c) c_uint {
    var intermediary: [JENT_SIZEOF_INTERMEDIARY]u8 = @splat(0);
    var current_delta: u64 = 0;

    jent_memaccess_deterministic(
        ec,
        if (loop_cnt != 0) loop_cnt else @as(u64, ec.memaccessloops) * internal.JENT_MEM_ACC_LOOP_INIT,
        &current_delta,
    );
    const stuck = if (health != 0) internal.jent_stuck(ec, current_delta) else 0;
    intermediary[JENT_OFFSET_DOMAINSEPARATOR] = 0x01;
    jent_hash_insert(ec, current_delta, &intermediary);
    if (ret_current_delta) |out| out.* = current_delta;
    return stuck;
}

pub export fn jent_measure_jitter_ntg1_sha3(
    ec: *rand_data,
    loop_cnt: u64,
    ret_current_delta: ?*u64,
    health: c_int,
) callconv(.c) c_uint {
    var intermediary: [JENT_SIZEOF_INTERMEDIARY]u8 = @splat(0);
    var time_now: u64 = 0;

    internal.jent_get_nstime_internal(ec, &ec.prev_time);
    jent_hash_loop(
        ec,
        &intermediary,
        if (loop_cnt != 0) loop_cnt else @as(u64, ec.hashloopcnt) * internal.JENT_HASH_LOOP_INIT,
    );
    internal.jent_get_nstime_internal(ec, &time_now);
    const current_delta = internal.jent_udiv64(
        internal.jent_delta(ec.prev_time, time_now),
        ec.jent_common_timer_gcd,
    );
    const stuck = if (health != 0) internal.jent_stuck(ec, current_delta) else 0;
    intermediary[JENT_OFFSET_DOMAINSEPARATOR] = 0x02;
    jent_hash_insert(ec, current_delta, &intermediary);
    if (ret_current_delta) |out| out.* = current_delta;
    return stuck;
}

pub export fn jent_measure_jitter(
    ec: *rand_data,
    loop_cnt: u64,
    ret_current_delta: ?*u64,
    health: c_int,
) callconv(.c) c_uint {
    var intermediary: [JENT_SIZEOF_INTERMEDIARY]u8 = @splat(0);
    var time_now: u64 = 0;

    if (internal.enable_random_memaccess) {
        jent_memaccess_pseudorandom(ec, loop_cnt, null);
    } else {
        jent_memaccess_deterministic(ec, loop_cnt, null);
    }

    internal.jent_get_nstime_internal(ec, &time_now);
    const current_delta = internal.jent_udiv64(
        internal.jent_delta(ec.prev_time, time_now),
        ec.jent_common_timer_gcd,
    );
    ec.prev_time = time_now;
    const stuck = if (health != 0) internal.jent_stuck(ec, current_delta) else 0;

    jent_hash_loop(ec, &intermediary, loop_cnt);
    intermediary[JENT_OFFSET_DOMAINSEPARATOR] = 0x03;
    jent_hash_insert(ec, current_delta, &intermediary);
    if (ret_current_delta) |out| out.* = current_delta;
    return stuck;
}

fn adjustedMeasureJitterLoopCount(osr: u64, safety_factor: u64) u64 {
    const count = (internal.DATA_SIZE_BITS + safety_factor) * osr;
    return internal.jent_udiv64(count + 2, 3) * 3;
}

pub export fn jent_random_data_one(
    ec: *rand_data,
    measure_jitter: MeasureJitter,
) callconv(.c) void {
    const safety_factor: u64 = if (ec.isFipsEnabled() != 0)
        internal.ENTROPY_SAFETY_FACTOR
    else
        0;
    var ctr: c_uint = 0;

    ec.rct_mem_ctr = 0;
    const nosr = adjustedMeasureJitterLoopCount(ec.osr, safety_factor);
    if (nosr > std.math.maxInt(c_ushort) or nosr < internal.DATA_SIZE_BITS) {
        ec.health_failure |= internal.JENT_RCT_MEM_FAILURE_PERMANENT;
        return;
    }
    ec.rct_mem_nosr = @intCast(nosr);

    while (internal.jent_health_failure_query(ec) == 0) {
        if (measure_jitter(ec, 0, null, 1) != 0) continue;
        ctr += 1;
        if (ctr >= ec.rct_mem_nosr) break;
    }
}

fn jent_random_data_impl(ec: *rand_data) callconv(.c) void {
    switch (ec.startup_state) {
        .jent_startup_memory => {
            jent_random_data_one(ec, &jent_measure_jitter_ntg1_memaccess);
            ec.startup_state = .jent_startup_sha3;
            _ = internal.jent_health_init(
                ec,
                if (ec.flags & internal.JENT_NTG1 != 0)
                    .jent_health_init_type_ntg1
                else
                    .jent_health_init_type_common,
            );
            jent_random_data_one(ec, &jent_measure_jitter_ntg1_sha3);
            ec.startup_state = .jent_startup_completed;
            _ = internal.jent_health_init(
                ec,
                if (ec.flags & internal.JENT_NTG1 != 0)
                    .jent_health_init_type_ntg1
                else
                    .jent_health_init_type_common,
            );
        },
        .jent_startup_sha3 => {
            jent_random_data_one(ec, &jent_measure_jitter_ntg1_sha3);
            ec.startup_state = .jent_startup_completed;
            _ = internal.jent_health_init(
                ec,
                if (ec.flags & internal.JENT_NTG1 != 0)
                    .jent_health_init_type_ntg1
                else
                    .jent_health_init_type_common,
            );
        },
        .jent_startup_completed => {
            _ = jent_measure_jitter(ec, 0, null, 0);
            jent_random_data_one(ec, &jent_measure_jitter);
        },
    }
}

pub const jent_random_data = jent_random_data_impl;

comptime {
    @export(&jent_random_data_impl, .{
        .name = "jent_random_data",
        .linkage = if (builtin.os.tag == .windows) .strong else .weak,
    });
}

pub export fn jent_read_random_block(
    ec: *rand_data,
    dst: [*]u8,
    dst_len: usize,
) callconv(.c) void {
    internal.jent_drbg_generate_block(&ec.hash_state, dst, dst_len);
}
