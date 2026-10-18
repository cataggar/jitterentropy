// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const std = @import("std");
const builtin = @import("builtin");
const root = @import("root");
const enable_test_hooks = (@hasDecl(root, "build_options") and @hasDecl(root.build_options, "export_internals") and root.build_options.export_internals) or
    (!@hasDecl(root, "build_options") and !(@hasDecl(root, "is_linux_kernel") and root.is_linux_kernel)) or
    builtin.is_test;

const is_linux = builtin.os.tag == .linux;
const is_windows = builtin.os.tag == .windows;
const is_darwin = builtin.os.tag.isDarwin();
const is_x86 = builtin.cpu.arch == .x86 or builtin.cpu.arch == .x86_64;
const is_arm = builtin.cpu.arch == .arm or builtin.cpu.arch == .aarch64;
const is_freestanding = builtin.os.tag == .freestanding or builtin.os.tag == .uefi;

const O_RDONLY = 0;
const O_CLOEXEC = 524_288;
const F_OK = 0;
const EINTR = 4;
const SC_NPROCESSORS_CONF = 83;
const SC_LEVEL1_DCACHE_SIZE = 188;
const SC_LEVEL2_CACHE_SIZE = 191;
const SC_LEVEL3_CACHE_SIZE = 194;

extern fn open(path: [*:0]const u8, flags: c_int, ...) c_int;
extern fn read(fd: c_int, buf: [*]u8, len: usize) isize;
extern fn close(fd: c_int) c_int;
extern fn access(path: [*:0]const u8, mode: c_int) c_int;
extern fn sysconf(name: c_int) c_long;
extern fn __errno_location() *c_int;

extern fn sysctlbyname(
    name: [*:0]const u8,
    oldp: ?*anyopaque,
    oldlenp: *usize,
    newp: ?*anyopaque,
    newlen: usize,
) c_int;

const BOOL = c_int;
const DWORD = u32;
const RelationCache: DWORD = 2;
const CacheUnified: DWORD = 0;
const CacheData: DWORD = 2;
const ERROR_INSUFFICIENT_BUFFER: DWORD = 122;

extern "kernel32" fn GetLogicalProcessorInformationEx(
    relationship_type: DWORD,
    buffer: ?*anyopaque,
    returned_length: *DWORD,
) callconv(.winapi) BOOL;
extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;

pub const CpuidFn = *const fn (
    leaf: c_uint,
    subleaf: c_uint,
    eax: *c_uint,
    ebx: *c_uint,
    ecx: *c_uint,
    edx: *c_uint,
) callconv(.c) c_int;

pub const ReadCcsidrFn = *const fn (level: c_uint) callconv(.c) u64;

pub const ArmMidr = extern struct {
    implementer: c_long = -1,
    architecture: c_long = -1,
    variant: c_long = -1,
    part: c_long = -1,
    revision: c_long = -1,
};

pub const ArmCoreCache = extern struct {
    implementer: u16,
    part: u16,
    l1_kib: u16,
    l2_kib: u16,
    l3_kib: u16,
};

const default_sysfs_cpu_base: [:0]const u8 = "/sys/devices/system/cpu";
const default_proc_cpuinfo: [:0]const u8 = "/proc/cpuinfo";

pub var sysfs_cpu_base: [*:0]const u8 = default_sysfs_cpu_base.ptr;
pub var proc_cpuinfo_path: [*:0]const u8 = default_proc_cpuinfo.ptr;
pub var jent_cache_cpuid_callback: ?CpuidFn = null;

/// Fault injection for the cache backend's sysconf calls.
/// 0 = real, 1 = failure, 2 = zero, 3 = implausibly large.
pub var jent_fi_cache_sysconf_mode: c_int = 0;

var cached_bits: [2]u32 = .{ 0, 0 };
var cached_valid: u32 = 0;

fn saturatingAdd(a: u64, b: u64) u64 {
    return if (b > std.math.maxInt(u64) - a) std.math.maxInt(u64) else a + b;
}

pub fn cacheRoundupFromSizes(l1: u64, l2: u64, l3: u64, all_caches: bool) u64 {
    var sum = l1;
    if (all_caches) {
        sum = saturatingAdd(sum, l2);
        sum = saturatingAdd(sum, l3);
    }
    if (sum == 0) return 0;
    if (sum >= (@as(u64, 1) << 63)) return @as(u64, 1) << 63;

    sum |= sum >> 1;
    sum |= sum >> 2;
    sum |= sum >> 4;
    sum |= sum >> 8;
    sum |= sum >> 16;
    sum |= sum >> 32;
    return sum + 1;
}

