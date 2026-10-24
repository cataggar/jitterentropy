// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const std = @import("std");
const kmod = @import("kmod_core");

const EINVAL: isize = 22;
const ENOMEM: isize = 12;
const EFAULT: isize = 14;
const EOVERFLOW: isize = 75;
const JENT_STATUS_MAX_LEN: usize = 4096;

const StatusIoctl = extern struct {
    buf: u64,
    length: u32,
};

var dummy_file: u8 = 0;
var dummy_ctx: u8 = 0;
var dummy_lock: u8 = 0;
var dummy_ec_storage: u8 = 0;
var dummy_ec: ?*anyopaque = @ptrCast(&dummy_ec_storage);
var dummy_selftest: u8 = 0;
var dummy_seq: u8 = 0;
var dummy_hwrng: u8 = 0;
var dummy_record_storage: u8 = 0;
var dummy_record: ?*anyopaque = @ptrCast(&dummy_record_storage);

var mock_nonblock: bool = false;
var mock_fail_kvzalloc: bool = false;
var mock_kvzalloc_calls: usize = 0;
var mock_kvfree_calls: usize = 0;
var mock_mutex_lock_interruptible_calls: usize = 0;
var mock_mutex_trylock_calls: usize = 0;
var mock_mutex_unlock_calls: usize = 0;
var mock_copy_to_user_calls: usize = 0;
var mock_read_entropy_calls: usize = 0;
var mock_read_entropy_safe_calls: usize = 0;
var mock_last_chunk_sizes: [16]usize = @splat(0);
var mock_chunk_count: usize = 0;
var mock_memzero_last_len: usize = 0;
var mock_testing_loop_count: u64 = 0;
var mock_last_primed_loop_count: u32 = 0;
var mock_last_sampled_loop_count: u32 = 0;
var mock_kvzalloc_buf: [8192]u8 align(8) = @splat(0);

fn resetMocks() void {
    mock_nonblock = false;
    mock_fail_kvzalloc = false;
    mock_kvzalloc_calls = 0;
    mock_kvfree_calls = 0;
    mock_mutex_lock_interruptible_calls = 0;
    mock_mutex_trylock_calls = 0;
    mock_mutex_unlock_calls = 0;
    mock_copy_to_user_calls = 0;
    mock_read_entropy_calls = 0;
    mock_read_entropy_safe_calls = 0;
    mock_last_chunk_sizes = @splat(0);
    mock_chunk_count = 0;
    mock_memzero_last_len = 0;
    mock_testing_loop_count = 0;
    mock_last_primed_loop_count = 0;
    mock_last_sampled_loop_count = 0;
    @memset(&mock_kvzalloc_buf, 0);
    dummy_ec = @ptrCast(&dummy_ec_storage);
    dummy_record = @ptrCast(&dummy_record_storage);
}

export fn jent_version() callconv(.c) u32 {
    return 0x03060000;
}

export fn jent_entropy_init_ex(_: u32, _: u32) callconv(.c) c_int {
    return 0;
}

export fn jent_set_fips_failure_callback(_: ?*const fn (?*anyopaque, c_int) callconv(.c) void) callconv(.c) c_int {
    return 0;
}

export fn jent_selftest(_: ?*anyopaque) callconv(.c) c_int {
    return 0;
}

export fn jent_status(ec: ?*const anyopaque, buf: ?[*]u8, len: usize) callconv(.c) c_int {
    if (ec == null) return -1;
    const out = buf orelse return -1;
    const sample = "ok: jitterentropy status\n";
    if (len <= sample.len) return -1;
    @memcpy(out[0..sample.len], sample);
    out[sample.len] = 0;
    return 0;
}

export fn jent_entropy_collector_uuid(_: ?*const anyopaque, buf: ?[*]u8, len: usize) callconv(.c) c_int {
    if (buf) |b| {
        if (len > 0) b[0] = 'u';
    }
    return 0;
}

export fn jent_entropy_collector_osr(_: ?*const anyopaque) callconv(.c) u32 {
    return 3;
}

export fn jent_entropy_collector_flags(_: ?*const anyopaque) callconv(.c) u32 {
    return 0;
}

export fn jent_entropy_collector_health_failure(_: ?*const anyopaque) callconv(.c) u32 {
    return 0;
}

export fn jent_entropy_collector_reinitializations(_: ?*const anyopaque) callconv(.c) u32 {
    return 0;
}

export fn jent_entropy_collector_memsize(_: ?*const anyopaque) callconv(.c) usize {
    return 2048;
}

