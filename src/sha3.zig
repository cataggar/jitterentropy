const std = @import("std");
const internal = @import("internal.zig");

// build.zig compiles every root module containing this file in Debug mode.
// Zig 0.16/0.17 do not provide a per-function @setOptimizeMode builtin.

const ShaCtx = internal.jent_sha_ctx;
const rate = internal.JENT_SHA3_256_SIZE_BLOCK;
const digest_size = internal.JENT_SHA3_256_SIZE_DIGEST;
const xdrbg_state_size = internal.JENT_XDRBG_SIZE_STATE;

fn loadLe64(bytes: [*]const u8) u64 {
    var value: u64 = 0;
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        value |= @as(u64, bytes[i]) << @intCast(i * 8);
    }
    return value;
}

fn storeLe64(bytes: [*]u8, value: u64) void {
    var i: usize = 0;
    while (i < 8) : (i += 1) {
        bytes[i] = @truncate(value >> @intCast(i * 8));
    }
}

fn rol64(value: u64, amount: u6) u64 {
    return std.math.rotl(u64, value, amount);
}

fn lane(x: usize, y: usize) usize {
    return x + 5 * y;
}

fn theta(state: *[25]u64) void {
    var c: [5]u64 = undefined;
    var d: [5]u64 = undefined;

    for (0..5) |x| {
        c[x] = state[lane(x, 0)] ^ state[lane(x, 1)] ^ state[lane(x, 2)] ^
            state[lane(x, 3)] ^ state[lane(x, 4)];
    }
    d[0] = c[4] ^ rol64(c[1], 1);
    d[1] = c[0] ^ rol64(c[2], 1);
    d[2] = c[1] ^ rol64(c[3], 1);
    d[3] = c[2] ^ rol64(c[4], 1);
    d[4] = c[3] ^ rol64(c[0], 1);

    for (0..5) |y| {
        for (0..5) |x| state[lane(x, y)] ^= d[x];
    }
}

const rho_offsets = [24]u6{
    1,  3,  6,  10, 15, 21, 28, 36,
    45, 55, 2,  14, 27, 41, 56, 8,
    25, 43, 62, 18, 39, 61, 20, 44,
};

const rho_lanes = [24]usize{
    lane(1, 0), lane(0, 2), lane(2, 1), lane(1, 2),
    lane(2, 3), lane(3, 3), lane(3, 0), lane(0, 1),
    lane(1, 3), lane(3, 1), lane(1, 4), lane(4, 4),
    lane(4, 0), lane(0, 3), lane(3, 4), lane(4, 3),
    lane(3, 2), lane(2, 2), lane(2, 0), lane(0, 4),
    lane(4, 2), lane(2, 4), lane(4, 1), lane(1, 1),
};

fn rho(state: *[25]u64) void {
    for (rho_lanes, rho_offsets) |index, offset| {
        state[index] = rol64(state[index], offset);
    }
}

fn pi(state: *[25]u64) void {
    const saved = state[lane(4, 4)];
    state[lane(4, 4)] = state[lane(1, 4)];
    state[lane(1, 4)] = state[lane(3, 1)];
    state[lane(3, 1)] = state[lane(1, 3)];
    state[lane(1, 3)] = state[lane(0, 1)];
    state[lane(0, 1)] = state[lane(3, 0)];
    state[lane(3, 0)] = state[lane(3, 3)];
    state[lane(3, 3)] = state[lane(2, 3)];
    state[lane(2, 3)] = state[lane(1, 2)];
    state[lane(1, 2)] = state[lane(2, 1)];
    state[lane(2, 1)] = state[lane(0, 2)];
    state[lane(0, 2)] = state[lane(1, 0)];
    state[lane(1, 0)] = state[lane(1, 1)];
    state[lane(1, 1)] = state[lane(4, 1)];
    state[lane(4, 1)] = state[lane(2, 4)];
    state[lane(2, 4)] = state[lane(4, 2)];
    state[lane(4, 2)] = state[lane(0, 4)];
    state[lane(0, 4)] = state[lane(2, 0)];
    state[lane(2, 0)] = state[lane(2, 2)];
    state[lane(2, 2)] = state[lane(3, 2)];
    state[lane(3, 2)] = state[lane(4, 3)];
    state[lane(4, 3)] = state[lane(3, 4)];
    state[lane(3, 4)] = state[lane(0, 3)];
    state[lane(0, 3)] = state[lane(4, 0)];
    state[lane(4, 0)] = saved;
}