pub fn cacheSizeBits(size_arg: u64) u32 {
    var size = size_arg;
    var bits: u32 = 0;
    while (size > 1) : (size >>= 1) bits += 1;
    return bits;
}

pub fn jent_cache_roundup_from_sizes(
    l1: u64,
    l2: u64,
    l3: u64,
    all_caches: c_int,
) callconv(.c) u64 {
    return cacheRoundupFromSizes(l1, l2, l3, all_caches != 0);
}

pub fn jent_cache_size_bits(size: u64) callconv(.c) u32 {
    return cacheSizeBits(size);
}

pub fn jent_cache_reset() callconv(.c) void {
    @atomicStore(u32, &cached_valid, 0, .release);
    @atomicStore(u32, &cached_bits[0], 0, .release);
    @atomicStore(u32, &cached_bits[1], 0, .release);
}

pub fn jent_cache_size_roundup(all_caches: c_int) callconv(.c) u32 {
    if (@atomicLoad(u32, &cached_valid, .acquire) == 0) {
        var l1: u64 = 0;
        var l2: u64 = 0;
        var l3: u64 = 0;
        getCacheSizeUncached(&l1, &l2, &l3);

        const one = @min(cacheRoundupFromSizes(l1, l2, l3, false), @as(u64, 1) << 31);
        const all = @min(cacheRoundupFromSizes(l1, l2, l3, true), @as(u64, 1) << 31);
        @atomicStore(u32, &cached_bits[0], cacheSizeBits(one), .release);
        @atomicStore(u32, &cached_bits[1], cacheSizeBits(all), .release);
        @atomicStore(u32, &cached_valid, 1, .release);
    }

    const bits = @atomicLoad(u32, &cached_bits[@intFromBool(all_caches != 0)], .acquire);
    return if (bits == 0) 0 else @as(u32, 1) << @intCast(bits);
}

pub fn mergeCacheSizes(l1: *u64, l2: *u64, l3: *u64, s1: u64, s2: u64, s3: u64) void {
    l1.* = @max(l1.*, s1);
    l2.* = @max(l2.*, s2);
    l3.* = @max(l3.*, s3);
}

pub fn jent_cache_sizes_merge(
    l1: *u64,
    l2: *u64,
    l3: *u64,
    s1: u64,
    s2: u64,
    s3: u64,
) callconv(.c) void {
    mergeCacheSizes(l1, l2, l3, s1, s2, s3);
}

pub fn cacheTypeIsData(buf: []const u8) bool {
    return std.mem.startsWith(u8, buf, "Data") or std.mem.startsWith(u8, buf, "Unified");
}

pub fn jent_cache_type_is_data(buf: [*:0]const u8) callconv(.c) c_int {
    return @intFromBool(cacheTypeIsData(std.mem.span(buf)));
}

pub fn parseCacheLevel(buf: []const u8) ?c_long {
    const trimmed = std.mem.trim(u8, buf, " \t\r\n");
    const level = std.fmt.parseInt(c_long, trimmed, 10) catch return null;
    return if (level >= 1) level else null;
}

pub fn jent_parse_cache_level(buf: [*:0]const u8, level: *c_long) callconv(.c) c_int {
    level.* = parseCacheLevel(std.mem.span(buf)) orelse return -1;
    return 0;
}

pub fn parseCacheSize(buf: []const u8, read_len: usize, buffer_len: usize) ?u64 {
    if (read_len >= buffer_len) return null;
    const input = buf[0..@min(read_len, buf.len)];
    var shift: u6 = 0;
    var end = input.len;
    if (std.mem.indexOfScalar(u8, input, 'K')) |idx| {
        shift = 10;
        end = idx;
    } else if (std.mem.indexOfScalar(u8, input, 'M')) |idx| {
        shift = 20;
        end = idx;
    }
    const number = std.mem.trim(u8, input[0..end], " \t\r\n");
    const value = std.fmt.parseInt(i64, number, 10) catch return null;
    if (value <= 0) return null;
    const unsigned: u64 = @intCast(value);
    if (unsigned > (@as(u64, std.math.maxInt(u64)) >> shift)) return null;
    return unsigned << shift;
}

pub fn jent_parse_cache_size(
    buf: [*]const u8,
    read_len: usize,
    buffer_len: usize,
    size: *u64,
) callconv(.c) c_int {
    size.* = parseCacheSize(buf[0..read_len], read_len, buffer_len) orelse return -1;
    return 0;
}

