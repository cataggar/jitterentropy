const builtin = @import("builtin");
pub const internal = @import("internal.zig");

const rand_data = internal.rand_data;
const jent_health_init_type = internal.jent_health_init_type;
const jent_fips_failure_cb = internal.jent_fips_failure_cb;
const eagain: c_int = switch (builtin.os.tag) {
    .macos, .ios, .tvos, .watchos, .freebsd, .netbsd, .openbsd, .dragonfly => 35,
    .wasi => 6,
    else => 11,
};

const jent_lag_global_cutoff_lookup = [20]c_uint{
    66444,  93505,  104762, 110876, 114708, 117331, 119238, 120687, 121824, 122740,
    123494, 124125, 124661, 125121, 125521, 125872, 126182, 126458, 126705, 126927,
};
const jent_lag_global_cutoff_permanent_lookup = [20]c_uint{
    66877,  93897,  105109, 111189, 114994, 117597, 119487, 120921, 122046, 122952,
    123697, 124319, 124848, 125302, 125696, 126042, 126347, 126618, 126861, 127080,
};
const jent_lag_local_cutoff_lookup = [20]c_uint{
    38,  75,  111, 146, 181, 215, 250, 284, 318, 351,
    385, 419, 452, 485, 518, 551, 584, 617, 650, 683,
};
const jent_lag_local_cutoff_permanent_lookup = [20]c_uint{
    60,  119, 177, 234, 291, 347, 404, 460,  516,  571,
    627, 683, 738, 793, 848, 903, 958, 1013, 1068, 1123,
};

const jent_apt_cutoff_lookup = [20]c_uint{
    325, 422, 459, 477, 488, 494, 499, 502, 505, 507,
    508, 509, 510, 511, 512, 512, 512, 512, 512, 512,
};
const jent_apt_cutoff_permanent_lookup = [20]c_uint{
    355, 447, 479, 494, 502, 507, 510, 512, 512, 512,
    512, 512, 512, 512, 512, 512, 512, 512, 512, 512,
};
const jent_apt_cutoff_lookup_ntg1 = [20]c_uint{
    17,  71,  136, 191, 236, 272, 301, 325, 345, 361,
    375, 388, 398, 407, 415, 422, 429, 434, 439, 444,
};
const jent_apt_cutoff_permanent_lookup_ntg1 = [20]c_uint{
    26,  92,  162, 221, 267, 303, 332, 355, 375, 390,
    404, 415, 425, 433, 440, 447, 453, 458, 462, 466,
};

const jent_rct_mem_cutoff_lookup = [20]c_ushort{
    107,  214,  321,  428,  535,  642,  749,  856,  963,  1070,
    1177, 1284, 1391, 1498, 1605, 1712, 1819, 1926, 2033, 2140,
};
const jent_rct_mem_cutoff_permanent_lookup = [20]c_ushort{
    108,  215,  322,  429,  536,  643,  750,  857,  964,  1071,
    1178, 1285, 1392, 1499, 1606, 1713, 1820, 1927, 2034, 2141,
};
const jent_rct_mem_cutoff_lookup_ntg1 = [20]c_ushort{
    4,    46,   134,  255,  399,  560,  733,  856,  963,  1070,
    1177, 1284, 1391, 1498, 1605, 1712, 1819, 1926, 2033, 2140,
};
const jent_rct_mem_cutoff_permanent_lookup_ntg1 = [20]c_ushort{
    5,    50,   142,  265,  410,  572,  746,  857,  964,  1071,
    1178, 1285, 1392, 1499, 1606, 1713, 1820, 1927, 2034, 2141,
};

comptime {
    if (jent_lag_global_cutoff_lookup.len != internal.JENT_MAX_OSR or
        jent_lag_global_cutoff_permanent_lookup.len != internal.JENT_MAX_OSR or
        jent_lag_local_cutoff_lookup.len != internal.JENT_MAX_OSR or
        jent_lag_local_cutoff_permanent_lookup.len != internal.JENT_MAX_OSR or
        jent_apt_cutoff_lookup.len != internal.JENT_MAX_OSR or
        jent_apt_cutoff_permanent_lookup.len != internal.JENT_MAX_OSR or
        jent_apt_cutoff_lookup_ntg1.len != internal.JENT_MAX_OSR or
        jent_apt_cutoff_permanent_lookup_ntg1.len != internal.JENT_MAX_OSR or
        jent_rct_mem_cutoff_lookup.len != internal.JENT_MAX_OSR or
        jent_rct_mem_cutoff_permanent_lookup.len != internal.JENT_MAX_OSR or
        jent_rct_mem_cutoff_lookup_ntg1.len != internal.JENT_MAX_OSR or
        jent_rct_mem_cutoff_permanent_lookup_ntg1.len != internal.JENT_MAX_OSR)
        @compileError("health cutoff table does not cover every supported OSR");
}