export fn jent_entropy_collector_hashloops(_: ?*const anyopaque) callconv(.c) u32 {
    return 1;
}

export fn jent_entropy_collector_read_invocations(_: ?*const anyopaque) callconv(.c) u64 {
    return 1;
}

export fn jent_entropy_collector_bytes_output(_: ?*const anyopaque) callconv(.c) u64 {
    return 64;
}

export fn jent_kshim_fips_enabled() callconv(.c) c_int {
    return 0;
}

export fn jent_kshim_max_memsize_kb() callconv(.c) u32 {
    return 524288;
}

export fn jent_kshim_mutex_lock_interruptible(_: *anyopaque) callconv(.c) c_int {
    mock_mutex_lock_interruptible_calls += 1;
    return 0;
}

export fn jent_kshim_mutex_lock(_: *anyopaque) callconv(.c) void {}

export fn jent_kshim_mutex_unlock(_: *anyopaque) callconv(.c) void {
    mock_mutex_unlock_calls += 1;
}

export fn jent_kshim_copy_from_user(dst: *anyopaque, src: *const anyopaque, len: usize) callconv(.c) c_int {
    const d: [*]u8 = @ptrCast(dst);
    const s: [*]const u8 = @ptrCast(src);
    @memcpy(d[0..len], s[0..len]);
    return 0;
}

export fn jent_kshim_copy_to_user(dst: *anyopaque, src: *const anyopaque, len: usize) callconv(.c) c_int {
    mock_copy_to_user_calls += 1;
    const d: [*]u8 = @ptrCast(dst);
    const s: [*]const u8 = @ptrCast(src);
    @memcpy(d[0..len], s[0..len]);
    return 0;
}

export fn jent_kshim_kvzalloc(len: usize) callconv(.c) ?*anyopaque {
    mock_kvzalloc_calls += 1;
    if (mock_fail_kvzalloc or len > mock_kvzalloc_buf.len) return null;
    @memset(mock_kvzalloc_buf[0..len], 0);
    return @ptrCast(&mock_kvzalloc_buf);
}

export fn jent_kshim_kvfree_sensitive(_: ?*anyopaque, _: usize) callconv(.c) void {
    mock_kvfree_calls += 1;
}

export fn jent_kshim_seq_write(_: *anyopaque, _: [*]const u8, _: usize) callconv(.c) c_int {
    return 0;
}

export fn jent_kshim_log(_: c_int, _: [*]const u8, _: usize) callconv(.c) void {}

export fn jent_kshim_panic_init(_: c_int) callconv(.c) noreturn {
    @trap();
}

export fn jent_kshim_panic_selftest(_: c_int) callconv(.c) noreturn {
    @trap();
}

export fn jent_kshim_ioctl_kind(_: c_uint) callconv(.c) c_int {
    return 0;
}

export fn jent_kshim_proc_create() callconv(.c) c_int {
    return 0;
}

export fn jent_kshim_proc_remove() callconv(.c) void {}

export fn jent_kshim_interface_enabled(_: c_uint) callconv(.c) c_uint {
    return 1;
}

export fn jent_kshim_selftest_setup(_: *anyopaque, _: *anyopaque, _: *?*anyopaque) callconv(.c) void {}

export fn jent_kshim_selftest_lock(_: *anyopaque) callconv(.c) *anyopaque {
    return @ptrCast(&dummy_lock);
}

export fn jent_kshim_selftest_ec(_: *anyopaque) callconv(.c) *?*anyopaque {
    return &dummy_ec;
}

export fn jent_kshim_selftest_failed(_: *anyopaque) callconv(.c) bool {
    return false;
}

export fn jent_kshim_selftest_set_failed(_: *anyopaque, _: bool) callconv(.c) void {}

export fn jent_kshim_selftest_schedule(_: *anyopaque, _: u32) callconv(.c) void {}

export fn jent_kshim_selftest_cancel(_: *anyopaque) callconv(.c) void {}

export fn jent_kshim_selftest_interval_max() callconv(.c) u32 {
    return 86400;
}

export fn jent_entropy_collector_alloc(_: u32, _: u32) callconv(.c) ?*anyopaque {
    return @ptrCast(&dummy_ec_storage);
}

export fn jent_entropy_collector_free(_: ?*anyopaque) callconv(.c) void {}

