// SPDX-License-Identifier: GPL-2.0 OR BSD-2-Clause

const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const internal = @import("../internal.zig");

const root = @import("root");
const is_linux_kernel = @hasDecl(root, "is_linux_kernel") and root.is_linux_kernel;
const external_crypto = build_options.external_crypto;
const use_openssl = external_crypto == .openssl;
const use_awslc = external_crypto == .awslc;
const use_libgcrypt = external_crypto == .libgcrypt;
const use_windows = !use_openssl and !use_awslc and !use_libgcrypt and builtin.os.tag == .windows;
const use_posix = !use_openssl and !use_awslc and !use_libgcrypt and switch (builtin.os.tag) {
    .linux, .macos, .freebsd, .netbsd, .openbsd, .dragonfly => true,
    else => false,
};

extern "c" fn CRYPTO_secure_malloc_init(sz: usize, minsize: usize) c_int;
extern "c" fn CRYPTO_secure_malloc_done() c_int;
extern "c" fn CRYPTO_secure_zalloc(
    length: usize,
    file: [*:0]const u8,
    line: c_int,
) ?*anyopaque;
extern "c" fn CRYPTO_secure_clear_free(
    ptr: ?*anyopaque,
    length: usize,
    file: [*:0]const u8,
    line: c_int,
) void;
extern "c" fn CRYPTO_clear_free(
    ptr: ?*anyopaque,
    length: usize,
    file: [*:0]const u8,
    line: c_int,
) void;
extern "c" fn CRYPTO_secure_malloc_initialized() c_int;
extern "c" fn CRYPTO_secure_allocated(ptr: ?*const anyopaque) c_int;
extern "c" fn CRYPTO_zalloc(
    length: usize,
    file: [*:0]const u8,
    line: c_int,
) ?*anyopaque;
extern "c" fn ERR_set_mark() c_int;
extern "c" fn ERR_pop_to_mark() c_int;
extern "c" fn OPENSSL_malloc(size: usize) ?*anyopaque;
extern "c" fn OPENSSL_free(ptr: ?*anyopaque) void;
extern "c" fn gcry_check_version(req_version: ?[*:0]const u8) ?[*:0]const u8;
extern "c" fn gcry_control(cmd: c_uint, ...) c_int;
extern "c" fn gcry_is_secure(a: ?*const anyopaque) c_int;
extern "c" fn gcry_calloc_secure(count: usize, length: usize) ?*anyopaque;
extern "c" fn gcry_calloc(count: usize, length: usize) ?*anyopaque;
extern "c" fn gcry_free(ptr: ?*anyopaque) void;

const PAGE_NOACCESS: u32 = 0x01;
const PAGE_READWRITE: u32 = 0x04;
const MEM_COMMIT: u32 = 0x1000;
const MEM_RESERVE: u32 = 0x2000;
const MEM_RELEASE: u32 = 0x8000;

const SystemInfo = extern struct {
    processor_architecture: u16,
    reserved: u16,
    page_size: u32,
    minimum_application_address: ?*anyopaque,
    maximum_application_address: ?*anyopaque,
    active_processor_mask: usize,
    number_of_processors: u32,
    processor_type: u32,
    allocation_granularity: u32,
    processor_level: u16,
    processor_revision: u16,
};

extern "kernel32" fn GetSystemInfo(system_info: *SystemInfo) callconv(.winapi) void;
extern "kernel32" fn VirtualAlloc(
    address: ?*anyopaque,
    size: usize,
    allocation_type: u32,
    protect: u32,
) callconv(.winapi) ?*anyopaque;
extern "kernel32" fn VirtualProtect(
    address: *anyopaque,
    size: usize,
    new_protect: u32,
    old_protect: *u32,
) callconv(.winapi) i32;
extern "kernel32" fn VirtualLock(address: *anyopaque, size: usize) callconv(.winapi) i32;
extern "kernel32" fn VirtualUnlock(address: *anyopaque, size: usize) callconv(.winapi) i32;
extern "kernel32" fn VirtualFree(
    address: *anyopaque,
    size: usize,
    free_type: u32,
) callconv(.winapi) i32;

const SysconfName = if (use_posix) std.c._SC else c_int;
extern "c" fn sysconf(name: SysconfName) c_long;
extern "c" fn mmap(
    address: ?*anyopaque,
    length: usize,
    protection: c_int,
    flags: c_int,
    fd: c_int,
    offset: isize,
) ?*anyopaque;
extern "c" fn mprotect(address: *anyopaque, length: usize, protection: c_int) c_int;
extern "c" fn mlock(address: *const anyopaque, length: usize) c_int;
extern "c" fn munlock(address: *const anyopaque, length: usize) c_int;
extern "c" fn madvise(address: *anyopaque, length: usize, advice: c_int) c_int;
extern "c" fn munmap(address: *anyopaque, length: usize) c_int;
extern fn malloc(length: usize) ?*anyopaque;
extern "c" fn calloc(count: usize, length: usize) ?*anyopaque;
extern fn free(address: ?*anyopaque) void;
extern fn jent_kshim_kvzalloc(length: usize) callconv(.c) ?*anyopaque;
extern fn jent_kshim_kvfree_sensitive(address: ?*anyopaque, length: usize) callconv(.c) void;

