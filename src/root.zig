const std = @import("std");
pub const internal = @import("internal.zig");

fn trapPanic(_: []const u8, _: ?usize) noreturn {
    @trap();
}

pub const panic = std.debug.FullPanic(trapPanic);
pub const build_options = internal.build_options;
pub const arch_atomic = @import("arch/atomic.zig");
pub const arch_cache = @import("arch/cache.zig");
pub const arch_fips = @import("arch/fips.zig");
pub const arch_memory = @import("arch/memory.zig");
pub const arch_ncpu = @import("arch/ncpu.zig");
pub const arch_random = @import("arch/random.zig");
pub const arch_sched = @import("arch/sched.zig");
pub const arch_thread = @import("arch/thread.zig");
pub const arch_timer = @import("arch/timer.zig");
pub const sha3 = @import("sha3.zig");
pub const gcd = @import("gcd.zig");
pub const health = @import("health.zig");
pub const noise = @import("noise.zig");
pub const timer = @import("timer.zig");
pub const base = @import("base.zig");
pub const uuid = @import("uuid.zig");
pub const status = @import("status.zig");

fn isPublicApiSymbol(comptime name: []const u8) bool {
    const names = .{
        "jent_entropy_collector_alloc",
        "jent_entropy_collector_bytes_output",
        "jent_entropy_collector_flags",
        "jent_entropy_collector_free",
        "jent_entropy_collector_hashloops",
        "jent_entropy_collector_health_failure",
        "jent_entropy_collector_memsize",
        "jent_entropy_collector_osr",
        "jent_entropy_collector_read_invocations",
        "jent_entropy_collector_reinitializations",
        "jent_entropy_collector_uuid",
        "jent_entropy_init",
        "jent_entropy_init_ex",
        "jent_entropy_set_notime_cpu",
        "jent_entropy_switch_notime_impl",
        "jent_notime_fini",
        "jent_notime_init",
        "jent_read_entropy",
        "jent_read_entropy_safe",
        "jent_secure_memory_supported",
        "jent_selftest",
        "jent_set_fips_failure_callback",
        "jent_status",
        "jent_version",
    };
    inline for (names) |public_name| {
        if (std.mem.eql(u8, name, public_name)) return true;
    }
    return false;
}

fn symbolLinkage(comptime name: []const u8) std.builtin.GlobalLinkage {
    if (build_options.weak_internals and !(isPublicApiSymbol(name) and build_options.export_public_api)) return .weak;
    return .strong;
}

fn symbolVisibility(comptime name: []const u8) std.builtin.SymbolVisibility {
    if (isPublicApiSymbol(name) and build_options.export_public_api) return .default;
    if (build_options.export_internals) return .default;
    return .hidden;
}

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
        "jent_fi_fail_thread_create",
        "jent_fi_fail_pthread_create",
        "jent_fi_fail_pthread_attr",
        "jent_fi_fail_thread_start",
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

