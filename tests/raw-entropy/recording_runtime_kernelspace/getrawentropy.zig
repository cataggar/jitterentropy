// Copyright (C) 2019 - 2026, Stephan Mueller <smueller@chronox.de>
//
// License: see LICENSE file in root directory

const std = @import("std");
const builtin = @import("builtin");
const linux = std.os.linux;

const RAWENTROPY_SAMPLES: usize = 1001;
const DEBUGFS_INTERFACE: [:0]const u8 = "/sys/kernel/debug/jitter_rng/jent_raw_hires";
const SYSFS_PARAM_DIR: [:0]const u8 = "/sys/module/jitter_rng/parameters";

const JENT_DISABLE_MEMORY_ACCESS: c_uint = 1 << 2;
const JENT_FORCE_INTERNAL_TIMER: c_uint = 1 << 3;
const JENT_DISABLE_INTERNAL_TIMER: c_uint = 1 << 4;
const JENT_FORCE_FIPS: c_uint = 1 << 5;
const JENT_NTG1: c_uint = 1 << 6;
const JENT_CACHE_ALL: c_uint = 1 << 7;
const JENT_TEST_HASHLOOP: c_uint = 1 << 15;
const JENT_TEST_MEMACCLOOP: c_uint = 1 << 16;

const JENT_FLAGS_TO_MEMSIZE_SHIFT: u5 = 27;
const JENT_FLAGS_TO_HASHLOOP_SHIFT: u5 = 23;

fn jentMaxMemsizeToFlags(val: u32) c_uint {
    return val << JENT_FLAGS_TO_MEMSIZE_SHIFT;
}

fn jentHashloopToFlags(val: u32) c_uint {
    return val << JENT_FLAGS_TO_HASHLOOP_SHIFT;
}

const JENT_STATUS_MAX_LEN: usize = 4096;
const JENT_IOC_MAGIC: u8 = 'J';

const jent_status_ioctl = extern struct {
    buf: u64 align(8) = 0,
    length: u32 = 0,
};

const JENT_IOCSTATUS: u32 = linux.IOCTL.IOWR(JENT_IOC_MAGIC, 0x01, jent_status_ioctl);
const JENT_IOCLOOPCNT: u32 = linux.IOCTL.IOW(JENT_IOC_MAGIC, 0x02, u64);

const lrngval_t = u64;
const DATASIZE: usize = @sizeOf(lrngval_t);
const BUFFER_SIZE: usize = RAWENTROPY_SAMPLES * DATASIZE;

const EINVAL: c_int = 22;
const EIO: c_int = 5;

const IoctlRequest = if (builtin.abi.isGnu()) c_ulong else c_int;

const FILE = opaque {};
extern "c" var stdout: *FILE;
extern "c" var stderr: *FILE;
extern "c" fn fopen(pathname: [*:0]const u8, mode: [*:0]const u8) ?*FILE;
extern "c" fn fwrite(ptr: *const anyopaque, size: usize, nmemb: usize, stream: *FILE) usize;
extern "c" fn fclose(stream: *FILE) c_int;
extern "c" fn fflush(stream: ?*FILE) c_int;
extern "c" fn ferror(stream: *FILE) c_int;
extern "c" fn printf(fmt: [*:0]const u8, ...) c_int;
extern "c" fn fprintf(stream: *FILE, fmt: [*:0]const u8, ...) c_int;
extern "c" fn perror(s: [*:0]const u8) void;
extern "c" fn strerror(errnum: c_int) [*:0]const u8;
extern "c" fn strtoul(nptr: [*:0]const u8, endptr: ?*[*:0]u8, base: c_int) c_ulong;
extern "c" fn strncmp(s1: [*:0]const u8, s2: [*:0]const u8, n: usize) c_int;
extern "c" fn open(path: [*:0]const u8, oflag: c_int, ...) c_int;
extern "c" fn close(fd: c_int) c_int;
extern "c" fn read(fd: c_int, buf: [*]u8, nbytes: usize) isize;
extern "c" fn ioctl(fd: c_int, request: IoctlRequest, ...) c_int;
extern "c" fn __errno_location() *c_int;

