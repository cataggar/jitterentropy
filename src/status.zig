const std = @import("std");
const i = @import("internal.zig");

const RandData = i.rand_data;

const arch_timer = @import("arch/timer.zig");

const StatusWriter = struct {
    buf: [*]u8,
    buflen: usize,
    truncated: bool = false,

    fn init(buf: [*]u8, buflen: usize) StatusWriter {
        var writer = StatusWriter{ .buf = buf, .buflen = buflen };
        writer.writeInitial("{\n");
        return writer;
    }

    fn writeInitial(self: *StatusWriter, text: []const u8) void {
        const copied = @min(text.len, self.buflen - 1);
        @memcpy(self.buf[0..copied], text[0..copied]);
        self.buf[copied] = 0;
        if (text.len >= self.buflen) self.truncated = true;
    }

    fn used(self: *const StatusWriter) usize {
        var len: usize = 0;
        while (len < self.buflen and self.buf[len] != 0) : (len += 1) {}
        return len;
    }

    fn add(self: *StatusWriter, text: []const u8) void {
        const len = self.used();
        if (len + 1 >= self.buflen) {
            self.truncated = true;
            return;
        }

        const available = self.buflen - len;
        const copied = @min(text.len, available - 1);
        @memcpy(self.buf[len .. len + copied], text[0..copied]);
        self.buf[len + copied] = 0;
        if (text.len >= available) self.truncated = true;
    }

    fn print(self: *StatusWriter, comptime fmt: []const u8, args: anytype) void {
        var tmp: [512]u8 = undefined;
        const text = std.fmt.bufPrint(&tmp, fmt, args) catch unreachable;
        self.add(text);
    }
};

fn boolText(value: bool) []const u8 {
    return if (value) "true" else "false";
}

pub fn jent_status(ec_opt: ?*const RandData, buf_opt: ?[*]u8, buflen: usize) callconv(.c) c_int {
    const buf = buf_opt orelse return -1;
    if (buflen == 0) return -1;

    var out = StatusWriter.init(buf, buflen);
    out.print("\t\"version\": \"{d}.{d}.{d}\"", .{
        i.JENT_MAJVERSION,
        i.JENT_MINVERSION,
        i.JENT_PATCHLEVEL,
    });

    const ec = ec_opt orelse {
        out.add("\n");
        out.add("}\n");
        return if (out.truncated) -1 else 0;
    };

    out.print(",\n\t\"uuid\": \"{s}\",\n", .{std.mem.sliceTo(ec.uuid[0..], 0)});
    out.print("\t\"reinitializations\": {d},\n", .{ec.reinit_count});

    out.add("\t\"output\": {\n");
    out.print("\t\t\"invocations\": {d},\n", .{ec.read_invocations});
    out.print("\t\t\"bytes\": {d},\n", .{ec.bytes_output});
    out.print("\t\t\"bits\": {d}\n", .{ec.bytes_output *% 8});
    out.add("\t},\n");

    out.add("\t\"healthFailure\": {\n");
    out.add("\t\t\"apt\": {\n");
    out.print("\t\t\t\"intermittent\": {s},\n", .{boolText(ec.health_failure & i.JENT_APT_FAILURE != 0)});
    out.print("\t\t\t\"permanent\": {s}\n", .{boolText(ec.health_failure & i.JENT_APT_FAILURE_PERMANENT != 0)});
    out.add("\t\t},\n");

    out.add("\t\t\"rct\": {\n");
    out.print("\t\t\t\"intermittent\": {s},\n", .{boolText(ec.health_failure & i.JENT_RCT_FAILURE != 0)});
    out.print("\t\t\t\"permanent\": {s}\n", .{boolText(ec.health_failure & i.JENT_RCT_FAILURE_PERMANENT != 0)});
    out.add("\t\t},\n");

    out.add("\t\t\"rctMemory\": {\n");
    out.print("\t\t\t\"intermittent\": {s},\n", .{boolText(ec.health_failure & i.JENT_RCT_MEM_FAILURE != 0)});
    out.print("\t\t\t\"permanent\": {s}\n", .{boolText(ec.health_failure & i.JENT_RCT_MEM_FAILURE_PERMANENT != 0)});
    out.add("\t\t},\n");

    out.add("\t\t\"lag\": {\n");
    out.print("\t\t\t\"intermittent\": {s},\n", .{boolText(ec.health_failure & i.JENT_LAG_FAILURE != 0)});
    out.print("\t\t\t\"permanent\": {s}\n", .{boolText(ec.health_failure & i.JENT_LAG_FAILURE_PERMANENT != 0)});
    out.add("\t\t}\n");
    out.add("\t},\n");

    out.add("\t\"runtimeEnvironment\": {\n");
    out.print("\t\t\"cpuCores\": {d},\n", .{i.jent_ncpu()});
    out.add("\t\t\"cpuCache\": {\n");
    out.print("\t\t\t\"l1Bytes\": {d},\n", .{i.jent_cache_size_roundup(0)});
    out.print("\t\t\t\"allBytes\": {d}\n", .{i.jent_cache_size_roundup(1)});
    out.add("\t\t}\n");
    out.add("\t},\n");

    out.add("\t\"configuration\": {\n");
    out.print("\t\t\"osr\": {d},\n", .{ec.osr});
    out.print("\t\t\"memoryBlockSizeBytes\": {d},\n", .{
        if (ec.memmask != 0) ec.memmask +% 1 else 0,
    });

    const hashloops = i.jent_hashloop_cnt(ec.flags);
    out.add("\t\t\"hashLoopCount\": {\n");
    out.print("\t\t\t\"runtime\": {d},\n", .{hashloops});
    out.print("\t\t\t\"initialization\": {d}\n", .{hashloops *% i.JENT_HASH_LOOP_INIT});
    out.add("\t\t},\n");

    out.add("\t\t\"memoryLoopCount\": {\n");
    out.print("\t\t\t\"runtime\": {d},\n", .{ec.memaccessloops});
    out.print("\t\t\t\"initialization\": {d}\n", .{ec.memaccessloops *% i.JENT_MEM_ACC_LOOP_INIT});
    out.add("\t\t},\n");

    out.print("\t\t\"secureMemory\": {s},\n", .{boolText(i.jent_memory_is_secure(ec.flags) != 0)});
    out.print("\t\t\"secureMemoryBackend\": \"{s}\",\n", .{std.mem.span(i.jent_memory_backend_name())});
    out.print("\t\t\"internalTimer\": {s},\n", .{boolText(ec.enableNotime() != 0)});
    if (i.build_options.mock_timer) {
        out.add("\t\t\"mockedTimerBuild\": true,\n");
        out.print("\t\t\"mockedTimerActive\": {s},\n", .{boolText(arch_timer.jent_mock_timer_active() != 0)});
    } else {
        out.add("\t\t\"mockedTimerBuild\": false,\n");
    }
    out.print("\t\t\"fipsMode\": {s},\n", .{boolText(ec.isFipsEnabled() != 0)});
    out.print("\t\t\"ntg1Mode\": {s},\n", .{boolText(ec.flags & i.JENT_NTG1 != 0)});

    out.add("\t\t\"flags\": {\n");
    out.print("\t\t\t\"JENT_DISABLE_MEMORY_ACCESS\": {s},\n", .{boolText(ec.flags & i.JENT_DISABLE_MEMORY_ACCESS != 0)});
    out.print("\t\t\t\"JENT_FORCE_INTERNAL_TIMER\": {s},\n", .{boolText(ec.flags & i.JENT_FORCE_INTERNAL_TIMER != 0)});
    out.print("\t\t\t\"JENT_DISABLE_INTERNAL_TIMER\": {s},\n", .{boolText(ec.flags & i.JENT_DISABLE_INTERNAL_TIMER != 0)});
    out.print("\t\t\t\"JENT_FORCE_FIPS\": {s},\n", .{boolText(ec.flags & i.JENT_FORCE_FIPS != 0)});
    out.print("\t\t\t\"JENT_NTG1\": {s},\n", .{boolText(ec.flags & i.JENT_NTG1 != 0)});
    out.print("\t\t\t\"JENT_CACHE_ALL\": {s},\n", .{boolText(ec.flags & i.JENT_CACHE_ALL != 0)});
    out.print("\t\t\t\"JENT_FORCE_SECURE_MEM\": {s}\n", .{boolText(ec.flags & i.JENT_FORCE_SECURE_MEM != 0)});
    out.add("\t\t}\n");
    out.add("\t}\n");
    out.add("}\n");

    return if (out.truncated) -1 else 0;
}

