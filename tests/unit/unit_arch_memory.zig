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

const Handle = ?*anyopaque;
const StartupInfoW = extern struct {
    size: u32,
    reserved: ?[*:0]u16,
    desktop: ?[*:0]u16,
    title: ?[*:0]u16,
    x: u32,
    y: u32,
    x_size: u32,
    y_size: u32,
    x_count_chars: u32,
    y_count_chars: u32,
    fill_attribute: u32,
    flags: u32,
    show_window: u16,
    reserved2_size: u16,
    reserved2: ?[*]u8,
    std_input: Handle,
    std_output: Handle,
    std_error: Handle,
};
const ProcessInformation = extern struct {
    process: Handle,
    thread: Handle,
    process_id: u32,
    thread_id: u32,
};

extern "kernel32" fn GetModuleFileNameW(
    module: Handle,
    filename: [*]u16,
    size: u32,
) callconv(.winapi) u32;
extern "kernel32" fn GetCommandLineW() callconv(.winapi) [*:0]const u16;
extern "kernel32" fn CreateProcessW(
    application_name: ?[*:0]const u16,
    command_line: [*:0]u16,
    process_attributes: ?*anyopaque,
    thread_attributes: ?*anyopaque,
    inherit_handles: i32,
    creation_flags: u32,
    environment: ?*anyopaque,
    current_directory: ?[*:0]const u16,
    startup_info: *StartupInfoW,
    process_information: *ProcessInformation,
) callconv(.winapi) i32;
extern "kernel32" fn WaitForSingleObject(handle: Handle, milliseconds: u32) callconv(.winapi) u32;
extern "kernel32" fn GetExitCodeProcess(handle: Handle, exit_code: *u32) callconv(.winapi) i32;
extern "kernel32" fn CloseHandle(handle: Handle) callconv(.winapi) i32;

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

fn windowsFaultChild(trailing: bool) noreturn {
    const page_size = jent_pagesize();
    const raw = jent_zalloc(page_size, 0) orelse std.process.exit(2);
    const payload: [*]volatile u8 = @ptrCast(raw);
    const address = if (trailing) payload + page_size else payload - 1;
    _ = address[0];
    jent_zfree(raw, page_size);
    std.process.exit(0);
}

fn windowsGuardFault(argument: []const u8) ?bool {
    var executable: [32768]u16 = undefined;
    const executable_len = GetModuleFileNameW(null, &executable, executable.len);
    if (executable_len == 0 or executable_len >= executable.len) return null;
    executable[executable_len] = 0;

    var command_line: [32768]u16 = undefined;
    var used: usize = 0;
    command_line[used] = '"';
    used += 1;
    @memcpy(command_line[used..][0..executable_len], executable[0..executable_len]);
    used += executable_len;
    command_line[used] = '"';
    used += 1;
    command_line[used] = ' ';
    used += 1;
    for (argument) |byte| {
        command_line[used] = byte;
        used += 1;
    }

    command_line[used] = 0;

    var startup: StartupInfoW = std.mem.zeroes(StartupInfoW);
    startup.size = @sizeOf(StartupInfoW);
    var process: ProcessInformation = undefined;
    if (CreateProcessW(
        @ptrCast(&executable),
        @ptrCast(&command_line),
        null,
        null,
        0,
        0,
        null,
        null,
        &startup,
        &process,
    ) == 0) return null;
    defer _ = CloseHandle(process.thread);
    defer _ = CloseHandle(process.process);

    if (WaitForSingleObject(process.process, std.math.maxInt(u32)) != 0) return null;
    var exit_code: u32 = 0;
    if (GetExitCodeProcess(process.process, &exit_code) == 0) return null;
    return exit_code == 0xc0000005;
}

fn windowsCommandLineContains(needle: []const u8) bool {
    const command_line = std.mem.span(GetCommandLineW());
    if (needle.len > command_line.len) return false;
    var start: usize = 0;
    while (start + needle.len <= command_line.len) : (start += 1) {
        var equal = true;
        for (needle, 0..) |byte, index| {
            if (command_line[start + index] != byte) {
                equal = false;
                break;
            }
        }
        if (equal) return true;
    }
    return false;
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
        jent_memory_is_secure(internal.JENT_FORCE_SECURE_MEM) == 1,
        "the memory is secure memory",
    );
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
        const below = windowsGuardFault("--fault-leading");
        const above = windowsGuardFault("--fault-trailing");
        if (below == null or above == null) {
            harness.skipOrExit(@src(), "the guard pages: no child process to fault in", .{});
        } else {
            check(below.?, "the page below the payload faults");
            check(above.?, "the page above the payload faults");
        }
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
    if (builtin.os.tag == .windows) {
        if (windowsCommandLineContains("--fault-leading")) windowsFaultChild(false);
        if (windowsCommandLineContains("--fault-trailing")) windowsFaultChild(true);
    }

    harness.resetCounters();
    testMemory();
    testGuardPages();
    harness.pass("unit-arch-memory");
}
