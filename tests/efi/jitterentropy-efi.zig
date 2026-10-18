// SPDX-License-Identifier: BSD-2-Clause OR GPL-2.0-only
//
// Copyright (C) 2026, Stephan Mueller <smueller@chronox.de>
//
// Minimal UEFI application exercising libjitterentropy in JENT_BAREMETAL
// mode.
//
// The application executes the startup self-tests, allocates entropy
// collectors for the default, FIPS and NTG.1 configurations, extracts a
// sample from each, dumps the collector status and finally shuts the virtual
// machine down via ResetSystem(EfiResetShutdown) so a QEMU test harness can
// run unattended and inspect the serial log.

const std = @import("std");
const uefi = std.os.uefi;

const JE_TAG = "jitterentropy-efi: ";
const JE_SAMPLE_BYTES: usize = 32;
const JE_STATUS_BUF_BYTES: usize = 4096;

const JENT_FORCE_INTERNAL_TIMER: c_uint = 1 << 2;
const JENT_FORCE_FIPS: c_uint = 1 << 4;
const JENT_NTG1: c_uint = 1 << 7;

pub const rand_data = opaque {};

extern fn jent_version() callconv(.c) c_uint;
extern fn jent_entropy_init_ex(osr: c_uint, flags: c_uint) callconv(.c) c_int;
extern fn jent_entropy_collector_alloc(osr: c_uint, flags: c_uint) callconv(.c) ?*rand_data;
extern fn jent_entropy_collector_free(entropy_collector: ?*rand_data) callconv(.c) void;
extern fn jent_read_entropy(entropy_collector: ?*rand_data, data: [*]u8, len: usize) callconv(.c) isize;
extern fn jent_read_entropy_safe(entropy_collector: *?*rand_data, data: [*]u8, len: usize) callconv(.c) isize;
extern fn jent_status(entropy_collector: *const rand_data, buf: [*]u8, buflen: usize) callconv(.c) c_int;

var g_st: ?*uefi.tables.SystemTable = null;
var g_bs: ?*uefi.tables.BootServices = null;

// ===========================================================================
// Minimal console output
//
// No formatting library is pulled in so the binary stays self-contained: a
// handful of small routines convert ASCII strings, signed/unsigned integers
// and byte buffers to the UCS-2 strings expected by
// EFI_SIMPLE_TEXT_OUTPUT_PROTOCOL.OutputString, translating '\n' to "\r\n".
// ===========================================================================

fn je_write_ascii(s: []const u8) void {
    const st = g_st orelse return;
    const con_out = st.con_out orelse return;

    var buf: [128]u16 = undefined;
    var i: usize = 0;

    for (s) |ch| {
        if (i >= buf.len - 3) {
            buf[i] = 0;
            _ = con_out._output_string(con_out, @ptrCast(&buf));
            i = 0;
        }
        if (ch == '\n') {
            buf[i] = '\r';
            i += 1;
        }
        buf[i] = ch;
        i += 1;
    }

    if (i > 0) {
        buf[i] = 0;
        _ = con_out._output_string(con_out, @ptrCast(&buf));
    }
}

fn je_write_cstr(s: [*:0]const u8) void {
    je_write_ascii(std.mem.span(s));
}

fn je_write_tag() void {
    je_write_ascii(JE_TAG);
}

fn je_write_nl() void {
    je_write_ascii("\n");
}

fn je_write_u64_dec(val: u64) void {
    var tmp: [24]u8 = undefined;
    var n: usize = 0;
    var v = val;

    if (v == 0) {
        je_write_ascii("0");
        return;
    }
    while (v > 0 and n < tmp.len) {
        tmp[n] = @intCast('0' + (v % 10));
        v /= 10;
        n += 1;
    }
    var out: [24]u8 = undefined;
    var idx: usize = 0;
    while (n > 0) {
        n -= 1;
        out[idx] = tmp[n];
        idx += 1;
    }
    je_write_ascii(out[0..idx]);
}

