const std = @import("std");
const fuzz = @import("fuzz_health");

const FILE = opaque {};
extern fn printf(format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn fopen(path: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*FILE;
extern fn fclose(stream: *FILE) callconv(.c) c_int;
extern fn fread(buffer: [*]u8, size: usize, count: usize, stream: *FILE) callconv(.c) usize;

fn runFile(path: [:0]const u8) c_int {
    var buffer: [65536]u8 = undefined;
    const optional_file = fopen(path.ptr, "rb");
    if (optional_file == null) {
        _ = printf("fuzz-health: cannot open %s\n", path.ptr);
        return 1;
    }
    const file = optional_file.?;
    const length = fread(&buffer, 1, buffer.len, file);
    _ = fclose(file);
    _ = fuzz.LLVMFuzzerTestOneInput(&buffer, length);
    _ = printf("fuzz-health: %s (%zu bytes) survived\n", path.ptr, length);
    return 0;
}

pub fn main(init_context: std.process.Init.Minimal) u8 {
    var args = std.process.Args.Iterator.initAllocator(init_context.args, std.heap.c_allocator) catch return 1;
    defer args.deinit();
    _ = args.next();
    var result: c_int = 0;
    var had_file = false;
    while (args.next()) |path| {
        had_file = true;
        result |= runFile(path);
    }
    if (had_file) return @intCast(result);

    var input: [2048]u8 = undefined;
    for (0..64) |i| {
        var x: u64 = 0x9e3779b97f4a7c15 *% (i + 1);
        for (&input) |*byte| {
            x ^= x >> 30;
            x *%= 0xbf58476d1ce4e5b9;
            x ^= x >> 27;
            byte.* = @truncate(x >> 24);
        }
        _ = fuzz.LLVMFuzzerTestOneInput(&input, input.len);
    }
    _ = printf("fuzz-health: %u inputs survived\n", @as(c_uint, 64));
    return 0;
}
