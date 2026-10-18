const std = @import("std");
const builtin = @import("builtin");
const i = @import("internal.zig");

const RandData = i.rand_data;
const POWERUP_TESTLOOPCOUNT: usize = 1024;
const CLEARCACHE: c_int = 100;
const EOPNOTSUPP: c_int = switch (builtin.os.tag) {
    .macos, .ios, .tvos, .watchos, .visionos => 102,
    .freebsd, .netbsd, .openbsd, .dragonfly => 45,
    else => 95,
};

comptime {
    // Zig 0.16/0.17 select optimization per module, so build.zig supplies
    // .Debug and this guard prevents the entropy loops from being optimized.
    const mode_name = @tagName(builtin.mode);
    if (!std.mem.eql(u8, mode_name, "Debug") and !std.mem.eql(u8, mode_name, "debug"))
        @compileError("the entropy collection core must be compiled in Debug mode");
}

const timer = @import("timer.zig");

pub var jent_selftest_run: c_int = 0;

pub fn ensure_osr_is_at_least_minimal(current_osr: c_uint) callconv(.c) c_uint {
    return if (current_osr < i.JENT_MIN_OSR) i.JENT_MIN_OSR else current_osr;
}

pub fn jent_version() callconv(.c) c_uint {
    return i.JENT_VERSION;
}

fn notimeBlockSwitch() void {
    if (i.build_options.internal_timer) timer.jent_notime_block_switch();
}

fn notimeSetCpu(cpu: c_ulong) c_int {
    if (i.build_options.internal_timer) return timer.jent_notime_set_cpu(cpu);
    return -EOPNOTSUPP;
}

fn notimeSettick(ec: *RandData) c_int {
    if (i.build_options.internal_timer) return timer.jent_notime_settick(ec);
    return 0;
}

fn notimeUnsettick(ec: *RandData) void {
    if (i.build_options.internal_timer) timer.jent_notime_unsettick(ec);
}

fn notimeEnable(ec: *RandData, flags: c_uint) c_int {
    if (i.build_options.internal_timer) return timer.jent_notime_enable(ec, flags);
    return if (flags & i.JENT_FORCE_INTERNAL_TIMER != 0) i.EHEALTH else 0;
}

fn notimeDisable(ec: *RandData) void {
    if (i.build_options.internal_timer) timer.jent_notime_disable(ec);
}

fn notimeSwitch(new_thread: ?*i.jent_notime_thread) c_int {
    if (i.build_options.internal_timer) return timer.jent_notime_switch(new_thread);
    return -EOPNOTSUPP;
}

fn notimeForce() void {
    if (i.build_options.internal_timer) timer.jent_notime_force();
}

fn notimeForced() c_int {
    if (i.build_options.internal_timer) return timer.jent_notime_forced();
    return 0;
}

fn log2Simple(input: u64) c_uint {
    var value = input;
    var idx: c_uint = 0;
    while (value > 1) : (idx += 1) value >>= 1;
    return idx;
}

fn updateMemsize(input_flags: c_uint, inc: c_uint) c_uint {
    var flags = input_flags;
    const global_max = i.JENT_FLAGS_TO_MAX_MEMSIZE(i.JENT_MAX_MEMSIZE_MAX);
    var max = i.JENT_FLAGS_TO_MAX_MEMSIZE(flags);

    if (max == 0) {
        max = log2Simple(i.jent_cache_size_roundup(if (flags & i.JENT_CACHE_ALL != 0) 1 else 0));
        if (max == 0) {
            max = i.JENT_DEFAULT_MEMORY_BITS;
        } else {
            max +%= i.JENT_CACHE_SHIFT_BITS;
            if (flags & i.JENT_CACHE_ALL == 0) max +%= 2;
        }

        max = if (max > i.JENT_MAX_MEMSIZE_OFFSET)
            max - i.JENT_MAX_MEMSIZE_OFFSET
        else
            0;
        if (max > i.JENT_MAX_AUTO_MEMSIZE) max = i.JENT_MAX_AUTO_MEMSIZE;
    } else {
        max +%= inc;
    }

    if (max > global_max) max = global_max;
    flags &= ~i.JENT_MAX_MEMSIZE_MASK;
    flags |= i.JENT_MAX_MEMSIZE_TO_FLAGS(max);
    return flags;
}

