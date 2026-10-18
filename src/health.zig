const std = @import("std");
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

pub fn jent_health_cb_block_switch() callconv(.c) void {
    internal.jent_atomic_store_int(&health_cb_switch_blocked, 1);
}

pub fn jent_set_fips_failure_callback_internal(cb: jent_fips_failure_cb) callconv(.c) c_int {
    if (internal.jent_atomic_load_int(&health_cb_switch_blocked) != 0)
        return -eagain;
    internal.jent_atomic_store_fips_cb(&fips_cb, cb);
    return 0;
}

inline fn lagHistory(ec: *const rand_data, location: usize) u64 {
    const observation: usize = @intCast(ec.lag_observations);
    return ec.lag_delta_history[(observation -% location -% 1) & internal.JENT_LAG_MASK];
}

inline fn lagInit(ec: *rand_data, osr: c_uint) void {
    const index: usize = @intCast(osr - 1);
    ec.lag_global_cutoff = jent_lag_global_cutoff_lookup[index];
    ec.lag_global_cutoff_permanent = jent_lag_global_cutoff_permanent_lookup[index];
    ec.lag_local_cutoff = jent_lag_local_cutoff_lookup[index];
    ec.lag_local_cutoff_permanent = jent_lag_local_cutoff_permanent_lookup[index];
}

pub fn jent_lag_reset(ec: *rand_data) callconv(.c) void {
    ec.lag_prediction_success_count = 0;
    ec.lag_prediction_success_run = 0;
    ec.lag_best_predictor = 0;
    ec.lag_observations = 0;
    ec.lag_scoreboard = @splat(0);
    ec.lag_delta_history = @splat(0);
}

pub fn jent_lag_insert(ec: *rand_data, current_delta: u64) callconv(.c) void {
    const obs: usize = @intCast(ec.lag_observations);
    const history = &ec.lag_delta_history;
    if (obs < internal.JENT_LAG_HISTORY_SIZE) {
        history[obs] = current_delta;
        ec.lag_observations +%= 1;
        return;
    }

    const scoreboard = &ec.lag_scoreboard;
    var best_predictor: usize = @intCast(ec.lag_best_predictor);
    const prediction = history[(obs - 1 -% best_predictor) & internal.JENT_LAG_MASK];
    if (prediction == current_delta) {
        const count = ec.lag_prediction_success_count +% 1;
        const run = ec.lag_prediction_success_run +% 1;
        ec.lag_prediction_success_count = count;
        ec.lag_prediction_success_run = run;
        if (run >= ec.lag_local_cutoff_permanent or
            count >= ec.lag_global_cutoff_permanent)
        {
            ec.health_failure |= internal.JENT_LAG_FAILURE_PERMANENT;
        } else if (run >= ec.lag_local_cutoff or
            count >= ec.lag_global_cutoff)
        {
            ec.health_failure |= internal.JENT_LAG_FAILURE;
        }
    } else {
        ec.lag_prediction_success_run = 0;
    }

    for (0..internal.JENT_LAG_HISTORY_SIZE) |i| {
        const idx = (obs - 1 - i) & internal.JENT_LAG_MASK;
        if (history[idx] == current_delta) {
            const score = scoreboard[i] +% 1;
            scoreboard[i] = score;
            if (score > scoreboard[best_predictor]) {
                best_predictor = i;
                ec.lag_best_predictor = @intCast(i);
            }
        }
    }

    history[obs & internal.JENT_LAG_MASK] = current_delta;
    const next_obs = ec.lag_observations +% 1;
    ec.lag_observations = next_obs;
    if (next_obs >= internal.JENT_LAG_WINDOW_SIZE)
        jent_lag_reset(ec);
}

inline fn delta2(ec: *rand_data, current_delta: u64) u64 {
    return internal.jent_delta(lagHistory(ec, 0), current_delta);
}

inline fn delta3(ec: *rand_data, current_delta2: u64) u64 {
    return internal.jent_delta(
        internal.jent_delta(lagHistory(ec, 1), lagHistory(ec, 0)),
        current_delta2,
    );
}

pub fn jent_lag_duplicate(new_ec: *rand_data, old_ec: *rand_data) callconv(.c) void {
    new_ec.lag_prediction_success_run = old_ec.lag_prediction_success_run;
    new_ec.lag_prediction_success_count = old_ec.lag_prediction_success_count;
    new_ec.lag_best_predictor = old_ec.lag_best_predictor;
    new_ec.lag_observations = old_ec.lag_observations;
    new_ec.lag_scoreboard = old_ec.lag_scoreboard;
    new_ec.lag_delta_history = old_ec.lag_delta_history;
}