pub fn parseSharedCpuMap(buf: []const u8) u32 {
    var count: u32 = 0;
    for (buf) |ch| {
        const nibble: u4 = switch (ch) {
            '0'...'9' => @intCast(ch - '0'),
            'a'...'f' => @intCast(ch - 'a' + 10),
            'A'...'F' => @intCast(ch - 'A' + 10),
            else => continue,
        };
        count +|= @popCount(nibble);
    }
    return count;
}

pub fn jent_parse_shared_cpu_map(buf: [*:0]const u8) callconv(.c) u32 {
    return parseSharedCpuMap(std.mem.span(buf));
}

fn fiSysconf(name: c_int) c_long {
    if (comptime enable_test_hooks) {
        switch (jent_fi_cache_sysconf_mode) {
            1 => return -1,
            2 => return 0,
            3 => return @as(c_long, 1) << 20,
            else => {},
        }
    }
    return if (is_linux) sysconf(name) else -1;
}

pub fn jent_get_cachesize_sysconf(l1: *u64, l2: *u64, l3: *u64) callconv(.c) void {
    l1.* = 0;
    l2.* = 0;
    l3.* = 0;
    if (!is_linux) return;

    const value1 = fiSysconf(SC_LEVEL1_DCACHE_SIZE);
    const value2 = fiSysconf(SC_LEVEL2_CACHE_SIZE);
    const value3 = fiSysconf(SC_LEVEL3_CACHE_SIZE);
    if (value1 > 0) l1.* = @intCast(value1);
    if (value2 > 0) l2.* = @intCast(value2);
    if (value3 > 0) l3.* = @intCast(value3);
}

fn readSysfsAttr(path: [*:0]const u8, buf: []u8) ?usize {
    if (!is_linux or buf.len == 0) return null;
    @memset(buf, 0);
    const fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return null;
    defer _ = close(fd);

    var len: isize = undefined;
    while (true) {
        len = read(fd, buf.ptr, buf.len);
        if (len >= 0) break;
        if (__errno_location().* == EINTR) continue;
        return null;
    }
    if (len <= 0) return null;
    buf[buf.len - 1] = 0;
    return @intCast(len);
}

pub fn jent_read_sysfs_attr(path: [*:0]const u8, buf: [*]u8, buffer_len: usize) callconv(.c) isize {
    const len = readSysfsAttr(path, buf[0..buffer_len]) orelse return -1;
    return @intCast(len);
}

fn pathZ(buf: []u8, comptime fmt: []const u8, args: anytype) ?[*:0]const u8 {
    if (buf.len == 0) return null;
    const out = std.fmt.bufPrint(buf[0 .. buf.len - 1], fmt, args) catch return null;
    buf[out.len] = 0;
    return @ptrCast(buf.ptr);
}

fn configuredCpuCount() c_long {
    if (!is_linux) return 1;
    var count: c_long = -1;
    count = fiSysconf(SC_NPROCESSORS_CONF);
    if (count <= 0) count = 1;
    return @min(count, 1 << 16);
}

pub fn jent_get_cachesize_sysfs_dir(
    cpu_dir: [*:0]const u8,
    l1: *u64,
    l2: *u64,
    l3: *u64,
) callconv(.c) void {
    l1.* = 0;
    l2.* = 0;
    l3.* = 0;
    if (!is_linux) return;

    const base = std.mem.span(cpu_dir);
    const configured = configuredCpuCount();
    var cpu: c_long = 0;
    while (cpu < (1 << 16)) : (cpu += 1) {
        if (cpu >= configured) {
            var dir_buf: [512]u8 = undefined;
            const cpu_path = pathZ(&dir_buf, "{s}/cpu{d}", .{ base, cpu }) orelse break;
            if (access(cpu_path, F_OK) != 0) break;
        }

        var index: u32 = 0;
        while (index < 16) : (index += 1) {
            var file_buf: [640]u8 = undefined;
            var attr_buf: [64]u8 = undefined;
            const type_path = pathZ(&file_buf, "{s}/cpu{d}/cache/index{d}/type", .{ base, cpu, index }) orelse break;
            const type_len = readSysfsAttr(type_path, &attr_buf) orelse {
                if (index == 0) {
                    var dir_buf: [512]u8 = undefined;
                    const cpu_path = pathZ(&dir_buf, "{s}/cpu{d}", .{ base, cpu }) orelse return;
                    if (access(cpu_path, F_OK) != 0) return;
                }
                break;
            };
            if (!cacheTypeIsData(attr_buf[0..type_len])) continue;

            const level_path = pathZ(&file_buf, "{s}/cpu{d}/cache/index{d}/level", .{ base, cpu, index }) orelse continue;
            const level_len = readSysfsAttr(level_path, &attr_buf) orelse continue;
            const level = parseCacheLevel(attr_buf[0..level_len]) orelse continue;
            const slot = switch (level) {
                1 => l1,
                2 => l2,
                3 => l3,
                else => continue,
            };

            const size_path = pathZ(&file_buf, "{s}/cpu{d}/cache/index{d}/size", .{ base, cpu, index }) orelse continue;
            const size_len = readSysfsAttr(size_path, &attr_buf) orelse continue;
            var value = parseCacheSize(&attr_buf, size_len, attr_buf.len) orelse continue;

            const map_path = pathZ(&file_buf, "{s}/cpu{d}/cache/index{d}/shared_cpu_map", .{ base, cpu, index }) orelse continue;
            if (readSysfsAttr(map_path, &attr_buf)) |map_len| {
                const shared = parseSharedCpuMap(attr_buf[0..map_len]);
                if (shared > 1) value = @max(@as(u64, 1), value / shared);
            }
            slot.* = @max(slot.*, value);
        }
    }
}

