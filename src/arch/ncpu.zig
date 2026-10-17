// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const std = @import("std");
const builtin = @import("builtin");
const internal = @import("../internal.zig");

const root = @import("root");
const is_linux_kernel = @hasDecl(root, "is_linux_kernel") and root.is_linux_kernel;
const hosted = builtin.os.tag != .freestanding and builtin.os.tag != .uefi;
const windows = builtin.os.tag == .windows;
const linux = builtin.os.tag == .linux;
const posix = hosted and !windows;
const use_linux_sysfs = linux and switch (builtin.abi) {
    .musl, .musleabi, .musleabihf => true,
    else => false,
};

const CpuSet = [128]u8;
const Handle = ?*anyopaque;
const GroupAffinity = extern struct {
    Mask: usize,
    Group: c_ushort,
    Reserved: [3]c_ushort,
};

extern "c" fn __errno_location() *c_int;
extern "c" fn __error() *c_int;
extern "c" fn ___errno() *c_int;
extern "c" fn _errno() *c_int;
extern "c" fn sched_getaffinity(pid: c_int, size: usize, set: *anyopaque) c_int;
extern "c" fn sysconf(name: c_int) c_long;
extern "c" fn open(path: [*:0]const u8, flags: c_int, ...) c_int;
extern "c" fn read(fd: c_int, buf: *anyopaque, len: usize) isize;
extern "c" fn close(fd: c_int) c_int;
extern fn jent_kshim_num_online_cpus() callconv(.c) c_long;

extern "kernel32" fn GetCurrentThread() callconv(.winapi) Handle;
extern "kernel32" fn GetThreadGroupAffinity(thread: Handle, affinity: *GroupAffinity) callconv(.winapi) c_int;
extern "kernel32" fn GetLogicalProcessorInformationEx(
    relationship: c_int,
    buffer: ?*anyopaque,
    returned_length: *u32,
) callconv(.winapi) c_int;
extern "kernel32" fn GetLastError() callconv(.winapi) u32;
extern "kernel32" fn GetActiveProcessorCount(group: c_ushort) callconv(.winapi) u32;

const Err = enum {
    perm,
    io,
    again,
    nomem,
    fault,
    inval,
    nodev,
    nosys,
    notsup,
};

fn errnoValue(err: Err) c_int {
    return switch (builtin.os.tag) {
        .macos, .ios, .tvos, .watchos, .visionos => switch (err) {
            .perm => 1,
            .io => 5,
            .again => 35,
            .nomem => 12,
            .fault => 14,
            .inval => 22,
            .nodev => 19,
            .nosys => 78,
            .notsup => 45,
        },
        else => switch (err) {
            .perm => 1,
            .io => 5,
            .again => 11,
            .nomem => 12,
            .fault => 14,
            .inval => 22,
            .nodev => 19,
            .nosys => 38,
            .notsup => 95,
        },
    };
}

fn negErr(err: Err) c_long {
    return -@as(c_long, errnoValue(err));
}

fn errnoPtr() *c_int {
    if (linux) return __errno_location();
    if (builtin.os.tag.isDarwin() or builtin.os.tag == .freebsd or
        builtin.os.tag == .netbsd or builtin.os.tag == .openbsd or
        builtin.os.tag == .dragonfly)
    {
        return __error();
    }
    if (builtin.os.tag == .illumos) return ___errno();
    return _errno();
}

fn sysconfNprocessorsOnln() c_int {
    return switch (builtin.os.tag) {
        .linux => 84,
        .macos, .ios, .tvos, .watchos, .visionos, .freebsd, .openbsd, .dragonfly => 58,
        .netbsd => 1002,
        .illumos => 15,
        else => 58,
    };
}

const WindowsGroups = struct {
    bytes: []u8,
    active_count: c_ushort,

    fn deinit(self: WindowsGroups) void {
        std.c.free(self.bytes.ptr);
    }

    fn infoOffset(group: c_ushort) usize {
        return 32 + @as(usize, group) * (40 + @sizeOf(usize));
    }

    fn activeProcessorCount(self: WindowsGroups, group: c_ushort) u8 {
        return self.bytes[infoOffset(group) + 1];
    }

    fn activeProcessorMask(self: WindowsGroups, group: c_ushort) usize {
        const offset = infoOffset(group) + 40;
        var value: usize = 0;
        for (self.bytes[offset..][0..@sizeOf(usize)], 0..) |byte, shift| {
            value |= @as(usize, byte) << @intCast(shift * 8);
        }
        return value;
    }
};

fn readWindowsU16(bytes: []const u8, offset: usize) u16 {
    return @as(u16, bytes[offset]) | (@as(u16, bytes[offset + 1]) << 8);
}

fn readWindowsU32(bytes: []const u8, offset: usize) u32 {
    return @as(u32, bytes[offset]) |
        (@as(u32, bytes[offset + 1]) << 8) |
        (@as(u32, bytes[offset + 2]) << 16) |
        (@as(u32, bytes[offset + 3]) << 24);
}

