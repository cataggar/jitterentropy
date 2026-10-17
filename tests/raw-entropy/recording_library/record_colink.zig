const std = @import("std");

const c = struct {
    const FILE = opaque {};

    extern fn printf(format: [*:0]const u8, ...) callconv(.c) c_int;
    extern fn snprintf(
        buf: [*]u8,
        size: usize,
        format: [*:0]const u8,
        ...,
    ) callconv(.c) c_int;
    extern fn fopen(path: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*FILE;
    extern fn fclose(stream: *FILE) callconv(.c) c_int;
    extern fn fgets(buf: [*]u8, size: c_int, stream: *FILE) callconv(.c) ?[*]u8;
    extern fn remove(path: [*:0]const u8) callconv(.c) c_int;
    extern fn strstr(haystack: [*]const u8, needle: [*:0]const u8) callconv(.c) ?[*]u8;
    extern fn malloc(size: usize) callconv(.c) ?*anyopaque;
    extern fn free(ptr: ?*anyopaque) callconv(.c) void;
};

const ROUNDS: c_uint = 1000;
const JENT_RECORD_COMMON: c_uint = 0;
const JENT_RECORD_HASHLOOP: c_uint = 1;
const JENT_RECORD_MEMACCESS: c_uint = 2;
const JENT_RECORD_EINVAL: c_int = 1;
const JENT_DISABLE_MEMORY_ACCESS: c_uint = 1 << 2;
const JENT_MAX_OSR: c_uint = 20;

const RecordResult = extern struct {
    health_failure: c_uint,
    memsize: c_uint,
    hashloopcnt: c_uint,
    internal_timer: c_uint,
};

const RecordConfig = extern struct {
    file: ?[*:0]const u8 = null,
    rounds: c_ulong = 0,
    repeats: c_ulong = 0,
    flags: c_uint = 0,
    osr: c_uint = 0,
    loopcnt: c_uint = 0,
    source: c_uint = JENT_RECORD_COMMON,
    cpu: c_int = -1,
    cores: c_uint = 0,
    status: c_int = 0,
};

const Record = opaque {};
const Collector = opaque {};

extern fn jent_entropy_init_ex(c_uint, c_uint) callconv(.c) c_int;
extern fn jent_entropy_collector_alloc(c_uint, c_uint) callconv(.c) ?*Collector;
extern fn jent_entropy_collector_free(?*Collector) callconv(.c) void;
extern fn jent_read_entropy_safe(*?*Collector, [*]u8, usize) callconv(.c) isize;

extern fn jent_record_raw(
    [*:0]const u8,
    c_uint,
    c_uint,
    c_uint,
    c_uint,
    c_uint,
    *RecordResult,
    [*]u8,
    usize,
) callconv(.c) c_int;
extern fn jent_record_report_len(*const RecordConfig) callconv(.c) usize;
extern fn jent_record_run(*const RecordConfig, [*]u8, usize) callconv(.c) c_int;
extern fn jent_record_alloc(*?*Record, c_uint, c_uint, c_uint) callconv(.c) c_int;
extern fn jent_record_free(?*Record) callconv(.c) void;
extern fn jent_record_prime(*Record, c_uint) callconv(.c) void;
extern fn jent_record_sample(*Record, c_uint) callconv(.c) u64;

pub fn main(init: std.process.Init) u8 {
    var args = std.process.Args.Iterator.initAllocator(init.minimal.args, init.gpa) catch
        return 1;
    defer args.deinit();
    const program = args.next() orelse "record-colink";
    const prefix = args.next() orelse {
        _ = c.printf("%s <file name prefix>\n", program.ptr);
        return 1;
    };
    if (args.next() != null) {
        _ = c.printf("%s <file name prefix>\n", program.ptr);
        return 1;
    }

    var ret = jent_entropy_init_ex(0, 0);
    if (ret != 0) {
        _ = c.printf("SKIP: jent_entropy_init_ex failed on this machine: %d\n", ret);
        return 77;
    }
    var ec: ?*Collector = jent_entropy_collector_alloc(0, 0);
    if (ec == null) {
        _ = c.printf("FAIL: jent_entropy_collector_alloc\n");
        return 1;
    }
    defer if (ec != null) jent_entropy_collector_free(ec);

    var path: [4096]u8 = undefined;
    _ = c.snprintf(&path, path.len, "%s-0001.data", prefix.ptr);

    var result: RecordResult = undefined;
    var status: [4096]u8 = undefined;
    ret = jent_record_raw(
        @ptrCast(&path),
        ROUNDS,
        0,
        0,
        JENT_RECORD_COMMON,
        0,
        &result,
        &status,
        status.len,
    );
    if (ret != 0) {
        _ = c.printf("FAIL: jent_record_raw: %d\n", ret);
        return 1;
    }

    const file = c.fopen(@ptrCast(&path), "r") orelse {
        _ = c.printf("FAIL: %s not written\n", &path);
        return 1;
    };
    var line: [64]u8 = undefined;
    var lines: c_uint = 0;
    while (c.fgets(&line, line.len, file) != null) lines += 1;
    _ = c.fclose(file);
    _ = c.remove(@ptrCast(&path));
    if (lines != ROUNDS) {
        _ = c.printf("FAIL: %u time deltas recorded, not %u\n", lines, ROUNDS);
        return 1;
    }
    if (c.strstr(&status, "\"version\"") == null) {
        _ = c.printf("FAIL: no status document of the recording collector\n");
        return 1;
    }

    var config = RecordConfig{
        .rounds = ROUNDS,
        .repeats = 2,
        .source = JENT_RECORD_HASHLOOP,
    };
    var file_name: [4096]u8 = undefined;
    _ = c.snprintf(&file_name, file_name.len, "%s-run", prefix.ptr);
    config.file = @ptrCast(&file_name);
    const report_len = jent_record_report_len(&config);
    const report_mem = c.malloc(report_len) orelse {
        _ = c.printf("FAIL: no memory for the report\n");
        return 1;
    };
    defer c.free(report_mem);
    const report: [*]u8 = @ptrCast(report_mem);
    ret = jent_record_run(&config, report, report_len);
    if (ret != 0 or
        c.strstr(report, "Processing") == null or
        c.strstr(report, "-run-0002.data") == null)
    {
        _ = c.printf("FAIL: jent_record_run: %d, report:\n%s", ret, report);
        return 1;
    }
    var i: c_uint = 1;
    while (i <= 2) : (i += 1) {
        _ = c.snprintf(&path, path.len, "%s-%04u.data", &file_name, i);
        if (c.remove(@ptrCast(&path)) != 0) {
            _ = c.printf("FAIL: %s not written\n", &path);
            return 1;
        }
    }

    var record: ?*Record = null;
    if (jent_record_alloc(
        &record,
        0,
        JENT_DISABLE_MEMORY_ACCESS,
        JENT_RECORD_MEMACCESS,
    ) != JENT_RECORD_EINVAL or
        jent_record_alloc(
            &record,
            JENT_MAX_OSR + 1,
            0,
            JENT_RECORD_COMMON,
        ) != JENT_RECORD_EINVAL)
    {
        _ = c.printf("FAIL: jent_record_alloc took bad arguments\n");
        return 1;
    }
    ret = jent_record_alloc(&record, 0, 0, JENT_RECORD_COMMON);
    if (ret != 0) {
        _ = c.printf("FAIL: jent_record_alloc: %d\n", ret);
        return 1;
    }
    var nonzero: u64 = 0;
    jent_record_prime(record.?, 0);
    i = 0;
    while (i < ROUNDS) : (i += 1) {
        nonzero |= jent_record_sample(record.?, 0);
    }
    jent_record_free(record);
    if (nonzero == 0) {
        _ = c.printf("FAIL: jent_record_sample gave only zeroes\n");
        return 1;
    }

    var output: [32]u8 = undefined;
    ret = @intCast(jent_read_entropy_safe(&ec, &output, output.len));
    if (ret < 0 and ret != -2 and ret != -3 and ret != -5 and ret != -9) {
        _ = c.printf("FAIL: jent_read_entropy_safe after the recording: %d\n", ret);
        return 1;
    }
    jent_entropy_collector_free(ec);
    ec = null;

    _ = c.printf("PASS: %u time deltas recorded beside a collector\n", lines);
    return 0;
}