pub fn jent_get_cachesize_sysfs(l1: *u64, l2: *u64, l3: *u64) callconv(.c) void {
    const base = if (comptime enable_test_hooks) sysfs_cpu_base else default_sysfs_cpu_base.ptr;
    jent_get_cachesize_sysfs_dir(base, l1, l2, l3);
}

pub const arm_core_caches = [_]ArmCoreCache{
    .{ .implementer = 0x41, .part = 0xc05, .l1_kib = 64, .l2_kib = 8192, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xc07, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xc08, .l1_kib = 32, .l2_kib = 1024, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xc09, .l1_kib = 64, .l2_kib = 8192, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xc0e, .l1_kib = 32, .l2_kib = 8192, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xc0f, .l1_kib = 32, .l2_kib = 4096, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xd01, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xd02, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xd03, .l1_kib = 64, .l2_kib = 2048, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xd04, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xd05, .l1_kib = 64, .l2_kib = 256, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd06, .l1_kib = 64, .l2_kib = 256, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd07, .l1_kib = 32, .l2_kib = 2048, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xd08, .l1_kib = 32, .l2_kib = 4096, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xd09, .l1_kib = 64, .l2_kib = 8192, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xd0a, .l1_kib = 64, .l2_kib = 512, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd0b, .l1_kib = 64, .l2_kib = 512, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd0c, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd0d, .l1_kib = 64, .l2_kib = 512, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd0e, .l1_kib = 64, .l2_kib = 512, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd40, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd41, .l1_kib = 64, .l2_kib = 512, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd42, .l1_kib = 64, .l2_kib = 512, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd43, .l1_kib = 64, .l2_kib = 256, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd44, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd46, .l1_kib = 64, .l2_kib = 512, .l3_kib = 16384 },
    .{ .implementer = 0x41, .part = 0xd47, .l1_kib = 64, .l2_kib = 512, .l3_kib = 16384 },
    .{ .implementer = 0x41, .part = 0xd48, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 16384 },
    .{ .implementer = 0x41, .part = 0xd49, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xd4a, .l1_kib = 64, .l2_kib = 256, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd4b, .l1_kib = 64, .l2_kib = 512, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd4c, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 4096 },
    .{ .implementer = 0x41, .part = 0xd4d, .l1_kib = 64, .l2_kib = 512, .l3_kib = 16384 },
    .{ .implementer = 0x41, .part = 0xd4e, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 16384 },
    .{ .implementer = 0x41, .part = 0xd4f, .l1_kib = 64, .l2_kib = 2048, .l3_kib = 0 },
    .{ .implementer = 0x41, .part = 0xd80, .l1_kib = 64, .l2_kib = 512, .l3_kib = 32768 },
    .{ .implementer = 0x41, .part = 0xd81, .l1_kib = 64, .l2_kib = 512, .l3_kib = 32768 },
    .{ .implementer = 0x41, .part = 0xd82, .l1_kib = 64, .l2_kib = 2048, .l3_kib = 32768 },
    .{ .implementer = 0x41, .part = 0xd83, .l1_kib = 64, .l2_kib = 2048, .l3_kib = 32768 },
    .{ .implementer = 0x41, .part = 0xd84, .l1_kib = 64, .l2_kib = 3072, .l3_kib = 32768 },
    .{ .implementer = 0x41, .part = 0xd85, .l1_kib = 64, .l2_kib = 3072, .l3_kib = 32768 },
    .{ .implementer = 0x41, .part = 0xd87, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 32768 },
    .{ .implementer = 0x41, .part = 0xd88, .l1_kib = 64, .l2_kib = 512, .l3_kib = 32768 },
    .{ .implementer = 0x41, .part = 0xd89, .l1_kib = 64, .l2_kib = 1024, .l3_kib = 32768 },
    .{ .implementer = 0x51, .part = 0x801, .l1_kib = 64, .l2_kib = 2048, .l3_kib = 0 },
    .{ .implementer = 0x51, .part = 0x804, .l1_kib = 64, .l2_kib = 512, .l3_kib = 4096 },
    .{ .implementer = 0x51, .part = 0x805, .l1_kib = 64, .l2_kib = 256, .l3_kib = 4096 },
};

