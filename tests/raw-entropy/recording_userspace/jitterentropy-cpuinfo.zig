// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause
//
// Test tool listing the identification and cache layout of every CPU.
//
// Copyright (C) 2026, Stephan Mueller <smueller@chronox.de>
// Copyright (C) 2026, Markus Theil <theil.markus@gmail.com>
//
// On hybrid CPUs (Intel P/E cores, ARM big.LITTLE) the timing of both noise
// sources depends on the micro-architecture and the caches of the core the
// Jitter RNG runs on, so a recording only characterizes that core type. This
// tool names the CPUs and their caches, and the measurement is then pinned to
// one of them with "jitterentropy-hashtime --cpu <CPU>".
//
// Coverage per system:
//
//   Linux    Complete, from sysfs plus CPUID/MIDR read on each core.
//   Windows  Complete, from GetLogicalProcessorInformationEx() and the registry.
//   macOS    Complete, but per performance level (hw.perflevel<N>.*) rather
//            than per CPU - which is how Apple Silicon exposes P and E cores.
//   Others   Only the CPU this tool runs on, its caches only on x86: nothing
//            there enumerates the caches of the other CPUs.
//
// Usage: jitterentropy-cpuinfo [--summary] [--json]

const std = @import("std");
const builtin = @import("builtin");

const Backend = enum {
    windows,
    linux,
    macos,
    generic,
    none,
};

const current_backend: Backend = switch (builtin.os.tag) {
    .windows => .windows,
    .linux => .linux,
    .macos, .ios, .tvos, .watchos, .visionos => .macos,
    .freebsd,
    .netbsd,
    .openbsd,
    .dragonfly,
    .illumos,
    .haiku,
    .hurd,
    .serenity,
    => .generic,
    else => .none,
};

const is_x86 = builtin.cpu.arch == .x86_64 or builtin.cpu.arch == .x86;
const is_arm64 = builtin.cpu.arch == .aarch64 or builtin.cpu.arch == .aarch64_be;

pub const JENT_MAX_CPUS: usize = 1024;
pub const JENT_CPU_LIST_MAX: u64 = 1 << 16;
pub const JENT_IDENT_LEN: usize = 160;
pub const JENT_TYPE_LEN: usize = 16;

const Errno = struct {
    const NOENT: i32 = if (builtin.os.tag == .windows) 2 else @backingInt(std.posix.E.NOENT);
    const IO: i32 = if (builtin.os.tag == .windows) 5 else @backingInt(std.posix.E.IO);
    const AGAIN: i32 = if (builtin.os.tag == .windows) 11 else @backingInt(std.posix.E.AGAIN);
    const NOMEM: i32 = if (builtin.os.tag == .windows) 12 else @backingInt(std.posix.E.NOMEM);
    const FAULT: i32 = if (builtin.os.tag == .windows) 14 else @backingInt(std.posix.E.FAULT);
    const INVAL: i32 = if (builtin.os.tag == .windows) 22 else @backingInt(std.posix.E.INVAL);
    const NOSYS: i32 = if (builtin.os.tag == .windows) 40 else @backingInt(std.posix.E.NOSYS);
    const NODATA: i32 = if (builtin.os.tag == .linux) @backingInt(std.posix.E.NODATA) else 61;
};

const FILE = opaque {};
extern "c" fn fopen(path: [*:0]const u8, mode: [*:0]const u8) ?*FILE;
extern "c" fn fgets(buf: [*]u8, n: c_int, stream: *FILE) ?[*]u8;
extern "c" fn fclose(stream: *FILE) c_int;
extern "c" fn fwrite(ptr: [*]const u8, size: usize, nmemb: usize, stream: *FILE) usize;
extern "c" fn strerror(errnum: c_int) [*:0]const u8;
extern "c" fn write(fd: c_int, buf: [*]const u8, count: usize) isize;

fn getErrno() i32 {
    const e: i32 = @intCast(std.c._errno().*);
    return if (e > 0) e else Errno.IO;
}

fn strerrorSlice(errnum: i32) []const u8 {
    return std.mem.sliceTo(strerror(@intCast(errnum)), 0);
}

fn bufPrintZ(buf: []u8, comptime fmt: []const u8, args: anytype) ![:0]u8 {
    if (buf.len == 0) return error.NoSpaceLeft;
    const s = try std.fmt.bufPrint(buf[0 .. buf.len - 1], fmt, args);
    buf[s.len] = 0;
    return buf[0..s.len :0];
}

pub const CacheInfo = struct {
    size: u64 = 0,
    shared: u64 = 0,

    pub fn eql(a: CacheInfo, b: CacheInfo) bool {
        return a.size == b.size and a.shared == b.shared;
    }
};

pub const CpuInfo = struct {
    cpu: u64 = 0,
    cpu_valid: bool = false,
    pkg: i64 = -1,
    core: i64 = -1,
    max_khz: u64 = 0,
    base_khz: u64 = 0,
    tsc_khz: u64 = 0,
    tsc_invariant: i32 = -1,
    tsc_nonstop: i32 = -1,
    tsc_known_freq: i32 = -1,
    l1d: CacheInfo = .{},
    l1i: CacheInfo = .{},
    l2: CacheInfo = .{},
    l3: CacheInfo = .{},
    ident_buf: [JENT_IDENT_LEN]u8 = @splat(0),
    ident_len: usize = 0,
    type_buf: [JENT_TYPE_LEN]u8 = @splat(0),
    type_len: usize = 0,

    pub fn ident(self: *const CpuInfo) []const u8 {
        return self.ident_buf[0..self.ident_len];
    }

    pub fn coreType(self: *const CpuInfo) []const u8 {
        return self.type_buf[0..self.type_len];
    }

    pub fn setType(self: *CpuInfo, s: []const u8) void {
        const cap = JENT_TYPE_LEN - 1;
        const n = @min(s.len, cap);
        @memcpy(self.type_buf[0..n], s[0..n]);
        self.type_buf[n] = 0;
        self.type_len = n;
    }

    pub fn setTypeFmt(self: *CpuInfo, comptime fmt: []const u8, args: anytype) void {
        var tmp: [64]u8 = undefined;
        const formatted = std.fmt.bufPrint(&tmp, fmt, args) catch tmp[0..];
        self.setType(formatted);
    }

    pub fn setIdentRaw(self: *CpuInfo, s: []const u8) void {
        const cap = JENT_IDENT_LEN - 1;
        const n = @min(s.len, cap);
        @memcpy(self.ident_buf[0..n], s[0..n]);
        self.ident_buf[n] = 0;
        self.ident_len = n;
    }

    /// Set the model of @self to "<vendor> <model>", padding removed: CPUID pads
    /// the AMD brand string with blanks that /proc/cpuinfo and the Windows registry
    /// do not, and left in, the two spellings list one machine as two models.
    pub fn setIdent(self: *CpuInfo, vendor_opt: ?[]const u8, model_opt: ?[]const u8) void {
        const v_raw = vendor_opt orelse "";
        const m_raw = model_opt orelse "";
        const v = std.mem.trimStart(u8, v_raw, " \t");
        const m = std.mem.trimStart(u8, m_raw, " \t");
        const sep: []const u8 = if (v.len > 0 and m.len > 0) " " else "";

        var combined: [JENT_IDENT_LEN * 2]u8 = undefined;
        const full = std.fmt.bufPrint(&combined, "{s}{s}{s}", .{ v, sep, m }) catch combined[0..];
        const cap = JENT_IDENT_LEN - 1;
        const truncated = full[0..@min(full.len, cap)];
        const trimmed = std.mem.trimEnd(u8, truncated, " \t");
        self.setIdentRaw(trimmed);
    }
};

pub const CpuList = struct {
    cpu: [JENT_MAX_CPUS]CpuInfo = undefined,
    entries: usize = 0,
    ncpu: i64 = 0,
    pinning: bool = false,
    backend: []const u8 = "none",
    note: ?[]const u8 = null,
    select: ?[]const u8 = null,

    pub fn cpuById(self: *CpuList, cpu_id: i64) ?*CpuInfo {
        if (cpu_id < 0) return null;
        const target_id: u64 = @intCast(cpu_id);
        for (self.cpu[0..self.entries]) |*info| {
            if (info.cpu_valid and info.cpu == target_id)
                return info;
        }
        return null;
    }
};

// ============================================================================
// x86 identification, frequency, and cache helpers (CPUID)
// ============================================================================

fn cpuidRaw(leaf: u32, subleaf: u32) [4]u32 {
    if (!comptime is_x86) return .{ 0, 0, 0, 0 };
    var eax: u32 = undefined;
    var ebx: u32 = undefined;
    var ecx: u32 = undefined;
    var edx: u32 = undefined;
    asm volatile ("cpuid"
        : [eax] "={eax}" (eax),
          [ebx] "={ebx}" (ebx),
          [ecx] "={ecx}" (ecx),
          [edx] "={edx}" (edx),
        : [leaf] "{eax}" (leaf),
          [subleaf] "{ecx}" (subleaf),
    );
    return .{ eax, ebx, ecx, edx };
}

fn cpuidHypervisor(leaf: u32, subleaf: u32) ?[4]u32 {
    const r1 = cpuid(1, 0) orelse return null;
    if ((r1[2] & (@as(u32, 1) << 31)) == 0)
        return null;

    const r_hv = cpuidRaw(0x40000000, 0);
    if (leaf > r_hv[0])
        return null;

    return cpuidRaw(leaf, subleaf);
}

fn cpuid(leaf: u32, subleaf: u32) ?[4]u32 {
    if (!comptime is_x86) return null;

    if ((leaf & 0xFF000000) == 0x40000000)
        return cpuidHypervisor(leaf, subleaf);

    const max_regs = cpuidRaw(leaf & 0x80000000, 0);
    if (leaf > max_regs[0])
        return null;

    return cpuidRaw(leaf, subleaf);
}

pub fn parseCpuidVendor(leaf0: [4]u32) [12]u8 {
    var vendor: [12]u8 = undefined;
    std.mem.writeInt(u32, vendor[0..4], leaf0[1], .little);
    std.mem.writeInt(u32, vendor[4..8], leaf0[3], .little);
    std.mem.writeInt(u32, vendor[8..12], leaf0[2], .little);
    return vendor;
}

pub fn parseCpuidBrand(regs: [12]u32, out: *[48]u8) []const u8 {
    for (regs, 0..) |reg, idx| {
        std.mem.writeInt(u32, out[idx * 4 ..][0..4], reg, .little);
    }
    const nul_trimmed = std.mem.sliceTo(out, 0);
    return std.mem.trimStart(u8, nul_trimmed, " ");
}

pub fn applyCpuidHybridType(info: *CpuInfo, leaf1a_eax: u32) void {
    if (leaf1a_eax == 0) return;
    const core_type_id = leaf1a_eax >> 24;
    switch (core_type_id) {
        0x20 => info.setType("E-core"),
        0x40 => info.setType("P-core"),
        else => info.setTypeFmt("0x{x:0>2}", .{core_type_id}),
    }
}

fn identX86(info: *CpuInfo) void {
    const r0 = cpuid(0, 0) orelse return;
    const vendor = parseCpuidVendor(r0);

    var brand_regs: [12]u32 = undefined;
    var brand_buf: [48]u8 = undefined;
    var model: []const u8 = "";
    var have_brand = true;
    for (0..3) |i| {
        if (cpuid(0x80000002 + @as(u32, @intCast(i)), 0)) |r| {
            brand_regs[i * 4 + 0] = r[0];
            brand_regs[i * 4 + 1] = r[1];
            brand_regs[i * 4 + 2] = r[2];
            brand_regs[i * 4 + 3] = r[3];
        } else {
            have_brand = false;
            break;
        }
    }
    if (have_brand) {
        model = parseCpuidBrand(brand_regs, &brand_buf);
    }

    info.setIdent(std.mem.sliceTo(&vendor, 0), model);

    if (cpuid(0x1A, 0)) |r1a| {
        applyCpuidHybridType(info, r1a[0]);
    }
}