var fips_cb: jent_fips_failure_cb = null;
var health_cb_switch_blocked: c_int = 0;

pub export fn jent_health_cb_block_switch() callconv(.c) void {
    internal.jent_atomic_store_int(&health_cb_switch_blocked, 1);
}

pub export fn jent_set_fips_failure_callback_internal(cb: jent_fips_failure_cb) callconv(.c) c_int {
    if (internal.jent_atomic_load_int(&health_cb_switch_blocked) != 0)
        return -eagain;
    internal.jent_atomic_store_fips_cb(&fips_cb, cb);
    return 0;
}

fn lagHistory(ec: *const rand_data, location: usize) u64 {
    const observation: usize = @intCast(ec.lag_observations);
    return ec.lag_delta_history[(observation -% location -% 1) & internal.JENT_LAG_MASK];
}

fn lagInit(ec: *rand_data, osr: c_uint) void {
    const index: usize = @intCast(osr - 1);
    ec.lag_global_cutoff = jent_lag_global_cutoff_lookup[index];
    ec.lag_global_cutoff_permanent = jent_lag_global_cutoff_permanent_lookup[index];
    ec.lag_local_cutoff = jent_lag_local_cutoff_lookup[index];
    ec.lag_local_cutoff_permanent = jent_lag_local_cutoff_permanent_lookup[index];
}

pub export fn jent_lag_reset(ec: *rand_data) callconv(.c) void {
    ec.lag_prediction_success_count = 0;
    ec.lag_prediction_success_run = 0;
    ec.lag_best_predictor = 0;
    ec.lag_observations = 0;
    ec.lag_scoreboard = @splat(0);
    ec.lag_delta_history = @splat(0);
}

pub export fn jent_lag_insert(ec: *rand_data, current_delta: u64) callconv(.c) void {
    if (ec.lag_observations < internal.JENT_LAG_HISTORY_SIZE) {
        ec.lag_delta_history[@intCast(ec.lag_observations)] = current_delta;
        ec.lag_observations +%= 1;
        return;
    }

    const prediction = lagHistory(ec, @intCast(ec.lag_best_predictor));
    if (prediction == current_delta) {
        ec.lag_prediction_success_count +%= 1;
        ec.lag_prediction_success_run +%= 1;
        if (ec.lag_prediction_success_run >= ec.lag_local_cutoff_permanent or
            ec.lag_prediction_success_count >= ec.lag_global_cutoff_permanent)
        {
            ec.health_failure |= internal.JENT_LAG_FAILURE_PERMANENT;
        } else if (ec.lag_prediction_success_run >= ec.lag_local_cutoff or
            ec.lag_prediction_success_count >= ec.lag_global_cutoff)
        {
            ec.health_failure |= internal.JENT_LAG_FAILURE;
        }
    } else {
        ec.lag_prediction_success_run = 0;
    }

    for (0..internal.JENT_LAG_HISTORY_SIZE) |i| {
        if (lagHistory(ec, i) == current_delta) {
            ec.lag_scoreboard[i] +%= 1;
            if (ec.lag_scoreboard[i] > ec.lag_scoreboard[@intCast(ec.lag_best_predictor)])
                ec.lag_best_predictor = @intCast(i);
        }
    }

    ec.lag_delta_history[@as(usize, @intCast(ec.lag_observations)) & internal.JENT_LAG_MASK] = current_delta;
    ec.lag_observations +%= 1;
    if (ec.lag_observations >= internal.JENT_LAG_WINDOW_SIZE)
        jent_lag_reset(ec);
}

fn delta2(ec: *rand_data, current_delta: u64) u64 {
    return internal.jent_delta(lagHistory(ec, 0), current_delta);
}

fn delta3(ec: *rand_data, current_delta2: u64) u64 {
    return internal.jent_delta(
        internal.jent_delta(lagHistory(ec, 1), lagHistory(ec, 0)),
        current_delta2,
    );
}