fn parseCpuinfoValue(text: []const u8) ?c_long {
    const trimmed = std.mem.trim(u8, text, " \t\r\n");
    return std.fmt.parseInt(c_long, trimmed, 0) catch null;
}

pub fn cpuinfoArmLine(line: []const u8, midr: *ArmMidr, l1: *u64, l2: *u64, l3: *u64) void {
    const colon = std.mem.indexOfScalar(u8, line, ':') orelse return;
    const key = std.mem.trimEnd(u8, line[0..colon], " \t");
    if (std.mem.eql(u8, key, "processor")) {
        midr.* = .{};
        return;
    }
    const value = parseCpuinfoValue(line[colon + 1 ..]) orelse return;
    if (std.mem.eql(u8, key, "CPU implementer")) midr.implementer = value else if (std.mem.eql(u8, key, "CPU architecture")) midr.architecture = value else if (std.mem.eql(u8, key, "CPU variant")) midr.variant = value else if (std.mem.eql(u8, key, "CPU part")) midr.part = value else if (std.mem.eql(u8, key, "CPU revision")) midr.revision = value else return;

    if (!std.mem.eql(u8, key, "CPU part") or midr.implementer < 0) return;
    for (arm_core_caches) |core| {
        if (core.implementer == midr.implementer and core.part == value) {
            mergeCacheSizes(
                l1,
                l2,
                l3,
                @as(u64, core.l1_kib) << 10,
                @as(u64, core.l2_kib) << 10,
                @as(u64, core.l3_kib) << 10,
            );
            return;
        }
    }
}

pub fn jent_cpuinfo_arm_line(
    line: [*:0]const u8,
    midr: *ArmMidr,
    l1: *u64,
    l2: *u64,
    l3: *u64,
) callconv(.c) void {
    cpuinfoArmLine(std.mem.span(line), midr, l1, l2, l3);
}

pub fn jent_get_cachesize_cpuinfo_file(
    path: [*:0]const u8,
    l1: *u64,
    l2: *u64,
    l3: *u64,
) callconv(.c) void {
    l1.* = 0;
    l2.* = 0;
    l3.* = 0;
    if (!is_linux) return;

    var buf: [512]u8 = undefined;
    var line: [64]u8 = undefined;
    var line_len: usize = 0;
    var overlong = false;
    var midr: ArmMidr = .{};
    const fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) return;
    defer _ = close(fd);

    while (true) {
        var read_len: isize = undefined;
        while (true) {
            read_len = read(fd, &buf, buf.len);
            if (read_len >= 0 or __errno_location().* != EINTR) break;
        }
        if (read_len <= 0) break;
        for (buf[0..@intCast(read_len)]) |ch| {
            if (ch != '\n') {
                if (line_len < line.len - 1) {
                    line[line_len] = ch;
                    line_len += 1;
                } else {
                    overlong = true;
                }
                continue;
            }
            if (!overlong) cpuinfoArmLine(line[0..line_len], &midr, l1, l2, l3);
            line_len = 0;
            overlong = false;
        }
    }
    if (line_len != 0 and !overlong) cpuinfoArmLine(line[0..line_len], &midr, l1, l2, l3);
}

pub fn jent_get_cachesize_cpuinfo(l1: *u64, l2: *u64, l3: *u64) callconv(.c) void {
    const path = if (comptime enable_test_hooks) proc_cpuinfo_path else default_proc_cpuinfo.ptr;
    jent_get_cachesize_cpuinfo_file(path, l1, l2, l3);
}