fn updateHashloop(input_flags: c_uint, inc: c_uint) c_uint {
    var flags = input_flags;
    const global_max = i.JENT_FLAGS_TO_HASHLOOP(i.JENT_MAX_HASHLOOP);
    var max = i.JENT_FLAGS_TO_HASHLOOP(flags);

    if (max == 0 and inc != 0) {
        if (i.JENT_HASH_LOOP_DEFAULT > (@as(c_uint, 1) << @intCast(global_max - 1)))
            return flags;
        max = 1;
        while ((@as(c_uint, 1) << @intCast(max - 1)) < i.JENT_HASH_LOOP_DEFAULT) : (max += 1) {}
    }

    max +%= inc;
    if (max > global_max) max = global_max;
    flags &= ~i.JENT_MAX_HASHLOOP_MASK;
    flags |= i.JENT_HASHLOOP_TO_FLAGS(max);
    return flags;
}

fn updateSecureMem(input_flags: c_uint) c_uint {
    var flags = input_flags;
    if (flags & (i.JENT_NTG1 | i.JENT_FORCE_FIPS) != 0 or i.jent_fips_enabled() != 0)
        flags |= i.JENT_FORCE_SECURE_MEM;
    return flags;
}

fn memaccessContradicts(flags: c_uint) bool {
    return flags & i.JENT_DISABLE_MEMORY_ACCESS != 0 and
        (flags & (i.JENT_NTG1 | i.JENT_FORCE_FIPS) != 0 or i.jent_fips_enabled() != 0);
}

fn stackScrub() void {
    if (i.is_freestanding) return;
    var scrub: [4096]u8 = undefined;
    i.jent_memset_secure(&scrub, scrub.len);
    std.mem.doNotOptimizeAway(&scrub);
}

fn healthErr(result: c_uint) c_int {
    if (result & i.JENT_RCT_FAILURE_PERMANENT != 0) return i.JENT_ERR_RCT_PERMANENT;
    if (result & i.JENT_APT_FAILURE_PERMANENT != 0) return i.JENT_ERR_APT_PERMANENT;
    if (result & i.JENT_LAG_FAILURE_PERMANENT != 0) return i.JENT_ERR_LAG_PERMANENT;
    if (result & i.JENT_RCT_MEM_FAILURE_PERMANENT != 0) return i.JENT_ERR_RCT_MEM_PERMANENT;
    if (result & i.JENT_RCT_FAILURE != 0) return i.JENT_ERR_RCT;
    if (result & i.JENT_APT_FAILURE != 0) return i.JENT_ERR_APT;
    if (result & i.JENT_RCT_MEM_FAILURE != 0) return i.JENT_ERR_RCT_MEM;
    return i.JENT_ERR_LAG;
}

pub fn jent_read_entropy(ec_opt: ?*RandData, data_opt: ?[*]u8, requested_len: usize) callconv(.c) isize {
    const ec = ec_opt orelse return i.JENT_ERR_EINVAL;
    if (data_opt == null and requested_len > 0) return i.JENT_ERR_EINVAL;

    if (requested_len == 0) {
        if (i.jent_atomic_load_int(&ec.selftest_failed) != 0) return i.JENT_ERR_SELFTEST;
        const result = i.jent_health_failure(ec);
        return if (result != 0) healthErr(result) else 0;
    }

    const data = data_opt.?;
    const ssize_max = std.math.maxInt(usize) >> 1;
    var len: usize = @min(requested_len, ssize_max);
    const orig_len = len;
    var offset: usize = 0;
    var ret: c_int = 0;

    if (notimeSettick(ec) != 0) {
        stackScrub();
        return i.JENT_ERR_NOTIME;
    }

    while (len > 0) {
        if (i.jent_atomic_load_int(&ec.selftest_failed) != 0) {
            ret = i.JENT_ERR_SELFTEST;
            break;
        }

        i.jent_random_data(ec);
        const health_result = i.jent_health_failure(ec);
        if (health_result != 0) {
            ret = healthErr(health_result);
            break;
        }

        const tocopy = @min(i.DATA_SIZE_BITS / 8, len);
        i.jent_read_random_block(ec, data + offset, tocopy);
        len -= tocopy;
        offset += tocopy;
    }

    notimeUnsettick(ec);
    if (ret != 0 and offset != 0) i.jent_memset_secure(data, offset);
    if (ret == 0) {
        ec.read_invocations +%= 1;
        ec.bytes_output +%= orig_len;
    }
    stackScrub();
    return if (ret != 0) ret else @intCast(orig_len);
}