/// The nominal frequency some brand strings end in ("... CPU @ 2.40GHz"), in
/// kHz, or 0 when there is none. Only a trailing "@ <number><unit>Hz" is taken,
/// so that a model number containing a digit cannot pass for a frequency.
pub fn parseBrandKhz(brand: []const u8) u64 {
    const at_idx = std.mem.lastIndexOfScalar(u8, brand, '@') orelse return 0;
    var rest = brand[at_idx + 1 ..];
    while (rest.len > 0 and rest[0] == ' ') {
        rest = rest[1..];
    }

    var value: u64 = 0;
    var frac_digits: usize = 0;
    var seen_digit = false;
    var in_frac = false;

    while (rest.len > 0) {
        const c = rest[0];
        if (c >= '0' and c <= '9') {
            value = value * 10 + (c - '0');
            if (in_frac) frac_digits += 1;
            seen_digit = true;
            rest = rest[1..];
        } else if (c == '.' and !in_frac) {
            in_frac = true;
            rest = rest[1..];
        } else {
            break;
        }
    }

    if (!seen_digit or rest.len < 3)
        return 0;

    var scale: u64 = switch (rest[0]) {
        'G' => 1_000_000,
        'M' => 1_000,
        'k', 'K' => 1,
        else => return 0,
    };

    if (!std.mem.startsWith(u8, rest[1..], "Hz"))
        return 0;

    while (frac_digits > 0) : (frac_digits -= 1) {
        if (scale < 10) return 0;
        scale /= 10;
    }

    return value * scale;
}

pub fn applyCpuidFreq(
    info: *CpuInfo,
    leaf16: ?[4]u32,
    leaf15: ?[4]u32,
    leaf40000010: ?[4]u32,
    leaf80000007: ?[4]u32,
) void {
    if (leaf16) |r| {
        if (info.base_khz == 0 and (r[0] & 0xFFFF) != 0)
            info.base_khz = @as(u64, r[0] & 0xFFFF) * 1000;
        if (info.max_khz == 0 and (r[1] & 0xFFFF) != 0)
            info.max_khz = @as(u64, r[1] & 0xFFFF) * 1000;
    }

    if (info.base_khz == 0)
        info.base_khz = parseBrandKhz(info.ident());

    if (leaf15) |r| {
        if (r[0] != 0 and r[1] != 0 and r[2] != 0) {
            info.tsc_khz = (@as(u64, r[2]) * @as(u64, r[1])) / @as(u64, r[0]) / 1000;
        }
    }

    if (info.tsc_khz == 0) {
        if (leaf40000010) |r| {
            if (r[0] != 0)
                info.tsc_khz = r[0];
        }
    }

    info.tsc_known_freq = if (info.tsc_khz != 0) 1 else 0;

    if (leaf80000007) |r| {
        info.tsc_invariant = if ((r[3] & (@as(u32, 1) << 8)) != 0) 1 else 0;
        info.tsc_nonstop = info.tsc_invariant;
    }
}

fn freqX86(info: *CpuInfo) void {
    applyCpuidFreq(
        info,
        cpuid(0x16, 0),
        cpuid(0x15, 0),
        cpuid(0x40000010, 0),
        cpuid(0x80000007, 0),
    );
}

pub const CpuidCacheSubleafOutcome = enum {
    end_of_leaves,
    ignored_level,
    recorded,
};

pub fn applyCpuidCacheSubleaf(info: *CpuInfo, regs: [4]u32) CpuidCacheSubleafOutcome {
    const eax = regs[0];
    const ebx = regs[1];
    const ecx = regs[2];

    const cache_type = eax & 0x1F;
    if (cache_type == 0)
        return .end_of_leaves;

    const level = (eax >> 5) & 0x7;
    const ways: u64 = ((ebx >> 22) & 0x3FF) + 1;
    const partitions: u64 = ((ebx >> 12) & 0x3FF) + 1;
    const line: u64 = (ebx & 0xFFF) + 1;
    const sets: u64 = @as(u64, ecx) + 1;

    const cache: *CacheInfo = if (level == 1 and cache_type == 2)
        &info.l1i
    else if (level == 1 and (cache_type == 1 or cache_type == 3))
        &info.l1d
    else if (level == 2 and cache_type != 2)
        &info.l2
    else if (level == 3 and cache_type != 2)
        &info.l3
    else
        return .ignored_level;

    cache.size = ways * partitions * line * sets;
    return .recorded;
}

fn cachesX86Leaf(info: *CpuInfo, leaf: u32) bool {
    var found = false;
    var sub: u32 = 0;
    while (sub < 16) : (sub += 1) {
        const r = cpuid(leaf, sub) orelse break;
        switch (applyCpuidCacheSubleaf(info, r)) {
            .end_of_leaves => break,
            .ignored_level => continue,
            .recorded => found = true,
        }
    }
    return found;
}

fn cachesX86(info: *CpuInfo) void {
    if (cachesX86Leaf(info, 0x00000004))
        return;
    _ = cachesX86Leaf(info, 0x8000001D);
}

// ============================================================================
// AArch64 timer & MIDR identification
// ============================================================================

fn timerArm64(info: *CpuInfo) void {
    if (!comptime is_arm64) return;
    const freq = asm volatile ("mrs %[ret], cntfrq_el0"
        : [ret] "=r" (-> u64),
    );
    if (freq == 0) return;
    info.tsc_khz = freq / 1000;
    info.tsc_invariant = 1;
    info.tsc_nonstop = 1;
    info.tsc_known_freq = 1;
}

const ArmEntry = struct {
    id: u64,
    name: []const u8,
};

const arm_implementers = [_]ArmEntry{
    .{ .id = 0x41, .name = "ARM" },
    .{ .id = 0x42, .name = "Broadcom" },
    .{ .id = 0x43, .name = "Cavium" },
    .{ .id = 0x46, .name = "Fujitsu" },
    .{ .id = 0x48, .name = "HiSilicon" },
    .{ .id = 0x4e, .name = "NVIDIA" },
    .{ .id = 0x50, .name = "APM" },
    .{ .id = 0x51, .name = "Qualcomm" },
    .{ .id = 0x53, .name = "Samsung" },
    .{ .id = 0x56, .name = "Marvell" },
    .{ .id = 0x61, .name = "Apple" },
    .{ .id = 0x69, .name = "Intel" },
    .{ .id = 0x6d, .name = "Microsoft" },
    .{ .id = 0x70, .name = "Phytium" },
    .{ .id = 0xc0, .name = "Ampere" },
};

const arm_parts = [_]ArmEntry{
    .{ .id = 0xd03, .name = "Cortex-A53" },
    .{ .id = 0xd04, .name = "Cortex-A35" },
    .{ .id = 0xd05, .name = "Cortex-A55" },
    .{ .id = 0xd06, .name = "Cortex-A65" },
    .{ .id = 0xd07, .name = "Cortex-A57" },
    .{ .id = 0xd08, .name = "Cortex-A72" },
    .{ .id = 0xd09, .name = "Cortex-A73" },
    .{ .id = 0xd0a, .name = "Cortex-A75" },
    .{ .id = 0xd0b, .name = "Cortex-A76" },
    .{ .id = 0xd0c, .name = "Neoverse-N1" },
    .{ .id = 0xd0d, .name = "Cortex-A77" },
    .{ .id = 0xd40, .name = "Neoverse-V1" },
    .{ .id = 0xd41, .name = "Cortex-A78" },
    .{ .id = 0xd44, .name = "Cortex-X1" },
    .{ .id = 0xd46, .name = "Cortex-A510" },
    .{ .id = 0xd47, .name = "Cortex-A710" },
    .{ .id = 0xd48, .name = "Cortex-X2" },
    .{ .id = 0xd49, .name = "Neoverse-N2" },
    .{ .id = 0xd4a, .name = "Neoverse-E1" },
    .{ .id = 0xd4d, .name = "Cortex-A715" },
    .{ .id = 0xd4e, .name = "Cortex-X3" },
    .{ .id = 0xd4f, .name = "Neoverse-V2" },
    .{ .id = 0xd80, .name = "Cortex-A520" },
    .{ .id = 0xd81, .name = "Cortex-A720" },
    .{ .id = 0xd82, .name = "Cortex-X4" },
    .{ .id = 0xd84, .name = "Neoverse-V3" },
    .{ .id = 0xd85, .name = "Cortex-X925" },
    .{ .id = 0xd87, .name = "Cortex-A725" },
    .{ .id = 0xd8e, .name = "Neoverse-N3" },
};

pub fn armLookup(id: u64, implementer: bool) ?[]const u8 {
    const table = if (implementer) &arm_implementers else &arm_parts;
    for (table) |entry| {
        if (entry.id == id) return entry.name;
    }
    return null;
}

pub fn formatMidrIdent(info: *CpuInfo, midr: u64) void {
    const impl = (midr >> 24) & 0xff;
    const part = (midr >> 4) & 0xfff;
    const variant = (midr >> 20) & 0xf;
    const revision = midr & 0xf;

    const impl_name = armLookup(impl, true);
    var part_buf: [16]u8 = undefined;
    const part_name = if (impl == 0x41)
        armLookup(part, false) orelse (std.fmt.bufPrint(&part_buf, "part 0x{x:0>3}", .{part}) catch "part")
    else
        std.fmt.bufPrint(&part_buf, "part 0x{x:0>3}", .{part}) catch "part";

    var out_buf: [JENT_IDENT_LEN]u8 = undefined;
    const formatted = if (impl_name) |iname|
        std.fmt.bufPrint(&out_buf, "{s} {s} r{d}p{d}", .{ iname, part_name, variant, revision }) catch ""
    else
        std.fmt.bufPrint(&out_buf, "implementer 0x{x:0>2} {s} r{d}p{d}", .{ impl, part_name, variant, revision }) catch "";

    info.setIdentRaw(formatted);
}

// ============================================================================
// Common parsing helpers (Linux sysfs & /proc/cpuinfo)
// ============================================================================

fn parseDecimalU64(s: []const u8, pos: *usize) ?u64 {
    const start = pos.*;
    var val: u64 = 0;
    while (pos.* < s.len) {
        const c = s[pos.*];
        if (c < '0' or c > '9') break;
        val = std.math.mul(u64, val, 10) catch return null;
        val = std.math.add(u64, val, c - '0') catch return null;
        pos.* += 1;
    }
    if (pos.* == start) return null;
    return val;
}

/// Parse a kernel CPU list like "0-3,8" (/sys/.../online, shared_cpu_list) into
/// @cpus. Returns the length of the list or a negative errno - a count above
/// cpus.len reports the truncation to the caller.
pub fn parseCpuList(str: []const u8, cpus: ?[]u64) i64 {
    const line = if (std.mem.indexOfScalar(u8, str, '\n')) |nl| str[0..nl] else str;
    var pos: usize = 0;
    var count: i64 = 0;

    while (pos < line.len) {
        const start = parseDecimalU64(line, &pos) orelse return -Errno.INVAL;
        var end = start;

        if (pos < line.len and line[pos] == '-') {
            pos += 1;
            end = parseDecimalU64(line, &pos) orelse return -Errno.INVAL;
            if (end < start) return -Errno.INVAL;
        }

        if (end >= JENT_CPU_LIST_MAX)
            return -Errno.INVAL;

        var i = start;
        while (i <= end) : (i += 1) {
            if (cpus) |out| {
                const idx: usize = @intCast(count);
                if (idx < out.len)
                    out[idx] = i;
            }
            count += 1;
        }

        if (pos < line.len and line[pos] == ',') {
            pos += 1;
        } else {
            break;
        }
    }

    return if (count > 0) count else -Errno.INVAL;
}

/// Convert a sysfs cache size like "48K" or "32M" into bytes.
pub fn parseCacheSize(str: []const u8) u64 {
    var pos: usize = 0;
    const val = parseDecimalU64(str, &pos) orelse return 0;
    if (pos >= str.len) return val;
    return switch (str[pos]) {
        'K' => val * 1024,
        'M' => val * 1024 * 1024,
        'G' => val * 1024 * 1024 * 1024,
        else => val,
    };
}

/// Is @name one of the space separated words of @flags?
pub fn hasFlag(flags: []const u8, name: []const u8) bool {
    if (name.len == 0) return false;
    var offset: usize = 0;
    while (std.mem.indexOfPos(u8, flags, offset, name)) |idx| {
        const before_ok = (idx == 0) or (flags[idx - 1] == ' ');
        const after_idx = idx + name.len;
        const after_ok = (after_idx == flags.len) or (flags[after_idx] == ' ');
        if (before_ok and after_ok)
            return true;
        offset = after_idx;
    }
    return false;
}

