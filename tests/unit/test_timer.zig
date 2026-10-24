// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const std = @import("std");
const builtin = @import("builtin");
const h = @import("test_harness");
const jent = @import("internal");

fn expect(cond: bool, comptime message: []const u8) void {
    h.expectOrExit(cond, @src(), "{s}", .{message});
}

fn skip(comptime message: []const u8) void {
    h.skipOrExit(@src(), "{s}", .{message});
}

fn testAtomicNotimeTimerAndInterrupt() void {
    if (comptime !jent.build_options.internal_timer) {
        skip("the internal timer is not compiled in");
        return;
    }
    if (comptime builtin.single_threaded) {
        skip("single-threaded build");
        return;
    }

    var ec: jent.rand_data = std.mem.zeroes(jent.rand_data);
    ec.setNotimeInterrupt(0);
    ec.setNotimeTimer(0);

    const Worker = struct {
        fn tickLoop(collector: *jent.rand_data) void {
            while (collector.getNotimeInterrupt() == 0) {
                collector.setNotimeTimer(collector.getNotimeTimer() +% 1);
            }
        }
    };

    const thread = std.Thread.spawn(.{}, Worker.tickLoop, .{&ec}) catch {
        skip("thread spawn not available");
        return;
    };
    while (ec.getNotimeTimer() < 64) {
        jent.jent_yield();
    }
    expect(ec.getNotimeTimer() >= 64, "atomic timer counter advances across threads");
    ec.setNotimeInterrupt(1);
    thread.join();
    expect(ec.getNotimeInterrupt() == 1, "atomic interrupt flag stops worker thread");
}

fn testConcurrentSetNotimeCpu() void {
    if (comptime !jent.build_options.internal_timer) {
        skip("the internal timer is not compiled in");
        return;
    }
    if (comptime builtin.single_threaded) {
        skip("single-threaded build");
        return;
    }

    const Worker = struct {
        fn setCpuLoop(base_cpu: c_ulong) void {
            var i: c_ulong = 0;
            while (i < 256) : (i += 1) {
                _ = jent.jent_entropy_set_notime_cpu(base_cpu + (i & 3));
            }
        }
    };

    const t1 = std.Thread.spawn(.{}, Worker.setCpuLoop, .{0}) catch {
        skip("thread spawn not available");
        return;
    };
    const t2 = std.Thread.spawn(.{}, Worker.setCpuLoop, .{4}) catch {
        t1.join();
        skip("thread spawn not available");
        return;
    };
    t1.join();
    t2.join();
    expect(jent.jent_entropy_set_notime_cpu(0) == 0, "concurrent jent_notime_set_cpu calls are race-free");
}

pub fn main() u8 {
    h.resetCounters();
    testAtomicNotimeTimerAndInterrupt();
    testConcurrentSetNotimeCpu();
    return h.finish("test-timer");
}

test "test-timer unit checks" {
    try std.testing.expectEqual(@as(u8, 0), main());
}

