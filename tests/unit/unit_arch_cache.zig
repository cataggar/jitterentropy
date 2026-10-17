// SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0-only

const std = @import("std");
const builtin = @import("builtin");
const cache = @import("cache");
const harness = @import("test_harness");

const is_linux = builtin.os.tag == .linux;

extern fn getenv(name: [*:0]const u8) ?[*:0]const u8;
extern fn getpid() c_int;
extern fn mkdir(path: [*:0]const u8, mode: c_uint) c_int;
extern fn open(path: [*:0]const u8, flags: c_int, ...) c_int;
extern fn write(fd: c_int, buf: [*]const u8, len: usize) isize;
extern fn close(fd: c_int) c_int;
extern fn unlink(path: [*:0]const u8) c_int;
extern fn rmdir(path: [*:0]const u8) c_int;

const O_WRONLY = 1;
const O_CREAT = 64;
const O_TRUNC = 512;

fn expectEqual(expected: anytype, actual: @TypeOf(expected), what: []const u8) !void {
    try harness.expect(expected == actual, @src(), "{s}: expected {any}, got {any}", .{ what, expected, actual });
}

fn expectTrue(value: bool, what: []const u8) !void {
    try harness.expect(value, @src(), "{s}", .{what});
}

fn testRoundup() !void {
    try expectEqual(@as(u64, 0), cache.cacheRoundupFromSizes(0, 0, 0, false), "no cache");
    try expectEqual(@as(u64, 65_536), cache.cacheRoundupFromSizes(32_768, 262_144, 8_388_608, false), "L1 rounds up");
    try expectEqual(@as(u64, 16_777_216), cache.cacheRoundupFromSizes(32_768, 262_144, 8_388_608, true), "all levels sum");
    try expectEqual(@as(u64, 524_288), cache.cacheRoundupFromSizes(0, 262_144, 0, true), "missing L1");
    try expectEqual(@as(u64, 1) << 33, cache.cacheRoundupFromSizes(@as(u64, 1) << 32, 0, 0, false), "4 GiB");
    try expectEqual(@as(u64, 1) << 63, cache.cacheRoundupFromSizes(std.math.maxInt(u64), std.math.maxInt(u64), std.math.maxInt(u64), true), "saturated sum");
    try expectEqual(@as(u32, 63), cache.cacheSizeBits(@as(u64, 1) << 63), "cached exponent");
    try expectEqual(@as(u64, 131_072), cache.cacheRoundupFromSizes(65_536, 0, 0, false), "exact power rounds onward");
}

fn testParsers() !void {
    const size_cases = [_]struct { text: []const u8, expected: ?u64 }{
        .{ .text = "32K\n", .expected = 32_768 },
        .{ .text = "8M\n", .expected = 8_388_608 },
        .{ .text = "512\n", .expected = 512 },
        .{ .text = "0K\n", .expected = null },
        .{ .text = "K\n", .expected = null },
        .{ .text = "\n", .expected = null },
        .{ .text = "abc\n", .expected = null },
        .{ .text = "-4K\n", .expected = null },
        .{ .text = "99999999999999999999M\n", .expected = null },
        .{ .text = "4194304K\n", .expected = @as(u64, 1) << 32 },
        .{ .text = "99999999999999M\n", .expected = null },
    };
    for (size_cases) |case| {
        try expectEqual(case.expected, cache.parseCacheSize(case.text, case.text.len, 32), case.text);
    }
    try expectEqual(@as(?u64, null), cache.parseCacheSize("1234567", 8, 8), "truncated size");

    const level_cases = [_]struct { text: []const u8, expected: ?c_long }{
        .{ .text = "1\n", .expected = 1 },
        .{ .text = "2\n", .expected = 2 },
        .{ .text = "3\n", .expected = 3 },
        .{ .text = "0\n", .expected = null },
        .{ .text = "-1\n", .expected = null },
        .{ .text = "\n", .expected = null },
        .{ .text = "x\n", .expected = null },
    };
    for (level_cases) |case| {
        try expectEqual(case.expected, cache.parseCacheLevel(case.text), case.text);
    }

    try expectTrue(cache.cacheTypeIsData("Data\n"), "data cache");
    try expectTrue(cache.cacheTypeIsData("Unified\n"), "unified cache");
    try expectTrue(!cache.cacheTypeIsData("Instruction\n"), "instruction cache excluded");
    try expectEqual(@as(u32, 5), cache.parseSharedCpuMap("0000000f,00000001\n"), "shared CPU map popcount");
    try expectEqual(@as(u32, 64), cache.parseSharedCpuMap("ffffffff,ffffffff\n"), "wide shared CPU map");
}