const CAbiWrappers = struct {
    const EINVAL: c_int = 22;

    pub fn jent_notime_init(ctx: ?*?*anyopaque) callconv(.c) c_int {
        const ptr = ctx orelse return -EINVAL;
        return timer.jent_notime_init(ptr);
    }

    pub fn jent_notime_enable(ec: ?*internal.rand_data, flags: c_uint) callconv(.c) c_int {
        const collector = ec orelse return internal.ENOTIME;
        return timer.jent_notime_enable(collector, flags);
    }

    pub fn jent_notime_settick(ec: ?*internal.rand_data) callconv(.c) c_int {
        const collector = ec orelse return -EINVAL;
        return timer.jent_notime_settick(collector);
    }

    pub fn jent_notime_unsettick(ec: ?*internal.rand_data) callconv(.c) void {
        const collector = ec orelse return;
        timer.jent_notime_unsettick(collector);
    }

    pub fn jent_get_nstime_internal(ec: ?*internal.rand_data, out: ?*u64) callconv(.c) void {
        const collector = ec orelse return;
        const out_ptr = out orelse return;
        timer.jent_get_nstime_internal(collector, out_ptr);
    }

    pub fn jent_thread_pin_to_cpu(cpu: c_ulong) callconv(.c) c_int {
        if (cpu > std.math.maxInt(c_uint)) return -EINVAL;
        return arch_thread.jent_thread_pin_to_cpu(cpu);
    }

    pub fn jent_notime_thread_create(
        ctx: ?*internal.jent_notime_ctx,
        start_routine: internal.jent_notime_start_routine,
        arg: ?*anyopaque,
    ) callconv(.c) c_int {
        const ptr = ctx orelse return -EINVAL;
        return arch_thread.jent_notime_thread_create(ptr, start_routine, arg);
    }

    pub fn jent_notime_thread_join(ctx: ?*internal.jent_notime_ctx) callconv(.c) void {
        const ptr = ctx orelse return;
        arch_thread.jent_notime_thread_join(ptr);
    }

    pub fn jent_status(ec: ?*const internal.rand_data, buf: ?[*:0]u8, buflen: usize) callconv(.c) c_int {
        const ptr = buf orelse return -1;
        if (buflen == 0) return -1;
        const max_addr_len = std.math.maxInt(usize) - @intFromPtr(ptr);
        const safe_len = @min(buflen, max_addr_len);
        return status.jent_status(ec, ptr, safe_len);
    }

    pub fn jent_apt_reset(ec: ?*internal.rand_data, delta_masked: u64) callconv(.c) void {
        const collector = ec orelse return;
        health.jent_apt_reset(collector, delta_masked);
    }

    pub fn jent_apt_insert(ec: ?*internal.rand_data, delta_masked: u64) callconv(.c) void {
        const collector = ec orelse return;
        health.jent_apt_insert(collector, delta_masked);
    }

    pub fn jent_rct_insert(ec: ?*internal.rand_data, stuck: c_uint) callconv(.c) void {
        const collector = ec orelse return;
        health.jent_rct_insert(collector, stuck);
    }

    pub fn jent_lag_init(ec: ?*internal.rand_data, osr: c_uint) callconv(.c) void {
        const collector = ec orelse return;
        health.jent_lag_init(collector, osr);
    }

    pub fn jent_health_init(ec: ?*internal.rand_data, inittype: internal.jent_health_init_type) callconv(.c) c_int {
        const collector = ec orelse return 0;
        return health.jent_health_init(collector, inittype);
    }

    pub fn jent_Validation_Insert(ec: ?*internal.rand_data, time: u64, stuck: c_int) callconv(.c) void {
        const collector = ec orelse return;
        noise.jent_Validation_Insert(collector, time, stuck);
    }

    pub fn jent_measure_jitter(
        ec: ?*internal.rand_data,
        loop_cnt: u64,
        ret_current_delta: ?*u64,
        health_check: c_int,
    ) callconv(.c) c_uint {
        const collector = ec orelse return 1;
        return noise.jent_measure_jitter(collector, loop_cnt, ret_current_delta, health_check);
    }

    pub fn jent_random_data_OneByte(ec: ?*internal.rand_data) callconv(.c) void {
        const collector = ec orelse return;
        noise.jent_random_data_OneByte(collector);
    }

    pub fn jent_random_data(ec: ?*internal.rand_data) callconv(.c) void {
        const collector = ec orelse return;
        noise.jent_random_data(collector);
    }

    pub fn jent_sha3_update(ctx: ?*internal.jent_sha_ctx, in: ?[*]const u8, inlen: usize) callconv(.c) void {
        const state = ctx orelse return;
        if (inlen == 0) return;
        const ptr = in orelse return;
        const max_addr_len = std.math.maxInt(usize) - @intFromPtr(ptr);
        if (inlen > max_addr_len) return;
        sha3.jent_sha3_update(state, ptr, inlen);
    }

    pub fn jent_drbg_init_ex(ctx: ?*internal.jent_sha_ctx, personalization: ?[*]const u8, personalization_len: usize) callconv(.c) void {
        const state = ctx orelse return;
        if (personalization) |ptr| {
            const max_addr_len = std.math.maxInt(usize) - @intFromPtr(ptr);
            if (personalization_len > max_addr_len) return;
        }
        sha3.jent_drbg_init_ex(state, personalization, personalization_len);
    }
};

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
        if (std.mem.eql(u8, name, "jent_random_data") and !build_options.export_random_data) continue;
        const is_public = isPublicApiSymbol(name) and build_options.export_public_api;
        if (!is_public and !build_options.export_internals) continue;
        const value = if (@hasDecl(CAbiWrappers, name))
            @field(CAbiWrappers, name)
        else
            @field(namespace, name);
        if (@typeInfo(@TypeOf(value)) != .@"fn") continue;
        @export(&value, .{
            .name = name,
            .linkage = symbolLinkage(name),
            .visibility = symbolVisibility(name),
        });
    }
}