fn collectorStartup(initial_ec: *RandData) ?*RandData {
    var ec = initial_ec;
    if (notimeSettick(ec) != 0) {
        jent_entropy_collector_free(ec);
        return null;
    }

    while (true) {
        i.jent_random_data(ec);
        if (i.jent_health_failure(ec) != 0) {
            var replacement: ?*RandData = ec;
            if (jent_health_failure_reset(&replacement, 0) != 0) {
                jent_entropy_collector_free(ec);
                return null;
            }
            ec = replacement.?;
            if (notimeSettick(ec) != 0) {
                jent_entropy_collector_free(ec);
                return null;
            }
            continue;
        }
        if (ec.startup_state == .jent_startup_completed) break;
    }

    notimeUnsettick(ec);
    return ec;
}

pub fn jent_health_failure_reset(ec_ptr: *?*RandData, startup: c_int) callconv(.c) c_int {
    const old_ec = ec_ptr.*.?;
    var osr = old_ec.osr +% 1;
    var flags = old_ec.flags;

    if (old_ec.isFipsEnabled() != 0) {
        if (old_ec.enableNotime() != 0)
            flags |= i.JENT_FORCE_INTERNAL_TIMER
        else
            flags |= i.JENT_DISABLE_INTERNAL_TIMER;
    }
    if (osr > i.JENT_MAX_OSR) return -1;
    if (old_ec.maxMemSet() == 0) flags = updateMemsize(flags, 1);
    flags = updateHashloop(flags, 1);

    while (jent_entropy_init_ex(osr, flags) != 0) {
        osr +%= 1;
        if (osr > i.JENT_MAX_OSR) return -1;
    }

    var new_ec = jent_entropy_collector_alloc_internal(osr, flags) orelse return -1;
    new_ec.setMaxMemSet(old_ec.maxMemSet());
    new_ec.uuid = old_ec.uuid;
    new_ec.reinit_count = old_ec.reinit_count +% 1;
    new_ec.read_invocations = old_ec.read_invocations;
    new_ec.bytes_output = old_ec.bytes_output;

    if (startup != 0) new_ec = collectorStartup(new_ec) orelse return -1;
    i.jent_health_duplicate(new_ec, old_ec);
    jent_entropy_collector_free(old_ec);
    ec_ptr.* = new_ec;
    return 0;
}

pub fn jent_read_entropy_safe(
    ec_ptr_opt: ?*?*RandData,
    data_opt: ?[*]u8,
    requested_len: usize,
) callconv(.c) isize {
    const ec_ptr = ec_ptr_opt orelse return i.JENT_ERR_EINVAL;
    if (data_opt == null and requested_len > 0) return i.JENT_ERR_EINVAL;
    if (requested_len == 0) return jent_read_entropy(ec_ptr.*, data_opt, 0);

    const data = data_opt.?;
    const ssize_max = std.math.maxInt(usize) >> 1;
    var len: usize = @min(requested_len, ssize_max);
    const orig_len = len;
    var offset: usize = 0;

    while (len > 0) {
        const ret = jent_read_entropy(ec_ptr.*, data + offset, len);
        switch (ret) {
            i.JENT_ERR_EINVAL,
            i.JENT_ERR_NOTIME,
            i.JENT_ERR_RCT_PERMANENT,
            i.JENT_ERR_APT_PERMANENT,
            i.JENT_ERR_LAG_PERMANENT,
            i.JENT_ERR_RCT_MEM_PERMANENT,
            i.JENT_ERR_SELFTEST,
            => return ret,
            i.JENT_ERR_RCT,
            i.JENT_ERR_APT,
            i.JENT_ERR_LAG,
            i.JENT_ERR_RCT_MEM,
            => if (jent_health_failure_reset(ec_ptr, 1) != 0) return ret,
            else => {
                if (ret < 0) return i.JENT_ERR_EINVAL;
                const generated: usize = @intCast(ret);
                len -= generated;
                offset += generated;
            },
        }
    }
    return @intCast(orig_len);
}

