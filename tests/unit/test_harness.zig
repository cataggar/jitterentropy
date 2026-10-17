// SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0-only
//
// Shared unit test harness for jitterentropy tests (Zig port of tests/unit/unit.h
// and tests/jitterentropy-memlock.h).

const std = @import("std");
const builtin = @import("builtin");

/// Automake / Meson / CTest convention for a runtime-skipped test.
pub const SKIP_RETURN_CODE: u8 = 77;

/// Minimum memlock limit (256 KiB) required by unit tests (notably unit-concurrency).
pub const MIN_MEMLOCK_BYTES: usize = 256 * 1024;

/// Global test counters matching `jent_ut_Attempted` and `jent_ut_Skipped` in `unit.h`.
pub var jent_ut_Attempted: c_int = 0;
pub var jent_ut_Skipped: c_int = 0;

/// Reset the global test counters.
pub fn resetCounters() void {
    jent_ut_Attempted = 0;
    jent_ut_Skipped = 0;
}

/// Check whether `JENT_UT_STRICT` is set to a non-empty, non-"0" value in the environment.
/// Returns true when skips should be treated as hard failures.
pub fn isStrict() bool {
    if (builtin.link_libc) {
        const val_ptr = std.c.getenv("JENT_UT_STRICT") orelse return false;
        const first = val_ptr[0];
        return first != 0 and first != '0';
    }
    return false;
}

/// Evaluate whether a `JENT_UT_STRICT` string value enables strict mode.
pub fn isStrictValue(val: ?[]const u8) bool {
    const s = val orelse return false;
    if (s.len == 0 or s[0] == '0') return false;
    return true;
}

/// Stateful harness instance for isolated test tracking or self-tests.
pub const Harness = struct {
    attempted: usize = 0,
    skipped: usize = 0,
    strict_override: ?bool = null,

    pub fn strictEnabled(self: *const Harness) bool {
        return self.strict_override orelse isStrict();
    }

    pub fn recordCheck(self: *Harness, cond: bool) !void {
        self.attempted += 1;
        if (!cond) return error.TestExpectationFailed;
    }

    pub fn recordSkip(self: *Harness) !void {
        if (self.strictEnabled()) {
            return error.TestStrictSkipForbidden;
        }
        self.attempted += 1;
        self.skipped += 1;
    }

    pub fn exitCode(self: *const Harness) u8 {
        if (self.attempted > 0 and self.skipped == self.attempted) {
            return SKIP_RETURN_CODE;
        }
        return 0;
    }
};

/// Assert `cond` is true, incrementing `jent_ut_Attempted`.
/// On failure, prints a diagnostic to stderr and returns `error.TestExpectationFailed`.
pub fn expect(
    cond: bool,
    src: std.builtin.SourceLocation,
    comptime fmt: []const u8,
    args: anytype,
) !void {
    jent_ut_Attempted += 1;
    if (!cond) {
        std.debug.print(
            "FAIL [{s}:{d} in {s}]: " ++ fmt ++ "\n",
            .{ src.file, src.line, src.fn_name } ++ args,
        );
        return error.TestExpectationFailed;
    }
}

/// Simple boolean check matching `check(cond)` in `unit.h`.
pub fn check(cond: bool, src: std.builtin.SourceLocation) !void {
    jent_ut_Attempted += 1;
    if (!cond) {
        std.debug.print(
            "FAIL [{s}:{d} in {s}]: check failed\n",
            .{ src.file, src.line, src.fn_name },
        );
        return error.TestExpectationFailed;
    }
}

/// Assert `cond` is true or terminate the process with exit code 1 (matching `expect` macro in `unit.h`).
pub fn expectOrExit(
    cond: bool,
    src: std.builtin.SourceLocation,
    comptime fmt: []const u8,
    args: anytype,
) void {
    expect(cond, src, fmt, args) catch std.process.exit(1);
}

/// Check `cond` or terminate the process with exit code 1 (matching `check` macro in `unit.h`).
pub fn checkOrExit(cond: bool, src: std.builtin.SourceLocation) void {
    check(cond, src) catch std.process.exit(1);
}

/// Record a skipped check (matching `skip(...)` in `unit.h`).
/// If `JENT_UT_STRICT` is enabled, prints a strict failure diagnostic and returns `error.TestStrictSkipForbidden`.
pub fn skip(
    src: std.builtin.SourceLocation,
    comptime fmt: []const u8,
    args: anytype,
) !void {
    if (isStrict()) {
        std.debug.print(
            "FAIL (strict) [{s}:{d} in {s}]: " ++ fmt ++ "\n",
            .{ src.file, src.line, src.fn_name } ++ args,
        );
        return error.TestStrictSkipForbidden;
    }
    jent_ut_Attempted += 1;
    jent_ut_Skipped += 1;
    std.debug.print(
        "SKIP [{s}:{d}]: " ++ fmt ++ "\n",
        .{ src.file, src.line } ++ args,
    );
}