const Opts = struct {
    samples: usize = RAWENTROPY_SAMPLES,
    flags: c_uint = 0,
    osr: c_uint = 0,
    timestamps: c_uint = 0,
    status: c_uint = 0,
    loopcnt: u64 = 0,
    debugfs_file: [*:0]const u8 = DEBUGFS_INTERFACE.ptr,
    sysfs_dir: [*:0]const u8 = SYSFS_PARAM_DIR.ptr,
};

fn callIoctl(fd: c_int, request: u32, arg: ?*anyopaque) c_int {
    const req: IoctlRequest = if (builtin.abi.isGnu())
        @as(c_ulong, request)
    else
        @as(c_int, @bitCast(request));
    return ioctl(fd, req, arg);
}

fn parse_ulong(str: [*:0]const u8, val: *c_ulong) c_int {
    var endptr: [*:0]u8 = undefined;

    __errno_location().* = 0;
    val.* = strtoul(str, &endptr, 10);
    if (@intFromPtr(endptr) == @intFromPtr(str) or endptr[0] != 0 or __errno_location().* != 0) {
        _ = printf("Invalid numeric value \"%s\"\n", str);
        return -EINVAL;
    }
    return 0;
}

fn write_config(opts: *const Opts, file: [*:0]const u8, val: c_uint) c_int {
    var filename: [4096]u8 = undefined;
    var ret: c_int = 0;

    const path_slice = std.fmt.bufPrint(
        filename[0 .. filename.len - 1],
        "{s}/{s}",
        .{ std.mem.span(opts.sysfs_dir), std.mem.span(file) },
    ) catch return -EINVAL;
    filename[path_slice.len] = 0;
    const path_ptr: [*:0]const u8 = @ptrCast(&filename);

    const config = fopen(path_ptr, "r+") orelse {
        if (val == 0)
            return 0;
        _ = printf(
            "Configuration parameter %s cannot be set (%s), so %u cannot be applied\n",
            path_ptr,
            strerror(__errno_location().*),
            val,
        );
        return -EINVAL;
    };

    const val_slice = std.fmt.bufPrint(filename[0 .. filename.len - 1], "{d}", .{val}) catch {
        _ = fclose(config);
        return -EINVAL;
    };
    filename[val_slice.len] = 0;
    const len = val_slice.len;
    const written = fwrite(val_slice.ptr, 1, len, config);
    if (written != len) {
        _ = printf(
            "Configuration parameters writing to %s failed (%zu written, %zu expected to write)\n",
            file,
            written,
            len,
        );
        ret = -EINVAL;
    }

    if (fclose(config) != 0 and ret == 0) {
        _ = printf(
            "Configuration parameters writing to %s failed: %s\n",
            file,
            strerror(__errno_location().*),
        );
        ret = -EINVAL;
    }
    return ret;
}