// ============================================================================
// Linux backend
// ============================================================================

const JENT_SYSFS_CPU = "/sys/devices/system/cpu";
const JENT_MAX_CACHE_INDEX: u32 = 10;

extern "c" fn sched_getaffinity(pid: c_int, cpusetsize: usize, mask: *anyopaque) c_int;
extern "c" fn sched_setaffinity(pid: c_int, cpusetsize: usize, mask: *const anyopaque) c_int;
extern "c" fn sched_getcpu() c_int;

fn readFileStr(path: [*:0]const u8, buf: []u8) ResultSlice {
    const f = fopen(path, "r") orelse return .{ .err = -getErrno() };
    defer _ = fclose(f);

    if (fgets(buf.ptr, @intCast(buf.len), f) == null)
        return .{ .err = -Errno.IO };

    const raw = std.mem.sliceTo(buf, 0);
    const trimmed = std.mem.trimEnd(u8, raw, "\n ");
    if (trimmed.len == 0)
        return .{ .err = -Errno.NODATA };

    return .{ .ok = trimmed };
}

const ResultSlice = union(enum) {
    ok: []const u8,
    err: i32,
};

fn readCpuStr(cpu: u64, attr: []const u8, buf: []u8) ResultSlice {
    var path_buf: [256]u8 = undefined;
    const path = bufPrintZ(&path_buf, JENT_SYSFS_CPU ++ "/cpu{d}/{s}", .{ cpu, attr }) catch {
        return .{ .err = -Errno.INVAL };
    };
    return readFileStr(path.ptr, buf);
}

fn readCpuVal(cpu: u64, attr: []const u8) ?u64 {
    var buf: [64]u8 = undefined;
    const s = switch (readCpuStr(cpu, attr, &buf)) {
        .ok => |v| std.mem.trim(u8, v, " \t"),
        .err => return null,
    };
    return std.fmt.parseInt(u64, s, 0) catch null;
}

fn readCpuSigned(cpu: u64, attr: []const u8) ?i64 {
    var buf: [64]u8 = undefined;
    const s = switch (readCpuStr(cpu, attr, &buf)) {
        .ok => |v| std.mem.trim(u8, v, " \t"),
        .err => return null,
    };
    return std.fmt.parseInt(i64, s, 10) catch null;
}

fn cachesLinux(info: *CpuInfo) void {
    var idx: u32 = 0;
    while (idx < JENT_MAX_CACHE_INDEX) : (idx += 1) {
        var attr_buf: [64]u8 = undefined;
        var type_buf: [32]u8 = undefined;
        var size_buf: [32]u8 = undefined;
        var list_buf: [512]u8 = undefined;

        const level_attr = std.fmt.bufPrint(&attr_buf, "cache/index{d}/level", .{idx}) catch break;
        const level = readCpuVal(info.cpu, level_attr) orelse break;

        const type_attr = std.fmt.bufPrint(&attr_buf, "cache/index{d}/type", .{idx}) catch continue;
        const cache_type = switch (readCpuStr(info.cpu, type_attr, &type_buf)) {
            .ok => |s| s,
            .err => continue,
        };

        const is_inst = std.mem.startsWith(u8, cache_type, "Instruction");
        const cache: *CacheInfo = if (level == 1 and is_inst)
            &info.l1i
        else if (level == 1)
            &info.l1d
        else if (level == 2 and !is_inst)
            &info.l2
        else if (level == 3 and !is_inst)
            &info.l3
        else
            continue;

        const size_attr = std.fmt.bufPrint(&attr_buf, "cache/index{d}/size", .{idx}) catch continue;
        const size_str = switch (readCpuStr(info.cpu, size_attr, &size_buf)) {
            .ok => |s| s,
            .err => continue,
        };
        cache.size = parseCacheSize(size_str);

        const shared_attr = std.fmt.bufPrint(&attr_buf, "cache/index{d}/shared_cpu_list", .{idx}) catch continue;
        const shared_str = switch (readCpuStr(info.cpu, shared_attr, &list_buf)) {
            .ok => |s| s,
            .err => continue,
        };
        const shared = parseCpuList(shared_str, null);
        if (shared > 0)
            cache.shared = @intCast(shared);
    }
}

fn identLocalLinux(info: *CpuInfo) void {
    if (comptime is_arm64) {
        timerArm64(info);
    } else if (comptime is_x86) {
        identX86(info);
        freqX86(info);
    }
}

fn identSysfsLinux(info: *CpuInfo) void {
    if (comptime is_arm64) {
        const midr = readCpuVal(info.cpu, "regs/identification/midr_el1") orelse return;
        formatMidrIdent(info, midr);
        if (readCpuVal(info.cpu, "cpu_capacity")) |capacity| {
            info.setTypeFmt("cap {d}", .{capacity});
        }
    } else if (comptime is_x86) {
        if (info.coreType().len == 0) {
            if (readCpuVal(info.cpu, "cpufreq/amd_pstate_highest_perf")) |perf| {
                info.setTypeFmt("perf {d}", .{perf});
            }
        }
    }
}

pub fn parseProcCpuinfoText(list: *CpuList, content: []const u8) void {
    const keys = [_][]const u8{ "model name", "uarch", "cpu model", "cpu", "machine" };
    var vendor_buf: [64]u8 = @splat(0);
    var vendor_len: usize = 0;
    var cur: i64 = -1;

    var line_it = std.mem.splitScalar(u8, content, '\n');
    while (line_it.next()) |raw_line| {
        const colon = std.mem.indexOfScalar(u8, raw_line, ':') orelse continue;
        const key = std.mem.trimEnd(u8, raw_line[0..colon], " \t");
        const val_raw = std.mem.trimStart(u8, raw_line[colon + 1 ..], " \t");
        const val = std.mem.trimEnd(u8, val_raw, "\r");

        if (std.mem.eql(u8, key, "processor")) {
            cur = std.fmt.parseInt(i64, std.mem.trim(u8, val, " \t"), 10) catch -1;
            vendor_len = 0;
            continue;
        }

        const info = list.cpuById(cur) orelse continue;

        if (std.mem.eql(u8, key, "vendor_id")) {
            const n = @min(val.len, vendor_buf.len - 1);
            @memcpy(vendor_buf[0..n], val[0..n]);
            vendor_len = n;
            continue;
        }

        if (comptime is_x86) {
            if (std.mem.eql(u8, key, "flags")) {
                info.tsc_invariant = if (hasFlag(val, "constant_tsc")) 1 else 0;
                info.tsc_nonstop = if (hasFlag(val, "nonstop_tsc")) 1 else 0;
                info.tsc_known_freq = if (hasFlag(val, "tsc_known_freq")) 1 else 0;
                continue;
            }
        }

        if (info.ident().len != 0)
            continue;

        for (keys) |k| {
            if (std.mem.eql(u8, key, k)) {
                info.setIdent(vendor_buf[0..vendor_len], val);
                break;
            }
        }
    }
}

fn cpuinfoLinux(list: *CpuList) void {
    const keys = [_][]const u8{ "model name", "uarch", "cpu model", "cpu", "machine" };
    const f = fopen("/proc/cpuinfo", "r") orelse return;
    defer _ = fclose(f);

    var line_buf: [4096]u8 = undefined;
    var vendor_buf: [64]u8 = @splat(0);
    var vendor_len: usize = 0;
    var cur: i64 = -1;

    while (fgets(&line_buf, line_buf.len, f) != null) {
        const raw_line = std.mem.sliceTo(&line_buf, 0);
        const colon = std.mem.indexOfScalar(u8, raw_line, ':') orelse continue;
        const key = std.mem.trimEnd(u8, raw_line[0..colon], " \t");
        const after_colon = std.mem.trimStart(u8, raw_line[colon + 1 ..], " \t");
        const val = if (std.mem.indexOfScalar(u8, after_colon, '\n')) |nl| after_colon[0..nl] else after_colon;

        if (std.mem.eql(u8, key, "processor")) {
            cur = std.fmt.parseInt(i64, std.mem.trim(u8, val, " \t"), 10) catch -1;
            vendor_len = 0;
            continue;
        }

        const info = list.cpuById(cur) orelse continue;

        if (std.mem.eql(u8, key, "vendor_id")) {
            const n = @min(val.len, vendor_buf.len - 1);
            @memcpy(vendor_buf[0..n], val[0..n]);
            vendor_len = n;
            continue;
        }

        if (comptime is_x86) {
            if (std.mem.eql(u8, key, "flags")) {
                info.tsc_invariant = if (hasFlag(val, "constant_tsc")) 1 else 0;
                info.tsc_nonstop = if (hasFlag(val, "nonstop_tsc")) 1 else 0;
                info.tsc_known_freq = if (hasFlag(val, "tsc_known_freq")) 1 else 0;
                continue;
            }
        }

        if (info.ident().len != 0)
            continue;

        for (keys) |k| {
            if (std.mem.eql(u8, key, k)) {
                info.setIdent(vendor_buf[0..vendor_len], val);
                break;
            }
        }
    }
}

fn pinToCpuLinux(cpu: u64) i32 {
    const cpu_setsize: u64 = 1024;
    if (cpu >= cpu_setsize)
        return -Errno.INVAL;

    const bits_per_word = @bitSizeOf(usize);
    var set: [cpu_setsize / bits_per_word]usize = @splat(0);
    const word_idx: usize = @intCast(cpu / bits_per_word);
    const bit_idx: std.math.Log2Int(usize) = @intCast(cpu % bits_per_word);
    set[word_idx] |= @as(usize, 1) << bit_idx;

    if (sched_setaffinity(0, @sizeOf(@TypeOf(set)), &set) != 0)
        return -getErrno();

    if (sched_getcpu() != @as(c_int, @intCast(cpu)))
        return -Errno.AGAIN;

    return 0;
}

var unreachable_note_buf: [512]u8 = undefined;

fn getCpusLinux(list: *CpuList, err_writer: *std.Io.Writer) i32 {
    var online_buf: [1024]u8 = undefined;
    const online = switch (readFileStr(JENT_SYSFS_CPU ++ "/online", &online_buf)) {
        .ok => |s| s,
        .err => |ret| {
            err_writer.print("Cannot read " ++ JENT_SYSFS_CPU ++ "/online: {s}\n", .{strerrorSlice(-ret)}) catch {};
            return ret;
        },
    };

    var cpu_ids: [JENT_MAX_CPUS]u64 = undefined;
    var ncpu = parseCpuList(online, &cpu_ids);
    if (ncpu < 0) {
        err_writer.print("Cannot parse the list of online CPUs \"{s}\"\n", .{online}) catch {};
        return @intCast(ncpu);
    }

    list.ncpu = ncpu;
    list.pinning = true;
    list.backend = "linux";

    if (ncpu > JENT_MAX_CPUS) {
        err_writer.print("Only the first {d} of {d} online CPUs are reported\n", .{ JENT_MAX_CPUS, ncpu }) catch {};
        ncpu = JENT_MAX_CPUS;
    }

    const ncpu_usize: usize = @intCast(ncpu);
    const bits_per_word = @bitSizeOf(usize);
    const ncpu_set: usize = @intCast(cpu_ids[ncpu_usize - 1] + 1);
    const words_needed = (ncpu_set + bits_per_word - 1) / bits_per_word;
    const setsize = words_needed * @sizeOf(usize);
    var previous_mask: [JENT_CPU_LIST_MAX / bits_per_word]usize = @splat(0);
    const have_previous = (setsize <= @sizeOf(@TypeOf(previous_mask))) and
        (sched_getaffinity(0, setsize, &previous_mask) == 0);

    var unreachable_count: i64 = 0;

    for (0..ncpu_usize) |i| {
        const info = &list.cpu[i];
        info.* = .{
            .cpu = cpu_ids[i],
            .cpu_valid = true,
        };

        info.pkg = readCpuSigned(info.cpu, "topology/physical_package_id") orelse -1;
        info.core = readCpuSigned(info.cpu, "topology/core_id") orelse -1;
        info.max_khz = readCpuVal(info.cpu, "cpufreq/cpuinfo_max_freq") orelse 0;
        info.base_khz = readCpuVal(info.cpu, "cpufreq/base_frequency") orelse 0;

        if (info.base_khz == 0) {
            if (readCpuVal(info.cpu, "acpi_cppc/nominal_freq")) |nominal| {
                if (nominal != 0)
                    info.base_khz = nominal * 1000;
            }
        }

        if (info.max_khz == 0) {
            info.max_khz = readCpuVal(info.cpu, "cpufreq/amd_pstate_max_freq") orelse 0;
        }

        cachesLinux(info);
        identSysfsLinux(info);

        if (pinToCpuLinux(info.cpu) != 0) {
            unreachable_count += 1;
            continue;
        }

        identLocalLinux(info);
    }

    if (have_previous) {
        _ = sched_setaffinity(0, setsize, &previous_mask);
    }

    list.entries = ncpu_usize;

    cpuinfoLinux(list);

    if (unreachable_count > 0) {
        const note = std.fmt.bufPrint(
            &unreachable_note_buf,
            "{d} of the {d} CPUs could not be visited: this process is confined to a cpuset\n" ++
                "that does not include them - a container or a cgroup - so what only the CPU\n" ++
                "itself reports is missing for them, its core type on Intel among it. Run outside\n" ++
                "that confinement to describe every CPU.",
            .{ unreachable_count, ncpu },
        ) catch unreachable_note_buf[0..0];
        list.note = note;
    }

    return 0;
}

