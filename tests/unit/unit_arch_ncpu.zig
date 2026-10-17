// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const std = @import("std");
const builtin = @import("builtin");
const harness = @import("test_harness.zig");

extern fn jent_ncpu() callconv(.c) c_long;
extern fn jent_cpu_highest() callconv(.c) c_long;
extern fn jent_parse_cpulist(buf: [*:0]const u8) callconv(.c) c_long;

fn expectEqual(actual: c_long, expected: c_long, what: []const u8) !void {
    try harness.expect(
        actual == expected,
        @src(),
        "{s}: got {d}, expected {d}",
        .{ what, actual, expected },
    );
}

fn testCpuCount() !void {
    const count = jent_ncpu();
    if (builtin.os.tag == .freestanding or builtin.os.tag == .uefi) {
        try harness.expect(count < 0, @src(), "freestanding count must fail, got {d}", .{count});
        return;
    }
    try harness.expect(count > 0, @src(), "CPU count must be positive, got {d}", .{count});
    const highest = jent_cpu_highest();
    try harness.expect(highest >= 0, @src(), "highest CPU must be nonnegative, got {d}", .{highest});
    try harness.expect(highest + 1 >= count, @src(), "highest CPU {d} cannot describe count {d}", .{ highest, count });
}

fn testCpuListParser() !void {
    const cases = [_]struct {
        list: [*:0]const u8,
        expected: c_long,
        what: []const u8,
    }{
        .{ .list = "0", .expected = 1, .what = "single CPU" },
        .{ .list = "0\n", .expected = 1, .what = "single CPU with newline" },
        .{ .list = "0-3\n", .expected = 4, .what = "contiguous range" },
        .{ .list = "0,2-5,8\n", .expected = 6, .what = "ranges with holes" },
        .{ .list = "0-0\n", .expected = 1, .what = "one-element range" },
        .{ .list = "0,\n", .expected = 1, .what = "trailing comma" },
        .{ .list = "65535\n", .expected = 1, .what = "largest CPU index" },
        .{ .list = "0-65535\n", .expected = 65536, .what = "largest CPU set" },
    };
    for (cases) |case| {
        try expectEqual(jent_parse_cpulist(case.list), case.expected, case.what);
    }

    const invalid = [_][*:0]const u8{
        "65536\n",
        "0-65536\n",
        "0,1-x\n",
        "99999999999999999999\n",
        "0-99999999999999999999\n",
        "\n",
        "",
        "x\n",
        "-1\n",
        "3-1\n",
        "0-\n",
    };
    for (invalid) |list| {
        try harness.expect(
            jent_parse_cpulist(list) < 0,
            @src(),
            "malformed CPU list was accepted: {s}",
            .{list},
        );
    }
}

pub fn main() !void {
    harness.resetCounters();
    try testCpuCount();
    try testCpuListParser();
    harness.pass("unit-arch-ncpu");
}