pub fn cacheSizesArm64(
    clidr: u64,
    ccidx: bool,
    read_ccsidr: ReadCcsidrFn,
    l1: *u64,
    l2: *u64,
    l3: *u64,
) void {
    l1.* = 0;
    l2.* = 0;
    l3.* = 0;
    var level: u32 = 1;
    while (level <= 7) : (level += 1) {
        const cache_type: u3 = @truncate(clidr >> @intCast(3 * (level - 1)));
        if (cache_type == 0) break;
        if (cache_type != 2 and cache_type != 3 and cache_type != 4) continue;

        const ccsidr = read_ccsidr(level);
        const line: u6 = @intCast((ccsidr & 7) + 4);
        const associativity = if (ccidx) ((ccsidr >> 3) & 0x1fffff) + 1 else ((ccsidr >> 3) & 0x3ff) + 1;
        const sets = if (ccidx) ((ccsidr >> 32) & 0xffffff) + 1 else ((ccsidr >> 13) & 0x7fff) + 1;
        const size = (@as(u64, 1) << line) * associativity * sets;
        if (size < 4096) continue;

        if (level == 1 and l1.* == 0) l1.* = size else if (level == 2 and l2.* == 0) l2.* = size else if (level == 3 and l3.* == 0) l3.* = size;
    }
}

pub fn jent_cache_sizes_arm64(
    clidr: u64,
    ccidx: c_int,
    read_ccsidr: ReadCcsidrFn,
    l1: *u64,
    l2: *u64,
    l3: *u64,
) callconv(.c) void {
    cacheSizesArm64(clidr, ccidx != 0, read_ccsidr, l1, l2, l3);
}

fn rawCpuid(leaf: u32, subleaf: u32, eax: *u32, ebx: *u32, ecx: *u32, edx: *u32) void {
    if (!is_x86) {
        eax.* = 0;
        ebx.* = 0;
        ecx.* = 0;
        edx.* = 0;
        return;
    }
    var out_eax: u32 = undefined;
    var out_ebx: u32 = undefined;
    var out_ecx: u32 = undefined;
    var out_edx: u32 = undefined;
    asm volatile ("cpuid"
        : [eax] "={eax}" (out_eax),
          [ebx] "={ebx}" (out_ebx),
          [ecx] "={ecx}" (out_ecx),
          [edx] "={edx}" (out_edx),
        : [leaf] "{eax}" (leaf),
          [subleaf] "{ecx}" (subleaf),
    );
    eax.* = out_eax;
    ebx.* = out_ebx;
    ecx.* = out_ecx;
    edx.* = out_edx;
}

pub fn jent_cpuid_count(
    leaf: c_uint,
    subleaf: c_uint,
    eax: *c_uint,
    ebx: *c_uint,
    ecx: *c_uint,
    edx: *c_uint,
) callconv(.c) c_int {
    if (!is_x86) return 0;
    var max_eax: u32 = 0;
    var ignored_b: u32 = 0;
    var ignored_c: u32 = 0;
    var ignored_d: u32 = 0;
    rawCpuid(leaf & 0x80000000, 0, &max_eax, &ignored_b, &ignored_c, &ignored_d);
    if (max_eax == 0 or max_eax < leaf) return 0;
    rawCpuid(leaf, subleaf, eax, ebx, ecx, edx);
    return 1;
}

fn cpuidSource() CpuidFn {
    if (comptime enable_test_hooks) {
        return jent_cache_cpuid_callback orelse jent_cpuid_count;
    }
    return jent_cpuid_count;
}

pub fn cacheSizesCpuidLeaf(cpuid: CpuidFn, leaf: u32, l1: *u64, l2: *u64, l3: *u64) bool {
    l1.* = 0;
    l2.* = 0;
    l3.* = 0;
    var subleaf: u32 = 0;
    while (subleaf < 16) : (subleaf += 1) {
        var eax: u32 = 0;
        var ebx: u32 = 0;
        var ecx: u32 = 0;
        var edx: u32 = 0;
        if (cpuid(leaf, subleaf, &eax, &ebx, &ecx, &edx) == 0) break;
        const cache_type = eax & 0x1f;
        if (cache_type == 0) break;
        if (cache_type != 1 and cache_type != 3) continue;
        if (ecx == 0xffffffff) continue;
        const level = (eax >> 5) & 7;
        const ways: u64 = ((ebx >> 22) & 0x3ff) + 1;
        const partitions: u64 = ((ebx >> 12) & 0x3ff) + 1;
        const line_size: u64 = (ebx & 0xfff) + 1;
        const sets: u64 = @as(u64, ecx) + 1;
        const size = ways * partitions * line_size * sets;
        if (level == 1 and cache_type == 1 and l1.* == 0) l1.* = size else if (level == 2 and l2.* == 0) l2.* = size else if (level == 3 and l3.* == 0) l3.* = size;
    }
    return l1.* != 0 or l2.* != 0 or l3.* != 0;
}