// ============================================================================
// macOS backend
// ============================================================================

extern "c" fn sysctlbyname(
    name: [*:0]const u8,
    oldp: ?*anyopaque,
    oldlenp: *usize,
    newp: ?*const anyopaque,
    newlen: usize,
) c_int;

fn sysctlStr(name: [*:0]const u8, buf: []u8) i32 {
    if (buf.len == 0) return -Errno.INVAL;
    buf[0] = 0;
    var len: usize = buf.len;
    if (sysctlbyname(name, buf.ptr, &len, null, 0) != 0)
        return -getErrno();
    buf[buf.len - 1] = 0;
    return 0;
}

fn sysctlNum(name: [*:0]const u8, val: *u64) i32 {
    var len: usize = 0;
    if (sysctlbyname(name, null, &len, null, 0) != 0)
        return -getErrno();

    if (len == @sizeOf(u32)) {
        var v: u32 = 0;
        len = @sizeOf(u32);
        if (sysctlbyname(name, &v, &len, null, 0) != 0)
            return -getErrno();
        val.* = v;
        return 0;
    }
    if (len == @sizeOf(u64)) {
        var v: u64 = 0;
        len = @sizeOf(u64);
        if (sysctlbyname(name, &v, &len, null, 0) != 0)
            return -getErrno();
        val.* = v;
        return 0;
    }
    return -Errno.INVAL;
}

fn sysctlLevelNum(level: i32, attr: []const u8, val: *u64) i32 {
    var name_buf: [64]u8 = undefined;
    const name = if (level < 0)
        bufPrintZ(&name_buf, "hw.{s}", .{attr}) catch return -Errno.INVAL
    else
        bufPrintZ(&name_buf, "hw.perflevel{d}.{s}", .{ level, attr }) catch return -Errno.INVAL;
    return sysctlNum(name.ptr, val);
}

fn timerMacos(info: *CpuInfo) void {
    if (comptime is_arm64) {
        timerArm64(info);
    } else if (comptime is_x86) {
        var freq: u64 = 0;
        if (sysctlNum("machdep.tsc.frequency", &freq) == 0 and freq != 0)
            info.tsc_khz = freq / 1000;
    }
}

fn getCpusMacos(list: *CpuList) i32 {
    var nlevels: u64 = 0;
    var freq: u64 = 0;
    var ncpu: u64 = 0;
    var packages: u64 = 0;
    var ident_buf: [JENT_IDENT_LEN - 64]u8 = @splat(0);
    var vendor_buf: [63]u8 = @splat(0);

    if (sysctlNum("hw.logicalcpu", &ncpu) != 0 or ncpu == 0)
        return -Errno.NOENT;
    list.ncpu = @intCast(ncpu);

    list.pinning = false;
    list.backend = "macos";
    list.note =
        "macOS describes the cores per performance level, not per CPU: the CPU\n" ++
        "column is the position in this listing, fastest level first, and Core\n" ++
        "counts within a level - equal Core numbers of different Types are\n" ++
        "different cores.";
    list.select =
        "  jitterentropy-hashtime <rounds> <repeats> <file> --e-cores\n" ++
        "  No thread-to-CPU pinning here: --e-cores selects the efficiency cores and\n" ++
        "  --p-cores asks for the performance ones, which a recording uses anyway\n" ++
        "  unless the process was put in the background.";

    _ = sysctlStr("machdep.cpu.vendor", &vendor_buf);
    _ = sysctlStr("machdep.cpu.brand_string", &ident_buf);
    if (sysctlNum("hw.cpufrequency_max", &freq) != 0)
        freq = 0;

    if (sysctlNum("hw.packages", &packages) != 0 or packages != 1)
        packages = 0;

    if (sysctlNum("hw.nperflevels", &nlevels) != 0 or nlevels < 2)
        nlevels = 0;
    const levels: i32 = if (nlevels != 0) @intCast(nlevels) else 1;

    var n: usize = 0;
    var level: i32 = 0;
    while (level < levels and n < JENT_MAX_CPUS) : (level += 1) {
        var logical: u64 = 0;
        var physical: u64 = 0;
        var l1d: u64 = 0;
        var l1i: u64 = 0;
        var l2: u64 = 0;
        var l3: u64 = 0;
        var per_l2: u64 = 0;
        const sel: i32 = if (nlevels != 0) level else -1;
        var name_buf: [64]u8 = undefined;
        var type_buf: [64]u8 = @splat(0);
        var core_type_buf: [JENT_TYPE_LEN]u8 = @splat(0);
        var core_type_len: usize = 0;

        if (sysctlLevelNum(sel, "logicalcpu", &logical) != 0 or logical == 0)
            continue;
        if (sysctlLevelNum(sel, "physicalcpu", &physical) != 0 or physical == 0 or physical > logical)
            physical = logical;

        _ = sysctlLevelNum(sel, "l1dcachesize", &l1d);
        _ = sysctlLevelNum(sel, "l1icachesize", &l1i);
        _ = sysctlLevelNum(sel, "l2cachesize", &l2);
        if (sysctlLevelNum(sel, "cpusperl2", &per_l2) != 0)
            per_l2 = 0;
        if (sysctlNum("hw.l3cachesize", &l3) != 0)
            l3 = 0;

        if (nlevels != 0) {
            if (bufPrintZ(&name_buf, "hw.perflevel{d}.name", .{level})) |name_z| {
                if (sysctlStr(name_z.ptr, &type_buf) != 0)
                    type_buf[0] = 0;
            } else |_| {
                type_buf[0] = 0;
            }
            const t_str = std.mem.sliceTo(&type_buf, 0);
            const chosen = if (t_str.len > 0 and t_str[0] == 'P' or (t_str.len == 0 and level == 0))
                "P-core"
            else if (t_str.len == 0 or t_str[0] == 'E')
                "E-core"
            else
                t_str;
            core_type_len = @min(chosen.len, JENT_TYPE_LEN - 1);
            @memcpy(core_type_buf[0..core_type_len], chosen[0..core_type_len]);
        }

        const vendor_s = std.mem.sliceTo(&vendor_buf, 0);
        const ident_s = std.mem.sliceTo(&ident_buf, 0);

        var i: u64 = 0;
        while (i < logical and n < JENT_MAX_CPUS) : ({
            i += 1;
            n += 1;
        }) {
            const info = &list.cpu[n];
            info.* = .{
                .cpu = @intCast(n),
                .cpu_valid = true,
                .pkg = if (packages != 0) 0 else -1,
                .core = @intCast(i / (logical / physical)),
                .max_khz = freq / 1000,
                .l1d = .{ .size = l1d, .shared = 1 },
                .l1i = .{ .size = l1i, .shared = 1 },
                .l2 = .{ .size = l2, .shared = per_l2 },
                .l3 = .{ .size = l3, .shared = ncpu },
            };
            timerMacos(info);
            info.setIdent(vendor_s, ident_s);
            info.setType(core_type_buf[0..core_type_len]);
        }
    }

    if (n == 0)
        return -Errno.NOENT;

    list.entries = n;
    return 0;
}

// ============================================================================
// Windows backend
// ============================================================================

const JENT_MAX_GROUPS: u16 = 64;

pub const WinGroup = struct {
    base: u64 = 0,
    active: usize = 0,
};

pub fn flatCpu(groups: []const WinGroup, group: u16, bit: usize) i64 {
    if (group >= groups.len or bit >= @bitSizeOf(usize))
        return -1;
    const shift: std.math.Log2Int(usize) = @intCast(bit);
    if (((groups[group].active >> shift) & 1) == 0)
        return -1;
    const mask_below: usize = if (bit == 0) 0 else (@as(usize, 1) << shift) - 1;
    const below = groups[group].active & mask_below;
    return @intCast(groups[group].base + @popCount(below));
}

const WinApi = struct {
    const ERROR_SUCCESS: c_long = 0;
    const ERROR_INSUFFICIENT_BUFFER: u32 = 122;
    const HKEY_LOCAL_MACHINE: ?*anyopaque = @ptrFromInt(0x80000002);
    const RRF_RT_REG_SZ: u32 = 0x00000002;
    const RRF_RT_REG_DWORD: u32 = 0x00000010;

    const RelationProcessorCore: c_uint = 0;
    const RelationCache: c_uint = 2;
    const RelationProcessorPackage: c_uint = 3;
    const RelationGroup: c_uint = 4;
    const RelationAll: c_uint = 0xffff;

    const CacheInstruction: c_uint = 1;
    const CacheTrace: c_uint = 3;

    const PROCESSOR_NUMBER = extern struct {
        Group: u16,
        Number: u8,
        Reserved: u8,
    };

    const GROUP_AFFINITY = extern struct {
        Mask: usize,
        Group: u16,
        Reserved: [3]u16,
    };

    const PROCESSOR_GROUP_INFO = extern struct {
        MaximumProcessorCount: u8,
        ActiveProcessorCount: u8,
        Reserved: [38]u8,
        ActiveProcessorMask: usize,
    };

    const GROUP_RELATIONSHIP = extern struct {
        MaximumGroupCount: u16,
        ActiveGroupCount: u16,
        Reserved: [20]u8,
        GroupInfo: [1]PROCESSOR_GROUP_INFO,
    };

    const PROCESSOR_RELATIONSHIP = extern struct {
        Flags: u8,
        EfficiencyClass: u8,
        Reserved: [20]u8,
        GroupCount: u16,
        GroupMask: [1]GROUP_AFFINITY,
    };

    const CACHE_RELATIONSHIP = extern struct {
        Level: u8,
        Associativity: u8,
        LineSize: u16,
        CacheSize: u32,
        Type: c_uint,
        Reserved: [20]u8,
        GroupMask: GROUP_AFFINITY,
    };

    const SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX = extern struct {
        Relationship: c_uint,
        Size: u32,
        u: extern union {
            Processor: PROCESSOR_RELATIONSHIP,
            Cache: CACHE_RELATIONSHIP,
            Group: GROUP_RELATIONSHIP,
        },
    };

    extern "kernel32" fn GetLogicalProcessorInformationEx(
        RelationshipType: c_uint,
        Buffer: ?*anyopaque,
        ReturnedLength: *u32,
    ) callconv(.winapi) c_int;
    extern "kernel32" fn GetLastError() callconv(.winapi) u32;
    extern "kernel32" fn GetCurrentThread() callconv(.winapi) ?*anyopaque;
    extern "kernel32" fn SetThreadGroupAffinity(
        hThread: ?*anyopaque,
        GroupAffinity: *const GROUP_AFFINITY,
        PreviousGroupAffinity: ?*GROUP_AFFINITY,
    ) callconv(.winapi) c_int;
    extern "kernel32" fn GetCurrentProcessorNumberEx(
        ProcNumber: *PROCESSOR_NUMBER,
    ) callconv(.winapi) void;
    extern "advapi32" fn RegGetValueA(
        hkey: ?*anyopaque,
        lpSubKey: [*:0]const u8,
        lpValue: [*:0]const u8,
        dwFlags: u32,
        pdwType: ?*u32,
        pvData: ?*anyopaque,
        pcbData: ?*u32,
    ) callconv(.winapi) c_long;
};