const PROT_NONE: c_int = 0;
const PROT_READ: c_int = 1;
const PROT_WRITE: c_int = 2;
const MAP_PRIVATE: c_int = 2;
const MAP_ANONYMOUS: c_int = if (builtin.os.tag == .linux) 0x20 else 0x1000;
const MADV_DONTDUMP: c_int = 16;
const MADV_NOCORE: c_int = 17;
const EAGAIN: c_int = if (builtin.os.tag == .linux) 11 else 35;
const EPERM: c_int = 1;
const ENOMEM: c_int = 12;
const ENOSYS: c_int = if (builtin.os.tag == .linux) 38 else 78;

pub var jent_fi_fail_alloc: c_uint = 0;
pub var jent_fi_alloc_count: c_uint = 0;
pub var jent_fi_fail_mmap: c_int = 0;
pub var jent_fi_fail_mprotect: c_int = 0;
pub var jent_fi_mprotect_calls: c_uint = 0;
pub var jent_fi_fail_mlock: c_int = 0;
pub var jent_fi_mlock_errno: c_int = 1;
pub var jent_fi_sysconf_mode: c_int = 0;

pub const ZeroizeInspectHook = *const fn (
    base: ?*const anyopaque,
    size: usize,
) callconv(.c) void;

pub var jent_zeroize_inspect_hook: ?ZeroizeInspectHook = null;

pub fn jent_secure_memzero(ptr: ?*anyopaque, len: usize) callconv(.c) void {
    if (len != 0) {
        const bytes = @as([*]volatile u8, @ptrCast(ptr.?))[0..len];
        @memset(bytes, 0);
    }
    asm volatile (""
        :
        : [ptr] "r" (ptr),
        : .{ .memory = true });
}

pub fn jent_memset_secure(ptr: ?*anyopaque, len: usize) callconv(.c) void {
    jent_secure_memzero(ptr, len);
}

pub fn jent_secure_memory_supported() callconv(.c) c_int {
    return 1;
}

pub fn jent_memory_is_secure(flags: c_uint) callconv(.c) c_int {
    _ = flags;
    return 1;
}

pub fn jent_memory_backend_name() callconv(.c) [*:0]const u8 {
    if (is_linux_kernel) return "linux-kernel";
    if (external_crypto == .libgcrypt) return "libgcrypt";
    if (external_crypto == .awslc) return "aws-lc";
    if (external_crypto == .openssl) return "openssl";
    if (use_windows) return "windows-virtuallock";
    if (use_posix) return "posix-mlock";
    if (builtin.os.tag == .freestanding or builtin.os.tag == .uefi) return "baremetal";
    return "malloc";
}

pub fn jent_pagesize() callconv(.c) usize {
    if (jent_fi_sysconf_mode == 1 or jent_fi_sysconf_mode == 2) return 4096;
    if (use_windows) {
        var system_info: SystemInfo = undefined;
        GetSystemInfo(&system_info);
        return if (system_info.page_size == 0) 4096 else system_info.page_size;
    }
    if (use_posix) {
        const page_size = sysconf(.PAGESIZE);
        return if (page_size <= 0) 4096 else @intCast(page_size);
    }
    return 4096;
}

fn roundedLayout(len: usize) ?struct { payload: usize, total: usize } {
    const page_size = jent_pagesize();
    if (len > std.math.maxInt(usize) - 3 * page_size) return null;
    const payload = (len + page_size - 1) & ~(page_size - 1);
    return .{ .payload = payload, .total = payload + 2 * page_size };
}

fn ptrAdd(ptr: *anyopaque, offset: usize) *anyopaque {
    return @ptrFromInt(@intFromPtr(ptr) + offset);
}

fn ptrSub(ptr: *anyopaque, offset: usize) *anyopaque {
    return @ptrFromInt(@intFromPtr(ptr) - offset);
}

fn injectedMprotect(address: *anyopaque, length: usize, protection: c_int) bool {
    const call_num = @atomicRmw(c_uint, &jent_fi_mprotect_calls, .Add, 1, .monotonic) +% 1;
    const fail_mprotect = @atomicLoad(c_int, &jent_fi_fail_mprotect, .monotonic);
    if (fail_mprotect != 0 and
        @as(c_uint, @intCast(fail_mprotect)) == call_num)
    {
        return false;
    }
    return mprotect(address, length, protection) == 0;
}