pub fn jent_cache_sizes_cpuid_leaf(
    cpuid: CpuidFn,
    leaf: c_uint,
    l1: *u64,
    l2: *u64,
    l3: *u64,
) callconv(.c) c_int {
    return @intFromBool(cacheSizesCpuidLeaf(cpuid, leaf, l1, l2, l3));
}

fn cacheSizesCpuidLegacy(cpuid: CpuidFn, l1: *u64, l2: *u64, l3: *u64) void {
    var eax: u32 = 0;
    var ebx: u32 = 0;
    var ecx: u32 = 0;
    var edx: u32 = 0;
    if (cpuid(0x80000005, 0, &eax, &ebx, &ecx, &edx) != 0) {
        const kib = ecx >> 24;
        if (kib != 0) l1.* = @as(u64, kib) << 10;
    }
    if (cpuid(0x80000006, 0, &eax, &ebx, &ecx, &edx) != 0) {
        const l2_kib = ecx >> 16;
        const l3_units = edx >> 18;
        if (l2_kib != 0) l2.* = @as(u64, l2_kib) << 10;
        if (l3_units != 0) l3.* = @as(u64, l3_units) << 19;
    }
}

pub fn cacheSizesCpuid(cpuid: CpuidFn, l1: *u64, l2: *u64, l3: *u64) void {
    if (cacheSizesCpuidLeaf(cpuid, 4, l1, l2, l3)) return;
    if (cacheSizesCpuidLeaf(cpuid, 0x8000001d, l1, l2, l3)) return;
    cacheSizesCpuidLegacy(cpuid, l1, l2, l3);
}

pub fn jent_cache_sizes_cpuid(
    cpuid: CpuidFn,
    l1: *u64,
    l2: *u64,
    l3: *u64,
) callconv(.c) void {
    cacheSizesCpuid(cpuid, l1, l2, l3);
}

pub fn jent_get_cachesize_cpuid(l1: *u64, l2: *u64, l3: *u64) callconv(.c) void {
    cacheSizesCpuid(cpuidSource(), l1, l2, l3);
}

fn sysctlCacheSize(names: []const [*:0]const u8) u64 {
    if (!is_darwin) return 0;
    for (names) |name| {
        var value: u64 = 0;
        var len: usize = @sizeOf(u64);
        if (sysctlbyname(name, &value, &len, null, 0) != 0) continue;
        if (len != @sizeOf(u64) and len != @sizeOf(u32)) continue;
        if (value != 0) return value;
    }
    return 0;
}

fn getCacheSizeDarwin(l1: *u64, l2: *u64, l3: *u64) void {
    l1.* = sysctlCacheSize(&.{ "hw.perflevel0.l1dcachesize", "hw.l1dcachesize" });
    l2.* = sysctlCacheSize(&.{ "hw.perflevel0.l2cachesize", "hw.l2cachesize" });
    l3.* = sysctlCacheSize(&.{ "hw.perflevel0.l3cachesize", "hw.l3cachesize" });
}

fn readU32Native(bytes: []const u8) u32 {
    return @as(u32, bytes[0]) |
        (@as(u32, bytes[1]) << 8) |
        (@as(u32, bytes[2]) << 16) |
        (@as(u32, bytes[3]) << 24);
}

fn getCacheSizeWindows(l1: *u64, l2: *u64, l3: *u64) void {
    l1.* = 0;
    l2.* = 0;
    l3.* = 0;
    if (!is_windows) return;

    var len: DWORD = 0;
    if (GetLogicalProcessorInformationEx(RelationCache, null, &len) != 0 or GetLastError() != ERROR_INSUFFICIENT_BUFFER or len == 0) return;
    const buffer = std.heap.c_allocator.alloc(u8, len) catch return;
    defer std.heap.c_allocator.free(buffer);
    if (GetLogicalProcessorInformationEx(RelationCache, @ptrCast(buffer.ptr), &len) == 0) return;

    var pos: usize = 0;
    while (pos + 8 <= len) {
        const relationship = readU32Native(buffer[pos..]);
        const record_size = readU32Native(buffer[pos + 4 ..]);
        if (record_size < 8 or pos + record_size > len) break;
        if (relationship == RelationCache and record_size >= 20) {
            const level = buffer[pos + 8];
            const cache_size = readU32Native(buffer[pos + 12 ..]);
            const cache_type = readU32Native(buffer[pos + 16 ..]);
            if (level == 1 and cache_type == CacheData) l1.* = @max(l1.*, cache_size) else if (level == 2 and (cache_type == CacheData or cache_type == CacheUnified)) l2.* = @max(l2.*, cache_size) else if (level == 3 and (cache_type == CacheData or cache_type == CacheUnified)) l3.* = @max(l3.*, cache_size);
        }
        pos += record_size;
    }
}