fn exportVariable(comptime name: []const u8, comptime variable: anytype) void {
    if (!build_options.export_internals) return;
    @export(variable, .{
        .name = name,
        .linkage = if (build_options.weak_internals) .weak else .strong,
        .visibility = if (build_options.export_internals) .default else .hidden,
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
    exportNamespaceFunctions(arch_thread);
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
    exportVariable("jent_cache_cpuid_callback", &arch_cache.jent_cache_cpuid_callback);
    exportVariable("jent_fi_cache_sysconf_mode", &arch_cache.jent_fi_cache_sysconf_mode);
    exportVariable("sysfs_cpu_base", &arch_cache.sysfs_cpu_base);
    exportVariable("proc_cpuinfo_path", &arch_cache.proc_cpuinfo_path);
    exportVariable("jent_fi_force_fips_enabled", &arch_fips.jent_fi_force_fips_enabled);
    exportVariable("jent_fi_fail_alloc", &arch_memory.jent_fi_fail_alloc);
    exportVariable("jent_fi_alloc_count", &arch_memory.jent_fi_alloc_count);
    exportVariable("jent_fi_fail_mmap", &arch_memory.jent_fi_fail_mmap);
    exportVariable("jent_fi_fail_mprotect", &arch_memory.jent_fi_fail_mprotect);
    exportVariable("jent_fi_mprotect_calls", &arch_memory.jent_fi_mprotect_calls);
    exportVariable("jent_fi_fail_mlock", &arch_memory.jent_fi_fail_mlock);
    exportVariable("jent_fi_mlock_errno", &arch_memory.jent_fi_mlock_errno);
    exportVariable("jent_fi_sysconf_mode", &arch_memory.jent_fi_sysconf_mode);
    exportVariable("jent_zeroize_inspect_hook", &arch_memory.jent_zeroize_inspect_hook);
    exportVariable("jent_fi_ncpu", &arch_ncpu.jent_fi_ncpu);
    exportVariable("jent_fi_fail_affinity", &arch_ncpu.jent_fi_fail_affinity);
    exportVariable("jent_fi_empty_affinity", &arch_ncpu.jent_fi_empty_affinity);
    exportVariable("jent_fi_fail_cpu_alloc", &arch_ncpu.jent_fi_fail_cpu_alloc);
    exportVariable("jent_fi_ncpu_sysconf_mode", &arch_ncpu.jent_fi_ncpu_sysconf_mode);
    exportVariable("jent_fi_fail_getrandom", &arch_random.jent_fi_fail_getrandom);
    exportVariable("jent_fi_fail_thread_create", &arch_thread.jent_fi_fail_thread_create);
    exportVariable("jent_fi_fail_pthread_create", &arch_thread.jent_fi_fail_pthread_create);
    exportVariable("jent_fi_fail_pthread_attr", &arch_thread.jent_fi_fail_pthread_attr);
    exportVariable("jent_fi_fail_thread_start", &arch_thread.jent_fi_fail_thread_start);
    exportVariable("jent_fi_time_mode", &arch_timer.jent_fi_time_mode);
    exportVariable("jent_fi_time_value", &arch_timer.jent_fi_time_value);
}

// ============================================================================
// Re-exported Public & Internal Constants, Flags, Error Codes, and Types
// ============================================================================

pub const JENT_MAJVERSION = internal.JENT_MAJVERSION;
pub const JENT_MINVERSION = internal.JENT_MINVERSION;
pub const JENT_PATCHLEVEL = internal.JENT_PATCHLEVEL;
pub const JENT_VERSION = internal.JENT_VERSION;

pub const JENT_DISABLE_STIR = internal.JENT_DISABLE_STIR;
pub const JENT_DISABLE_UNBIAS = internal.JENT_DISABLE_UNBIAS;
pub const JENT_DISABLE_MEMORY_ACCESS = internal.JENT_DISABLE_MEMORY_ACCESS;
pub const JENT_FORCE_INTERNAL_TIMER = internal.JENT_FORCE_INTERNAL_TIMER;
pub const JENT_DISABLE_INTERNAL_TIMER = internal.JENT_DISABLE_INTERNAL_TIMER;
pub const JENT_FORCE_FIPS = internal.JENT_FORCE_FIPS;
pub const JENT_NTG1 = internal.JENT_NTG1;
pub const JENT_CACHE_ALL = internal.JENT_CACHE_ALL;
pub const JENT_FORCE_SECURE_MEM = internal.JENT_FORCE_SECURE_MEM;
pub const JENT_INT_MEASURE_CLOCK = internal.JENT_INT_MEASURE_CLOCK;

pub const JENT_FLAGS_TO_MEMSIZE_SHIFT = internal.JENT_FLAGS_TO_MEMSIZE_SHIFT;
pub const jent_flags_to_max_memsize = internal.jent_flags_to_max_memsize;
pub const jent_max_memsize_to_flags = internal.jent_max_memsize_to_flags;
pub const JENT_FLAGS_TO_MAX_MEMSIZE = internal.JENT_FLAGS_TO_MAX_MEMSIZE;
pub const JENT_MAX_MEMSIZE_TO_FLAGS = internal.JENT_MAX_MEMSIZE_TO_FLAGS;

pub const JENT_MAX_MEMSIZE_1kB = internal.JENT_MAX_MEMSIZE_1kB;
pub const JENT_MAX_MEMSIZE_2kB = internal.JENT_MAX_MEMSIZE_2kB;
pub const JENT_MAX_MEMSIZE_4kB = internal.JENT_MAX_MEMSIZE_4kB;
pub const JENT_MAX_MEMSIZE_8kB = internal.JENT_MAX_MEMSIZE_8kB;
pub const JENT_MAX_MEMSIZE_16kB = internal.JENT_MAX_MEMSIZE_16kB;
pub const JENT_MAX_MEMSIZE_32kB = internal.JENT_MAX_MEMSIZE_32kB;
pub const JENT_MAX_MEMSIZE_64kB = internal.JENT_MAX_MEMSIZE_64kB;
pub const JENT_MAX_MEMSIZE_128kB = internal.JENT_MAX_MEMSIZE_128kB;
pub const JENT_MAX_MEMSIZE_256kB = internal.JENT_MAX_MEMSIZE_256kB;
pub const JENT_MAX_MEMSIZE_512kB = internal.JENT_MAX_MEMSIZE_512kB;
pub const JENT_MAX_MEMSIZE_1MB = internal.JENT_MAX_MEMSIZE_1MB;
pub const JENT_MAX_MEMSIZE_2MB = internal.JENT_MAX_MEMSIZE_2MB;
pub const JENT_MAX_MEMSIZE_4MB = internal.JENT_MAX_MEMSIZE_4MB;
pub const JENT_MAX_MEMSIZE_8MB = internal.JENT_MAX_MEMSIZE_8MB;
pub const JENT_MAX_MEMSIZE_16MB = internal.JENT_MAX_MEMSIZE_16MB;
pub const JENT_MAX_MEMSIZE_32MB = internal.JENT_MAX_MEMSIZE_32MB;
pub const JENT_MAX_MEMSIZE_64MB = internal.JENT_MAX_MEMSIZE_64MB;
pub const JENT_MAX_MEMSIZE_128MB = internal.JENT_MAX_MEMSIZE_128MB;
pub const JENT_MAX_MEMSIZE_256MB = internal.JENT_MAX_MEMSIZE_256MB;
pub const JENT_MAX_MEMSIZE_512MB = internal.JENT_MAX_MEMSIZE_512MB;
pub const JENT_MAX_MEMSIZE_MAX = internal.JENT_MAX_MEMSIZE_MAX;
pub const JENT_MAX_MEMSIZE_MASK = internal.JENT_MAX_MEMSIZE_MASK;
pub const JENT_MAX_MEMSIZE_OFFSET = internal.JENT_MAX_MEMSIZE_OFFSET;

pub const JENT_FLAGS_TO_HASHLOOP_SHIFT = internal.JENT_FLAGS_TO_HASHLOOP_SHIFT;
pub const jent_hashloop_to_flags = internal.jent_hashloop_to_flags;
pub const jent_flags_to_hashloop = internal.jent_flags_to_hashloop;
pub const JENT_HASHLOOP_TO_FLAGS = internal.JENT_HASHLOOP_TO_FLAGS;
pub const JENT_FLAGS_TO_HASHLOOP = internal.JENT_FLAGS_TO_HASHLOOP;
pub const JENT_MAX_HASHLOOP_MASK = internal.JENT_MAX_HASHLOOP_MASK;
pub const JENT_HASHLOOP_1 = internal.JENT_HASHLOOP_1;
pub const JENT_HASHLOOP_2 = internal.JENT_HASHLOOP_2;
pub const JENT_HASHLOOP_4 = internal.JENT_HASHLOOP_4;
pub const JENT_HASHLOOP_8 = internal.JENT_HASHLOOP_8;
pub const JENT_HASHLOOP_16 = internal.JENT_HASHLOOP_16;
pub const JENT_HASHLOOP_32 = internal.JENT_HASHLOOP_32;
pub const JENT_HASHLOOP_64 = internal.JENT_HASHLOOP_64;
pub const JENT_HASHLOOP_128 = internal.JENT_HASHLOOP_128;
pub const JENT_MAX_HASHLOOP = internal.JENT_MAX_HASHLOOP;

pub const JENT_MIN_OSR = internal.JENT_MIN_OSR;
pub const JENT_MAX_OSR = internal.JENT_MAX_OSR;
pub const JENT_UUID_STRLEN = internal.JENT_UUID_STRLEN;

pub const ENOTIME = internal.ENOTIME;
pub const ECOARSETIME = internal.ECOARSETIME;
pub const ENOMONOTONIC = internal.ENOMONOTONIC;
pub const EMINVARIATION = internal.EMINVARIATION;
pub const EVARVAR = internal.EVARVAR;
pub const EMINVARVAR = internal.EMINVARVAR;
pub const EPROGERR = internal.EPROGERR;
pub const ESTUCK = internal.ESTUCK;
pub const EHEALTH = internal.EHEALTH;
pub const ERCT = internal.ERCT;
pub const EHASH = internal.EHASH;
pub const EMEM = internal.EMEM;
pub const EGCD = internal.EGCD;

pub const JENT_ENOTIME = internal.JENT_ENOTIME;
pub const JENT_ECOARSETIME = internal.JENT_ECOARSETIME;
pub const JENT_ENOMONOTONIC = internal.JENT_ENOMONOTONIC;
pub const JENT_EMINVARIATION = internal.JENT_EMINVARIATION;
pub const JENT_EVARVAR = internal.JENT_EVARVAR;
pub const JENT_EMINVARVAR = internal.JENT_EMINVARVAR;
pub const JENT_EPROGERR = internal.JENT_EPROGERR;
pub const JENT_ESTUCK = internal.JENT_ESTUCK;
pub const JENT_EHEALTH = internal.JENT_EHEALTH;
pub const JENT_ERCT = internal.JENT_ERCT;
pub const JENT_EHASH = internal.JENT_EHASH;
pub const JENT_EMEM = internal.JENT_EMEM;
pub const JENT_EGCD = internal.JENT_EGCD;
pub const JENT_EAPT = internal.JENT_EAPT;
pub const JENT_ECALLBACK = internal.JENT_ECALLBACK;
pub const JENT_ECTX = internal.JENT_ECTX;
pub const JENT_EDIV = internal.JENT_EDIV;
pub const JENT_EENTROPY = internal.JENT_EENTROPY;
pub const JENT_ELAG = internal.JENT_ELAG;
pub const JENT_ERCT_MEM = internal.JENT_ERCT_MEM;
pub const JENT_ESELFTEST = internal.JENT_ESELFTEST;
pub const JENT_ERECORD = internal.JENT_ERECORD;

pub const JENT_ERR_EINVAL = internal.JENT_ERR_EINVAL;
pub const JENT_ERR_RCT = internal.JENT_ERR_RCT;
pub const JENT_ERR_APT = internal.JENT_ERR_APT;
pub const JENT_ERR_NOTIME = internal.JENT_ERR_NOTIME;
pub const JENT_ERR_LAG = internal.JENT_ERR_LAG;
pub const JENT_ERR_RCT_PERMANENT = internal.JENT_ERR_RCT_PERMANENT;
pub const JENT_ERR_APT_PERMANENT = internal.JENT_ERR_APT_PERMANENT;
pub const JENT_ERR_LAG_PERMANENT = internal.JENT_ERR_LAG_PERMANENT;
pub const JENT_ERR_RCT_MEM = internal.JENT_ERR_RCT_MEM;
pub const JENT_ERR_RCT_MEM_PERMANENT = internal.JENT_ERR_RCT_MEM_PERMANENT;
pub const JENT_ERR_SELFTEST = internal.JENT_ERR_SELFTEST;

pub const JENT_RCT_FAILURE = internal.JENT_RCT_FAILURE;
pub const JENT_APT_FAILURE = internal.JENT_APT_FAILURE;
pub const JENT_LAG_FAILURE = internal.JENT_LAG_FAILURE;
pub const JENT_RCT_MEM_FAILURE = internal.JENT_RCT_MEM_FAILURE;
pub const JENT_PERMANENT_FAILURE_SHIFT = internal.JENT_PERMANENT_FAILURE_SHIFT;
pub const jent_permanent_failure = internal.jent_permanent_failure;
pub const JENT_PERMANENT_FAILURE = internal.JENT_PERMANENT_FAILURE;
pub const JENT_RCT_FAILURE_PERMANENT = internal.JENT_RCT_FAILURE_PERMANENT;
pub const JENT_APT_FAILURE_PERMANENT = internal.JENT_APT_FAILURE_PERMANENT;
pub const JENT_LAG_FAILURE_PERMANENT = internal.JENT_LAG_FAILURE_PERMANENT;
pub const JENT_RCT_MEM_FAILURE_PERMANENT = internal.JENT_RCT_MEM_FAILURE_PERMANENT;

pub const jent_udiv64 = internal.jent_udiv64;
pub const jent_umod64 = internal.jent_umod64;

pub const jent_fips_failure_cb = internal.jent_fips_failure_cb;
pub const jent_notime_start_routine = internal.jent_notime_start_routine;
pub const jent_notime_thread = internal.jent_notime_thread;
pub const jent_notime_ctx = internal.jent_notime_ctx;
pub const jent_startup_state = internal.jent_startup_state;
pub const jent_health_init_type = internal.jent_health_init_type;
pub const jent_sha_ctx = internal.jent_sha_ctx;
pub const rand_data = internal.rand_data;

pub const jent_entropy_init = base.jent_entropy_init;
pub const jent_entropy_init_ex = base.jent_entropy_init_ex;
pub const jent_entropy_collector_alloc = base.jent_entropy_collector_alloc;
pub const jent_entropy_collector_free = base.jent_entropy_collector_free;
pub const jent_read_entropy = base.jent_read_entropy;
pub const jent_read_entropy_safe = base.jent_read_entropy_safe;
pub const jent_entropy_switch_notime_impl = base.jent_entropy_switch_notime_impl;
pub const jent_entropy_set_notime_cpu = base.jent_entropy_set_notime_cpu;
pub const jent_set_fips_failure_callback = base.jent_set_fips_failure_callback;
pub const jent_version = base.jent_version;
pub const jent_status = CAbiWrappers.jent_status;
pub const jent_notime_init = CAbiWrappers.jent_notime_init;
pub const jent_notime_fini = timer.jent_notime_fini;
pub const jent_selftest = base.jent_selftest;
pub const jent_entropy_collector_uuid = status.jent_entropy_collector_uuid;
pub const jent_entropy_collector_osr = status.jent_entropy_collector_osr;
pub const jent_entropy_collector_flags = status.jent_entropy_collector_flags;
pub const jent_entropy_collector_memsize = status.jent_entropy_collector_memsize;
pub const jent_entropy_collector_health_failure = status.jent_entropy_collector_health_failure;
pub const jent_entropy_collector_reinitializations = status.jent_entropy_collector_reinitializations;
pub const jent_entropy_collector_read_invocations = status.jent_entropy_collector_read_invocations;
pub const jent_entropy_collector_bytes_output = status.jent_entropy_collector_bytes_output;
pub const jent_entropy_collector_hashloops = status.jent_entropy_collector_hashloops;
pub const jent_secure_memory_supported = arch_memory.jent_secure_memory_supported;

test "JENT_* public flag bit values and C ABI constants" {
    try std.testing.expectEqual(@as(c_uint, 1 << 0), JENT_DISABLE_STIR);
    try std.testing.expectEqual(@as(c_uint, 1 << 1), JENT_DISABLE_UNBIAS);
    try std.testing.expectEqual(@as(c_uint, 1 << 2), JENT_DISABLE_MEMORY_ACCESS);
    try std.testing.expectEqual(@as(c_uint, 1 << 3), JENT_FORCE_INTERNAL_TIMER);
    try std.testing.expectEqual(@as(c_uint, 1 << 4), JENT_DISABLE_INTERNAL_TIMER);
    try std.testing.expectEqual(@as(c_uint, 1 << 5), JENT_FORCE_FIPS);
    try std.testing.expectEqual(@as(c_uint, 1 << 6), JENT_NTG1);
    try std.testing.expectEqual(@as(c_uint, 1 << 7), JENT_CACHE_ALL);
    try std.testing.expectEqual(@as(c_uint, 1 << 8), JENT_FORCE_SECURE_MEM);
    try std.testing.expectEqual(@as(c_uint, 1 << 22), JENT_INT_MEASURE_CLOCK);
    try std.testing.expectEqual(@as(c_uint, 9), JENT_MAX_MEMSIZE_OFFSET);
    try std.testing.expectEqual(@as(u5, 23), JENT_FLAGS_TO_HASHLOOP_SHIFT);
    try std.testing.expectEqual(@as(u5, 27), JENT_FLAGS_TO_MEMSIZE_SHIFT);
}

test "C ABI entrypoints safely handle null and out-of-range inputs in Debug mode" {
    var dummy_buf: [64]u8 = @splat(0);
    var null_ec: ?*rand_data = null;

    // Negative ssize_t cast to size_t (SIZE_MAX / top-bit-set lengths) with null collector or buffer
    const neg_one_usize: usize = @bitCast(@as(isize, -1));
    const min_isize_usize: usize = @bitCast(@as(isize, std.math.minInt(isize)));
    try std.testing.expectEqual(JENT_ERR_EINVAL, jent_read_entropy(null, &dummy_buf, neg_one_usize));
    try std.testing.expectEqual(JENT_ERR_EINVAL, jent_read_entropy(null, &dummy_buf, min_isize_usize));
    try std.testing.expectEqual(JENT_ERR_EINVAL, jent_read_entropy_safe(null, &dummy_buf, neg_one_usize));
    try std.testing.expectEqual(JENT_ERR_EINVAL, jent_read_entropy_safe(&null_ec, &dummy_buf, neg_one_usize));

    // Extreme OSR and flag values (including negative int cast to c_uint)
    const neg_one_uint: c_uint = @bitCast(@as(c_int, -1));
    try std.testing.expectEqual(EPROGERR, jent_entropy_init_ex(neg_one_uint, neg_one_uint));
    try std.testing.expectEqual(EPROGERR, jent_entropy_init_ex(JENT_MAX_OSR + 1, 0));
    try std.testing.expectEqual(@as(?*rand_data, null), jent_entropy_collector_alloc(neg_one_uint, neg_one_uint));
    try std.testing.expectEqual(@as(?*rand_data, null), jent_entropy_collector_alloc(JENT_MAX_OSR + 1, 0));
    try std.testing.expectEqual(
        @as(?*rand_data, null),
        jent_entropy_collector_alloc(0, JENT_FORCE_INTERNAL_TIMER | JENT_DISABLE_INTERNAL_TIMER),
    );

    // Null / out-of-range inputs on timer, thread, status, and uuid entrypoints
    try std.testing.expectEqual(-CAbiWrappers.EINVAL, jent_notime_init(null));
    jent_notime_fini(null);
    try std.testing.expectEqual(-CAbiWrappers.EINVAL, CAbiWrappers.jent_thread_pin_to_cpu(std.math.maxInt(c_ulong)));
    try std.testing.expectEqual(-CAbiWrappers.EINVAL, CAbiWrappers.jent_notime_thread_create(null, null, null));
    CAbiWrappers.jent_notime_thread_join(null);
    try std.testing.expectEqual(@as(c_int, -1), jent_status(null, null, neg_one_usize));
    try std.testing.expectEqual(@as(c_int, -1), jent_entropy_collector_uuid(null, &dummy_buf, neg_one_usize));
}

test {
    std.testing.refAllDecls(@This());
    std.testing.refAllDecls(internal);
    std.testing.refAllDecls(arch_atomic);
    std.testing.refAllDecls(arch_cache);
    std.testing.refAllDecls(arch_fips);
    std.testing.refAllDecls(arch_memory);
    std.testing.refAllDecls(arch_ncpu);
    std.testing.refAllDecls(arch_random);
    std.testing.refAllDecls(arch_sched);
    std.testing.refAllDecls(arch_thread);
    std.testing.refAllDecls(arch_timer);
    std.testing.refAllDecls(sha3);
    std.testing.refAllDecls(gcd);
    std.testing.refAllDecls(health);
    std.testing.refAllDecls(noise);
    std.testing.refAllDecls(timer);
    std.testing.refAllDecls(base);
    std.testing.refAllDecls(uuid);
    std.testing.refAllDecls(status);
}
