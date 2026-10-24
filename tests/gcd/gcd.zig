const std = @import("std");
const jent = @import("jent");

fn trapPanic(_: []const u8, _: ?usize) noreturn {
    @trap();
}
pub const panic = std.debug.FullPanic(trapPanic);

const elements: usize = 1000;
const expected_gcd: u64 = 50;

pub fn main() u8 {
    const history = jent.jent_gcd_init(elements, 0) orelse return 4;
    defer jent.jent_gcd_fini(history, elements);

    for (0..elements) |i| history[i] = i * expected_gcd;
    if (jent.jent_gcd_analyze(history, elements, jent.JENT_MIN_OSR, jent.JENT_GCD_CLOCK_PLATFORM) != 0)
        return 1;

    var value: u64 = 0;
    if (jent.jent_gcd_get(&value, jent.JENT_GCD_CLOCK_PLATFORM) != 0) return 2;
    return if (value == expected_gcd) 0 else 3;
}