fn injectedMlock(address: *anyopaque, length: usize) struct { ok: bool, err: c_int } {
    if (jent_fi_fail_mlock != 0) {
        return .{ .ok = false, .err = jent_fi_mlock_errno };
    }
    const rc = mlock(address, length);
    const err = if (rc == 0) 0 else switch (std.c.errno(rc)) {
        .PERM => EPERM,
        .NOMEM => ENOMEM,
        .AGAIN => EAGAIN,
        .NOSYS => ENOSYS,
        else => 22,
    };
    return .{
        .ok = rc == 0,
        .err = err,
    };
}

fn lockFailureIsTolerable(err: c_int) bool {
    return err == EPERM or err == ENOMEM or err == EAGAIN or err == ENOSYS;
}

pub fn jent_init_test_secure_memory() callconv(.c) void {
    if (use_openssl) {
        if (CRYPTO_secure_malloc_initialized() == 0) {
            const ret = CRYPTO_secure_malloc_init(2 << 20, 32);
            if (ret == 2) {
                _ = CRYPTO_secure_malloc_done();
            }
        }
    } else if (use_libgcrypt) {
        const GCRYCTL_INITIALIZATION_FINISHED: c_uint = 19;
        const GCRYCTL_INIT_SECMEM: c_uint = 24;
        const GCRYCTL_SUSPEND_SECMEM_WARN: c_uint = 28;
        const GCRYCTL_RESUME_SECMEM_WARN: c_uint = 29;
        const GCRYCTL_INITIALIZATION_FINISHED_P: c_uint = 39;
        if (gcry_control(GCRYCTL_INITIALIZATION_FINISHED_P, @as(c_int, 0)) == 0) {
            if (gcry_check_version(null) != null) {
                _ = gcry_control(GCRYCTL_SUSPEND_SECMEM_WARN);
                _ = gcry_control(GCRYCTL_INIT_SECMEM, @as(usize, 2 << 20), @as(c_int, 0));
                _ = gcry_control(GCRYCTL_RESUME_SECMEM_WARN);
                _ = gcry_control(GCRYCTL_INITIALIZATION_FINISHED, @as(c_int, 0));
            }
        }
    }
}

fn allocCommon(len: usize, flags: c_uint, secure: bool) ?*anyopaque {
    if (len > std.math.maxInt(usize) / 2) return null;
    var result: ?*anyopaque = null;

    if (use_libgcrypt) {
        const GCRYCTL_INITIALIZATION_FINISHED_P: c_uint = 39;
        if (secure and gcry_control(GCRYCTL_INITIALIZATION_FINISHED_P, @as(c_int, 0)) != 0) {
            result = gcry_calloc_secure(1, len);
            if (result != null and gcry_is_secure(result) == 0) {
                gcry_free(result);
                result = null;
            }
        }
        if (result == null and (!secure or (flags & internal.JENT_FORCE_SECURE_MEM) == 0)) {
            result = gcry_calloc(1, len);
        }
    } else if (use_awslc) {
        result = OPENSSL_malloc(len);
    } else if (use_openssl) {
        if (secure and CRYPTO_secure_malloc_initialized() != 0) {
            _ = ERR_set_mark();
            result = CRYPTO_secure_zalloc(len, "src/arch/memory.zig", 0);
            _ = ERR_pop_to_mark();
            if (result != null and CRYPTO_secure_allocated(result) == 0) {
                CRYPTO_secure_clear_free(result, len, "src/arch/memory.zig", 0);
                result = null;
            }
        }
        if (result == null and (!secure or (flags & internal.JENT_FORCE_SECURE_MEM) == 0)) {
            result = CRYPTO_zalloc(len, "src/arch/memory.zig", 0);
        }
    } else if (use_windows) {
        const layout = roundedLayout(len) orelse return null;
        if (jent_fi_fail_mmap != 0) return null;
        const base = VirtualAlloc(
            null,
            layout.total,
            MEM_COMMIT | MEM_RESERVE,
            PAGE_NOACCESS,
        ) orelse return null;

        const call_num = @atomicRmw(c_uint, &jent_fi_mprotect_calls, .Add, 1, .monotonic) +% 1;
        const fail_mprotect = @atomicLoad(c_int, &jent_fi_fail_mprotect, .monotonic);
        if (fail_mprotect != 0 and
            @as(c_uint, @intCast(fail_mprotect)) == call_num)
        {
            _ = VirtualFree(base, 0, MEM_RELEASE);
            return null;
        }

        const payload_ptr = ptrAdd(base, jent_pagesize());
        var old_protection: u32 = 0;
        if (VirtualProtect(payload_ptr, layout.payload, PAGE_READWRITE, &old_protection) == 0) {
            _ = VirtualFree(base, 0, MEM_RELEASE);
            return null;
        }
        if (secure) {
            const locked = if (jent_fi_fail_mlock != 0) 0 else VirtualLock(payload_ptr, layout.payload);
            if (locked == 0 and (flags & internal.JENT_FORCE_SECURE_MEM) != 0) {
                _ = VirtualFree(base, 0, MEM_RELEASE);
                return null;
            }
        }
        result = payload_ptr;
    } else if (use_posix) {
        const layout = roundedLayout(len) orelse return null;
        if (jent_fi_fail_mmap != 0) return null;
        const mapped = mmap(
            null,
            layout.total,
            PROT_READ | PROT_WRITE,
            MAP_PRIVATE | MAP_ANONYMOUS,
            -1,
            0,
        ) orelse return null;
        if (@intFromPtr(mapped) == std.math.maxInt(usize)) return null;

        const page_size = jent_pagesize();
        if (!injectedMprotect(mapped, page_size, PROT_NONE) or
            !injectedMprotect(ptrAdd(mapped, page_size + layout.payload), page_size, PROT_NONE))
        {
            _ = munmap(mapped, layout.total);
            return null;
        }

        const payload_ptr = ptrAdd(mapped, page_size);
        if (builtin.os.tag == .linux) {
            _ = madvise(payload_ptr, len, MADV_DONTDUMP);
        } else if (builtin.os.tag == .freebsd) {
            _ = madvise(payload_ptr, len, MADV_NOCORE);
        }

        if (secure) {
            const locked = injectedMlock(payload_ptr, len);
            if (!locked.ok and
                ((flags & internal.JENT_FORCE_SECURE_MEM) != 0 or
                    !lockFailureIsTolerable(locked.err)))
            {
                _ = munmap(mapped, layout.total);
                return null;
            }
        }
        result = payload_ptr;
    } else if (is_linux_kernel) {
        result = jent_kshim_kvzalloc(len);
    } else if (builtin.os.tag == .freestanding or builtin.os.tag == .uefi) {
        result = malloc(len);
    } else {
        result = calloc(1, len);
    }

    if (result) |ptr| jent_secure_memzero(ptr, len);
    return result;
}