export fn jent_read_entropy(_: ?*anyopaque, data: ?[*]u8, len: usize) callconv(.c) isize {
    mock_read_entropy_calls += 1;
    if (mock_chunk_count < mock_last_chunk_sizes.len) {
        mock_last_chunk_sizes[mock_chunk_count] = len;
        mock_chunk_count += 1;
    }
    if (data) |out| {
        for (0..len) |i| out[i] = @intCast((i + 0x41) & 0xff);
    }
    return @intCast(len);
}

export fn jent_read_entropy_safe(_: *?*anyopaque, data: ?[*]u8, len: usize) callconv(.c) isize {
    mock_read_entropy_safe_calls += 1;
    const chunk_idx = mock_chunk_count;
    if (mock_chunk_count < mock_last_chunk_sizes.len) {
        mock_last_chunk_sizes[mock_chunk_count] = len;
        mock_chunk_count += 1;
    }
    if (data) |out| {
        for (0..len) |i| out[i] = @intCast((chunk_idx * 37 + i) & 0xff);
    }
    return @intCast(len);
}

export fn jent_kshim_mutex_init(_: *anyopaque) callconv(.c) void {}

export fn jent_kshim_mutex_destroy(_: *anyopaque) callconv(.c) void {}

export fn jent_kshim_mutex_trylock(_: *anyopaque) callconv(.c) bool {
    mock_mutex_trylock_calls += 1;
    return true;
}

export fn jent_kshim_signal_pending() callconv(.c) bool {
    return false;
}

export fn jent_kshim_need_resched() callconv(.c) bool {
    return false;
}

export fn jent_kshim_cond_resched() callconv(.c) void {}

export fn jent_kshim_capable_admin() callconv(.c) bool {
    return true;
}

export fn jent_kshim_capable_resource() callconv(.c) bool {
    return true;
}

export fn jent_kshim_map_read_error(_: isize, _: bool) callconv(.c) c_int {
    return -5;
}

export fn jent_kshim_memzero(ptr: *anyopaque, len: usize) callconv(.c) void {
    mock_memzero_last_len = len;
    const bytes: [*]u8 = @ptrCast(ptr);
    @memset(bytes[0..len], 0);
}

export fn jent_kshim_copy_to_user_count(dst: *anyopaque, src: *const anyopaque, len: usize) callconv(.c) usize {
    const d: [*]u8 = @ptrCast(dst);
    const s: [*]const u8 = @ptrCast(src);
    @memcpy(d[0..len], s[0..len]);
    return 0;
}

export fn jent_kshim_chardev_ctx_alloc() callconv(.c) ?*anyopaque {
    return @ptrCast(&dummy_ctx);
}

export fn jent_kshim_chardev_ctx_free(_: *anyopaque) callconv(.c) void {}

export fn jent_kshim_chardev_lock(_: *anyopaque) callconv(.c) *anyopaque {
    return @ptrCast(&dummy_lock);
}

export fn jent_kshim_chardev_ec(_: *anyopaque) callconv(.c) *?*anyopaque {
    return &dummy_ec;
}

export fn jent_kshim_chardev_selftest(_: *anyopaque) callconv(.c) *anyopaque {
    return @ptrCast(&dummy_selftest);
}

export fn jent_kshim_chardev_file_ctx(_: *anyopaque) callconv(.c) ?*anyopaque {
    return @ptrCast(&dummy_ctx);
}

export fn jent_kshim_chardev_file_set_ctx(_: *anyopaque, _: ?*anyopaque) callconv(.c) void {}

export fn jent_kshim_file_nonblock(_: *anyopaque) callconv(.c) bool {
    return mock_nonblock;
}

export fn jent_kshim_chardev_proc_create(_: *anyopaque, _: [*:0]const u8) callconv(.c) void {}

export fn jent_kshim_chardev_proc_remove(_: *anyopaque) callconv(.c) void {}

export fn jent_kshim_chardev_register() callconv(.c) c_int {
    return 0;
}

export fn jent_kshim_chardev_unregister() callconv(.c) void {}

export fn jent_kshim_hwrng_ctx() callconv(.c) *anyopaque {
    return @ptrCast(&dummy_hwrng);
}

export fn jent_kshim_hwrng_lock(_: *anyopaque) callconv(.c) *anyopaque {
    return @ptrCast(&dummy_lock);
}

export fn jent_kshim_hwrng_ec(_: *anyopaque) callconv(.c) *?*anyopaque {
    return &dummy_ec;
}

export fn jent_kshim_hwrng_selftest(_: *anyopaque) callconv(.c) *anyopaque {
    return @ptrCast(&dummy_selftest);
}

export fn jent_kshim_hwrng_register(_: u32) callconv(.c) c_int {
    return 0;
}