fn forEachCpuWindows(
    list: *CpuList,
    groups: []const WinGroup,
    mask: *const WinApi.GROUP_AFFINITY,
    ctx: anytype,
    comptime applyFn: fn (*CpuInfo, @TypeOf(ctx)) void,
) void {
    for (0..@bitSizeOf(usize)) |bit| {
        const shift: std.math.Log2Int(usize) = @intCast(bit);
        if (((mask.Mask >> shift) & 1) == 0)
            continue;
        const cpu = flatCpu(groups, mask.Group, bit);
        if (cpu < 0 or @as(usize, @intCast(cpu)) >= list.entries)
            continue;
        applyFn(&list.cpu[@intCast(cpu)], ctx);
    }
}

fn groupsWindows(out: []WinGroup, ngroups_out: *u16) i64 {
    const hdr = @offsetOf(WinApi.SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX, "u");
    var len: u32 = 0;

    if (WinApi.GetLogicalProcessorInformationEx(WinApi.RelationGroup, null, &len) != 0 or
        WinApi.GetLastError() != WinApi.ERROR_INSUFFICIENT_BUFFER)
    {
        return -Errno.FAULT;
    }

    const raw_buf = std.c.malloc(len) orelse return -Errno.NOMEM;
    defer std.c.free(raw_buf);

    if (WinApi.GetLogicalProcessorInformationEx(WinApi.RelationGroup, raw_buf, &len) == 0)
        return -Errno.FAULT;

    const rec: *const WinApi.SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX = @ptrCast(@alignCast(raw_buf));
    var need: usize = hdr + @offsetOf(WinApi.GROUP_RELATIONSHIP, "GroupInfo");
    if (@as(usize, len) < hdr or
        @as(usize, len) < rec.Size or
        rec.Relationship != WinApi.RelationGroup or
        rec.Size < need)
    {
        return -Errno.FAULT;
    }

    const rel = &rec.u.Group;
    need += @as(usize, rel.ActiveGroupCount) * @sizeOf(WinApi.PROCESSOR_GROUP_INFO);
    if (rec.Size < need)
        return -Errno.FAULT;

    const max_groups: u16 = @intCast(out.len);
    const count: u16 = @min(rel.ActiveGroupCount, max_groups);
    ngroups_out.* = count;

    const group_info_ptr: [*]const WinApi.PROCESSOR_GROUP_INFO = @ptrCast(&rel.GroupInfo);
    var ncpu: i64 = 0;
    for (0..count) |group| {
        const gi = &group_info_ptr[group];
        out[group].base = @intCast(ncpu);
        out[group].active = gi.ActiveProcessorMask;
        ncpu += gi.ActiveProcessorCount;
    }

    return ncpu;
}

const WinCacheCtx = struct {
    cache: CacheInfo,
    level: u8,
    instruction: bool,
};

fn setWinCache(info: *CpuInfo, ctx: WinCacheCtx) void {
    const cache: *CacheInfo = if (ctx.level == 1 and ctx.instruction)
        &info.l1i
    else if (ctx.level == 1)
        &info.l1d
    else if (ctx.level == 2 and !ctx.instruction)
        &info.l2
    else if (ctx.level == 3 and !ctx.instruction)
        &info.l3
    else
        return;

    cache.* = ctx.cache;
}

const WinCoreCtx = struct {
    index: i64,
    efficiency_class: u8,
};

fn setWinCore(info: *CpuInfo, ctx: WinCoreCtx) void {
    info.core = ctx.index;
    info.max_khz = @as(u64, ctx.efficiency_class) + 1;
}

fn setWinPackage(info: *CpuInfo, pkg: i64) void {
    info.pkg = pkg;
}

fn identWindows(info: *CpuInfo) void {
    var key_buf: [128]u8 = undefined;
    var name_buf: [JENT_IDENT_LEN - 64]u8 = @splat(0);
    var vendor_buf: [63]u8 = @splat(0);
    var len: u32 = 0;
    var mhz: u32 = 0;

    const key = bufPrintZ(
        &key_buf,
        "HARDWARE\\DESCRIPTION\\System\\CentralProcessor\\{d}",
        .{info.cpu},
    ) catch return;

    len = vendor_buf.len;
    if (WinApi.RegGetValueA(
        WinApi.HKEY_LOCAL_MACHINE,
        key.ptr,
        "VendorIdentifier",
        WinApi.RRF_RT_REG_SZ,
        null,
        &vendor_buf,
        &len,
    ) != WinApi.ERROR_SUCCESS) {
        vendor_buf[0] = 0;
    }

    len = name_buf.len;
    if (WinApi.RegGetValueA(
        WinApi.HKEY_LOCAL_MACHINE,
        key.ptr,
        "ProcessorNameString",
        WinApi.RRF_RT_REG_SZ,
        null,
        &name_buf,
        &len,
    ) != WinApi.ERROR_SUCCESS) {
        name_buf[0] = 0;
    }

    info.setIdent(std.mem.sliceTo(&vendor_buf, 0), std.mem.sliceTo(&name_buf, 0));

    len = @sizeOf(u32);
    if (WinApi.RegGetValueA(
        WinApi.HKEY_LOCAL_MACHINE,
        key.ptr,
        "~MHz",
        WinApi.RRF_RT_REG_DWORD,
        null,
        &mhz,
        &len,
    ) == WinApi.ERROR_SUCCESS) {
        info.base_khz = @as(u64, mhz) * 1000;
    }
}

fn recordFitsWindows(p: *const WinApi.SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX, hdr: usize) bool {
    if (p.Relationship == WinApi.RelationCache)
        return p.Size >= hdr + @sizeOf(WinApi.CACHE_RELATIONSHIP);

    if (p.Relationship != WinApi.RelationProcessorCore and
        p.Relationship != WinApi.RelationProcessorPackage)
    {
        return true;
    }

    const need = hdr + @offsetOf(WinApi.PROCESSOR_RELATIONSHIP, "GroupMask");
    if (p.Size < need)
        return false;

    return @as(usize, p.Size - @as(u32, @intCast(need))) >=
        @as(usize, p.u.Processor.GroupCount) * @sizeOf(WinApi.GROUP_AFFINITY);
}

fn getCpusWindows(list: *CpuList, err_writer: *std.Io.Writer) i32 {
    var groups: [JENT_MAX_GROUPS]WinGroup = @splat(.{});
    var classes: [JENT_MAX_CPUS]u32 = @splat(0);
    var max_class: u32 = 0;
    const hdr = @offsetOf(WinApi.SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX, "u");
    var ngroups: u16 = 0;
    var len: u32 = 0;
    var cores: i64 = 0;
    var packages: i64 = 0;

    var ncpu = groupsWindows(&groups, &ngroups);
    if (ncpu < 0)
        return @intCast(ncpu);
    if (ngroups == 0 or ncpu == 0)
        return -Errno.NOENT;

    list.ncpu = ncpu;
    list.pinning = true;
    list.backend = "windows";
    if (ncpu > JENT_MAX_CPUS) {
        err_writer.print("Only the first {d} of {d} CPUs are reported\n", .{ JENT_MAX_CPUS, ncpu }) catch {};
        ncpu = JENT_MAX_CPUS;
    }
    const ncpu_usize: usize = @intCast(ncpu);
    list.entries = ncpu_usize;

    for (0..ncpu_usize) |i| {
        list.cpu[i] = .{
            .cpu = @intCast(i),
            .cpu_valid = true,
        };
    }

    if (WinApi.GetLogicalProcessorInformationEx(WinApi.RelationAll, null, &len) != 0 or
        WinApi.GetLastError() != WinApi.ERROR_INSUFFICIENT_BUFFER)
    {
        return -Errno.FAULT;
    }

    const raw_buf = std.c.malloc(len) orelse return -Errno.NOMEM;
    defer std.c.free(raw_buf);

    if (WinApi.GetLogicalProcessorInformationEx(WinApi.RelationAll, raw_buf, &len) == 0)
        return -Errno.FAULT;

    const active_groups = groups[0..ngroups];
    const base_bytes: [*]const u8 = @ptrCast(raw_buf);
    var offset: usize = 0;
    const total_len: usize = len;

    while (total_len - offset >= hdr) {
        const p: *const WinApi.SYSTEM_LOGICAL_PROCESSOR_INFORMATION_EX =
            @ptrCast(@alignCast(base_bytes + offset));

        if (p.Size < hdr or (total_len - offset) < p.Size or !recordFitsWindows(p, hdr))
            break;
        offset += p.Size;

        if (p.Relationship == WinApi.RelationCache and p.u.Cache.Type != WinApi.CacheTrace) {
            const ctx = WinCacheCtx{
                .level = p.u.Cache.Level,
                .instruction = (p.u.Cache.Type == WinApi.CacheInstruction),
                .cache = .{
                    .size = p.u.Cache.CacheSize,
                    .shared = @popCount(p.u.Cache.GroupMask.Mask),
                },
            };
            forEachCpuWindows(list, active_groups, &p.u.Cache.GroupMask, ctx, setWinCache);
        } else if (p.Relationship == WinApi.RelationProcessorCore) {
            const ctx = WinCoreCtx{
                .index = cores,
                .efficiency_class = p.u.Processor.EfficiencyClass,
            };
            cores += 1;
            if (ctx.efficiency_class > max_class)
                max_class = ctx.efficiency_class;
            const masks_ptr: [*]const WinApi.GROUP_AFFINITY = @ptrCast(&p.u.Processor.GroupMask);
            for (0..p.u.Processor.GroupCount) |n| {
                forEachCpuWindows(list, active_groups, &masks_ptr[n], ctx, setWinCore);
            }
        } else if (p.Relationship == WinApi.RelationProcessorPackage) {
            const pkg = packages;
            packages += 1;
            const masks_ptr: [*]const WinApi.GROUP_AFFINITY = @ptrCast(&p.u.Processor.GroupMask);
            for (0..p.u.Processor.GroupCount) |n| {
                forEachCpuWindows(list, active_groups, &masks_ptr[n], pkg, setWinPackage);
            }
        }
    }

    for (0..ncpu_usize) |i| {
        classes[i] = @intCast(list.cpu[i].max_khz);
        list.cpu[i].max_khz = 0;
    }

    for (0..ncpu_usize) |i| {
        const info = &list.cpu[i];
        if (max_class != 0 and classes[i] != 0) {
            info.setType(if (classes[i] - 1 == max_class) "P-core" else "E-core");
        }
        identWindows(info);
    }

    if (comptime is_x86) {
        var previous: WinApi.GROUP_AFFINITY = std.mem.zeroes(WinApi.GROUP_AFFINITY);
        var restore = false;

        for (0..ngroups) |group_idx| {
            const group: u16 = @intCast(group_idx);
            for (0..@bitSizeOf(usize)) |bit| {
                const cpu = flatCpu(active_groups, group, bit);
                if (cpu < 0 or @as(usize, @intCast(cpu)) >= ncpu_usize)
                    continue;

                const shift: std.math.Log2Int(usize) = @intCast(bit);
                var affinity = std.mem.zeroes(WinApi.GROUP_AFFINITY);
                affinity.Group = group;
                affinity.Mask = @as(usize, 1) << shift;
                var old = std.mem.zeroes(WinApi.GROUP_AFFINITY);
                if (WinApi.SetThreadGroupAffinity(WinApi.GetCurrentThread(), &affinity, &old) == 0)
                    continue;
                if (!restore) {
                    previous = old;
                    restore = true;
                }

                var current = std.mem.zeroes(WinApi.PROCESSOR_NUMBER);
                WinApi.GetCurrentProcessorNumberEx(&current);
                if (current.Group != group or current.Number != @as(u8, @intCast(bit)))
                    continue;

                freqX86(&list.cpu[@intCast(cpu)]);
            }
        }

        if (restore) {
            _ = WinApi.SetThreadGroupAffinity(WinApi.GetCurrentThread(), &previous, null);
        }
    }

    return 0;
}

// ============================================================================
// Generic backend (BSDs, Solaris, Haiku, AIX)
// ============================================================================

const have_sysctl = switch (builtin.os.tag) {
    .freebsd, .netbsd, .openbsd, .dragonfly => true,
    else => false,
};

