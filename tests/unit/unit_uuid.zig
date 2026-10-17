const std = @import("std");
const builtin = @import("builtin");
const jent = @import("jent");

var checks: usize = 0;
var failures: usize = 0;

extern fn jent_random_read_file(path_arg: [*:0]const u8, buffer: [*]u8, len: usize) callconv(.c) c_int;
extern fn jent_random_dev_urandom(buffer: [*]u8, len: usize) callconv(.c) c_int;
extern fn fopen(path: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn fwrite(data: [*]const u8, size: usize, count: usize, stream: *anyopaque) callconv(.c) usize;
extern fn fclose(stream: *anyopaque) callconv(.c) c_int;
extern fn remove(path: [*:0]const u8) callconv(.c) c_int;

fn expect(condition: bool, comptime message: []const u8) void {
    checks += 1;
    if (!condition) {
        failures += 1;
        std.debug.print("  FAILED: {s}\n", .{message});
    }
}

fn uuidSlice(uuid: *const [jent.JENT_UUID_STRLEN]u8) []const u8 {
    return uuid[0 .. jent.JENT_UUID_STRLEN - 1];
}

fn testGenerate() void {
    var a: [jent.JENT_UUID_STRLEN]u8 = undefined;
    var b: [jent.JENT_UUID_STRLEN]u8 = undefined;
    var probe: [16]u8 = undefined;
    const before = jent.jent_os_random_bytes(&probe, probe.len) == 0;
    jent.jent_uuid_generate(&a);
    const after = jent.jent_os_random_bytes(&probe, probe.len) == 0;
    jent.jent_uuid_generate(&b);

    expect(a[jent.JENT_UUID_STRLEN - 1] == 0, "UUID is NUL terminated");
    for (uuidSlice(&a), 0..) |character, i| {
        const valid = if (i == 8 or i == 13 or i == 18 or i == 23)
            character == '-'
        else
            std.ascii.isDigit(character) or (character >= 'a' and character <= 'f');
        if (!valid) {
            expect(false, "UUID has canonical lowercase hexadecimal form");
            break;
        }
    } else expect(true, "UUID has canonical lowercase hexadecimal form");

    expect(!std.mem.eql(u8, uuidSlice(&a), "00000000-0000-0000-0000-000000000000"), "UUID is not nil");
    if (jent.jent_os_random_supported() == 0) {
        expect(a[14] == '8', "fallback UUID is version 8");
    } else if (before and after) {
        expect(a[14] == '4', "CSPRNG UUID is version 4");
    } else if (!before and !after) {
        expect(a[14] == '8', "failed CSPRNG UUID is version 8");
    } else {
        expect(a[14] == '4' or a[14] == '8', "UUID version reflects available source");
    }
    expect(a[19] == '8' or a[19] == '9' or a[19] == 'a' or a[19] == 'b', "UUID has RFC variant");
    expect(!std.mem.eql(u8, uuidSlice(&a), uuidSlice(&b)), "consecutive UUIDs differ");
}

fn testCounterAndFormat() void {
    var a: [16]u8 = undefined;
    var b: [16]u8 = undefined;
    jent.jent_uuid_from_counter(&a);
    jent.jent_uuid_from_counter(&b);
    expect(!std.mem.eql(u8, &a, &b), "counter-derived UUIDs differ");
    expect(a[6] >> 4 == 8, "counter-derived UUID is version 8");

    for (&a, 0..) |*byte, i| byte.* = @truncate(i * 0x11);
    var output: [jent.JENT_UUID_STRLEN]u8 = undefined;
    jent.jent_uuid_format(&a, &output);
    expect(std.mem.eql(u8, uuidSlice(&output), "00112233-4455-6677-8899-aabbccddeeff"), "UUID formatting vector");
}

fn testRandomFileBackend() void {
    if (builtin.os.tag != .linux) return;
    const path: [:0]const u8 = ".zig-cache/unit-uuid-random-source";
    const absent: [:0]const u8 = ".zig-cache/unit-uuid-does-not-exist";
    const directory: [:0]const u8 = ".";
    var buffer: [16]u8 = undefined;
    @memset(&buffer, 0);
    const urandom_result = jent_random_dev_urandom(&buffer, buffer.len);
    expect(urandom_result != 0 or !std.mem.allEqual(u8, &buffer, 0), "/dev/urandom returns data or an error");

    expect(jent_random_read_file(absent, &buffer, buffer.len) != 0, "absent random source fails");
    expect(jent_random_read_file(directory, &buffer, buffer.len) != 0, "unreadable random source fails");

    defer _ = remove(path);
    {
        const file = fopen(path, "wb") orelse {
            expect(false, "create random source fixture");
            return;
        };
        _ = fclose(file);
    }
    expect(jent_random_read_file(path, &buffer, buffer.len) != 0, "empty random source fails");

    {
        const file = fopen(path, "wb") orelse unreachable;
        _ = fwrite("12345", 1, 5, file);
        _ = fclose(file);
    }
    expect(jent_random_read_file(path, &buffer, buffer.len) != 0, "short random source fails");

    {
        const file = fopen(path, "wb") orelse unreachable;
        var data: [64]u8 = undefined;
        for (&data, 0..) |*byte, i| byte.* = @truncate(i + 1);
        _ = fwrite(&data, 1, data.len, file);
        _ = fclose(file);
    }
    @memset(&buffer, 0);
    expect(jent_random_read_file(path, &buffer, buffer.len) == 0, "full random source succeeds");
    expect(buffer[0] == 1 and buffer[15] == 16, "random source fills requested bytes");
}

pub fn main() u8 {
    testGenerate();
    testCounterAndFormat();
    testRandomFileBackend();
    std.debug.print("unit-uuid: {d} checks, {d} failed\n", .{ checks, failures });
    return if (failures == 0) 0 else 1;
}