pub fn jent_memsize(flags: c_uint) callconv(.c) u32 {
    var field = i.JENT_FLAGS_TO_MAX_MEMSIZE(flags);
    const max_field = i.JENT_FLAGS_TO_MAX_MEMSIZE(i.JENT_MAX_MEMSIZE_MAX);
    if (field > max_field) field = max_field;
    const shift = if (field == 0) i.JENT_DEFAULT_MEMORY_BITS else field + i.JENT_MAX_MEMSIZE_OFFSET;
    return @as(u32, 1) << @intCast(shift);
}

pub fn jent_hashloop_cnt(flags: c_uint) callconv(.c) c_uint {
    var count = i.JENT_FLAGS_TO_HASHLOOP(flags);
    const max_count = i.JENT_FLAGS_TO_HASHLOOP(i.JENT_MAX_HASHLOOP);
    if (count > max_count) count = max_count;
    return if (count == 0) i.JENT_HASH_LOOP_DEFAULT else @as(c_uint, 1) << @intCast(count - 1);
}

pub fn jent_entropy_collector_alloc_internal(osr_input: c_uint, flags_input: c_uint) callconv(.c) ?*RandData {
    const osr = ensure_osr_is_at_least_minimal(osr_input);
    var flags = flags_input;

    if (flags & (i.JENT_DISABLE_INTERNAL_TIMER | i.JENT_NTG1) != 0 and
        flags & i.JENT_FORCE_INTERNAL_TIMER != 0) return null;
    if (osr > i.JENT_MAX_OSR) return null;
    if (flags & i.JENT_INT_MEASURE_CLOCK == 0 and
        i.jent_atomic_load_int(&jent_selftest_run) == 0 and
        jent_entropy_init_ex(osr, flags) != 0) return null;

    if (flags & i.JENT_NTG1 != 0) flags |= i.JENT_DISABLE_INTERNAL_TIMER;
    if (notimeForced() != 0 and flags & i.JENT_DISABLE_INTERNAL_TIMER != 0) return null;

    const raw = i.jent_zalloc(@sizeOf(RandData), flags) orelse return null;
    const ec: *RandData = @ptrCast(@alignCast(raw));
    ec.setMaxMemSet(if (i.JENT_FLAGS_TO_MAX_MEMSIZE(flags) != 0) 1 else 0);

    if (flags & i.JENT_DISABLE_MEMORY_ACCESS == 0) {
        flags = updateMemsize(flags, 0);
        const memsize = jent_memsize(flags);
        const mem_raw = i.jent_zalloc_unlocked(memsize) orelse {
            jent_entropy_collector_free(ec);
            return null;
        };
        ec.mem = @ptrCast(mem_raw);
        ec.memmask = memsize - 1;
        ec.memaccessloops = i.JENT_MEM_ACC_LOOP_DEFAULT;
    }

    flags = updateHashloop(flags, 0);
    ec.hashloopcnt = jent_hashloop_cnt(flags);
    i.jent_shake256_init(&ec.hash_state);

    if (flags & i.JENT_FORCE_FIPS != 0 or i.jent_fips_enabled() != 0) {
        ec.startup_state = .jent_startup_memory;
        ec.setIsFipsEnabled(1);
    }
    ec.osr = osr;
    ec.flags = flags;
    if (flags & i.JENT_NTG1 != 0) {
        ec.startup_state = .jent_startup_memory;
        ec.setIsFipsEnabled(1);
    }

    const health_type: i.jent_health_init_type = if (flags & i.JENT_NTG1 != 0)
        .jent_health_init_type_ntg1
    else
        .jent_health_init_type_common;
    if (i.jent_health_init(ec, health_type) != 0) {
        jent_entropy_collector_free(ec);
        return null;
    }

    if (flags & i.JENT_DISABLE_INTERNAL_TIMER == 0 and notimeEnable(ec, flags) != 0) {
        jent_entropy_collector_free(ec);
        return null;
    }

    if (i.jent_gcd_get(&ec.jent_common_timer_gcd, ec.enableNotime()) != 0) {
        if (flags & i.JENT_INT_MEASURE_CLOCK == 0) {
            jent_entropy_collector_free(ec);
            return null;
        }
        ec.jent_common_timer_gcd = 1;
    }
    return ec;
}