export fn jent_kshim_hwrng_unregister() callconv(.c) void {}

export fn jent_kshim_hwrng_report_promotion() callconv(.c) void {}

export fn jent_kshim_kcapi_lock(_: *anyopaque) callconv(.c) *anyopaque {
    return @ptrCast(&dummy_lock);
}

export fn jent_kshim_kcapi_ec(_: *anyopaque) callconv(.c) *?*anyopaque {
    return &dummy_ec;
}

export fn jent_kshim_kcapi_selftest(_: *anyopaque) callconv(.c) *anyopaque {
    return @ptrCast(&dummy_selftest);
}

export fn jent_kshim_kcapi_log_allowed() callconv(.c) bool {
    return true;
}

export fn jent_kshim_kcapi_register() callconv(.c) c_int {
    return 0;
}

export fn jent_kshim_kcapi_unregister() callconv(.c) void {}

export fn jent_kshim_testing_lock() callconv(.c) *anyopaque {
    return @ptrCast(&dummy_lock);
}

export fn jent_kshim_testing_locked_down() callconv(.c) bool {
    return false;
}

export fn jent_kshim_testing_ctx_alloc() callconv(.c) ?*anyopaque {
    return @ptrCast(&dummy_ctx);
}

export fn jent_kshim_testing_ctx_free(_: *anyopaque) callconv(.c) void {}

export fn jent_kshim_testing_file_ctx(_: *anyopaque) callconv(.c) ?*anyopaque {
    return @ptrCast(&dummy_ctx);
}

export fn jent_kshim_testing_file_set_ctx(_: *anyopaque, _: ?*anyopaque) callconv(.c) void {}

export fn jent_kshim_testing_record(_: *anyopaque) callconv(.c) *?*anyopaque {
    return &dummy_record;
}

export fn jent_kshim_testing_ec(_: *anyopaque) callconv(.c) *?*anyopaque {
    return &dummy_ec;
}

export fn jent_kshim_testing_loop_count(_: *anyopaque) callconv(.c) *u64 {
    return &mock_testing_loop_count;
}

export fn jent_kshim_testing_register() callconv(.c) c_int {
    return 0;
}

export fn jent_kshim_testing_unregister() callconv(.c) void {}

export fn jent_record_alloc(out: *?*anyopaque, _: u32, _: u32, _: u32) callconv(.c) c_int {
    out.* = @ptrCast(&dummy_record_storage);
    return 0;
}

export fn jent_record_free(_: ?*anyopaque) callconv(.c) void {}

export fn jent_record_prime(_: *anyopaque, loop_count: u32) callconv(.c) void {
    mock_last_primed_loop_count = loop_count;
}

export fn jent_record_sample(_: *anyopaque, loop_count: u32) callconv(.c) u64 {
    mock_last_sampled_loop_count = loop_count;
    return 0xfeedfacecafebeef;
}

export fn jent_record_collector(_: *anyopaque) callconv(.c) *anyopaque {
    return @ptrCast(&dummy_ec_storage);
}

test "jent_zig_chardev_read batches multi-chunk reads in 256-byte chunks" {
    resetMocks();
    var out: [600]u8 = @splat(0);
    const rc = kmod.jent_zig_chardev_read(@ptrCast(&dummy_file), &out, out.len);
    try std.testing.expectEqual(@as(isize, 600), rc);
    try std.testing.expectEqual(@as(usize, 3), mock_chunk_count);
    try std.testing.expectEqual(@as(usize, 256), mock_last_chunk_sizes[0]);
    try std.testing.expectEqual(@as(usize, 256), mock_last_chunk_sizes[1]);
    try std.testing.expectEqual(@as(usize, 88), mock_last_chunk_sizes[2]);
    try std.testing.expectEqual(@as(usize, 3), mock_mutex_lock_interruptible_calls);
    try std.testing.expectEqual(@as(usize, 3), mock_mutex_unlock_calls);
    try std.testing.expectEqual(@as(usize, 3), mock_read_entropy_safe_calls);
    try std.testing.expectEqual(@as(usize, 3), mock_copy_to_user_calls);
    try std.testing.expectEqual(@as(usize, 256), mock_memzero_last_len);

    for (0..256) |i| {
        try std.testing.expectEqual(@as(u8, @intCast((0 * 37 + i) & 0xff)), out[i]);
    }
    for (0..256) |i| {
        try std.testing.expectEqual(@as(u8, @intCast((1 * 37 + i) & 0xff)), out[256 + i]);
    }
    for (0..88) |i| {
        try std.testing.expectEqual(@as(u8, @intCast((2 * 37 + i) & 0xff)), out[512 + i]);
    }
}