fn chi(state: *[25]u64) void {
    var first: [5]u64 = undefined;
    var second: [5]u64 = undefined;
    for (0..5) |y| {
        first[y] = state[lane(0, y)];
        second[y] = state[lane(1, y)];
    }
    for (0..5) |y| {
        state[lane(0, y)] ^= ~state[lane(1, y)] & state[lane(2, y)];
        state[lane(1, y)] ^= ~state[lane(2, y)] & state[lane(3, y)];
        state[lane(2, y)] ^= ~state[lane(3, y)] & state[lane(4, y)];
        state[lane(3, y)] ^= ~state[lane(4, y)] & first[y];
        state[lane(4, y)] ^= ~first[y] & second[y];
    }
}

const round_constants = [24]u64{
    0x0000000000000001, 0x0000000000008082, 0x800000000000808a,
    0x8000000080008000, 0x000000000000808b, 0x0000000080000001,
    0x8000000080008081, 0x8000000000008009, 0x000000000000008a,
    0x0000000000000088, 0x0000000080008009, 0x000000008000000a,
    0x000000008000808b, 0x800000000000008b, 0x8000000000008089,
    0x8000000000008003, 0x8000000000008002, 0x8000000000000080,
    0x000000000000800a, 0x800000008000000a, 0x8000000080008081,
    0x8000000000008080, 0x0000000080000001, 0x8000000080008008,
};

fn keccakPermutation(state: *[25]u64) void {
    for (round_constants) |round_constant| {
        theta(state);
        rho(state);
        pi(state);
        chi(state);
        state[0] ^= round_constant;
    }
}

pub fn keccakf(state: [*]u64) callconv(.c) void {
    keccakPermutation(state[0..25]);
}

pub fn jent_sha3_init(ctx: *ShaCtx) callconv(.c) void {
    @memset(&ctx.state, 0);
    ctx.msg_len = 0;
}

pub fn jent_sha3_256_init(ctx: *ShaCtx) callconv(.c) void {
    jent_sha3_init(ctx);
    ctx.r = rate;
    ctx.rword = rate / @sizeOf(u64);
    ctx.digestsize = digest_size;
    ctx.padding = 0x06;
}

pub fn jent_shake256_init(ctx: *ShaCtx) callconv(.c) void {
    jent_sha3_init(ctx);
    ctx.r = rate;
    ctx.rword = rate / @sizeOf(u64);
    ctx.digestsize = 0;
    ctx.padding = 0x1f;
    ctx.setInitiallySeeded(0);
}

fn fillState(ctx: *ShaCtx, input: [*]const u8) void {
    var offset: usize = 0;
    var i: usize = 0;
    while (i < ctx.rword) : (i += 1) {
        ctx.state[i] ^= loadLe64(input + offset);
        offset += 8;
    }
}

pub fn jent_sha3_update(ctx: *ShaCtx, input: [*]const u8, input_len_arg: usize) callconv(.c) void {
    var in = input;
    var input_len = input_len_arg;
    const partial = ctx.msg_len % ctx.r;
    ctx.msg_len +%= input_len;

    if (partial != 0) {
        const todo = ctx.r - partial;
        if (input_len < todo) {
            std.mem.copyForwards(u8, ctx.partial[partial .. partial + input_len], in[0..input_len]);
            return;
        }
        std.mem.copyForwards(u8, ctx.partial[partial .. partial + todo], in[0..todo]);
        input_len -= todo;
        in += todo;
        fillState(ctx, &ctx.partial);
        keccakPermutation(&ctx.state);
    }

    while (input_len >= ctx.r) {
        fillState(ctx, in);
        keccakPermutation(&ctx.state);
        input_len -= ctx.r;
        in += ctx.r;
    }
    std.mem.copyForwards(u8, ctx.partial[0..input_len], in[0..input_len]);
}

pub fn jent_sha3_final(ctx: *ShaCtx, digest: [*]u8) callconv(.c) void {
    const partial = ctx.msg_len % ctx.r;
    @memset(ctx.partial[partial..ctx.r], 0);
    ctx.partial[partial] = ctx.padding;
    ctx.partial[ctx.r - 1] |= 0x80;

    fillState(ctx, &ctx.partial);
    keccakPermutation(&ctx.state);

    var out = digest;
    var i: usize = 0;
    while (i < ctx.digestsize / 8) : (i += 1) {
        storeLe64(out, ctx.state[i]);
        out += 8;
    }

    @memset(ctx.partial[0..ctx.r], 0);
    jent_sha3_init(ctx);
}