fn collectorAlloc(osr: c_uint, input_flags: c_uint) ?*RandData {
    if (memaccessContradicts(input_flags)) return null;
    const flags = updateSecureMem(input_flags);
    const initial = jent_entropy_collector_alloc_internal(osr, flags) orelse return null;
    const ec = collectorStartup(initial) orelse return null;
    i.jent_uuid_generate(&ec.uuid);
    return ec;
}

pub fn jent_entropy_collector_alloc(osr: c_uint, flags: c_uint) callconv(.c) ?*RandData {
    const ec = collectorAlloc(osr, flags & ~i.JENT_INT_MEASURE_CLOCK);
    stackScrub();
    return ec;
}

fn entropyInitCommonPre(flags: c_uint) c_int {
    notimeBlockSwitch();
    i.jent_health_cb_block_switch();
    var ret = jent_selftest(null);
    if (ret == 0) ret = i.jent_gcd_selftest(flags);
    if (ret != 0) i.jent_atomic_store_int(&jent_selftest_run, 0);
    return ret;
}

fn entropyInitCommonPost(ret: c_int) c_int {
    i.jent_atomic_store_int(&jent_selftest_run, if (ret == 0) 1 else 0);
    return ret;
}

pub fn jent_raw_selftest(flags: c_uint) callconv(.c) c_int {
    return entropyInitCommonPre(flags);
}

pub fn jent_entropy_collector_alloc_raw(osr: c_uint, input_flags: c_uint) callconv(.c) ?*RandData {
    if (memaccessContradicts(input_flags)) return null;
    if (jent_raw_selftest(input_flags) != 0) return null;
    const flags = updateSecureMem(input_flags);
    return jent_entropy_collector_alloc_internal(osr, flags | i.JENT_INT_MEASURE_CLOCK);
}

pub fn jent_entropy_collector_free(ec_opt: ?*RandData) callconv(.c) void {
    const ec = ec_opt orelse return;
    notimeUnsettick(ec);
    notimeDisable(ec);
    if (ec.mem) |mem| {
        i.jent_zfree(mem, @as(usize, ec.memmask) + 1);
        ec.mem = null;
    }
    i.jent_zfree(ec, @sizeOf(RandData));
}

pub fn jent_time_entropy_init(osr: c_uint, input_flags: c_uint) callconv(.c) c_int {
    const delta_history = i.jent_gcd_init(POWERUP_TESTLOOPCOUNT, input_flags) orelse return i.EMEM;
    var flags = input_flags;
    var ec: ?*RandData = null;
    var gcd: u64 = 0;
    var time_backwards: c_int = 0;
    var count_stuck: c_int = 0;
    var ret: c_int = 0;
    var nelem: usize = 0;

    if (flags & i.JENT_FORCE_INTERNAL_TIMER != 0)
        notimeForce()
    else
        flags |= i.JENT_DISABLE_INTERNAL_TIMER;

    if (notimeForced() != 0 and flags & i.JENT_DISABLE_INTERNAL_TIMER != 0) {
        ret = i.ENOTIME;
    } else {
        flags |= i.JENT_FORCE_FIPS;
        ec = jent_entropy_collector_alloc_internal(osr, flags | i.JENT_INT_MEASURE_CLOCK);
        if (ec == null) {
            ret = i.EMEM;
        } else if (notimeSettick(ec.?) != 0) {
            ret = i.EMEM;
        } else {
            _ = i.jent_measure_jitter(ec.?, 0, null, 0);
            var iteration: c_int = -CLEARCACHE;
            while (iteration < @as(c_int, @intCast(POWERUP_TESTLOOPCOUNT))) : (iteration += 1) {
                const start_time = ec.?.prev_time;
                var delta: u64 = 0;
                const stuck = i.jent_measure_jitter(ec.?, 0, &delta, 1);
                const end_time = ec.?.prev_time;

                if (start_time == 0 or end_time == 0) {
                    ret = i.ENOTIME;
                    break;
                }
                if (delta == 0) {
                    ret = i.ECOARSETIME;
                    break;
                }
                if (iteration < 0) continue;
                if (stuck != 0) count_stuck += 1;
                if (end_time <= start_time) {
                    time_backwards += 1;
                    continue;
                }
                i.jent_gcd_add_value(delta_history, delta, nelem);
                nelem += 1;
            }

            if (ret == 0 and time_backwards > 3) ret = i.ENOMONOTONIC;
            if (ret == 0) {
                const health_result = i.jent_health_failure(ec.?);
                if (health_result != 0) {
                    ret = if (health_result & (i.JENT_RCT_FAILURE | i.JENT_RCT_FAILURE_PERMANENT) != 0)
                        i.ERCT
                    else
                        i.EHEALTH;
                }
            }
            if (ret == 0) ret = i.jent_gcd_verdict(delta_history, nelem, ec.?.osr, &gcd);
            if (ret == 0 and i.jent_stuck_init_thres(POWERUP_TESTLOOPCOUNT) < count_stuck)
                ret = i.ESTUCK;
            if (ret == 0) i.jent_gcd_store(gcd, ec.?.enableNotime());
        }
    }

    i.jent_gcd_fini(delta_history, POWERUP_TESTLOOPCOUNT);
    if (ec) |collector| notimeUnsettick(collector);
    jent_entropy_collector_free(ec);
    return ret;
}