test "jent_zig_chardev_read caps O_NONBLOCK reads at 32 bytes" {
    resetMocks();
    mock_nonblock = true;
    var out: [512]u8 = @splat(0);
    const rc = kmod.jent_zig_chardev_read(@ptrCast(&dummy_file), &out, out.len);
    try std.testing.expectEqual(@as(isize, 32), rc);
    try std.testing.expectEqual(@as(usize, 1), mock_chunk_count);
    try std.testing.expectEqual(@as(usize, 32), mock_last_chunk_sizes[0]);
    try std.testing.expectEqual(@as(usize, 1), mock_mutex_trylock_calls);
    try std.testing.expectEqual(@as(usize, 1), mock_read_entropy_calls);
    try std.testing.expectEqual(@as(usize, 256), mock_memzero_last_len);
}

test "jent_status_to_user fails fast on null buf or zero length without kvzalloc" {
    resetMocks();
    var null_buf_req = StatusIoctl{
        .buf = 0,
        .length = 128,
    };
    const rc_null_buf = kmod.jent_status_to_user(
        @ptrCast(&dummy_lock),
        @ptrCast(&dummy_ec),
        &null_buf_req,
    );
    try std.testing.expectEqual(@as(c_long, -EINVAL), rc_null_buf);
    try std.testing.expectEqual(@as(usize, 0), mock_kvzalloc_calls);

    resetMocks();
    var user_buf: [128]u8 = @splat(0);
    var zero_len_req = StatusIoctl{
        .buf = @intFromPtr(&user_buf),
        .length = 0,
    };
    const rc_zero_len = kmod.jent_status_to_user(
        @ptrCast(&dummy_lock),
        @ptrCast(&dummy_ec),
        &zero_len_req,
    );
    try std.testing.expectEqual(@as(c_long, -EINVAL), rc_zero_len);
    try std.testing.expectEqual(@as(usize, 0), mock_kvzalloc_calls);

    resetMocks();
    var probe_req = StatusIoctl{
        .buf = 0,
        .length = 0,
    };
    const rc_probe = kmod.jent_status_to_user(
        @ptrCast(&dummy_lock),
        @ptrCast(&dummy_ec),
        &probe_req,
    );
    try std.testing.expectEqual(@as(c_long, -EOVERFLOW), rc_probe);
    try std.testing.expect(probe_req.length > 0);
    try std.testing.expectEqual(@as(usize, 1), mock_kvzalloc_calls);
    try std.testing.expectEqual(@as(usize, 1), mock_kvfree_calls);

    resetMocks();
    mock_fail_kvzalloc = true;
    var valid_req = StatusIoctl{
        .buf = @intFromPtr(&user_buf),
        .length = user_buf.len,
    };
    const rc_nomem = kmod.jent_status_to_user(
        @ptrCast(&dummy_lock),
        @ptrCast(&dummy_ec),
        &valid_req,
    );
    try std.testing.expectEqual(@as(c_long, -ENOMEM), rc_nomem);
    try std.testing.expectEqual(
        @as(c_int, -ENOMEM),
        kmod.jent_status_seq_show(@ptrCast(&dummy_seq), @ptrCast(&dummy_lock), @ptrCast(&dummy_ec)),
    );
    try std.testing.expectEqual(
        @as(c_int, -ENOMEM),
        kmod.jent_status_to_log(@ptrCast(&dummy_lock), @ptrCast(&dummy_ec)),
    );
}

test "jent_zig_testing_read clamps oversized loop_count before intCast" {
    resetMocks();
    mock_testing_loop_count = (@as(u64, 1) << 40) + 99;
    var samples: [2]u64 = @splat(0);
    var pos: i64 = 0;
    const rc = kmod.jent_zig_testing_read(
        @ptrCast(&dummy_file),
        &samples,
        @sizeOf(@TypeOf(samples)),
        &pos,
    );
    try std.testing.expectEqual(@as(isize, @sizeOf(@TypeOf(samples))), rc);
    try std.testing.expectEqual(@as(u32, 1 << 16), mock_last_primed_loop_count);
    try std.testing.expectEqual(@as(u32, 1 << 16), mock_last_sampled_loop_count);
    try std.testing.expectEqual(@as(u64, 0xfeedfacecafebeef), samples[0]);
    try std.testing.expectEqual(@as(u64, 0xfeedfacecafebeef), samples[1]);
}