const CLIDR_L1_L2_L3 = @as(u64, 3) | (@as(u64, 4) << 3) | (@as(u64, 4) << 6);

fn ccsidr(line: u64, ways: u64, sets: u64) u64 {
    return line | ((ways - 1) << 3) | ((sets - 1) << 13);
}

fn ccsidrCcidx(line: u64, ways: u64, sets: u64) u64 {
    return line | ((ways - 1) << 3) | ((sets - 1) << 32);
}

fn ccsidrReal(level: c_uint) callconv(.c) u64 {
    return switch (level) {
        1 => ccsidr(2, 4, 128),
        2 => ccsidr(2, 16, 1024),
        else => ccsidr(2, 16, 8192),
    };
}

fn ccsidrRealCcidx(level: c_uint) callconv(.c) u64 {
    return switch (level) {
        1 => ccsidrCcidx(2, 4, 128),
        2 => ccsidrCcidx(2, 16, 1024),
        else => ccsidrCcidx(2, 16, 8192),
    };
}

fn ccsidrKvm(_: c_uint) callconv(.c) u64 {
    return ccsidr(2, 1, 1);
}

fn ccsidrL1Only(level: c_uint) callconv(.c) u64 {
    return if (level == 1) ccsidr(2, 4, 256) else ccsidr(2, 1, 1);
}

fn testArm64Decoder() !void {
    var l1: u64 = 0;
    var l2: u64 = 0;
    var l3: u64 = 0;
    cache.cacheSizesArm64(CLIDR_L1_L2_L3, false, ccsidrReal, &l1, &l2, &l3);
    try expectEqual(@as(u64, 32_768), l1, "ARM64 L1");
    try expectEqual(@as(u64, 1_048_576), l2, "ARM64 L2");
    try expectEqual(@as(u64, 8_388_608), l3, "ARM64 L3");

    cache.cacheSizesArm64(CLIDR_L1_L2_L3, true, ccsidrRealCcidx, &l1, &l2, &l3);
    try expectEqual(@as(u64, 32_768), l1, "CCIDX L1");
    try expectEqual(@as(u64, 8_388_608), l3, "CCIDX L3");

    cache.cacheSizesArm64(CLIDR_L1_L2_L3, false, ccsidrKvm, &l1, &l2, &l3);
    try expectTrue(l1 == 0 and l2 == 0 and l3 == 0, "KVM placeholders ignored");
    cache.cacheSizesArm64(CLIDR_L1_L2_L3, false, ccsidrL1Only, &l1, &l2, &l3);
    try expectTrue(l1 == 65_536 and l2 == 0 and l3 == 0, "real L1 beside placeholders");
    cache.cacheSizesArm64(0, false, ccsidrReal, &l1, &l2, &l3);
    try expectTrue(l1 == 0 and l2 == 0 and l3 == 0, "empty CLIDR");
}

var fake_leaf: u32 = 4;
var fake_legacy = false;

fn cpuidFake(leaf: c_uint, subleaf: c_uint, eax: *c_uint, ebx: *c_uint, ecx: *c_uint, edx: *c_uint) callconv(.c) c_int {
    eax.* = 0;
    ebx.* = 0;
    ecx.* = 0;
    edx.* = 0;
    if (fake_legacy) {
        if (leaf == 4 or leaf == 0x8000001d) return 1;
        if (leaf == 0x80000005) {
            ecx.* = 64 << 24;
            return 1;
        }
        if (leaf == 0x80000006) {
            ecx.* = 1024 << 16;
            edx.* = 16 << 18;
            return 1;
        }
        return 0;
    }
    if (leaf != fake_leaf) return 1;
    switch (subleaf) {
        0 => {
            eax.* = 1 | (1 << 5);
            ebx.* = (7 << 22) | 63;
            ecx.* = 63;
        },
        1 => {
            eax.* = 2 | (1 << 5);
            ebx.* = (7 << 22) | 63;
            ecx.* = 1023;
        },
        2 => {
            eax.* = 3 | (2 << 5);
            ebx.* = (15 << 22) | 63;
            ecx.* = 1023;
        },
        3 => {
            eax.* = 3 | (3 << 5);
            ebx.* = (15 << 22) | 63;
            ecx.* = 8191;
        },
        else => {},
    }
    return 1;
}

