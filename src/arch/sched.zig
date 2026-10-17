// SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0-only

const builtin = @import("builtin");

const windows = struct {
    extern "kernel32" fn SwitchToThread() callconv(.winapi) c_int;
};

const posix = struct {
    extern "c" fn sched_yield() c_int;
};

export fn jent_yield() callconv(.c) void {
    if (comptime builtin.os.tag == .windows) {
        _ = windows.SwitchToThread();
    } else if (comptime builtin.os.tag != .freestanding and builtin.os.tag != .uefi and builtin.link_libc) {
        _ = posix.sched_yield();
    }
}

test "scheduler yield returns" {
    jent_yield();
}
