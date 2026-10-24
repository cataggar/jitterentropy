// SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0-only

const std = @import("std");
const builtin = @import("builtin");
const harness = @import("test_harness");
const internal = @import("jent_internal");

extern fn jent_pagesize() callconv(.c) usize;
extern fn jent_zalloc(len: usize, flags: c_uint) callconv(.c) ?*anyopaque;
extern fn jent_zalloc_unlocked(len: usize) callconv(.c) ?*anyopaque;
extern fn jent_zfree(ptr: ?*anyopaque, len: usize) callconv(.c) void;
extern fn jent_memset_secure(ptr: ?*anyopaque, len: usize) callconv(.c) void;
extern fn jent_memory_is_secure(flags: c_uint) callconv(.c) c_int;
extern fn jent_secure_memory_supported() callconv(.c) c_int;

extern fn fork() c_int;
extern fn waitpid(pid: c_int, status: *c_int, options: c_int) c_int;
extern fn setrlimit(resource: c_int, limits: *const RLimit) c_int;
extern fn signal(
    signal_number: c_int,
    handler: ?*const fn (c_int) callconv(.c) void,
) ?*const fn (c_int) callconv(.c) void;
extern fn _exit(status: c_int) noreturn;

const RLimit = extern struct {
    current: usize,
    maximum: usize,
};

const PAGE_NOACCESS: u32 = 0x01;
const MemoryBasicInformation = extern struct {
    base_address: ?*anyopaque,
    allocation_base: ?*anyopaque,
    allocation_protect: u32,
    region_size: usize,
    state: u32,
    protect: u32,
    memory_type: u32,
};

extern "kernel32" fn VirtualQuery(
    address: ?*const anyopaque,
    buffer: *MemoryBasicInformation,
    length: usize,
) callconv(.winapi) usize;

fn fail(comptime fmt: []const u8, args: anytype) noreturn {
    std.debug.print("FAIL: " ++ fmt ++ "\n", args);
    std.process.exit(1);
}

fn check(condition: bool, comptime message: []const u8) void {
    harness.expect(condition, @src(), "{s}", .{message}) catch
        fail("{s}", .{message});
}

fn readInChild(address: *volatile u8) ?bool {
    const pid = fork();
    if (pid < 0) return null;
    if (pid == 0) {
        const no_core = RLimit{ .current = 0, .maximum = 0 };
        _ = setrlimit(4, &no_core);
        _ = signal(11, null);
        _ = signal(if (builtin.os.tag == .linux) 7 else 10, null);
        _ = address.*;
        _exit(0);
    }

    var status: c_int = 0;
    if (waitpid(pid, &status, 0) != pid) return null;
    return !((status & 0x7f) == 0 and ((status >> 8) & 0xff) == 0);
}