const have_sysctlbyname = switch (builtin.os.tag) {
    .freebsd, .netbsd, .dragonfly => true,
    else => false,
};

const bsd_affinity = builtin.os.tag == .freebsd;

extern "c" fn sysconf(name: c_int) c_long;
extern "c" fn sysctl(
    name: [*]const c_int,
    namelen: c_uint,
    oldp: ?*anyopaque,
    oldlenp: *usize,
    newp: ?*const anyopaque,
    newlen: usize,
) c_int;
extern "c" fn cpuset_setaffinity(
    level: c_int,
    which: c_int,
    id: i64,
    setsize: usize,
    mask: *const anyopaque,
) c_int;

fn pinToCpuFreeBsd(cpu: u64) i32 {
    const cpu_setsize: u64 = 1024;
    if (cpu >= cpu_setsize)
        return -Errno.INVAL;

    const bits_per_word = @bitSizeOf(usize);
    var set: [cpu_setsize / bits_per_word]usize = @splat(0);
    const word_idx: usize = @intCast(cpu / bits_per_word);
    const bit_idx: std.math.Log2Int(usize) = @intCast(cpu % bits_per_word);
    set[word_idx] |= @as(usize, 1) << bit_idx;

    const CPU_LEVEL_WHICH: c_int = 3;
    const CPU_WHICH_TID: c_int = 1;
    if (cpuset_setaffinity(CPU_LEVEL_WHICH, CPU_WHICH_TID, -1, @sizeOf(@TypeOf(set)), &set) != 0)
        return -getErrno();

    return 0;
}

fn sysctlHwStr(node: c_int, buf: []u8) i32 {
    const CTL_HW: c_int = 6;
    const mib = [2]c_int{ CTL_HW, node };
    var len: usize = buf.len;
    if (sysctl(&mib, 2, buf.ptr, &len, null, 0) != 0)
        return -getErrno();
    buf[buf.len - 1] = 0;
    return 0;
}

fn clockrateGeneric() u64 {
    if (builtin.os.tag == .openbsd) {
        const CTL_HW: c_int = 6;
        const HW_CPUSPEED: c_int = 12;
        const mib = [2]c_int{ CTL_HW, HW_CPUSPEED };
        var speed: c_int = 0;
        var len: usize = @sizeOf(c_int);
        if (sysctl(&mib, 2, &speed, &len, null, 0) != 0 or speed <= 0)
            return 0;
        return @as(u64, @intCast(speed)) * 1000;
    } else if (comptime have_sysctlbyname) {
        var speed: c_int = 0;
        var len: usize = @sizeOf(c_int);
        if (sysctlbyname("hw.clockrate", &speed, &len, null, 0) == 0 and speed > 0)
            return @as(u64, @intCast(speed)) * 1000;

        var freq: u64 = 0;
        len = @sizeOf(u64);
        if (sysctlbyname("machdep.tsc_freq", &freq, &len, null, 0) == 0 and freq != 0)
            return freq / 1000;

        return 0;
    } else {
        return 0;
    }
}

fn describeCurrentGeneric(info: *CpuInfo) void {
    if (comptime have_sysctl) {
        const HW_MODEL: c_int = 2;
        var model_buf: [JENT_IDENT_LEN]u8 = @splat(0);
        if (sysctlHwStr(HW_MODEL, &model_buf) == 0 and model_buf[0] != 0) {
            info.setIdent(null, std.mem.sliceTo(&model_buf, 0));
        }
    }

    info.base_khz = clockrateGeneric();

    if (comptime is_x86) {
        identX86(info);
        cachesX86(info);
        freqX86(info);
    }
}

fn getCpusGeneric(list: *CpuList) i32 {
    const sc_nprocessors_onln: c_int = switch (builtin.os.tag) {
        .freebsd, .dragonfly => 58,
        .openbsd => 502,
        .netbsd => 83,
        .illumos => 15,
        .haiku => 35,
        else => 84,
    };
    const ncpu = sysconf(sc_nprocessors_onln);
    list.ncpu = if (ncpu > 0) @intCast(ncpu) else 1;
    list.backend = "generic";
    list.pinning = (builtin.os.tag != .openbsd);

    var n: usize = 0;
    if (comptime bsd_affinity) {
        const max_n: usize = @intCast(@min(list.ncpu, @as(i64, JENT_MAX_CPUS)));
        while (n < max_n) : (n += 1) {
            if (pinToCpuFreeBsd(@intCast(n)) != 0)
                break;
            const info = &list.cpu[n];
            info.* = .{
                .cpu = @intCast(n),
                .cpu_valid = true,
            };
            describeCurrentGeneric(info);
        }
    }

    if (n == 0) {
        const info = &list.cpu[0];
        info.* = .{
            .cpu_valid = false,
        };
        describeCurrentGeneric(info);
        n = 1;
        list.note =
            "This system describes no CPU but the one this tool runs on. On a\n" ++
            "hybrid CPU, run it repeatedly to see the other core types.";
    } else if (@as(i64, @intCast(n)) < list.ncpu) {
        list.note = "Only the CPUs this tool could place itself on are described.";
    }

    list.entries = n;
    return 0;
}

pub fn getCpus(list: *CpuList, err_writer: *std.Io.Writer) i32 {
    return switch (current_backend) {
        .linux => getCpusLinux(list, err_writer),
        .macos => getCpusMacos(list),
        .windows => getCpusWindows(list, err_writer),
        .generic => getCpusGeneric(list),
        .none => blk: {
            list.backend = "none";
            break :blk -Errno.NOSYS;
        },
    };
}

// ============================================================================
// Post-processing & Output formatting
// ============================================================================

pub fn markLpCores(list: *CpuList) void {
    var have_l3 = false;
    for (list.cpu[0..list.entries]) |*info| {
        if (info.l3.size != 0) {
            have_l3 = true;
            break;
        }
    }
    if (!have_l3) return;

    for (list.cpu[0..list.entries]) |*info| {
        if (std.mem.eql(u8, info.coreType(), "E-core") and info.l3.size == 0) {
            info.setType("LP-E-core");
        }
    }
}

pub fn formatCache(cache: CacheInfo, buf: []u8) []const u8 {
    if (cache.size == 0)
        return std.fmt.bufPrint(buf, "-", .{}) catch "-";
    if (cache.shared != 0)
        return std.fmt.bufPrint(buf, "{d}K/{d}", .{ cache.size / 1024, cache.shared }) catch "-";
    return std.fmt.bufPrint(buf, "{d}K", .{cache.size / 1024}) catch "-";
}

pub fn formatNum(val: i64, buf: []u8) []const u8 {
    if (val < 0)
        return std.fmt.bufPrint(buf, "-", .{}) catch "-";
    return std.fmt.bufPrint(buf, "{d}", .{val}) catch "-";
}

pub const JENT_FLAG_NONE: i32 = -1;
pub const JENT_FLAG_MIXED: i32 = -2;

const timer_name = if (is_arm64) "generic timer" else "timestamp counter";

pub const TscProp = enum {
    invariant,
    nonstop,
    known_freq,
};

pub fn tscFlag(list: *const CpuList, prop: TscProp) i32 {
    var value: i32 = JENT_FLAG_NONE;
    for (list.cpu[0..list.entries]) |*info| {
        const cur: i32 = switch (prop) {
            .nonstop => info.tsc_nonstop,
            .known_freq => info.tsc_known_freq,
            .invariant => info.tsc_invariant,
        };
        if (cur < 0) continue;
        if (value == JENT_FLAG_NONE)
            value = cur
        else if (value != cur)
            return JENT_FLAG_MIXED;
    }
    return value;
}

pub fn vendorIs(list: *const CpuList, vendor: []const u8) bool {
    for (list.cpu[0..list.entries]) |*info| {
        if (std.mem.startsWith(u8, info.ident(), vendor))
            return true;
    }
    return false;
}

pub fn flagStr(value: i32) []const u8 {
    return switch (value) {
        1 => "yes",
        0 => "no",
        JENT_FLAG_MIXED => "differs between CPUs",
        else => "unknown",
    };
}

pub fn haveType(list: *const CpuList, prefix: []const u8) bool {
    for (list.cpu[0..list.entries]) |*info| {
        if (std.mem.startsWith(u8, info.coreType(), prefix))
            return true;
    }
    return false;
}

pub fn writeNote(writer: *std.Io.Writer, heading: *bool, text: []const u8) !void {
    if (!heading.*) {
        try writer.writeAll("\nNotes:\n");
        heading.* = true;
    }
    try writer.writeAll("  - ");
    for (text) |c| {
        try writer.writeByte(c);
        if (c == '\n')
            try writer.writeAll("    ");
    }
    try writer.writeByte('\n');
}

pub fn formatIdent(
    info: *const CpuInfo,
    idents: *[JENT_MAX_CPUS][]const u8,
    nidents: *usize,
    buf: []u8,
) []const u8 {
    const id_str = info.ident();
    if (id_str.len == 0)
        return std.fmt.bufPrint(buf, "-", .{}) catch "-";

    var j: usize = 0;
    while (j < nidents.*) : (j += 1) {
        if (std.mem.eql(u8, idents[j], id_str))
            break;
    }
    if (j == nidents.* and nidents.* < JENT_MAX_CPUS) {
        idents[nidents.*] = id_str;
        nidents.* += 1;
    }

    return std.fmt.bufPrint(buf, "#{d}", .{j + 1}) catch "-";
}

const row_fmt = "{s:<9} {s:>7} {s:>7} {s:>7} {s:>10} {s:>10} {s:>10} {s:>11} {s:>6}\n";

fn formatRow(
    info: *const CpuInfo,
    idents: *[JENT_MAX_CPUS][]const u8,
    nidents: *usize,
    buf: []u8,
) []const u8 {
    var base_b: [16]u8 = undefined;
    var mhz_b: [16]u8 = undefined;
    var tsc_b: [16]u8 = undefined;
    var ident_b: [16]u8 = undefined;
    var l1d_b: [24]u8 = undefined;
    var l1i_b: [24]u8 = undefined;
    var l2_b: [24]u8 = undefined;
    var l3_b: [24]u8 = undefined;

    const base = formatNum(if (info.base_khz != 0) @intCast(info.base_khz / 1000) else -1, &base_b);
    const mhz = formatNum(if (info.max_khz != 0) @intCast(info.max_khz / 1000) else -1, &mhz_b);
    const tsc = formatNum(if (info.tsc_khz != 0) @intCast(info.tsc_khz / 1000) else -1, &tsc_b);
    const l1d = formatCache(info.l1d, &l1d_b);
    const l1i = formatCache(info.l1i, &l1i_b);
    const l2 = formatCache(info.l2, &l2_b);
    const l3 = formatCache(info.l3, &l3_b);
    const id_col = formatIdent(info, idents, nidents, &ident_b);
    const t_col = if (info.coreType().len != 0) info.coreType() else "-";

    return std.fmt.bufPrint(buf, row_fmt, .{
        t_col, base, mhz, tsc, l1d, l1i, l2, l3, id_col,
    }) catch "";
}

fn writeTable(
    writer: *std.Io.Writer,
    list: *const CpuList,
    idents: *[JENT_MAX_CPUS][]const u8,
    nidents: *usize,
) !void {
    try writer.print("{s:>4} {s:>4} {s:>5} " ++ row_fmt, .{
        "CPU",    "Pkg", "Core", "Type", "BaseMHz", "MaxMHz",
        "TmrMHz", "L1d", "L1i",  "L2",   "L3",      "Model",
    });

    for (list.cpu[0..list.entries]) |*info| {
        var cpu_b: [16]u8 = undefined;
        var pkg_b: [16]u8 = undefined;
        var core_b: [16]u8 = undefined;
        var row_b: [256]u8 = undefined;

        const cpu_s = if (info.cpu_valid)
            std.fmt.bufPrint(&cpu_b, "{d}", .{info.cpu}) catch "?"
        else
            "?";
        const pkg_s = formatNum(info.pkg, &pkg_b);
        const core_s = formatNum(info.core, &core_b);
        const row_s = formatRow(info, idents, nidents, &row_b);

        try writer.print("{s:>4} {s:>4} {s:>5} {s}", .{ cpu_s, pkg_s, core_s, row_s });
    }
}