fn readArmRegister(comptime register: []const u8) u64 {
    if (builtin.cpu.arch != .aarch64) return 0;
    return asm volatile ("mrs %[ret], " ++ register
        : [ret] "=r" (-> u64),
    );
}

fn writeCsselr(value: u64) void {
    if (builtin.cpu.arch != .aarch64) return;
    asm volatile (
        \\msr csselr_el1, %[value]
        \\isb
        :
        : [value] "r" (value),
        : .{ .memory = true });
}

fn readCcsidrFreestanding(level: c_uint) callconv(.c) u64 {
    const saved = readArmRegister("csselr_el1");
    writeCsselr((@as(u64, level) - 1) << 1);
    const value = readArmRegister("ccsidr_el1");
    writeCsselr(saved);
    return value;
}

fn getCacheSizeFreestandingArm64(l1: *u64, l2: *u64, l3: *u64) void {
    const clidr = readArmRegister("clidr_el1");
    const ccidx = ((readArmRegister("id_aa64mmfr2_el1") >> 20) & 0xf) != 0;
    cacheSizesArm64(clidr, ccidx, readCcsidrFreestanding, l1, l2, l3);
}

fn getCacheSizeLinux(l1: *u64, l2: *u64, l3: *u64) void {
    var s1: u64 = 0;
    var s2: u64 = 0;
    var s3: u64 = 0;
    jent_get_cachesize_sysfs(l1, l2, l3);
    if (l1.* == 0 or l2.* == 0 or l3.* == 0) {
        jent_get_cachesize_sysconf(&s1, &s2, &s3);
        mergeCacheSizes(l1, l2, l3, s1, s2, s3);
    }
    if (is_arm and (l1.* == 0 or l2.* == 0 or l3.* == 0)) {
        jent_get_cachesize_cpuinfo(&s1, &s2, &s3);
        if (l1.* == 0) l1.* = s1;
        if (l2.* == 0) l2.* = s2;
        if (l3.* == 0) l3.* = s3;
    } else if (is_x86 and (l1.* == 0 or l2.* == 0 or l3.* == 0)) {
        jent_get_cachesize_cpuid(&s1, &s2, &s3);
        if (l1.* == 0) l1.* = s1;
        if (l2.* == 0) l2.* = s2;
        if (l3.* == 0) l3.* = s3;
    }
}

pub fn getCacheSizeUncached(l1: *u64, l2: *u64, l3: *u64) void {
    if (is_linux and builtin.link_libc) {
        getCacheSizeLinux(l1, l2, l3);
    } else if (is_windows) {
        getCacheSizeWindows(l1, l2, l3);
    } else if (is_darwin) {
        getCacheSizeDarwin(l1, l2, l3);
    } else if (is_x86) {
        jent_get_cachesize_cpuid(l1, l2, l3);
    } else if (is_freestanding and builtin.cpu.arch == .aarch64) {
        getCacheSizeFreestandingArm64(l1, l2, l3);
    } else {
        l1.* = 0;
        l2.* = 0;
        l3.* = 0;
    }
}

pub fn jent_get_cachesize_uncached(l1: *u64, l2: *u64, l3: *u64) callconv(.c) void {
    getCacheSizeUncached(l1, l2, l3);
}

test "cache helpers" {
    try std.testing.expectEqual(@as(u64, 65_536), cacheRoundupFromSizes(32_768, 0, 0, false));
    try std.testing.expectEqual(@as(u64, 16_777_216), cacheRoundupFromSizes(32_768, 262_144, 8_388_608, true));
    try std.testing.expectEqual(@as(?u64, 8 * 1024 * 1024), parseCacheSize("8M\n", 3, 32));
    try std.testing.expectEqual(@as(u32, 5), parseSharedCpuMap("0000000f,00000001\n"));
}

test "sysfs dir scan stops immediately on missing cpu0 directory" {
    var l1: u64 = 123;
    var l2: u64 = 456;
    var l3: u64 = 789;
    const saved_mode = jent_fi_cache_sysconf_mode;
    defer jent_fi_cache_sysconf_mode = saved_mode;
    jent_fi_cache_sysconf_mode = 3;
    jent_get_cachesize_sysfs_dir("/nonexistent/jent/cpu", &l1, &l2, &l3);
    try std.testing.expectEqual(@as(u64, 0), l1);
    try std.testing.expectEqual(@as(u64, 0), l2);
    try std.testing.expectEqual(@as(u64, 0), l3);
}