fn testMemory() void {
    const Mode = struct {
        unlocked: bool,
        flags: c_uint,
        name: []const u8,
    };
    const modes = [_]Mode{
        .{ .unlocked = false, .flags = 0, .name = "ordinary memory" },
        .{ .unlocked = false, .flags = internal.JENT_FORCE_SECURE_MEM, .name = "secure memory" },
        .{ .unlocked = true, .flags = 0, .name = "unlocked memory" },
    };

    for (modes) |mode| {
        const len = 4096;
        const raw = if (mode.unlocked)
            jent_zalloc_unlocked(len)
        else
            jent_zalloc(len, mode.flags);
        if (raw == null) {
            if (mode.flags != 0) {
                harness.skipOrExit(@src(), "{s}: allocation failed", .{mode.name});
            } else {
                fail("{s}: allocation failed", .{mode.name});
            }
            continue;
        }

        const bytes: [*]u8 = @ptrCast(raw.?);
        check(std.mem.allEqual(u8, bytes[0..len], 0), "the allocation is zeroed");
        @memset(bytes[0..len], 0x5a);
        check(bytes[0] == 0x5a, "the first byte is writable");
        check(bytes[len - 1] == 0x5a, "the last byte is writable");
        jent_memset_secure(raw, len);
        check(std.mem.allEqual(u8, bytes[0..len], 0), "jent_memset_secure clears the buffer");
        jent_zfree(raw, len);
    }

    jent_zfree(null, 4096);
    var byte: u8 = 0x5a;
    jent_memset_secure(&byte, 0);
    check(byte == 0x5a, "a zero-length wipe writes nothing");

    check(
        jent_secure_memory_supported() == 1,
        "secure memory support is reported on supported host platforms",
    );
    check(
        jent_memory_is_secure(internal.JENT_FORCE_SECURE_MEM) == 1,
        "the memory is secure memory",
    );
    const unforced_secure = jent_memory_is_secure(0);
    check(
        unforced_secure == 0 or unforced_secure == 1,
        "jent_memory_is_secure(0) returns a boolean flag",
    );

    const page_size = jent_pagesize();
    for ([_]usize{ 1, 64, page_size + 7 }) |unaligned_len| {
        const ptr_raw = jent_zalloc(unaligned_len, 0) orelse {
            fail("unaligned allocation ({d} bytes) failed", .{unaligned_len});
            continue;
        };
        defer jent_zfree(ptr_raw, unaligned_len);
        const bytes = @as([*]u8, @ptrCast(ptr_raw))[0..unaligned_len];
        var any_nonzero = false;
        for (bytes) |b| {
            if (b != 0) any_nonzero = true;
        }
        check(!any_nonzero, "page-rounded allocation is zero-initialized");
        @memset(bytes, 0x3c);
        check(bytes[0] == 0x3c and bytes[unaligned_len - 1] == 0x3c, "page-rounded allocation is writable across its length");
    }
}

fn testGuardPages() void {
    const guarded = internal.build_options.external_crypto == .none and
        (builtin.os.tag == .windows or switch (builtin.os.tag) {
            .linux, .macos, .freebsd, .netbsd, .openbsd, .dragonfly => true,
            else => false,
        });
    if (!guarded) {
        harness.skipOrExit(@src(), "the guard pages: this backend places none", .{});
        return;
    }

    const page_size = jent_pagesize();
    const raw = jent_zalloc(page_size, 0) orelse fail("guard-page allocation failed", .{});
    const payload: [*]u8 = @ptrCast(raw);
    check(@intFromPtr(payload) % page_size == 0, "the payload starts on a page boundary");

    if (builtin.os.tag == .windows) {
        var mbi: MemoryBasicInformation = std.mem.zeroes(MemoryBasicInformation);
        check(
            VirtualQuery(payload - page_size, &mbi, @sizeOf(MemoryBasicInformation)) == @sizeOf(MemoryBasicInformation) and
                mbi.protect == PAGE_NOACCESS,
            "the page below the payload is PAGE_NOACCESS",
        );
        mbi = std.mem.zeroes(MemoryBasicInformation);
        check(
            VirtualQuery(payload + page_size, &mbi, @sizeOf(MemoryBasicInformation)) == @sizeOf(MemoryBasicInformation) and
                mbi.protect == PAGE_NOACCESS,
            "the page above the payload is PAGE_NOACCESS",
        );
    } else {
        const readable = readInChild(@ptrCast(payload));
        const below = readInChild(@ptrCast(payload - 1));
        const above = readInChild(@ptrCast(payload + page_size));
        if (readable == null or below == null or above == null) {
            harness.skipOrExit(@src(), "the guard pages: no child process to fault in", .{});
        } else {
            check(!readable.?, "the payload is readable");
            check(below.?, "the page below the payload faults");
            check(above.?, "the page above the payload faults");
        }
    }

    @memset(payload[0..page_size], 0x5a);
    check(payload[0] == 0x5a, "the first byte of the payload is writable");
    check(payload[page_size - 1] == 0x5a, "the last byte of the payload is writable");
    jent_zfree(raw, page_size);
}

pub fn main() void {
    harness.resetCounters();
    testMemory();
    testGuardPages();
    harness.pass("unit-arch-memory");
}
