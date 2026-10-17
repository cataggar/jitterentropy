pub const internal_timer = false;
pub const mock_timer = false;
pub const raw_memory_access = false;
pub const stack_protector = false;
pub const linkage = @import("std").builtin.LinkMode.static;
pub const external_crypto = enum { none, awslc, openssl, libgcrypt }.none;
pub const aarch64_nstime_register: ?[]const u8 = null;
pub const is_linux_kernel = true;
