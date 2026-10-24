const std = @import("std");

fn trapPanic(_: []const u8, _: ?usize) noreturn {
    @trap();
}

pub const panic = std.debug.FullPanic(trapPanic);
pub const is_linux_kernel = true;

const arch_atomic = @import("arch/atomic.zig");
const arch_cache = @import("arch/cache.zig");
const arch_fips = @import("arch/fips.zig");
const arch_memory = @import("arch/memory.zig");
const arch_ncpu = @import("arch/ncpu.zig");
const arch_random = @import("arch/random.zig");
const arch_sched = @import("arch/sched.zig");
const arch_timer = @import("arch/timer.zig");
const sha3 = @import("sha3.zig");
const gcd = @import("gcd.zig");
const health = @import("health.zig");
const noise = @import("noise.zig");
const timer = @import("timer.zig");
const base = @import("base.zig");
const uuid = @import("uuid.zig");
const status = @import("status.zig");

fn isExportedVariable(comptime name: []const u8) bool {
    const names = .{
        "jent_selftest_run",
        "jent_common_timer_gcd",
        "jent_notime_thread_builtin",
        "jent_cache_cpuid_callback",
        "jent_fi_cache_sysconf_mode",
        "jent_fi_force_fips_enabled",
        "jent_fi_fail_alloc",
        "jent_fi_alloc_count",
        "jent_fi_fail_mmap",
        "jent_fi_fail_mprotect",
        "jent_fi_mprotect_calls",
        "jent_fi_fail_mlock",
        "jent_fi_mlock_errno",
        "jent_fi_sysconf_mode",
        "jent_zeroize_inspect_hook",
        "jent_fi_ncpu",
        "jent_fi_fail_affinity",
        "jent_fi_empty_affinity",
        "jent_fi_fail_cpu_alloc",
        "jent_fi_ncpu_sysconf_mode",
        "jent_fi_fail_getrandom",
        "jent_fi_time_mode",
        "jent_fi_time_value",
    };
    inline for (names) |variable_name| {
        if (std.mem.eql(u8, name, variable_name)) return true;
    }
    return false;
}

fn declarationName(comptime declaration: anytype) []const u8 {
    return switch (@typeInfo(@TypeOf(declaration))) {
        .@"struct" => declaration.name,
        else => declaration,
    };
}

fn exportNamespaceFunctions(comptime namespace: type) void {
    inline for (std.meta.declarations(namespace)) |declaration| {
        const name = declarationName(declaration);
        if (!std.mem.startsWith(u8, name, "jent_") and
            !std.mem.eql(u8, name, "ensure_osr_is_at_least_minimal") and
            !std.mem.eql(u8, name, "keccakf"))
        {
            continue;
        }
        if (isExportedVariable(name)) continue;
        if (std.mem.startsWith(u8, name, "jent_fi_") or
            std.mem.eql(u8, name, "jent_init_test_secure_memory"))
        {
            continue;
        }
        const value = @field(namespace, name);
        if (@typeInfo(@TypeOf(value)) != .@"fn") continue;
        @export(&value, .{
            .name = name,
            .linkage = .strong,
            .visibility = .hidden,
        });
    }
}

fn exportVariable(comptime name: []const u8, comptime variable: anytype) void {
    @export(variable, .{
        .name = name,
        .linkage = .strong,
        .visibility = .hidden,
    });
}

comptime {
    @setEvalBranchQuota(100_000);
    exportNamespaceFunctions(arch_atomic);
    exportNamespaceFunctions(arch_cache);
    exportNamespaceFunctions(arch_fips);
    exportNamespaceFunctions(arch_memory);
    exportNamespaceFunctions(arch_ncpu);
    exportNamespaceFunctions(arch_random);
    exportNamespaceFunctions(arch_sched);
    exportNamespaceFunctions(arch_timer);
    exportNamespaceFunctions(sha3);
    exportNamespaceFunctions(gcd);
    exportNamespaceFunctions(health);
    exportNamespaceFunctions(noise);
    exportNamespaceFunctions(timer);
    exportNamespaceFunctions(base);
    exportNamespaceFunctions(uuid);
    exportNamespaceFunctions(status);

    exportVariable("jent_selftest_run", &base.jent_selftest_run);
    exportVariable("jent_common_timer_gcd", &gcd.jent_common_timer_gcd);
    exportVariable("jent_notime_thread_builtin", &timer.jent_notime_thread_builtin);

    _ = @import("kernel_record.zig");
    _ = @import("kmod_core");
}
