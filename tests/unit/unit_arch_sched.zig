// SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0-only

const harness = @import("test_harness.zig");

extern fn jent_yield() callconv(.c) void;

pub fn main() void {
    harness.resetCounters();
    jent_yield();
    harness.expectOrExit(true, @src(), "jent_yield returned", .{});
    harness.pass("unit-arch-sched");
}
