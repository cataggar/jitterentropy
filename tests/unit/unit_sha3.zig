const std = @import("std");
const jent = @import("jent");

var checks: usize = 0;
var failures: usize = 0;

fn expect(condition: bool, comptime message: []const u8) void {
    checks += 1;
    if (!condition) {
        failures += 1;
        std.debug.print("  FAILED: {s}\n", .{message});
    }
}

fn hash(input: []const u8) [jent.JENT_SHA3_256_SIZE_DIGEST]u8 {
    var ctx: jent.jent_sha_ctx = .{};
    var output: [jent.JENT_SHA3_256_SIZE_DIGEST]u8 = undefined;
    jent.jent_sha3_256_init(&ctx);
    jent.jent_sha3_update(&ctx, input.ptr, input.len);
    jent.jent_sha3_final(&ctx, &output);
    return output;
}

fn testKnownAnswers() void {
    const empty_expected = [_]u8{
        0xa7, 0xff, 0xc6, 0xf8, 0xbf, 0x1e, 0xd7, 0x66,
        0x51, 0xc1, 0x47, 0x56, 0xa0, 0x61, 0xd6, 0x62,
        0xf5, 0x80, 0xff, 0x4d, 0xe4, 0x3b, 0x49, 0xfa,
        0x82, 0xd8, 0x0a, 0x4b, 0x80, 0xf8, 0x43, 0x4a,
    };
    const abc_expected = [_]u8{
        0x3a, 0x98, 0x5d, 0xa7, 0x4f, 0xe2, 0x25, 0xb2,
        0x04, 0x5c, 0x17, 0x2d, 0x6b, 0xd3, 0x90, 0xbd,
        0x85, 0x5f, 0x08, 0x6e, 0x3e, 0x9d, 0x52, 0x5b,
        0x46, 0xbf, 0xe2, 0x45, 0x11, 0x43, 0x15, 0x32,
    };
    expect(jent.jent_sha3_tester() == 0, "SHA-3 / XDRBG self-test");
    expect(std.mem.eql(u8, &hash(""), &empty_expected), "SHA3-256 empty-message vector");
    expect(std.mem.eql(u8, &hash("abc"), &abc_expected), "SHA3-256 abc vector");
}

fn testIncremental() void {
    var message: [3 * jent.JENT_SHA3_256_SIZE_BLOCK + 7]u8 = undefined;
    for (&message, 0..) |*byte, i| byte.* = @truncate(i);
    const expected = hash(&message);
    const chunks = [_]usize{ 1, jent.JENT_SHA3_256_SIZE_BLOCK - 1, jent.JENT_SHA3_256_SIZE_BLOCK, jent.JENT_SHA3_256_SIZE_BLOCK + 1 };

    for (chunks) |chunk| {
        var ctx: jent.jent_sha_ctx = .{};
        var actual: [jent.JENT_SHA3_256_SIZE_DIGEST]u8 = undefined;
        jent.jent_sha3_256_init(&ctx);
        var offset: usize = 0;
        while (offset < message.len) : (offset += chunk) {
            const len = @min(chunk, message.len - offset);
            jent.jent_sha3_update(&ctx, message[offset..].ptr, len);
        }
        jent.jent_sha3_final(&ctx, &actual);
        expect(std.mem.eql(u8, &actual, &expected), "incremental SHA3-256 equals one-shot");
    }

    var ctx: jent.jent_sha_ctx = .{};
    var actual: [jent.JENT_SHA3_256_SIZE_DIGEST]u8 = undefined;
    jent.jent_sha3_256_init(&ctx);
    jent.jent_sha3_update(&ctx, &message, 0);
    jent.jent_sha3_update(&ctx, &message, message.len);
    jent.jent_sha3_update(&ctx, &message, 0);
    jent.jent_sha3_final(&ctx, &actual);
    expect(std.mem.eql(u8, &actual, &expected), "zero-length updates are no-ops");
}

fn testShakeAndDrbg() void {
    var a: [128]u8 = undefined;
    var b: [128]u8 = undefined;
    var ctx: jent.jent_sha_ctx = .{};

    jent.jent_shake256_init(&ctx);
    jent.jent_shake256_set_digestsize(&ctx, a.len);
    jent.jent_sha3_update(&ctx, "seed", 4);
    jent.jent_sha3_final(&ctx, &a);

    jent.jent_shake256_init(&ctx);
    jent.jent_shake256_set_digestsize(&ctx, b.len);
    jent.jent_sha3_update(&ctx, "seed", 4);
    jent.jent_sha3_final(&ctx, &b);
    expect(std.mem.eql(u8, &a, &b), "SHAKE256 is deterministic");

    jent.jent_shake256_init(&ctx);
    jent.jent_shake256_set_digestsize(&ctx, b.len);
    jent.jent_sha3_update(&ctx, "seeD", 4);
    jent.jent_sha3_final(&ctx, &b);
    expect(!std.mem.eql(u8, &a, &b), "different SHAKE256 inputs differ");

    @memset(&a, 0xcc);
    jent.jent_shake256_init(&ctx);
    jent.jent_sha3_update(&ctx, "seed", 4);
    jent.jent_drbg_generate_block(&ctx, &a, a.len);
    expect(!std.mem.allEqual(u8, a[0..jent.JENT_SHA3_256_SIZE_DIGEST], 0xcc), "DRBG writes a digest");
    expect(std.mem.allEqual(u8, a[jent.JENT_SHA3_256_SIZE_DIGEST..], 0xcc), "DRBG clamps output to one digest");

    @memset(&a, 0);
    jent.jent_shake256_init(&ctx);
    jent.jent_sha3_update(&ctx, "seed", 4);
    jent.jent_drbg_generate_block(&ctx, &a, 17);
    expect(!std.mem.allEqual(u8, a[0..17], 0), "DRBG writes requested short output");
    expect(std.mem.allEqual(u8, a[17..], 0), "DRBG does not write past requested output");
}

pub fn main() u8 {
    testKnownAnswers();
    testIncremental();
    testShakeAndDrbg();

    var ctx: jent.jent_sha_ctx = .{};
    jent.jent_sha3_256_init(&ctx);
    expect(jent.jent_sha3_rate(&ctx) == jent.JENT_SHA3_256_SIZE_BLOCK, "SHA3-256 rate");

    std.debug.print("unit-sha3: {d} checks, {d} failed\n", .{ checks, failures });
    return if (failures == 0) 0 else 1;
}