fn getrawentropy(opts: *const Opts) c_int {
    var requested: usize = opts.samples * DATASIZE;
    var leftover: lrngval_t = 0;
    var leftover_present: u8 = 0;
    var fill: usize = 0;
    var buffer: [BUFFER_SIZE]u8 = undefined;
    var ret: isize = 0;

    ret = write_config(opts, "testing_osr", opts.osr);
    if (ret < 0)
        return @intCast(ret);
    ret = write_config(opts, "testing_flags", opts.flags);
    if (ret < 0)
        return @intCast(ret);

    const fd = open(opts.debugfs_file, @as(c_int, @bitCast(linux.O{ .ACCMODE = .RDONLY })));
    if (fd < 0)
        return __errno_location().*;

    blk: {
        if (opts.loopcnt != 0) {
            var loopcnt: u64 = opts.loopcnt;
            if (callIoctl(fd, JENT_IOCLOOPCNT, &loopcnt) < 0) {
                perror("JENT_IOCLOOPCNT");
                ret = -@as(isize, __errno_location().*);
                break :blk;
            }
        }

        if (opts.status != 0) {
            var status = jent_status_ioctl{};
            var status_str: [JENT_STATUS_MAX_LEN]u8 = undefined;

            status.buf = @intFromPtr(&status_str);
            status.length = status_str.len;

            if (callIoctl(fd, JENT_IOCSTATUS, &status) < 0) {
                perror("JENT_IOCSTATUS");
                ret = -@as(isize, __errno_location().*);
                break :blk;
            }
            _ = printf("%s", @as([*:0]const u8, @ptrCast(&status_str)));
            ret = 0;
            break :blk;
        }

        while (requested != 0) {
            var need: usize = requested;
            if (opts.timestamps != 0 and leftover_present == 0)
                need += DATASIZE;

            const gather: usize = if (need > BUFFER_SIZE) BUFFER_SIZE else need;

            ret = read(fd, @as([*]u8, &buffer) + fill, gather - fill);
            if (ret < 0) {
                ret = -@as(isize, __errno_location().*);
                break :blk;
            }
            if (ret == 0) {
                _ = fprintf(stderr, "Unexpected EOF reading %s\n", opts.debugfs_file);
                ret = -@as(isize, EIO);
                break :blk;
            }

            fill += @intCast(ret);

            var offset: usize = 0;
            const records = fill / DATASIZE;
            var i: usize = 0;
            while (i < records) : (i += 1) {
                var val: lrngval_t = undefined;
                @memcpy(std.mem.asBytes(&val), buffer[offset .. offset + DATASIZE]);
                offset += DATASIZE;

                if (opts.timestamps != 0) {
                    if (leftover_present == 0) {
                        leftover = val;
                        leftover_present = 1;
                        continue;
                    }
                    _ = printf("%llu\n", @as(c_ulonglong, val -% leftover));
                    leftover = val;
                } else {
                    _ = printf("%llu\n", @as(c_ulonglong, val));
                }

                requested -= DATASIZE;
                if (requested == 0)
                    break;
            }

            fill -= offset;
            std.mem.copyForwards(u8, buffer[0..fill], buffer[offset .. offset + fill]);
        }

        ret = 0;
    }

    if (fd >= 0)
        _ = close(fd);

    if (ret == 0 and (fflush(stdout) != 0 or ferror(stdout) != 0)) {
        _ = fprintf(stderr, "Failed to write output\n");
        ret = -@as(isize, EIO);
    }

    return @intCast(ret);
}