fn je_write_s64_dec(val: i64) void {
    if (val < 0) {
        je_write_ascii("-");
        const mag: u64 = @intCast(-(val + 1));
        je_write_u64_dec(mag + 1);
    } else {
        je_write_u64_dec(@intCast(val));
    }
}

fn je_write_hex(buf: []const u8) void {
    const hex = "0123456789abcdef";
    var pair: [2]u8 = undefined;
    for (buf) |b| {
        pair[0] = hex[(b >> 4) & 0x0f];
        pair[1] = hex[b & 0x0f];
        je_write_ascii(&pair);
    }
}

fn je_log_str(msg: []const u8) void {
    je_write_tag();
    je_write_ascii(msg);
    je_write_nl();
}

fn je_log_str_s64(msg: []const u8, val: i64) void {
    je_write_tag();
    je_write_ascii(msg);
    je_write_s64_dec(val);
    je_write_nl();
}

// ===========================================================================
// Minimal C library symbols required by libjitterentropy in JENT_BAREMETAL
// mode.
//
// - malloc / free back jent_zalloc / jent_zfree (arch/jitterentropy-arch-memory.c)
//   and delegate directly to UEFI BootServices AllocatePool / FreePool.
// - strlen / strcmp / snprintf back jent_status (src/jitterentropy-status.c).
// ===========================================================================

pub export fn malloc(size: usize) callconv(.c) ?*anyopaque {
    const bs = g_bs orelse return null;
    if (size == 0) return null;
    var ptr: [*]align(8) u8 = undefined;
    const status = bs._allocatePool(.boot_services_data, size, &ptr);
    if (status != .success) return null;
    return @ptrCast(ptr);
}

pub export fn free(ptr: ?*anyopaque) callconv(.c) void {
    const p = ptr orelse return;
    const bs = g_bs orelse return;
    _ = bs._freePool(@ptrCast(@alignCast(p)));
}

pub export fn strlen(s: [*:0]const u8) callconv(.c) usize {
    var n: usize = 0;
    while (s[n] != 0) : (n += 1) {}
    return n;
}

pub export fn strcmp(s1: [*:0]const u8, s2: [*:0]const u8) callconv(.c) c_int {
    var i: usize = 0;
    while (s1[i] != 0 and s1[i] == s2[i]) : (i += 1) {}
    return @as(c_int, s1[i]) - @as(c_int, s2[i]);
}

pub export fn __chkstk() callconv(.c) void {}

fn sb_putc(buf: ?[*]u8, size: usize, pos: *usize, c: u8) void {
    if (buf) |b| {
        if (size > 0 and pos.* + 1 < size) {
            b[pos.*] = c;
        }
    }
    pos.* += 1;
}

fn sb_puts(buf: ?[*]u8, size: usize, pos: *usize, s: ?[*:0]const u8) void {
    const str = s orelse "(null)";
    var i: usize = 0;
    while (str[i] != 0) : (i += 1) {
        sb_putc(buf, size, pos, str[i]);
    }
}

fn sb_putu(buf: ?[*]u8, size: usize, pos: *usize, val: u64, base: u32) void {
    const digits = "0123456789abcdef";
    var tmp: [24]u8 = undefined;
    var n: usize = 0;
    var v = val;

    if (v == 0) {
        sb_putc(buf, size, pos, '0');
        return;
    }
    while (v > 0 and n < tmp.len) {
        tmp[n] = digits[@intCast(v % base)];
        v /= base;
        n += 1;
    }
    while (n > 0) {
        n -= 1;
        sb_putc(buf, size, pos, tmp[n]);
    }
}

fn sb_putd(buf: ?[*]u8, size: usize, pos: *usize, val: i64) void {
    if (val < 0) {
        sb_putc(buf, size, pos, '-');
        const mag: u64 = @intCast(-(val + 1));
        sb_putu(buf, size, pos, mag + 1, 10);
    } else {
        sb_putu(buf, size, pos, @intCast(val), 10);
    }
}

