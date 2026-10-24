const internal = @import("internal.zig");
const memory = @import("arch/memory.zig");

var uuid_counter: u32 = 0;
const hex = "0123456789abcdef";

pub fn jent_uuid_format(bytes: [*]const u8, output: [*]u8) callconv(.c) void {
    var j: usize = 0;
    for (0..16) |i| {
        if (i == 4 or i == 6 or i == 8 or i == 10) {
            output[j] = '-';
            j += 1;
        }
        output[j] = hex[bytes[i] >> 4];
        output[j + 1] = hex[bytes[i] & 0x0f];
        j += 2;
    }
    output[j] = 0;
}

pub fn jent_uuid_from_counter(bytes: [*]u8) callconv(.c) void {
    var ctx: internal.jent_sha_ctx = .{};
    var digest: [internal.JENT_SHA3_256_SIZE_DIGEST]u8 = undefined;
    var input: [12]u8 = undefined;
    const value = internal.jent_atomic_inc_u32(&uuid_counter);
    var now: u64 = 0;
    internal.jent_get_nstime(&now);

    for (0..4) |i| input[i] = @truncate(value >> @intCast(8 * i));
    for (0..8) |i| input[4 + i] = @truncate(now >> @intCast(8 * i));

    internal.jent_sha3_256_init(&ctx);
    internal.jent_sha3_update(&ctx, &input, input.len);
    internal.jent_sha3_final(&ctx, &digest);
    @memcpy(bytes[0..16], digest[0..16]);
    bytes[6] = (bytes[6] & 0x0f) | 0x80;

    internal.jent_memset_secure(&ctx, internal.JENT_SHA_MAX_CTX_SIZE);
    internal.jent_memset_secure(&digest, digest.len);
}

pub fn jent_uuid_generate(output: [*]u8) callconv(.c) void {
    var bytes: [16]u8 = undefined;
    defer memory.jent_memset_secure(&bytes, bytes.len);
    if (internal.jent_os_random_bytes(&bytes, bytes.len) != 0) {
        jent_uuid_from_counter(&bytes);
    } else {
        bytes[6] = (bytes[6] & 0x0f) | 0x40;
    }
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    jent_uuid_format(&bytes, output);
}
