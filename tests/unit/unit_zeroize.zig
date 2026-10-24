// SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0-only

const std = @import("std");
const harness = @import("test_harness");
const internal = @import("jent_internal");

const InspectHook = *const fn (?*const anyopaque, usize) callconv(.c) void;

extern var jent_zeroize_inspect_hook: ?InspectHook;
extern fn jent_zalloc(len: usize, flags: c_uint) callconv(.c) ?*anyopaque;
extern fn jent_zfree(ptr: ?*anyopaque, len: usize) callconv(.c) void;
extern fn jent_memset_secure(ptr: ?*anyopaque, len: usize) callconv(.c) void;

var watched_ptr: ?*const anyopaque = null;
var watched_len: usize = 0;
var releases: usize = 0;
var dirty: usize = 0;

fn inspect(base: ?*const anyopaque, size: usize) callconv(.c) void {
    const watched = watched_ptr orelse return;
    const actual = base orelse return;
    if (actual != watched or size < watched_len) return;
    releases += 1;
    const bytes: [*]const u8 = @ptrCast(actual);
    for (bytes[0..watched_len]) |byte| {
        if (byte != 0) dirty += 1;
    }
}

fn arm(ptr: *const anyopaque, len: usize) void {
    watched_ptr = ptr;
    watched_len = len;
    releases = 0;
    dirty = 0;
    jent_zeroize_inspect_hook = inspect;
}

fn disarm() void {
    jent_zeroize_inspect_hook = null;
    watched_ptr = null;
    watched_len = 0;
}

fn fail(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print("FAIL: " ++ fmt ++ "\n", args);
    std.process.exit(1);
}

fn check(condition: bool, comptime message: []const u8) void {
    harness.expect(condition, @src(), "{s}", .{message}) catch
        fail("{s}", .{message});
}

fn checkRelease(name: []const u8) void {
    if (releases == 0) fail("{s}: the release was not seen", .{name});
    if (dirty != 0) fail("{s}: {d} bytes survived the wipe", .{ name, dirty });
    check(true, "the watched allocation was wiped before release");
}

fn testZfreeWipes() void {
    const Mode = struct { flags: c_uint, name: []const u8 };
    const modes = [_]Mode{
        .{ .flags = 0, .name = "ordinary memory is wiped on release" },
        .{
            .flags = internal.JENT_FORCE_SECURE_MEM,
            .name = "secure memory is wiped on release",
        },
    };

    for (modes) |mode| {
        const len = 4096;
        const raw = jent_zalloc(len, mode.flags);
        if (raw == null) {
            harness.skipOrExit(@src(), "{s}: allocation failed", .{mode.name});
            continue;
        }
        const bytes: [*]u8 = @ptrCast(raw.?);
        @memset(bytes[0..len], 0x5a);
        arm(raw.?, len);
        jent_zfree(raw, len);
        disarm();
        check(releases != 0, "the release hook was invoked");
        check(dirty == 0, "jent_zfree wiped every byte");
    }
}

fn testCollectorStateWiped() void {
    if (internal.jent_entropy_init() != 0) {
        harness.skipOrExit(@src(), "the collector startup does not pass on this machine", .{});
        return;
    }

    var part: usize = 0;
    while (part < 2) : (part += 1) {
        const collector = internal.jent_entropy_collector_alloc(0, 0);
        if (collector == null) {
            harness.skipOrExit(@src(), "no collector", .{});
            continue;
        }

        var output: [64]u8 = undefined;
        if (internal.jent_read_entropy(collector, &output, output.len) != output.len) {
            internal.jent_entropy_collector_free(collector);
            harness.skipOrExit(@src(), "no entropy generated", .{});
            continue;
        }

        const ec = collector.?;
        const pointer: ?*const anyopaque = if (part == 0)
            if (ec.mem) |mem| @ptrCast(mem) else null
        else
            ec;
        const len: usize = if (part == 0) @as(usize, ec.memmask) + 1 else @sizeOf(internal.rand_data);
        const name = if (part == 0)
            "the entropy pool is wiped on free"
        else
            "the collector state is wiped on free";

        if (pointer == null) {
            internal.jent_entropy_collector_free(collector);
            harness.skipOrExit(@src(), "{s}: this collector has no memory pool", .{name});
            continue;
        }

        const before = std.heap.c_allocator.alloc(u8, len) catch {
            internal.jent_entropy_collector_free(collector);
            harness.skipOrExit(@src(), "{s}: out of memory", .{name});
            continue;
        };
        const state: [*]const u8 = @ptrCast(pointer.?);
        @memcpy(before, state[0..len]);

        arm(pointer.?, len);
        internal.jent_entropy_collector_free(collector);
        disarm();

        var had_data = false;
        for (before) |byte| {
            if (byte != 0) {
                had_data = true;
                break;
            }
        }
        if (!had_data) std.debug.print("  note: {s} held nothing before release\n", .{name});
        checkRelease(name);
        jent_memset_secure(before.ptr, before.len);
        std.heap.c_allocator.free(before);
    }
}

pub fn main() void {
    harness.resetCounters();
    harness.raiseMemlockLimit();
    testZfreeWipes();
    testCollectorStateWiped();
    harness.pass("unit-zeroize");
}