pub export fn main(initial_argc: c_int, initial_argv: [*]const [*:0]const u8) callconv(.c) c_int {
    var opts = Opts{};
    var argc = initial_argc;
    var argv = initial_argv;

    if (argc < 2) {
        _ = printf(
            "%s --samples <NUMSAMPLES> | --debugfs-file <FILE> [ --param-dir <DIR> | --timestamps | --ntg1|--force-fips|--disable-memory-access|--disable-internal-timer|--force-internal-timer|--osr <OSR>|--loopcnt <NUM>|--max-mem <NUM>|--hashloop|--memaccess|--all-caches|--hloopcnt <NUM>|--status]\n",
            argv[0],
        );
        return 1;
    }

    while (argc > 1) {
        if (strncmp(argv[1], "--samples", 9) == 0 or strncmp(argv[1], "-s", 2) == 0) {
            var val: c_ulong = 0;

            argc -= 1;
            argv += 1;
            if (argc <= 1) {
                _ = printf("OSR value missing\n");
                return 1;
            }

            if (parse_ulong(argv[1], &val) != 0)
                return 1;
            if (val == 0 or val >= std.math.maxInt(c_uint) or val + 1 > std.math.maxInt(usize) / DATASIZE)
                return 1;
            opts.samples = @intCast(val);
        } else if (strncmp(argv[1], "--debugfs-file", 14) == 0 or strncmp(argv[1], "-f", 6) == 0) {
            argc -= 1;
            argv += 1;
            if (argc <= 1) {
                _ = printf("debugfs file path missing\n");
                return 1;
            }
            opts.debugfs_file = argv[1];
        } else if (strncmp(argv[1], "--param-dir", 11) == 0) {
            argc -= 1;
            argv += 1;
            if (argc <= 1) {
                _ = printf("sysfs parameter directory path missing\n");
                return 1;
            }
            opts.sysfs_dir = argv[1];
        } else if (strncmp(argv[1], "--timestamps", 12) == 0) {
            opts.timestamps = 1;
        } else if (strncmp(argv[1], "--ntg1", 6) == 0) {
            opts.flags |= JENT_NTG1;
        } else if (strncmp(argv[1], "--force-fips", 12) == 0) {
            opts.flags |= JENT_FORCE_FIPS;
        } else if (strncmp(argv[1], "--disable-memory-access", 23) == 0) {
            opts.flags |= JENT_DISABLE_MEMORY_ACCESS;
        } else if (strncmp(argv[1], "--disable-internal-timer", 24) == 0) {
            opts.flags |= JENT_DISABLE_INTERNAL_TIMER;
        } else if (strncmp(argv[1], "--force-internal-timer", 22) == 0) {
            opts.flags |= JENT_FORCE_INTERNAL_TIMER;
        } else if (strncmp(argv[1], "--all-caches", 12) == 0) {
            opts.flags |= JENT_CACHE_ALL;
        } else if (strncmp(argv[1], "--hashloop", 10) == 0) {
            opts.flags |= JENT_TEST_HASHLOOP;
        } else if (strncmp(argv[1], "--memaccess", 11) == 0) {
            opts.flags |= JENT_TEST_MEMACCLOOP;
        } else if (strncmp(argv[1], "--osr", 5) == 0) {
            var val: c_ulong = 0;

            argc -= 1;
            argv += 1;
            if (argc <= 1) {
                _ = printf("OSR value missing\n");
                return 1;
            }

            if (parse_ulong(argv[1], &val) != 0 or val >= std.math.maxInt(c_uint))
                return 1;
            opts.osr = @intCast(val);
        } else if (strncmp(argv[1], "--loopcnt", 9) == 0) {
            var val: c_ulong = 0;

            argc -= 1;
            argv += 1;
            if (argc <= 1) {
                _ = printf("Loop count value missing\n");
                return 1;
            }

            if (parse_ulong(argv[1], &val) != 0 or val >= std.math.maxInt(c_uint))
                return 1;
            opts.loopcnt = val;
        } else if (strncmp(argv[1], "--max-mem", 9) == 0) {
            var val: c_ulong = 0;

            argc -= 1;
            argv += 1;
            if (argc <= 1) {
                _ = printf("Maximum memory value missing\n");
                return 1;
            }

            if (parse_ulong(argv[1], &val) != 0)
                return 1;
            if (val == 0) {
                // Allow to set no option
            } else if (val >= 1 and val <= 20) {
                opts.flags |= jentMaxMemsizeToFlags(@intCast(val));
            } else {
                _ = printf("Unknown maximum memory value\n");
                return 1;
            }
        } else if (strncmp(argv[1], "--hloopcnt", 10) == 0) {
            var val: c_ulong = 0;

            argc -= 1;
            argv += 1;
            if (argc <= 1) {
                _ = printf("Hash loop count value missing\n");
                return 1;
            }

            if (parse_ulong(argv[1], &val) != 0)
                return 1;
            if (val <= 7) {
                opts.flags |= jentHashloopToFlags(@intCast(val + 1));
            } else {
                _ = printf("Unknown hashloop value\n");
                return 1;
            }
        } else if (strncmp(argv[1], "--status", 8) == 0) {
            opts.status = 1;
        } else {
            _ = printf("Unknown option %s\n", argv[1]);
            return 1;
        }

        argc -= 1;
        argv += 1;
    }

    return getrawentropy(&opts);
}
