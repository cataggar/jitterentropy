// SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0-only

const internal = @import("../internal.zig");

fn pointerToInt(ptr: ?*anyopaque) usize {
    return if (ptr) |value| @intFromPtr(value) else 0;
}

fn intToPointer(value: usize) ?*anyopaque {
    return if (value == 0) null else @ptrFromInt(value);
}

export fn jent_atomic_load_int(ptr: *const c_int) callconv(.c) c_int {
    return @atomicLoad(c_int, ptr, .seq_cst);
}

export fn jent_atomic_store_int(ptr: *c_int, val: c_int) callconv(.c) void {
    @atomicStore(c_int, ptr, val, .seq_cst);
}

export fn jent_atomic_exchange_int(ptr: *c_int, val: c_int) callconv(.c) c_int {
    return @atomicRmw(c_int, ptr, .Xchg, val, .seq_cst);
}

export fn jent_atomic_load_u32(ptr: *const u32) callconv(.c) u32 {
    return @atomicLoad(u32, ptr, .seq_cst);
}

export fn jent_atomic_inc_u32(ptr: *u32) callconv(.c) u32 {
    return @atomicRmw(u32, ptr, .Add, 1, .seq_cst) +% 1;
}

export fn jent_atomic_cmpxchg_u32(ptr: *u32, old: u32, val: u32) callconv(.c) u32 {
    return @cmpxchgStrong(u32, ptr, old, val, .seq_cst, .seq_cst) orelse old;
}

export fn jent_atomic_store_u32(ptr: *u32, val: u32) callconv(.c) void {
    @atomicStore(u32, ptr, val, .seq_cst);
}

export fn jent_atomic_load_u64(ptr: *const u64) callconv(.c) u64 {
    return @atomicLoad(u64, ptr, .seq_cst);
}

export fn jent_atomic_store_u64(ptr: *u64, val: u64) callconv(.c) void {
    @atomicStore(u64, ptr, val, .seq_cst);
}

export fn jent_atomic_load_ptr(ptr: *const ?*anyopaque) callconv(.c) ?*anyopaque {
    const atomic_ptr: *const usize = @ptrCast(ptr);
    return intToPointer(@atomicLoad(usize, atomic_ptr, .seq_cst));
}

export fn jent_atomic_store_ptr(ptr: *?*anyopaque, val: ?*anyopaque) callconv(.c) void {
    const atomic_ptr: *usize = @ptrCast(ptr);
    @atomicStore(usize, atomic_ptr, pointerToInt(val), .seq_cst);
}

export fn jent_atomic_cas_ptr(
    ptr: *?*anyopaque,
    old: ?*anyopaque,
    val: ?*anyopaque,
) callconv(.c) ?*anyopaque {
    const atomic_ptr: *usize = @ptrCast(ptr);
    const old_int = pointerToInt(old);
    const observed = @cmpxchgStrong(
        usize,
        atomic_ptr,
        old_int,
        pointerToInt(val),
        .seq_cst,
        .seq_cst,
    ) orelse old_int;
    return intToPointer(observed);
}

export fn jent_atomic_load_fips_cb(
    ptr: *const internal.jent_fips_failure_cb,
) callconv(.c) internal.jent_fips_failure_cb {
    const atomic_ptr: *const usize = @ptrCast(ptr);
    const value = @atomicLoad(usize, atomic_ptr, .seq_cst);
    return if (value == 0) null else @ptrFromInt(value);
}

export fn jent_atomic_store_fips_cb(
    ptr: *internal.jent_fips_failure_cb,
    val: internal.jent_fips_failure_cb,
) callconv(.c) void {
    const atomic_ptr: *usize = @ptrCast(ptr);
    const value = if (val) |callback| @intFromPtr(callback) else 0;
    @atomicStore(usize, atomic_ptr, value, .seq_cst);
}

test "integer atomics" {
    const testing = @import("std").testing;

    var int_value: c_int = 1;
    try testing.expectEqual(@as(c_int, 1), jent_atomic_load_int(&int_value));
    jent_atomic_store_int(&int_value, 2);
    try testing.expectEqual(@as(c_int, 2), jent_atomic_exchange_int(&int_value, 3));
    try testing.expectEqual(@as(c_int, 3), int_value);

    var u32_value: u32 = 4;
    try testing.expectEqual(@as(u32, 5), jent_atomic_inc_u32(&u32_value));
    try testing.expectEqual(@as(u32, 5), jent_atomic_cmpxchg_u32(&u32_value, 5, 6));
    try testing.expectEqual(@as(u32, 6), u32_value);
    try testing.expectEqual(@as(u32, 6), jent_atomic_cmpxchg_u32(&u32_value, 5, 7));

    var u64_value: u64 = 8;
    jent_atomic_store_u64(&u64_value, 9);
    try testing.expectEqual(@as(u64, 9), jent_atomic_load_u64(&u64_value));
}

test "pointer atomics preserve null and compare-and-swap semantics" {
    const testing = @import("std").testing;

    var first: u8 = 1;
    var second: u8 = 2;
    var value: ?*anyopaque = null;

    try testing.expectEqual(@as(?*anyopaque, null), jent_atomic_load_ptr(&value));
    jent_atomic_store_ptr(&value, &first);
    try testing.expectEqual(@as(?*anyopaque, &first), jent_atomic_load_ptr(&value));
    try testing.expectEqual(
        @as(?*anyopaque, &first),
        jent_atomic_cas_ptr(&value, &first, &second),
    );
    try testing.expectEqual(@as(?*anyopaque, &second), value);
}
