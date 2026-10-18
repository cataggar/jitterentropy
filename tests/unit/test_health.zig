// SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0-only
//
// Unit tests for health tests in src/health.zig, including jent_lag_insert
// ring-buffer wraparound across lag-0, lag-1, and lag-7 distances, scoreboard
// tracking, and cutoff transitions.

const std = @import("std");
const jent = @import("jent");
const health = if (@hasDecl(jent, "health")) jent.health else jent;
const internal = if (@hasDecl(health, "internal")) health.internal else jent;

const rand_data = internal.rand_data;

pub export fn jent_random_data(ec: *rand_data) callconv(.c) void {
    _ = ec;
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
        health.jent_lag_reset(ec);
}

pub fn runLagWraparoundTests() !void {
    var ec: rand_data = .{};
    var ref_ec: rand_data = .{};
    ec.osr = internal.JENT_MIN_OSR;
    ec.setIsFipsEnabled(1);
    try std.testing.expectEqual(@as(c_int, 0), health.jent_health_init(&ec, .jent_health_init_type_common));
    ref_ec = ec;

    // 1. Prime history with 8 distinct deltas (0..JENT_LAG_HISTORY_SIZE).
    for (0..internal.JENT_LAG_HISTORY_SIZE) |i| {
        const d: u64 = 100 + @as(u64, i);
        health.jent_lag_insert(&ec, d);
        referenceLagInsert(&ref_ec, d);
    }
    try std.testing.expectEqual(@as(c_uint, internal.JENT_LAG_HISTORY_SIZE), ec.lag_observations);
    try std.testing.expectEqualSlices(u64, &ref_ec.lag_delta_history, &ec.lag_delta_history);

    // 2. Repeat the 8-element cycle twice (16 observations -> total 24) to produce pure lag-7 hits
    // across 2 full ring-buffer wraparounds.
    for (0..(internal.JENT_LAG_HISTORY_SIZE * 2)) |step| {
        const d: u64 = 100 + @as(u64, step % internal.JENT_LAG_HISTORY_SIZE);
        health.jent_lag_insert(&ec, d);
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
            health.jent_lag_insert(&ec, d);
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

    // 4. Feed constant deltas (lag-0 hits) up to local intermittent and permanent cutoffs.
    var clean_ec: rand_data = .{};
    var clean_ref: rand_data = .{};
    clean_ec.osr = internal.JENT_MIN_OSR;
    clean_ec.setIsFipsEnabled(1);
    try std.testing.expectEqual(@as(c_int, 0), health.jent_health_init(&clean_ec, .jent_health_init_type_common));
    clean_ref = clean_ec;

    const total_to_permanent = internal.JENT_LAG_HISTORY_SIZE + @as(usize, clean_ec.lag_local_cutoff_permanent);
    for (0..total_to_permanent) |step| {
        health.jent_lag_insert(&clean_ec, 0xdeadbeef);
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

test "jent_lag_insert ring-buffer wraparound across lag-0, lag-1, and lag-7 hits" {
    try runLagWraparoundTests();
}

pub fn main() u8 {
    runLagWraparoundTests() catch return 1;
    return 0;
}