pub fn sameKind(a: *const CpuInfo, b: *const CpuInfo) bool {
    return std.mem.eql(u8, a.coreType(), b.coreType()) and
        std.mem.eql(u8, a.ident(), b.ident()) and
        a.base_khz == b.base_khz and
        a.max_khz == b.max_khz and
        a.tsc_khz == b.tsc_khz and
        a.l1d.eql(b.l1d) and
        a.l1i.eql(b.l1i) and
        a.l2.eql(b.l2) and
        a.l3.eql(b.l3);
}

pub fn appendRange(buf: []u8, len: *usize, first: u64, last: u64) void {
    if (len.* > 0 and len.* + 1 < buf.len) {
        buf[len.*] = ',';
        len.* += 1;
    }
    const rem = buf[len.*..];
    const written = if (first == last)
        std.fmt.bufPrint(rem, "{d}", .{first}) catch return
    else
        std.fmt.bufPrint(rem, "{d}-{d}", .{ first, last }) catch return;
    len.* += written.len;
}

fn writeSummary(
    writer: *std.Io.Writer,
    list: *const CpuList,
    idents: *[JENT_MAX_CPUS][]const u8,
    nidents: *usize,
) !void {
    var printed: usize = 0;

    try writer.print("{s:>5} " ++ row_fmt, .{
        "CPUs", "Type", "BaseMHz", "MaxMHz", "TmrMHz",
        "L1d",  "L1i",  "L2",      "L3",     "Model",
    });

    for (0..list.entries) |i| {
        const info = &list.cpu[i];
        var already_covered = false;
        for (0..i) |j| {
            if (sameKind(&list.cpu[j], info)) {
                already_covered = true;
                break;
            }
        }
        if (already_covered) continue;

        var cpus_b: [512]u8 = undefined;
        var cpus_len: usize = 0;
        var first: u64 = 0;
        var last: u64 = 0;
        var open = false;
        var count: usize = 0;

        for (i..list.entries) |j| {
            const other = &list.cpu[j];
            if (!sameKind(other, info)) continue;
            count += 1;
            if (!other.cpu_valid) continue;

            if (open and other.cpu == last + 1) {
                last = other.cpu;
                continue;
            }
            if (open)
                appendRange(&cpus_b, &cpus_len, first, last);
            first = other.cpu;
            last = other.cpu;
            open = true;
        }
        if (open)
            appendRange(&cpus_b, &cpus_len, first, last);

        var row_b: [256]u8 = undefined;
        const row_s = formatRow(info, idents, nidents, &row_b);
        try writer.print("{d:>5} {s}", .{ count, row_s });
        if (cpus_len > 0)
            try writer.print("      CPUs {s}\n", .{cpus_b[0..cpus_len]});
        printed += 1;
    }

    if (printed == 1 and @as(i64, @intCast(list.entries)) == list.ncpu) {
        try writer.writeAll(
            "\nEvery CPU of this machine is of the same kind: any one of them can be\n" ++
                "recorded for all.\n",
        );
    }
}

pub fn writeCpus(writer: *std.Io.Writer, list: *const CpuList, summary: bool) !void {
    var idents: [JENT_MAX_CPUS][]const u8 = undefined;
    var nidents: usize = 0;

    if (summary)
        try writeSummary(writer, list, &idents, &nidents)
    else
        try writeTable(writer, list, &idents, &nidents);

    try writer.writeAll("\nColumns:\n");
    if (!summary)
        try writer.writeAll("  Pkg, Core  package and core ID - equal in both means SMT siblings of one core\n")
    else
        try writer.writeAll("  CPUs       how many CPUs are of this kind, and which ones they are\n");
    try writer.writeAll("  Type       core type as the system reports it\n");

    if (haveType(list, "cap "))
        try writer.writeAll(
            "             \"cap <N>\" is the compute capacity the scheduler works with,\n" ++
                "             1024 being the most capable core of the system\n",
        );
    if (haveType(list, "perf "))
        try writer.writeAll(
            "             \"perf <N>\" is the performance ranking the firmware gives the\n" ++
                "             core, 255 being the maximum - AMD reports no core type\n",
        );
    try writer.writeAll("  BaseMHz    nominal base frequency, not the clock the CPU currently runs at\n");
    try writer.print("  TmrMHz     rate of the {s}, which the Jitter RNG times with\n", .{timer_name});
    try writer.writeAll("  L1d - L3   cache size in KiB, followed by the number of CPUs sharing it\n");

    const inv = tscFlag(list, .invariant);
    const non = tscFlag(list, .nonstop);
    const knw = tscFlag(list, .known_freq);
    if (inv != JENT_FLAG_NONE or non != JENT_FLAG_NONE or knw != JENT_FLAG_NONE) {
        try writer.print("\nTimer: invariant {s}, nonstop {s}, known rate {s}\n", .{
            flagStr(inv),
            flagStr(non),
            flagStr(knw),
        });
    }

    var have_freq = false;
    var have_tsc = false;
    var heading = false;

    if (list.note) |note|
        try writeNote(writer, &heading, note);

    for (list.cpu[0..list.entries]) |*info| {
        if (info.base_khz != 0 or info.max_khz != 0)
            have_freq = true;
        if (info.tsc_khz != 0)
            have_tsc = true;
    }

    if (!have_tsc) {
        const amd = vendorIs(list, "AuthenticAMD");
        const known = tscFlag(list, .known_freq);

        if (amd and known == 1)
            try writeNote(
                writer,
                &heading,
                "The counter rate is not enumerated by this CPU: AMD implements neither\n" ++
                    "CPUID leaf carrying it, so only the operating system knows it.",
            )
        else if (amd)
            try writeNote(
                writer,
                &heading,
                "The counter rate is not enumerated by this CPU: AMD implements neither\n" ++
                    "CPUID leaf carrying it, and the operating system determines it on its own.",
            )
        else if (known == 1)
            try writeNote(
                writer,
                &heading,
                "The counter rate is not enumerated by this CPU, so only the operating\n" ++
                    "system knows it.",
            )
        else
            try writeNote(
                writer,
                &heading,
                "The counter rate is not enumerated by this CPU, and the operating system\n" ++
                    "determines it on its own.",
            );
    }

    if (!have_freq)
        try writeNote(
            writer,
            &heading,
            "No frequency is reported: neither the CPU nor the operating system\n" ++
                "states one.",
        );

    if (nidents > 0) {
        try writer.writeAll("\nModels:\n");
        for (0..nidents) |j| {
            try writer.print("  #{d}: {s}\n", .{ j + 1, idents[j] });
        }
    }

    try writer.writeAll("\nRecording:\n");
    if (list.pinning)
        try writer.writeAll("  jitterentropy-hashtime <rounds> <repeats> <file> --cpu <CPU>\n")
    else if (list.select) |sel|
        try writer.print("{s}\n", .{sel})
    else
        try writer.writeAll(
            "  This system offers no thread-to-CPU pinning, so a recording cannot be\n" ++
                "  confined to one core.\n",
        );
    try writer.writeAll("  Add --status to print the configuration a recording is made with.\n");
}

pub fn writeJsonString(writer: *std.Io.Writer, str: []const u8) !void {
    try writer.writeByte('"');
    for (str) |c| {
        switch (c) {
            '"', '\\' => try writer.print("\\{c}", .{c}),
            '\n' => try writer.writeAll("\\n"),
            '\t' => try writer.writeAll("\\t"),
            else => {
                if (c < 0x20)
                    try writer.print("\\u{x:0>4}", .{@as(u16, c)})
                else
                    try writer.writeByte(c);
            },
        }
    }
    try writer.writeByte('"');
}

pub fn jsonFlagStr(value: i32) []const u8 {
    if (value < 0) return "null";
    return if (value != 0) "true" else "false";
}

fn writeJsonCache(writer: *std.Io.Writer, name: []const u8, cache: CacheInfo, last: bool) !void {
    const suffix = if (last) "" else ",";
    try writer.print("\t\t\t\t\"{s}\": ", .{name});
    if (cache.size == 0) {
        try writer.print("null{s}\n", .{suffix});
        return;
    }
    try writer.print("{{ \"sizeBytes\": {d}, \"sharedCpus\": ", .{cache.size});
    if (cache.shared != 0)
        try writer.print("{d}", .{cache.shared})
    else
        try writer.writeAll("null");
    try writer.print(" }}{s}\n", .{suffix});
}

pub fn writeJson(writer: *std.Io.Writer, list: *const CpuList) !void {
    try writer.writeAll("{\n");
    try writer.print("\t\"cpus\": {d},\n", .{list.ncpu});
    try writer.print("\t\"pinning\": {s},\n", .{if (list.pinning) "true" else "false"});
    try writer.writeAll("\t\"backend\": ");
    try writeJsonString(writer, if (list.backend.len > 0) list.backend else "none");
    try writer.writeAll(",\n");

    try writer.writeAll("\t\"processors\": [\n");
    for (0..list.entries) |i| {
        const info = &list.cpu[i];
        try writer.writeAll("\t\t{\n");

        try writer.writeAll("\t\t\t\"cpu\": ");
        if (info.cpu_valid)
            try writer.print("{d},\n", .{info.cpu})
        else
            try writer.writeAll("null,\n");

        try writer.writeAll("\t\t\t\"package\": ");
        if (info.pkg < 0)
            try writer.writeAll("null,\n")
        else
            try writer.print("{d},\n", .{info.pkg});

        try writer.writeAll("\t\t\t\"core\": ");
        if (info.core < 0)
            try writer.writeAll("null,\n")
        else
            try writer.print("{d},\n", .{info.core});

        try writer.writeAll("\t\t\t\"coreType\": ");
        if (info.coreType().len != 0)
            try writeJsonString(writer, info.coreType())
        else
            try writer.writeAll("null");
        try writer.writeAll(",\n");

        try writer.writeAll("\t\t\t\"baseFrequencyKHz\": ");
        if (info.base_khz != 0)
            try writer.print("{d},\n", .{info.base_khz})
        else
            try writer.writeAll("null,\n");

        try writer.writeAll("\t\t\t\"maxFrequencyKHz\": ");
        if (info.max_khz != 0)
            try writer.print("{d},\n", .{info.max_khz})
        else
            try writer.writeAll("null,\n");

        try writer.writeAll("\t\t\t\"timer\": { \"frequencyKHz\": ");
        if (info.tsc_khz != 0)
            try writer.print("{d}", .{info.tsc_khz})
        else
            try writer.writeAll("null");
        try writer.print(", \"invariant\": {s}", .{jsonFlagStr(info.tsc_invariant)});
        try writer.print(", \"nonstop\": {s}", .{jsonFlagStr(info.tsc_nonstop)});
        try writer.print(", \"knownFrequency\": {s} }},\n", .{jsonFlagStr(info.tsc_known_freq)});

        try writer.writeAll("\t\t\t\"model\": ");
        if (info.ident().len != 0)
            try writeJsonString(writer, info.ident())
        else
            try writer.writeAll("null");
        try writer.writeAll(",\n");

        try writer.writeAll("\t\t\t\"caches\": {\n");
        try writeJsonCache(writer, "l1d", info.l1d, false);
        try writeJsonCache(writer, "l1i", info.l1i, false);
        try writeJsonCache(writer, "l2", info.l2, false);
        try writeJsonCache(writer, "l3", info.l3, true);
        try writer.writeAll("\t\t\t}\n");

        const comma = if (i + 1 < list.entries) "," else "";
        try writer.print("\t\t}}{s}\n", .{comma});
    }
    try writer.writeAll("\t]\n");
    try writer.writeAll("}\n");
}

pub fn writeUsage(writer: *std.Io.Writer, name: []const u8) !void {
    try writer.print("{s} [--summary] [--json]\n", .{name});
    try writer.writeAll("List the identification and the caches of all CPUs.\n\n");
    try writer.writeAll("  --summary  one row per kind of CPU instead of one per CPU\n");
    try writer.writeAll("  --json     report the same data as JSON, one entry per CPU\n");
    try writer.writeAll("  --help     print this text\n");
}

