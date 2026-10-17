// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const root = @import("root");
const is_linux_kernel = @hasDecl(root, "is_linux_kernel") and root.is_linux_kernel;

extern fn jent_kshim_random_get_entropy() callconv(.c) u64;

pub const FI_TIME_REAL: c_int = 0;
pub const FI_TIME_ZERO: c_int = 1;
pub const FI_TIME_CONSTANT: c_int = 2;
pub const FI_TIME_BACKWARDS: c_int = 3;
pub const FI_TIME_FIXED_STEP: c_int = 4;

pub export var jent_fi_time_mode: c_int = FI_TIME_REAL;
pub export var jent_fi_time_value: u64 = 0x8000000000000000;

const MockTimerCallback = *const fn (?*anyopaque, *u64) callconv(.c) void;
var mock_timer: ?MockTimerCallback = null;
var mock_timer_arg: ?*anyopaque = null;

pub export fn jent_set_mock_timer(cb: ?MockTimerCallback, arg: ?*anyopaque) callconv(.c) c_int {
    if (!build_options.mock_timer) return -1;
    mock_timer = cb;
    mock_timer_arg = arg;
    return 0;
}

pub export fn jent_mock_timer_active() callconv(.c) c_int {
    if (!build_options.mock_timer) return 0;
    return if (mock_timer != null) 1 else 0;
}

pub export fn jent_fi_time_set(mode: c_int) callconv(.c) void {
    jent_fi_time_mode = mode;
    jent_fi_time_value = 0x8000000000000000;
}

pub export fn jent_fi_real_get_nstime(out: *u64) callconv(.c) void {
    realGetNstime(out);
}

pub export fn jent_get_nstime(out: *u64) callconv(.c) void {
    if (build_options.mock_timer) {
        if (mock_timer) |cb| {
            cb(mock_timer_arg, out);
            return;
        }
    }

    switch (jent_fi_time_mode) {
        FI_TIME_ZERO => out.* = 0,
        FI_TIME_CONSTANT => out.* = 0x4242424242424242,
        FI_TIME_BACKWARDS => {
            jent_fi_time_value -%= 4096;
            out.* = jent_fi_time_value;
        },
        FI_TIME_FIXED_STEP => {
            jent_fi_time_value +%= 4096;
            out.* = jent_fi_time_value;
        },
        else => realGetNstime(out),
    }
}

fn realGetNstime(out: *u64) void {
    if (is_linux_kernel) {
        out.* = jent_kshim_random_get_entropy();
        return;
    }
    const arch = builtin.cpu.arch;
    const os = builtin.os.tag;

    if (os == .windows and (arch == .arm or arch == .aarch64)) {
        out.* = windowsPerformanceCounter();
    } else switch (arch) {
        .x86, .x86_64 => out.* = readX86Tsc(),
        .aarch64 => out.* = readAarch64Counter(),
        .s390x => out.* = readS390Clock(),
        .powerpc => out.* = readPowerPc32Timebase(),
        .powerpc64, .powerpc64le => out.* = readPowerPc64Timebase(),
        .riscv32 => out.* = readRiscv32Time(),
        .riscv64 => out.* = readRiscv64Time(),
        .sparc64 => out.* = readSparc64Tick(),
        .loongarch64 => out.* = readLoongArch64Time(),
        else => {
            if (os == .freestanding or os == .uefi) {
                out.* = 0;
            } else if (os == .windows) {
                out.* = windowsPerformanceCounter();
            } else if (isDarwin(os)) {
                out.* = mach_absolute_time();
            } else {
                out.* = posixMonotonicTime();
            }
        },
    }
}

fn readX86Tsc() u64 {
    var lo: u32 = undefined;
    var hi: u32 = undefined;
    asm volatile ("rdtsc"
        : [lo] "={eax}" (lo),
          [hi] "={edx}" (hi),
    );
    return (@as(u64, hi) << 32) | lo;
}

fn readAarch64Counter() u64 {
    const configured = build_options.aarch64_nstime_register orelse "cntvct_el0";
    const register = if (configured.len >= 2 and configured[0] == '"' and configured[configured.len - 1] == '"')
        configured[1 .. configured.len - 1]
    else
        configured;
    return asm volatile ("mrs %[value], " ++ register
        : [value] "=r" (-> u64),
    );
}

fn readS390Clock() u64 {
    var clock: [8]u8 = undefined;
    asm volatile ("stck 0(%[address])"
        :
        : [address] "a" (&clock),
        : .{ .memory = true });
    return std.mem.readInt(u64, &clock, .big);
}

fn readPowerPc64Timebase() u64 {
    return asm volatile ("mftb %[value]"
        : [value] "=r" (-> u64),
    );
}

fn readPowerPc32Timebase() u64 {
    while (true) {
        const hi = asm volatile ("mftbu %[value]"
            : [value] "=r" (-> u32),
        );
        const lo = asm volatile ("mftb %[value]"
            : [value] "=r" (-> u32),
        );
        const hi2 = asm volatile ("mftbu %[value]"
            : [value] "=r" (-> u32),
        );
        if (hi == hi2) return (@as(u64, hi) << 32) | lo;
    }
}

fn readRiscv64Time() u64 {
    return asm volatile ("csrrs %[value], time, zero"
        : [value] "=r" (-> u64),
    );
}

fn readRiscv32Time() u64 {
    while (true) {
        const hi = asm volatile ("csrrs %[value], timeh, zero"
            : [value] "=r" (-> u32),
        );
        const lo = asm volatile ("csrrs %[value], time, zero"
            : [value] "=r" (-> u32),
        );
        const hi2 = asm volatile ("csrrs %[value], timeh, zero"
            : [value] "=r" (-> u32),
        );
        if (hi == hi2) return (@as(u64, hi) << 32) | lo;
    }
}

fn readSparc64Tick() u64 {
    return asm volatile ("rd %%tick, %[value]"
        : [value] "=r" (-> u64),
    );
}

fn readLoongArch64Time() u64 {
    var value: u64 = undefined;
    var counter_id: u64 = undefined;
    asm volatile ("rdtime.d %[value], %[counter_id]"
        : [value] "=r" (value),
          [counter_id] "=r" (counter_id),
    );
    return value;
}

fn isDarwin(os: std.Target.Os.Tag) bool {
    return switch (os) {
        .macos, .ios, .tvos, .watchos, .visionos => true,
        else => false,
    };
}

extern fn mach_absolute_time() callconv(.c) u64;

extern "kernel32" fn QueryPerformanceCounter(value: *i64) callconv(.winapi) c_int;

fn windowsPerformanceCounter() u64 {
    var ticks: i64 = 0;
    if (QueryPerformanceCounter(&ticks) == 0) return 0;
    return @bitCast(ticks);
}

const Timespec = extern struct {
    tv_sec: c_long,
    tv_nsec: c_long,
};

extern fn clock_gettime(clock_id: c_int, time: *Timespec) callconv(.c) c_int;

fn posixMonotonicClockId() c_int {
    return switch (builtin.os.tag) {
        .freebsd, .dragonfly => 4,
        .openbsd, .netbsd => 3,
        .illumos => 4,
        else => 1,
    };
}

fn posixMonotonicTime() u64 {
    var time: Timespec = undefined;
    if (clock_gettime(posixMonotonicClockId(), &time) != 0) return 0;
    const seconds: u64 = @bitCast(@as(i64, time.tv_sec));
    return (seconds & 0xffffffff) *% 1_000_000_000 +% @as(u64, @intCast(time.tv_nsec));
}