inline fn aptInit(ec: *rand_data, ntg1: bool) void {
    const index: usize = @intCast(ec.osr - 1);
    if (ntg1) {
        ec.apt_cutoff = jent_apt_cutoff_lookup_ntg1[index];
        ec.apt_cutoff_permanent = jent_apt_cutoff_permanent_lookup_ntg1[index];
    } else {
        ec.apt_cutoff = jent_apt_cutoff_lookup[index];
        ec.apt_cutoff_permanent = jent_apt_cutoff_permanent_lookup[index];
    }
}

inline fn aptReinit(ec: *rand_data, current_delta: u64, apt_count: c_uint, apt_observations: c_uint) void {
    ec.apt_base = current_delta;
    ec.setAptBaseSet(1);
    ec.apt_count = if (apt_count != 0) apt_count else ec.apt_cutoff;
    ec.apt_observations = apt_observations;
}

pub fn jent_apt_duplicate(new_ec: *rand_data, old_ec: *rand_data) callconv(.c) void {
    if (old_ec.apt_observations != 0)
        aptReinit(new_ec, old_ec.apt_base, 0, old_ec.apt_observations);
}

inline fn aptReset(ec: *rand_data) void {
    ec.setAptBaseSet(0);
}

pub fn jent_apt_insert(ec: *rand_data, delta: u64) callconv(.c) void {
    const current_delta = delta & internal.JENT_APT_MASK;
    if (ec.aptBaseSet() == 0) {
        aptReinit(ec, current_delta, 1, 1);
        return;
    }

    if (current_delta == ec.apt_base) {
        const count = ec.apt_count +% 1;
        ec.apt_count = count;
        if (count >= ec.apt_cutoff_permanent)
            ec.health_failure |= internal.JENT_APT_FAILURE_PERMANENT
        else if (count == ec.apt_cutoff)
            ec.health_failure |= internal.JENT_APT_FAILURE;
    }

    const obs = ec.apt_observations +% 1;
    ec.apt_observations = obs;
    if (obs >= internal.JENT_APT_WINDOW_SIZE)
        aptReset(ec);
}

inline fn rctMemInit(ec: *rand_data, ntg1: bool) void {
    const index: usize = @intCast(ec.osr - 1);
    if (ntg1) {
        ec.rct_mem_cutoff = jent_rct_mem_cutoff_lookup_ntg1[index];
        ec.rct_mem_cutoff_permanent = jent_rct_mem_cutoff_permanent_lookup_ntg1[index];
    } else {
        ec.rct_mem_cutoff = jent_rct_mem_cutoff_lookup[index];
        ec.rct_mem_cutoff_permanent = jent_rct_mem_cutoff_permanent_lookup[index];
    }
}

