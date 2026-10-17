// SPDX-License-Identifier: BSD-3-Clause OR GPL-2.0-only

const harness = @import("test_harness.zig");

extern fn jent_fips_enabled() callconv(.c) c_int;
extern var jent_fi_force_fips_enabled: c_int;

pub fn main() void {
    harness.resetCounters();

    const enabled = jent_fips_enabled();
    harness.expectOrExit(
        enabled == 0 or enabled == 1,
        @src(),
        "the FIPS answer is 0 or 1",
        .{},
    );

    const saved = jent_fi_force_fips_enabled;
    defer jent_fi_force_fips_enabled = saved;
    jent_fi_force_fips_enabled = 1;
    harness.expectOrExit(
        jent_fips_enabled() == 1,
        @src(),
        "the fault-injection hook forces FIPS mode",
        .{},
    );

    harness.pass("unit-arch-fips");
}
