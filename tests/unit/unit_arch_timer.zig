// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const std = @import("std");
const harness = @import("test_harness");

extern fn jent_get_nstime(out: *u64) callconv(.c) void;

pub fn main() !void {
    harness.resetCounters();
    std.debug.print("jent_get_nstime\n", .{});

    var first: u64 = 0;
    jent_get_nstime(&first);
    try harness.expect(first != 0, @src(), "the first reading is not zero", .{});

    var previous = first;
    var moved: usize = 0;
    var backwards: usize = 0;
    for (0..10_000) |_| {
        var now: u64 = 0;
        jent_get_nstime(&now);
        if (now != previous) moved += 1;
        if (now < previous) backwards += 1;
        previous = now;
    }

    try harness.expect(moved != 0, @src(), "the counter changes across repeated reads", .{});
    try harness.expect(backwards < 10, @src(), "the counter does not routinely move backwards", .{});
    if (backwards != 0) {
        std.debug.print("  note: {d} of 10000 reads moved backwards\n", .{backwards});
    }

    harness.pass("unit-arch-timer");
}