pub fn jent_rct_mem_insert(ec: *rand_data, stuck: c_uint) callconv(.c) void {
    const ctr = ec.rct_mem_ctr;
    var count = if (ctr == 0) blk: {
        ec.rct_mem_count = 0;
        break :blk @as(c_ushort, 0);
    } else ec.rct_mem_count;

    const in_window = ctr < ec.rct_mem_nosr;
    const skip_stuck = ctr % 3 != 0;
    if (stuck != 0 and in_window and !skip_stuck) {
        count +%= 1;
        ec.rct_mem_count = count;
    }

    if (count >= ec.rct_mem_cutoff_permanent) {
        if (in_window)
            ec.health_failure |= internal.JENT_RCT_MEM_FAILURE_PERMANENT;
    } else if (count == ec.rct_mem_cutoff) {
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

pub fn jent_rct_mem_duplicate(new_ec: *rand_data, old_ec: *rand_data) callconv(.c) void {
    _ = old_ec;
    new_ec.rct_mem_count = new_ec.rct_mem_cutoff;
}

inline fn rctInit(ec: *rand_data, safety: c_ushort) void {
    const osr: c_ushort = @intCast(ec.osr);
    var cutoff = internal.jent_health_rct_intermittent_cutoff(osr);
    var cutoff_permanent = internal.jent_health_rct_permanent_cutoff(osr);
    if (safety != 0) {
        cutoff = (cutoff + safety - 1) / safety;
        cutoff_permanent = (cutoff_permanent + safety - 1) / safety;
    }
    ec.rct_cutoff = cutoff;
    ec.rct_cutoff_permanent = cutoff_permanent;
}

pub fn jent_rct_duplicate(new_ec: *rand_data) callconv(.c) void {
    new_ec.rct_count = new_ec.rct_cutoff;
}

pub fn jent_health_duplicate(new_ec: *rand_data, old_ec: *rand_data) callconv(.c) void {
    jent_rct_duplicate(new_ec);
    jent_rct_mem_duplicate(new_ec, old_ec);
    if (new_ec.enableNotime() != old_ec.enableNotime())
        return;
    jent_apt_duplicate(new_ec, old_ec);
    jent_lag_duplicate(new_ec, old_ec);
}

pub fn jent_rct_insert(ec: *rand_data, stuck: c_uint) callconv(.c) void {
    if (stuck != 0) {
        const count = ec.rct_count +% 1;
        ec.rct_count = count;
        if (count >= ec.rct_cutoff_permanent)
            ec.health_failure |= internal.JENT_RCT_FAILURE_PERMANENT
        else if (count == ec.rct_cutoff)
            ec.health_failure |= internal.JENT_RCT_FAILURE;
    } else {
        ec.rct_count = 0;
    }
}

pub fn jent_stuck(ec: *rand_data, current_delta: u64) callconv(.c) c_uint {
    const current_delta2 = delta2(ec, current_delta);
    const current_delta3 = delta3(ec, current_delta2);
    const stuck: c_uint = @intFromBool(current_delta == 0 or current_delta2 == 0 or current_delta3 == 0);

    const prime = ec.stuckPrime();
    if (prime != 0) {
        ec.setStuckPrime(prime - 1);
        jent_lag_insert(ec, current_delta);
        return 1;
    }

    jent_apt_insert(ec, current_delta);
    jent_lag_insert(ec, current_delta);
    jent_rct_insert(ec, stuck);
    jent_rct_mem_insert(ec, stuck);
    return stuck;
}

pub fn jent_health_insert_timestamp(ec: *rand_data, timestamp: u64) callconv(.c) c_uint {
    const gcd = if (ec.jent_common_timer_gcd != 0) ec.jent_common_timer_gcd else 1;
    const current_delta = internal.jent_udiv64(internal.jent_delta(ec.prev_time, timestamp), gcd);
    ec.prev_time = timestamp;
    return jent_stuck(ec, current_delta);
}

pub fn jent_health_failure_query(ec: *const rand_data) callconv(.c) c_uint {
    if (ec.isFipsEnabled() == 0)
        return 0;
    return ec.health_failure;
}

pub fn jent_health_failure(ec: *rand_data) callconv(.c) c_uint {
    const failure = jent_health_failure_query(ec);
    if (failure == 0)
        return 0;
    const callback = internal.jent_atomic_load_fips_cb(&fips_cb);
    if (callback) |cb|
        cb(ec, failure);
    return failure;
}

pub fn jent_health_init(ec: *rand_data, inittype: jent_health_init_type) callconv(.c) c_int {
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

fn referenceLagInsert(ec: *rand_data, current_delta: u64) void {
    if (ec.lag_observations < internal.JENT_LAG_HISTORY_SIZE) {
        ec.lag_delta_history[@intCast(ec.lag_observations)] = current_delta;
        ec.lag_observations +%= 1;
        return;
    }

    const obs_usize: usize = @intCast(ec.lag_observations);
    const best_usize: usize = @intCast(ec.lag_best_predictor);
    const prediction = ec.lag_delta_history[(obs_usize -% best_usize -% 1) & internal.JENT_LAG_MASK];
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
        const hist = ec.lag_delta_history[(obs_usize -% i -% 1) & internal.JENT_LAG_MASK];
        if (hist == current_delta) {
            ec.lag_scoreboard[i] +%= 1;
            if (ec.lag_scoreboard[i] > ec.lag_scoreboard[@intCast(ec.lag_best_predictor)])
                ec.lag_best_predictor = @intCast(i);
        }
    }

    ec.lag_delta_history[obs_usize & internal.JENT_LAG_MASK] = current_delta;
    ec.lag_observations +%= 1;
    if (ec.lag_observations >= internal.JENT_LAG_WINDOW_SIZE)
        jent_lag_reset(ec);
}

test "jent_lag_insert ring-buffer wraparound across lag-0, lag-1, and lag-7 hits" {
    var ec: rand_data = .{};
    var ref_ec: rand_data = .{};
    ec.osr = internal.JENT_MIN_OSR;
    ec.setIsFipsEnabled(1);
    try std.testing.expectEqual(@as(c_int, 0), jent_health_init(&ec, .jent_health_init_type_common));
    ref_ec = ec;

    // 1. Prime history with 8 distinct deltas (0..JENT_LAG_HISTORY_SIZE).
    for (0..internal.JENT_LAG_HISTORY_SIZE) |i| {
        const d: u64 = 100 + @as(u64, i);
        jent_lag_insert(&ec, d);
        referenceLagInsert(&ref_ec, d);
    }
    try std.testing.expectEqual(@as(c_uint, internal.JENT_LAG_HISTORY_SIZE), ec.lag_observations);
    try std.testing.expectEqualSlices(u64, &ref_ec.lag_delta_history, &ec.lag_delta_history);

    // 2. Repeat the 8-element cycle twice (16 observations -> total 24) to produce pure lag-7 hits
    // across 2 full ring-buffer wraparounds.
    for (0..(internal.JENT_LAG_HISTORY_SIZE * 2)) |step| {
        const d: u64 = 100 + @as(u64, step % internal.JENT_LAG_HISTORY_SIZE);
        jent_lag_insert(&ec, d);
        referenceLagInsert(&ref_ec, d);
        try std.testing.expectEqual(ref_ec.lag_best_predictor, ec.lag_best_predictor);
        try std.testing.expectEqual(ref_ec.lag_prediction_success_count, ec.lag_prediction_success_count);
        try std.testing.expectEqual(ref_ec.lag_prediction_success_run, ec.lag_prediction_success_run);
        try std.testing.expectEqualSlices(c_uint, &ref_ec.lag_scoreboard, &ec.lag_scoreboard);
        try std.testing.expectEqualSlices(u64, &ref_ec.lag_delta_history, &ec.lag_delta_history);
    }
    try std.testing.expectEqual(@as(c_uint, 7), ec.lag_best_predictor);
    try std.testing.expectEqual(@as(c_uint, 16), ec.lag_scoreboard[7]);
    try std.testing.expectEqual(@as(c_uint, 15), ec.lag_prediction_success_count);
    try std.testing.expectEqual(@as(c_uint, 15), ec.lag_prediction_success_run);
    for (0..7) |k| {
        try std.testing.expectEqual(@as(c_uint, 0), ec.lag_scoreboard[k]);
    }

    // 3. Feed 17 triples (A, B, A) = 51 observations (total 75 > JENT_LAG_HISTORY_SIZE * 4)
    // where the third element of each triple matches ONLY lag-1 (distance 2), overtaking lag-7.
    for (0..17) |group| {
        const base_val: u64 = 1000 + @as(u64, group) * 10;
        const triple = [3]u64{ base_val, base_val + 1, base_val };
        for (triple) |d| {
            jent_lag_insert(&ec, d);
            referenceLagInsert(&ref_ec, d);
            try std.testing.expectEqual(ref_ec.lag_best_predictor, ec.lag_best_predictor);
            try std.testing.expectEqual(ref_ec.lag_prediction_success_count, ec.lag_prediction_success_count);
            try std.testing.expectEqual(ref_ec.lag_prediction_success_run, ec.lag_prediction_success_run);
            try std.testing.expectEqualSlices(c_uint, &ref_ec.lag_scoreboard, &ec.lag_scoreboard);
            try std.testing.expectEqualSlices(u64, &ref_ec.lag_delta_history, &ec.lag_delta_history);
        }
    }
    try std.testing.expect(ec.lag_observations > internal.JENT_LAG_HISTORY_SIZE * 4);
    try std.testing.expectEqual(@as(c_uint, 1), ec.lag_best_predictor);
    try std.testing.expectEqual(@as(c_uint, 17), ec.lag_scoreboard[1]);
    try std.testing.expectEqual(@as(c_uint, 16), ec.lag_scoreboard[7]);

    // 4. Feed constant deltas (lag-0 hits, followed by all lags matching) up to local intermittent
    // and permanent cutoffs, verifying exact cutoff transitions.
    var clean_ec: rand_data = .{};
    var clean_ref: rand_data = .{};
    clean_ec.osr = internal.JENT_MIN_OSR;
    clean_ec.setIsFipsEnabled(1);
    try std.testing.expectEqual(@as(c_int, 0), jent_health_init(&clean_ec, .jent_health_init_type_common));
    clean_ref = clean_ec;

    const total_to_permanent = internal.JENT_LAG_HISTORY_SIZE + @as(usize, clean_ec.lag_local_cutoff_permanent);
    for (0..total_to_permanent) |step| {
        jent_lag_insert(&clean_ec, 0xdeadbeef);
        referenceLagInsert(&clean_ref, 0xdeadbeef);
        try std.testing.expectEqual(clean_ref.health_failure, clean_ec.health_failure);
        try std.testing.expectEqual(clean_ref.lag_best_predictor, clean_ec.lag_best_predictor);
        try std.testing.expectEqual(clean_ref.lag_prediction_success_run, clean_ec.lag_prediction_success_run);
        try std.testing.expectEqual(clean_ref.lag_prediction_success_count, clean_ec.lag_prediction_success_count);
        if (step + 1 < internal.JENT_LAG_HISTORY_SIZE + @as(usize, clean_ec.lag_local_cutoff)) {
            try std.testing.expectEqual(@as(c_uint, 0), clean_ec.health_failure);
        } else if (step + 1 < total_to_permanent) {
            try std.testing.expectEqual(internal.JENT_LAG_FAILURE, clean_ec.health_failure);
        } else {
            try std.testing.expectEqual(
                internal.JENT_LAG_FAILURE | internal.JENT_LAG_FAILURE_PERMANENT,
                clean_ec.health_failure,
            );
        }
    }
    try std.testing.expectEqual(@as(c_uint, 0), clean_ec.lag_best_predictor);
}