/// Minimal snprintf supporting the format specifiers used by
/// src/jitterentropy-status.c: %%, %s, %d, %i, %ld, %lld, %u, %lu, %llu,
/// %zu, %x, %lx, %llx (no width/precision modifiers needed).
/// Uses fixed register/stack arguments matching the C variadic calling
/// convention on x86_64-uefi and aarch64-uefi (at most 3 arguments are passed
/// by jitterentropy-status.c).
pub export fn snprintf(
    buf: ?[*]u8,
    size: usize,
    fmt: ?[*:0]const u8,
    arg0: usize,
    arg1: usize,
    arg2: usize,
    arg3: usize,
) callconv(.c) c_int {
    const f = fmt orelse return 0;
    const args = [4]usize{ arg0, arg1, arg2, arg3 };
    var arg_idx: usize = 0;
    var pos: usize = 0;
    var i: usize = 0;

    while (f[i] != 0) {
        if (f[i] != '%') {
            sb_putc(buf, size, &pos, f[i]);
            i += 1;
            continue;
        }
        i += 1;
        if (f[i] == '%') {
            sb_putc(buf, size, &pos, '%');
            i += 1;
            continue;
        }

        var lmod: u32 = 0;
        var zmod: bool = false;
        while (f[i] == 'l' or f[i] == 'z') {
            if (f[i] == 'l') lmod += 1 else zmod = true;
            i += 1;
        }

        const raw_arg: usize = if (arg_idx < args.len) blk: {
            const v = args[arg_idx];
            arg_idx += 1;
            break :blk v;
        } else 0;

        switch (f[i]) {
            's' => {
                const s_ptr: ?[*:0]const u8 = @ptrFromInt(raw_arg);
                sb_puts(buf, size, &pos, s_ptr);
                i += 1;
            },
            'd', 'i' => {
                const v: i64 = if (lmod >= 2)
                    @as(c_longlong, @bitCast(@as(u64, raw_arg)))
                else if (lmod == 1)
                    @as(c_long, @truncate(@as(isize, @bitCast(raw_arg))))
                else
                    @as(c_int, @truncate(@as(isize, @bitCast(raw_arg))));
                sb_putd(buf, size, &pos, v);
                i += 1;
            },
            'u', 'x' => {
                const base: u32 = if (f[i] == 'x') 16 else 10;
                const v: u64 = if (zmod)
                    raw_arg
                else if (lmod >= 2)
                    @as(c_ulonglong, raw_arg)
                else if (lmod == 1)
                    @as(c_ulong, @truncate(raw_arg))
                else
                    @as(c_uint, @truncate(raw_arg));
                sb_putu(buf, size, &pos, v, base);
                i += 1;
            },
            0 => {},
            else => {
                sb_putc(buf, size, &pos, '%');
                sb_putc(buf, size, &pos, f[i]);
                i += 1;
            },
        }
    }

    if (buf) |b| {
        if (size > 0) {
            const term = if (pos < size) pos else size - 1;
            b[term] = 0;
        }
    }

    return @intCast(pos);
}

// ===========================================================================
// Jitter RNG test cases
// ===========================================================================

