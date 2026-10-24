pub const internal = @import("internal.zig");
pub const gcd = @import("gcd.zig");

comptime {
    _ = gcd.jent_common_timer_gcd;
    _ = gcd.jent_gcd64;
    _ = gcd.jent_gcd_analyze_internal;
    _ = gcd.jent_gcd_verdict;
    _ = gcd.jent_gcd_store;
    _ = gcd.jent_gcd_analyze;
    _ = gcd.jent_gcd_init;
    _ = gcd.jent_gcd_fini;
    _ = gcd.jent_gcd_get;
    _ = gcd.jent_gcd_selftest;
}