pub export fn jent_lag_duplicate(new_ec: *rand_data, old_ec: *rand_data) callconv(.c) void {
    new_ec.lag_prediction_success_run = old_ec.lag_prediction_success_run;
    new_ec.lag_prediction_success_count = old_ec.lag_prediction_success_count;
    new_ec.lag_best_predictor = old_ec.lag_best_predictor;
    new_ec.lag_observations = old_ec.lag_observations;
    new_ec.lag_scoreboard = old_ec.lag_scoreboard;
    new_ec.lag_delta_history = old_ec.lag_delta_history;
}

fn aptInit(ec: *rand_data, ntg1: bool) void {
    const index: usize = @intCast(ec.osr - 1);
    if (ntg1) {
        ec.apt_cutoff = jent_apt_cutoff_lookup_ntg1[index];
        ec.apt_cutoff_permanent = jent_apt_cutoff_permanent_lookup_ntg1[index];
    } else {
        ec.apt_cutoff = jent_apt_cutoff_lookup[index];
        ec.apt_cutoff_permanent = jent_apt_cutoff_permanent_lookup[index];
    }
}

fn aptReinit(ec: *rand_data, current_delta: u64, apt_count: c_uint, apt_observations: c_uint) void {
    ec.apt_base = current_delta;
    ec.setAptBaseSet(1);
    ec.apt_count = if (apt_count != 0) apt_count else ec.apt_cutoff;
    ec.apt_observations = apt_observations;
}

pub export fn jent_apt_duplicate(new_ec: *rand_data, old_ec: *rand_data) callconv(.c) void {
    if (old_ec.apt_observations != 0)
        aptReinit(new_ec, old_ec.apt_base, 0, old_ec.apt_observations);
}

fn aptReset(ec: *rand_data) void {
    ec.setAptBaseSet(0);
}

pub export fn jent_apt_insert(ec: *rand_data, delta: u64) callconv(.c) void {
    const current_delta = delta & internal.JENT_APT_MASK;
    if (ec.aptBaseSet() == 0) {
        aptReinit(ec, current_delta, 1, 1);
        return;
    }

    if (current_delta == ec.apt_base) {
        ec.apt_count +%= 1;
        if (ec.apt_count >= ec.apt_cutoff_permanent)
            ec.health_failure |= internal.JENT_APT_FAILURE_PERMANENT
        else if (ec.apt_count == ec.apt_cutoff)
            ec.health_failure |= internal.JENT_APT_FAILURE;
    }

    ec.apt_observations +%= 1;
    if (ec.apt_observations >= internal.JENT_APT_WINDOW_SIZE)
        aptReset(ec);
}

fn rctMemInit(ec: *rand_data, ntg1: bool) void {
    const index: usize = @intCast(ec.osr - 1);
    if (ntg1) {
        ec.rct_mem_cutoff = jent_rct_mem_cutoff_lookup_ntg1[index];
        ec.rct_mem_cutoff_permanent = jent_rct_mem_cutoff_permanent_lookup_ntg1[index];
    } else {
        ec.rct_mem_cutoff = jent_rct_mem_cutoff_lookup[index];
        ec.rct_mem_cutoff_permanent = jent_rct_mem_cutoff_permanent_lookup[index];
    }
}

pub export fn jent_rct_mem_insert(ec: *rand_data, stuck: c_uint) callconv(.c) void {
    if (ec.rct_mem_ctr == 0)
        ec.rct_mem_count = 0;

    const in_window = ec.rct_mem_ctr < ec.rct_mem_nosr;
    const skip_stuck = ec.rct_mem_ctr % 3 != 0;
    if (stuck != 0 and in_window and !skip_stuck)
        ec.rct_mem_count +%= 1;

    if (ec.rct_mem_count >= ec.rct_mem_cutoff_permanent) {
        if (in_window)
            ec.health_failure |= internal.JENT_RCT_MEM_FAILURE_PERMANENT;
    } else if (ec.rct_mem_count == ec.rct_mem_cutoff) {
        if (ec.inRecovery() == 0) {
            const saved_state = ec.startup_state;
            ec.rct_mem_count = 0;
            ec.setInRecovery(1);
            ec.startup_state = .jent_startup_completed;
            for (0..10) |_|
                internal.jent_random_data(ec);
            ec.startup_state = saved_state;
            ec.setInRecovery(0);
        } else if (in_window) {
            ec.health_failure |= internal.JENT_RCT_MEM_FAILURE;
        }
    }

    if (in_window)
        ec.rct_mem_ctr +%= 1;
}

