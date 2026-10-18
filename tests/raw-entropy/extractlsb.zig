const std = @import("std");
const builtin = @import("builtin");

const c = struct {
    const FILE = opaque {};

    extern fn printf(format: [*:0]const u8, ...) callconv(.c) c_int;
    extern fn fopen(path: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*FILE;
    extern fn fclose(stream: *FILE) callconv(.c) c_int;
    extern fn fgets(buf: [*]u8, size: c_int, stream: *FILE) callconv(.c) ?[*]u8;
    extern fn ferror(stream: *FILE) callconv(.c) c_int;
    extern fn fwrite(
        ptr: *const anyopaque,
        size: usize,
        count: usize,
        stream: *FILE,
    ) callconv(.c) usize;
    extern fn remove(path: [*:0]const u8) callconv(.c) c_int;
    extern fn strerror(err: c_int) callconv(.c) [*:0]u8;

    extern fn __errno_location() callconv(.c) *c_int;
    extern fn __error() callconv(.c) *c_int;
    extern fn _errno() callconv(.c) *c_int;
};

fn getErrno() c_int {
    if (builtin.os.tag == .dragonfly) return c.__error().*;
    return std.c._errno().*;
}

fn extract(sample_value: u64, mask_value: u64) u8 {
    var sample = sample_value;
    var mask = mask_value;
    var byte: u8 = 0;
    var source_bit: u7 = 0;
    var dest_bit: u4 = 0;
    while (source_bit < 64 and mask != 0) : (source_bit += 1) {
        if (mask & 1 != 0) {
            byte |= @as(u8, @intCast(sample & 1)) << @as(u3, @intCast(dest_bit));
            dest_bit += 1;
        }
        mask >>= 1;
        sample >>= 1;
    }
    return byte;
}

fn parseMask(text: []const u8) ?u64 {
    if (text.len > 16) return null;
    var mask: u64 = 0;
    for (text) |char| {
        mask <<= 4;
        mask |= switch (char) {
            '0'...'9' => char - '0',
            'A'...'F' => char - 'A' + 10,
            'a'...'f' => char - 'a' + 10,
            else => return null,
        };
    }
    return mask;
}

fn printBits(sample_value: u64, value: u1, buf: *[73]u8) [*:0]const u8 {
    var sample = sample_value;
    var pos: usize = buf.len - 1;
    buf[pos] = 0;
    var i: usize = 0;
    while (i < 64) : (i += 1) {
        if (i % 8 == 0) {
            pos -= 1;
            buf[pos] = ' ';
        }
        pos -= 1;
        buf[pos] = if ((sample & 1) == value)
            @as(u8, '0') + @as(u8, value)
        else
            '-';
        sample >>= 1;
    }
    return @ptrCast(&buf[pos]);
}

fn failOutput(input: *c.FILE, output: *c.FILE, output_path: [*:0]const u8) u8 {
    _ = c.fclose(input);
    _ = c.fclose(output);
    _ = c.remove(output_path);
    return 1;
}

fn trapPanic(_: []const u8, _: ?usize) noreturn {
    @trap();
}
pub const panic = std.debug.FullPanic(trapPanic);

pub fn main(init: std.process.Init.Minimal) u8 {
    var args = std.process.Args.Iterator.initAllocator(init.args, std.heap.c_allocator) catch
        return 1;
    defer args.deinit();
    const program = args.next() orelse "extractlsb";
    const input_path = args.next() orelse {
        _ = c.printf("Usage: %s inputfile outfile maxevents mask\n", program.ptr);
        return 1;
    };
    const output_path = args.next() orelse {
        _ = c.printf("Usage: %s inputfile outfile maxevents mask\n", program.ptr);
        return 1;
    };
    const count_text = args.next() orelse {
        _ = c.printf("Usage: %s inputfile outfile maxevents mask\n", program.ptr);
        return 1;
    };
    const mask_text = args.next() orelse {
        _ = c.printf("Usage: %s inputfile outfile maxevents mask\n", program.ptr);
        return 1;
    };
    if (args.next() != null) {
        _ = c.printf("Usage: %s inputfile outfile maxevents mask\n", program.ptr);
        return 1;
    }

    const count = std.fmt.parseInt(u32, count_text, 10) catch {
        _ = c.printf("maxevents value is incorrect [%s]\n", count_text.ptr);
        return 1;
    };
    if (count == 0) {
        _ = c.printf("maxevents value is incorrect [%s]\n", count_text.ptr);
        return 1;
    }

    const mask = parseMask(mask_text) orelse {
        _ = c.printf(
            "Mask value is incorrect [%s], use up to 16 hexadecimal characters\n",
            mask_text.ptr,
        );
        return 1;
    };
    const selected_bits = @popCount(mask);
    if (selected_bits > 8) {
        _ = c.printf(
            "SP800-90B tool only supports up to 8 bits. Check the mask value\n",
        );
        return 1;
    }
    if (selected_bits == 0) {
        _ = c.printf(
            "Mask selects no bits - the output would be all-zero. Check the mask value\n",
        );
        return 1;
    }

    const input = c.fopen(input_path.ptr, "r") orelse {
        _ = c.printf(
            "File %s cannot be opened for read: %s\n",
            input_path.ptr,
            c.strerror(getErrno()),
        );
        return 1;
    };
    const output = c.fopen(output_path.ptr, "wbx") orelse {
        _ = c.printf(
            "File %s cannot be opened for write: %s\n",
            output_path.ptr,
            c.strerror(getErrno()),
        );
        _ = c.fclose(input);
        return 1;
    };

    var unchanged0s: u64 = 0;
    var unchanged1s: u64 = std.math.maxInt(u64);
    var processed: u32 = 0;
    var line: [64]u8 = undefined;
    while (processed < count and c.fgets(&line, line.len, input) != null) {
        processed += 1;
        const raw = std.mem.sliceTo(&line, 0);
        var token_len = raw.len;
        while (token_len != 0 and
            (raw[token_len - 1] == '\r' or raw[token_len - 1] == '\n'))
        {
            token_len -= 1;
        }
        const token = raw[0..token_len];
        if (token.len == 0 or token[0] == '-' or
            std.mem.indexOfScalar(u8, token, ' ') != null)
        {
            _ = c.printf("Invalid sample line [%s]\n", &line);
            return failOutput(input, output, output_path.ptr);
        }
        const sample = std.fmt.parseInt(u64, token, 10) catch {
            _ = c.printf("Invalid sample line [%s]\n", &line);
            return failOutput(input, output, output_path.ptr);
        };
        unchanged0s |= sample;
        unchanged1s &= sample;
        var symbol = extract(sample, mask);
        if (c.fwrite(&symbol, 1, 1, output) != 1) {
            _ = c.printf("write error: %s\n", c.strerror(getErrno()));
            return failOutput(input, output, output_path.ptr);
        }
    }

    if (c.ferror(input) != 0) {
        _ = c.printf("Read error on %s\n", input_path.ptr);
        return failOutput(input, output, output_path.ptr);
    }
    if (processed < count) {
        _ = c.printf(
            "Premature end of input: only %u of %u samples processed from %s\n",
            processed,
            count,
            input_path.ptr,
        );
        return failOutput(input, output, output_path.ptr);
    }

    _ = c.printf(
        "Processed %u items from %s samples with mask [0x%016llx] significant bits [%d]\n",
        processed,
        input_path.ptr,
        @as(c_ulonglong, mask),
        @as(c_int, @intCast(selected_bits)),
    );
    var zero_bits: [73]u8 = undefined;
    var one_bits: [73]u8 = undefined;
    _ = c.printf("Constant 0s in sample: \n%s\n", printBits(unchanged0s, 0, &zero_bits));
    _ = c.printf("Constant 1s in sample: \n%s\n", printBits(unchanged1s, 1, &one_bits));

    _ = c.fclose(input);
    if (c.fclose(output) != 0) {
        _ = c.remove(output_path.ptr);
        return 1;
    }
    return 0;
}