/// Record a skipped check or exit with code 1 if `JENT_UT_STRICT` is set.
pub fn skipOrExit(
    src: std.builtin.SourceLocation,
    comptime fmt: []const u8,
    args: anytype,
) void {
    skip(src, fmt, args) catch std.process.exit(1);
}

/// Compute summary status and print PASS/SKIP banner (matching `pass(name)` in `unit.h`).
/// Returns `SKIP_RETURN_CODE` (77) if all attempted checks were skipped, or `0` on pass.
pub fn finish(name: []const u8) u8 {
    if (jent_ut_Attempted > 0 and jent_ut_Skipped == jent_ut_Attempted) {
        std.debug.print(
            "SKIP: {s} (all {d} checks skipped)\n",
            .{ name, jent_ut_Skipped },
        );
        return SKIP_RETURN_CODE;
    }
    std.debug.print(
        "PASS: {s} ({d} checks, {d} skipped)\n",
        .{ name, jent_ut_Attempted, jent_ut_Skipped },
    );
    return 0;
}

/// Print final summary for `name` and exit the process with 0 or `SKIP_RETURN_CODE` (77).
pub fn pass(name: []const u8) noreturn {
    const code = finish(name);
    std.process.exit(code);
}

/// Raise `RLIMIT_MEMLOCK` soft limit to hard limit if below 256 KiB
/// (Zig port of `raise_memlock_limit` from `tests/jitterentropy-memlock.h`).
pub fn raiseMemlockLimit() void {
    if (builtin.os.tag == .windows or builtin.os.tag == .freestanding or !builtin.link_libc) {
        return;
    }
    if (@hasDecl(std.c, "rlimit_resource") and @hasDecl(std.c, "getrlimit") and @hasDecl(std.c, "setrlimit")) {
        if (@hasField(std.c.rlimit_resource, "MEMLOCK")) {
            var rl: std.c.rlimit = undefined;
            if (std.c.getrlimit(.MEMLOCK, &rl) != 0) return;
            if (rl.cur == std.c.RLIM.INFINITY or rl.cur >= MIN_MEMLOCK_BYTES) return;
            rl.cur = rl.max;
            _ = std.c.setrlimit(.MEMLOCK, &rl);
        }
    }
}

/// Alias matching the C identifier in `tests/jitterentropy-memlock.h`.
pub const raise_memlock_limit = raiseMemlockLimit;

test "Harness counters and exit codes" {
    var h: Harness = .{ .strict_override = false };
    try std.testing.expectEqual(@as(u8, 0), h.exitCode());

    try h.recordSkip();
    try std.testing.expectEqual(@as(usize, 1), h.attempted);
    try std.testing.expectEqual(@as(usize, 1), h.skipped);
    try std.testing.expectEqual(SKIP_RETURN_CODE, h.exitCode());

    try h.recordCheck(true);
    try std.testing.expectEqual(@as(usize, 2), h.attempted);
    try std.testing.expectEqual(@as(usize, 1), h.skipped);
    try std.testing.expectEqual(@as(u8, 0), h.exitCode());

    try std.testing.expectError(error.TestExpectationFailed, h.recordCheck(false));
}

test "Harness strict mode rejects skips" {
    var h: Harness = .{ .strict_override = true };
    try std.testing.expectError(error.TestStrictSkipForbidden, h.recordSkip());
    try std.testing.expectEqual(@as(usize, 0), h.attempted);
    try std.testing.expectEqual(@as(usize, 0), h.skipped);
}

test "isStrictValue parses environment values" {
    try std.testing.expect(!isStrictValue(null));
    try std.testing.expect(!isStrictValue(""));
    try std.testing.expect(!isStrictValue("0"));
    try std.testing.expect(!isStrictValue("00"));
    try std.testing.expect(isStrictValue("1"));
    try std.testing.expect(isStrictValue("true"));
}

test "global counters and raiseMemlockLimit" {
    resetCounters();
    try check(true, @src());
    try expect(1 + 1 == 2, @src(), "math check {d}", .{2});
    try std.testing.expectEqual(@as(c_int, 2), jent_ut_Attempted);
    try std.testing.expectEqual(@as(c_int, 0), jent_ut_Skipped);
    raiseMemlockLimit();
    resetCounters();
}