pub fn jent_entropy_collector_uuid(
    ec_opt: ?*const RandData,
    buf_opt: ?[*]u8,
    buflen: usize,
) callconv(.c) c_int {
    const ec = ec_opt orelse return -1;
    const buf = buf_opt orelse return -1;
    if (buflen < i.JENT_UUID_STRLEN) return -1;
    @memcpy(buf[0..i.JENT_UUID_STRLEN], ec.uuid[0..]);
    return 0;
}

fn collectorNull() c_uint {
    if (!i.is_freestanding) std.c._errno().* = 22;
    return 0;
}

pub fn jent_entropy_collector_osr(ec: ?*const RandData) callconv(.c) c_uint {
    return if (ec) |collector| collector.osr else collectorNull();
}

pub fn jent_entropy_collector_flags(ec: ?*const RandData) callconv(.c) c_uint {
    return if (ec) |collector| collector.flags else collectorNull();
}

pub fn jent_entropy_collector_memsize(ec: ?*const RandData) callconv(.c) usize {
    const collector = ec orelse return collectorNull();
    return if (collector.memmask != 0) @as(usize, collector.memmask) + 1 else 0;
}

pub fn jent_entropy_collector_health_failure(ec: ?*const RandData) callconv(.c) c_uint {
    return if (ec) |collector| collector.health_failure else collectorNull();
}

pub fn jent_entropy_collector_reinitializations(ec: ?*const RandData) callconv(.c) c_uint {
    return if (ec) |collector| collector.reinit_count else collectorNull();
}

pub fn jent_entropy_collector_read_invocations(ec: ?*const RandData) callconv(.c) u64 {
    return if (ec) |collector| collector.read_invocations else collectorNull();
}

pub fn jent_entropy_collector_bytes_output(ec: ?*const RandData) callconv(.c) u64 {
    return if (ec) |collector| collector.bytes_output else collectorNull();
}

pub fn jent_entropy_collector_hashloops(ec: ?*const RandData) callconv(.c) c_uint {
    return if (ec) |collector| collector.hashloopcnt else collectorNull();
}

test "status writer matches snprintf truncation semantics" {
    var buf: [3]u8 = undefined;
    var writer = StatusWriter.init(&buf, buf.len);
    try std.testing.expectEqualStrings("{\n", std.mem.sliceTo(buf[0..], 0));
    writer.add("x");
    try std.testing.expect(writer.truncated);
    try std.testing.expectEqualStrings("{\n", std.mem.sliceTo(buf[0..], 0));
}