fn xdrbgGenerateBlock(ctx: *ShaCtx, destination: [*]u8, destination_len_arg: usize) void {
    const block = &ctx.xdrbg_block;

    var encode: u8 = @as(u8, ctx.initiallySeeded()) * 85;
    ctx.setInitiallySeeded(1);
    jent_sha3_update(ctx, @ptrCast(&encode), 1);
    internal.jent_shake256_set_digestsize(ctx, xdrbg_state_size);
    jent_sha3_final(ctx, block);

    jent_sha3_update(ctx, block, xdrbg_state_size);
    encode = 2 * 85;
    jent_sha3_update(ctx, @ptrCast(&encode), 1);
    internal.jent_shake256_set_digestsize(ctx, block.len);
    jent_sha3_final(ctx, block);

    var destination_len = destination_len_arg;
    if (destination_len != 0) {
        destination_len = @min(destination_len, digest_size);
        std.mem.copyForwards(
            u8,
            destination[0..destination_len],
            block[xdrbg_state_size .. xdrbg_state_size + destination_len],
        );
    }

    jent_sha3_update(ctx, block, xdrbg_state_size);
    internal.jent_memset_secure(block, block.len);
}

pub fn jent_drbg_generate_block(ctx: *ShaCtx, destination: [*]u8, destination_len: usize) callconv(.c) void {
    xdrbgGenerateBlock(ctx, destination, destination_len);
}

fn shake256Tester() c_int {
    const message = [_]u8{
        0x6c, 0x9e, 0xc8, 0x5c, 0xba, 0xba, 0x62, 0xf5,
        0xbc, 0xfe, 0xa1, 0x9e, 0xb9, 0xc9, 0x20, 0x52,
        0xd8, 0xff, 0x18, 0x81, 0x52, 0xe9, 0x61, 0xc1,
        0xec, 0x5c, 0x75, 0xbf, 0xc3, 0xc9, 0x1c, 0x8d,
    };
    const expected = [_]u8{
        0x7d, 0x6a, 0x09, 0x6e, 0x13, 0x66, 0x1d, 0x9d,
        0x0e, 0xca, 0xf5, 0x38, 0x30, 0xa1, 0x92, 0x87,
        0xe0, 0xb3, 0x6e, 0xce, 0x48, 0x82, 0xeb, 0x58,
        0x0b, 0x78, 0x5c, 0x1d, 0xef, 0x2d, 0xe5, 0xaa,
    };
    var actual: [expected.len]u8 = @splat(0);
    var ctx: ShaCtx = .{};
    jent_shake256_init(&ctx);
    jent_sha3_update(&ctx, &message, message.len);
    internal.jent_shake256_set_digestsize(&ctx, expected.len);
    jent_sha3_final(&ctx, &actual);
    return if (std.mem.eql(u8, &actual, &expected)) 0 else 1;
}

fn xdrbg256Tester() c_int {
    const seed = [_]u8{ 0, 1, 2, 3, 4, 5, 6, 7, 8 };
    const expected = [_]u8{
        0x51, 0xe4, 0x3c, 0xf6, 0x4b, 0xa2, 0x80, 0x77,
        0x33, 0x1a, 0x47, 0xe3, 0xf8, 0xb4, 0x1a, 0x42,
        0xad, 0xd3, 0xa0, 0xf2, 0x53, 0x97, 0x10, 0xdd,
        0x6e, 0xa1, 0x16, 0x1d, 0x37, 0x8a, 0x6f, 0xb6,
    };
    var actual: [expected.len]u8 = @splat(0);
    var ctx: ShaCtx = .{};
    jent_shake256_init(&ctx);
    jent_sha3_update(&ctx, &seed, seed.len);
    xdrbgGenerateBlock(&ctx, &actual, actual.len);
    jent_sha3_update(&ctx, &seed, seed.len);
    xdrbgGenerateBlock(&ctx, &actual, actual.len);
    return if (std.mem.eql(u8, &actual, &expected)) 0 else 1;
}

fn sha3MultiblockTester() c_int {
    const chunks = [_]usize{ 1, 140, 300 };
    const expected = [_]u8{
        0xc5, 0xe3, 0x16, 0x92, 0x0a, 0x0d, 0x7e, 0x5d,
        0x6c, 0x84, 0x4c, 0x52, 0x9c, 0xa8, 0x82, 0x18,
        0x8a, 0xb2, 0x29, 0x9d, 0xa5, 0xed, 0x65, 0x0d,
        0xc6, 0x16, 0xf0, 0xd4, 0xa3, 0x72, 0x2e, 0x02,
    };
    var message: [300]u8 = undefined;
    for (&message, 0..) |*byte, i| byte.* = @truncate(i);
    var actual: [expected.len]u8 = @splat(0);
    var ctx: ShaCtx = .{};
    jent_sha3_256_init(&ctx);
    for (chunks) |chunk| jent_sha3_update(&ctx, &message, chunk);
    jent_sha3_final(&ctx, &actual);
    return if (std.mem.eql(u8, &actual, &expected)) 0 else 1;
}

pub fn jent_sha3_tester() callconv(.c) c_int {
    if (sha3MultiblockTester() != 0) return 1;
    if (shake256Tester() != 0) return 1;
    return xdrbg256Tester();
}