pub export fn jent_rct_mem_duplicate(new_ec: *rand_data, old_ec: *rand_data) callconv(.c) void {
    _ = old_ec;
    new_ec.rct_mem_count = new_ec.rct_mem_cutoff;
}

fn rctInit(ec: *rand_data, safety: c_ushort) void {
    const osr: c_ushort = @intCast(ec.osr);
    ec.rct_cutoff = internal.jent_health_rct_intermittent_cutoff(osr);
    ec.rct_cutoff_permanent = internal.jent_health_rct_permanent_cutoff(osr);
    if (safety != 0) {
        ec.rct_cutoff = (ec.rct_cutoff + safety - 1) / safety;
        ec.rct_cutoff_permanent = (ec.rct_cutoff_permanent + safety - 1) / safety;
    }
}

pub export fn jent_rct_duplicate(new_ec: *rand_data) callconv(.c) void {
    new_ec.rct_count = new_ec.rct_cutoff;
}

pub export fn jent_health_duplicate(new_ec: *rand_data, old_ec: *rand_data) callconv(.c) void {
    jent_rct_duplicate(new_ec);
    jent_rct_mem_duplicate(new_ec, old_ec);
    if (new_ec.enableNotime() != old_ec.enableNotime())
        return;
    jent_apt_duplicate(new_ec, old_ec);
    jent_lag_duplicate(new_ec, old_ec);
}

pub export fn jent_rct_insert(ec: *rand_data, stuck: c_uint) callconv(.c) void {
    if (stuck != 0) {
        ec.rct_count +%= 1;
        if (ec.rct_count >= ec.rct_cutoff_permanent)
            ec.health_failure |= internal.JENT_RCT_FAILURE_PERMANENT
        else if (ec.rct_count == ec.rct_cutoff)
            ec.health_failure |= internal.JENT_RCT_FAILURE;
    } else {
        ec.rct_count = 0;
    }
}

pub export fn jent_stuck(ec: *rand_data, current_delta: u64) callconv(.c) c_uint {
    const current_delta2 = delta2(ec, current_delta);
    const current_delta3 = delta3(ec, current_delta2);
    const stuck: c_uint = @intFromBool(current_delta == 0 or current_delta2 == 0 or current_delta3 == 0);

    if (ec.stuckPrime() != 0) {
        ec.setStuckPrime(ec.stuckPrime() - 1);
        jent_lag_insert(ec, current_delta);
        return 1;
    }

    jent_apt_insert(ec, current_delta);
    jent_lag_insert(ec, current_delta);
    jent_rct_insert(ec, stuck);
    jent_rct_mem_insert(ec, stuck);
    return stuck;
}

pub export fn jent_health_insert_timestamp(ec: *rand_data, timestamp: u64) callconv(.c) c_uint {
    const gcd = if (ec.jent_common_timer_gcd != 0) ec.jent_common_timer_gcd else 1;
    const current_delta = internal.jent_udiv64(internal.jent_delta(ec.prev_time, timestamp), gcd);
    ec.prev_time = timestamp;
    return jent_stuck(ec, current_delta);
}

pub export fn jent_health_failure_query(ec: *const rand_data) callconv(.c) c_uint {
    if (ec.isFipsEnabled() == 0)
        return 0;
    return ec.health_failure;
}

pub export fn jent_health_failure(ec: *rand_data) callconv(.c) c_uint {
    const failure = jent_health_failure_query(ec);
    if (failure == 0)
        return 0;
    const callback = internal.jent_atomic_load_fips_cb(&fips_cb);
    if (callback) |cb|
        cb(ec, failure);
    return failure;
}

pub export fn jent_health_init(ec: *rand_data, inittype: jent_health_init_type) callconv(.c) c_int {
    ec.rct_count = 0;
    if (ec.osr == 0 or ec.osr > internal.JENT_MAX_OSR)
        return 1;

    aptReset(ec);
    jent_lag_reset(ec);
    ec.setStuckPrime(internal.JENT_STUCK_PRIME);
    lagInit(ec, ec.osr);

    switch (inittype) {
        .jent_health_init_type_ntg1 => {
            aptInit(ec, true);
            rctInit(ec, 8);
            rctMemInit(ec, true);
        },
        .jent_health_init_type_common => {
            aptInit(ec, false);
            rctInit(ec, 0);
            rctMemInit(ec, false);
        },
    }
    return 0;
}