const FdWriter = struct {
    fd: c_int,
    interface: std.Io.Writer,

    fn init(fd: c_int, buffer: []u8) FdWriter {
        return .{
            .fd = fd,
            .interface = .{
                .vtable = &.{
                    .drain = drain,
                },
                .buffer = buffer,
            },
        };
    }

    fn drain(io_w: *std.Io.Writer, data: []const []const u8, splat: usize) std.Io.Writer.Error!usize {
        const self: *FdWriter = @alignCast(@fieldParentPtr("interface", io_w));
        const buffered = io_w.buffered();
        if (buffered.len > 0) {
            writeAllFd(self.fd, buffered);
            io_w.end = 0;
        }
        var total: usize = 0;
        if (data.len > 0) {
            for (data[0 .. data.len - 1]) |slice| {
                writeAllFd(self.fd, slice);
                total += slice.len;
            }
            const pattern = data[data.len - 1];
            for (0..splat) |_| {
                writeAllFd(self.fd, pattern);
                total += pattern.len;
            }
        }
        return total;
    }

    fn writeAllFd(fd: c_int, bytes: []const u8) void {
        var off: usize = 0;
        while (off < bytes.len) {
            const rc = write(fd, bytes.ptr + off, bytes.len - off);
            if (rc <= 0) break;
            off += @intCast(rc);
        }
    }
};

var global_cpu_list: CpuList = .{};

pub fn main(init: std.process.Init) u8 {
    var stdout_buf: [4096]u8 = undefined;
    var stderr_buf: [1024]u8 = undefined;
    var out_fd = FdWriter.init(1, &stdout_buf);
    var err_fd = FdWriter.init(2, &stderr_buf);
    const stdout = &out_fd.interface;
    const stderr = &err_fd.interface;
    defer {
        stdout.flush() catch {};
        stderr.flush() catch {};
    }

    var args_it = std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa) catch return 1;
    defer args_it.deinit();
    const prog_name = args_it.next() orelse "jitterentropy-cpuinfo";

    var json = false;
    var summary = false;

    while (args_it.next()) |arg| {
        if (std.mem.eql(u8, arg, "--json")) {
            json = true;
        } else if (std.mem.eql(u8, arg, "--summary")) {
            summary = true;
        } else if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            writeUsage(stdout, prog_name) catch {};
            return 0;
        } else {
            stderr.print("Unknown option {s}\n", .{arg}) catch {};
            stderr.flush() catch {};
            writeUsage(stdout, prog_name) catch {};
            return 1;
        }
    }

    global_cpu_list = .{};
    const ret = getCpus(&global_cpu_list, stderr);
    if (ret != 0) {
        stderr.print("Cannot obtain the CPU information: {s}\n", .{strerrorSlice(-ret)}) catch {};
        return 1;
    }

    markLpCores(&global_cpu_list);

    if (json) {
        writeJson(stdout, &global_cpu_list) catch return 1;
        return 0;
    }

    stdout.print("CPUs: {d}\n\n", .{global_cpu_list.ncpu}) catch return 1;
    writeCpus(stdout, &global_cpu_list, summary) catch return 1;

    return 0;
}

// ============================================================================
// Unit tests
// ============================================================================

test "setIdent trims leading and trailing spaces and joins vendor/model" {
    var info: CpuInfo = .{};

    info.setIdent("  AuthenticAMD  ", "  AMD EPYC 7763 64-Core Processor   \t ");
    try std.testing.expectEqualStrings("AuthenticAMD   AMD EPYC 7763 64-Core Processor", info.ident());

    info.setIdent("GenuineIntel", "   Intel(R) Core(TM) i7-13700K   ");
    try std.testing.expectEqualStrings("GenuineIntel Intel(R) Core(TM) i7-13700K", info.ident());

    info.setIdent(null, "  Apple M3 Max  ");
    try std.testing.expectEqualStrings("Apple M3 Max", info.ident());

    info.setIdent("GenuineIntel", "");
    try std.testing.expectEqualStrings("GenuineIntel", info.ident());

    info.setIdent("", "");
    try std.testing.expectEqualStrings("", info.ident());
}

test "parseBrandKhz extracts trailing nominal frequency" {
    try std.testing.expectEqual(@as(u64, 2_400_000), parseBrandKhz("Intel(R) Xeon(R) CPU E5-2620 v3 @ 2.40GHz"));
    try std.testing.expectEqual(@as(u64, 800_000), parseBrandKhz("Some CPU @ 800MHz"));
    try std.testing.expectEqual(@as(u64, 500), parseBrandKhz("Slow CPU @ 500kHz"));
    try std.testing.expectEqual(@as(u64, 500), parseBrandKhz("Slow CPU @ 500KHz"));
    try std.testing.expectEqual(@as(u64, 0), parseBrandKhz("AMD Ryzen 9 7950X 16-Core Processor"));
    try std.testing.expectEqual(@as(u64, 0), parseBrandKhz("CPU @ GHz"));
    try std.testing.expectEqual(@as(u64, 0), parseBrandKhz("CPU @ 2.40THz"));
}

test "CPUID parsing helpers" {
    // "GenuineIntel" -> EBX="Genu", EDX="ineI", ECX="ntel"
    const leaf0 = [4]u32{
        0x20,
        std.mem.readInt(u32, "Genu", .little),
        std.mem.readInt(u32, "ntel", .little),
        std.mem.readInt(u32, "ineI", .little),
    };
    const vendor = parseCpuidVendor(leaf0);
    try std.testing.expectEqualStrings("GenuineIntel", &vendor);

    var info: CpuInfo = .{};
    applyCpuidHybridType(&info, 0x20000000);
    try std.testing.expectEqualStrings("E-core", info.coreType());
    applyCpuidHybridType(&info, 0x40000000);
    try std.testing.expectEqualStrings("P-core", info.coreType());
    applyCpuidHybridType(&info, 0x30000000);
    try std.testing.expectEqualStrings("0x30", info.coreType());

    // CPUID frequency leaves
    var freq_info: CpuInfo = .{};
    applyCpuidFreq(
        &freq_info,
        .{ 3400, 5400, 100, 0 }, // leaf 0x16: base 3400 MHz, max 5400 MHz
        .{ 2, 176, 38_400_000, 0 }, // leaf 0x15: 38.4 MHz * 176 / 2 = 3,379,200 kHz
        null,
        .{ 0, 0, 0, @as(u32, 1) << 8 }, // leaf 0x80000007: invariant TSC
    );
    try std.testing.expectEqual(@as(u64, 3_400_000), freq_info.base_khz);
    try std.testing.expectEqual(@as(u64, 5_400_000), freq_info.max_khz);
    try std.testing.expectEqual(@as(u64, 3_379_200), freq_info.tsc_khz);
    try std.testing.expectEqual(@as(i32, 1), freq_info.tsc_known_freq);
    try std.testing.expectEqual(@as(i32, 1), freq_info.tsc_invariant);
    try std.testing.expectEqual(@as(i32, 1), freq_info.tsc_nonstop);

    // Deterministic cache parameter subleaf: L1d (level=1, type=1), 12 ways, 1 part, 64B line, 64 sets = 48 KiB
    var cache_info: CpuInfo = .{};
    const eax: u32 = 1 | (1 << 5);
    const ebx: u32 = ((12 - 1) << 22) | ((1 - 1) << 12) | (64 - 1);
    const ecx: u32 = 64 - 1;
    const outcome = applyCpuidCacheSubleaf(&cache_info, .{ eax, ebx, ecx, 0 });
    try std.testing.expectEqual(CpuidCacheSubleafOutcome.recorded, outcome);
    try std.testing.expectEqual(@as(u64, 48 * 1024), cache_info.l1d.size);
    try std.testing.expectEqual(CpuidCacheSubleafOutcome.end_of_leaves, applyCpuidCacheSubleaf(&cache_info, .{ 0, 0, 0, 0 }));
}

test "MIDR lookup table and formatting" {
    try std.testing.expectEqualStrings("ARM", armLookup(0x41, true).?);
    try std.testing.expectEqualStrings("Apple", armLookup(0x61, true).?);
    try std.testing.expectEqualStrings("Neoverse-N2", armLookup(0xd49, false).?);
    try std.testing.expect(armLookup(0xff, true) == null);

    var info: CpuInfo = .{};
    // ARM (0x41), variant 0, part 0xd49 (Neoverse-N2), revision 0 -> 0x410fd490
    formatMidrIdent(&info, 0x00000000410fd490);
    try std.testing.expectEqualStrings("ARM Neoverse-N2 r0p0", info.ident());

    // Apple (0x61), variant 1, part 0x032, revision 2
    formatMidrIdent(&info, (0x61 << 24) | (1 << 20) | (0x032 << 4) | 2);
    try std.testing.expectEqualStrings("Apple part 0x032 r1p2", info.ident());

    // Unknown implementer (0xfe)
    formatMidrIdent(&info, (0xfe << 24) | (2 << 20) | (0x123 << 4) | 3);
    try std.testing.expectEqualStrings("implementer 0xfe part 0x123 r2p3", info.ident());
}

test "parseCpuList and parseCacheSize and hasFlag" {
    var cpus: [16]u64 = undefined;
    const n = parseCpuList("0-3,8,10-11\n", &cpus);
    try std.testing.expectEqual(@as(i64, 7), n);
    try std.testing.expectEqualSlices(u64, &.{ 0, 1, 2, 3, 8, 10, 11 }, cpus[0..7]);

    try std.testing.expectEqual(@as(i64, -Errno.INVAL), parseCpuList("", null));
    try std.testing.expectEqual(@as(i64, -Errno.INVAL), parseCpuList("5-2", null));
    try std.testing.expectEqual(@as(i64, -Errno.INVAL), parseCpuList("0-65536", null));

    try std.testing.expectEqual(@as(u64, 65536), parseCacheSize("64K"));
    try std.testing.expectEqual(@as(u64, 33554432), parseCacheSize("32M"));
    try std.testing.expectEqual(@as(u64, 1073741824), parseCacheSize("1G"));
    try std.testing.expectEqual(@as(u64, 1024), parseCacheSize("1024"));
    try std.testing.expectEqual(@as(u64, 0), parseCacheSize("invalid"));

    try std.testing.expect(hasFlag("fpu vme constant_tsc nonstop_tsc", "constant_tsc"));
    try std.testing.expect(hasFlag("constant_tsc", "constant_tsc"));
    try std.testing.expect(!hasFlag("my_constant_tsc_ext", "constant_tsc"));
}

test "markLpCores and JSON escaping" {
    var list: CpuList = .{ .entries = 2, .ncpu = 2, .pinning = true, .backend = "linux" };
    list.cpu[0] = .{ .cpu = 0, .cpu_valid = true, .l3 = .{ .size = 32 * 1024 * 1024, .shared = 2 } };
    list.cpu[0].setType("P-core");
    list.cpu[1] = .{ .cpu = 1, .cpu_valid = true, .l3 = .{ .size = 0, .shared = 0 } };
    list.cpu[1].setType("E-core");

    markLpCores(&list);
    try std.testing.expectEqualStrings("P-core", list.cpu[0].coreType());
    try std.testing.expectEqualStrings("LP-E-core", list.cpu[1].coreType());

    var buf: [256]u8 = undefined;
    var w = std.Io.Writer.fixed(&buf);
    try writeJsonString(&w, "a\"b\\c\nd\te\x01");
    try std.testing.expectEqualStrings("\"a\\\"b\\\\c\\nd\\te\\u0001\"", w.buffered());
}

test "live getCpus and JSON output validation" {
    if (current_backend == .none) return;

    var err_buf: [512]u8 = undefined;
    var err_w = std.Io.Writer.fixed(&err_buf);
    var list: CpuList = .{};
    const rc = getCpus(&list, &err_w);
    try std.testing.expectEqual(@as(i32, 0), rc);
    try std.testing.expect(list.ncpu > 0);
    try std.testing.expect(list.entries > 0);

    markLpCores(&list);

    const json_buf = try std.testing.allocator.alloc(u8, 512 * 1024);
    defer std.testing.allocator.free(json_buf);
    var json_w = std.Io.Writer.fixed(json_buf);
    try writeJson(&json_w, &list);

    const parsed = try std.json.parseFromSlice(std.json.Value, std.testing.allocator, json_w.buffered(), .{});
    defer parsed.deinit();
    try std.testing.expect(parsed.value == .object);
    try std.testing.expectEqual(list.ncpu, parsed.value.object.get("cpus").?.integer);
}