pub fn jent_selftest(ec: ?*RandData) callconv(.c) c_int {
    const ret: c_int = if (i.jent_sha3_tester() != 0) i.EHASH else 0;
    if (ec) |collector|
        i.jent_atomic_store_int(&collector.selftest_failed, if (ret != 0) 1 else 0);
    return ret;
}

pub fn jent_entropy_init() callconv(.c) c_int {
    const flags = updateSecureMem(0);
    var ret = entropyInitCommonPre(flags);
    if (ret != 0) return ret;

    ret = jent_time_entropy_init(0, flags | i.JENT_DISABLE_INTERNAL_TIMER);
    if (i.build_options.internal_timer and ret != 0)
        ret = jent_time_entropy_init(0, flags | i.JENT_FORCE_INTERNAL_TIMER);
    ret = entropyInitCommonPost(ret);
    stackScrub();
    return ret;
}

pub fn jent_entropy_init_ex(osr: c_uint, input_flags: c_uint) callconv(.c) c_int {
    const flags = updateSecureMem(input_flags);
    notimeBlockSwitch();
    i.jent_health_cb_block_switch();

    if (osr > i.JENT_MAX_OSR or memaccessContradicts(flags) or
        (flags & i.JENT_DISABLE_INTERNAL_TIMER != 0 and flags & i.JENT_FORCE_INTERNAL_TIMER != 0))
        return i.EPROGERR;
    if (flags & i.JENT_NTG1 != 0 and flags & i.JENT_FORCE_INTERNAL_TIMER != 0)
        return i.ENOTIME;

    var ret = entropyInitCommonPre(flags);
    if (ret != 0) return ret;
    ret = i.ENOTIME;
    if (flags & i.JENT_FORCE_INTERNAL_TIMER == 0)
        ret = jent_time_entropy_init(osr, flags | i.JENT_DISABLE_INTERNAL_TIMER);
    if (i.build_options.internal_timer and ret != 0 and
        flags & (i.JENT_DISABLE_INTERNAL_TIMER | i.JENT_NTG1) == 0)
        ret = jent_time_entropy_init(osr, flags | i.JENT_FORCE_INTERNAL_TIMER);
    ret = entropyInitCommonPost(ret);
    stackScrub();
    return ret;
}

pub fn jent_entropy_switch_notime_impl(new_thread: ?*i.jent_notime_thread) callconv(.c) c_int {
    return notimeSwitch(new_thread);
}

pub fn jent_entropy_set_notime_cpu(cpu: c_ulong) callconv(.c) c_int {
    return notimeSetCpu(cpu);
}

pub fn jent_set_fips_failure_callback(cb: i.jent_fips_failure_cb) callconv(.c) c_int {
    return i.jent_set_fips_failure_callback_internal(cb);
}

test "configuration decoding" {
    try std.testing.expectEqual(@as(c_uint, i.JENT_MIN_OSR), ensure_osr_is_at_least_minimal(0));
    try std.testing.expectEqual(@as(u32, 1024), jent_memsize(i.JENT_MAX_MEMSIZE_1kB));
    try std.testing.expectEqual(@as(c_uint, 128), jent_hashloop_cnt(i.JENT_HASHLOOP_128));
}