fn je_collector(name: [*:0]const u8, flags: c_uint, required: bool) uefi.Status {
    var status_buf: [JE_STATUS_BUF_BYTES]u8 = undefined;
    var sample: [JE_SAMPLE_BYTES]u8 = undefined;

    var ec: ?*rand_data = jent_entropy_collector_alloc(0, flags);
    if (ec == null) {
        if (!required) {
            je_write_tag();
            je_write_cstr(name);
            je_write_ascii(" refused, which its health test cutoffs allow\n");
            return .success;
        }
        je_write_tag();
        je_write_ascii("FAIL: no ");
        je_write_cstr(name);
        je_write_ascii(" collector could be allocated\n");
        return .load_error;
    }
    defer if (ec) |p| jent_entropy_collector_free(p);

    je_write_tag();
    je_write_cstr(name);
    je_write_ascii(" collector allocated\n");

    @memset(&sample, 0);
    const n = if (required)
        jent_read_entropy_safe(&ec, &sample, sample.len)
    else
        jent_read_entropy(ec, &sample, sample.len);
    if (n < 0) {
        je_write_tag();
        je_write_cstr(name);
        je_write_ascii(" read failed with ");
        je_write_s64_dec(@intCast(n));
        je_write_nl();
        if (!required)
            return .success;
        return .device_error;
    }
    if (@as(usize, @intCast(n)) != sample.len) {
        je_write_tag();
        je_write_ascii("FAIL: ");
        je_write_cstr(name);
        je_write_ascii(" read returned ");
        je_write_s64_dec(@intCast(n));
        je_write_nl();
        return .device_error;
    }

    je_write_tag();
    je_write_cstr(name);
    je_write_ascii(" entropy ");
    je_write_hex(&sample);
    je_write_nl();

    @memset(&status_buf, 0);
    if (ec) |collector| {
        if (jent_status(collector, &status_buf, status_buf.len) == 0) {
            je_write_tag();
            je_write_cstr(name);
            je_write_ascii(" status\n");
            status_buf[status_buf.len - 1] = 0;
            const status_cstr: [*:0]const u8 = status_buf[0 .. status_buf.len - 1 :0];
            je_write_cstr(status_cstr);
            je_write_nl();
        }
    }

    return .success;
}

/// Without pthreads (JENT_BAREMETAL) the internal timer cannot exist and
/// forcing it must be refused both by initialization and by allocation.
fn je_no_internal_timer() uefi.Status {
    const ret = jent_entropy_init_ex(0, JENT_FORCE_INTERNAL_TIMER);
    if (ret == 0) {
        je_log_str("FAIL: initialization accepted the internal timer");
        return .unsupported;
    }

    const ec = jent_entropy_collector_alloc(0, JENT_FORCE_INTERNAL_TIMER);
    if (ec != null) {
        jent_entropy_collector_free(ec);
        je_log_str("FAIL: collector allocated with the internal timer");
        return .unsupported;
    }

    je_log_str_s64("internal timer refused, the startup reporting ", @intCast(ret));
    return .success;
}

pub export fn efi_main(image_handle: uefi.Handle, system_table: *uefi.tables.SystemTable) callconv(uefi.cc) usize {
    _ = image_handle;
    var status: uefi.Status = .success;

    g_st = system_table;
    g_bs = system_table.boot_services;
    uefi.system_table = system_table;

    if (system_table.con_out) |con_out| {
        _ = con_out._reset(con_out, false);
    }

    je_write_tag();
    je_write_ascii("start, library version ");
    je_write_u64_dec(@intCast(jent_version()));
    je_write_nl();

    const ret = jent_entropy_init_ex(0, 0);
    if (ret != 0) {
        je_log_str_s64("FAIL: the startup reports ", @intCast(ret));
        status = .load_error;
        return finish(system_table, status);
    }
    je_log_str("startup passed");

    status = je_collector("default", 0, true);
    if (status != .success) return finish(system_table, status);

    status = je_collector("FIPS", JENT_FORCE_FIPS, false);
    if (status != .success) return finish(system_table, status);

    status = je_collector("NTG.1", JENT_NTG1, false);
    if (status != .success) return finish(system_table, status);

    status = je_no_internal_timer();
    if (status != .success) return finish(system_table, status);

    return finish(system_table, status);
}

pub export fn EfiMain(image_handle: uefi.Handle, system_table: *uefi.tables.SystemTable) callconv(uefi.cc) usize {
    return efi_main(image_handle, system_table);
}

fn finish(system_table: *uefi.tables.SystemTable, status: uefi.Status) usize {
    if (status == .success) {
        je_log_str("done");
    } else {
        je_log_str("failed");
    }

    system_table.runtime_services._resetSystem(.shutdown, status, 0, null);

    return @as(*const usize, @ptrCast(&status)).*;
}