fn windowsGroups() ?WindowsGroups {
    var len: u32 = 0;
    if (GetLogicalProcessorInformationEx(4, null, &len) != 0 or
        GetLastError() != 122 or len < 32)
    {
        return null;
    }
    const raw = std.c.malloc(len) orelse return null;
    var keep = false;
    defer if (!keep) std.c.free(raw);
    const bytes = @as([*]u8, @ptrCast(raw))[0..len];
    if (GetLogicalProcessorInformationEx(4, raw, &len) == 0 or len < 32) return null;

    const record_size = readWindowsU32(bytes, 4);
    if (readWindowsU32(bytes, 0) != 4 or record_size > len or record_size < 32) return null;
    const active_count = readWindowsU16(bytes, 10);
    const need = 32 + @as(usize, active_count) * (40 + @sizeOf(usize));
    if (record_size < need) return null;
    keep = true;
    return .{ .bytes = bytes, .active_count = active_count };
}

pub export var jent_fi_ncpu: c_long = 0;
pub export var jent_fi_fail_affinity: c_int = 0;
pub export var jent_fi_empty_affinity: c_int = 0;
pub export var jent_fi_fail_cpu_alloc: c_int = 0;
pub export var jent_fi_ncpu_sysconf_mode: c_int = 0;

fn countAndHighest(bytes: []const u8, count: *c_long, highest: *c_long) void {
    var total: c_long = 0;
    var last: c_long = -1;
    for (bytes, 0..) |byte, byte_index| {
        total += @popCount(byte);
        if (byte != 0) {
            var bit: usize = 8;
            while (bit > 0) {
                bit -= 1;
                if ((byte & (@as(u8, 1) << @intCast(bit))) != 0) {
                    last = @intCast(byte_index * 8 + bit);
                    break;
                }
            }
        }
    }
    count.* = total;
    highest.* = last;
}

fn affinityMask(count: *c_long, highest: *c_long) c_int {
    if (!linux) return @intCast(negErr(.nosys));
    if (jent_fi_fail_affinity != 0) return @intCast(negErr(.perm));
    if (jent_fi_empty_affinity != 0) {
        count.* = 0;
        highest.* = -1;
        return 0;
    }

    var fixed: CpuSet align(@alignOf(usize)) = @splat(0);
    if (sched_getaffinity(0, fixed.len, &fixed) == 0) {
        countAndHighest(&fixed, count, highest);
        return 0;
    }
    if (errnoPtr().* != errnoValue(.inval)) return -errnoPtr().*;

    var ncpu_set: usize = fixed.len * 8 * 2;
    while (ncpu_set <= internal.JENT_NCPU_SET_MAX) : (ncpu_set *= 2) {
        const size = (ncpu_set + 7) / 8;
        if (jent_fi_fail_cpu_alloc != 0) return @intCast(negErr(.nomem));
        const raw = std.c.malloc(size) orelse return @intCast(negErr(.nomem));
        defer std.c.free(raw);
        const bytes = @as([*]u8, @ptrCast(raw))[0..size];
        @memset(bytes, 0);

        if (sched_getaffinity(0, size, raw) == 0) {
            countAndHighest(bytes, count, highest);
            return 0;
        }
        const err = errnoPtr().*;
        if (err != errnoValue(.inval)) return -err;
    }
    return @intCast(negErr(.inval));
}

fn parseNumber(p: [*:0]const u8, index: *usize) ?c_long {
    var value: c_long = 0;
    var digits: usize = 0;
    const max = std.math.maxInt(c_long);
    while (p[index.*] >= '0' and p[index.*] <= '9') {
        const digit: c_long = @intCast(p[index.*] - '0');
        if (value > @divTrunc(max - digit, 10)) return null;
        value = value * 10 + digit;
        index.* += 1;
        digits += 1;
    }
    return if (digits == 0) null else value;
}

pub export fn jent_parse_cpulist(buf: [*:0]const u8) callconv(.c) c_long {
    var index: usize = 0;
    var count: c_long = 0;

    while (buf[index] != 0 and buf[index] != '\n') {
        const start = parseNumber(buf, &index) orelse return negErr(.inval);
        var end = start;
        if (buf[index] == '-') {
            index += 1;
            end = parseNumber(buf, &index) orelse return negErr(.inval);
            if (end < start) return negErr(.inval);
        }
        if (end >= @as(c_long, internal.JENT_NCPU_SET_MAX)) return negErr(.inval);
        count += end - start + 1;
        if (buf[index] == ',') {
            index += 1;
        } else {
            break;
        }
    }
    return if (count > 0) count else negErr(.inval);
}

fn ncpuSysfsFile(path: [*:0]const u8) c_long {
    if (!use_linux_sysfs) return negErr(.nosys);
    var buf: [256]u8 = undefined;
    const fd = open(path, 0 | 0o2000000);
    if (fd < 0) return -errnoPtr().*;
    defer _ = close(fd);

    var rlen: isize = undefined;
    while (true) {
        rlen = read(fd, &buf, buf.len - 1);
        if (rlen >= 0 or errnoPtr().* != 4) break;
    }
    if (rlen <= 0) return negErr(.io);
    const len: usize = @intCast(rlen);
    buf[len] = 0;
    if (len == buf.len - 1 and buf[len - 1] != '\n') return negErr(.inval);
    return jent_parse_cpulist(@ptrCast(&buf));
}