fn cpuidNone(_: c_uint, _: c_uint, eax: *c_uint, ebx: *c_uint, ecx: *c_uint, edx: *c_uint) callconv(.c) c_int {
    eax.* = 0;
    ebx.* = 0;
    ecx.* = 0;
    edx.* = 0;
    return 0;
}

fn testCpuid() !void {
    var l1: u64 = 0;
    var l2: u64 = 0;
    var l3: u64 = 0;
    fake_legacy = false;
    fake_leaf = 4;
    cache.cacheSizesCpuid(cpuidFake, &l1, &l2, &l3);
    try expectTrue(l1 == 32_768 and l2 == 1_048_576 and l3 == 8_388_608, "Intel deterministic leaf");
    fake_leaf = 0x8000001d;
    cache.cacheSizesCpuid(cpuidFake, &l1, &l2, &l3);
    try expectTrue(l1 == 32_768 and l2 == 1_048_576 and l3 == 8_388_608, "AMD deterministic leaf");

    cache.jent_cache_cpuid_callback = cpuidFake;
    cache.jent_get_cachesize_cpuid(&l1, &l2, &l3);
    cache.jent_cache_cpuid_callback = null;
    try expectTrue(l1 == 32_768 and l2 == 1_048_576 and l3 == 8_388_608, "injectable CPUID callback");

    fake_legacy = true;
    cache.cacheSizesCpuid(cpuidFake, &l1, &l2, &l3);
    try expectTrue(l1 == 65_536 and l2 == 1_048_576 and l3 == 8_388_608, "AMD legacy leaves");
    cache.cacheSizesCpuid(cpuidNone, &l1, &l2, &l3);
    try expectTrue(l1 == 0 and l2 == 0 and l3 == 0, "missing CPUID leaves");
}

fn testArmTable() !void {
    for (cache.arm_core_caches) |core| {
        var midr: cache.ArmMidr = .{};
        var l1: u64 = 0;
        var l2: u64 = 0;
        var l3: u64 = 0;
        var line_buf: [64]u8 = undefined;

        const implementer = try std.fmt.bufPrint(&line_buf, "CPU implementer\t: 0x{x}", .{core.implementer});
        cache.cpuinfoArmLine(implementer, &midr, &l1, &l2, &l3);
        cache.cpuinfoArmLine("CPU architecture\t: 8", &midr, &l1, &l2, &l3);
        cache.cpuinfoArmLine("CPU variant\t: 0x1", &midr, &l1, &l2, &l3);
        const part = try std.fmt.bufPrint(&line_buf, "CPU part\t: 0x{x}", .{core.part});
        cache.cpuinfoArmLine(part, &midr, &l1, &l2, &l3);
        cache.cpuinfoArmLine("CPU revision\t: 3", &midr, &l1, &l2, &l3);

        try expectEqual(@as(u64, core.l1_kib) << 10, l1, "ARM table L1");
        try expectEqual(@as(u64, core.l2_kib) << 10, l2, "ARM table L2");
        try expectEqual(@as(u64, core.l3_kib) << 10, l3, "ARM table L3");
        try expectTrue(midr.architecture == 8 and midr.variant == 1 and midr.revision == 3, "complete MIDR parsed");
    }

    var midr: cache.ArmMidr = .{};
    var l1: u64 = 0;
    var l2: u64 = 0;
    var l3: u64 = 0;
    cache.cpuinfoArmLine("CPU implementer\t: 0x41", &midr, &l1, &l2, &l3);
    cache.cpuinfoArmLine("processor\t: 1", &midr, &l1, &l2, &l3);
    cache.cpuinfoArmLine("CPU part\t: 0xd07", &midr, &l1, &l2, &l3);
    try expectEqual(@as(u64, 0), l1, "implementer resets between CPUs");
}