pub fn jent_fi_real_zalloc(len: usize, flags: c_uint) callconv(.c) ?*anyopaque {
    return allocCommon(len, flags, true);
}

pub fn jent_zalloc(len: usize, flags: c_uint) callconv(.c) ?*anyopaque {
    const count = @atomicRmw(c_uint, &jent_fi_alloc_count, .Add, 1, .monotonic) +% 1;
    const fail_alloc = @atomicLoad(c_uint, &jent_fi_fail_alloc, .monotonic);
    if (fail_alloc != 0 and count == fail_alloc) {
        return null;
    }
    return jent_fi_real_zalloc(len, flags);
}

pub fn jent_zalloc_unlocked(len: usize) callconv(.c) ?*anyopaque {
    return allocCommon(len, 0, false);
}

fn inspectBeforeRelease(ptr: *anyopaque, len: usize) void {
    if (jent_zeroize_inspect_hook) |hook| hook(ptr, len);
}

pub fn jent_zfree(optional_ptr: ?*anyopaque, len: usize) callconv(.c) void {
    const ptr = optional_ptr orelse return;
    jent_secure_memzero(ptr, len);

    if (is_linux_kernel) {
        inspectBeforeRelease(ptr, len);
        jent_kshim_kvfree_sensitive(ptr, len);
    } else if (use_libgcrypt) {
        inspectBeforeRelease(ptr, len);
        gcry_free(ptr);
    } else if (use_awslc) {
        inspectBeforeRelease(ptr, len);
        OPENSSL_free(ptr);
    } else if (use_openssl) {
        inspectBeforeRelease(ptr, len);
        if (CRYPTO_secure_allocated(ptr) != 0) {
            CRYPTO_secure_clear_free(ptr, len, "src/arch/memory.zig", 0);
        } else {
            CRYPTO_clear_free(ptr, len, "src/arch/memory.zig", 0);
        }
    } else if (use_windows) {
        const layout = roundedLayout(len) orelse return;
        const base = ptrSub(ptr, jent_pagesize());
        _ = VirtualUnlock(ptr, layout.payload);
        inspectBeforeRelease(ptr, len);
        _ = VirtualFree(base, 0, MEM_RELEASE);
    } else if (use_posix) {
        const layout = roundedLayout(len) orelse return;
        const base = ptrSub(ptr, jent_pagesize());
        _ = munlock(ptr, len);
        inspectBeforeRelease(ptr, len);
        _ = munmap(base, layout.total);
    } else {
        inspectBeforeRelease(ptr, len);
        free(ptr);
    }
}