fn sysconfNcpu() c_long {
    switch (jent_fi_ncpu_sysconf_mode) {
        1 => return negErr(.inval),
        2 => return negErr(.fault),
        3 => return 1 << 20,
        else => {},
    }

    errnoPtr().* = 0;
    const result = sysconf(sysconfNprocessorsOnln());
    if (result == -1) {
        const err = errnoPtr().*;
        return if (err != 0) -err else negErr(.fault);
    }
    if (result == 0) return negErr(.fault);
    return result;
}

fn windowsNcpu() c_long {
    var affinity: GroupAffinity = std.mem.zeroes(GroupAffinity);
    if (GetThreadGroupAffinity(GetCurrentThread(), &affinity) != 0) {
        if (windowsGroups()) |groups| {
            defer groups.deinit();
            if (affinity.Group < groups.active_count) {
                const mask = affinity.Mask & groups.activeProcessorMask(affinity.Group);
                const count: c_long = @intCast(@popCount(mask));
                if (count > 0) return count;
            }
        }
    }
    const count = GetActiveProcessorCount(0xffff);
    return if (count != 0) @intCast(count) else negErr(.fault);
}

pub export fn jent_fi_real_ncpu() callconv(.c) c_long {
    if (is_linux_kernel) return jent_kshim_num_online_cpus();
    if (!hosted) return negErr(.nodev);
    if (windows) return windowsNcpu();
    if (linux) {
        var count: c_long = 0;
        var highest: c_long = -1;
        if (affinityMask(&count, &highest) == 0 and count > 0) return count;
        if (use_linux_sysfs and jent_fi_ncpu_sysconf_mode == 0) {
            const sysfs = ncpuSysfsFile("/sys/devices/system/cpu/online");
            if (sysfs > 0) return sysfs;
        }
    }
    if (posix) return sysconfNcpu();
    return negErr(.nodev);
}

pub export fn jent_ncpu() callconv(.c) c_long {
    if (jent_fi_ncpu != 0) return jent_fi_ncpu;
    return jent_fi_real_ncpu();
}

pub export fn jent_cpu_highest() callconv(.c) c_long {
    if (is_linux_kernel) {
        const count = jent_kshim_num_online_cpus();
        return if (count > 0) count - 1 else count;
    }
    if (linux) {
        var count: c_long = 0;
        var highest: c_long = -1;
        if (affinityMask(&count, &highest) == 0 and highest >= 0) return highest;
    } else if (windows) {
        var affinity: GroupAffinity = std.mem.zeroes(GroupAffinity);
        if (GetThreadGroupAffinity(GetCurrentThread(), &affinity) != 0 and affinity.Mask != 0) {
            if (windowsGroups()) |groups| {
                defer groups.deinit();
                if (affinity.Group < groups.active_count) {
                    const active = groups.activeProcessorMask(affinity.Group);
                    const mask = affinity.Mask & active;
                    var bit: usize = @bitSizeOf(usize);
                    while (bit > 0) {
                        bit -= 1;
                        const selected = @as(usize, 1) << @intCast(bit);
                        if ((mask & selected) != 0) {
                            var base: c_long = 0;
                            var group: c_ushort = 0;
                            while (group < affinity.Group) : (group += 1) {
                                base += groups.activeProcessorCount(group);
                            }
                            const below = if (bit == 0) 0 else active & (selected - 1);
                            return base + @as(c_long, @intCast(@popCount(below)));
                        }
                    }
                }
            }
        }
    }

    const count = jent_ncpu();
    if (count < 0) return count;
    if (count == 0) return negErr(.fault);
    return count - 1;
}

pub export fn jent_cpu_to_group(cpu_arg: c_ulong, group: *c_ushort, bit: *c_uint) callconv(.c) c_int {
    if (!windows) return @intCast(negErr(.nosys));
    const groups = windowsGroups() orelse return @intCast(negErr(.fault));
    defer groups.deinit();
    var cpu = cpu_arg;
    var current: c_ushort = 0;
    while (current < groups.active_count) : (current += 1) {
        const count: c_ulong = groups.activeProcessorCount(current);
        if (cpu < count) {
            const mask = groups.activeProcessorMask(current);
            var current_bit: c_uint = 0;
            var seen: c_ulong = 0;
            while (current_bit < @bitSizeOf(usize)) : (current_bit += 1) {
                if ((mask & (@as(usize, 1) << @intCast(current_bit))) == 0) continue;
                if (seen == cpu) {
                    group.* = current;
                    bit.* = current_bit;
                    return 0;
                }
                seen += 1;
            }
            return @intCast(negErr(.fault));
        }
        cpu -= count;
    }
    return @intCast(negErr(.inval));
}