fn makePathZ(buf: []u8, comptime fmt: []const u8, args: anytype) ![*:0]const u8 {
    const text = try std.fmt.bufPrint(buf[0 .. buf.len - 1], fmt, args);
    buf[text.len] = 0;
    return @ptrCast(buf.ptr);
}

fn makeDir(path: [*:0]const u8) void {
    _ = mkdir(path, 0o700);
}

fn writeFile(path: [*:0]const u8, text: []const u8) !void {
    const fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, @as(c_uint, 0o600));
    if (fd < 0) return error.CreateFailed;
    defer _ = close(fd);
    if (write(fd, text.ptr, text.len) != text.len) return error.WriteFailed;
}

fn createIndex(root: []const u8, cpu: u32, index: u32, cache_type: ?[]const u8, level: ?[]const u8, size: ?[]const u8, shared: ?[]const u8) !void {
    var path_buf: [512]u8 = undefined;
    const index_path = try makePathZ(&path_buf, "{s}/cpu{d}/cache/index{d}", .{ root, cpu, index });
    makeDir(index_path);
    if (cache_type) |value| {
        const path = try makePathZ(&path_buf, "{s}/cpu{d}/cache/index{d}/type", .{ root, cpu, index });
        try writeFile(path, value);
    }
    if (level) |value| {
        const path = try makePathZ(&path_buf, "{s}/cpu{d}/cache/index{d}/level", .{ root, cpu, index });
        try writeFile(path, value);
    }
    if (size) |value| {
        const path = try makePathZ(&path_buf, "{s}/cpu{d}/cache/index{d}/size", .{ root, cpu, index });
        try writeFile(path, value);
    }
    if (shared) |value| {
        const path = try makePathZ(&path_buf, "{s}/cpu{d}/cache/index{d}/shared_cpu_map", .{ root, cpu, index });
        try writeFile(path, value);
    }
}

fn removeIndex(root: []const u8, cpu: u32, index: u32) void {
    var path_buf: [512]u8 = undefined;
    const names = [_][]const u8{ "type", "level", "size", "shared_cpu_map" };
    for (names) |name| {
        const path = makePathZ(&path_buf, "{s}/cpu{d}/cache/index{d}/{s}", .{ root, cpu, index, name }) catch continue;
        _ = unlink(path);
    }
    const index_path = makePathZ(&path_buf, "{s}/cpu{d}/cache/index{d}", .{ root, cpu, index }) catch return;
    _ = rmdir(index_path);
}

fn removeTree(root: []const u8, cpu_count: u32, index_count: u32) void {
    var path_buf: [512]u8 = undefined;
    var cpu: u32 = 0;
    while (cpu < cpu_count) : (cpu += 1) {
        var index: u32 = 0;
        while (index < index_count) : (index += 1) removeIndex(root, cpu, index);
        const cache_path = makePathZ(&path_buf, "{s}/cpu{d}/cache", .{ root, cpu }) catch continue;
        _ = rmdir(cache_path);
        const cpu_path = makePathZ(&path_buf, "{s}/cpu{d}", .{ root, cpu }) catch continue;
        _ = rmdir(cpu_path);
    }
    const root_path = makePathZ(&path_buf, "{s}", .{root}) catch return;
    _ = rmdir(root_path);
}

