pub const is_linux_kernel = true;

comptime {
    _ = @import("base.zig");
    _ = @import("gcd.zig");
    _ = @import("health.zig");
    _ = @import("noise.zig");
    _ = @import("sha3.zig");
    _ = @import("status.zig");
    _ = @import("timer.zig");
    _ = @import("uuid.zig");
    _ = @import("arch/atomic.zig");
    _ = @import("arch/cache.zig");
    _ = @import("arch/fips.zig");
    _ = @import("arch/memory.zig");
    _ = @import("arch/ncpu.zig");
    _ = @import("arch/random.zig");
    _ = @import("arch/sched.zig");
    _ = @import("arch/timer.zig");
    _ = @import("kmod_core");
}