fn testSysfs() !void {
    if (!is_linux) {
        try harness.skip(@src(), "not the Linux sysfs backend", .{});
        return;
    }
    const temp = getenv("TMPDIR") orelse {
        try harness.skip(@src(), "TMPDIR is unavailable", .{});
        return;
    };
    var root_buf: [512]u8 = undefined;
    const root_z = try makePathZ(&root_buf, "{s}/jent-cache-{d}", .{ std.mem.span(temp), getpid() });
    const root = std.mem.span(root_z);
    makeDir(root_z);
    defer removeTree(root, 2, 20);

    var path_buf: [512]u8 = undefined;
    var cpu: u32 = 0;
    while (cpu < 2) : (cpu += 1) {
        makeDir(try makePathZ(&path_buf, "{s}/cpu{d}", .{ root, cpu }));
        makeDir(try makePathZ(&path_buf, "{s}/cpu{d}/cache", .{ root, cpu }));
    }

    try createIndex(root, 0, 0, "Instruction\n", "1\n", "32K\n", null);
    try createIndex(root, 0, 1, "Data\n", "1\n", "16K\n", "00000001\n");
    try createIndex(root, 0, 2, "Unified\n", "2\n", "1M\n", "00000003\n");
    try createIndex(root, 0, 3, "Unified\n", "3\n", "not-a-size\n", null);
    try createIndex(root, 0, 4, "Data\n", "1\n", "48K\n", null);
    try createIndex(root, 0, 5, "Data\n", "no-level\n", "8K\n", null);
    try createIndex(root, 0, 6, "Data\n", null, "8K\n", null);
    try createIndex(root, 0, 7, "Data\n", "1\n", null, null);
    try createIndex(root, 0, 8, "Unified\n", "3\n", "8M\n", "0000000f\n");
    try createIndex(root, 0, 9, "Unified\n", "4\n", "128M\n", null);
    try createIndex(root, 0, 10, "", "1\n", "8K\n", null);

    try createIndex(root, 1, 0, "Data\n", "1\n", "64K\n", null);
    try createIndex(root, 1, 1, "Unified\n", "2\n", "2M\n", null);
    try createIndex(root, 1, 2, "Unified\n", "3\n", "16M\n", null);

    var l1: u64 = 0;
    var l2: u64 = 0;
    var l3: u64 = 0;
    cache.jent_get_cachesize_sysfs_dir(root_z, &l1, &l2, &l3);
    try expectEqual(@as(u64, 65_536), l1, "largest L1 across CPUs");
    try expectEqual(@as(u64, 2_097_152), l2, "largest L2 across CPUs");
    try expectEqual(@as(u64, 16_777_216), l3, "largest L3 across CPUs");

    var absent_buf: [512]u8 = undefined;
    const absent = try makePathZ(&absent_buf, "{s}/absent", .{root});
    l1 = std.math.maxInt(u64);
    l2 = std.math.maxInt(u64);
    l3 = std.math.maxInt(u64);
    cache.jent_get_cachesize_sysfs_dir(absent, &l1, &l2, &l3);
    try expectTrue(l1 == 0 and l2 == 0 and l3 == 0, "absent sysfs tree");

    const saved = cache.sysfs_cpu_base;
    cache.sysfs_cpu_base = root_z;
    cache.jent_get_cachesize_sysfs(&l1, &l2, &l3);
    cache.sysfs_cpu_base = saved;
    try expectEqual(@as(u64, 65_536), l1, "configurable sysfs base");

    var limit_root_buf: [512]u8 = undefined;
    const limit_root_z = try makePathZ(&limit_root_buf, "{s}/jent-cache-limit-{d}", .{ std.mem.span(temp), getpid() });
    const limit_root = std.mem.span(limit_root_z);
    makeDir(limit_root_z);
    defer removeTree(limit_root, 1, 20);
    makeDir(try makePathZ(&path_buf, "{s}/cpu0", .{limit_root}));
    makeDir(try makePathZ(&path_buf, "{s}/cpu0/cache", .{limit_root}));
    var index: u32 = 0;
    while (index < 20) : (index += 1) {
        try createIndex(limit_root, 0, index, "Data\n", "1\n", if (index < 16) "4K\n" else "64K\n", null);
    }
    cache.jent_get_cachesize_sysfs_dir(limit_root_z, &l1, &l2, &l3);
    try expectEqual(@as(u64, 4096), l1, "walk stops after sixteen cache indices");

    var shared_root_buf: [512]u8 = undefined;
    const shared_root_z = try makePathZ(&shared_root_buf, "{s}/jent-cache-shared-{d}", .{ std.mem.span(temp), getpid() });
    const shared_root = std.mem.span(shared_root_z);
    makeDir(shared_root_z);
    defer removeTree(shared_root, 1, 1);
    makeDir(try makePathZ(&path_buf, "{s}/cpu0", .{shared_root}));
    makeDir(try makePathZ(&path_buf, "{s}/cpu0/cache", .{shared_root}));
    try createIndex(shared_root, 0, 0, "Data\n", "1\n", "64K\n", "0000000f\n");
    cache.jent_get_cachesize_sysfs_dir(shared_root_z, &l1, &l2, &l3);
    try expectEqual(@as(u64, 16_384), l1, "shared cache is scaled by CPU-map population");
}

fn testCpuinfoFile() !void {
    if (!is_linux) return;
    const temp = getenv("TMPDIR") orelse return;
    var path_buf: [512]u8 = undefined;
    const path = try makePathZ(&path_buf, "{s}/jent-cpuinfo-{d}", .{ std.mem.span(temp), getpid() });
    defer _ = unlink(path);
    try writeFile(path, "processor\t: 0\n" ++
        "Features\t: fp asimd evtstrm aes pmull sha1 sha2 crc32 atomics fphp asimdhp cpuid asimdrdm lrcpc dcpop asimddp\n" ++
        "CPU implementer\t: 0x41\n" ++
        "CPU architecture\t: 8\n" ++
        "CPU variant\t: 0x1\n" ++
        "CPU part\t: 0xd07\n" ++
        "CPU revision\t: 3");
    var l1: u64 = 0;
    var l2: u64 = 0;
    var l3: u64 = 0;
    cache.jent_get_cachesize_cpuinfo_file(path, &l1, &l2, &l3);
    try expectTrue(l1 == 32_768 and l2 == 2_097_152 and l3 == 0, "cpuinfo reader handles long and unterminated lines");
}

fn testFaultHooks() !void {
    if (!is_linux) return;
    var l1: u64 = 1;
    var l2: u64 = 1;
    var l3: u64 = 1;
    cache.jent_fi_cache_sysconf_mode = 1;
    cache.jent_get_cachesize_sysconf(&l1, &l2, &l3);
    try expectTrue(l1 == 0 and l2 == 0 and l3 == 0, "failed sysconf is unknown");
    cache.jent_fi_cache_sysconf_mode = 2;
    cache.jent_get_cachesize_sysconf(&l1, &l2, &l3);
    try expectTrue(l1 == 0 and l2 == 0 and l3 == 0, "zero sysconf is unknown");
    cache.jent_fi_cache_sysconf_mode = 3;
    cache.jent_get_cachesize_sysconf(&l1, &l2, &l3);
    try expectTrue(l1 == 1_048_576 and l2 == 1_048_576 and l3 == 1_048_576, "huge fault mode");
    cache.jent_fi_cache_sysconf_mode = 0;
}

fn testLive() !void {
    var l1: u64 = std.math.maxInt(u64);
    var l2: u64 = std.math.maxInt(u64);
    var l3: u64 = std.math.maxInt(u64);
    cache.getCacheSizeUncached(&l1, &l2, &l3);
    const plausible = struct {
        fn check(size: u64) bool {
            return size == 0 or (size >= 4096 and size <= (@as(u64, 1) << 32));
        }
    }.check;
    try expectTrue(plausible(l1) and plausible(l2) and plausible(l3), "live cache sizes are plausible");
    try expectTrue(l2 == 0 or l1 == 0 or l2 >= l1, "live L2 is no smaller than L1");
    cache.jent_cache_reset();
    const one = cache.jent_cache_size_roundup(0);
    const all = cache.jent_cache_size_roundup(1);
    try expectTrue(one == 0 or std.math.isPowerOfTwo(one), "memoized L1 result is a power of two");
    try expectTrue(all == 0 or std.math.isPowerOfTwo(all), "memoized all-cache result is a power of two");
    try expectTrue(one == 0 or all == 0 or all >= one, "all caches are no smaller");
}

pub fn main() !void {
    harness.resetCounters();
    try testRoundup();
    try testParsers();
    try testArm64Decoder();
    try testCpuid();
    try testArmTable();
    try testSysfs();
    try testCpuinfoFile();
    try testFaultHooks();
    try testLive();
    std.process.exit(harness.finish("unit-arch-cache"));
}
