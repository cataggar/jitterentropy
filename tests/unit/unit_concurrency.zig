const __root = @This();
pub const __builtin = @import("std").zig.c_translation.builtins;
pub const __helpers = @import("std").zig.c_translation.helpers;
pub extern fn __sysconf(__name: c_int) c_long;
pub const ptrdiff_t = c_long;
pub const wchar_t = c_uint;
pub const max_align_t = extern struct {
    __aro_max_align_ll: c_longlong = 0,
    __aro_max_align_ld: c_longdouble = 0,
};
pub const __u_char = u8;
pub const __u_short = c_ushort;
pub const __u_int = c_uint;
pub const __u_long = c_ulong;
pub const __int8_t = i8;
pub const __uint8_t = u8;
pub const __int16_t = c_short;
pub const __uint16_t = c_ushort;
pub const __int32_t = c_int;
pub const __uint32_t = c_uint;
pub const __int64_t = c_long;
pub const __uint64_t = c_ulong;
pub const __int_least8_t = __int8_t;
pub const __uint_least8_t = __uint8_t;
pub const __int_least16_t = __int16_t;
pub const __uint_least16_t = __uint16_t;
pub const __int_least32_t = __int32_t;
pub const __uint_least32_t = __uint32_t;
pub const __int_least64_t = __int64_t;
pub const __uint_least64_t = __uint64_t;
pub const __quad_t = c_long;
pub const __u_quad_t = c_ulong;
pub const __intmax_t = c_long;
pub const __uintmax_t = c_ulong;
pub const __dev_t = c_ulong;
pub const __uid_t = c_uint;
pub const __gid_t = c_uint;
pub const __ino_t = c_ulong;
pub const __ino64_t = c_ulong;
pub const __mode_t = c_uint;
pub const __nlink_t = c_uint;
pub const __off_t = c_long;
pub const __off64_t = c_long;
pub const __pid_t = c_int;
pub const __fsid_t = extern struct {
    __val: [2]c_int = @import("std").mem.zeroes([2]c_int),
};
pub const __clock_t = c_long;
pub const __rlim_t = c_ulong;
pub const __rlim64_t = c_ulong;
pub const __id_t = c_uint;
pub const __time_t = c_long;
pub const __useconds_t = c_uint;
pub const __suseconds_t = c_long;
pub const __suseconds64_t = c_long;
pub const __daddr_t = c_int;
pub const __key_t = c_int;
pub const __clockid_t = c_int;
pub const __timer_t = ?*anyopaque;
pub const __blksize_t = c_int;
pub const __blkcnt_t = c_long;
pub const __blkcnt64_t = c_long;
pub const __fsblkcnt_t = c_ulong;
pub const __fsblkcnt64_t = c_ulong;
pub const __fsfilcnt_t = c_ulong;
pub const __fsfilcnt64_t = c_ulong;
pub const __fsword_t = c_long;
pub const __ssize_t = c_long;
pub const __syscall_slong_t = c_long;
pub const __syscall_ulong_t = c_ulong;
pub const __loff_t = __off64_t;
pub const __caddr_t = [*c]u8;
pub const __intptr_t = c_long;
pub const __socklen_t = c_uint;
pub const __sig_atomic_t = c_int;
pub const struct_timeval = extern struct {
    tv_sec: __time_t = 0,
    tv_usec: __suseconds_t = 0,
    pub const gettimeofday = __root.gettimeofday;
    pub const settimeofday = __root.settimeofday;
    pub const adjtime = __root.adjtime;
};
// /home/g/.local/share/ghr/tools/_v2/units/u-cataggar/u-zig/_unit/zig-aarch64-linux-0.17.0/lib/compiler/aro/include/limits.h:3:2: warning: struct demoted to opaque type - has bitfield
pub const struct_timex = opaque {};
pub extern fn clock_adjtime(__clock_id: __clockid_t, __utx: ?*struct_timex) c_int;
pub const clock_t = __clock_t;
pub const time_t = __time_t;
pub const struct_tm = extern struct {
    tm_sec: c_int = 0,
    tm_min: c_int = 0,
    tm_hour: c_int = 0,
    tm_mday: c_int = 0,
    tm_mon: c_int = 0,
    tm_year: c_int = 0,
    tm_wday: c_int = 0,
    tm_yday: c_int = 0,
    tm_isdst: c_int = 0,
    tm_gmtoff: c_long = 0,
    tm_zone: [*c]const u8 = null,
    pub const mktime = __root.mktime;
    pub const asctime = __root.asctime;
    pub const asctime_r = __root.asctime_r;
    pub const timegm = __root.timegm;
    pub const timelocal = __root.timelocal;
    pub const r = __root.asctime_r;
};
pub const struct_timespec = extern struct {
    tv_sec: __time_t = 0,
    tv_nsec: __syscall_slong_t = 0,
    pub const nanosleep = __root.nanosleep;
    pub const timespec_get = __root.timespec_get;
    pub const timespec_getres = __root.timespec_getres;
    pub const get = __root.timespec_get;
    pub const getres = __root.timespec_getres;
};
pub const clockid_t = __clockid_t;
pub const timer_t = __timer_t;
pub const struct_itimerspec = extern struct {
    it_interval: struct_timespec = @import("std").mem.zeroes(struct_timespec),
    it_value: struct_timespec = @import("std").mem.zeroes(struct_timespec),
};
pub const struct_sigevent = opaque {};
pub const pid_t = __pid_t;
pub const struct___locale_data_1 = opaque {};
pub const struct___locale_struct = extern struct {
    __locales: [13]?*struct___locale_data_1 = @import("std").mem.zeroes([13]?*struct___locale_data_1),
    __ctype_b: [*c]const c_ushort = null,
    __ctype_tolower: [*c]const c_int = null,
    __ctype_toupper: [*c]const c_int = null,
    __names: [13][*c]const u8 = @import("std").mem.zeroes([13][*c]const u8),
};
pub const __locale_t = [*c]struct___locale_struct;
pub const locale_t = __locale_t;
pub extern fn clock() clock_t;
pub extern fn time(__timer: [*c]time_t) time_t;
pub extern fn difftime(__time1: time_t, __time0: time_t) f64;
pub extern fn mktime(__tp: [*c]struct_tm) time_t;
pub extern fn strftime(noalias __s: [*c]u8, __maxsize: usize, noalias __format: [*c]const u8, noalias __tp: [*c]const struct_tm) usize;
pub extern fn strptime(noalias __s: [*c]const u8, noalias __fmt: [*c]const u8, __tp: [*c]struct_tm) [*c]u8;
pub extern fn strftime_l(noalias __s: [*c]u8, __maxsize: usize, noalias __format: [*c]const u8, noalias __tp: [*c]const struct_tm, __loc: locale_t) usize;
pub extern fn strptime_l(noalias __s: [*c]const u8, noalias __fmt: [*c]const u8, __tp: [*c]struct_tm, __loc: locale_t) [*c]u8;
pub extern fn gmtime(__timer: [*c]const time_t) [*c]struct_tm;
pub extern fn localtime(__timer: [*c]const time_t) [*c]struct_tm;
pub extern fn gmtime_r(noalias __timer: [*c]const time_t, noalias __tp: [*c]struct_tm) [*c]struct_tm;
pub extern fn localtime_r(noalias __timer: [*c]const time_t, noalias __tp: [*c]struct_tm) [*c]struct_tm;
pub extern fn asctime(__tp: [*c]const struct_tm) [*c]u8;
pub extern fn ctime(__timer: [*c]const time_t) [*c]u8;
pub extern fn asctime_r(noalias __tp: [*c]const struct_tm, noalias __buf: [*c]u8) [*c]u8;
pub extern fn ctime_r(noalias __timer: [*c]const time_t, noalias __buf: [*c]u8) [*c]u8;
pub extern var __tzname: [2][*c]u8;
pub extern var __daylight: c_int;
pub extern var __timezone: c_long;
pub extern var tzname: [2][*c]u8;
pub extern fn tzset() void;
pub extern var daylight: c_int;
pub extern var timezone: c_long;
pub extern fn timegm(__tp: [*c]struct_tm) time_t;
pub extern fn timelocal(__tp: [*c]struct_tm) time_t;
pub extern fn dysize(__year: c_int) c_int;
pub extern fn nanosleep(__requested_time: [*c]const struct_timespec, __remaining: [*c]struct_timespec) c_int;
pub extern fn clock_getres(__clock_id: clockid_t, __res: [*c]struct_timespec) c_int;
pub extern fn clock_gettime(__clock_id: clockid_t, __tp: [*c]struct_timespec) c_int;
pub extern fn clock_settime(__clock_id: clockid_t, __tp: [*c]const struct_timespec) c_int;
pub extern fn clock_nanosleep(__clock_id: clockid_t, __flags: c_int, __req: [*c]const struct_timespec, __rem: [*c]struct_timespec) c_int;
pub extern fn clock_getcpuclockid(__pid: pid_t, __clock_id: [*c]clockid_t) c_int;
pub extern fn timer_create(__clock_id: clockid_t, noalias __evp: ?*struct_sigevent, noalias __timerid: [*c]timer_t) c_int;
pub extern fn timer_delete(__timerid: timer_t) c_int;
pub extern fn timer_settime(__timerid: timer_t, __flags: c_int, noalias __value: [*c]const struct_itimerspec, noalias __ovalue: [*c]struct_itimerspec) c_int;
pub extern fn timer_gettime(__timerid: timer_t, __value: [*c]struct_itimerspec) c_int;
pub extern fn timer_getoverrun(__timerid: timer_t) c_int;
pub extern fn timespec_get(__ts: [*c]struct_timespec, __base: c_int) c_int;
pub extern fn timespec_getres(__ts: [*c]struct_timespec, __base: c_int) c_int;
pub extern var getdate_err: c_int;
pub extern fn getdate(__string: [*c]const u8) [*c]struct_tm;
pub extern fn getdate_r(noalias __string: [*c]const u8, noalias __resbufp: [*c]struct_tm) c_int;
pub const int_least8_t = __int_least8_t;
pub const int_least16_t = __int_least16_t;
pub const int_least32_t = __int_least32_t;
pub const int_least64_t = __int_least64_t;
pub const uint_least8_t = __uint_least8_t;
pub const uint_least16_t = __uint_least16_t;
pub const uint_least32_t = __uint_least32_t;
pub const uint_least64_t = __uint_least64_t;
pub const int_fast8_t = i8;
pub const int_fast16_t = c_long;
pub const int_fast32_t = c_long;
pub const int_fast64_t = c_long;
pub const uint_fast8_t = u8;
pub const uint_fast16_t = c_ulong;
pub const uint_fast32_t = c_ulong;
pub const uint_fast64_t = c_ulong;
pub const intmax_t = __intmax_t;
pub const uintmax_t = __uintmax_t;
pub const struct___va_list_2 = extern struct {
    unnamed_0: ?*anyopaque = null,
    unnamed_1: ?*anyopaque = null,
    unnamed_2: ?*anyopaque = null,
    unnamed_3: c_int = 0,
    unnamed_4: c_int = 0,
};
pub const __builtin_va_list = struct___va_list_2;
pub const va_list = __builtin_va_list;
pub const __gnuc_va_list = __builtin_va_list;
const union_unnamed_3 = extern union {
    __wch: c_uint,
    __wchb: [4]u8,
};
pub const __mbstate_t = extern struct {
    __count: c_int = 0,
    __value: union_unnamed_3 = @import("std").mem.zeroes(union_unnamed_3),
};
pub const struct__G_fpos_t = extern struct {
    __pos: __off_t = 0,
    __state: __mbstate_t = @import("std").mem.zeroes(__mbstate_t),
};
pub const __fpos_t = struct__G_fpos_t;
pub const struct__G_fpos64_t = extern struct {
    __pos: __off64_t = 0,
    __state: __mbstate_t = @import("std").mem.zeroes(__mbstate_t),
};
pub const __fpos64_t = struct__G_fpos64_t;
pub const struct__IO_marker = opaque {};
// /usr/include/aarch64-linux-gnu/bits/types/struct_FILE.h:75:7: warning: struct demoted to opaque type - has bitfield
pub const struct__IO_FILE = opaque {
    pub const fclose = __root.fclose;
    pub const fflush = __root.fflush;
    pub const fflush_unlocked = __root.fflush_unlocked;
    pub const setbuf = __root.setbuf;
    pub const setvbuf = __root.setvbuf;
    pub const setbuffer = __root.setbuffer;
    pub const setlinebuf = __root.setlinebuf;
    pub const fprintf = __root.fprintf;
    pub const vfprintf = __root.vfprintf;
    pub const fscanf = __root.fscanf;
    pub const vfscanf = __root.vfscanf;
    pub const fgetc = __root.fgetc;
    pub const getc = __root.getc;
    pub const getc_unlocked = __root.getc_unlocked;
    pub const fgetc_unlocked = __root.fgetc_unlocked;
    pub const getw = __root.getw;
    pub const fseek = __root.fseek;
    pub const ftell = __root.ftell;
    pub const rewind = __root.rewind;
    pub const fseeko = __root.fseeko;
    pub const ftello = __root.ftello;
    pub const fgetpos = __root.fgetpos;
    pub const fsetpos = __root.fsetpos;
    pub const fseeko64 = __root.fseeko64;
    pub const ftello64 = __root.ftello64;
    pub const fgetpos64 = __root.fgetpos64;
    pub const fsetpos64 = __root.fsetpos64;
    pub const clearerr = __root.clearerr;
    pub const feof = __root.feof;
    pub const ferror = __root.ferror;
    pub const clearerr_unlocked = __root.clearerr_unlocked;
    pub const feof_unlocked = __root.feof_unlocked;
    pub const ferror_unlocked = __root.ferror_unlocked;
    pub const fileno = __root.fileno;
    pub const fileno_unlocked = __root.fileno_unlocked;
    pub const pclose = __root.pclose;
    pub const flockfile = __root.flockfile;
    pub const ftrylockfile = __root.ftrylockfile;
    pub const funlockfile = __root.funlockfile;
    pub const __uflow = __root.__uflow;
    pub const __overflow = __root.__overflow;
    pub const unlocked = __root.fflush_unlocked;
    pub const uflow = __root.__uflow;
    pub const overflow = __root.__overflow;
};
pub const __FILE = struct__IO_FILE;
pub const FILE = struct__IO_FILE;
pub const struct__IO_codecvt = opaque {};
pub const struct__IO_wide_data = opaque {};
pub const _IO_lock_t = anyopaque;
pub const cookie_read_function_t = fn (__cookie: ?*anyopaque, __buf: [*c]u8, __nbytes: usize) callconv(.c) __ssize_t;
pub const cookie_write_function_t = fn (__cookie: ?*anyopaque, __buf: [*c]const u8, __nbytes: usize) callconv(.c) __ssize_t;
pub const cookie_seek_function_t = fn (__cookie: ?*anyopaque, __pos: [*c]__off64_t, __w: c_int) callconv(.c) c_int;
pub const cookie_close_function_t = fn (__cookie: ?*anyopaque) callconv(.c) c_int;
pub const struct__IO_cookie_io_functions_t = extern struct {
    read: ?*const cookie_read_function_t = null,
    write: ?*const cookie_write_function_t = null,
    seek: ?*const cookie_seek_function_t = null,
    close: ?*const cookie_close_function_t = null,
};
pub const cookie_io_functions_t = struct__IO_cookie_io_functions_t;
pub const off_t = __off_t;
pub const off64_t = __off64_t;
pub const fpos_t = __fpos_t;
pub const fpos64_t = __fpos64_t;
pub extern fn remove(__filename: [*c]const u8) c_int;
pub extern fn rename(__old: [*c]const u8, __new: [*c]const u8) c_int;
pub extern fn renameat(__oldfd: c_int, __old: [*c]const u8, __newfd: c_int, __new: [*c]const u8) c_int;
pub extern fn renameat2(__oldfd: c_int, __old: [*c]const u8, __newfd: c_int, __new: [*c]const u8, __flags: c_uint) c_int;
pub extern fn fclose(__stream: ?*FILE) c_int;
pub extern fn tmpfile() ?*FILE;
pub extern fn tmpfile64() ?*FILE;
pub extern fn tmpnam([*c]u8) [*c]u8;
pub extern fn tmpnam_r(__s: [*c]u8) [*c]u8;
pub extern fn tempnam(__dir: [*c]const u8, __pfx: [*c]const u8) [*c]u8;
pub extern fn fflush(__stream: ?*FILE) c_int;
pub extern fn fflush_unlocked(__stream: ?*FILE) c_int;
pub extern fn fcloseall() c_int;
pub extern fn fopen(noalias __filename: [*c]const u8, noalias __modes: [*c]const u8) ?*FILE;
pub extern fn freopen(noalias __filename: [*c]const u8, noalias __modes: [*c]const u8, noalias __stream: ?*FILE) ?*FILE;
pub extern fn fopen64(noalias __filename: [*c]const u8, noalias __modes: [*c]const u8) ?*FILE;
pub extern fn freopen64(noalias __filename: [*c]const u8, noalias __modes: [*c]const u8, noalias __stream: ?*FILE) ?*FILE;
pub extern fn fdopen(__fd: c_int, __modes: [*c]const u8) ?*FILE;
pub extern fn fopencookie(noalias __magic_cookie: ?*anyopaque, noalias __modes: [*c]const u8, __io_funcs: cookie_io_functions_t) ?*FILE;
pub extern fn fmemopen(__s: ?*anyopaque, __len: usize, __modes: [*c]const u8) ?*FILE;
pub extern fn open_memstream(__bufloc: [*c][*c]u8, __sizeloc: [*c]usize) ?*FILE;
pub extern fn setbuf(noalias __stream: ?*FILE, noalias __buf: [*c]u8) void;
pub extern fn setvbuf(noalias __stream: ?*FILE, noalias __buf: [*c]u8, __modes: c_int, __n: usize) c_int;
pub extern fn setbuffer(noalias __stream: ?*FILE, noalias __buf: [*c]u8, __size: usize) void;
pub extern fn setlinebuf(__stream: ?*FILE) void;
pub extern fn fprintf(noalias __stream: ?*FILE, noalias __format: [*c]const u8, ...) c_int;
pub extern fn printf(noalias __format: [*c]const u8, ...) c_int;
pub extern fn sprintf(noalias __s: [*c]u8, noalias __format: [*c]const u8, ...) c_int;
pub extern fn vfprintf(noalias __s: ?*FILE, noalias __format: [*c]const u8, __arg: __gnuc_va_list) c_int;
pub extern fn vprintf(noalias __format: [*c]const u8, __arg: __gnuc_va_list) c_int;
pub extern fn vsprintf(noalias __s: [*c]u8, noalias __format: [*c]const u8, __arg: __gnuc_va_list) c_int;
pub extern fn snprintf(noalias __s: [*c]u8, __maxlen: usize, noalias __format: [*c]const u8, ...) c_int;
pub extern fn vsnprintf(noalias __s: [*c]u8, __maxlen: usize, noalias __format: [*c]const u8, __arg: __gnuc_va_list) c_int;
pub extern fn vasprintf(noalias __ptr: [*c][*c]u8, noalias __f: [*c]const u8, __arg: __gnuc_va_list) c_int;
pub extern fn __asprintf(noalias __ptr: [*c][*c]u8, noalias __fmt: [*c]const u8, ...) c_int;
pub extern fn asprintf(noalias __ptr: [*c][*c]u8, noalias __fmt: [*c]const u8, ...) c_int;
pub extern fn vdprintf(__fd: c_int, noalias __fmt: [*c]const u8, __arg: __gnuc_va_list) c_int;
pub extern fn dprintf(__fd: c_int, noalias __fmt: [*c]const u8, ...) c_int;
pub extern fn fscanf(noalias __stream: ?*FILE, noalias __format: [*c]const u8, ...) c_int;
pub extern fn scanf(noalias __format: [*c]const u8, ...) c_int;
pub extern fn sscanf(noalias __s: [*c]const u8, noalias __format: [*c]const u8, ...) c_int;
pub extern fn vfscanf(noalias __s: ?*FILE, noalias __format: [*c]const u8, __arg: __gnuc_va_list) c_int;
pub extern fn vscanf(noalias __format: [*c]const u8, __arg: __gnuc_va_list) c_int;
pub extern fn vsscanf(noalias __s: [*c]const u8, noalias __format: [*c]const u8, __arg: __gnuc_va_list) c_int;
pub extern fn fgetc(__stream: ?*FILE) c_int;
pub extern fn getc(__stream: ?*FILE) c_int;
pub extern fn getchar() c_int;
pub extern fn getc_unlocked(__stream: ?*FILE) c_int;
pub extern fn getchar_unlocked() c_int;
pub extern fn fgetc_unlocked(__stream: ?*FILE) c_int;
pub extern fn fputc(__c: c_int, __stream: ?*FILE) c_int;
pub extern fn putc(__c: c_int, __stream: ?*FILE) c_int;
pub extern fn putchar(__c: c_int) c_int;
pub extern fn fputc_unlocked(__c: c_int, __stream: ?*FILE) c_int;
pub extern fn putc_unlocked(__c: c_int, __stream: ?*FILE) c_int;
pub extern fn putchar_unlocked(__c: c_int) c_int;
pub extern fn getw(__stream: ?*FILE) c_int;
pub extern fn putw(__w: c_int, __stream: ?*FILE) c_int;
pub extern fn fgets(noalias __s: [*c]u8, __n: c_int, noalias __stream: ?*FILE) [*c]u8;
pub extern fn fgets_unlocked(noalias __s: [*c]u8, __n: c_int, noalias __stream: ?*FILE) [*c]u8;
pub extern fn __getdelim(noalias __lineptr: [*c][*c]u8, noalias __n: [*c]usize, __delimiter: c_int, noalias __stream: ?*FILE) __ssize_t;
pub extern fn getdelim(noalias __lineptr: [*c][*c]u8, noalias __n: [*c]usize, __delimiter: c_int, noalias __stream: ?*FILE) __ssize_t;
pub extern fn getline(noalias __lineptr: [*c][*c]u8, noalias __n: [*c]usize, noalias __stream: ?*FILE) __ssize_t;
pub extern fn fputs(noalias __s: [*c]const u8, noalias __stream: ?*FILE) c_int;
pub extern fn puts(__s: [*c]const u8) c_int;
pub extern fn ungetc(__c: c_int, __stream: ?*FILE) c_int;
pub extern fn fread(noalias __ptr: ?*anyopaque, __size: usize, __n: usize, noalias __stream: ?*FILE) usize;
pub extern fn fwrite(noalias __ptr: ?*const anyopaque, __size: usize, __n: usize, noalias __s: ?*FILE) usize;
pub extern fn fputs_unlocked(noalias __s: [*c]const u8, noalias __stream: ?*FILE) c_int;
pub extern fn fread_unlocked(noalias __ptr: ?*anyopaque, __size: usize, __n: usize, noalias __stream: ?*FILE) usize;
pub extern fn fwrite_unlocked(noalias __ptr: ?*const anyopaque, __size: usize, __n: usize, noalias __stream: ?*FILE) usize;
pub extern fn fseek(__stream: ?*FILE, __off: c_long, __whence: c_int) c_int;
pub extern fn ftell(__stream: ?*FILE) c_long;
pub extern fn rewind(__stream: ?*FILE) void;
pub extern fn fseeko(__stream: ?*FILE, __off: __off_t, __whence: c_int) c_int;
pub extern fn ftello(__stream: ?*FILE) __off_t;
pub extern fn fgetpos(noalias __stream: ?*FILE, noalias __pos: [*c]fpos_t) c_int;
pub extern fn fsetpos(__stream: ?*FILE, __pos: [*c]const fpos_t) c_int;
pub extern fn fseeko64(__stream: ?*FILE, __off: __off64_t, __whence: c_int) c_int;
pub extern fn ftello64(__stream: ?*FILE) __off64_t;
pub extern fn fgetpos64(noalias __stream: ?*FILE, noalias __pos: [*c]fpos64_t) c_int;
pub extern fn fsetpos64(__stream: ?*FILE, __pos: [*c]const fpos64_t) c_int;
pub extern fn clearerr(__stream: ?*FILE) void;
pub extern fn feof(__stream: ?*FILE) c_int;
pub extern fn ferror(__stream: ?*FILE) c_int;
pub extern fn clearerr_unlocked(__stream: ?*FILE) void;
pub extern fn feof_unlocked(__stream: ?*FILE) c_int;
pub extern fn ferror_unlocked(__stream: ?*FILE) c_int;
pub extern fn perror(__s: [*c]const u8) void;
pub extern fn fileno(__stream: ?*FILE) c_int;
pub extern fn fileno_unlocked(__stream: ?*FILE) c_int;
pub extern fn pclose(__stream: ?*FILE) c_int;
pub extern fn popen(__command: [*c]const u8, __modes: [*c]const u8) ?*FILE;
pub extern fn ctermid(__s: [*c]u8) [*c]u8;
pub extern fn cuserid(__s: [*c]u8) [*c]u8;
pub const struct_obstack = opaque {
    pub const obstack_printf = __root.obstack_printf;
    pub const obstack_vprintf = __root.obstack_vprintf;
};
pub extern fn obstack_printf(noalias __obstack: ?*struct_obstack, noalias __format: [*c]const u8, ...) c_int;
pub extern fn obstack_vprintf(noalias __obstack: ?*struct_obstack, noalias __format: [*c]const u8, __args: __gnuc_va_list) c_int;
pub extern fn flockfile(__stream: ?*FILE) void;
pub extern fn ftrylockfile(__stream: ?*FILE) c_int;
pub extern fn funlockfile(__stream: ?*FILE) void;
pub extern fn __uflow(?*FILE) c_int;
pub extern fn __overflow(?*FILE, c_int) c_int;
pub const div_t = extern struct {
    quot: c_int = 0,
    rem: c_int = 0,
};
pub const ldiv_t = extern struct {
    quot: c_long = 0,
    rem: c_long = 0,
};
pub const lldiv_t = extern struct {
    quot: c_longlong = 0,
    rem: c_longlong = 0,
};
pub extern fn __ctype_get_mb_cur_max() usize;
pub extern fn atof(__nptr: [*c]const u8) f64;
pub extern fn atoi(__nptr: [*c]const u8) c_int;
pub extern fn atol(__nptr: [*c]const u8) c_long;
pub extern fn atoll(__nptr: [*c]const u8) c_longlong;
pub extern fn strtod(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8) f64;
pub extern fn strtof(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8) f32;
pub extern fn strtold(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8) c_longdouble;
pub extern fn strtof32(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8) f32;
pub extern fn strtof64(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8) f64;
pub extern fn strtof128(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8) f128;
pub extern fn strtof32x(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8) f64;
pub extern fn strtof64x(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8) c_longdouble;
pub extern fn strtol(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __base: c_int) c_long;
pub extern fn strtoul(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __base: c_int) c_ulong;
pub extern fn strtoq(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __base: c_int) c_longlong;
pub extern fn strtouq(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __base: c_int) c_ulonglong;
pub extern fn strtoll(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __base: c_int) c_longlong;
pub extern fn strtoull(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __base: c_int) c_ulonglong;
pub extern fn strfromd(__dest: [*c]u8, __size: usize, __format: [*c]const u8, __f: f64) c_int;
pub extern fn strfromf(__dest: [*c]u8, __size: usize, __format: [*c]const u8, __f: f32) c_int;
pub extern fn strfroml(__dest: [*c]u8, __size: usize, __format: [*c]const u8, __f: c_longdouble) c_int;
pub extern fn strfromf32(__dest: [*c]u8, __size: usize, __format: [*c]const u8, __f: f32) c_int;
pub extern fn strfromf64(__dest: [*c]u8, __size: usize, __format: [*c]const u8, __f: f64) c_int;
pub extern fn strfromf128(__dest: [*c]u8, __size: usize, __format: [*c]const u8, __f: f128) c_int;
pub extern fn strfromf32x(__dest: [*c]u8, __size: usize, __format: [*c]const u8, __f: f64) c_int;
pub extern fn strfromf64x(__dest: [*c]u8, __size: usize, __format: [*c]const u8, __f: c_longdouble) c_int;
pub extern fn strtol_l(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __base: c_int, __loc: locale_t) c_long;
pub extern fn strtoul_l(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __base: c_int, __loc: locale_t) c_ulong;
pub extern fn strtoll_l(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __base: c_int, __loc: locale_t) c_longlong;
pub extern fn strtoull_l(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __base: c_int, __loc: locale_t) c_ulonglong;
pub extern fn strtod_l(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __loc: locale_t) f64;
pub extern fn strtof_l(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __loc: locale_t) f32;
pub extern fn strtold_l(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __loc: locale_t) c_longdouble;
pub extern fn strtof32_l(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __loc: locale_t) f32;
pub extern fn strtof64_l(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __loc: locale_t) f64;
pub extern fn strtof128_l(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __loc: locale_t) f128;
pub extern fn strtof32x_l(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __loc: locale_t) f64;
pub extern fn strtof64x_l(noalias __nptr: [*c]const u8, noalias __endptr: [*c][*c]u8, __loc: locale_t) c_longdouble;
pub extern fn l64a(__n: c_long) [*c]u8;
pub extern fn a64l(__s: [*c]const u8) c_long;
pub const u_char = __u_char;
pub const u_short = __u_short;
pub const u_int = __u_int;
pub const u_long = __u_long;
pub const quad_t = __quad_t;
pub const u_quad_t = __u_quad_t;
pub const fsid_t = __fsid_t;
pub const loff_t = __loff_t;
pub const ino_t = __ino_t;
pub const ino64_t = __ino64_t;
pub const dev_t = __dev_t;
pub const gid_t = __gid_t;
pub const mode_t = __mode_t;
pub const nlink_t = __nlink_t;
pub const uid_t = __uid_t;
pub const id_t = __id_t;
pub const daddr_t = __daddr_t;
pub const caddr_t = __caddr_t;
pub const key_t = __key_t;
pub const useconds_t = __useconds_t;
pub const suseconds_t = __suseconds_t;
pub const ulong = c_ulong;
pub const ushort = c_ushort;
pub const uint = c_uint;
pub const u_int8_t = __uint8_t;
pub const u_int16_t = __uint16_t;
pub const u_int32_t = __uint32_t;
pub const u_int64_t = __uint64_t;
pub const register_t = c_int;
pub fn __bswap_16(arg___bsx: __uint16_t) callconv(.c) __uint16_t {
    var __bsx = arg___bsx;
    _ = &__bsx;
    return @byteSwap(@as(__uint16_t, __bsx));
}
pub fn __bswap_32(arg___bsx: __uint32_t) callconv(.c) __uint32_t {
    var __bsx = arg___bsx;
    _ = &__bsx;
    return @byteSwap(@as(__uint32_t, __bsx));
}
pub fn __bswap_64(arg___bsx: __uint64_t) callconv(.c) __uint64_t {
    var __bsx = arg___bsx;
    _ = &__bsx;
    return @byteSwap(@as(__uint64_t, __bsx));
}
pub fn __uint16_identity(arg___x: __uint16_t) callconv(.c) __uint16_t {
    var __x = arg___x;
    _ = &__x;
    return __x;
}
pub fn __uint32_identity(arg___x: __uint32_t) callconv(.c) __uint32_t {
    var __x = arg___x;
    _ = &__x;
    return __x;
}
pub fn __uint64_identity(arg___x: __uint64_t) callconv(.c) __uint64_t {
    var __x = arg___x;
    _ = &__x;
    return __x;
}
pub const __sigset_t = extern struct {
    __val: [16]c_ulong = @import("std").mem.zeroes([16]c_ulong),
};
pub const sigset_t = __sigset_t;
pub const __fd_mask = c_long;
pub const fd_set = extern struct {
    fds_bits: [16]__fd_mask = @import("std").mem.zeroes([16]__fd_mask),
};
pub const fd_mask = __fd_mask;
pub extern fn select(__nfds: c_int, noalias __readfds: [*c]fd_set, noalias __writefds: [*c]fd_set, noalias __exceptfds: [*c]fd_set, noalias __timeout: [*c]struct_timeval) c_int;
pub extern fn pselect(__nfds: c_int, noalias __readfds: [*c]fd_set, noalias __writefds: [*c]fd_set, noalias __exceptfds: [*c]fd_set, noalias __timeout: [*c]const struct_timespec, noalias __sigmask: [*c]const __sigset_t) c_int;
pub const blksize_t = __blksize_t;
pub const blkcnt_t = __blkcnt_t;
pub const fsblkcnt_t = __fsblkcnt_t;
pub const fsfilcnt_t = __fsfilcnt_t;
pub const blkcnt64_t = __blkcnt64_t;
pub const fsblkcnt64_t = __fsblkcnt64_t;
pub const fsfilcnt64_t = __fsfilcnt64_t;
const struct_unnamed_4 = extern struct {
    __low: c_uint = 0,
    __high: c_uint = 0,
};
pub const __atomic_wide_counter = extern union {
    __value64: c_ulonglong,
    __value32: struct_unnamed_4,
};
pub const struct___pthread_internal_list = extern struct {
    __prev: [*c]struct___pthread_internal_list = null,
    __next: [*c]struct___pthread_internal_list = null,
};
pub const __pthread_list_t = struct___pthread_internal_list;
pub const struct___pthread_internal_slist = extern struct {
    __next: [*c]struct___pthread_internal_slist = null,
};
pub const __pthread_slist_t = struct___pthread_internal_slist;
pub const struct___pthread_mutex_s = extern struct {
    __lock: c_int = 0,
    __count: c_uint = 0,
    __owner: c_int = 0,
    __nusers: c_uint = 0,
    __kind: c_int = 0,
    __spins: c_int = 0,
    __list: __pthread_list_t = @import("std").mem.zeroes(__pthread_list_t),
};
pub const struct___pthread_rwlock_arch_t = extern struct {
    __readers: c_uint = 0,
    __writers: c_uint = 0,
    __wrphase_futex: c_uint = 0,
    __writers_futex: c_uint = 0,
    __pad3: c_uint = 0,
    __pad4: c_uint = 0,
    __cur_writer: c_int = 0,
    __shared: c_int = 0,
    __pad1: c_ulong = 0,
    __pad2: c_ulong = 0,
    __flags: c_uint = 0,
};
pub const struct___pthread_cond_s = extern struct {
    __wseq: __atomic_wide_counter = @import("std").mem.zeroes(__atomic_wide_counter),
    __g1_start: __atomic_wide_counter = @import("std").mem.zeroes(__atomic_wide_counter),
    __g_size: [2]c_uint = @import("std").mem.zeroes([2]c_uint),
    __g1_orig_size: c_uint = 0,
    __wrefs: c_uint = 0,
    __g_signals: [2]c_uint = @import("std").mem.zeroes([2]c_uint),
    __unused_initialized_1: c_uint = 0,
    __unused_initialized_2: c_uint = 0,
};
pub const __tss_t = c_uint;
pub const __thrd_t = c_ulong;
pub const __once_flag = extern struct {
    __data: c_int = 0,
    pub const call_once = __root.call_once;
    pub const once = __root.call_once;
};
pub const pthread_t = c_ulong;
pub const pthread_mutexattr_t = extern union {
    __size: [8]u8,
    __align: c_int,
    pub const pthread_mutexattr_init = __root.pthread_mutexattr_init;
    pub const pthread_mutexattr_destroy = __root.pthread_mutexattr_destroy;
    pub const pthread_mutexattr_getpshared = __root.pthread_mutexattr_getpshared;
    pub const pthread_mutexattr_setpshared = __root.pthread_mutexattr_setpshared;
    pub const pthread_mutexattr_gettype = __root.pthread_mutexattr_gettype;
    pub const pthread_mutexattr_settype = __root.pthread_mutexattr_settype;
    pub const pthread_mutexattr_getprotocol = __root.pthread_mutexattr_getprotocol;
    pub const pthread_mutexattr_setprotocol = __root.pthread_mutexattr_setprotocol;
    pub const pthread_mutexattr_getprioceiling = __root.pthread_mutexattr_getprioceiling;
    pub const pthread_mutexattr_setprioceiling = __root.pthread_mutexattr_setprioceiling;
    pub const pthread_mutexattr_getrobust = __root.pthread_mutexattr_getrobust;
    pub const pthread_mutexattr_getrobust_np = __root.pthread_mutexattr_getrobust_np;
    pub const pthread_mutexattr_setrobust = __root.pthread_mutexattr_setrobust;
    pub const pthread_mutexattr_setrobust_np = __root.pthread_mutexattr_setrobust_np;
    pub const init = __root.pthread_mutexattr_init;
    pub const destroy = __root.pthread_mutexattr_destroy;
    pub const getpshared = __root.pthread_mutexattr_getpshared;
    pub const setpshared = __root.pthread_mutexattr_setpshared;
    pub const gettype = __root.pthread_mutexattr_gettype;
    pub const settype = __root.pthread_mutexattr_settype;
    pub const getprotocol = __root.pthread_mutexattr_getprotocol;
    pub const setprotocol = __root.pthread_mutexattr_setprotocol;
    pub const getprioceiling = __root.pthread_mutexattr_getprioceiling;
    pub const setprioceiling = __root.pthread_mutexattr_setprioceiling;
    pub const getrobust = __root.pthread_mutexattr_getrobust;
    pub const np = __root.pthread_mutexattr_getrobust_np;
    pub const setrobust = __root.pthread_mutexattr_setrobust;
};
pub const pthread_condattr_t = extern union {
    __size: [8]u8,
    __align: c_int,
    pub const pthread_condattr_init = __root.pthread_condattr_init;
    pub const pthread_condattr_destroy = __root.pthread_condattr_destroy;
    pub const pthread_condattr_getpshared = __root.pthread_condattr_getpshared;
    pub const pthread_condattr_setpshared = __root.pthread_condattr_setpshared;
    pub const pthread_condattr_getclock = __root.pthread_condattr_getclock;
    pub const pthread_condattr_setclock = __root.pthread_condattr_setclock;
    pub const init = __root.pthread_condattr_init;
    pub const destroy = __root.pthread_condattr_destroy;
    pub const getpshared = __root.pthread_condattr_getpshared;
    pub const setpshared = __root.pthread_condattr_setpshared;
    pub const getclock = __root.pthread_condattr_getclock;
    pub const setclock = __root.pthread_condattr_setclock;
};
pub const pthread_key_t = c_uint;
pub const pthread_once_t = c_int;
pub const union_pthread_attr_t = extern union {
    __size: [64]u8,
    __align: c_long,
    pub const pthread_attr_init = __root.pthread_attr_init;
    pub const pthread_attr_destroy = __root.pthread_attr_destroy;
    pub const pthread_attr_getdetachstate = __root.pthread_attr_getdetachstate;
    pub const pthread_attr_setdetachstate = __root.pthread_attr_setdetachstate;
    pub const pthread_attr_getguardsize = __root.pthread_attr_getguardsize;
    pub const pthread_attr_setguardsize = __root.pthread_attr_setguardsize;
    pub const pthread_attr_getschedparam = __root.pthread_attr_getschedparam;
    pub const pthread_attr_setschedparam = __root.pthread_attr_setschedparam;
    pub const pthread_attr_getschedpolicy = __root.pthread_attr_getschedpolicy;
    pub const pthread_attr_setschedpolicy = __root.pthread_attr_setschedpolicy;
    pub const pthread_attr_getinheritsched = __root.pthread_attr_getinheritsched;
    pub const pthread_attr_setinheritsched = __root.pthread_attr_setinheritsched;
    pub const pthread_attr_getscope = __root.pthread_attr_getscope;
    pub const pthread_attr_setscope = __root.pthread_attr_setscope;
    pub const pthread_attr_getstackaddr = __root.pthread_attr_getstackaddr;
    pub const pthread_attr_setstackaddr = __root.pthread_attr_setstackaddr;
    pub const pthread_attr_getstacksize = __root.pthread_attr_getstacksize;
    pub const pthread_attr_setstacksize = __root.pthread_attr_setstacksize;
    pub const pthread_attr_getstack = __root.pthread_attr_getstack;
    pub const pthread_attr_setstack = __root.pthread_attr_setstack;
    pub const pthread_attr_setaffinity_np = __root.pthread_attr_setaffinity_np;
    pub const pthread_attr_getaffinity_np = __root.pthread_attr_getaffinity_np;
    pub const pthread_getattr_default_np = __root.pthread_getattr_default_np;
    pub const pthread_attr_setsigmask_np = __root.pthread_attr_setsigmask_np;
    pub const pthread_attr_getsigmask_np = __root.pthread_attr_getsigmask_np;
    pub const pthread_setattr_default_np = __root.pthread_setattr_default_np;
    pub const init = __root.pthread_attr_init;
    pub const destroy = __root.pthread_attr_destroy;
    pub const getdetachstate = __root.pthread_attr_getdetachstate;
    pub const setdetachstate = __root.pthread_attr_setdetachstate;
    pub const getguardsize = __root.pthread_attr_getguardsize;
    pub const setguardsize = __root.pthread_attr_setguardsize;
    pub const getschedparam = __root.pthread_attr_getschedparam;
    pub const setschedparam = __root.pthread_attr_setschedparam;
    pub const getschedpolicy = __root.pthread_attr_getschedpolicy;
    pub const setschedpolicy = __root.pthread_attr_setschedpolicy;
    pub const getinheritsched = __root.pthread_attr_getinheritsched;
    pub const setinheritsched = __root.pthread_attr_setinheritsched;
    pub const getscope = __root.pthread_attr_getscope;
    pub const setscope = __root.pthread_attr_setscope;
    pub const getstackaddr = __root.pthread_attr_getstackaddr;
    pub const setstackaddr = __root.pthread_attr_setstackaddr;
    pub const getstacksize = __root.pthread_attr_getstacksize;
    pub const setstacksize = __root.pthread_attr_setstacksize;
    pub const getstack = __root.pthread_attr_getstack;
    pub const setstack = __root.pthread_attr_setstack;
    pub const np = __root.pthread_attr_setaffinity_np;
};
pub const pthread_attr_t = union_pthread_attr_t;
pub const pthread_mutex_t = extern union {
    __data: struct___pthread_mutex_s,
    __size: [48]u8,
    __align: c_long,
    pub const pthread_mutex_init = __root.pthread_mutex_init;
    pub const pthread_mutex_destroy = __root.pthread_mutex_destroy;
    pub const pthread_mutex_trylock = __root.pthread_mutex_trylock;
    pub const pthread_mutex_lock = __root.pthread_mutex_lock;
    pub const pthread_mutex_timedlock = __root.pthread_mutex_timedlock;
    pub const pthread_mutex_clocklock = __root.pthread_mutex_clocklock;
    pub const pthread_mutex_unlock = __root.pthread_mutex_unlock;
    pub const pthread_mutex_getprioceiling = __root.pthread_mutex_getprioceiling;
    pub const pthread_mutex_setprioceiling = __root.pthread_mutex_setprioceiling;
    pub const pthread_mutex_consistent = __root.pthread_mutex_consistent;
    pub const pthread_mutex_consistent_np = __root.pthread_mutex_consistent_np;
    pub const init = __root.pthread_mutex_init;
    pub const destroy = __root.pthread_mutex_destroy;
    pub const trylock = __root.pthread_mutex_trylock;
    pub const lock = __root.pthread_mutex_lock;
    pub const timedlock = __root.pthread_mutex_timedlock;
    pub const clocklock = __root.pthread_mutex_clocklock;
    pub const unlock = __root.pthread_mutex_unlock;
    pub const getprioceiling = __root.pthread_mutex_getprioceiling;
    pub const setprioceiling = __root.pthread_mutex_setprioceiling;
    pub const consistent = __root.pthread_mutex_consistent;
    pub const np = __root.pthread_mutex_consistent_np;
};
pub const pthread_cond_t = extern union {
    __data: struct___pthread_cond_s,
    __size: [48]u8,
    __align: c_longlong,
    pub const pthread_cond_init = __root.pthread_cond_init;
    pub const pthread_cond_destroy = __root.pthread_cond_destroy;
    pub const pthread_cond_signal = __root.pthread_cond_signal;
    pub const pthread_cond_broadcast = __root.pthread_cond_broadcast;
    pub const pthread_cond_wait = __root.pthread_cond_wait;
    pub const pthread_cond_timedwait = __root.pthread_cond_timedwait;
    pub const pthread_cond_clockwait = __root.pthread_cond_clockwait;
    pub const init = __root.pthread_cond_init;
    pub const destroy = __root.pthread_cond_destroy;
    pub const signal = __root.pthread_cond_signal;
    pub const broadcast = __root.pthread_cond_broadcast;
    pub const wait = __root.pthread_cond_wait;
    pub const timedwait = __root.pthread_cond_timedwait;
    pub const clockwait = __root.pthread_cond_clockwait;
};
pub const pthread_rwlock_t = extern union {
    __data: struct___pthread_rwlock_arch_t,
    __size: [56]u8,
    __align: c_long,
    pub const pthread_rwlock_init = __root.pthread_rwlock_init;
    pub const pthread_rwlock_destroy = __root.pthread_rwlock_destroy;
    pub const pthread_rwlock_rdlock = __root.pthread_rwlock_rdlock;
    pub const pthread_rwlock_tryrdlock = __root.pthread_rwlock_tryrdlock;
    pub const pthread_rwlock_timedrdlock = __root.pthread_rwlock_timedrdlock;
    pub const pthread_rwlock_clockrdlock = __root.pthread_rwlock_clockrdlock;
    pub const pthread_rwlock_wrlock = __root.pthread_rwlock_wrlock;
    pub const pthread_rwlock_trywrlock = __root.pthread_rwlock_trywrlock;
    pub const pthread_rwlock_timedwrlock = __root.pthread_rwlock_timedwrlock;
    pub const pthread_rwlock_clockwrlock = __root.pthread_rwlock_clockwrlock;
    pub const pthread_rwlock_unlock = __root.pthread_rwlock_unlock;
    pub const init = __root.pthread_rwlock_init;
    pub const destroy = __root.pthread_rwlock_destroy;
    pub const rdlock = __root.pthread_rwlock_rdlock;
    pub const tryrdlock = __root.pthread_rwlock_tryrdlock;
    pub const timedrdlock = __root.pthread_rwlock_timedrdlock;
    pub const clockrdlock = __root.pthread_rwlock_clockrdlock;
    pub const wrlock = __root.pthread_rwlock_wrlock;
    pub const trywrlock = __root.pthread_rwlock_trywrlock;
    pub const timedwrlock = __root.pthread_rwlock_timedwrlock;
    pub const clockwrlock = __root.pthread_rwlock_clockwrlock;
    pub const unlock = __root.pthread_rwlock_unlock;
};
pub const pthread_rwlockattr_t = extern union {
    __size: [8]u8,
    __align: c_long,
    pub const pthread_rwlockattr_init = __root.pthread_rwlockattr_init;
    pub const pthread_rwlockattr_destroy = __root.pthread_rwlockattr_destroy;
    pub const pthread_rwlockattr_getpshared = __root.pthread_rwlockattr_getpshared;
    pub const pthread_rwlockattr_setpshared = __root.pthread_rwlockattr_setpshared;
    pub const pthread_rwlockattr_getkind_np = __root.pthread_rwlockattr_getkind_np;
    pub const pthread_rwlockattr_setkind_np = __root.pthread_rwlockattr_setkind_np;
    pub const init = __root.pthread_rwlockattr_init;
    pub const destroy = __root.pthread_rwlockattr_destroy;
    pub const getpshared = __root.pthread_rwlockattr_getpshared;
    pub const setpshared = __root.pthread_rwlockattr_setpshared;
    pub const np = __root.pthread_rwlockattr_getkind_np;
};
pub const pthread_spinlock_t = c_int;
pub const pthread_barrier_t = extern union {
    __size: [32]u8,
    __align: c_long,
    pub const pthread_barrier_init = __root.pthread_barrier_init;
    pub const pthread_barrier_destroy = __root.pthread_barrier_destroy;
    pub const pthread_barrier_wait = __root.pthread_barrier_wait;
    pub const init = __root.pthread_barrier_init;
    pub const destroy = __root.pthread_barrier_destroy;
    pub const wait = __root.pthread_barrier_wait;
};
pub const pthread_barrierattr_t = extern union {
    __size: [8]u8,
    __align: c_int,
    pub const pthread_barrierattr_init = __root.pthread_barrierattr_init;
    pub const pthread_barrierattr_destroy = __root.pthread_barrierattr_destroy;
    pub const pthread_barrierattr_getpshared = __root.pthread_barrierattr_getpshared;
    pub const pthread_barrierattr_setpshared = __root.pthread_barrierattr_setpshared;
    pub const init = __root.pthread_barrierattr_init;
    pub const destroy = __root.pthread_barrierattr_destroy;
    pub const getpshared = __root.pthread_barrierattr_getpshared;
    pub const setpshared = __root.pthread_barrierattr_setpshared;
};
pub extern fn random() c_long;
pub extern fn srandom(__seed: c_uint) void;
pub extern fn initstate(__seed: c_uint, __statebuf: [*c]u8, __statelen: usize) [*c]u8;
pub extern fn setstate(__statebuf: [*c]u8) [*c]u8;
pub const struct_random_data = extern struct {
    fptr: [*c]i32 = null,
    rptr: [*c]i32 = null,
    state: [*c]i32 = null,
    rand_type: c_int = 0,
    rand_deg: c_int = 0,
    rand_sep: c_int = 0,
    end_ptr: [*c]i32 = null,
    pub const random_r = __root.random_r;
    pub const r = __root.random_r;
};
pub extern fn random_r(noalias __buf: [*c]struct_random_data, noalias __result: [*c]i32) c_int;
pub extern fn srandom_r(__seed: c_uint, __buf: [*c]struct_random_data) c_int;
pub extern fn initstate_r(__seed: c_uint, noalias __statebuf: [*c]u8, __statelen: usize, noalias __buf: [*c]struct_random_data) c_int;
pub extern fn setstate_r(noalias __statebuf: [*c]u8, noalias __buf: [*c]struct_random_data) c_int;
pub extern fn rand() c_int;
pub extern fn srand(__seed: c_uint) void;
pub extern fn rand_r(__seed: [*c]c_uint) c_int;
pub extern fn drand48() f64;
pub extern fn erand48(__xsubi: [*c]c_ushort) f64;
pub extern fn lrand48() c_long;
pub extern fn nrand48(__xsubi: [*c]c_ushort) c_long;
pub extern fn mrand48() c_long;
pub extern fn jrand48(__xsubi: [*c]c_ushort) c_long;
pub extern fn srand48(__seedval: c_long) void;
pub extern fn seed48(__seed16v: [*c]c_ushort) [*c]c_ushort;
pub extern fn lcong48(__param: [*c]c_ushort) void;
pub const struct_drand48_data = extern struct {
    __x: [3]c_ushort = @import("std").mem.zeroes([3]c_ushort),
    __old_x: [3]c_ushort = @import("std").mem.zeroes([3]c_ushort),
    __c: c_ushort = 0,
    __init: c_ushort = 0,
    __a: c_ulonglong = 0,
    pub const drand48_r = __root.drand48_r;
    pub const lrand48_r = __root.lrand48_r;
    pub const mrand48_r = __root.mrand48_r;
    pub const r = __root.drand48_r;
};
pub extern fn drand48_r(noalias __buffer: [*c]struct_drand48_data, noalias __result: [*c]f64) c_int;
pub extern fn erand48_r(__xsubi: [*c]c_ushort, noalias __buffer: [*c]struct_drand48_data, noalias __result: [*c]f64) c_int;
pub extern fn lrand48_r(noalias __buffer: [*c]struct_drand48_data, noalias __result: [*c]c_long) c_int;
pub extern fn nrand48_r(__xsubi: [*c]c_ushort, noalias __buffer: [*c]struct_drand48_data, noalias __result: [*c]c_long) c_int;
pub extern fn mrand48_r(noalias __buffer: [*c]struct_drand48_data, noalias __result: [*c]c_long) c_int;
pub extern fn jrand48_r(__xsubi: [*c]c_ushort, noalias __buffer: [*c]struct_drand48_data, noalias __result: [*c]c_long) c_int;
pub extern fn srand48_r(__seedval: c_long, __buffer: [*c]struct_drand48_data) c_int;
pub extern fn seed48_r(__seed16v: [*c]c_ushort, __buffer: [*c]struct_drand48_data) c_int;
pub extern fn lcong48_r(__param: [*c]c_ushort, __buffer: [*c]struct_drand48_data) c_int;
pub extern fn arc4random() __uint32_t;
pub extern fn arc4random_buf(__buf: ?*anyopaque, __size: usize) void;
pub extern fn arc4random_uniform(__upper_bound: __uint32_t) __uint32_t;
pub extern fn malloc(__size: usize) ?*anyopaque;
pub extern fn calloc(__nmemb: usize, __size: usize) ?*anyopaque;
pub extern fn realloc(__ptr: ?*anyopaque, __size: usize) ?*anyopaque;
pub extern fn free(__ptr: ?*anyopaque) void;
pub extern fn free_sized(__ptr: ?*anyopaque, __size: usize) void;
pub extern fn free_aligned_sized(__ptr: ?*anyopaque, __alignment: usize, __size: usize) void;
pub extern fn reallocarray(__ptr: ?*anyopaque, __nmemb: usize, __size: usize) ?*anyopaque;
pub extern fn alloca(__size: usize) ?*anyopaque;
pub extern fn valloc(__size: usize) ?*anyopaque;
pub extern fn posix_memalign(__memptr: [*c]?*anyopaque, __alignment: usize, __size: usize) c_int;
pub extern fn aligned_alloc(__alignment: usize, __size: usize) ?*anyopaque;
pub extern fn abort() noreturn;
pub extern fn atexit(__func: ?*const fn () callconv(.c) void) c_int;
pub extern fn at_quick_exit(__func: ?*const fn () callconv(.c) void) c_int;
pub extern fn on_exit(__func: ?*const fn (__status: c_int, __arg: ?*anyopaque) callconv(.c) void, __arg: ?*anyopaque) c_int;
pub extern fn exit(__status: c_int) noreturn;
pub extern fn quick_exit(__status: c_int) noreturn;
pub extern fn _Exit(__status: c_int) noreturn;
pub extern fn getenv(__name: [*c]const u8) [*c]u8;
pub extern fn secure_getenv(__name: [*c]const u8) [*c]u8;
pub extern fn putenv(__string: [*c]u8) c_int;
pub extern fn setenv(__name: [*c]const u8, __value: [*c]const u8, __replace: c_int) c_int;
pub extern fn unsetenv(__name: [*c]const u8) c_int;
pub extern fn clearenv() c_int;
pub extern fn mktemp(__template: [*c]u8) [*c]u8;
pub extern fn mkstemp(__template: [*c]u8) c_int;
pub extern fn mkstemp64(__template: [*c]u8) c_int;
pub extern fn mkstemps(__template: [*c]u8, __suffixlen: c_int) c_int;
pub extern fn mkstemps64(__template: [*c]u8, __suffixlen: c_int) c_int;
pub extern fn mkdtemp(__template: [*c]u8) [*c]u8;
pub extern fn mkostemp(__template: [*c]u8, __flags: c_int) c_int;
pub extern fn mkostemp64(__template: [*c]u8, __flags: c_int) c_int;
pub extern fn mkostemps(__template: [*c]u8, __suffixlen: c_int, __flags: c_int) c_int;
pub extern fn mkostemps64(__template: [*c]u8, __suffixlen: c_int, __flags: c_int) c_int;
pub extern fn system(__command: [*c]const u8) c_int;
pub extern fn canonicalize_file_name(__name: [*c]const u8) [*c]u8;
pub extern fn realpath(noalias __name: [*c]const u8, noalias __resolved: [*c]u8) [*c]u8;
pub const __compar_fn_t = ?*const fn (?*const anyopaque, ?*const anyopaque) callconv(.c) c_int;
pub const comparison_fn_t = __compar_fn_t;
pub const __compar_d_fn_t = ?*const fn (?*const anyopaque, ?*const anyopaque, ?*anyopaque) callconv(.c) c_int;
pub extern fn bsearch(__key: ?*const anyopaque, __base: ?*const anyopaque, __nmemb: usize, __size: usize, __compar: __compar_fn_t) ?*anyopaque;
pub extern fn qsort(__base: ?*anyopaque, __nmemb: usize, __size: usize, __compar: __compar_fn_t) void;
pub extern fn qsort_r(__base: ?*anyopaque, __nmemb: usize, __size: usize, __compar: __compar_d_fn_t, __arg: ?*anyopaque) void;
pub extern fn abs(__x: c_int) c_int;
pub extern fn labs(__x: c_long) c_long;
pub extern fn llabs(__x: c_longlong) c_longlong;
pub extern fn uabs(__x: c_int) c_uint;
pub extern fn ulabs(__x: c_long) c_ulong;
pub extern fn ullabs(__x: c_longlong) c_ulonglong;
pub extern fn div(__numer: c_int, __denom: c_int) div_t;
pub extern fn ldiv(__numer: c_long, __denom: c_long) ldiv_t;
pub extern fn lldiv(__numer: c_longlong, __denom: c_longlong) lldiv_t;
pub extern fn ecvt(__value: f64, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int) [*c]u8;
pub extern fn fcvt(__value: f64, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int) [*c]u8;
pub extern fn gcvt(__value: f64, __ndigit: c_int, __buf: [*c]u8) [*c]u8;
pub extern fn qecvt(__value: c_longdouble, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int) [*c]u8;
pub extern fn qfcvt(__value: c_longdouble, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int) [*c]u8;
pub extern fn qgcvt(__value: c_longdouble, __ndigit: c_int, __buf: [*c]u8) [*c]u8;
pub extern fn ecvt_r(__value: f64, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int, noalias __buf: [*c]u8, __len: usize) c_int;
pub extern fn fcvt_r(__value: f64, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int, noalias __buf: [*c]u8, __len: usize) c_int;
pub extern fn qecvt_r(__value: c_longdouble, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int, noalias __buf: [*c]u8, __len: usize) c_int;
pub extern fn qfcvt_r(__value: c_longdouble, __ndigit: c_int, noalias __decpt: [*c]c_int, noalias __sign: [*c]c_int, noalias __buf: [*c]u8, __len: usize) c_int;
pub extern fn mblen(__s: [*c]const u8, __n: usize) c_int;
pub extern fn mbtowc(noalias __pwc: [*c]wchar_t, noalias __s: [*c]const u8, __n: usize) c_int;
pub extern fn wctomb(__s: [*c]u8, __wchar: wchar_t) c_int;
pub extern fn mbstowcs(noalias __pwcs: [*c]wchar_t, noalias __s: [*c]const u8, __n: usize) usize;
pub extern fn wcstombs(noalias __s: [*c]u8, noalias __pwcs: [*c]const wchar_t, __n: usize) usize;
pub extern fn rpmatch(__response: [*c]const u8) c_int;
pub extern fn getsubopt(noalias __optionp: [*c][*c]u8, noalias __tokens: [*c]const [*c]u8, noalias __valuep: [*c][*c]u8) c_int;
pub extern fn posix_openpt(__oflag: c_int) c_int;
pub extern fn grantpt(__fd: c_int) c_int;
pub extern fn unlockpt(__fd: c_int) c_int;
pub extern fn ptsname(__fd: c_int) [*c]u8;
pub extern fn ptsname_r(__fd: c_int, __buf: [*c]u8, __buflen: usize) c_int;
pub extern fn getpt() c_int;
pub extern fn getloadavg(__loadavg: [*c]f64, __nelem: c_int) c_int;
pub const once_flag = __once_flag;
pub extern fn call_once(__flag: [*c]once_flag, __func: ?*const fn () callconv(.c) void) void;
pub extern fn memalignment(__p: ?*const anyopaque) usize;
pub extern fn memcpy(noalias __dest: ?*anyopaque, noalias __src: ?*const anyopaque, __n: usize) ?*anyopaque;
pub extern fn memmove(__dest: ?*anyopaque, __src: ?*const anyopaque, __n: usize) ?*anyopaque;
pub extern fn memccpy(noalias __dest: ?*anyopaque, noalias __src: ?*const anyopaque, __c: c_int, __n: usize) ?*anyopaque;
pub extern fn memset(__s: ?*anyopaque, __c: c_int, __n: usize) ?*anyopaque;
pub extern fn memset_explicit(__s: ?*anyopaque, __c: c_int, __n: usize) ?*anyopaque;
pub extern fn memcmp(__s1: ?*const anyopaque, __s2: ?*const anyopaque, __n: usize) c_int;
pub extern fn __memcmpeq(__s1: ?*const anyopaque, __s2: ?*const anyopaque, __n: usize) c_int;
pub extern fn memchr(__s: ?*const anyopaque, __c: c_int, __n: usize) ?*anyopaque;
pub extern fn rawmemchr(__s: ?*const anyopaque, __c: c_int) ?*anyopaque;
pub extern fn memrchr(__s: ?*const anyopaque, __c: c_int, __n: usize) ?*anyopaque;
pub extern fn strcpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8) [*c]u8;
pub extern fn strncpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) [*c]u8;
pub extern fn strcat(noalias __dest: [*c]u8, noalias __src: [*c]const u8) [*c]u8;
pub extern fn strncat(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) [*c]u8;
pub extern fn strcmp(__s1: [*c]const u8, __s2: [*c]const u8) c_int;
pub extern fn strncmp(__s1: [*c]const u8, __s2: [*c]const u8, __n: usize) c_int;
pub extern fn strcoll(__s1: [*c]const u8, __s2: [*c]const u8) c_int;
pub extern fn strxfrm(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) usize;
pub extern fn strcoll_l(__s1: [*c]const u8, __s2: [*c]const u8, __l: locale_t) c_int;
pub extern fn strxfrm_l(__dest: [*c]u8, __src: [*c]const u8, __n: usize, __l: locale_t) usize;
pub extern fn strdup(__s: [*c]const u8) [*c]u8;
pub extern fn strndup(__string: [*c]const u8, __n: usize) [*c]u8;
pub extern fn strchr(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn strrchr(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn strchrnul(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn strcspn(__s: [*c]const u8, __reject: [*c]const u8) usize;
pub extern fn strspn(__s: [*c]const u8, __accept: [*c]const u8) usize;
pub extern fn strpbrk(__s: [*c]const u8, __accept: [*c]const u8) [*c]u8;
pub extern fn strstr(__haystack: [*c]const u8, __needle: [*c]const u8) [*c]u8;
pub extern fn strtok(noalias __s: [*c]u8, noalias __delim: [*c]const u8) [*c]u8;
pub extern fn __strtok_r(noalias __s: [*c]u8, noalias __delim: [*c]const u8, noalias __save_ptr: [*c][*c]u8) [*c]u8;
pub extern fn strtok_r(noalias __s: [*c]u8, noalias __delim: [*c]const u8, noalias __save_ptr: [*c][*c]u8) [*c]u8;
pub extern fn strcasestr(__haystack: [*c]const u8, __needle: [*c]const u8) [*c]u8;
pub extern fn memmem(__haystack: ?*const anyopaque, __haystacklen: usize, __needle: ?*const anyopaque, __needlelen: usize) ?*anyopaque;
pub extern fn __mempcpy(noalias __dest: ?*anyopaque, noalias __src: ?*const anyopaque, __n: usize) ?*anyopaque;
pub extern fn mempcpy(noalias __dest: ?*anyopaque, noalias __src: ?*const anyopaque, __n: usize) ?*anyopaque;
pub extern fn strlen(__s: [*c]const u8) usize;
pub extern fn strnlen(__string: [*c]const u8, __maxlen: usize) usize;
pub extern fn strerror(__errnum: c_int) [*c]u8;
pub extern fn strerror_r(__errnum: c_int, __buf: [*c]u8, __buflen: usize) [*c]u8;
pub extern fn strerrordesc_np(__err: c_int) [*c]const u8;
pub extern fn strerrorname_np(__err: c_int) [*c]const u8;
pub extern fn strerror_l(__errnum: c_int, __l: locale_t) [*c]u8;
pub extern fn bcmp(__s1: ?*const anyopaque, __s2: ?*const anyopaque, __n: usize) c_int;
pub extern fn bcopy(__src: ?*const anyopaque, __dest: ?*anyopaque, __n: usize) void;
pub extern fn bzero(__s: ?*anyopaque, __n: usize) void;
pub extern fn index(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn rindex(__s: [*c]const u8, __c: c_int) [*c]u8;
pub extern fn ffs(__i: c_int) c_int;
pub extern fn ffsl(__l: c_long) c_int;
pub extern fn ffsll(__ll: c_longlong) c_int;
pub extern fn strcasecmp(__s1: [*c]const u8, __s2: [*c]const u8) c_int;
pub extern fn strncasecmp(__s1: [*c]const u8, __s2: [*c]const u8, __n: usize) c_int;
pub extern fn strcasecmp_l(__s1: [*c]const u8, __s2: [*c]const u8, __loc: locale_t) c_int;
pub extern fn strncasecmp_l(__s1: [*c]const u8, __s2: [*c]const u8, __n: usize, __loc: locale_t) c_int;
pub extern fn explicit_bzero(__s: ?*anyopaque, __n: usize) void;
pub extern fn strsep(noalias __stringp: [*c][*c]u8, noalias __delim: [*c]const u8) [*c]u8;
pub extern fn strsignal(__sig: c_int) [*c]u8;
pub extern fn sigabbrev_np(__sig: c_int) [*c]const u8;
pub extern fn sigdescr_np(__sig: c_int) [*c]const u8;
pub extern fn __stpcpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8) [*c]u8;
pub extern fn stpcpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8) [*c]u8;
pub extern fn __stpncpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) [*c]u8;
pub extern fn stpncpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) [*c]u8;
pub extern fn strlcpy(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) usize;
pub extern fn strlcat(noalias __dest: [*c]u8, noalias __src: [*c]const u8, __n: usize) usize;
pub extern fn strverscmp(__s1: [*c]const u8, __s2: [*c]const u8) c_int;
pub extern fn strfry(__string: [*c]u8) [*c]u8;
pub extern fn memfrob(__s: ?*anyopaque, __n: usize) ?*anyopaque;
pub extern fn basename(__filename: [*c]const u8) [*c]u8;
pub extern var program_invocation_name: [*c]u8;
pub extern var program_invocation_short_name: [*c]u8;
pub const error_t = c_int;
pub const struct_stat = extern struct {
    st_dev: __dev_t = 0,
    st_ino: __ino_t = 0,
    st_mode: __mode_t = 0,
    st_nlink: __nlink_t = 0,
    st_uid: __uid_t = 0,
    st_gid: __gid_t = 0,
    st_rdev: __dev_t = 0,
    __pad1: __dev_t = 0,
    st_size: __off_t = 0,
    st_blksize: __blksize_t = 0,
    __pad2: c_int = 0,
    st_blocks: __blkcnt_t = 0,
    st_atim: struct_timespec = @import("std").mem.zeroes(struct_timespec),
    st_mtim: struct_timespec = @import("std").mem.zeroes(struct_timespec),
    st_ctim: struct_timespec = @import("std").mem.zeroes(struct_timespec),
    __glibc_reserved: [2]c_int = @import("std").mem.zeroes([2]c_int),
};
pub const struct_stat64 = extern struct {
    st_dev: __dev_t = 0,
    st_ino: __ino64_t = 0,
    st_mode: __mode_t = 0,
    st_nlink: __nlink_t = 0,
    st_uid: __uid_t = 0,
    st_gid: __gid_t = 0,
    st_rdev: __dev_t = 0,
    __pad1: __dev_t = 0,
    st_size: __off64_t = 0,
    st_blksize: __blksize_t = 0,
    __pad2: c_int = 0,
    st_blocks: __blkcnt64_t = 0,
    st_atim: struct_timespec = @import("std").mem.zeroes(struct_timespec),
    st_mtim: struct_timespec = @import("std").mem.zeroes(struct_timespec),
    st_ctim: struct_timespec = @import("std").mem.zeroes(struct_timespec),
    __glibc_reserved: [2]c_int = @import("std").mem.zeroes([2]c_int),
};
pub extern fn stat(noalias __file: [*c]const u8, noalias __buf: [*c]struct_stat) c_int;
pub extern fn fstat(__fd: c_int, __buf: [*c]struct_stat) c_int;
pub extern fn stat64(noalias __file: [*c]const u8, noalias __buf: [*c]struct_stat64) c_int;
pub extern fn fstat64(__fd: c_int, __buf: [*c]struct_stat64) c_int;
pub extern fn fstatat(__fd: c_int, noalias __file: [*c]const u8, noalias __buf: [*c]struct_stat, __flag: c_int) c_int;
pub extern fn fstatat64(__fd: c_int, noalias __file: [*c]const u8, noalias __buf: [*c]struct_stat64, __flag: c_int) c_int;
pub extern fn lstat(noalias __file: [*c]const u8, noalias __buf: [*c]struct_stat) c_int;
pub extern fn lstat64(noalias __file: [*c]const u8, noalias __buf: [*c]struct_stat64) c_int;
pub extern fn chmod(__file: [*c]const u8, __mode: __mode_t) c_int;
pub extern fn lchmod(__file: [*c]const u8, __mode: __mode_t) c_int;
pub extern fn fchmod(__fd: c_int, __mode: __mode_t) c_int;
pub extern fn fchmodat(__fd: c_int, __file: [*c]const u8, __mode: __mode_t, __flag: c_int) c_int;
pub extern fn umask(__mask: __mode_t) __mode_t;
pub extern fn getumask() __mode_t;
pub extern fn mkdir(__path: [*c]const u8, __mode: __mode_t) c_int;
pub extern fn mkdirat(__fd: c_int, __path: [*c]const u8, __mode: __mode_t) c_int;
pub extern fn mknod(__path: [*c]const u8, __mode: __mode_t, __dev: __dev_t) c_int;
pub extern fn mknodat(__fd: c_int, __path: [*c]const u8, __mode: __mode_t, __dev: __dev_t) c_int;
pub extern fn mkfifo(__path: [*c]const u8, __mode: __mode_t) c_int;
pub extern fn mkfifoat(__fd: c_int, __path: [*c]const u8, __mode: __mode_t) c_int;
pub extern fn utimensat(__fd: c_int, __path: [*c]const u8, __times: [*c]const struct_timespec, __flags: c_int) c_int;
pub extern fn futimens(__fd: c_int, __times: [*c]const struct_timespec) c_int;
pub const __s8 = i8;
pub const __u8 = u8;
pub const __s16 = c_short;
pub const __u16 = c_ushort;
pub const __s32 = c_int;
pub const __u32 = c_uint;
pub const __s64 = c_longlong;
pub const __u64 = c_ulonglong;
pub const __kernel_fd_set = extern struct {
    fds_bits: [16]c_ulong = @import("std").mem.zeroes([16]c_ulong),
};
pub const __kernel_sighandler_t = ?*const fn (c_int) callconv(.c) void;
pub const __kernel_key_t = c_int;
pub const __kernel_mqd_t = c_int;
pub const __kernel_old_uid_t = c_ushort;
pub const __kernel_old_gid_t = c_ushort;
pub const __kernel_long_t = c_long;
pub const __kernel_ulong_t = c_ulong;
pub const __kernel_ino_t = __kernel_ulong_t;
pub const __kernel_mode_t = c_uint;
pub const __kernel_pid_t = c_int;
pub const __kernel_ipc_pid_t = c_int;
pub const __kernel_uid_t = c_uint;
pub const __kernel_gid_t = c_uint;
pub const __kernel_suseconds_t = __kernel_long_t;
pub const __kernel_daddr_t = c_int;
pub const __kernel_uid32_t = c_uint;
pub const __kernel_gid32_t = c_uint;
pub const __kernel_old_dev_t = c_uint;
pub const __kernel_size_t = __kernel_ulong_t;
pub const __kernel_ssize_t = __kernel_long_t;
pub const __kernel_ptrdiff_t = __kernel_long_t;
pub const __kernel_fsid_t = extern struct {
    val: [2]c_int = @import("std").mem.zeroes([2]c_int),
};
pub const __kernel_off_t = __kernel_long_t;
pub const __kernel_loff_t = c_longlong;
pub const __kernel_uoff_t = c_ulonglong;
pub const __kernel_old_time_t = __kernel_long_t;
pub const __kernel_time_t = __kernel_long_t;
pub const __kernel_time64_t = c_longlong;
pub const __kernel_clock_t = __kernel_long_t;
pub const __kernel_timer_t = c_int;
pub const __kernel_clockid_t = c_int;
pub const __kernel_caddr_t = [*c]u8;
pub const __kernel_uid16_t = c_ushort;
pub const __kernel_gid16_t = c_ushort;
pub const __s128 = i128;
pub const __u128 = u128;
pub const __le16 = __u16;
pub const __be16 = __u16;
pub const __le32 = __u32;
pub const __be32 = __u32;
pub const __le64 = __u64;
pub const __be64 = __u64;
pub const __sum16 = __u16;
pub const __wsum = __u32;
pub const __poll_t = c_uint;
pub const struct_statx_timestamp = extern struct {
    tv_sec: __s64 = 0,
    tv_nsec: __u32 = 0,
    __reserved: __s32 = 0,
};
pub const struct_statx = extern struct {
    stx_mask: __u32 = 0,
    stx_blksize: __u32 = 0,
    stx_attributes: __u64 = 0,
    stx_nlink: __u32 = 0,
    stx_uid: __u32 = 0,
    stx_gid: __u32 = 0,
    stx_mode: __u16 = 0,
    __spare0: [1]__u16 = @import("std").mem.zeroes([1]__u16),
    stx_ino: __u64 = 0,
    stx_size: __u64 = 0,
    stx_blocks: __u64 = 0,
    stx_attributes_mask: __u64 = 0,
    stx_atime: struct_statx_timestamp = @import("std").mem.zeroes(struct_statx_timestamp),
    stx_btime: struct_statx_timestamp = @import("std").mem.zeroes(struct_statx_timestamp),
    stx_ctime: struct_statx_timestamp = @import("std").mem.zeroes(struct_statx_timestamp),
    stx_mtime: struct_statx_timestamp = @import("std").mem.zeroes(struct_statx_timestamp),
    stx_rdev_major: __u32 = 0,
    stx_rdev_minor: __u32 = 0,
    stx_dev_major: __u32 = 0,
    stx_dev_minor: __u32 = 0,
    stx_mnt_id: __u64 = 0,
    stx_dio_mem_align: __u32 = 0,
    stx_dio_offset_align: __u32 = 0,
    stx_subvol: __u64 = 0,
    stx_atomic_write_unit_min: __u32 = 0,
    stx_atomic_write_unit_max: __u32 = 0,
    stx_atomic_write_segments_max: __u32 = 0,
    stx_dio_read_offset_align: __u32 = 0,
    stx_atomic_write_unit_max_opt: __u32 = 0,
    __spare2: [1]__u32 = @import("std").mem.zeroes([1]__u32),
    __spare3: [8]__u64 = @import("std").mem.zeroes([8]__u64),
};
pub extern fn statx(__dirfd: c_int, noalias __path: [*c]const u8, __flags: c_int, __mask: c_uint, noalias __buf: [*c]struct_statx) c_int;
pub const struct_flock = extern struct {
    l_type: c_short = 0,
    l_whence: c_short = 0,
    l_start: __off_t = 0,
    l_len: __off_t = 0,
    l_pid: __pid_t = 0,
};
pub const struct_flock64 = extern struct {
    l_type: c_short = 0,
    l_whence: c_short = 0,
    l_start: __off64_t = 0,
    l_len: __off64_t = 0,
    l_pid: __pid_t = 0,
};
pub const struct_iovec = extern struct {
    iov_base: ?*anyopaque = null,
    iov_len: usize = 0,
};
pub const F_OWNER_TID: c_int = 0;
pub const F_OWNER_PID: c_int = 1;
pub const F_OWNER_PGRP: c_int = 2;
pub const F_OWNER_GID: c_int = 2;
pub const enum___pid_type = c_uint;
pub const struct_f_owner_ex = extern struct {
    type: enum___pid_type = @import("std").mem.zeroes(enum___pid_type),
    pid: __pid_t = 0,
};
pub const struct_file_handle = extern struct {
    handle_bytes: c_uint = 0,
    handle_type: c_int = 0,
    _f_handle: [0]u8 = @import("std").mem.zeroes([0]u8),
    pub fn f_handle(_self: anytype) __helpers.FlexibleArrayType(@TypeOf(_self), @typeInfo(@TypeOf(_self.*._f_handle)).array.child) {
        return @ptrCast(@alignCast(&_self.*._f_handle));
    }
};
pub extern fn readahead(__fd: c_int, __offset: __off64_t, __count: usize) __ssize_t;
pub extern fn sync_file_range(__fd: c_int, __offset: __off64_t, __count: __off64_t, __flags: c_uint) c_int;
pub extern fn vmsplice(__fdout: c_int, __iov: [*c]const struct_iovec, __count: usize, __flags: c_uint) __ssize_t;
pub extern fn splice(__fdin: c_int, __offin: [*c]__off64_t, __fdout: c_int, __offout: [*c]__off64_t, __len: usize, __flags: c_uint) __ssize_t;
pub extern fn tee(__fdin: c_int, __fdout: c_int, __len: usize, __flags: c_uint) __ssize_t;
pub extern fn fallocate(__fd: c_int, __mode: c_int, __offset: __off_t, __len: __off_t) c_int;
pub extern fn fallocate64(__fd: c_int, __mode: c_int, __offset: __off64_t, __len: __off64_t) c_int;
pub extern fn name_to_handle_at(__dfd: c_int, __name: [*c]const u8, __handle: [*c]struct_file_handle, __mnt_id: [*c]c_int, __flags: c_int) c_int;
pub extern fn open_by_handle_at(__mountdirfd: c_int, __handle: [*c]struct_file_handle, __flags: c_int) c_int;
pub const struct_open_how = extern struct {
    flags: __u64 = 0,
    mode: __u64 = 0,
    resolve: __u64 = 0,
};
pub extern fn openat2(__dfd: c_int, __filename: [*c]const u8, __how: [*c]const struct_open_how, __usize: c_ulong) c_int;
pub extern fn fcntl(__fd: c_int, __cmd: c_int, ...) c_int;
pub extern fn fcntl64(__fd: c_int, __cmd: c_int, ...) c_int;
pub extern fn open(__file: [*c]const u8, __oflag: c_int, ...) c_int;
pub extern fn open64(__file: [*c]const u8, __oflag: c_int, ...) c_int;
pub extern fn openat(__fd: c_int, __file: [*c]const u8, __oflag: c_int, ...) c_int;
pub extern fn openat64(__fd: c_int, __file: [*c]const u8, __oflag: c_int, ...) c_int;
pub extern fn creat(__file: [*c]const u8, __mode: mode_t) c_int;
pub extern fn creat64(__file: [*c]const u8, __mode: mode_t) c_int;
pub extern fn lockf(__fd: c_int, __cmd: c_int, __len: off_t) c_int;
pub extern fn lockf64(__fd: c_int, __cmd: c_int, __len: off64_t) c_int;
pub extern fn posix_fadvise(__fd: c_int, __offset: off_t, __len: off_t, __advise: c_int) c_int;
pub extern fn posix_fadvise64(__fd: c_int, __offset: off64_t, __len: off64_t, __advise: c_int) c_int;
pub extern fn posix_fallocate(__fd: c_int, __offset: off_t, __len: off_t) c_int;
pub extern fn posix_fallocate64(__fd: c_int, __offset: off64_t, __len: off64_t) c_int;
pub const socklen_t = __socklen_t;
pub extern fn access(__name: [*c]const u8, __type: c_int) c_int;
pub extern fn euidaccess(__name: [*c]const u8, __type: c_int) c_int;
pub extern fn eaccess(__name: [*c]const u8, __type: c_int) c_int;
pub extern fn execveat(__fd: c_int, __path: [*c]const u8, __argv: [*c]const [*c]u8, __envp: [*c]const [*c]u8, __flags: c_int) c_int;
pub extern fn faccessat(__fd: c_int, __file: [*c]const u8, __type: c_int, __flag: c_int) c_int;
pub extern fn lseek(__fd: c_int, __offset: __off_t, __whence: c_int) __off_t;
pub extern fn lseek64(__fd: c_int, __offset: __off64_t, __whence: c_int) __off64_t;
pub extern fn close(__fd: c_int) c_int;
pub extern fn closefrom(__lowfd: c_int) void;
pub extern fn read(__fd: c_int, __buf: ?*anyopaque, __nbytes: usize) isize;
pub extern fn write(__fd: c_int, __buf: ?*const anyopaque, __n: usize) isize;
pub extern fn pread(__fd: c_int, __buf: ?*anyopaque, __nbytes: usize, __offset: __off_t) isize;
pub extern fn pwrite(__fd: c_int, __buf: ?*const anyopaque, __n: usize, __offset: __off_t) isize;
pub extern fn pread64(__fd: c_int, __buf: ?*anyopaque, __nbytes: usize, __offset: __off64_t) isize;
pub extern fn pwrite64(__fd: c_int, __buf: ?*const anyopaque, __n: usize, __offset: __off64_t) isize;
pub extern fn pipe(__pipedes: [*c]c_int) c_int;
pub extern fn pipe2(__pipedes: [*c]c_int, __flags: c_int) c_int;
pub extern fn alarm(__seconds: c_uint) c_uint;
pub extern fn sleep(__seconds: c_uint) c_uint;
pub extern fn ualarm(__value: __useconds_t, __interval: __useconds_t) __useconds_t;
pub extern fn usleep(__useconds: __useconds_t) c_int;
pub extern fn pause() c_int;
pub extern fn chown(__file: [*c]const u8, __owner: __uid_t, __group: __gid_t) c_int;
pub extern fn fchown(__fd: c_int, __owner: __uid_t, __group: __gid_t) c_int;
pub extern fn lchown(__file: [*c]const u8, __owner: __uid_t, __group: __gid_t) c_int;
pub extern fn fchownat(__fd: c_int, __file: [*c]const u8, __owner: __uid_t, __group: __gid_t, __flag: c_int) c_int;
pub extern fn chdir(__path: [*c]const u8) c_int;
pub extern fn fchdir(__fd: c_int) c_int;
pub extern fn getcwd(__buf: [*c]u8, __size: usize) [*c]u8;
pub extern fn get_current_dir_name() [*c]u8;
pub extern fn getwd(__buf: [*c]u8) [*c]u8;
pub extern fn dup(__fd: c_int) c_int;
pub extern fn dup2(__fd: c_int, __fd2: c_int) c_int;
pub extern fn dup3(__fd: c_int, __fd2: c_int, __flags: c_int) c_int;
pub extern var __environ: [*c][*c]u8;
pub extern var environ: [*c][*c]u8;
pub extern fn execve(__path: [*c]const u8, __argv: [*c]const [*c]u8, __envp: [*c]const [*c]u8) c_int;
pub extern fn fexecve(__fd: c_int, __argv: [*c]const [*c]u8, __envp: [*c]const [*c]u8) c_int;
pub extern fn execv(__path: [*c]const u8, __argv: [*c]const [*c]u8) c_int;
pub extern fn execle(__path: [*c]const u8, __arg: [*c]const u8, ...) c_int;
pub extern fn execl(__path: [*c]const u8, __arg: [*c]const u8, ...) c_int;
pub extern fn execvp(__file: [*c]const u8, __argv: [*c]const [*c]u8) c_int;
pub extern fn execlp(__file: [*c]const u8, __arg: [*c]const u8, ...) c_int;
pub extern fn execvpe(__file: [*c]const u8, __argv: [*c]const [*c]u8, __envp: [*c]const [*c]u8) c_int;
pub extern fn nice(__inc: c_int) c_int;
pub extern fn _exit(__status: c_int) noreturn;
pub const _PC_LINK_MAX: c_int = 0;
pub const _PC_MAX_CANON: c_int = 1;
pub const _PC_MAX_INPUT: c_int = 2;
pub const _PC_NAME_MAX: c_int = 3;
pub const _PC_PATH_MAX: c_int = 4;
pub const _PC_PIPE_BUF: c_int = 5;
pub const _PC_CHOWN_RESTRICTED: c_int = 6;
pub const _PC_NO_TRUNC: c_int = 7;
pub const _PC_VDISABLE: c_int = 8;
pub const _PC_SYNC_IO: c_int = 9;
pub const _PC_ASYNC_IO: c_int = 10;
pub const _PC_PRIO_IO: c_int = 11;
pub const _PC_SOCK_MAXBUF: c_int = 12;
pub const _PC_FILESIZEBITS: c_int = 13;
pub const _PC_REC_INCR_XFER_SIZE: c_int = 14;
pub const _PC_REC_MAX_XFER_SIZE: c_int = 15;
pub const _PC_REC_MIN_XFER_SIZE: c_int = 16;
pub const _PC_REC_XFER_ALIGN: c_int = 17;
pub const _PC_ALLOC_SIZE_MIN: c_int = 18;
pub const _PC_SYMLINK_MAX: c_int = 19;
pub const _PC_2_SYMLINKS: c_int = 20;
const enum_unnamed_5 = c_uint;
pub const _SC_ARG_MAX: c_int = 0;
pub const _SC_CHILD_MAX: c_int = 1;
pub const _SC_CLK_TCK: c_int = 2;
pub const _SC_NGROUPS_MAX: c_int = 3;
pub const _SC_OPEN_MAX: c_int = 4;
pub const _SC_STREAM_MAX: c_int = 5;
pub const _SC_TZNAME_MAX: c_int = 6;
pub const _SC_JOB_CONTROL: c_int = 7;
pub const _SC_SAVED_IDS: c_int = 8;
pub const _SC_REALTIME_SIGNALS: c_int = 9;
pub const _SC_PRIORITY_SCHEDULING: c_int = 10;
pub const _SC_TIMERS: c_int = 11;
pub const _SC_ASYNCHRONOUS_IO: c_int = 12;
pub const _SC_PRIORITIZED_IO: c_int = 13;
pub const _SC_SYNCHRONIZED_IO: c_int = 14;
pub const _SC_FSYNC: c_int = 15;
pub const _SC_MAPPED_FILES: c_int = 16;
pub const _SC_MEMLOCK: c_int = 17;
pub const _SC_MEMLOCK_RANGE: c_int = 18;
pub const _SC_MEMORY_PROTECTION: c_int = 19;
pub const _SC_MESSAGE_PASSING: c_int = 20;
pub const _SC_SEMAPHORES: c_int = 21;
pub const _SC_SHARED_MEMORY_OBJECTS: c_int = 22;
pub const _SC_AIO_LISTIO_MAX: c_int = 23;
pub const _SC_AIO_MAX: c_int = 24;
pub const _SC_AIO_PRIO_DELTA_MAX: c_int = 25;
pub const _SC_DELAYTIMER_MAX: c_int = 26;
pub const _SC_MQ_OPEN_MAX: c_int = 27;
pub const _SC_MQ_PRIO_MAX: c_int = 28;
pub const _SC_VERSION: c_int = 29;
pub const _SC_PAGESIZE: c_int = 30;
pub const _SC_RTSIG_MAX: c_int = 31;
pub const _SC_SEM_NSEMS_MAX: c_int = 32;
pub const _SC_SEM_VALUE_MAX: c_int = 33;
pub const _SC_SIGQUEUE_MAX: c_int = 34;
pub const _SC_TIMER_MAX: c_int = 35;
pub const _SC_BC_BASE_MAX: c_int = 36;
pub const _SC_BC_DIM_MAX: c_int = 37;
pub const _SC_BC_SCALE_MAX: c_int = 38;
pub const _SC_BC_STRING_MAX: c_int = 39;
pub const _SC_COLL_WEIGHTS_MAX: c_int = 40;
pub const _SC_EQUIV_CLASS_MAX: c_int = 41;
pub const _SC_EXPR_NEST_MAX: c_int = 42;
pub const _SC_LINE_MAX: c_int = 43;
pub const _SC_RE_DUP_MAX: c_int = 44;
pub const _SC_CHARCLASS_NAME_MAX: c_int = 45;
pub const _SC_2_VERSION: c_int = 46;
pub const _SC_2_C_BIND: c_int = 47;
pub const _SC_2_C_DEV: c_int = 48;
pub const _SC_2_FORT_DEV: c_int = 49;
pub const _SC_2_FORT_RUN: c_int = 50;
pub const _SC_2_SW_DEV: c_int = 51;
pub const _SC_2_LOCALEDEF: c_int = 52;
pub const _SC_PII: c_int = 53;
pub const _SC_PII_XTI: c_int = 54;
pub const _SC_PII_SOCKET: c_int = 55;
pub const _SC_PII_INTERNET: c_int = 56;
pub const _SC_PII_OSI: c_int = 57;
pub const _SC_POLL: c_int = 58;
pub const _SC_SELECT: c_int = 59;
pub const _SC_UIO_MAXIOV: c_int = 60;
pub const _SC_IOV_MAX: c_int = 60;
pub const _SC_PII_INTERNET_STREAM: c_int = 61;
pub const _SC_PII_INTERNET_DGRAM: c_int = 62;
pub const _SC_PII_OSI_COTS: c_int = 63;
pub const _SC_PII_OSI_CLTS: c_int = 64;
pub const _SC_PII_OSI_M: c_int = 65;
pub const _SC_T_IOV_MAX: c_int = 66;
pub const _SC_THREADS: c_int = 67;
pub const _SC_THREAD_SAFE_FUNCTIONS: c_int = 68;
pub const _SC_GETGR_R_SIZE_MAX: c_int = 69;
pub const _SC_GETPW_R_SIZE_MAX: c_int = 70;
pub const _SC_LOGIN_NAME_MAX: c_int = 71;
pub const _SC_TTY_NAME_MAX: c_int = 72;
pub const _SC_THREAD_DESTRUCTOR_ITERATIONS: c_int = 73;
pub const _SC_THREAD_KEYS_MAX: c_int = 74;
pub const _SC_THREAD_STACK_MIN: c_int = 75;
pub const _SC_THREAD_THREADS_MAX: c_int = 76;
pub const _SC_THREAD_ATTR_STACKADDR: c_int = 77;
pub const _SC_THREAD_ATTR_STACKSIZE: c_int = 78;
pub const _SC_THREAD_PRIORITY_SCHEDULING: c_int = 79;
pub const _SC_THREAD_PRIO_INHERIT: c_int = 80;
pub const _SC_THREAD_PRIO_PROTECT: c_int = 81;
pub const _SC_THREAD_PROCESS_SHARED: c_int = 82;
pub const _SC_NPROCESSORS_CONF: c_int = 83;
pub const _SC_NPROCESSORS_ONLN: c_int = 84;
pub const _SC_PHYS_PAGES: c_int = 85;
pub const _SC_AVPHYS_PAGES: c_int = 86;
pub const _SC_ATEXIT_MAX: c_int = 87;
pub const _SC_PASS_MAX: c_int = 88;
pub const _SC_XOPEN_VERSION: c_int = 89;
pub const _SC_XOPEN_XCU_VERSION: c_int = 90;
pub const _SC_XOPEN_UNIX: c_int = 91;
pub const _SC_XOPEN_CRYPT: c_int = 92;
pub const _SC_XOPEN_ENH_I18N: c_int = 93;
pub const _SC_XOPEN_SHM: c_int = 94;
pub const _SC_2_CHAR_TERM: c_int = 95;
pub const _SC_2_C_VERSION: c_int = 96;
pub const _SC_2_UPE: c_int = 97;
pub const _SC_XOPEN_XPG2: c_int = 98;
pub const _SC_XOPEN_XPG3: c_int = 99;
pub const _SC_XOPEN_XPG4: c_int = 100;
pub const _SC_CHAR_BIT: c_int = 101;
pub const _SC_CHAR_MAX: c_int = 102;
pub const _SC_CHAR_MIN: c_int = 103;
pub const _SC_INT_MAX: c_int = 104;
pub const _SC_INT_MIN: c_int = 105;
pub const _SC_LONG_BIT: c_int = 106;
pub const _SC_WORD_BIT: c_int = 107;
pub const _SC_MB_LEN_MAX: c_int = 108;
pub const _SC_NZERO: c_int = 109;
pub const _SC_SSIZE_MAX: c_int = 110;
pub const _SC_SCHAR_MAX: c_int = 111;
pub const _SC_SCHAR_MIN: c_int = 112;
pub const _SC_SHRT_MAX: c_int = 113;
pub const _SC_SHRT_MIN: c_int = 114;
pub const _SC_UCHAR_MAX: c_int = 115;
pub const _SC_UINT_MAX: c_int = 116;
pub const _SC_ULONG_MAX: c_int = 117;
pub const _SC_USHRT_MAX: c_int = 118;
pub const _SC_NL_ARGMAX: c_int = 119;
pub const _SC_NL_LANGMAX: c_int = 120;
pub const _SC_NL_MSGMAX: c_int = 121;
pub const _SC_NL_NMAX: c_int = 122;
pub const _SC_NL_SETMAX: c_int = 123;
pub const _SC_NL_TEXTMAX: c_int = 124;
pub const _SC_XBS5_ILP32_OFF32: c_int = 125;
pub const _SC_XBS5_ILP32_OFFBIG: c_int = 126;
pub const _SC_XBS5_LP64_OFF64: c_int = 127;
pub const _SC_XBS5_LPBIG_OFFBIG: c_int = 128;
pub const _SC_XOPEN_LEGACY: c_int = 129;
pub const _SC_XOPEN_REALTIME: c_int = 130;
pub const _SC_XOPEN_REALTIME_THREADS: c_int = 131;
pub const _SC_ADVISORY_INFO: c_int = 132;
pub const _SC_BARRIERS: c_int = 133;
pub const _SC_BASE: c_int = 134;
pub const _SC_C_LANG_SUPPORT: c_int = 135;
pub const _SC_C_LANG_SUPPORT_R: c_int = 136;
pub const _SC_CLOCK_SELECTION: c_int = 137;
pub const _SC_CPUTIME: c_int = 138;
pub const _SC_THREAD_CPUTIME: c_int = 139;
pub const _SC_DEVICE_IO: c_int = 140;
pub const _SC_DEVICE_SPECIFIC: c_int = 141;
pub const _SC_DEVICE_SPECIFIC_R: c_int = 142;
pub const _SC_FD_MGMT: c_int = 143;
pub const _SC_FIFO: c_int = 144;
pub const _SC_PIPE: c_int = 145;
pub const _SC_FILE_ATTRIBUTES: c_int = 146;
pub const _SC_FILE_LOCKING: c_int = 147;
pub const _SC_FILE_SYSTEM: c_int = 148;
pub const _SC_MONOTONIC_CLOCK: c_int = 149;
pub const _SC_MULTI_PROCESS: c_int = 150;
pub const _SC_SINGLE_PROCESS: c_int = 151;
pub const _SC_NETWORKING: c_int = 152;
pub const _SC_READER_WRITER_LOCKS: c_int = 153;
pub const _SC_SPIN_LOCKS: c_int = 154;
pub const _SC_REGEXP: c_int = 155;
pub const _SC_REGEX_VERSION: c_int = 156;
pub const _SC_SHELL: c_int = 157;
pub const _SC_SIGNALS: c_int = 158;
pub const _SC_SPAWN: c_int = 159;
pub const _SC_SPORADIC_SERVER: c_int = 160;
pub const _SC_THREAD_SPORADIC_SERVER: c_int = 161;
pub const _SC_SYSTEM_DATABASE: c_int = 162;
pub const _SC_SYSTEM_DATABASE_R: c_int = 163;
pub const _SC_TIMEOUTS: c_int = 164;
pub const _SC_TYPED_MEMORY_OBJECTS: c_int = 165;
pub const _SC_USER_GROUPS: c_int = 166;
pub const _SC_USER_GROUPS_R: c_int = 167;
pub const _SC_2_PBS: c_int = 168;
pub const _SC_2_PBS_ACCOUNTING: c_int = 169;
pub const _SC_2_PBS_LOCATE: c_int = 170;
pub const _SC_2_PBS_MESSAGE: c_int = 171;
pub const _SC_2_PBS_TRACK: c_int = 172;
pub const _SC_SYMLOOP_MAX: c_int = 173;
pub const _SC_STREAMS: c_int = 174;
pub const _SC_2_PBS_CHECKPOINT: c_int = 175;
pub const _SC_V6_ILP32_OFF32: c_int = 176;
pub const _SC_V6_ILP32_OFFBIG: c_int = 177;
pub const _SC_V6_LP64_OFF64: c_int = 178;
pub const _SC_V6_LPBIG_OFFBIG: c_int = 179;
pub const _SC_HOST_NAME_MAX: c_int = 180;
pub const _SC_TRACE: c_int = 181;
pub const _SC_TRACE_EVENT_FILTER: c_int = 182;
pub const _SC_TRACE_INHERIT: c_int = 183;
pub const _SC_TRACE_LOG: c_int = 184;
pub const _SC_LEVEL1_ICACHE_SIZE: c_int = 185;
pub const _SC_LEVEL1_ICACHE_ASSOC: c_int = 186;
pub const _SC_LEVEL1_ICACHE_LINESIZE: c_int = 187;
pub const _SC_LEVEL1_DCACHE_SIZE: c_int = 188;
pub const _SC_LEVEL1_DCACHE_ASSOC: c_int = 189;
pub const _SC_LEVEL1_DCACHE_LINESIZE: c_int = 190;
pub const _SC_LEVEL2_CACHE_SIZE: c_int = 191;
pub const _SC_LEVEL2_CACHE_ASSOC: c_int = 192;
pub const _SC_LEVEL2_CACHE_LINESIZE: c_int = 193;
pub const _SC_LEVEL3_CACHE_SIZE: c_int = 194;
pub const _SC_LEVEL3_CACHE_ASSOC: c_int = 195;
pub const _SC_LEVEL3_CACHE_LINESIZE: c_int = 196;
pub const _SC_LEVEL4_CACHE_SIZE: c_int = 197;
pub const _SC_LEVEL4_CACHE_ASSOC: c_int = 198;
pub const _SC_LEVEL4_CACHE_LINESIZE: c_int = 199;
pub const _SC_IPV6: c_int = 235;
pub const _SC_RAW_SOCKETS: c_int = 236;
pub const _SC_V7_ILP32_OFF32: c_int = 237;
pub const _SC_V7_ILP32_OFFBIG: c_int = 238;
pub const _SC_V7_LP64_OFF64: c_int = 239;
pub const _SC_V7_LPBIG_OFFBIG: c_int = 240;
pub const _SC_SS_REPL_MAX: c_int = 241;
pub const _SC_TRACE_EVENT_NAME_MAX: c_int = 242;
pub const _SC_TRACE_NAME_MAX: c_int = 243;
pub const _SC_TRACE_SYS_MAX: c_int = 244;
pub const _SC_TRACE_USER_EVENT_MAX: c_int = 245;
pub const _SC_XOPEN_STREAMS: c_int = 246;
pub const _SC_THREAD_ROBUST_PRIO_INHERIT: c_int = 247;
pub const _SC_THREAD_ROBUST_PRIO_PROTECT: c_int = 248;
pub const _SC_MINSIGSTKSZ: c_int = 249;
pub const _SC_SIGSTKSZ: c_int = 250;
const enum_unnamed_6 = c_uint;
pub const _CS_PATH: c_int = 0;
pub const _CS_V6_WIDTH_RESTRICTED_ENVS: c_int = 1;
pub const _CS_GNU_LIBC_VERSION: c_int = 2;
pub const _CS_GNU_LIBPTHREAD_VERSION: c_int = 3;
pub const _CS_V5_WIDTH_RESTRICTED_ENVS: c_int = 4;
pub const _CS_V7_WIDTH_RESTRICTED_ENVS: c_int = 5;
pub const _CS_LFS_CFLAGS: c_int = 1000;
pub const _CS_LFS_LDFLAGS: c_int = 1001;
pub const _CS_LFS_LIBS: c_int = 1002;
pub const _CS_LFS_LINTFLAGS: c_int = 1003;
pub const _CS_LFS64_CFLAGS: c_int = 1004;
pub const _CS_LFS64_LDFLAGS: c_int = 1005;
pub const _CS_LFS64_LIBS: c_int = 1006;
pub const _CS_LFS64_LINTFLAGS: c_int = 1007;
pub const _CS_XBS5_ILP32_OFF32_CFLAGS: c_int = 1100;
pub const _CS_XBS5_ILP32_OFF32_LDFLAGS: c_int = 1101;
pub const _CS_XBS5_ILP32_OFF32_LIBS: c_int = 1102;
pub const _CS_XBS5_ILP32_OFF32_LINTFLAGS: c_int = 1103;
pub const _CS_XBS5_ILP32_OFFBIG_CFLAGS: c_int = 1104;
pub const _CS_XBS5_ILP32_OFFBIG_LDFLAGS: c_int = 1105;
pub const _CS_XBS5_ILP32_OFFBIG_LIBS: c_int = 1106;
pub const _CS_XBS5_ILP32_OFFBIG_LINTFLAGS: c_int = 1107;
pub const _CS_XBS5_LP64_OFF64_CFLAGS: c_int = 1108;
pub const _CS_XBS5_LP64_OFF64_LDFLAGS: c_int = 1109;
pub const _CS_XBS5_LP64_OFF64_LIBS: c_int = 1110;
pub const _CS_XBS5_LP64_OFF64_LINTFLAGS: c_int = 1111;
pub const _CS_XBS5_LPBIG_OFFBIG_CFLAGS: c_int = 1112;
pub const _CS_XBS5_LPBIG_OFFBIG_LDFLAGS: c_int = 1113;
pub const _CS_XBS5_LPBIG_OFFBIG_LIBS: c_int = 1114;
pub const _CS_XBS5_LPBIG_OFFBIG_LINTFLAGS: c_int = 1115;
pub const _CS_POSIX_V6_ILP32_OFF32_CFLAGS: c_int = 1116;
pub const _CS_POSIX_V6_ILP32_OFF32_LDFLAGS: c_int = 1117;
pub const _CS_POSIX_V6_ILP32_OFF32_LIBS: c_int = 1118;
pub const _CS_POSIX_V6_ILP32_OFF32_LINTFLAGS: c_int = 1119;
pub const _CS_POSIX_V6_ILP32_OFFBIG_CFLAGS: c_int = 1120;
pub const _CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS: c_int = 1121;
pub const _CS_POSIX_V6_ILP32_OFFBIG_LIBS: c_int = 1122;
pub const _CS_POSIX_V6_ILP32_OFFBIG_LINTFLAGS: c_int = 1123;
pub const _CS_POSIX_V6_LP64_OFF64_CFLAGS: c_int = 1124;
pub const _CS_POSIX_V6_LP64_OFF64_LDFLAGS: c_int = 1125;
pub const _CS_POSIX_V6_LP64_OFF64_LIBS: c_int = 1126;
pub const _CS_POSIX_V6_LP64_OFF64_LINTFLAGS: c_int = 1127;
pub const _CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS: c_int = 1128;
pub const _CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS: c_int = 1129;
pub const _CS_POSIX_V6_LPBIG_OFFBIG_LIBS: c_int = 1130;
pub const _CS_POSIX_V6_LPBIG_OFFBIG_LINTFLAGS: c_int = 1131;
pub const _CS_POSIX_V7_ILP32_OFF32_CFLAGS: c_int = 1132;
pub const _CS_POSIX_V7_ILP32_OFF32_LDFLAGS: c_int = 1133;
pub const _CS_POSIX_V7_ILP32_OFF32_LIBS: c_int = 1134;
pub const _CS_POSIX_V7_ILP32_OFF32_LINTFLAGS: c_int = 1135;
pub const _CS_POSIX_V7_ILP32_OFFBIG_CFLAGS: c_int = 1136;
pub const _CS_POSIX_V7_ILP32_OFFBIG_LDFLAGS: c_int = 1137;
pub const _CS_POSIX_V7_ILP32_OFFBIG_LIBS: c_int = 1138;
pub const _CS_POSIX_V7_ILP32_OFFBIG_LINTFLAGS: c_int = 1139;
pub const _CS_POSIX_V7_LP64_OFF64_CFLAGS: c_int = 1140;
pub const _CS_POSIX_V7_LP64_OFF64_LDFLAGS: c_int = 1141;
pub const _CS_POSIX_V7_LP64_OFF64_LIBS: c_int = 1142;
pub const _CS_POSIX_V7_LP64_OFF64_LINTFLAGS: c_int = 1143;
pub const _CS_POSIX_V7_LPBIG_OFFBIG_CFLAGS: c_int = 1144;
pub const _CS_POSIX_V7_LPBIG_OFFBIG_LDFLAGS: c_int = 1145;
pub const _CS_POSIX_V7_LPBIG_OFFBIG_LIBS: c_int = 1146;
pub const _CS_POSIX_V7_LPBIG_OFFBIG_LINTFLAGS: c_int = 1147;
pub const _CS_V6_ENV: c_int = 1148;
pub const _CS_V7_ENV: c_int = 1149;
const enum_unnamed_7 = c_uint;
pub extern fn pathconf(__path: [*c]const u8, __name: c_int) c_long;
pub extern fn fpathconf(__fd: c_int, __name: c_int) c_long;
pub extern fn sysconf(__name: c_int) c_long;
pub extern fn confstr(__name: c_int, __buf: [*c]u8, __len: usize) usize;
pub extern fn getpid() __pid_t;
pub extern fn getppid() __pid_t;
pub extern fn getpgrp() __pid_t;
pub extern fn __getpgid(__pid: __pid_t) __pid_t;
pub extern fn getpgid(__pid: __pid_t) __pid_t;
pub extern fn setpgid(__pid: __pid_t, __pgid: __pid_t) c_int;
pub extern fn setpgrp() c_int;
pub extern fn setsid() __pid_t;
pub extern fn getsid(__pid: __pid_t) __pid_t;
pub extern fn getuid() __uid_t;
pub extern fn geteuid() __uid_t;
pub extern fn getgid() __gid_t;
pub extern fn getegid() __gid_t;
pub extern fn getgroups(__size: c_int, __list: [*c]__gid_t) c_int;
pub extern fn group_member(__gid: __gid_t) c_int;
pub extern fn setuid(__uid: __uid_t) c_int;
pub extern fn setreuid(__ruid: __uid_t, __euid: __uid_t) c_int;
pub extern fn seteuid(__uid: __uid_t) c_int;
pub extern fn setgid(__gid: __gid_t) c_int;
pub extern fn setregid(__rgid: __gid_t, __egid: __gid_t) c_int;
pub extern fn setegid(__gid: __gid_t) c_int;
pub extern fn getresuid(__ruid: [*c]__uid_t, __euid: [*c]__uid_t, __suid: [*c]__uid_t) c_int;
pub extern fn getresgid(__rgid: [*c]__gid_t, __egid: [*c]__gid_t, __sgid: [*c]__gid_t) c_int;
pub extern fn setresuid(__ruid: __uid_t, __euid: __uid_t, __suid: __uid_t) c_int;
pub extern fn setresgid(__rgid: __gid_t, __egid: __gid_t, __sgid: __gid_t) c_int;
pub extern fn fork() __pid_t;
pub extern fn vfork() __pid_t;
pub extern fn _Fork() __pid_t;
pub extern fn ttyname(__fd: c_int) [*c]u8;
pub extern fn ttyname_r(__fd: c_int, __buf: [*c]u8, __buflen: usize) c_int;
pub extern fn isatty(__fd: c_int) c_int;
pub extern fn ttyslot() c_int;
pub extern fn link(__from: [*c]const u8, __to: [*c]const u8) c_int;
pub extern fn linkat(__fromfd: c_int, __from: [*c]const u8, __tofd: c_int, __to: [*c]const u8, __flags: c_int) c_int;
pub extern fn symlink(__from: [*c]const u8, __to: [*c]const u8) c_int;
pub extern fn readlink(noalias __path: [*c]const u8, noalias __buf: [*c]u8, __len: usize) isize;
pub extern fn symlinkat(__from: [*c]const u8, __tofd: c_int, __to: [*c]const u8) c_int;
pub extern fn readlinkat(__fd: c_int, noalias __path: [*c]const u8, noalias __buf: [*c]u8, __len: usize) isize;
pub extern fn unlink(__name: [*c]const u8) c_int;
pub extern fn unlinkat(__fd: c_int, __name: [*c]const u8, __flag: c_int) c_int;
pub extern fn rmdir(__path: [*c]const u8) c_int;
pub extern fn tcgetpgrp(__fd: c_int) __pid_t;
pub extern fn tcsetpgrp(__fd: c_int, __pgrp_id: __pid_t) c_int;
pub extern fn getlogin() [*c]u8;
pub extern fn getlogin_r(__name: [*c]u8, __name_len: usize) c_int;
pub extern fn setlogin(__name: [*c]const u8) c_int;
pub extern var optarg: [*c]u8;
pub extern var optind: c_int;
pub extern var opterr: c_int;
pub extern var optopt: c_int;
pub extern fn getopt(___argc: c_int, ___argv: [*c]const [*c]u8, __shortopts: [*c]const u8) c_int;
pub extern fn gethostname(__name: [*c]u8, __len: usize) c_int;
pub extern fn sethostname(__name: [*c]const u8, __len: usize) c_int;
pub extern fn sethostid(__id: c_long) c_int;
pub extern fn getdomainname(__name: [*c]u8, __len: usize) c_int;
pub extern fn setdomainname(__name: [*c]const u8, __len: usize) c_int;
pub extern fn vhangup() c_int;
pub extern fn revoke(__file: [*c]const u8) c_int;
pub extern fn profil(__sample_buffer: [*c]c_ushort, __size: usize, __offset: usize, __scale: c_uint) c_int;
pub extern fn acct(__name: [*c]const u8) c_int;
pub extern fn getusershell() [*c]u8;
pub extern fn endusershell() void;
pub extern fn setusershell() void;
pub extern fn daemon(__nochdir: c_int, __noclose: c_int) c_int;
pub extern fn chroot(__path: [*c]const u8) c_int;
pub extern fn getpass(__prompt: [*c]const u8) [*c]u8;
pub extern fn fsync(__fd: c_int) c_int;
pub extern fn syncfs(__fd: c_int) c_int;
pub extern fn gethostid() c_long;
pub extern fn sync() void;
pub extern fn getpagesize() c_int;
pub extern fn getdtablesize() c_int;
pub extern fn truncate(__file: [*c]const u8, __length: __off_t) c_int;
pub extern fn truncate64(__file: [*c]const u8, __length: __off64_t) c_int;
pub extern fn ftruncate(__fd: c_int, __length: __off_t) c_int;
pub extern fn ftruncate64(__fd: c_int, __length: __off64_t) c_int;
pub extern fn brk(__addr: ?*anyopaque) c_int;
pub extern fn sbrk(__delta: isize) ?*anyopaque;
pub extern fn syscall(__sysno: c_long, ...) c_long;
pub extern fn copy_file_range(__infd: c_int, __pinoff: [*c]__off64_t, __outfd: c_int, __poutoff: [*c]__off64_t, __length: usize, __flags: c_uint) isize;
pub extern fn fdatasync(__fildes: c_int) c_int;
pub extern fn crypt(__key: [*c]const u8, __salt: [*c]const u8) [*c]u8;
pub extern fn swab(noalias __from: ?*const anyopaque, noalias __to: ?*anyopaque, __n: isize) void;
pub extern fn getentropy(__buffer: ?*anyopaque, __length: usize) c_int;
pub extern fn close_range(__fd: c_uint, __max_fd: c_uint, __flags: c_int) c_int;
pub extern fn gettid() __pid_t;
// src/jitterentropy-internal.h:462:10: warning: struct demoted to opaque type - has bitfield
pub const struct_jent_sha_ctx = opaque {
    pub const jent_sha3_256_init = __root.jent_sha3_256_init;
    pub const jent_sha3_update = __root.jent_sha3_update;
    pub const jent_sha3_final = __root.jent_sha3_final;
    pub const jent_shake256_init = __root.jent_shake256_init;
    pub const jent_drbg_generate_block = __root.jent_drbg_generate_block;
    pub const init = __root.jent_sha3_256_init;
    pub const update = __root.jent_sha3_update;
    pub const final = __root.jent_sha3_final;
    pub const block = __root.jent_drbg_generate_block;
};
// src/jitterentropy-internal.h:499:22: warning: struct demoted to opaque type - has opaque field
pub const struct_rand_data = opaque {
    pub const jent_read_entropy = __root.jent_read_entropy;
    pub const jent_entropy_collector_free = __root.jent_entropy_collector_free;
    pub const jent_selftest = __root.jent_selftest;
    pub const jent_status = __root.jent_status;
    pub const jent_entropy_collector_uuid = __root.jent_entropy_collector_uuid;
    pub const jent_entropy_collector_osr = __root.jent_entropy_collector_osr;
    pub const jent_entropy_collector_flags = __root.jent_entropy_collector_flags;
    pub const jent_entropy_collector_memsize = __root.jent_entropy_collector_memsize;
    pub const jent_entropy_collector_health_failure = __root.jent_entropy_collector_health_failure;
    pub const jent_entropy_collector_reinitializations = __root.jent_entropy_collector_reinitializations;
    pub const jent_entropy_collector_read_invocations = __root.jent_entropy_collector_read_invocations;
    pub const jent_entropy_collector_bytes_output = __root.jent_entropy_collector_bytes_output;
    pub const jent_entropy_collector_hashloops = __root.jent_entropy_collector_hashloops;
    pub const jent_lag_reset = __root.jent_lag_reset;
    pub const jent_lag_insert = __root.jent_lag_insert;
    pub const jent_apt_insert = __root.jent_apt_insert;
    pub const jent_rct_insert = __root.jent_rct_insert;
    pub const jent_rct_mem_insert = __root.jent_rct_mem_insert;
    pub const jent_lag_duplicate = __root.jent_lag_duplicate;
    pub const jent_apt_duplicate = __root.jent_apt_duplicate;
    pub const jent_rct_duplicate = __root.jent_rct_duplicate;
    pub const jent_rct_mem_duplicate = __root.jent_rct_mem_duplicate;
    pub const jent_health_duplicate = __root.jent_health_duplicate;
    pub const jent_stuck = __root.jent_stuck;
    pub const jent_health_insert_timestamp = __root.jent_health_insert_timestamp;
    pub const jent_health_failure_query = __root.jent_health_failure_query;
    pub const jent_health_failure = __root.jent_health_failure;
    pub const jent_health_init = __root.jent_health_init;
    pub const jent_measure_jitter_ntg1_memaccess = __root.jent_measure_jitter_ntg1_memaccess;
    pub const jent_measure_jitter_ntg1_sha3 = __root.jent_measure_jitter_ntg1_sha3;
    pub const jent_measure_jitter = __root.jent_measure_jitter;
    pub const jent_memaccess_pseudorandom = __root.jent_memaccess_pseudorandom;
    pub const jent_memaccess_deterministic = __root.jent_memaccess_deterministic;
    pub const jent_random_data_one = __root.jent_random_data_one;
    pub const jent_random_data = __root.jent_random_data;
    pub const jent_read_random_block = __root.jent_read_random_block;
    pub const jent_notime_settick = __root.jent_notime_settick;
    pub const jent_notime_unsettick = __root.jent_notime_unsettick;
    pub const jent_get_nstime_internal = __root.jent_get_nstime_internal;
    pub const jent_notime_enable = __root.jent_notime_enable;
    pub const jent_notime_disable = __root.jent_notime_disable;
    pub const ut_fips_failure = __root.ut_fips_failure;
    pub const entropy = __root.jent_read_entropy;
    pub const selftest = __root.jent_selftest;
    pub const status = __root.jent_status;
    pub const uuid = __root.jent_entropy_collector_uuid;
    pub const osr = __root.jent_entropy_collector_osr;
    pub const flags = __root.jent_entropy_collector_flags;
    pub const memsize = __root.jent_entropy_collector_memsize;
    pub const failure = __root.jent_entropy_collector_health_failure;
    pub const reinitializations = __root.jent_entropy_collector_reinitializations;
    pub const invocations = __root.jent_entropy_collector_read_invocations;
    pub const output = __root.jent_entropy_collector_bytes_output;
    pub const hashloops = __root.jent_entropy_collector_hashloops;
    pub const reset = __root.jent_lag_reset;
    pub const insert = __root.jent_lag_insert;
    pub const duplicate = __root.jent_lag_duplicate;
    pub const stuck = __root.jent_stuck;
    pub const timestamp = __root.jent_health_insert_timestamp;
    pub const query = __root.jent_health_failure_query;
    pub const init = __root.jent_health_init;
    pub const memaccess = __root.jent_measure_jitter_ntg1_memaccess;
    pub const sha3 = __root.jent_measure_jitter_ntg1_sha3;
    pub const jitter = __root.jent_measure_jitter;
    pub const pseudorandom = __root.jent_memaccess_pseudorandom;
    pub const deterministic = __root.jent_memaccess_deterministic;
    pub const one = __root.jent_random_data_one;
    pub const data = __root.jent_random_data;
    pub const block = __root.jent_read_random_block;
    pub const settick = __root.jent_notime_settick;
    pub const unsettick = __root.jent_notime_unsettick;
    pub const internal = __root.jent_get_nstime_internal;
    pub const enable = __root.jent_notime_enable;
    pub const disable = __root.jent_notime_disable;
};
pub extern fn jent_read_entropy(ec: ?*struct_rand_data, data: [*c]u8, len: usize) isize;
pub extern fn jent_read_entropy_safe(ec: [*c]?*struct_rand_data, data: [*c]u8, len: usize) isize;
pub extern fn jent_entropy_collector_alloc(osr: c_uint, flags: c_uint) ?*struct_rand_data;
pub extern fn jent_entropy_collector_free(entropy_collector: ?*struct_rand_data) void;
pub extern fn jent_entropy_init() c_int;
pub extern fn jent_entropy_init_ex(osr: c_uint, flags: c_uint) c_int;
pub extern fn jent_selftest(ec: ?*struct_rand_data) c_int;
pub const jent_fips_failure_cb = ?*const fn (ec: ?*struct_rand_data, health_failure: c_uint) callconv(.c) void;
pub extern fn jent_set_fips_failure_callback(cb: jent_fips_failure_cb) c_int;
pub extern fn jent_version() c_uint;
pub extern fn jent_status(ec: ?*const struct_rand_data, buf: [*c]u8, buflen: usize) c_int;
pub extern fn jent_entropy_collector_uuid(ec: ?*const struct_rand_data, buf: [*c]u8, buflen: usize) c_int;
pub extern fn jent_entropy_collector_osr(ec: ?*const struct_rand_data) c_uint;
pub extern fn jent_entropy_collector_flags(ec: ?*const struct_rand_data) c_uint;
pub extern fn jent_entropy_collector_memsize(ec: ?*const struct_rand_data) usize;
pub extern fn jent_entropy_collector_health_failure(ec: ?*const struct_rand_data) c_uint;
pub extern fn jent_entropy_collector_reinitializations(ec: ?*const struct_rand_data) c_uint;
pub extern fn jent_entropy_collector_read_invocations(ec: ?*const struct_rand_data) u64;
pub extern fn jent_entropy_collector_bytes_output(ec: ?*const struct_rand_data) u64;
pub extern fn jent_entropy_collector_hashloops(ec: ?*const struct_rand_data) c_uint;
pub extern fn jent_secure_memory_supported() c_int;
pub const struct_jent_notime_thread = extern struct {
    jent_notime_init: ?*const fn (ctx: [*c]?*anyopaque) callconv(.c) c_int = null,
    jent_notime_fini: ?*const fn (ctx: ?*anyopaque) callconv(.c) void = null,
    jent_notime_start: ?*const fn (ctx: ?*anyopaque, start_routine: ?*const fn (?*anyopaque) callconv(.c) ?*anyopaque, arg: ?*anyopaque) callconv(.c) c_int = null,
    jent_notime_stop: ?*const fn (ctx: ?*anyopaque) callconv(.c) void = null,
    pub const jent_entropy_switch_notime_impl = __root.jent_entropy_switch_notime_impl;
    pub const jent_notime_switch = __root.jent_notime_switch;
    pub const impl = __root.jent_entropy_switch_notime_impl;
    pub const @"switch" = __root.jent_notime_switch;
};
pub extern fn jent_entropy_switch_notime_impl(new_thread: [*c]struct_jent_notime_thread) c_int;
pub extern fn jent_entropy_set_notime_cpu(cpu: c_ulong) c_int;
pub extern fn jent_notime_init(ctx: [*c]?*anyopaque) c_int;
pub extern fn jent_notime_fini(ctx: ?*anyopaque) void;
pub const struct_timezone = extern struct {
    tz_minuteswest: c_int = 0,
    tz_dsttime: c_int = 0,
};
pub extern fn gettimeofday(noalias __tv: [*c]struct_timeval, noalias __tz: ?*anyopaque) c_int;
pub extern fn settimeofday(__tv: [*c]const struct_timeval, __tz: [*c]const struct_timezone) c_int;
pub extern fn adjtime(__delta: [*c]const struct_timeval, __olddelta: [*c]struct_timeval) c_int;
pub const ITIMER_REAL: c_int = 0;
pub const ITIMER_VIRTUAL: c_int = 1;
pub const ITIMER_PROF: c_int = 2;
pub const enum___itimer_which = c_uint;
pub const struct_itimerval = extern struct {
    it_interval: struct_timeval = @import("std").mem.zeroes(struct_timeval),
    it_value: struct_timeval = @import("std").mem.zeroes(struct_timeval),
};
pub const __itimer_which_t = enum___itimer_which;
pub extern fn getitimer(__which: __itimer_which_t, __value: [*c]struct_itimerval) c_int;
pub extern fn setitimer(__which: __itimer_which_t, noalias __new: [*c]const struct_itimerval, noalias __old: [*c]struct_itimerval) c_int;
pub extern fn utimes(__file: [*c]const u8, __tvp: [*c]const struct_timeval) c_int;
pub extern fn lutimes(__file: [*c]const u8, __tvp: [*c]const struct_timeval) c_int;
pub extern fn futimes(__fd: c_int, __tvp: [*c]const struct_timeval) c_int;
pub extern fn futimesat(__fd: c_int, __file: [*c]const u8, __tvp: [*c]const struct_timeval) c_int;
pub const RLIMIT_CPU: c_int = 0;
pub const RLIMIT_FSIZE: c_int = 1;
pub const RLIMIT_DATA: c_int = 2;
pub const RLIMIT_STACK: c_int = 3;
pub const RLIMIT_CORE: c_int = 4;
pub const __RLIMIT_RSS: c_int = 5;
pub const RLIMIT_NOFILE: c_int = 7;
pub const __RLIMIT_OFILE: c_int = 7;
pub const RLIMIT_AS: c_int = 9;
pub const __RLIMIT_NPROC: c_int = 6;
pub const __RLIMIT_MEMLOCK: c_int = 8;
pub const __RLIMIT_LOCKS: c_int = 10;
pub const __RLIMIT_SIGPENDING: c_int = 11;
pub const __RLIMIT_MSGQUEUE: c_int = 12;
pub const __RLIMIT_NICE: c_int = 13;
pub const __RLIMIT_RTPRIO: c_int = 14;
pub const __RLIMIT_RTTIME: c_int = 15;
pub const __RLIMIT_NLIMITS: c_int = 16;
pub const __RLIM_NLIMITS: c_int = 16;
pub const enum___rlimit_resource = c_uint;
pub const rlim_t = __rlim_t;
pub const rlim64_t = __rlim64_t;
pub const struct_rlimit = extern struct {
    rlim_cur: rlim_t = 0,
    rlim_max: rlim_t = 0,
};
pub const struct_rlimit64 = extern struct {
    rlim_cur: rlim64_t = 0,
    rlim_max: rlim64_t = 0,
};
pub const RUSAGE_SELF: c_int = 0;
pub const RUSAGE_CHILDREN: c_int = -1;
pub const RUSAGE_THREAD: c_int = 1;
pub const enum___rusage_who = c_int;
const union_unnamed_8 = extern union {
    ru_maxrss: c_long,
    __ru_maxrss_word: __syscall_slong_t,
};
const union_unnamed_9 = extern union {
    ru_ixrss: c_long,
    __ru_ixrss_word: __syscall_slong_t,
};
const union_unnamed_10 = extern union {
    ru_idrss: c_long,
    __ru_idrss_word: __syscall_slong_t,
};
const union_unnamed_11 = extern union {
    ru_isrss: c_long,
    __ru_isrss_word: __syscall_slong_t,
};
const union_unnamed_12 = extern union {
    ru_minflt: c_long,
    __ru_minflt_word: __syscall_slong_t,
};
const union_unnamed_13 = extern union {
    ru_majflt: c_long,
    __ru_majflt_word: __syscall_slong_t,
};
const union_unnamed_14 = extern union {
    ru_nswap: c_long,
    __ru_nswap_word: __syscall_slong_t,
};
const union_unnamed_15 = extern union {
    ru_inblock: c_long,
    __ru_inblock_word: __syscall_slong_t,
};
const union_unnamed_16 = extern union {
    ru_oublock: c_long,
    __ru_oublock_word: __syscall_slong_t,
};
const union_unnamed_17 = extern union {
    ru_msgsnd: c_long,
    __ru_msgsnd_word: __syscall_slong_t,
};
const union_unnamed_18 = extern union {
    ru_msgrcv: c_long,
    __ru_msgrcv_word: __syscall_slong_t,
};
const union_unnamed_19 = extern union {
    ru_nsignals: c_long,
    __ru_nsignals_word: __syscall_slong_t,
};
const union_unnamed_20 = extern union {
    ru_nvcsw: c_long,
    __ru_nvcsw_word: __syscall_slong_t,
};
const union_unnamed_21 = extern union {
    ru_nivcsw: c_long,
    __ru_nivcsw_word: __syscall_slong_t,
};
pub const struct_rusage = extern struct {
    ru_utime: struct_timeval = @import("std").mem.zeroes(struct_timeval),
    ru_stime: struct_timeval = @import("std").mem.zeroes(struct_timeval),
    unnamed_0: union_unnamed_8 = @import("std").mem.zeroes(union_unnamed_8),
    unnamed_1: union_unnamed_9 = @import("std").mem.zeroes(union_unnamed_9),
    unnamed_2: union_unnamed_10 = @import("std").mem.zeroes(union_unnamed_10),
    unnamed_3: union_unnamed_11 = @import("std").mem.zeroes(union_unnamed_11),
    unnamed_4: union_unnamed_12 = @import("std").mem.zeroes(union_unnamed_12),
    unnamed_5: union_unnamed_13 = @import("std").mem.zeroes(union_unnamed_13),
    unnamed_6: union_unnamed_14 = @import("std").mem.zeroes(union_unnamed_14),
    unnamed_7: union_unnamed_15 = @import("std").mem.zeroes(union_unnamed_15),
    unnamed_8: union_unnamed_16 = @import("std").mem.zeroes(union_unnamed_16),
    unnamed_9: union_unnamed_17 = @import("std").mem.zeroes(union_unnamed_17),
    unnamed_10: union_unnamed_18 = @import("std").mem.zeroes(union_unnamed_18),
    unnamed_11: union_unnamed_19 = @import("std").mem.zeroes(union_unnamed_19),
    unnamed_12: union_unnamed_20 = @import("std").mem.zeroes(union_unnamed_20),
    unnamed_13: union_unnamed_21 = @import("std").mem.zeroes(union_unnamed_21),
};
pub const PRIO_PROCESS: c_int = 0;
pub const PRIO_PGRP: c_int = 1;
pub const PRIO_USER: c_int = 2;
pub const enum___priority_which = c_uint;
pub extern fn prlimit(__pid: __pid_t, __resource: enum___rlimit_resource, __new_limit: [*c]const struct_rlimit, __old_limit: [*c]struct_rlimit) c_int;
pub extern fn prlimit64(__pid: __pid_t, __resource: enum___rlimit_resource, __new_limit: [*c]const struct_rlimit64, __old_limit: [*c]struct_rlimit64) c_int;
pub const __rlimit_resource_t = enum___rlimit_resource;
pub const __rusage_who_t = enum___rusage_who;
pub const __priority_which_t = enum___priority_which;
pub extern fn getrlimit(__resource: __rlimit_resource_t, __rlimits: [*c]struct_rlimit) c_int;
pub extern fn getrlimit64(__resource: __rlimit_resource_t, __rlimits: [*c]struct_rlimit64) c_int;
pub extern fn setrlimit(__resource: __rlimit_resource_t, __rlimits: [*c]const struct_rlimit) c_int;
pub extern fn setrlimit64(__resource: __rlimit_resource_t, __rlimits: [*c]const struct_rlimit64) c_int;
pub extern fn getrusage(__who: __rusage_who_t, __usage: [*c]struct_rusage) c_int;
pub extern fn getpriority(__which: __priority_which_t, __who: id_t) c_int;
pub extern fn setpriority(__which: __priority_which_t, __who: id_t, __prio: c_int) c_int;
pub fn jent_memlock_size(arg_flags: c_uint) callconv(.c) c_ulonglong {
    var flags = arg_flags;
    _ = &flags;
    _ = &flags;
    return @as(c_ulonglong, 1) << @intCast(@as(c_ulonglong, 20));
}
pub fn jent_memlock_required(arg_flags: c_uint) callconv(.c) c_int {
    var flags = arg_flags;
    _ = &flags;
    return @intFromBool(!!((flags & @as(c_uint, @bitCast(@as(c_int, ((@as(c_int, 1) << @intCast(@as(c_int, 6))) | (@as(c_int, 1) << @intCast(@as(c_int, 5)))) | (@as(c_int, 1) << @intCast(@as(c_int, 8))))))) != 0));
}
pub fn jent_raise_memlock_limit(arg_flags: c_uint) callconv(.c) c_int {
    _ = arg_flags;
    @import("test_harness").raiseMemlockLimit();
    return 0;
}
pub fn jent_secmem_size(arg_flags: c_uint) callconv(.c) c_ulonglong {
    var flags = arg_flags;
    _ = &flags;
    _ = &flags;
    return @as(c_ulonglong, 2) << @intCast(@as(c_ulonglong, 20));
}
pub fn jent_init_secure_memory(arg_flags: c_uint) callconv(.c) c_int {
    var flags = arg_flags;
    _ = &flags;
    _ = &flags;
    return 0;
}
pub var jent_ut_checks: c_uint = 0;
pub var jent_ut_failures: c_uint = 0;
pub var jent_ut_skipped: c_uint = 0;
pub fn jent_ut_strict() callconv(.c) c_int {
    var s: [*c]const u8 = getenv("JENT_UT_STRICT");
    _ = &s;
    return @intFromBool(((s != null) and (@as(c_int, s.*) != 0)) and (strcmp(s, "0") != 0));
}
pub fn jent_ut_group(arg_name: [*c]const u8) callconv(.c) void {
    var name = arg_name;
    _ = &name;
    _ = printf("%s\n", name);
    _ = fflush(null);
}
pub fn jent_ut_setup() callconv(.c) void {
    _ = jent_raise_memlock_limit(@bitCast(@as(c_int, @as(c_int, 1) << @intCast(@as(c_int, 8)))));
    _ = jent_init_secure_memory(@bitCast(@as(c_int, @as(c_int, 1) << @intCast(@as(c_int, 8)))));
}
pub fn jent_ut_memlock_available() callconv(.c) c_int {
    const std = @import("std");
    const builtin = @import("builtin");
    if (builtin.os.tag == .windows or builtin.os.tag == .freestanding) return 1;
    if (@hasDecl(std.c, "rlimit_resource") and @hasDecl(std.c, "getrlimit")) {
        if (@hasField(std.c.rlimit_resource, "MEMLOCK")) {
            var rl: std.c.rlimit = undefined;
            if (std.c.getrlimit(.MEMLOCK, &rl) != 0) return 1;
            return @intFromBool(rl.cur == std.c.RLIM.INFINITY or rl.cur >= 16384);
        }
    }
    return 1;
}
pub fn jent_ut_report(arg_suite: [*c]const u8) callconv(.c) c_int {
    var suite = arg_suite;
    _ = &suite;
    _ = printf("%s: %u checks, %u failed, %u skipped\n", suite, jent_ut_checks, jent_ut_failures, jent_ut_skipped);
    if (jent_ut_failures != 0) return 1;
    return if ((@as(c_uint, @bitCast(@as(c_int, @intFromBool(!(jent_ut_checks != 0))))) != 0) and (jent_ut_skipped != 0)) @as(c_int, 77) else @as(c_int, 0);
}
pub extern fn jent_atomic_load_int(ptr: [*c]const c_int) c_int;
pub extern fn jent_atomic_store_int(ptr: [*c]c_int, val: c_int) void;
pub extern fn jent_atomic_load_u32(ptr: [*c]const u32) u32;
pub extern fn jent_atomic_inc_u32(ptr: [*c]u32) u32;
pub extern fn jent_atomic_cmpxchg_u32(ptr: [*c]u32, old: u32, val: u32) u32;
pub extern fn jent_atomic_store_u32(ptr: [*c]u32, val: u32) void;
pub extern fn jent_atomic_load_fips_cb(ptr: [*c]const jent_fips_failure_cb) jent_fips_failure_cb;
pub extern fn jent_atomic_store_fips_cb(ptr: [*c]jent_fips_failure_cb, val: jent_fips_failure_cb) void;
pub extern fn jent_get_nstime(out: [*c]u64) void;
pub extern fn jent_pagesize() usize;
pub extern fn jent_memset_secure(s: ?*anyopaque, n: usize) void;
pub extern fn jent_zalloc(len: usize, flags: c_uint) ?*anyopaque;
pub extern fn jent_zalloc_unlocked(len: usize) ?*anyopaque;
pub extern fn jent_zfree(ptr: ?*anyopaque, len: usize) void;
pub extern fn jent_memory_is_secure(flags: c_uint) c_int;
pub extern fn jent_memory_backend_name() [*c]const u8;
pub extern fn jent_cache_size_roundup(all_caches: c_int) u64;
pub extern fn jent_ncpu() c_long;
pub extern fn jent_cpu_highest() c_long;
pub extern fn jent_fips_enabled_file(file: [*c]const u8) c_int;
pub extern fn jent_fips_enabled() c_int;
pub extern fn jent_yield() void;
pub extern fn jent_random_read_file(path: [*c]const u8, buf: [*c]u8, len: usize) c_int;
pub extern fn jent_random_dev_urandom(buf: [*c]u8, len: usize) c_int;
pub extern fn jent_os_random_bytes(buf: [*c]u8, len: usize) c_int;
pub extern fn jent_os_random_supported() c_int;
pub extern fn jent_uuid_format(b: [*c]const u8, out: [*c]u8) void;
pub extern fn jent_uuid_from_counter(b: [*c]u8) void;
pub extern fn jent_uuid_generate(out: [*c]u8) void;
pub fn jent_udiv64(arg_dividend: u64, arg_divisor: u64) callconv(.c) u64 {
    var dividend = arg_dividend;
    _ = &dividend;
    var divisor = arg_divisor;
    _ = &divisor;
    return dividend / divisor;
}
pub fn jent_umod64(arg_dividend: u64, arg_divisor: u64) callconv(.c) u64 {
    var dividend = arg_dividend;
    _ = &dividend;
    var divisor = arg_divisor;
    _ = &divisor;
    return dividend % divisor;
}
pub const jent_startup_completed: c_int = 0;
pub const jent_startup_sha3: c_int = 1;
pub const jent_startup_memory: c_int = 2;
pub const enum_jent_startup_state = c_uint;
pub extern fn jent_entropy_collector_alloc_raw(osr: c_uint, flags: c_uint) ?*struct_rand_data;
pub extern fn jent_raw_selftest(flags: c_uint) c_int;
pub extern var jent_selftest_run: c_int;
pub extern fn ensure_osr_is_at_least_minimal(current_osr: c_uint) c_uint;
pub extern fn jent_entropy_collector_alloc_internal(osr: c_uint, flags: c_uint) ?*struct_rand_data;
pub extern fn jent_health_failure_reset(ec: [*c]?*struct_rand_data, startup: c_int) c_int;
pub extern fn jent_time_entropy_init(osr: c_uint, flags: c_uint) c_int;
pub extern fn jent_memsize(flags: c_uint) u32;
pub extern fn jent_hashloop_cnt(flags: c_uint) c_uint;
pub extern var jent_common_timer_gcd: [2]u32;
pub extern fn jent_gcd64(a: u64, b: u64) u64;
pub extern fn jent_gcd_analyze_internal(delta_history: [*c]u64, nelem: usize, running_gcd_out: [*c]u64, delta_sum_out: [*c]u64) c_int;
pub extern fn jent_gcd_analyze(delta_history: [*c]u64, nelem: usize, osr: usize, notime: c_uint) c_int;
pub extern fn jent_gcd_verdict(delta_history: [*c]u64, nelem: usize, osr: usize, gcd: [*c]u64) c_int;
pub extern fn jent_gcd_store(gcd: u64, notime: c_uint) void;
pub extern fn jent_gcd_init(nelem: usize, flags: c_uint) [*c]u64;
pub extern fn jent_gcd_fini(delta_history: [*c]u64, nelem: usize) void;
pub extern fn jent_gcd_get(value: [*c]u64, notime: c_uint) c_int;
pub extern fn jent_gcd_selftest(flags: c_uint) c_int;
pub extern fn jent_health_cb_block_switch() void;
pub extern fn jent_set_fips_failure_callback_internal(cb: jent_fips_failure_cb) c_int;
pub fn jent_delta(arg_prev: u64, arg_next: u64) callconv(.c) u64 {
    var prev = arg_prev;
    _ = &prev;
    var next = arg_next;
    _ = &next;
    return next -% prev;
}
pub extern fn jent_lag_reset(ec: ?*struct_rand_data) void;
pub extern fn jent_lag_insert(ec: ?*struct_rand_data, current_delta: u64) void;
pub extern fn jent_apt_insert(ec: ?*struct_rand_data, current_delta: u64) void;
pub extern fn jent_rct_insert(ec: ?*struct_rand_data, stuck: c_uint) void;
pub extern fn jent_rct_mem_insert(ec: ?*struct_rand_data, stuck: c_uint) void;
pub extern fn jent_lag_duplicate(new_ec: ?*struct_rand_data, old_ec: ?*struct_rand_data) void;
pub extern fn jent_apt_duplicate(new_ec: ?*struct_rand_data, old_ec: ?*struct_rand_data) void;
pub extern fn jent_rct_duplicate(new_ec: ?*struct_rand_data) void;
pub extern fn jent_rct_mem_duplicate(new_ec: ?*struct_rand_data, old_ec: ?*struct_rand_data) void;
pub extern fn jent_health_duplicate(new_ec: ?*struct_rand_data, old_ec: ?*struct_rand_data) void;
pub extern fn jent_stuck(ec: ?*struct_rand_data, current_delta: u64) c_uint;
pub extern fn jent_health_insert_timestamp(ec: ?*struct_rand_data, timestamp: u64) c_uint;
pub extern fn jent_health_failure_query(ec: ?*const struct_rand_data) c_uint;
pub extern fn jent_health_failure(ec: ?*struct_rand_data) c_uint;
pub const jent_health_init_type_common: c_int = 0;
pub const jent_health_init_type_ntg1: c_int = 1;
pub const enum_jent_health_init_type = c_uint;
pub extern fn jent_health_init(ec: ?*struct_rand_data, inittype: enum_jent_health_init_type) c_int;
pub extern fn jent_measure_jitter_ntg1_memaccess(ec: ?*struct_rand_data, loop_cnt: u64, ret_current_delta: [*c]u64, health: c_int) c_uint;
pub extern fn jent_measure_jitter_ntg1_sha3(ec: ?*struct_rand_data, loop_cnt: u64, ret_current_delta: [*c]u64, health: c_int) c_uint;
pub extern fn jent_measure_jitter(ec: ?*struct_rand_data, loop_cnt: u64, ret_current_delta: [*c]u64, health: c_int) c_uint;
pub extern fn jent_memaccess_pseudorandom(ec: ?*struct_rand_data, loop_cnt: u64, current_delta: [*c]u64) void;
pub extern fn jent_memaccess_deterministic(ec: ?*struct_rand_data, loop_cnt: u64, current_delta: [*c]u64) void;
pub extern fn jent_random_data_one(ec: ?*struct_rand_data, measure_jitter: ?*const fn (ec: ?*struct_rand_data, loop_cnt: u64, ret_current_delta: [*c]u64, health: c_int) callconv(.c) c_uint) void;
pub extern fn jent_random_data(ec: ?*struct_rand_data) void;
pub extern fn jent_read_random_block(ec: ?*struct_rand_data, dst: [*c]u8, dst_len: usize) void;
pub fn jent_notime_block_switch() callconv(.c) void {}
pub fn jent_notime_set_cpu(arg_cpu: c_ulong) callconv(.c) c_int {
    var cpu = arg_cpu;
    _ = &cpu;
    _ = &cpu;
    return -EOPNOTSUPP;
}
pub fn jent_notime_settick(arg_ec: ?*struct_rand_data) callconv(.c) c_int {
    var ec = arg_ec;
    _ = &ec;
    _ = &ec;
    return 0;
}
pub fn jent_notime_unsettick(arg_ec: ?*struct_rand_data) callconv(.c) void {
    var ec = arg_ec;
    _ = &ec;
    _ = &ec;
}
pub fn jent_get_nstime_internal(arg_ec: ?*struct_rand_data, arg_out: [*c]u64) callconv(.c) void {
    var ec = arg_ec;
    _ = &ec;
    var out = arg_out;
    _ = &out;
    _ = &ec;
    jent_get_nstime(out);
}
pub fn jent_notime_enable(arg_ec: ?*struct_rand_data, arg_flags: c_uint) callconv(.c) c_int {
    var ec = arg_ec;
    _ = &ec;
    var flags = arg_flags;
    _ = &flags;
    _ = &ec;
    if ((flags & @as(c_uint, @bitCast(@as(c_int, @as(c_int, 1) << @intCast(@as(c_int, 3)))))) != 0) return EHEALTH;
    return 0;
}
pub fn jent_notime_disable(arg_ec: ?*struct_rand_data) callconv(.c) void {
    var ec = arg_ec;
    _ = &ec;
    _ = &ec;
}
pub fn jent_notime_switch(arg_new_thread: [*c]struct_jent_notime_thread) callconv(.c) c_int {
    var new_thread = arg_new_thread;
    _ = &new_thread;
    _ = &new_thread;
    return -EOPNOTSUPP;
}
pub fn jent_notime_force() callconv(.c) void {}
pub fn jent_notime_forced() callconv(.c) c_int {
    return 0;
}
// src/jitterentropy-sha3.h:39:12: warning: member access of demoted record

// src/jitterentropy-sha3.h:35:28: warning: unable to translate function, demoted to extern
pub extern fn jent_sha3_rate(arg_hash_state: ?*anyopaque) callconv(.c) c_uint;
pub extern fn jent_sha3_256_init(ctx: ?*struct_jent_sha_ctx) void;
pub extern fn jent_sha3_update(ctx: ?*struct_jent_sha_ctx, in: [*c]const u8, inlen: usize) void;
pub extern fn jent_sha3_final(ctx: ?*struct_jent_sha_ctx, digest: [*c]u8) void;
pub extern fn jent_sha3_tester() c_int;
pub extern fn jent_shake256_init(ctx: ?*struct_jent_sha_ctx) void;
// src/jitterentropy-sha3.h:57:5: warning: member access of demoted record

// src/jitterentropy-sha3.h:54:20: warning: unable to translate function, demoted to extern
pub extern fn jent_shake256_set_digestsize(arg_ctx: ?*struct_jent_sha_ctx, arg_digestsize: c_uint) callconv(.c) void;
pub extern fn jent_drbg_generate_block(ctx: ?*struct_jent_sha_ctx, dst: [*c]u8, dst_len: usize) void;
pub const struct_sched_attr = extern struct {
    size: __u32 = 0,
    sched_policy: __u32 = 0,
    sched_flags: __u64 = 0,
    sched_nice: __s32 = 0,
    sched_priority: __u32 = 0,
    sched_runtime: __u64 = 0,
    sched_deadline: __u64 = 0,
    sched_period: __u64 = 0,
    sched_util_min: __u32 = 0,
    sched_util_max: __u32 = 0,
};
pub const struct_sched_param = extern struct {
    sched_priority: c_int = 0,
};
pub extern fn clone(__fn: ?*const fn (__arg: ?*anyopaque) callconv(.c) c_int, __child_stack: ?*anyopaque, __flags: c_int, __arg: ?*anyopaque, ...) c_int;
pub extern fn unshare(__flags: c_int) c_int;
pub extern fn sched_getcpu() c_int;
pub extern fn getcpu([*c]c_uint, [*c]c_uint) c_int;
pub extern fn setns(__fd: c_int, __nstype: c_int) c_int;
pub extern fn sched_setattr(tid: pid_t, attr: [*c]struct_sched_attr, flags: c_uint) c_int;
pub extern fn sched_getattr(tid: pid_t, attr: [*c]struct_sched_attr, size: c_uint, flags: c_uint) c_int;
pub const __cpu_mask = c_ulong;
pub const cpu_set_t = extern struct {
    __bits: [16]__cpu_mask = @import("std").mem.zeroes([16]__cpu_mask),
    pub const __sched_cpufree = __root.__sched_cpufree;
    pub const cpufree = __root.__sched_cpufree;
};
pub extern fn __sched_cpucount(__setsize: usize, __setp: [*c]const cpu_set_t) c_int;
pub extern fn __sched_cpualloc(__count: usize) [*c]cpu_set_t;
pub extern fn __sched_cpufree(__set: [*c]cpu_set_t) void;
pub extern fn sched_setparam(__pid: __pid_t, __param: [*c]const struct_sched_param) c_int;
pub extern fn sched_getparam(__pid: __pid_t, __param: [*c]struct_sched_param) c_int;
pub extern fn sched_setscheduler(__pid: __pid_t, __policy: c_int, __param: [*c]const struct_sched_param) c_int;
pub extern fn sched_getscheduler(__pid: __pid_t) c_int;
pub extern fn sched_yield() c_int;
pub extern fn sched_get_priority_max(__algorithm: c_int) c_int;
pub extern fn sched_get_priority_min(__algorithm: c_int) c_int;
pub extern fn sched_rr_get_interval(__pid: __pid_t, __t: [*c]struct_timespec) c_int;
pub extern fn sched_setaffinity(__pid: __pid_t, __cpusetsize: usize, __cpuset: [*c]const cpu_set_t) c_int;
pub extern fn sched_getaffinity(__pid: __pid_t, __cpusetsize: usize, __cpuset: [*c]cpu_set_t) c_int;
pub const __jmp_buf = [22]c_ulonglong;
pub const struct___jmp_buf_tag = extern struct {
    __jmpbuf: __jmp_buf = @import("std").mem.zeroes(__jmp_buf),
    __mask_was_saved: c_int = 0,
    __saved_mask: __sigset_t = @import("std").mem.zeroes(__sigset_t),
    pub const __sigsetjmp = __root.__sigsetjmp;
    pub const sigsetjmp = __root.__sigsetjmp;
};
pub const PTHREAD_CREATE_JOINABLE: c_int = 0;
pub const PTHREAD_CREATE_DETACHED: c_int = 1;
const enum_unnamed_22 = c_uint;
pub const PTHREAD_MUTEX_TIMED_NP: c_int = 0;
pub const PTHREAD_MUTEX_RECURSIVE_NP: c_int = 1;
pub const PTHREAD_MUTEX_ERRORCHECK_NP: c_int = 2;
pub const PTHREAD_MUTEX_ADAPTIVE_NP: c_int = 3;
pub const PTHREAD_MUTEX_NORMAL: c_int = 0;
pub const PTHREAD_MUTEX_RECURSIVE: c_int = 1;
pub const PTHREAD_MUTEX_ERRORCHECK: c_int = 2;
pub const PTHREAD_MUTEX_DEFAULT: c_int = 0;
pub const PTHREAD_MUTEX_FAST_NP: c_int = 0;
const enum_unnamed_23 = c_uint;
pub const PTHREAD_MUTEX_STALLED: c_int = 0;
pub const PTHREAD_MUTEX_STALLED_NP: c_int = 0;
pub const PTHREAD_MUTEX_ROBUST: c_int = 1;
pub const PTHREAD_MUTEX_ROBUST_NP: c_int = 1;
const enum_unnamed_24 = c_uint;
pub const PTHREAD_PRIO_NONE: c_int = 0;
pub const PTHREAD_PRIO_INHERIT: c_int = 1;
pub const PTHREAD_PRIO_PROTECT: c_int = 2;
const enum_unnamed_25 = c_uint;
pub const PTHREAD_RWLOCK_PREFER_READER_NP: c_int = 0;
pub const PTHREAD_RWLOCK_PREFER_WRITER_NP: c_int = 1;
pub const PTHREAD_RWLOCK_PREFER_WRITER_NONRECURSIVE_NP: c_int = 2;
pub const PTHREAD_RWLOCK_DEFAULT_NP: c_int = 0;
const enum_unnamed_26 = c_uint;
pub const PTHREAD_INHERIT_SCHED: c_int = 0;
pub const PTHREAD_EXPLICIT_SCHED: c_int = 1;
const enum_unnamed_27 = c_uint;
pub const PTHREAD_SCOPE_SYSTEM: c_int = 0;
pub const PTHREAD_SCOPE_PROCESS: c_int = 1;
const enum_unnamed_28 = c_uint;
pub const PTHREAD_PROCESS_PRIVATE: c_int = 0;
pub const PTHREAD_PROCESS_SHARED: c_int = 1;
const enum_unnamed_29 = c_uint;
pub const struct__pthread_cleanup_buffer = extern struct {
    __routine: ?*const fn (?*anyopaque) callconv(.c) void = null,
    __arg: ?*anyopaque = null,
    __canceltype: c_int = 0,
    __prev: [*c]struct__pthread_cleanup_buffer = null,
};
pub const PTHREAD_CANCEL_ENABLE: c_int = 0;
pub const PTHREAD_CANCEL_DISABLE: c_int = 1;
const enum_unnamed_30 = c_uint;
pub const PTHREAD_CANCEL_DEFERRED: c_int = 0;
pub const PTHREAD_CANCEL_ASYNCHRONOUS: c_int = 1;
const enum_unnamed_31 = c_uint;
pub extern fn pthread_create(noalias __newthread: [*c]pthread_t, noalias __attr: [*c]const pthread_attr_t, __start_routine: ?*const fn (?*anyopaque) callconv(.c) ?*anyopaque, noalias __arg: ?*anyopaque) c_int;
pub extern fn pthread_exit(__retval: ?*anyopaque) noreturn;
pub extern fn pthread_join(__th: pthread_t, __thread_return: [*c]?*anyopaque) c_int;
pub extern fn pthread_tryjoin_np(__th: pthread_t, __thread_return: [*c]?*anyopaque) c_int;
pub extern fn pthread_timedjoin_np(__th: pthread_t, __thread_return: [*c]?*anyopaque, __abstime: [*c]const struct_timespec) c_int;
pub extern fn pthread_clockjoin_np(__th: pthread_t, __thread_return: [*c]?*anyopaque, __clockid: clockid_t, __abstime: [*c]const struct_timespec) c_int;
pub extern fn pthread_detach(__th: pthread_t) c_int;
pub extern fn pthread_self() pthread_t;
pub extern fn pthread_equal(__thread1: pthread_t, __thread2: pthread_t) c_int;
pub extern fn pthread_attr_init(__attr: [*c]pthread_attr_t) c_int;
pub extern fn pthread_attr_destroy(__attr: [*c]pthread_attr_t) c_int;
pub extern fn pthread_attr_getdetachstate(__attr: [*c]const pthread_attr_t, __detachstate: [*c]c_int) c_int;
pub extern fn pthread_attr_setdetachstate(__attr: [*c]pthread_attr_t, __detachstate: c_int) c_int;
pub extern fn pthread_attr_getguardsize(__attr: [*c]const pthread_attr_t, __guardsize: [*c]usize) c_int;
pub extern fn pthread_attr_setguardsize(__attr: [*c]pthread_attr_t, __guardsize: usize) c_int;
pub extern fn pthread_attr_getschedparam(noalias __attr: [*c]const pthread_attr_t, noalias __param: [*c]struct_sched_param) c_int;
pub extern fn pthread_attr_setschedparam(noalias __attr: [*c]pthread_attr_t, noalias __param: [*c]const struct_sched_param) c_int;
pub extern fn pthread_attr_getschedpolicy(noalias __attr: [*c]const pthread_attr_t, noalias __policy: [*c]c_int) c_int;
pub extern fn pthread_attr_setschedpolicy(__attr: [*c]pthread_attr_t, __policy: c_int) c_int;
pub extern fn pthread_attr_getinheritsched(noalias __attr: [*c]const pthread_attr_t, noalias __inherit: [*c]c_int) c_int;
pub extern fn pthread_attr_setinheritsched(__attr: [*c]pthread_attr_t, __inherit: c_int) c_int;
pub extern fn pthread_attr_getscope(noalias __attr: [*c]const pthread_attr_t, noalias __scope: [*c]c_int) c_int;
pub extern fn pthread_attr_setscope(__attr: [*c]pthread_attr_t, __scope: c_int) c_int;
pub extern fn pthread_attr_getstackaddr(noalias __attr: [*c]const pthread_attr_t, noalias __stackaddr: [*c]?*anyopaque) c_int;
pub extern fn pthread_attr_setstackaddr(__attr: [*c]pthread_attr_t, __stackaddr: ?*anyopaque) c_int;
pub extern fn pthread_attr_getstacksize(noalias __attr: [*c]const pthread_attr_t, noalias __stacksize: [*c]usize) c_int;
pub extern fn pthread_attr_setstacksize(__attr: [*c]pthread_attr_t, __stacksize: usize) c_int;
pub extern fn pthread_attr_getstack(noalias __attr: [*c]const pthread_attr_t, noalias __stackaddr: [*c]?*anyopaque, noalias __stacksize: [*c]usize) c_int;
pub extern fn pthread_attr_setstack(__attr: [*c]pthread_attr_t, __stackaddr: ?*anyopaque, __stacksize: usize) c_int;
pub extern fn pthread_attr_setaffinity_np(__attr: [*c]pthread_attr_t, __cpusetsize: usize, __cpuset: [*c]const cpu_set_t) c_int;
pub extern fn pthread_attr_getaffinity_np(__attr: [*c]const pthread_attr_t, __cpusetsize: usize, __cpuset: [*c]cpu_set_t) c_int;
pub extern fn pthread_getattr_default_np(__attr: [*c]pthread_attr_t) c_int;
pub extern fn pthread_attr_setsigmask_np(__attr: [*c]pthread_attr_t, sigmask: [*c]const __sigset_t) c_int;
pub extern fn pthread_attr_getsigmask_np(__attr: [*c]const pthread_attr_t, sigmask: [*c]__sigset_t) c_int;
pub extern fn pthread_setattr_default_np(__attr: [*c]const pthread_attr_t) c_int;
pub extern fn pthread_getattr_np(__th: pthread_t, __attr: [*c]pthread_attr_t) c_int;
pub extern fn pthread_setschedparam(__target_thread: pthread_t, __policy: c_int, __param: [*c]const struct_sched_param) c_int;
pub extern fn pthread_getschedparam(__target_thread: pthread_t, noalias __policy: [*c]c_int, noalias __param: [*c]struct_sched_param) c_int;
pub extern fn pthread_setschedprio(__target_thread: pthread_t, __prio: c_int) c_int;
pub extern fn pthread_getname_np(__target_thread: pthread_t, __buf: [*c]u8, __buflen: usize) c_int;
pub extern fn pthread_setname_np(__target_thread: pthread_t, __name: [*c]const u8) c_int;
pub extern fn pthread_getconcurrency() c_int;
pub extern fn pthread_setconcurrency(__level: c_int) c_int;
pub extern fn pthread_yield() c_int;
pub extern fn pthread_setaffinity_np(__th: pthread_t, __cpusetsize: usize, __cpuset: [*c]const cpu_set_t) c_int;
pub extern fn pthread_getaffinity_np(__th: pthread_t, __cpusetsize: usize, __cpuset: [*c]cpu_set_t) c_int;
pub extern fn pthread_once(__once_control: [*c]pthread_once_t, __init_routine: ?*const fn () callconv(.c) void) c_int;
pub extern fn pthread_setcancelstate(__state: c_int, __oldstate: [*c]c_int) c_int;
pub extern fn pthread_setcanceltype(__type: c_int, __oldtype: [*c]c_int) c_int;
pub extern fn pthread_cancel(__th: pthread_t) c_int;
pub extern fn pthread_testcancel() void;
pub const struct___cancel_jmp_buf_tag = extern struct {
    __cancel_jmp_buf: __jmp_buf = @import("std").mem.zeroes(__jmp_buf),
    __mask_was_saved: c_int = 0,
};
pub const __pthread_unwind_buf_t = extern struct {
    __cancel_jmp_buf: [1]struct___cancel_jmp_buf_tag = @import("std").mem.zeroes([1]struct___cancel_jmp_buf_tag),
    __pad: [4]?*anyopaque = @import("std").mem.zeroes([4]?*anyopaque),
    pub const __pthread_register_cancel = __root.__pthread_register_cancel;
    pub const __pthread_unregister_cancel = __root.__pthread_unregister_cancel;
    pub const __pthread_register_cancel_defer = __root.__pthread_register_cancel_defer;
    pub const __pthread_unregister_cancel_restore = __root.__pthread_unregister_cancel_restore;
    pub const __pthread_unwind_next = __root.__pthread_unwind_next;
    pub const cancel = __root.__pthread_register_cancel;
    pub const @"defer" = __root.__pthread_register_cancel_defer;
    pub const restore = __root.__pthread_unregister_cancel_restore;
    pub const next = __root.__pthread_unwind_next;
};
pub const struct___pthread_cleanup_frame = extern struct {
    __cancel_routine: ?*const fn (?*anyopaque) callconv(.c) void = null,
    __cancel_arg: ?*anyopaque = null,
    __do_it: c_int = 0,
    __cancel_type: c_int = 0,
};
pub extern fn __pthread_register_cancel(__buf: [*c]__pthread_unwind_buf_t) void;
pub extern fn __pthread_unregister_cancel(__buf: [*c]__pthread_unwind_buf_t) void;
pub extern fn __pthread_register_cancel_defer(__buf: [*c]__pthread_unwind_buf_t) void;
pub extern fn __pthread_unregister_cancel_restore(__buf: [*c]__pthread_unwind_buf_t) void;
// /usr/include/pthread.h:750:13: warning: TODO weak linkage ignored
pub extern fn __pthread_unwind_next(__buf: [*c]__pthread_unwind_buf_t) noreturn;
pub extern fn __sigsetjmp(__env: [*c]struct___jmp_buf_tag, __savemask: c_int) c_int;
pub extern fn pthread_mutex_init(__mutex: [*c]pthread_mutex_t, __mutexattr: [*c]const pthread_mutexattr_t) c_int;
pub extern fn pthread_mutex_destroy(__mutex: [*c]pthread_mutex_t) c_int;
pub extern fn pthread_mutex_trylock(__mutex: [*c]pthread_mutex_t) c_int;
pub extern fn pthread_mutex_lock(__mutex: [*c]pthread_mutex_t) c_int;
pub extern fn pthread_mutex_timedlock(noalias __mutex: [*c]pthread_mutex_t, noalias __abstime: [*c]const struct_timespec) c_int;
pub extern fn pthread_mutex_clocklock(noalias __mutex: [*c]pthread_mutex_t, __clockid: clockid_t, noalias __abstime: [*c]const struct_timespec) c_int;
pub extern fn pthread_mutex_unlock(__mutex: [*c]pthread_mutex_t) c_int;
pub extern fn pthread_mutex_getprioceiling(noalias __mutex: [*c]const pthread_mutex_t, noalias __prioceiling: [*c]c_int) c_int;
pub extern fn pthread_mutex_setprioceiling(noalias __mutex: [*c]pthread_mutex_t, __prioceiling: c_int, noalias __old_ceiling: [*c]c_int) c_int;
pub extern fn pthread_mutex_consistent(__mutex: [*c]pthread_mutex_t) c_int;
pub extern fn pthread_mutex_consistent_np([*c]pthread_mutex_t) c_int;
pub extern fn pthread_mutexattr_init(__attr: [*c]pthread_mutexattr_t) c_int;
pub extern fn pthread_mutexattr_destroy(__attr: [*c]pthread_mutexattr_t) c_int;
pub extern fn pthread_mutexattr_getpshared(noalias __attr: [*c]const pthread_mutexattr_t, noalias __pshared: [*c]c_int) c_int;
pub extern fn pthread_mutexattr_setpshared(__attr: [*c]pthread_mutexattr_t, __pshared: c_int) c_int;
pub extern fn pthread_mutexattr_gettype(noalias __attr: [*c]const pthread_mutexattr_t, noalias __kind: [*c]c_int) c_int;
pub extern fn pthread_mutexattr_settype(__attr: [*c]pthread_mutexattr_t, __kind: c_int) c_int;
pub extern fn pthread_mutexattr_getprotocol(noalias __attr: [*c]const pthread_mutexattr_t, noalias __protocol: [*c]c_int) c_int;
pub extern fn pthread_mutexattr_setprotocol(__attr: [*c]pthread_mutexattr_t, __protocol: c_int) c_int;
pub extern fn pthread_mutexattr_getprioceiling(noalias __attr: [*c]const pthread_mutexattr_t, noalias __prioceiling: [*c]c_int) c_int;
pub extern fn pthread_mutexattr_setprioceiling(__attr: [*c]pthread_mutexattr_t, __prioceiling: c_int) c_int;
pub extern fn pthread_mutexattr_getrobust(__attr: [*c]const pthread_mutexattr_t, __robustness: [*c]c_int) c_int;
pub extern fn pthread_mutexattr_getrobust_np([*c]pthread_mutexattr_t, [*c]c_int) c_int;
pub extern fn pthread_mutexattr_setrobust(__attr: [*c]pthread_mutexattr_t, __robustness: c_int) c_int;
pub extern fn pthread_mutexattr_setrobust_np([*c]pthread_mutexattr_t, c_int) c_int;
pub extern fn pthread_rwlock_init(noalias __rwlock: [*c]pthread_rwlock_t, noalias __attr: [*c]const pthread_rwlockattr_t) c_int;
pub extern fn pthread_rwlock_destroy(__rwlock: [*c]pthread_rwlock_t) c_int;
pub extern fn pthread_rwlock_rdlock(__rwlock: [*c]pthread_rwlock_t) c_int;
pub extern fn pthread_rwlock_tryrdlock(__rwlock: [*c]pthread_rwlock_t) c_int;
pub extern fn pthread_rwlock_timedrdlock(noalias __rwlock: [*c]pthread_rwlock_t, noalias __abstime: [*c]const struct_timespec) c_int;
pub extern fn pthread_rwlock_clockrdlock(noalias __rwlock: [*c]pthread_rwlock_t, __clockid: clockid_t, noalias __abstime: [*c]const struct_timespec) c_int;
pub extern fn pthread_rwlock_wrlock(__rwlock: [*c]pthread_rwlock_t) c_int;
pub extern fn pthread_rwlock_trywrlock(__rwlock: [*c]pthread_rwlock_t) c_int;
pub extern fn pthread_rwlock_timedwrlock(noalias __rwlock: [*c]pthread_rwlock_t, noalias __abstime: [*c]const struct_timespec) c_int;
pub extern fn pthread_rwlock_clockwrlock(noalias __rwlock: [*c]pthread_rwlock_t, __clockid: clockid_t, noalias __abstime: [*c]const struct_timespec) c_int;
pub extern fn pthread_rwlock_unlock(__rwlock: [*c]pthread_rwlock_t) c_int;
pub extern fn pthread_rwlockattr_init(__attr: [*c]pthread_rwlockattr_t) c_int;
pub extern fn pthread_rwlockattr_destroy(__attr: [*c]pthread_rwlockattr_t) c_int;
pub extern fn pthread_rwlockattr_getpshared(noalias __attr: [*c]const pthread_rwlockattr_t, noalias __pshared: [*c]c_int) c_int;
pub extern fn pthread_rwlockattr_setpshared(__attr: [*c]pthread_rwlockattr_t, __pshared: c_int) c_int;
pub extern fn pthread_rwlockattr_getkind_np(noalias __attr: [*c]const pthread_rwlockattr_t, noalias __pref: [*c]c_int) c_int;
pub extern fn pthread_rwlockattr_setkind_np(__attr: [*c]pthread_rwlockattr_t, __pref: c_int) c_int;
pub extern fn pthread_cond_init(noalias __cond: [*c]pthread_cond_t, noalias __cond_attr: [*c]const pthread_condattr_t) c_int;
pub extern fn pthread_cond_destroy(__cond: [*c]pthread_cond_t) c_int;
pub extern fn pthread_cond_signal(__cond: [*c]pthread_cond_t) c_int;
pub extern fn pthread_cond_broadcast(__cond: [*c]pthread_cond_t) c_int;
pub extern fn pthread_cond_wait(noalias __cond: [*c]pthread_cond_t, noalias __mutex: [*c]pthread_mutex_t) c_int;
pub extern fn pthread_cond_timedwait(noalias __cond: [*c]pthread_cond_t, noalias __mutex: [*c]pthread_mutex_t, noalias __abstime: [*c]const struct_timespec) c_int;
pub extern fn pthread_cond_clockwait(noalias __cond: [*c]pthread_cond_t, noalias __mutex: [*c]pthread_mutex_t, __clock_id: __clockid_t, noalias __abstime: [*c]const struct_timespec) c_int;
pub extern fn pthread_condattr_init(__attr: [*c]pthread_condattr_t) c_int;
pub extern fn pthread_condattr_destroy(__attr: [*c]pthread_condattr_t) c_int;
pub extern fn pthread_condattr_getpshared(noalias __attr: [*c]const pthread_condattr_t, noalias __pshared: [*c]c_int) c_int;
pub extern fn pthread_condattr_setpshared(__attr: [*c]pthread_condattr_t, __pshared: c_int) c_int;
pub extern fn pthread_condattr_getclock(noalias __attr: [*c]const pthread_condattr_t, noalias __clock_id: [*c]__clockid_t) c_int;
pub extern fn pthread_condattr_setclock(__attr: [*c]pthread_condattr_t, __clock_id: __clockid_t) c_int;
pub extern fn pthread_spin_init(__lock: [*c]volatile pthread_spinlock_t, __pshared: c_int) c_int;
pub extern fn pthread_spin_destroy(__lock: [*c]volatile pthread_spinlock_t) c_int;
pub extern fn pthread_spin_lock(__lock: [*c]volatile pthread_spinlock_t) c_int;
pub extern fn pthread_spin_trylock(__lock: [*c]volatile pthread_spinlock_t) c_int;
pub extern fn pthread_spin_unlock(__lock: [*c]volatile pthread_spinlock_t) c_int;
pub extern fn pthread_barrier_init(noalias __barrier: [*c]pthread_barrier_t, noalias __attr: [*c]const pthread_barrierattr_t, __count: c_uint) c_int;
pub extern fn pthread_barrier_destroy(__barrier: [*c]pthread_barrier_t) c_int;
pub extern fn pthread_barrier_wait(__barrier: [*c]pthread_barrier_t) c_int;
pub extern fn pthread_barrierattr_init(__attr: [*c]pthread_barrierattr_t) c_int;
pub extern fn pthread_barrierattr_destroy(__attr: [*c]pthread_barrierattr_t) c_int;
pub extern fn pthread_barrierattr_getpshared(noalias __attr: [*c]const pthread_barrierattr_t, noalias __pshared: [*c]c_int) c_int;
pub extern fn pthread_barrierattr_setpshared(__attr: [*c]pthread_barrierattr_t, __pshared: c_int) c_int;
pub extern fn pthread_key_create(__key: [*c]pthread_key_t, __destr_function: ?*const fn (?*anyopaque) callconv(.c) void) c_int;
pub extern fn pthread_key_delete(__key: pthread_key_t) c_int;
pub extern fn pthread_getspecific(__key: pthread_key_t) ?*anyopaque;
pub extern fn pthread_setspecific(__key: pthread_key_t, __pointer: ?*const anyopaque) c_int;
pub extern fn pthread_getcpuclockid(__thread_id: pthread_t, __clock_id: [*c]__clockid_t) c_int;
pub extern fn pthread_gettid_np(__thread_id: pthread_t) pid_t;
pub extern fn pthread_atfork(__prepare: ?*const fn () callconv(.c) void, __parent: ?*const fn () callconv(.c) void, __child: ?*const fn () callconv(.c) void) c_int;
pub const struct_ut_worker = extern struct {
    idx: c_uint = 0,
    flags: c_uint = 0,
    osr: c_uint = 0,
    work: ?*const fn (w: [*c]struct_ut_worker) callconv(.c) void = null,
    init_ret: c_int = 0,
    init_differed: c_int = 0,
    selftest_ret: c_int = 0,
    allocs: c_int = 0,
    reads: c_int = 0,
    read_err: c_int = 0,
    status_err: c_int = 0,
    misc_err: c_int = 0,
    registrations: c_int = 0,
    reg_blocked: c_int = 0,
    reg_reopened: c_int = 0,
    ec: ?*struct_rand_data = null,
    notime_used: c_int = 0,
    notime_crossed: c_int = 0,
    ticked: c_int = 0,
    osr_seen: c_uint = 0,
    divisor: u64 = 0,
    uuid: [37]u8 = @import("std").mem.zeroes([37]u8),
    block: [32]u8 = @import("std").mem.zeroes([32]u8),
    pub const ut_gate_wait = __root.ut_gate_wait;
    pub const ut_check_stateless = __root.ut_check_stateless;
    pub const ut_work_lifecycle = __root.ut_work_lifecycle;
    pub const ut_work_registrations = __root.ut_work_registrations;
    pub const ut_run = __root.ut_run;
    pub const ut_init_workers = __root.ut_init_workers;
    pub const ut_work_first_alloc = __root.ut_work_first_alloc;
    pub const wait = __root.ut_gate_wait;
    pub const stateless = __root.ut_check_stateless;
    pub const lifecycle = __root.ut_work_lifecycle;
    pub const run = __root.ut_run;
    pub const workers = __root.ut_init_workers;
    pub const alloc = __root.ut_work_first_alloc;
};
pub var ut_gate: c_int = 0;
pub var ut_ready: [8]c_int = @import("std").mem.zeroes([8]c_int);
pub fn ut_gate_reset() callconv(.c) void {
    var i: c_uint = undefined;
    _ = &i;
    jent_atomic_store_int(&ut_gate, 0);
    {
        i = 0;
        while (i < @as(c_uint, UT_MAX_THREADS)) : (i +%= 1) {
            jent_atomic_store_int(&ut_ready[i], 0);
        }
    }
}
pub fn ut_gate_wait(arg_w: [*c]const struct_ut_worker) callconv(.c) void {
    var w = arg_w;
    _ = &w;
    jent_atomic_store_int(&ut_ready[w.*.idx], 1);
    while (!(jent_atomic_load_int(&ut_gate) != 0)) {
        jent_yield();
    }
}
pub fn ut_gate_open(arg_started: c_uint) callconv(.c) void {
    var started = arg_started;
    _ = &started;
    var i: c_uint = undefined;
    _ = &i;
    {
        i = 0;
        while (i < started) : (i +%= 1) {
            while (!(jent_atomic_load_int(&ut_ready[i]) != 0)) {
                jent_yield();
            }
        }
    }
    jent_atomic_store_int(&ut_gate, 1);
}
pub fn ut_check_stateless(arg_w: [*c]struct_ut_worker) callconv(.c) void {
    var w = arg_w;
    _ = &w;
    var ret: c_int = undefined;
    _ = &ret;
    if (jent_version() != @as(c_uint, @bitCast(@as(c_int, ((JENT_MAJVERSION * @as(c_int, 1000000)) + (JENT_MINVERSION * @as(c_int, 10000))) + (JENT_PATCHLEVEL * @as(c_int, 100)))))) {
        w.*.misc_err = 1;
    }
    ret = jent_secure_memory_supported();
    if ((ret != @as(c_int, 0)) and (ret != @as(c_int, 1))) {
        w.*.misc_err = 1;
    }
}
pub fn ut_work_lifecycle(arg_w: [*c]struct_ut_worker) callconv(.c) void {
    var w = arg_w;
    _ = &w;
    var round: c_uint = undefined;
    _ = &round;
    {
        round = 0;
        while (round < @as(c_uint, UT_ROUNDS)) : (round +%= 1) {
            var ec: ?*struct_rand_data = undefined;
            _ = &ec;
            var status: [4096]u8 = undefined;
            _ = &status;
            var i: c_uint = undefined;
            _ = &i;
            var ret: c_int = undefined;
            _ = &ret;
            ret = jent_entropy_init_ex(0, 0);
            if (!(round != 0)) {
                w.*.init_ret = ret;
            } else if (ret != w.*.init_ret) {
                w.*.init_differed = 1;
            }
            ut_check_stateless(w);
            ec = jent_entropy_collector_alloc(0, w.*.flags);
            if (!(ec != null)) continue;
            w.*.allocs += 1;
            if (!(round != 0)) {
                w.*.selftest_ret = jent_selftest(ec);
            } else if (jent_selftest(ec) != w.*.selftest_ret) {
                w.*.misc_err = 1;
            }
            {
                i = 0;
                while (i < @as(c_uint, 2)) : (i +%= 1) {
                    var buf: [32]u8 = undefined;
                    _ = &buf;
                    var rc: isize = undefined;
                    _ = &rc;
                    if ((i & @as(c_uint, 1)) != 0) {
                        rc = jent_read_entropy_safe(&ec, @ptrCast(@alignCast(@as([*c]u8, @ptrCast(@alignCast(&buf))))), @sizeOf(@TypeOf(buf)));
                    } else {
                        rc = jent_read_entropy(ec, @ptrCast(@alignCast(@as([*c]u8, @ptrCast(@alignCast(&buf))))), @sizeOf(@TypeOf(buf)));
                    }
                    if (rc == @as(isize, @intCast(@sizeOf(@TypeOf(buf))))) {
                        w.*.reads += 1;
                        if (w.*.reads == @as(c_int, 1)) {
                            _ = memcpy(@ptrCast(@alignCast(@as([*c]u8, @ptrCast(@alignCast(&w.*.block))))), @ptrCast(@alignCast(@as([*c]u8, @ptrCast(@alignCast(&buf))))), @sizeOf(@TypeOf(buf)));
                        }
                    } else if (!(w.*.read_err != 0)) {
                        w.*.read_err = @truncate(rc);
                    }
                    if (!(ec != null)) break;
                }
            }
            if (!(ec != null)) continue;
            if (jent_status(ec, @ptrCast(@alignCast(&status)), @sizeOf(@TypeOf(status))) != 0) {
                w.*.status_err = 1;
            }
            if (jent_entropy_collector_uuid(ec, @ptrCast(@alignCast(&w.*.uuid)), @sizeOf(@TypeOf(w.*.uuid))) != 0) {
                w.*.status_err = 1;
            }
            jent_entropy_collector_free(ec);
        }
    }
}
pub var ut_fips_cb_seen: c_int = 0;
pub fn ut_fips_failure(arg_ec: ?*struct_rand_data, arg_failure: c_uint) callconv(.c) void {
    var ec = arg_ec;
    _ = &ec;
    var failure = arg_failure;
    _ = &failure;
    _ = &ec;
    _ = &failure;
    jent_atomic_store_int(&ut_fips_cb_seen, 1);
}
pub fn ut_work_registrations(arg_w: [*c]struct_ut_worker) callconv(.c) void {
    var w = arg_w;
    _ = &w;
    var i: c_uint = undefined;
    _ = &i;
    if ((w.*.idx & @as(c_uint, 1)) != 0) {
        {
            i = 0;
            while (i < @as(c_uint, UT_ROUNDS)) : (i +%= 1) {
                var ec: ?*struct_rand_data = jent_entropy_collector_alloc(0, w.*.flags);
                _ = &ec;
                var buf: [32]u8 = undefined;
                _ = &buf;
                if (!(ec != null)) continue;
                w.*.allocs += 1;
                if (jent_read_entropy(ec, @ptrCast(@alignCast(@as([*c]u8, @ptrCast(@alignCast(&buf))))), @sizeOf(@TypeOf(buf))) == @as(isize, @intCast(@sizeOf(@TypeOf(buf))))) {
                    w.*.reads += 1;
                }
                jent_entropy_collector_free(ec);
            }
        }
        return;
    }
    {
        i = 0;
        while (i < @as(c_uint, UT_REGISTRATIONS)) : (i +%= 1) {
            var ret: c_int = jent_set_fips_failure_callback(@ptrCast(@alignCast(if ((i & @as(c_uint, 1)) != 0) @as(?*anyopaque, @ptrCast(@alignCast(@constCast(&ut_fips_failure)))) else @as(?*anyopaque, null))));
            _ = &ret;
            w.*.registrations += 1;
            if (ret == -EAGAIN) {
                w.*.reg_blocked += 1;
            } else if (ret != 0) {
                w.*.misc_err = 1;
            } else if (w.*.reg_blocked != 0) {
                w.*.reg_reopened += 1;
            }
            ut_check_stateless(w);
        }
    }
}
const UtThreadReturn = if (@import("builtin").os.tag == .windows) c_int else ?*anyopaque;
pub fn ut_thread_main(arg_arg: ?*anyopaque) callconv(.c) UtThreadReturn {
    var arg = arg_arg;
    _ = &arg;
    var w: [*c]struct_ut_worker = @ptrCast(@alignCast(arg));
    _ = &w;
    ut_gate_wait(w);
    w.*.work.?(w);
    return if (@import("builtin").os.tag == .windows) 0 else null;
}
pub fn ut_threads() callconv(.c) c_uint {
    var ncpu: c_long = jent_ncpu();
    _ = &ncpu;
    if (ncpu < @as(c_long, UT_MIN_THREADS)) return UT_MIN_THREADS;
    if (ncpu > @as(c_long, UT_MAX_THREADS)) return UT_MAX_THREADS;
    return @bitCast(@as(c_int, @truncate(ncpu)));
}
pub fn ut_run(arg_workers: [*c]struct_ut_worker, arg_nthreads: c_uint) callconv(.c) c_uint {
    const jent_internal = @import("jent_internal");
    var workers = arg_workers;
    _ = &workers;
    var nthreads = arg_nthreads;
    _ = &nthreads;
    var handles: [8]jent_internal.jent_notime_ctx = undefined;
    _ = &handles;
    var started: c_uint = 0;
    _ = &started;
    var i: c_uint = undefined;
    _ = &i;
    ut_gate_reset();
    {
        i = 0;
        while (i < nthreads) : (i +%= 1) {
            if (jent_internal.jent_notime_thread_create(&handles[started], ut_thread_main, @ptrCast(@alignCast(&workers[i]))) != 0) break;
            started +%= 1;
        }
    }
    ut_gate_open(started);
    {
        i = 0;
        while (i < started) : (i +%= 1) {
            jent_internal.jent_notime_thread_join(&handles[i]);
        }
    }
    return started;
}
pub fn ut_flags(arg_idx: c_uint) callconv(.c) c_uint {
    var idx = arg_idx;
    _ = &idx;
    const static_local_flags = struct {
        const flags: [4]c_uint = [4]c_uint{
            0,
            @bitCast(@as(c_int, @as(c_int, 1) << @intCast(@as(c_int, 2)))),
            @as(c_uint, 3) << @intCast(@as(c_uint, JENT_FLAGS_TO_HASHLOOP_SHIFT)),
            @as(c_uint, 7) << @intCast(@as(c_uint, JENT_FLAGS_TO_MEMSIZE_SHIFT)),
        };
    };
    _ = &static_local_flags;
    return static_local_flags.flags[@as(c_ulong, idx) % (@sizeOf(@TypeOf(static_local_flags.flags)) / @sizeOf(@TypeOf(static_local_flags.flags[@as(c_int, 0)])))];
}
pub fn ut_init_workers(arg_workers: [*c]struct_ut_worker, arg_nthreads: c_uint, arg_work: ?*const fn ([*c]struct_ut_worker) callconv(.c) void, arg_flags: ?*const fn (c_uint) callconv(.c) c_uint) callconv(.c) void {
    var workers = arg_workers;
    _ = &workers;
    var nthreads = arg_nthreads;
    _ = &nthreads;
    var work = arg_work;
    _ = &work;
    var flags = arg_flags;
    _ = &flags;
    var i: c_uint = undefined;
    _ = &i;
    _ = memset(@ptrCast(@alignCast(workers)), 0, @sizeOf(@TypeOf(workers.*)) *% @as(c_ulong, nthreads));
    {
        i = 0;
        while (i < nthreads) : (i +%= 1) {
            workers[i].idx = i;
            workers[i].work = work;
            workers[i].flags = flags.?(i);
        }
    }
}
pub fn test_concurrent_lifecycle() callconv(.c) void {
    const static_local___func__ = struct {
        const __func__: [25:0]u8 = "test_concurrent_lifecycle".*;
    };
    _ = &static_local___func__;
    var workers: [8]struct_ut_worker = undefined;
    _ = &workers;
    var nthreads: c_uint = ut_threads();
    _ = &nthreads;
    var started: c_uint = undefined;
    _ = &started;
    var i: c_uint = undefined;
    _ = &i;
    var j: c_uint = undefined;
    _ = &j;
    var allocs: c_uint = 0;
    _ = &allocs;
    var reads: c_uint = 0;
    _ = &reads;
    var read_errs: c_uint = 0;
    _ = &read_errs;
    var status_errs: c_uint = 0;
    _ = &status_errs;
    var init_differed: c_uint = 0;
    _ = &init_differed;
    var misc_errs: c_uint = 0;
    _ = &misc_errs;
    jent_ut_group("several instances through their life cycle at once");
    ut_init_workers(@ptrCast(@alignCast(&workers)), nthreads, ut_work_lifecycle, ut_flags);
    started = ut_run(@ptrCast(@alignCast(&workers)), nthreads);
    if (!(started != 0)) {
        while (true) {
            jent_ut_skipped +%= 1;
            _ = printf("  skipped %s: %s\n", @constCast("the concurrent life cycle"), @constCast("no thread could be created"));
            if (!false) break;
        }
        return;
    }
    _ = printf("  note: %u threads, %u rounds each\n", started, UT_ROUNDS);
    {
        i = 1;
        while (i < started) : (i +%= 1) {
            while (true) {
                var _g: c_longlong = workers[i].init_ret;
                _ = &_g;
                var _w: c_longlong = workers[@as(c_int, 0)].init_ret;
                _ = &_w;
                jent_ut_checks +%= 1;
                if (_g != _w) while (true) {
                    jent_ut_failures +%= 1;
                    _ = printf("  FAILED %s:%d: %s: %s is %lld, expected %lld\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 737), @constCast("every thread is given the same startup verdict"), @constCast("workers[i].init_ret"), _g, _w);
                    if (!false) break;
                };
                if (!false) break;
            }
        }
    }
    {
        i = 0;
        while (i < started) : (i +%= 1) {
            allocs +%= @bitCast(@as(c_int, workers[i].allocs));
            reads +%= @bitCast(@as(c_int, workers[i].reads));
            read_errs +%= @bitCast(@as(c_int, if (workers[i].read_err != 0) @as(c_int, 1) else @as(c_int, 0)));
            status_errs +%= if (workers[i].status_err != 0) @as(c_uint, 1) else @as(c_uint, 0);
            init_differed +%= if (workers[i].init_differed != 0) @as(c_uint, 1) else @as(c_uint, 0);
            misc_errs +%= if (workers[i].misc_err != 0) @as(c_uint, 1) else @as(c_uint, 0);
            if (workers[i].read_err != 0) {
                _ = printf("  note: thread %u: a read returned %d\n", i, workers[i].read_err);
            }
        }
    }
    while (true) {
        var _g: c_longlong = init_differed;
        _ = &_g;
        var _w: c_longlong = @as(c_int, 0);
        _ = &_w;
        jent_ut_checks +%= 1;
        if (_g != _w) while (true) {
            jent_ut_failures +%= 1;
            _ = printf("  FAILED %s:%d: %s: %s is %lld, expected %lld\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 754), @constCast("and the same one on every call it makes"), @constCast("init_differed"), _g, _w);
            if (!false) break;
        };
        if (!false) break;
    }
    while (true) {
        var _g: c_longlong = read_errs;
        _ = &_g;
        var _w: c_longlong = @as(c_uint, 0);
        _ = &_w;
        jent_ut_checks +%= 1;
        if (_g != _w) while (true) {
            jent_ut_failures +%= 1;
            _ = printf("  FAILED %s:%d: %s: %s is %lld, expected %lld\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 756), @constCast("no thread was refused a generation"), @constCast("read_errs"), _g, _w);
            if (!false) break;
        };
        if (!false) break;
    }
    while (true) {
        var _g: c_longlong = status_errs;
        _ = &_g;
        var _w: c_longlong = @as(c_uint, 0);
        _ = &_w;
        jent_ut_checks +%= 1;
        if (_g != _w) while (true) {
            jent_ut_failures +%= 1;
            _ = printf("  FAILED %s:%d: %s: %s is %lld, expected %lld\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 757), @constCast("the status and UUID calls succeed alongside the others"), @constCast("status_errs"), _g, _w);
            if (!false) break;
        };
        if (!false) break;
    }
    while (true) {
        var _g: c_longlong = misc_errs;
        _ = &_g;
        var _w: c_longlong = @as(c_uint, 0);
        _ = &_w;
        jent_ut_checks +%= 1;
        if (_g != _w) while (true) {
            jent_ut_failures +%= 1;
            _ = printf("  FAILED %s:%d: %s: %s is %lld, expected %lld\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 759), @constCast("the process-wide queries answer the same on every thread"), @constCast("misc_errs"), _g, _w);
            if (!false) break;
        };
        if (!false) break;
    }
    if (workers[@as(c_int, 0)].init_ret != 0) {
        _ = printf("  note: the startup gives %d here\n", workers[@as(c_int, 0)].init_ret);
        while (true) {
            jent_ut_skipped +%= 1;
            _ = printf("  skipped %s: %s\n", @constCast("the concurrent generation"), @constCast("the startup does not pass on this machine"));
            if (!false) break;
        }
        return;
    }
    while (true) {
        var _g: c_longlong = allocs;
        _ = &_g;
        var _w: c_longlong = started *% @as(c_uint, UT_ROUNDS);
        _ = &_w;
        jent_ut_checks +%= 1;
        if (_g != _w) while (true) {
            jent_ut_failures +%= 1;
            _ = printf("  FAILED %s:%d: %s: %s is %lld, expected %lld\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 775), @constCast("every thread built a collector in every round"), @constCast("allocs"), _g, _w);
            if (!false) break;
        };
        if (!false) break;
    }
    while (true) {
        var _g: c_longlong = reads;
        _ = &_g;
        var _w: c_longlong = allocs *% @as(c_uint, 2);
        _ = &_w;
        jent_ut_checks +%= 1;
        if (_g != _w) while (true) {
            jent_ut_failures +%= 1;
            _ = printf("  FAILED %s:%d: %s: %s is %lld, expected %lld\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 777), @constCast("and every generation delivered"), @constCast("reads"), _g, _w);
            if (!false) break;
        };
        if (!false) break;
    }
    {
        i = 1;
        while (i < started) : (i +%= 1) {
            while (true) {
                var _g: c_longlong = workers[i].selftest_ret;
                _ = &_g;
                var _w: c_longlong = workers[@as(c_int, 0)].selftest_ret;
                _ = &_w;
                jent_ut_checks +%= 1;
                if (_g != _w) while (true) {
                    jent_ut_failures +%= 1;
                    _ = printf("  FAILED %s:%d: %s: %s is %lld, expected %lld\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 784), @constCast("the self test agrees across the instances"), @constCast("workers[i].selftest_ret"), _g, _w);
                    if (!false) break;
                };
                if (!false) break;
            }
        }
    }
    {
        i = 0;
        while (i < started) : (i +%= 1) {
            {
                j = i +% @as(c_uint, 1);
                while (j < started) : (j +%= 1) {
                    while (true) {
                        jent_ut_checks +%= 1;
                        if (!(memcmp(@ptrCast(@alignCast(@as([*c]u8, @ptrCast(@alignCast(&workers[i].block))))), @ptrCast(@alignCast(@as([*c]u8, @ptrCast(@alignCast(&workers[j].block))))), UT_BLOCK) != @as(c_int, 0))) while (true) {
                            jent_ut_failures +%= 1;
                            _ = printf("  FAILED %s:%d: %s (%s)\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 797), @constCast("two threads generate different blocks"), @constCast("memcmp(workers[i].block, workers[j].block, UT_BLOCK) != 0"));
                            if (!false) break;
                        };
                        if (!false) break;
                    }
                    while (true) {
                        jent_ut_checks +%= 1;
                        if (!(strcmp(@ptrCast(@alignCast(&workers[i].uuid)), @ptrCast(@alignCast(&workers[j].uuid))) != @as(c_int, 0))) while (true) {
                            jent_ut_failures +%= 1;
                            _ = printf("  FAILED %s:%d: %s (%s)\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 800), @constCast("two collectors carry different UUIDs"), @constCast("strcmp(workers[i].uuid, workers[j].uuid) != 0"));
                            if (!false) break;
                        };
                        if (!false) break;
                    }
                }
            }
        }
    }
}
pub var ut_init_duration: u64 = 0;
pub fn ut_init_state_reset() callconv(.c) void {
    var clock_1: c_uint = undefined;
    _ = &clock_1;
    jent_atomic_store_int(&jent_selftest_run, 0);
    {
        clock_1 = 0;
        while (clock_1 < @as(c_uint, JENT_GCD_CLOCKS)) : (clock_1 +%= 1) {
            jent_atomic_store_u32(&jent_common_timer_gcd[clock_1], 0);
        }
    }
}
pub fn ut_work_first_alloc(arg_w: [*c]struct_ut_worker) callconv(.c) void {
    var w = arg_w;
    _ = &w;
    var ec: ?*struct_rand_data = undefined;
    _ = &ec;
    var start: u64 = undefined;
    _ = &start;
    var now: u64 = undefined;
    _ = &now;
    jent_get_nstime(&start);
    while (true) {
        jent_get_nstime(&now);
        if (!((now -% start) < ((ut_init_duration *% @as(u64, w.*.idx)) / @as(u64, UT_MAX_THREADS)))) break;
    }
    ec = jent_entropy_collector_alloc(0, 0);
    w.*.allocs = if (ec != null) @as(c_int, 1) else @as(c_int, 0);
    jent_entropy_collector_free(ec);
}
pub fn ut_no_flags(arg_idx: c_uint) callconv(.c) c_uint {
    var idx = arg_idx;
    _ = &idx;
    _ = &idx;
    return 0;
}
pub fn test_concurrent_first_alloc() callconv(.c) void {
    const static_local___func__ = struct {
        const __func__: [27:0]u8 = "test_concurrent_first_alloc".*;
    };
    _ = &static_local___func__;
    var workers: [8]struct_ut_worker = undefined;
    _ = &workers;
    var nthreads: c_uint = ut_threads();
    _ = &nthreads;
    var round: c_uint = undefined;
    _ = &round;
    var started: c_uint = 0;
    _ = &started;
    var i: c_uint = undefined;
    _ = &i;
    var allocs: c_uint = 0;
    _ = &allocs;
    var runs: c_uint = 0;
    _ = &runs;
    var start: u64 = undefined;
    _ = &start;
    var end: u64 = undefined;
    _ = &end;
    var ret: c_int = undefined;
    _ = &ret;
    jent_ut_group("first allocations on several threads at once");
    ut_init_state_reset();
    jent_get_nstime(&start);
    ret = jent_entropy_init();
    jent_get_nstime(&end);
    if (ret != 0) {
        while (true) {
            jent_ut_skipped +%= 1;
            _ = printf("  skipped %s: %s\n", @constCast("the concurrent first allocation"), @constCast("the startup does not pass on this machine"));
            if (!false) break;
        }
        return;
    }
    ut_init_duration = end -% start;
    {
        round = 0;
        while (round < @as(c_uint, UT_FIRST_ALLOC_ROUNDS)) : (round +%= 1) {
            ut_init_state_reset();
            ut_init_workers(@ptrCast(@alignCast(&workers)), nthreads, ut_work_first_alloc, ut_no_flags);
            started = ut_run(@ptrCast(@alignCast(&workers)), nthreads);
            {
                i = 0;
                while (i < started) : (i +%= 1) {
                    allocs +%= @bitCast(@as(c_int, workers[i].allocs));
                }
            }
            runs +%= started;
        }
    }
    if (!(runs != 0)) {
        while (true) {
            jent_ut_skipped +%= 1;
            _ = printf("  skipped %s: %s\n", @constCast("the concurrent first allocation"), @constCast("no thread could be created"));
            if (!false) break;
        }
        return;
    }
    _ = printf("  note: %u allocations over %u rounds\n", runs, UT_FIRST_ALLOC_ROUNDS);
    while (true) {
        var _g: c_longlong = allocs;
        _ = &_g;
        var _w: c_longlong = runs;
        _ = &_w;
        jent_ut_checks +%= 1;
        if (_g != _w) while (true) {
            jent_ut_failures +%= 1;
            _ = printf("  FAILED %s:%d: %s: %s is %lld, expected %lld\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 893), @constCast("every first allocation builds a collector"), @constCast("allocs"), _g, _w);
            if (!false) break;
        };
        if (!false) break;
    }
}
pub fn ut_fips_flags(arg_idx: c_uint) callconv(.c) c_uint {
    var idx = arg_idx;
    _ = &idx;
    _ = &idx;
    return @bitCast(@as(c_int, @as(c_int, 1) << @intCast(@as(c_int, 5))));
}
pub fn test_concurrent_registrations() callconv(.c) void {
    const static_local___func__ = struct {
        const __func__: [29:0]u8 = "test_concurrent_registrations".*;
    };
    _ = &static_local___func__;
    var workers: [8]struct_ut_worker = undefined;
    _ = &workers;
    var nthreads: c_uint = ut_threads();
    _ = &nthreads;
    var started: c_uint = undefined;
    _ = &started;
    var i: c_uint = undefined;
    _ = &i;
    var allocs: c_uint = 0;
    _ = &allocs;
    var registrations: c_uint = 0;
    _ = &registrations;
    var blocked: c_uint = 0;
    _ = &blocked;
    var reopened: c_uint = 0;
    _ = &reopened;
    var misc_errs: c_uint = 0;
    _ = &misc_errs;
    jent_ut_group("the process-wide registrations against the collectors");
    ut_init_workers(@ptrCast(@alignCast(&workers)), nthreads, ut_work_registrations, ut_fips_flags);
    started = ut_run(@ptrCast(@alignCast(&workers)), nthreads);
    if (!(started != 0)) {
        while (true) {
            jent_ut_skipped +%= 1;
            _ = printf("  skipped %s: %s\n", @constCast("the concurrent registration"), @constCast("no thread could be created"));
            if (!false) break;
        }
        return;
    }
    {
        i = 0;
        while (i < started) : (i +%= 1) {
            allocs +%= @bitCast(@as(c_int, workers[i].allocs));
            registrations +%= @bitCast(@as(c_int, workers[i].registrations));
            blocked +%= @bitCast(@as(c_int, workers[i].reg_blocked));
            reopened +%= @bitCast(@as(c_int, workers[i].reg_reopened));
            misc_errs +%= if (workers[i].misc_err != 0) @as(c_uint, 1) else @as(c_uint, 0);
        }
    }
    _ = printf("  note: %u threads, %u registrations (%u refused), %u collectors\n", started, registrations, blocked, allocs);
    while (true) {
        var _g: c_longlong = misc_errs;
        _ = &_g;
        var _w: c_longlong = @as(c_uint, 0);
        _ = &_w;
        jent_ut_checks +%= 1;
        if (_g != _w) while (true) {
            jent_ut_failures +%= 1;
            _ = printf("  FAILED %s:%d: %s: %s is %lld, expected %lld\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 939), @constCast("the registration answers only 0 or -EAGAIN"), @constCast("misc_errs"), _g, _w);
            if (!false) break;
        };
        if (!false) break;
    }
    while (true) {
        var _g: c_longlong = reopened;
        _ = &_g;
        var _w: c_longlong = @as(c_uint, 0);
        _ = &_w;
        jent_ut_checks +%= 1;
        if (_g != _w) while (true) {
            jent_ut_failures +%= 1;
            _ = printf("  FAILED %s:%d: %s: %s is %lld, expected %lld\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 948), @constCast("no registration is accepted after one was refused"), @constCast("reopened"), _g, _w);
            if (!false) break;
        };
        if (!false) break;
    }
    if (!(allocs != 0)) {
        while (true) {
            jent_ut_skipped +%= 1;
            _ = printf("  skipped %s: %s\n", @constCast("the closing of the registration"), @constCast("no compliance-mode collector could be built on this machine"));
            if (!false) break;
        }
        return;
    }
    while (true) {
        jent_ut_checks +%= 1;
        if (!(registrations > @as(c_uint, 0))) while (true) {
            jent_ut_failures +%= 1;
            _ = printf("  FAILED %s:%d: %s (%s)\n", @as([*c]const u8, @ptrCast(@alignCast(&static_local___func__.__func__))), @as(c_int, 963), @constCast("the registering threads ran alongside them"), @constCast("registrations > 0"));
            if (!false) break;
        };
        if (!false) break;
    }
}
pub fn test_concurrent_notime() callconv(.c) void {
    jent_ut_group("the counting thread against the platform clock");
    while (true) {
        jent_ut_skipped +%= 1;
        _ = printf("  skipped %s: %s\n", @constCast("the counting thread"), @constCast("not compiled in"));
        if (!false) break;
    }
}
pub export fn main() c_int {
    jent_ut_setup();
    test_concurrent_registrations();
    test_concurrent_first_alloc();
    test_concurrent_lifecycle();
    test_concurrent_notime();
    return jent_ut_report("unit-concurrency");
}

pub const __VERSION__ = "Aro aro-zig";
pub const __Aro__ = "";
pub const __STDC__ = @as(c_int, 1);
pub const __STDC_HOSTED__ = @as(c_int, 1);
pub const __STDC_UTF_16__ = @as(c_int, 1);
pub const __STDC_UTF_32__ = @as(c_int, 1);
pub const __STDC_EMBED_NOT_FOUND__ = @as(c_int, 0);
pub const __STDC_EMBED_FOUND__ = @as(c_int, 1);
pub const __STDC_EMBED_EMPTY__ = @as(c_int, 2);
pub const __STDC_VERSION__ = @as(c_long, 201710);
pub const __GNUC__ = @as(c_int, 7);
pub const __GNUC_MINOR__ = @as(c_int, 1);
pub const __GNUC_PATCHLEVEL__ = @as(c_int, 0);
pub const __ARO_EMULATE_NO__ = @as(c_int, 0);
pub const __ARO_EMULATE_CLANG__ = @as(c_int, 1);
pub const __ARO_EMULATE_GCC__ = @as(c_int, 2);
pub const __ARO_EMULATE_MSVC__ = @as(c_int, 3);
pub const __ARO_EMULATE__ = __ARO_EMULATE_GCC__;
pub inline fn __building_module(x: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &x;
    return @as(c_int, 0);
}
pub const linux = @as(c_int, 1);
pub const __linux = @as(c_int, 1);
pub const __linux__ = @as(c_int, 1);
pub const unix = @as(c_int, 1);
pub const __unix = @as(c_int, 1);
pub const __unix__ = @as(c_int, 1);
pub const __aarch64__ = @as(c_int, 1);
pub const __ARM_64BIT_STATE = @as(c_int, 1);
pub const __ARM_ARCH_ISA_A64 = @as(c_int, 1);
pub const __ARM_FEATURE_CLZ = @as(c_int, 1);
pub const __ARM_FEATURE_FMA = @as(c_int, 1);
pub const __ARM_FEATURE_LDREX = @as(c_int, 0xf);
pub const __ARM_FEATURE_IDIV = @as(c_int, 1);
pub const __ARM_FEATURE_DIV = @as(c_int, 1);
pub const __ARM_STATE_ZA = @as(c_int, 1);
pub const __ARM_STATE_ZT0 = @as(c_int, 1);
pub const __ARM_ALIGN_MAX_STACK_PWR = @as(c_int, 4);
pub const __ARM_FEATURE_NUMERIC_MAXMIN = @as(c_int, 1);
pub const __ARM_FEATURE_DIRECTED_ROUNDING = @as(c_int, 1);
pub inline fn __ARM_ACLE_VERSION(year: anytype, quarter: anytype, patch: anytype) @TypeOf(((@as(c_int, 100) * year) + (@as(c_int, 10) * quarter)) + patch) {
    _ = &year;
    _ = &quarter;
    _ = &patch;
    return ((@as(c_int, 100) * year) + (@as(c_int, 10) * quarter)) + patch;
}
pub const __ARM_ACLE = __helpers.promoteIntLiteral(c_int, 202420, .decimal);
pub const __ARM_ARCH = @as(c_int, 9);
pub const __ARM_ARCH_PROFILE = 'A';
pub const __ARM_FEATURE_COMPLEX = @as(c_int, 1);
pub const __ARM_FEATURE_JCVT = @as(c_int, 1);
pub const __AARCH64EL__ = @as(c_int, 1);
pub const __AARCH64_CMODEL_SMALL__ = @as(c_int, 1);
pub const __ARM_FP = @as(c_int, 0xE);
pub const __ARM_NEON = @as(c_int, 1);
pub const __ARM_NEON_FP = @as(c_int, 0xE);
pub const __ARM_FEATURE_BF16 = @as(c_int, 1);
pub const __ARM_FEATURE_BF16_VECTOR_ARITHMETIC = @as(c_int, 1);
pub const __ARM_BF16_FORMAT_ALTERNATIVE = @as(c_int, 1);
pub const __ARM_FEATURE_BF16_SCALAR_ARITHMETIC = @as(c_int, 1);
pub const __ARM_FEATURE_SVE_BF16 = @as(c_int, 1);
pub const __ARM_FEATURE_SVE2_BITPERM = @as(c_int, 1);
pub const __ARM_FEATURE_SHA3 = @as(c_int, 1);
pub const __ARM_FEATURE_SHA512 = @as(c_int, 1);
pub const __ARM_FEATURE_SM3 = @as(c_int, 1);
pub const __ARM_FEATURE_SM4 = @as(c_int, 1);
pub const __ARM_FEATURE_UNALIGNED = @as(c_int, 1);
pub const __ARM_FEATURE_FP16_VECTOR_ARITHMETIC = @as(c_int, 1);
pub const __ARM_FEATURE_RCPC = @as(c_int, 1);
pub const __ARM_FEATURE_SVE = @as(c_int, 1);
pub const __ARM_FEATURE_SVE2 = @as(c_int, 1);
pub const __ARM_FEATURE_CRC32 = @as(c_int, 1);
pub const __ARM_FEATURE_AES = @as(c_int, 1);
pub const __ARM_FEATURE_SHA2 = @as(c_int, 1);
pub const __ARM_FEATURE_PAUTH = @as(c_int, 1);
pub const __ARM_FEATURE_BTI = @as(c_int, 1);
pub const __ARM_FEATURE_FP16_SCALAR_ARITHMETIC = @as(c_int, 1);
pub const __ARM_FEATURE_DOTPROD = @as(c_int, 1);
pub const __ARM_FEATURE_MATMUL_INT8 = @as(c_int, 1);
pub const __ARM_FEATURE_ATOMICS = @as(c_int, 1);
pub const __ARM_FEATURE_SVE_MATMUL_INT8 = @as(c_int, 1);
pub const __ARM_FEATURE_FP16_FML = @as(c_int, 1);
pub const __ARM_SIZEOF_MINIMAL_ENUM = @as(c_int, 4);
pub const __ARM_SIZEOF_WCHAR_T = @as(c_int, 4);
pub const _LP64 = @as(c_int, 1);
pub const __LP64__ = @as(c_int, 1);
pub const __FLOAT128__ = @as(c_int, 1);
pub const __ORDER_LITTLE_ENDIAN__ = @as(c_int, 1234);
pub const __ORDER_BIG_ENDIAN__ = @as(c_int, 4321);
pub const __ORDER_PDP_ENDIAN__ = @as(c_int, 3412);
pub const __BYTE_ORDER__ = __ORDER_LITTLE_ENDIAN__;
pub const __LITTLE_ENDIAN__ = @as(c_int, 1);
pub const __ELF__ = @as(c_int, 1);
pub const __ATOMIC_RELAXED = @as(c_int, 0);
pub const __ATOMIC_CONSUME = @as(c_int, 1);
pub const __ATOMIC_ACQUIRE = @as(c_int, 2);
pub const __ATOMIC_RELEASE = @as(c_int, 3);
pub const __ATOMIC_ACQ_REL = @as(c_int, 4);
pub const __ATOMIC_SEQ_CST = @as(c_int, 5);
pub const __ATOMIC_BOOL_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR16_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_CHAR32_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_WCHAR_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_WINT_T_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_SHORT_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_INT_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_LONG_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_LLONG_LOCK_FREE = @as(c_int, 1);
pub const __ATOMIC_POINTER_LOCK_FREE = @as(c_int, 1);
pub const __CHAR_UNSIGNED__ = @as(c_int, 1);
pub const __WCHAR_UNSIGNED__ = @as(c_int, 1);
pub const __WINT_UNSIGNED__ = @as(c_int, 1);
pub const __CHAR_BIT__ = @as(c_int, 8);
pub const __BOOL_WIDTH__ = @as(c_int, 8);
pub const __SCHAR_MAX__ = @as(c_int, 127);
pub const __SCHAR_WIDTH__ = @as(c_int, 8);
pub const __SHRT_MAX__ = @as(c_int, 32767);
pub const __SHRT_WIDTH__ = @as(c_int, 16);
pub const __INT_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_WIDTH__ = @as(c_int, 32);
pub const __LONG_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __LONG_WIDTH__ = @as(c_int, 64);
pub const __LONG_LONG_MAX__ = @as(c_longlong, 9223372036854775807);
pub const __LONG_LONG_WIDTH__ = @as(c_int, 64);
pub const __WCHAR_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __WCHAR_WIDTH__ = @as(c_int, 32);
pub const __WINT_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __WINT_WIDTH__ = @as(c_int, 32);
pub const __INTMAX_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTMAX_WIDTH__ = @as(c_int, 64);
pub const __SIZE_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __SIZE_WIDTH__ = @as(c_int, 64);
pub const __UINTMAX_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTMAX_WIDTH__ = @as(c_int, 64);
pub const __PTRDIFF_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __PTRDIFF_WIDTH__ = @as(c_int, 64);
pub const __INTPTR_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INTPTR_WIDTH__ = @as(c_int, 64);
pub const __UINTPTR_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __UINTPTR_WIDTH__ = @as(c_int, 64);
pub const __SIG_ATOMIC_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __SIG_ATOMIC_WIDTH__ = @as(c_int, 32);
pub const __BITINT_MAXWIDTH__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __SIZEOF_FLOAT__ = @as(c_int, 4);
pub const __SIZEOF_DOUBLE__ = @as(c_int, 8);
pub const __SIZEOF_LONG_DOUBLE__ = @as(c_int, 16);
pub const __SIZEOF_SHORT__ = @as(c_int, 2);
pub const __SIZEOF_INT__ = @as(c_int, 4);
pub const __SIZEOF_LONG__ = @as(c_int, 8);
pub const __SIZEOF_LONG_LONG__ = @as(c_int, 8);
pub const __SIZEOF_POINTER__ = @as(c_int, 8);
pub const __SIZEOF_PTRDIFF_T__ = @as(c_int, 8);
pub const __SIZEOF_SIZE_T__ = @as(c_int, 8);
pub const __SIZEOF_WCHAR_T__ = @as(c_int, 4);
pub const __SIZEOF_WINT_T__ = @as(c_int, 4);
pub const __SIZEOF_INT128__ = @as(c_int, 16);
pub const __INTPTR_TYPE__ = c_long;
pub const __UINTPTR_TYPE__ = c_ulong;
pub const __INTMAX_TYPE__ = c_long;
pub const __INTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`");
// <builtin>:154:9
pub const __INTMAX_C = __helpers.L_SUFFIX;
pub const __UINTMAX_TYPE__ = c_ulong;
pub const __UINTMAX_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`");
// <builtin>:157:9
pub const __UINTMAX_C = __helpers.UL_SUFFIX;
pub const __PTRDIFF_TYPE__ = c_long;
pub const __SIZE_TYPE__ = c_ulong;
pub const __WCHAR_TYPE__ = c_uint;
pub const __WINT_TYPE__ = c_uint;
pub const __CHAR16_TYPE__ = c_ushort;
pub const __CHAR32_TYPE__ = c_uint;
pub const __INT8_TYPE__ = i8;
pub const __INT8_FMTd__ = "hhd";
pub const __INT8_FMTi__ = "hhi";
pub const __INT8_C_SUFFIX__ = "";
pub inline fn __INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT16_TYPE__ = c_short;
pub const __INT16_FMTd__ = "hd";
pub const __INT16_FMTi__ = "hi";
pub const __INT16_C_SUFFIX__ = "";
pub inline fn __INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT32_TYPE__ = c_int;
pub const __INT32_FMTd__ = "d";
pub const __INT32_FMTi__ = "i";
pub const __INT32_C_SUFFIX__ = "";
pub inline fn __INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __INT64_TYPE__ = c_long;
pub const __INT64_FMTd__ = "ld";
pub const __INT64_FMTi__ = "li";
pub const __INT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `L`");
// <builtin>:183:9
pub const __UINT8_TYPE__ = u8;
pub const __UINT8_FMTo__ = "hho";
pub const __UINT8_FMTu__ = "hhu";
pub const __UINT8_FMTx__ = "hhx";
pub const __UINT8_FMTX__ = "hhX";
pub const __UINT8_C_SUFFIX__ = "";
pub inline fn __UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT8_MAX__ = @as(c_int, 255);
pub const __INT8_MAX__ = @as(c_int, 127);
pub const __UINT16_TYPE__ = c_ushort;
pub const __UINT16_FMTo__ = "ho";
pub const __UINT16_FMTu__ = "hu";
pub const __UINT16_FMTx__ = "hx";
pub const __UINT16_FMTX__ = "hX";
pub const __UINT16_C_SUFFIX__ = "";
pub inline fn __UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const __UINT16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const __INT16_MAX__ = @as(c_int, 32767);
pub const __UINT32_TYPE__ = c_uint;
pub const __UINT32_FMTo__ = "o";
pub const __UINT32_FMTu__ = "u";
pub const __UINT32_FMTx__ = "x";
pub const __UINT32_FMTX__ = "X";
pub const __UINT32_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `U`");
// <builtin>:208:9
pub const __UINT32_C = __helpers.U_SUFFIX;
pub const __UINT32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const __INT32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __UINT64_TYPE__ = c_ulong;
pub const __UINT64_FMTo__ = "lo";
pub const __UINT64_FMTu__ = "lu";
pub const __UINT64_FMTx__ = "lx";
pub const __UINT64_FMTX__ = "lX";
pub const __UINT64_C_SUFFIX__ = @compileError("unable to translate macro: undefined identifier `UL`");
// <builtin>:217:9
pub const __UINT64_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const __INT64_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST8_TYPE__ = i8;
pub const __INT_LEAST8_MAX__ = @as(c_int, 127);
pub const __INT_LEAST8_WIDTH__ = @as(c_int, 8);
pub const INT_LEAST8_FMTd__ = "hhd";
pub const INT_LEAST8_FMTi__ = "hhi";
pub const __UINT_LEAST8_TYPE__ = u8;
pub const __UINT_LEAST8_MAX__ = @as(c_int, 255);
pub const UINT_LEAST8_FMTo__ = "hho";
pub const UINT_LEAST8_FMTu__ = "hhu";
pub const UINT_LEAST8_FMTx__ = "hhx";
pub const UINT_LEAST8_FMTX__ = "hhX";
pub const __INT_FAST8_TYPE__ = i8;
pub const __INT_FAST8_MAX__ = @as(c_int, 127);
pub const __INT_FAST8_WIDTH__ = @as(c_int, 8);
pub const INT_FAST8_FMTd__ = "hhd";
pub const INT_FAST8_FMTi__ = "hhi";
pub const __UINT_FAST8_TYPE__ = u8;
pub const __UINT_FAST8_MAX__ = @as(c_int, 255);
pub const UINT_FAST8_FMTo__ = "hho";
pub const UINT_FAST8_FMTu__ = "hhu";
pub const UINT_FAST8_FMTx__ = "hhx";
pub const UINT_FAST8_FMTX__ = "hhX";
pub const __INT_LEAST16_TYPE__ = c_short;
pub const __INT_LEAST16_MAX__ = @as(c_int, 32767);
pub const __INT_LEAST16_WIDTH__ = @as(c_int, 16);
pub const INT_LEAST16_FMTd__ = "hd";
pub const INT_LEAST16_FMTi__ = "hi";
pub const __UINT_LEAST16_TYPE__ = c_ushort;
pub const __UINT_LEAST16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_LEAST16_FMTo__ = "ho";
pub const UINT_LEAST16_FMTu__ = "hu";
pub const UINT_LEAST16_FMTx__ = "hx";
pub const UINT_LEAST16_FMTX__ = "hX";
pub const __INT_FAST16_TYPE__ = c_short;
pub const __INT_FAST16_MAX__ = @as(c_int, 32767);
pub const __INT_FAST16_WIDTH__ = @as(c_int, 16);
pub const INT_FAST16_FMTd__ = "hd";
pub const INT_FAST16_FMTi__ = "hi";
pub const __UINT_FAST16_TYPE__ = c_ushort;
pub const __UINT_FAST16_MAX__ = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_FAST16_FMTo__ = "ho";
pub const UINT_FAST16_FMTu__ = "hu";
pub const UINT_FAST16_FMTx__ = "hx";
pub const UINT_FAST16_FMTX__ = "hX";
pub const __INT_LEAST32_TYPE__ = c_int;
pub const __INT_LEAST32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_LEAST32_WIDTH__ = @as(c_int, 32);
pub const INT_LEAST32_FMTd__ = "d";
pub const INT_LEAST32_FMTi__ = "i";
pub const __UINT_LEAST32_TYPE__ = c_uint;
pub const __UINT_LEAST32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_LEAST32_FMTo__ = "o";
pub const UINT_LEAST32_FMTu__ = "u";
pub const UINT_LEAST32_FMTx__ = "x";
pub const UINT_LEAST32_FMTX__ = "X";
pub const __INT_FAST32_TYPE__ = c_int;
pub const __INT_FAST32_MAX__ = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const __INT_FAST32_WIDTH__ = @as(c_int, 32);
pub const INT_FAST32_FMTd__ = "d";
pub const INT_FAST32_FMTi__ = "i";
pub const __UINT_FAST32_TYPE__ = c_uint;
pub const __UINT_FAST32_MAX__ = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_FAST32_FMTo__ = "o";
pub const UINT_FAST32_FMTu__ = "u";
pub const UINT_FAST32_FMTx__ = "x";
pub const UINT_FAST32_FMTX__ = "X";
pub const __INT_LEAST64_TYPE__ = c_long;
pub const __INT_LEAST64_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_LEAST64_WIDTH__ = @as(c_int, 64);
pub const INT_LEAST64_FMTd__ = "ld";
pub const INT_LEAST64_FMTi__ = "li";
pub const __UINT_LEAST64_TYPE__ = c_ulong;
pub const __UINT_LEAST64_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_LEAST64_FMTo__ = "lo";
pub const UINT_LEAST64_FMTu__ = "lu";
pub const UINT_LEAST64_FMTx__ = "lx";
pub const UINT_LEAST64_FMTX__ = "lX";
pub const __INT_FAST64_TYPE__ = c_long;
pub const __INT_FAST64_MAX__ = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const __INT_FAST64_WIDTH__ = @as(c_int, 64);
pub const INT_FAST64_FMTd__ = "ld";
pub const INT_FAST64_FMTi__ = "li";
pub const __UINT_FAST64_TYPE__ = c_ulong;
pub const __UINT_FAST64_MAX__ = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST64_FMTo__ = "lo";
pub const UINT_FAST64_FMTu__ = "lu";
pub const UINT_FAST64_FMTx__ = "lx";
pub const UINT_FAST64_FMTX__ = "lX";
pub const __FLT16_DENORM_MIN__ = @as(f16, 5.9604644775390625e-8);
pub const __FLT16_HAS_DENORM__ = "";
pub const __FLT16_DIG__ = @as(c_int, 3);
pub const __FLT16_DECIMAL_DIG__ = @as(c_int, 5);
pub const __FLT16_EPSILON__ = @as(f16, 9.765625e-4);
pub const __FLT16_HAS_INFINITY__ = "";
pub const __FLT16_HAS_QUIET_NAN__ = "";
pub const __FLT16_MANT_DIG__ = @as(c_int, 11);
pub const __FLT16_MAX_10_EXP__ = @as(c_int, 4);
pub const __FLT16_MAX_EXP__ = @as(c_int, 16);
pub const __FLT16_MAX__ = @as(f16, 6.5504e+4);
pub const __FLT16_MIN_10_EXP__ = -@as(c_int, 4);
pub const __FLT16_MIN_EXP__ = -@as(c_int, 13);
pub const __FLT16_MIN__ = @as(f16, 6.103515625e-5);
pub const __FLT_DENORM_MIN__ = @as(f32, 1.40129846e-45);
pub const __FLT_HAS_DENORM__ = "";
pub const __FLT_DIG__ = @as(c_int, 6);
pub const __FLT_DECIMAL_DIG__ = @as(c_int, 9);
pub const __FLT_EPSILON__ = @as(f32, 1.19209290e-7);
pub const __FLT_HAS_INFINITY__ = "";
pub const __FLT_HAS_QUIET_NAN__ = "";
pub const __FLT_MANT_DIG__ = @as(c_int, 24);
pub const __FLT_MAX_10_EXP__ = @as(c_int, 38);
pub const __FLT_MAX_EXP__ = @as(c_int, 128);
pub const __FLT_MAX__ = @as(f32, 3.40282347e+38);
pub const __FLT_MIN_10_EXP__ = -@as(c_int, 37);
pub const __FLT_MIN_EXP__ = -@as(c_int, 125);
pub const __FLT_MIN__ = @as(f32, 1.17549435e-38);
pub const __DBL_DENORM_MIN__ = @as(f64, 4.9406564584124654e-324);
pub const __DBL_HAS_DENORM__ = "";
pub const __DBL_DIG__ = @as(c_int, 15);
pub const __DBL_DECIMAL_DIG__ = @as(c_int, 17);
pub const __DBL_EPSILON__ = @as(f64, 2.2204460492503131e-16);
pub const __DBL_HAS_INFINITY__ = "";
pub const __DBL_HAS_QUIET_NAN__ = "";
pub const __DBL_MANT_DIG__ = @as(c_int, 53);
pub const __DBL_MAX_10_EXP__ = @as(c_int, 308);
pub const __DBL_MAX_EXP__ = @as(c_int, 1024);
pub const __DBL_MAX__ = @as(f64, 1.7976931348623157e+308);
pub const __DBL_MIN_10_EXP__ = -@as(c_int, 307);
pub const __DBL_MIN_EXP__ = -@as(c_int, 1021);
pub const __DBL_MIN__ = @as(f64, 2.2250738585072014e-308);
pub const __LDBL_DENORM_MIN__ = @as(c_longdouble, 6.47517511943802511092443895822764655e-4966);
pub const __LDBL_HAS_DENORM__ = "";
pub const __LDBL_DIG__ = @as(c_int, 33);
pub const __LDBL_DECIMAL_DIG__ = @as(c_int, 36);
pub const __LDBL_EPSILON__ = @as(c_longdouble, 1.92592994438723585305597794258492732e-34);
pub const __LDBL_HAS_INFINITY__ = "";
pub const __LDBL_HAS_QUIET_NAN__ = "";
pub const __LDBL_MANT_DIG__ = @as(c_int, 113);
pub const __LDBL_MAX_10_EXP__ = @as(c_int, 4932);
pub const __LDBL_MAX_EXP__ = @as(c_int, 16384);
pub const __LDBL_MAX__ = @as(c_longdouble, 1.18973149535723176508575932662800702e+4932);
pub const __LDBL_MIN_10_EXP__ = -@as(c_int, 4931);
pub const __LDBL_MIN_EXP__ = -@as(c_int, 16381);
pub const __LDBL_MIN__ = @as(c_longdouble, 3.36210314311209350626267781732175260e-4932);
pub const __FLT_EVAL_METHOD__ = @as(c_int, 0);
pub const __FLT_RADIX__ = @as(c_int, 2);
pub const __DECIMAL_DIG__ = __LDBL_DECIMAL_DIG__;
pub const _GNU_SOURCE = "";
pub const JITTERENTROPY_UNIT_H = "";
pub const _JITTERENTROPY_MEMLOCK_H = "";
pub const _JITTERENTROPY_H = "";
pub const _GCC_LIMITS_H_ = "";
pub const __CLANG_LIMITS_H = "";
pub const _LIBC_LIMITS_H_ = @as(c_int, 1);
pub const _FEATURES_H = @as(c_int, 1);
pub const __KERNEL_STRICT_NAMES = "";
pub inline fn __GNUC_PREREQ(maj: anytype, min: anytype) @TypeOf(((__GNUC__ << @as(c_int, 16)) + __GNUC_MINOR__) >= ((maj << @as(c_int, 16)) + min)) {
    _ = &maj;
    _ = &min;
    return ((__GNUC__ << @as(c_int, 16)) + __GNUC_MINOR__) >= ((maj << @as(c_int, 16)) + min);
}
pub inline fn __glibc_clang_prereq(maj: anytype, min: anytype) @TypeOf(@as(c_int, 0)) {
    _ = &maj;
    _ = &min;
    return @as(c_int, 0);
}
pub const __GLIBC_USE = @compileError("unable to translate macro: undefined identifier `__GLIBC_USE_`");
// /usr/include/features.h:197:9
pub const _ISOC95_SOURCE = @as(c_int, 1);
pub const _ISOC99_SOURCE = @as(c_int, 1);
pub const _ISOC11_SOURCE = @as(c_int, 1);
pub const _ISOC23_SOURCE = @as(c_int, 1);
pub const _ISOC2Y_SOURCE = @as(c_int, 1);
pub const _XOPEN_SOURCE = @as(c_int, 800);
pub const _XOPEN_SOURCE_EXTENDED = @as(c_int, 1);
pub const _LARGEFILE64_SOURCE = @as(c_int, 1);
pub const _DYNAMIC_STACK_SIZE_SOURCE = @as(c_int, 1);
pub const _DEFAULT_SOURCE = @as(c_int, 1);
pub const __GLIBC_USE_ISOC2Y = @as(c_int, 1);
pub const __GLIBC_USE_ISOC23 = @as(c_int, 1);
pub const __USE_ISOC11 = @as(c_int, 1);
pub const _POSIX_SOURCE = @as(c_int, 1);
pub const _POSIX_C_SOURCE = @as(c_long, 202405);
pub const __USE_POSIX = @as(c_int, 1);
pub const __USE_POSIX2 = @as(c_int, 1);
pub const __USE_POSIX199309 = @as(c_int, 1);
pub const __USE_POSIX199506 = @as(c_int, 1);
pub const __USE_XOPEN2K = @as(c_int, 1);
pub const __USE_XOPEN2K8 = @as(c_int, 1);
pub const _ATFILE_SOURCE = @as(c_int, 1);
pub const __USE_XOPEN2K24 = @as(c_int, 1);
pub const __USE_XOPEN = @as(c_int, 1);
pub const __USE_XOPEN_EXTENDED = @as(c_int, 1);
pub const __USE_UNIX98 = @as(c_int, 1);
pub const _LARGEFILE_SOURCE = @as(c_int, 1);
pub const __USE_XOPEN2K8XSI = @as(c_int, 1);
pub const __USE_XOPEN2K24XSI = @as(c_int, 1);
pub const __USE_XOPEN2KXSI = @as(c_int, 1);
pub const __USE_ISOC95 = @as(c_int, 1);
pub const __USE_ISOC99 = @as(c_int, 1);
pub const __USE_LARGEFILE = @as(c_int, 1);
pub const __USE_LARGEFILE64 = @as(c_int, 1);
pub const __WORDSIZE = @as(c_int, 64);
pub const __WORDSIZE_TIME64_COMPAT32 = @as(c_int, 0);
pub const __TIMESIZE = @as(c_int, 64);
pub const __USE_TIME_BITS64 = @as(c_int, 1);
pub const __USE_MISC = @as(c_int, 1);
pub const __USE_ATFILE = @as(c_int, 1);
pub const __USE_DYNAMIC_STACK_SIZE = @as(c_int, 1);
pub const __USE_GNU = @as(c_int, 1);
pub const __USE_FORTIFY_LEVEL = @as(c_int, 0);
pub const __GLIBC_USE_DEPRECATED_GETS = @as(c_int, 0);
pub const __GLIBC_USE_DEPRECATED_SCANF = @as(c_int, 0);
pub const __GLIBC_USE_C23_STRTOL = @as(c_int, 1);
pub const _STDC_PREDEF_H = @as(c_int, 1);
pub const __STDC_IEC_559__ = @as(c_int, 1);
pub const __STDC_IEC_60559_BFP__ = @as(c_long, 201404);
pub const __STDC_IEC_559_COMPLEX__ = @as(c_int, 1);
pub const __STDC_IEC_60559_COMPLEX__ = @as(c_long, 201404);
pub const __STDC_ISO_10646__ = @as(c_long, 201706);
pub const __GNU_LIBRARY__ = @as(c_int, 6);
pub const __GLIBC__ = @as(c_int, 2);
pub const __GLIBC_MINOR__ = @as(c_int, 43);
pub inline fn __GLIBC_PREREQ(maj: anytype, min: anytype) @TypeOf(((__GLIBC__ << @as(c_int, 16)) + __GLIBC_MINOR__) >= ((maj << @as(c_int, 16)) + min)) {
    _ = &maj;
    _ = &min;
    return ((__GLIBC__ << @as(c_int, 16)) + __GLIBC_MINOR__) >= ((maj << @as(c_int, 16)) + min);
}
pub const _SYS_CDEFS_H = @as(c_int, 1);
pub const __glibc_has_attribute = @compileError("unable to translate macro: undefined identifier `__has_attribute`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:45:10
pub inline fn __glibc_has_builtin(name: anytype) @TypeOf(__builtin.has_builtin(name)) {
    _ = &name;
    return __builtin.has_builtin(name);
}
pub const __glibc_has_extension = @compileError("unable to translate macro: undefined identifier `__has_extension`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:55:10
pub const __LEAF = @compileError("unable to translate macro: undefined identifier `__leaf__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:65:11
pub const __LEAF_ATTR = @compileError("unable to translate macro: undefined identifier `__leaf__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:66:11
pub const __THROW = @compileError("unable to translate macro: undefined identifier `__nothrow__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:79:11
pub const __THROWNL = @compileError("unable to translate macro: undefined identifier `__nothrow__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:80:11
pub const __NTH = @compileError("unable to translate macro: undefined identifier `__nothrow__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:81:11
pub const __NTHNL = @compileError("unable to translate macro: undefined identifier `__nothrow__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:82:11
pub const __COLD = @compileError("unable to translate macro: undefined identifier `__cold__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:102:11
pub inline fn __P(args: anytype) @TypeOf(args) {
    _ = &args;
    return args;
}
pub inline fn __PMT(args: anytype) @TypeOf(args) {
    _ = &args;
    return args;
}
pub const __CONCAT = @compileError("unable to translate C expr: unexpected token '##'");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:131:9
pub const __STRING = @compileError("unable to translate C expr: unexpected token ''");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:132:9
pub const __ptr_t = ?*anyopaque;
pub const __BEGIN_DECLS = "";
pub const __END_DECLS = "";
pub const __attribute_overloadable__ = "";
pub inline fn __bos(ptr: anytype) @TypeOf(__builtin.object_size(ptr, __USE_FORTIFY_LEVEL > @as(c_int, 1))) {
    _ = &ptr;
    return __builtin.object_size(ptr, __USE_FORTIFY_LEVEL > @as(c_int, 1));
}
pub inline fn __bos0(ptr: anytype) @TypeOf(__builtin.object_size(ptr, @as(c_int, 0))) {
    _ = &ptr;
    return __builtin.object_size(ptr, @as(c_int, 0));
}
pub inline fn __glibc_objsize0(__o: anytype) @TypeOf(__bos0(__o)) {
    _ = &__o;
    return __bos0(__o);
}
pub inline fn __glibc_objsize(__o: anytype) @TypeOf(__bos(__o)) {
    _ = &__o;
    return __bos(__o);
}
pub const __warnattr = @compileError("unable to translate macro: undefined identifier `__warning__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:366:10
pub const __errordecl = @compileError("unable to translate macro: undefined identifier `__error__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:367:10
pub const __flexarr = @compileError("unable to translate C expr: unexpected token '['");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:379:10
pub const __glibc_c99_flexarr_available = @as(c_int, 1);
pub const __REDIRECT = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:410:10
pub const __REDIRECT_NTH = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:417:11
pub const __REDIRECT_NTHNL = @compileError("unable to translate C expr: unexpected token '__asm__'");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:419:11
pub const __ASMNAME = @compileError("unable to translate macro: undefined identifier `__USER_LABEL_PREFIX__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:422:10
pub inline fn __ASMNAME2(prefix: anytype, cname: anytype) @TypeOf(__STRING(prefix) ++ cname) {
    _ = &prefix;
    _ = &cname;
    return __STRING(prefix) ++ cname;
}
pub const __REDIRECT_FORTIFY = __REDIRECT;
pub const __REDIRECT_FORTIFY_NTH = __REDIRECT_NTH;
pub const __attribute_malloc__ = @compileError("unable to translate macro: undefined identifier `__malloc__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:452:10
pub const __attribute_alloc_size__ = @compileError("unable to translate macro: undefined identifier `__alloc_size__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:460:10
pub const __attribute_alloc_align__ = @compileError("unable to translate macro: undefined identifier `__alloc_align__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:469:10
pub const __attribute_pure__ = @compileError("unable to translate macro: undefined identifier `__pure__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:479:10
pub const __attribute_const__ = @compileError("unable to translate C expr: unexpected token '__attribute__'");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:486:10
pub const __attribute_maybe_unused__ = @compileError("unable to translate macro: undefined identifier `__unused__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:492:10
pub const __attribute_used__ = @compileError("unable to translate macro: undefined identifier `__used__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:501:10
pub const __attribute_noinline__ = @compileError("unable to translate macro: undefined identifier `__noinline__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:502:10
pub const __attribute_deprecated__ = @compileError("unable to translate macro: undefined identifier `__deprecated__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:510:10
pub const __attribute_deprecated_msg__ = @compileError("unable to translate macro: undefined identifier `__deprecated__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:520:10
pub const __attribute_format_arg__ = @compileError("unable to translate macro: undefined identifier `__format_arg__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:533:10
pub const __attribute_format_strfmon__ = @compileError("unable to translate macro: undefined identifier `__format__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:543:10
pub const __attribute_nonnull__ = @compileError("unable to translate macro: undefined identifier `__nonnull__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:555:11
pub inline fn __nonnull(params: anytype) @TypeOf(__attribute_nonnull__(params)) {
    _ = &params;
    return __attribute_nonnull__(params);
}
pub const __returns_nonnull = @compileError("unable to translate macro: undefined identifier `__returns_nonnull__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:568:10
pub const __attribute_warn_unused_result__ = @compileError("unable to translate macro: undefined identifier `__warn_unused_result__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:577:10
pub const __wur = "";
pub const __always_inline = @compileError("unable to translate macro: undefined identifier `__always_inline__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:595:10
pub const __attribute_artificial__ = @compileError("unable to translate macro: undefined identifier `__artificial__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:604:10
pub const __extern_inline = @compileError("unable to translate C expr: unexpected token 'extern'");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:626:11
pub const __extern_always_inline = @compileError("unable to translate C expr: unexpected token 'extern'");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:627:11
pub const __fortify_function = __extern_always_inline ++ __attribute_artificial__;
pub const __va_arg_pack = @compileError("unable to translate macro: undefined identifier `__builtin_va_arg_pack`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:638:10
pub const __va_arg_pack_len = @compileError("unable to translate macro: undefined identifier `__builtin_va_arg_pack_len`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:639:10
pub const __restrict_arr = @compileError("unable to translate C expr: unexpected token '__restrict'");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:666:10
pub inline fn __glibc_unlikely(cond: anytype) @TypeOf(__builtin.expect(cond, @as(c_int, 0))) {
    _ = &cond;
    return __builtin.expect(cond, @as(c_int, 0));
}
pub inline fn __glibc_likely(cond: anytype) @TypeOf(__builtin.expect(cond, @as(c_int, 1))) {
    _ = &cond;
    return __builtin.expect(cond, @as(c_int, 1));
}
pub const __attribute_nonstring__ = "";
pub inline fn __attribute_copy__(arg: anytype) void {
    _ = &arg;
    return;
}
pub const __LDOUBLE_REDIRECTS_TO_FLOAT128_ABI = @as(c_int, 0);
pub inline fn __LDBL_REDIR1(name: anytype, proto: anytype, alias: anytype) @TypeOf(name ++ proto) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return name ++ proto;
}
pub inline fn __LDBL_REDIR(name: anytype, proto: anytype) @TypeOf(name ++ proto) {
    _ = &name;
    _ = &proto;
    return name ++ proto;
}
pub inline fn __LDBL_REDIR1_NTH(name: anytype, proto: anytype, alias: anytype) @TypeOf(name ++ proto ++ __THROW) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return name ++ proto ++ __THROW;
}
pub inline fn __LDBL_REDIR_NTH(name: anytype, proto: anytype) @TypeOf(name ++ proto ++ __THROW) {
    _ = &name;
    _ = &proto;
    return name ++ proto ++ __THROW;
}
pub inline fn __LDBL_REDIR2_DECL(name: anytype) void {
    _ = &name;
    return;
}
pub inline fn __LDBL_REDIR_DECL(name: anytype) void {
    _ = &name;
    return;
}
pub inline fn __REDIRECT_LDBL(name: anytype, proto: anytype, alias: anytype) @TypeOf(__REDIRECT(name, proto, alias)) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return __REDIRECT(name, proto, alias);
}
pub inline fn __REDIRECT_NTH_LDBL(name: anytype, proto: anytype, alias: anytype) @TypeOf(__REDIRECT_NTH(name, proto, alias)) {
    _ = &name;
    _ = &proto;
    _ = &alias;
    return __REDIRECT_NTH(name, proto, alias);
}
pub const __glibc_macro_warning1 = @compileError("unable to translate macro: undefined identifier `_Pragma`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:807:10
pub const __glibc_macro_warning = @compileError("unable to translate macro: undefined identifier `GCC`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:808:10
pub const __HAVE_GENERIC_SELECTION = @as(c_int, 1);
pub const __glibc_const_generic = @compileError("unable to translate C expr: expected type instead got 'const'");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:837:10
pub inline fn __fortified_attr_access(a: anytype, o: anytype, s: anytype) void {
    _ = &a;
    _ = &o;
    _ = &s;
    return;
}
pub inline fn __attr_access(x: anytype) void {
    _ = &x;
    return;
}
pub inline fn __attr_access_none(argno: anytype) void {
    _ = &argno;
    return;
}
pub inline fn __attr_dealloc(dealloc: anytype, argno: anytype) void {
    _ = &dealloc;
    _ = &argno;
    return;
}
pub const __attr_dealloc_free = "";
pub const __attribute_returns_twice__ = @compileError("unable to translate macro: undefined identifier `__returns_twice__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:884:10
pub const __attribute_struct_may_alias__ = @compileError("unable to translate macro: undefined identifier `__may_alias__`");
// /usr/include/aarch64-linux-gnu/sys/cdefs.h:893:10
pub const __stub___compat_bdflush = "";
pub const __stub___compat_create_module = "";
pub const __stub___compat_get_kernel_syms = "";
pub const __stub___compat_query_module = "";
pub const __stub___compat_uselib = "";
pub const __stub_chflags = "";
pub const __stub_fchflags = "";
pub const __stub_gtty = "";
pub const __stub_revoke = "";
pub const __stub_setlogin = "";
pub const __stub_sigreturn = "";
pub const __stub_stty = "";
pub const MB_LEN_MAX = @as(c_int, 16);
pub const CHAR_WIDTH = @as(c_int, 8);
pub const SCHAR_WIDTH = @as(c_int, 8);
pub const UCHAR_WIDTH = @as(c_int, 8);
pub const SHRT_WIDTH = @as(c_int, 16);
pub const USHRT_WIDTH = @as(c_int, 16);
pub const INT_WIDTH = @as(c_int, 32);
pub const UINT_WIDTH = @as(c_int, 32);
pub const LONG_WIDTH = __WORDSIZE;
pub const ULONG_WIDTH = __WORDSIZE;
pub const LLONG_WIDTH = @as(c_int, 64);
pub const ULLONG_WIDTH = @as(c_int, 64);
pub const BOOL_MAX = @as(c_int, 1);
pub const BOOL_WIDTH = @as(c_int, 1);
pub const __STDC_VERSION_LIMITS_H__ = @as(c_long, 202311);
pub const _BITS_POSIX1_LIM_H = @as(c_int, 1);
pub const _POSIX_AIO_LISTIO_MAX = @as(c_int, 2);
pub const _POSIX_AIO_MAX = @as(c_int, 1);
pub const _POSIX_ARG_MAX = @as(c_int, 4096);
pub const _POSIX_CHILD_MAX = @as(c_int, 25);
pub const _POSIX_DELAYTIMER_MAX = @as(c_int, 32);
pub const _POSIX_HOST_NAME_MAX = @as(c_int, 255);
pub const _POSIX_LINK_MAX = @as(c_int, 8);
pub const _POSIX_LOGIN_NAME_MAX = @as(c_int, 9);
pub const _POSIX_MAX_CANON = @as(c_int, 255);
pub const _POSIX_MAX_INPUT = @as(c_int, 255);
pub const _POSIX_MQ_OPEN_MAX = @as(c_int, 8);
pub const _POSIX_MQ_PRIO_MAX = @as(c_int, 32);
pub const _POSIX_NAME_MAX = @as(c_int, 14);
pub const _POSIX_NGROUPS_MAX = @as(c_int, 8);
pub const _POSIX_OPEN_MAX = @as(c_int, 20);
pub const _POSIX_FD_SETSIZE = _POSIX_OPEN_MAX;
pub const _POSIX_PATH_MAX = @as(c_int, 256);
pub const _POSIX_PIPE_BUF = @as(c_int, 512);
pub const _POSIX_RE_DUP_MAX = @as(c_int, 255);
pub const _POSIX_RTSIG_MAX = @as(c_int, 8);
pub const _POSIX_SEM_NSEMS_MAX = @as(c_int, 256);
pub const _POSIX_SEM_VALUE_MAX = @as(c_int, 32767);
pub const _POSIX_SIGQUEUE_MAX = @as(c_int, 32);
pub const _POSIX_SSIZE_MAX = @as(c_int, 32767);
pub const _POSIX_STREAM_MAX = @as(c_int, 8);
pub const _POSIX_SYMLINK_MAX = @as(c_int, 255);
pub const _POSIX_SYMLOOP_MAX = @as(c_int, 8);
pub const _POSIX_TIMER_MAX = @as(c_int, 32);
pub const _POSIX_TTY_NAME_MAX = @as(c_int, 9);
pub const _POSIX_TZNAME_MAX = @as(c_int, 6);
pub const _POSIX_QLIMIT = @as(c_int, 1);
pub const _POSIX_HIWAT = _POSIX_PIPE_BUF;
pub const _POSIX_UIO_MAXIOV = @as(c_int, 16);
pub const _POSIX_CLOCKRES_MIN = __helpers.promoteIntLiteral(c_int, 20000000, .decimal);
pub const _LINUX_LIMITS_H = "";
pub const NGROUPS_MAX = __helpers.promoteIntLiteral(c_int, 65536, .decimal);
pub const MAX_CANON = @as(c_int, 255);
pub const MAX_INPUT = @as(c_int, 255);
pub const NAME_MAX = @as(c_int, 255);
pub const PATH_MAX = @as(c_int, 4096);
pub const PIPE_BUF = @as(c_int, 4096);
pub const XATTR_NAME_MAX = @as(c_int, 255);
pub const XATTR_SIZE_MAX = __helpers.promoteIntLiteral(c_int, 65536, .decimal);
pub const XATTR_LIST_MAX = __helpers.promoteIntLiteral(c_int, 65536, .decimal);
pub const RTSIG_MAX = @as(c_int, 32);
pub const _POSIX_THREAD_KEYS_MAX = @as(c_int, 128);
pub const PTHREAD_KEYS_MAX = @as(c_int, 1024);
pub const _POSIX_THREAD_DESTRUCTOR_ITERATIONS = @as(c_int, 4);
pub const PTHREAD_DESTRUCTOR_ITERATIONS = _POSIX_THREAD_DESTRUCTOR_ITERATIONS;
pub const _POSIX_THREAD_THREADS_MAX = @as(c_int, 64);
pub const AIO_PRIO_DELTA_MAX = @as(c_int, 20);
pub const __SC_THREAD_STACK_MIN_VALUE = @as(c_int, 75);
pub const PTHREAD_STACK_MIN = __sysconf(__SC_THREAD_STACK_MIN_VALUE);
pub const DELAYTIMER_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const TTY_NAME_MAX = @as(c_int, 32);
pub const LOGIN_NAME_MAX = @as(c_int, 256);
pub const HOST_NAME_MAX = @as(c_int, 64);
pub const MQ_PRIO_MAX = __helpers.promoteIntLiteral(c_int, 32768, .decimal);
pub const SEM_VALUE_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const SSIZE_MAX = LONG_MAX;
pub const _BITS_POSIX2_LIM_H = @as(c_int, 1);
pub const _POSIX2_BC_BASE_MAX = @as(c_int, 99);
pub const _POSIX2_BC_DIM_MAX = @as(c_int, 2048);
pub const _POSIX2_BC_SCALE_MAX = @as(c_int, 99);
pub const _POSIX2_BC_STRING_MAX = @as(c_int, 1000);
pub const _POSIX2_COLL_WEIGHTS_MAX = @as(c_int, 2);
pub const _POSIX2_EXPR_NEST_MAX = @as(c_int, 32);
pub const _POSIX2_LINE_MAX = @as(c_int, 2048);
pub const _POSIX2_RE_DUP_MAX = @as(c_int, 255);
pub const _POSIX2_CHARCLASS_NAME_MAX = @as(c_int, 14);
pub const BC_BASE_MAX = _POSIX2_BC_BASE_MAX;
pub const BC_DIM_MAX = _POSIX2_BC_DIM_MAX;
pub const BC_SCALE_MAX = _POSIX2_BC_SCALE_MAX;
pub const BC_STRING_MAX = _POSIX2_BC_STRING_MAX;
pub const COLL_WEIGHTS_MAX = @as(c_int, 255);
pub const EXPR_NEST_MAX = _POSIX2_EXPR_NEST_MAX;
pub const LINE_MAX = _POSIX2_LINE_MAX;
pub const CHARCLASS_NAME_MAX = @as(c_int, 2048);
pub const RE_DUP_MAX = @as(c_int, 0x7fff);
pub const _XOPEN_LIM_H = @as(c_int, 1);
pub const _XOPEN_IOV_MAX = _POSIX_UIO_MAXIOV;
pub const _BITS_UIO_LIM_H = @as(c_int, 1);
pub const __IOV_MAX = @as(c_int, 1024);
pub const IOV_MAX = __IOV_MAX;
pub const NL_ARGMAX = _POSIX_ARG_MAX;
pub const NL_LANGMAX = _POSIX2_LINE_MAX;
pub const NL_MSGMAX = INT_MAX;
pub const NL_NMAX = INT_MAX;
pub const NL_SETMAX = INT_MAX;
pub const NL_TEXTMAX = INT_MAX;
pub const NZERO = @as(c_int, 20);
pub const WORD_BIT = @as(c_int, 32);
pub const LONG_BIT = @as(c_int, 64);
pub const LONG_LONG_MAX = __LONG_LONG_MAX__;
pub const LONG_LONG_MIN = -__LONG_LONG_MAX__ - @as(c_longlong, 1);
pub const ULONG_LONG_MAX = (__LONG_LONG_MAX__ * @as(c_ulonglong, 2)) + @as(c_ulonglong, 1);
pub const SCHAR_MAX = __SCHAR_MAX__;
pub const SHRT_MAX = __SHRT_MAX__;
pub const INT_MAX = __INT_MAX__;
pub const LONG_MAX = __LONG_MAX__;
pub const SCHAR_MIN = -__SCHAR_MAX__ - @as(c_int, 1);
pub const SHRT_MIN = -__SHRT_MAX__ - @as(c_int, 1);
pub const INT_MIN = -__INT_MAX__ - @as(c_int, 1);
pub const LONG_MIN = -__LONG_MAX__ - @as(c_long, 1);
pub const UCHAR_MAX = (__SCHAR_MAX__ * @as(c_int, 2)) + @as(c_int, 1);
pub const USHRT_MAX = (__SHRT_MAX__ * @as(c_int, 2)) + @as(c_int, 1);
pub const UINT_MAX = (__INT_MAX__ * @as(c_uint, 2)) + @as(c_uint, 1);
pub const ULONG_MAX = (__LONG_MAX__ * @as(c_ulong, 2)) + @as(c_ulong, 1);
pub const CHAR_BIT = __CHAR_BIT__;
pub const CHAR_MIN = @as(c_int, 0);
pub const CHAR_MAX = UCHAR_MAX;
pub const LLONG_MIN = -__LONG_LONG_MAX__ - @as(c_longlong, 1);
pub const LLONG_MAX = __LONG_LONG_MAX__;
pub const ULLONG_MAX = (__LONG_LONG_MAX__ * @as(c_ulonglong, 2)) + @as(c_ulonglong, 1);
pub const _TIME_H = @as(c_int, 1);
pub const __need_size_t = "";
pub const __need_NULL = "";
pub const __STDC_VERSION_STDDEF_H__ = @as(c_long, 202311);
pub const NULL = __helpers.cast(?*anyopaque, @as(c_int, 0));
pub const offsetof = @compileError("unable to translate macro: undefined identifier `__builtin_offsetof`");
// /home/g/.local/share/ghr/tools/_v2/units/u-cataggar/u-zig/_unit/zig-aarch64-linux-0.17.0/lib/compiler/aro/include/stddef.h:18:9
pub const __STDC_VERSION_TIME_H__ = @as(c_long, 202311);
pub const _BITS_TIME_H = @as(c_int, 1);
pub const _BITS_TYPES_H = @as(c_int, 1);
pub const __S16_TYPE = c_short;
pub const __U16_TYPE = c_ushort;
pub const __S32_TYPE = c_int;
pub const __U32_TYPE = c_uint;
pub const __SLONGWORD_TYPE = c_long;
pub const __ULONGWORD_TYPE = c_ulong;
pub const __SQUAD_TYPE = c_long;
pub const __UQUAD_TYPE = c_ulong;
pub const __SWORD_TYPE = c_long;
pub const __UWORD_TYPE = c_ulong;
pub const __SLONG32_TYPE = c_int;
pub const __ULONG32_TYPE = c_uint;
pub const __S64_TYPE = c_long;
pub const __U64_TYPE = c_ulong;
pub const _BITS_TYPESIZES_H = @as(c_int, 1);
pub const __INO_T_TYPE = __ULONGWORD_TYPE;
pub const __OFF_T_TYPE = __SLONGWORD_TYPE;
pub const __RLIM_T_TYPE = __ULONGWORD_TYPE;
pub const __BLKCNT_T_TYPE = __SLONGWORD_TYPE;
pub const __FSBLKCNT_T_TYPE = __ULONGWORD_TYPE;
pub const __FSFILCNT_T_TYPE = __ULONGWORD_TYPE;
pub const __TIME_T_TYPE = __SLONGWORD_TYPE;
pub const __SUSECONDS_T_TYPE = __SLONGWORD_TYPE;
pub const __DEV_T_TYPE = __UQUAD_TYPE;
pub const __UID_T_TYPE = __U32_TYPE;
pub const __GID_T_TYPE = __U32_TYPE;
pub const __INO64_T_TYPE = __UQUAD_TYPE;
pub const __MODE_T_TYPE = __U32_TYPE;
pub const __NLINK_T_TYPE = __U32_TYPE;
pub const __OFF64_T_TYPE = __SQUAD_TYPE;
pub const __PID_T_TYPE = __S32_TYPE;
pub const __RLIM64_T_TYPE = __UQUAD_TYPE;
pub const __BLKCNT64_T_TYPE = __SQUAD_TYPE;
pub const __FSBLKCNT64_T_TYPE = __UQUAD_TYPE;
pub const __FSFILCNT64_T_TYPE = __UQUAD_TYPE;
pub const __FSWORD_T_TYPE = __SWORD_TYPE;
pub const __ID_T_TYPE = __U32_TYPE;
pub const __CLOCK_T_TYPE = __SLONGWORD_TYPE;
pub const __USECONDS_T_TYPE = __U32_TYPE;
pub const __SUSECONDS64_T_TYPE = __SQUAD_TYPE;
pub const __DADDR_T_TYPE = __S32_TYPE;
pub const __KEY_T_TYPE = __S32_TYPE;
pub const __CLOCKID_T_TYPE = __S32_TYPE;
pub const __TIMER_T_TYPE = ?*anyopaque;
pub const __BLKSIZE_T_TYPE = __S32_TYPE;
pub const __FSID_T_TYPE = @compileError("unable to translate macro: undefined identifier `__val`");
// /usr/include/aarch64-linux-gnu/bits/typesizes.h:72:9
pub const __SSIZE_T_TYPE = __SWORD_TYPE;
pub const __SYSCALL_SLONG_TYPE = __SLONGWORD_TYPE;
pub const __SYSCALL_ULONG_TYPE = __ULONGWORD_TYPE;
pub const __CPU_MASK_TYPE = __ULONGWORD_TYPE;
pub const __OFF_T_MATCHES_OFF64_T = @as(c_int, 1);
pub const __INO_T_MATCHES_INO64_T = @as(c_int, 1);
pub const __RLIM_T_MATCHES_RLIM64_T = @as(c_int, 1);
pub const __STATFS_MATCHES_STATFS64 = @as(c_int, 1);
pub const __KERNEL_OLD_TIMEVAL_MATCHES_TIMEVAL64 = __WORDSIZE == @as(c_int, 64);
pub const _BITS_TIME64_H = @as(c_int, 1);
pub const __TIME64_T_TYPE = __TIME_T_TYPE;
pub const CLOCKS_PER_SEC = __helpers.cast(__clock_t, __helpers.promoteIntLiteral(c_int, 1000000, .decimal));
pub const CLOCK_REALTIME = @as(c_int, 0);
pub const CLOCK_MONOTONIC = @as(c_int, 1);
pub const CLOCK_PROCESS_CPUTIME_ID = @as(c_int, 2);
pub const CLOCK_THREAD_CPUTIME_ID = @as(c_int, 3);
pub const CLOCK_MONOTONIC_RAW = @as(c_int, 4);
pub const CLOCK_REALTIME_COARSE = @as(c_int, 5);
pub const CLOCK_MONOTONIC_COARSE = @as(c_int, 6);
pub const CLOCK_BOOTTIME = @as(c_int, 7);
pub const CLOCK_REALTIME_ALARM = @as(c_int, 8);
pub const CLOCK_BOOTTIME_ALARM = @as(c_int, 9);
pub const CLOCK_TAI = @as(c_int, 11);
pub const TIMER_ABSTIME = @as(c_int, 1);
pub const _BITS_TIMEX_H = @as(c_int, 1);
pub const __timeval_defined = @as(c_int, 1);
pub const ADJ_OFFSET = @as(c_int, 0x0001);
pub const ADJ_FREQUENCY = @as(c_int, 0x0002);
pub const ADJ_MAXERROR = @as(c_int, 0x0004);
pub const ADJ_ESTERROR = @as(c_int, 0x0008);
pub const ADJ_STATUS = @as(c_int, 0x0010);
pub const ADJ_TIMECONST = @as(c_int, 0x0020);
pub const ADJ_TAI = @as(c_int, 0x0080);
pub const ADJ_SETOFFSET = @as(c_int, 0x0100);
pub const ADJ_MICRO = @as(c_int, 0x1000);
pub const ADJ_NANO = @as(c_int, 0x2000);
pub const ADJ_TICK = @as(c_int, 0x4000);
pub const ADJ_OFFSET_SINGLESHOT = __helpers.promoteIntLiteral(c_int, 0x8001, .hex);
pub const ADJ_OFFSET_SS_READ = __helpers.promoteIntLiteral(c_int, 0xa001, .hex);
pub const MOD_OFFSET = ADJ_OFFSET;
pub const MOD_FREQUENCY = ADJ_FREQUENCY;
pub const MOD_MAXERROR = ADJ_MAXERROR;
pub const MOD_ESTERROR = ADJ_ESTERROR;
pub const MOD_STATUS = ADJ_STATUS;
pub const MOD_TIMECONST = ADJ_TIMECONST;
pub const MOD_CLKB = ADJ_TICK;
pub const MOD_CLKA = ADJ_OFFSET_SINGLESHOT;
pub const MOD_TAI = ADJ_TAI;
pub const MOD_MICRO = ADJ_MICRO;
pub const MOD_NANO = ADJ_NANO;
pub const STA_PLL = @as(c_int, 0x0001);
pub const STA_PPSFREQ = @as(c_int, 0x0002);
pub const STA_PPSTIME = @as(c_int, 0x0004);
pub const STA_FLL = @as(c_int, 0x0008);
pub const STA_INS = @as(c_int, 0x0010);
pub const STA_DEL = @as(c_int, 0x0020);
pub const STA_UNSYNC = @as(c_int, 0x0040);
pub const STA_FREQHOLD = @as(c_int, 0x0080);
pub const STA_PPSSIGNAL = @as(c_int, 0x0100);
pub const STA_PPSJITTER = @as(c_int, 0x0200);
pub const STA_PPSWANDER = @as(c_int, 0x0400);
pub const STA_PPSERROR = @as(c_int, 0x0800);
pub const STA_CLOCKERR = @as(c_int, 0x1000);
pub const STA_NANO = @as(c_int, 0x2000);
pub const STA_MODE = @as(c_int, 0x4000);
pub const STA_CLK = __helpers.promoteIntLiteral(c_int, 0x8000, .hex);
pub const STA_RONLY = ((((((STA_PPSSIGNAL | STA_PPSJITTER) | STA_PPSWANDER) | STA_PPSERROR) | STA_CLOCKERR) | STA_NANO) | STA_MODE) | STA_CLK;
pub const __clock_t_defined = @as(c_int, 1);
pub const __time_t_defined = @as(c_int, 1);
pub const __struct_tm_defined = @as(c_int, 1);
pub const _STRUCT_TIMESPEC = @as(c_int, 1);
pub const _BITS_ENDIAN_H = @as(c_int, 1);
pub const __LITTLE_ENDIAN = @as(c_int, 1234);
pub const __BIG_ENDIAN = @as(c_int, 4321);
pub const __PDP_ENDIAN = @as(c_int, 3412);
pub const _BITS_ENDIANNESS_H = @as(c_int, 1);
pub const __BYTE_ORDER = __LITTLE_ENDIAN;
pub const __FLOAT_WORD_ORDER = __BYTE_ORDER;
pub inline fn __LONG_LONG_PAIR(HI: anytype, LO: anytype) @TypeOf(HI) {
    _ = &HI;
    _ = &LO;
    return blk: {
        _ = &LO;
        break :blk HI;
    };
}
pub const __clockid_t_defined = @as(c_int, 1);
pub const __timer_t_defined = @as(c_int, 1);
pub const __itimerspec_defined = @as(c_int, 1);
pub const __pid_t_defined = "";
pub const _BITS_TYPES_LOCALE_T_H = @as(c_int, 1);
pub const _BITS_TYPES___LOCALE_T_H = @as(c_int, 1);
pub const TIME_UTC = @as(c_int, 1);
pub const TIME_MONOTONIC = @as(c_int, 2);
pub const TIME_ACTIVE = @as(c_int, 3);
pub const TIME_THREAD_ACTIVE = @as(c_int, 4);
pub inline fn __isleap(year: anytype) @TypeOf((__helpers.rem(year, @as(c_int, 4)) == @as(c_int, 0)) and ((__helpers.rem(year, @as(c_int, 100)) != @as(c_int, 0)) or (__helpers.rem(year, @as(c_int, 400)) == @as(c_int, 0)))) {
    _ = &year;
    return (__helpers.rem(year, @as(c_int, 4)) == @as(c_int, 0)) and ((__helpers.rem(year, @as(c_int, 100)) != @as(c_int, 0)) or (__helpers.rem(year, @as(c_int, 400)) == @as(c_int, 0)));
}
pub const __CLANG_STDINT_H = "";
pub const _STDINT_H = @as(c_int, 1);
pub const _BITS_WCHAR_H = @as(c_int, 1);
pub const __WCHAR_MAX = __WCHAR_MAX__;
pub const __WCHAR_MIN = '\x00' + @as(c_int, 0);
pub const __STDC_VERSION_STDINT_H__ = @as(c_long, 202311);
pub const _BITS_STDINT_INTN_H = @as(c_int, 1);
pub const _BITS_STDINT_UINTN_H = @as(c_int, 1);
pub const _BITS_STDINT_LEAST_H = @as(c_int, 1);
pub const __intptr_t_defined = "";
pub const __INT64_C = __helpers.L_SUFFIX;
pub const __UINT64_C = __helpers.UL_SUFFIX;
pub const INT8_MIN = -@as(c_int, 128);
pub const INT16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const INT32_MIN = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT64_MIN = -__INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT8_MAX = @as(c_int, 127);
pub const INT16_MAX = @as(c_int, 32767);
pub const INT32_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT64_MAX = __INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT8_MAX = @as(c_int, 255);
pub const UINT16_MAX = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT32_MAX = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT64_MAX = __UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INT_LEAST8_MIN = -@as(c_int, 128);
pub const INT_LEAST16_MIN = -@as(c_int, 32767) - @as(c_int, 1);
pub const INT_LEAST32_MIN = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const INT_LEAST64_MIN = -__INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT_LEAST8_MAX = @as(c_int, 127);
pub const INT_LEAST16_MAX = @as(c_int, 32767);
pub const INT_LEAST32_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const INT_LEAST64_MAX = __INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT_LEAST8_MAX = @as(c_int, 255);
pub const UINT_LEAST16_MAX = __helpers.promoteIntLiteral(c_int, 65535, .decimal);
pub const UINT_LEAST32_MAX = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub const UINT_LEAST64_MAX = __UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INT_FAST8_MIN = -@as(c_int, 128);
pub const INT_FAST16_MIN = -__helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INT_FAST32_MIN = -__helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INT_FAST64_MIN = -__INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INT_FAST8_MAX = @as(c_int, 127);
pub const INT_FAST16_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const INT_FAST32_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const INT_FAST64_MAX = __INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINT_FAST8_MAX = @as(c_int, 255);
pub const UINT_FAST16_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST32_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const UINT_FAST64_MAX = __UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const INTPTR_MIN = -__helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const INTPTR_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const UINTPTR_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const INTMAX_MIN = -__INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal)) - @as(c_int, 1);
pub const INTMAX_MAX = __INT64_C(__helpers.promoteIntLiteral(c_int, 9223372036854775807, .decimal));
pub const UINTMAX_MAX = __UINT64_C(__helpers.promoteIntLiteral(c_int, 18446744073709551615, .decimal));
pub const PTRDIFF_MIN = -__helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal) - @as(c_int, 1);
pub const PTRDIFF_MAX = __helpers.promoteIntLiteral(c_long, 9223372036854775807, .decimal);
pub const SIG_ATOMIC_MIN = -__helpers.promoteIntLiteral(c_int, 2147483647, .decimal) - @as(c_int, 1);
pub const SIG_ATOMIC_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const SIZE_MAX = __helpers.promoteIntLiteral(c_ulong, 18446744073709551615, .decimal);
pub const WCHAR_MIN = __WCHAR_MIN;
pub const WCHAR_MAX = __WCHAR_MAX;
pub const WINT_MIN = @as(c_uint, 0);
pub const WINT_MAX = __helpers.promoteIntLiteral(c_uint, 4294967295, .decimal);
pub inline fn INT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn INT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn INT32_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const INT64_C = __helpers.L_SUFFIX;
pub inline fn UINT8_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub inline fn UINT16_C(c: anytype) @TypeOf(c) {
    _ = &c;
    return c;
}
pub const UINT32_C = __helpers.U_SUFFIX;
pub const UINT64_C = __helpers.UL_SUFFIX;
pub const INTMAX_C = __helpers.L_SUFFIX;
pub const UINTMAX_C = __helpers.UL_SUFFIX;
pub const INT8_WIDTH = @as(c_int, 8);
pub const UINT8_WIDTH = @as(c_int, 8);
pub const INT16_WIDTH = @as(c_int, 16);
pub const UINT16_WIDTH = @as(c_int, 16);
pub const INT32_WIDTH = @as(c_int, 32);
pub const UINT32_WIDTH = @as(c_int, 32);
pub const INT64_WIDTH = @as(c_int, 64);
pub const UINT64_WIDTH = @as(c_int, 64);
pub const INT_LEAST8_WIDTH = @as(c_int, 8);
pub const UINT_LEAST8_WIDTH = @as(c_int, 8);
pub const INT_LEAST16_WIDTH = @as(c_int, 16);
pub const UINT_LEAST16_WIDTH = @as(c_int, 16);
pub const INT_LEAST32_WIDTH = @as(c_int, 32);
pub const UINT_LEAST32_WIDTH = @as(c_int, 32);
pub const INT_LEAST64_WIDTH = @as(c_int, 64);
pub const UINT_LEAST64_WIDTH = @as(c_int, 64);
pub const INT_FAST8_WIDTH = @as(c_int, 8);
pub const UINT_FAST8_WIDTH = @as(c_int, 8);
pub const INT_FAST16_WIDTH = __WORDSIZE;
pub const UINT_FAST16_WIDTH = __WORDSIZE;
pub const INT_FAST32_WIDTH = __WORDSIZE;
pub const UINT_FAST32_WIDTH = __WORDSIZE;
pub const INT_FAST64_WIDTH = @as(c_int, 64);
pub const UINT_FAST64_WIDTH = @as(c_int, 64);
pub const INTPTR_WIDTH = __WORDSIZE;
pub const UINTPTR_WIDTH = __WORDSIZE;
pub const INTMAX_WIDTH = @as(c_int, 64);
pub const UINTMAX_WIDTH = @as(c_int, 64);
pub const PTRDIFF_WIDTH = __WORDSIZE;
pub const SIG_ATOMIC_WIDTH = @as(c_int, 32);
pub const SIZE_WIDTH = __WORDSIZE;
pub const WCHAR_WIDTH = @as(c_int, 32);
pub const WINT_WIDTH = @as(c_int, 32);
pub const _STDIO_H = @as(c_int, 1);
pub const __STDC_VERSION_STDIO_H__ = @as(c_long, 202311);
pub const __need___va_list = "";
pub const __STDC_VERSION_STDARG_H__ = @as(c_int, 0);
pub const va_start = @compileError("unable to translate macro: undefined identifier `__builtin_va_start`");
// /home/g/.local/share/ghr/tools/_v2/units/u-cataggar/u-zig/_unit/zig-aarch64-linux-0.17.0/lib/compiler/aro/include/stdarg.h:12:9
pub const va_end = @compileError("unable to translate macro: undefined identifier `__builtin_va_end`");
// /home/g/.local/share/ghr/tools/_v2/units/u-cataggar/u-zig/_unit/zig-aarch64-linux-0.17.0/lib/compiler/aro/include/stdarg.h:14:9
pub const va_arg = @compileError("unable to translate macro: undefined identifier `__builtin_va_arg`");
// /home/g/.local/share/ghr/tools/_v2/units/u-cataggar/u-zig/_unit/zig-aarch64-linux-0.17.0/lib/compiler/aro/include/stdarg.h:15:9
pub const __va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`");
// /home/g/.local/share/ghr/tools/_v2/units/u-cataggar/u-zig/_unit/zig-aarch64-linux-0.17.0/lib/compiler/aro/include/stdarg.h:18:9
pub const va_copy = @compileError("unable to translate macro: undefined identifier `__builtin_va_copy`");
// /home/g/.local/share/ghr/tools/_v2/units/u-cataggar/u-zig/_unit/zig-aarch64-linux-0.17.0/lib/compiler/aro/include/stdarg.h:22:9
pub const __GNUC_VA_LIST = @as(c_int, 1);
pub const _____fpos_t_defined = @as(c_int, 1);
pub const ____mbstate_t_defined = @as(c_int, 1);
pub const _____fpos64_t_defined = @as(c_int, 1);
pub const ____FILE_defined = @as(c_int, 1);
pub const __FILE_defined = @as(c_int, 1);
pub const __struct_FILE_defined = @as(c_int, 1);
pub const __getc_unlocked_body = @compileError("TODO postfix inc/dec expr");
// /usr/include/aarch64-linux-gnu/bits/types/struct_FILE.h:113:9
pub const __putc_unlocked_body = @compileError("TODO postfix inc/dec expr");
// /usr/include/aarch64-linux-gnu/bits/types/struct_FILE.h:117:9
pub const _IO_EOF_SEEN = @as(c_int, 0x0010);
pub inline fn __feof_unlocked_body(_fp: anytype) @TypeOf((_fp.*._flags & _IO_EOF_SEEN) != @as(c_int, 0)) {
    _ = &_fp;
    return (_fp.*._flags & _IO_EOF_SEEN) != @as(c_int, 0);
}
pub const _IO_ERR_SEEN = @as(c_int, 0x0020);
pub inline fn __ferror_unlocked_body(_fp: anytype) @TypeOf((_fp.*._flags & _IO_ERR_SEEN) != @as(c_int, 0)) {
    _ = &_fp;
    return (_fp.*._flags & _IO_ERR_SEEN) != @as(c_int, 0);
}
pub const _IO_USER_LOCK = __helpers.promoteIntLiteral(c_int, 0x8000, .hex);
pub const __cookie_io_functions_t_defined = @as(c_int, 1);
pub const _VA_LIST_DEFINED = "";
pub const __off_t_defined = "";
pub const __off64_t_defined = "";
pub const __ssize_t_defined = "";
pub const _IOFBF = @as(c_int, 0);
pub const _IOLBF = @as(c_int, 1);
pub const _IONBF = @as(c_int, 2);
pub const BUFSIZ = @as(c_int, 8192);
pub const EOF = -@as(c_int, 1);
pub const SEEK_SET = @as(c_int, 0);
pub const SEEK_CUR = @as(c_int, 1);
pub const SEEK_END = @as(c_int, 2);
pub const SEEK_DATA = @as(c_int, 3);
pub const SEEK_HOLE = @as(c_int, 4);
pub const P_tmpdir = "/tmp";
pub const L_tmpnam = @as(c_int, 20);
pub const TMP_MAX = __helpers.promoteIntLiteral(c_int, 238328, .decimal);
pub const _BITS_STDIO_LIM_H = @as(c_int, 1);
pub const FILENAME_MAX = @as(c_int, 4096);
pub const L_ctermid = @as(c_int, 9);
pub const L_cuserid = @as(c_int, 9);
pub const FOPEN_MAX = @as(c_int, 16);
pub const _PRINTF_NAN_LEN_MAX = @as(c_int, 4);
pub const RENAME_NOREPLACE = @as(c_int, 1) << @as(c_int, 0);
pub const AT_RENAME_NOREPLACE = @as(c_int, 0x0001);
pub const RENAME_EXCHANGE = @as(c_int, 1) << @as(c_int, 1);
pub const AT_RENAME_EXCHANGE = @as(c_int, 0x0002);
pub const RENAME_WHITEOUT = @as(c_int, 1) << @as(c_int, 2);
pub const AT_RENAME_WHITEOUT = @as(c_int, 0x0004);
pub const __attr_dealloc_fclose = __attr_dealloc(fclose, @as(c_int, 1));
pub const _BITS_FLOATN_H = "";
pub const __HAVE_FLOAT128 = @as(c_int, 1);
pub const __HAVE_DISTINCT_FLOAT128 = @as(c_int, 0);
pub const __HAVE_FLOAT64X = __HAVE_FLOAT128;
pub const __HAVE_FLOAT64X_LONG_DOUBLE = __HAVE_FLOAT128;
pub const __f128 = @compileError("unable to translate macro: undefined identifier `f128`");
// /usr/include/aarch64-linux-gnu/bits/floatn.h:62:12
pub const __CFLOAT128 = @compileError("unable to translate: invalid numeric type");
// /usr/include/aarch64-linux-gnu/bits/floatn.h:71:12
pub const _BITS_FLOATN_COMMON_H = "";
pub const __HAVE_FLOAT16 = @as(c_int, 0);
pub const __HAVE_FLOAT32 = @as(c_int, 1);
pub const __HAVE_FLOAT64 = @as(c_int, 1);
pub const __HAVE_FLOAT32X = @as(c_int, 1);
pub const __HAVE_FLOAT128X = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT16 = __HAVE_FLOAT16;
pub const __HAVE_DISTINCT_FLOAT32 = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT64 = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT32X = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT64X = @as(c_int, 0);
pub const __HAVE_DISTINCT_FLOAT128X = __HAVE_FLOAT128X;
pub const __HAVE_FLOAT128_UNLIKE_LDBL = (__HAVE_DISTINCT_FLOAT128 != 0) and (__LDBL_MANT_DIG__ != @as(c_int, 113));
pub const __HAVE_FLOATN_NOT_TYPEDEF = @as(c_int, 1);
pub const __f32 = @compileError("unable to translate macro: undefined identifier `f32`");
// /usr/include/aarch64-linux-gnu/bits/floatn-common.h:93:12
pub const __f64 = @compileError("unable to translate macro: undefined identifier `f64`");
// /usr/include/aarch64-linux-gnu/bits/floatn-common.h:105:12
pub const __f32x = @compileError("unable to translate macro: undefined identifier `f32x`");
// /usr/include/aarch64-linux-gnu/bits/floatn-common.h:113:12
pub const __f64x = @compileError("unable to translate macro: undefined identifier `f64x`");
// /usr/include/aarch64-linux-gnu/bits/floatn-common.h:125:12
pub const __CFLOAT32 = @compileError("unable to translate: invalid numeric type");
// /usr/include/aarch64-linux-gnu/bits/floatn-common.h:151:12
pub const __CFLOAT64 = @compileError("unable to translate: invalid numeric type");
// /usr/include/aarch64-linux-gnu/bits/floatn-common.h:163:12
pub const __CFLOAT32X = @compileError("unable to translate: invalid numeric type");
// /usr/include/aarch64-linux-gnu/bits/floatn-common.h:171:12
pub const __CFLOAT64X = @compileError("unable to translate: invalid numeric type");
// /usr/include/aarch64-linux-gnu/bits/floatn-common.h:183:12
pub const __need_wchar_t = "";
pub const _STDLIB_H = @as(c_int, 1);
pub const __STDC_VERSION_STDLIB_H__ = @as(c_long, 202311);
pub const WNOHANG = @as(c_int, 1);
pub const WUNTRACED = @as(c_int, 2);
pub const WSTOPPED = @as(c_int, 2);
pub const WEXITED = @as(c_int, 4);
pub const WCONTINUED = @as(c_int, 8);
pub const WNOWAIT = __helpers.promoteIntLiteral(c_int, 0x01000000, .hex);
pub const __WNOTHREAD = __helpers.promoteIntLiteral(c_int, 0x20000000, .hex);
pub const __WALL = __helpers.promoteIntLiteral(c_int, 0x40000000, .hex);
pub const __WCLONE = __helpers.promoteIntLiteral(c_int, 0x80000000, .hex);
pub inline fn __WEXITSTATUS(status: anytype) @TypeOf((status & __helpers.promoteIntLiteral(c_int, 0xff00, .hex)) >> @as(c_int, 8)) {
    _ = &status;
    return (status & __helpers.promoteIntLiteral(c_int, 0xff00, .hex)) >> @as(c_int, 8);
}
pub inline fn __WTERMSIG(status: anytype) @TypeOf(status & @as(c_int, 0x7f)) {
    _ = &status;
    return status & @as(c_int, 0x7f);
}
pub inline fn __WSTOPSIG(status: anytype) @TypeOf(__WEXITSTATUS(status)) {
    _ = &status;
    return __WEXITSTATUS(status);
}
pub inline fn __WIFEXITED(status: anytype) @TypeOf(__WTERMSIG(status) == @as(c_int, 0)) {
    _ = &status;
    return __WTERMSIG(status) == @as(c_int, 0);
}
pub inline fn __WIFSIGNALED(status: anytype) @TypeOf((__helpers.cast(i8, (status & @as(c_int, 0x7f)) + @as(c_int, 1)) >> @as(c_int, 1)) > @as(c_int, 0)) {
    _ = &status;
    return (__helpers.cast(i8, (status & @as(c_int, 0x7f)) + @as(c_int, 1)) >> @as(c_int, 1)) > @as(c_int, 0);
}
pub inline fn __WIFSTOPPED(status: anytype) @TypeOf((status & @as(c_int, 0xff)) == @as(c_int, 0x7f)) {
    _ = &status;
    return (status & @as(c_int, 0xff)) == @as(c_int, 0x7f);
}
pub inline fn __WIFCONTINUED(status: anytype) @TypeOf(status == __W_CONTINUED) {
    _ = &status;
    return status == __W_CONTINUED;
}
pub inline fn __WCOREDUMP(status: anytype) @TypeOf(status & __WCOREFLAG) {
    _ = &status;
    return status & __WCOREFLAG;
}
pub inline fn __W_EXITCODE(ret: anytype, sig: anytype) @TypeOf((ret << @as(c_int, 8)) | sig) {
    _ = &ret;
    _ = &sig;
    return (ret << @as(c_int, 8)) | sig;
}
pub inline fn __W_STOPCODE(sig: anytype) @TypeOf((sig << @as(c_int, 8)) | @as(c_int, 0x7f)) {
    _ = &sig;
    return (sig << @as(c_int, 8)) | @as(c_int, 0x7f);
}
pub const __W_CONTINUED = __helpers.promoteIntLiteral(c_int, 0xffff, .hex);
pub const __WCOREFLAG = @as(c_int, 0x80);
pub inline fn WEXITSTATUS(status: anytype) @TypeOf(__WEXITSTATUS(status)) {
    _ = &status;
    return __WEXITSTATUS(status);
}
pub inline fn WTERMSIG(status: anytype) @TypeOf(__WTERMSIG(status)) {
    _ = &status;
    return __WTERMSIG(status);
}
pub inline fn WSTOPSIG(status: anytype) @TypeOf(__WSTOPSIG(status)) {
    _ = &status;
    return __WSTOPSIG(status);
}
pub inline fn WIFEXITED(status: anytype) @TypeOf(__WIFEXITED(status)) {
    _ = &status;
    return __WIFEXITED(status);
}
pub inline fn WIFSIGNALED(status: anytype) @TypeOf(__WIFSIGNALED(status)) {
    _ = &status;
    return __WIFSIGNALED(status);
}
pub inline fn WIFSTOPPED(status: anytype) @TypeOf(__WIFSTOPPED(status)) {
    _ = &status;
    return __WIFSTOPPED(status);
}
pub inline fn WIFCONTINUED(status: anytype) @TypeOf(__WIFCONTINUED(status)) {
    _ = &status;
    return __WIFCONTINUED(status);
}
pub const __ldiv_t_defined = @as(c_int, 1);
pub const __lldiv_t_defined = @as(c_int, 1);
pub const RAND_MAX = __helpers.promoteIntLiteral(c_int, 2147483647, .decimal);
pub const EXIT_FAILURE = @as(c_int, 1);
pub const EXIT_SUCCESS = @as(c_int, 0);
pub const MB_CUR_MAX = __ctype_get_mb_cur_max();
pub const _SYS_TYPES_H = @as(c_int, 1);
pub const __u_char_defined = "";
pub const __ino_t_defined = "";
pub const __ino64_t_defined = "";
pub const __dev_t_defined = "";
pub const __gid_t_defined = "";
pub const __mode_t_defined = "";
pub const __nlink_t_defined = "";
pub const __uid_t_defined = "";
pub const __id_t_defined = "";
pub const __daddr_t_defined = "";
pub const __key_t_defined = "";
pub const __useconds_t_defined = "";
pub const __suseconds_t_defined = "";
pub const __BIT_TYPES_DEFINED__ = @as(c_int, 1);
pub const _ENDIAN_H = @as(c_int, 1);
pub const LITTLE_ENDIAN = __LITTLE_ENDIAN;
pub const BIG_ENDIAN = __BIG_ENDIAN;
pub const PDP_ENDIAN = __PDP_ENDIAN;
pub const BYTE_ORDER = __BYTE_ORDER;
pub const _BITS_BYTESWAP_H = @as(c_int, 1);
pub inline fn __bswap_constant_16(x: anytype) __uint16_t {
    _ = &x;
    return __helpers.cast(__uint16_t, ((x >> @as(c_int, 8)) & @as(c_int, 0xff)) | ((x & @as(c_int, 0xff)) << @as(c_int, 8)));
}
pub inline fn __bswap_constant_32(x: anytype) @TypeOf(((((x & __helpers.promoteIntLiteral(c_uint, 0xff000000, .hex)) >> @as(c_int, 24)) | ((x & __helpers.promoteIntLiteral(c_uint, 0x00ff0000, .hex)) >> @as(c_int, 8))) | ((x & @as(c_uint, 0x0000ff00)) << @as(c_int, 8))) | ((x & @as(c_uint, 0x000000ff)) << @as(c_int, 24))) {
    _ = &x;
    return ((((x & __helpers.promoteIntLiteral(c_uint, 0xff000000, .hex)) >> @as(c_int, 24)) | ((x & __helpers.promoteIntLiteral(c_uint, 0x00ff0000, .hex)) >> @as(c_int, 8))) | ((x & @as(c_uint, 0x0000ff00)) << @as(c_int, 8))) | ((x & @as(c_uint, 0x000000ff)) << @as(c_int, 24));
}
pub inline fn __bswap_constant_64(x: anytype) @TypeOf(((((((((x & @as(c_ulonglong, 0xff00000000000000)) >> @as(c_int, 56)) | ((x & @as(c_ulonglong, 0x00ff000000000000)) >> @as(c_int, 40))) | ((x & @as(c_ulonglong, 0x0000ff0000000000)) >> @as(c_int, 24))) | ((x & @as(c_ulonglong, 0x000000ff00000000)) >> @as(c_int, 8))) | ((x & @as(c_ulonglong, 0x00000000ff000000)) << @as(c_int, 8))) | ((x & @as(c_ulonglong, 0x0000000000ff0000)) << @as(c_int, 24))) | ((x & @as(c_ulonglong, 0x000000000000ff00)) << @as(c_int, 40))) | ((x & @as(c_ulonglong, 0x00000000000000ff)) << @as(c_int, 56))) {
    _ = &x;
    return ((((((((x & @as(c_ulonglong, 0xff00000000000000)) >> @as(c_int, 56)) | ((x & @as(c_ulonglong, 0x00ff000000000000)) >> @as(c_int, 40))) | ((x & @as(c_ulonglong, 0x0000ff0000000000)) >> @as(c_int, 24))) | ((x & @as(c_ulonglong, 0x000000ff00000000)) >> @as(c_int, 8))) | ((x & @as(c_ulonglong, 0x00000000ff000000)) << @as(c_int, 8))) | ((x & @as(c_ulonglong, 0x0000000000ff0000)) << @as(c_int, 24))) | ((x & @as(c_ulonglong, 0x000000000000ff00)) << @as(c_int, 40))) | ((x & @as(c_ulonglong, 0x00000000000000ff)) << @as(c_int, 56));
}
pub const _BITS_UINTN_IDENTITY_H = @as(c_int, 1);
pub inline fn htobe16(x: anytype) @TypeOf(__bswap_16(x)) {
    _ = &x;
    return __bswap_16(x);
}
pub inline fn htole16(x: anytype) @TypeOf(__uint16_identity(x)) {
    _ = &x;
    return __uint16_identity(x);
}
pub inline fn be16toh(x: anytype) @TypeOf(__bswap_16(x)) {
    _ = &x;
    return __bswap_16(x);
}
pub inline fn le16toh(x: anytype) @TypeOf(__uint16_identity(x)) {
    _ = &x;
    return __uint16_identity(x);
}
pub inline fn htobe32(x: anytype) @TypeOf(__bswap_32(x)) {
    _ = &x;
    return __bswap_32(x);
}
pub inline fn htole32(x: anytype) @TypeOf(__uint32_identity(x)) {
    _ = &x;
    return __uint32_identity(x);
}
pub inline fn be32toh(x: anytype) @TypeOf(__bswap_32(x)) {
    _ = &x;
    return __bswap_32(x);
}
pub inline fn le32toh(x: anytype) @TypeOf(__uint32_identity(x)) {
    _ = &x;
    return __uint32_identity(x);
}
pub inline fn htobe64(x: anytype) @TypeOf(__bswap_64(x)) {
    _ = &x;
    return __bswap_64(x);
}
pub inline fn htole64(x: anytype) @TypeOf(__uint64_identity(x)) {
    _ = &x;
    return __uint64_identity(x);
}
pub inline fn be64toh(x: anytype) @TypeOf(__bswap_64(x)) {
    _ = &x;
    return __bswap_64(x);
}
pub inline fn le64toh(x: anytype) @TypeOf(__uint64_identity(x)) {
    _ = &x;
    return __uint64_identity(x);
}
pub const _SYS_SELECT_H = @as(c_int, 1);
pub const __FD_ZERO = @compileError("unable to translate macro: undefined identifier `__i`");
// /usr/include/aarch64-linux-gnu/bits/select.h:25:9
pub const __FD_SET = @compileError("unable to translate C expr: expected ')' instead got '|='");
// /usr/include/aarch64-linux-gnu/bits/select.h:32:9
pub const __FD_CLR = @compileError("unable to translate C expr: expected ')' instead got '&='");
// /usr/include/aarch64-linux-gnu/bits/select.h:34:9
pub inline fn __FD_ISSET(d: anytype, s: anytype) @TypeOf((__FDS_BITS(s)[@as(usize, @intCast(__FD_ELT(d)))] & __FD_MASK(d)) != @as(c_int, 0)) {
    _ = &d;
    _ = &s;
    return (__FDS_BITS(s)[@as(usize, @intCast(__FD_ELT(d)))] & __FD_MASK(d)) != @as(c_int, 0);
}
pub const __sigset_t_defined = @as(c_int, 1);
pub const ____sigset_t_defined = "";
pub const _SIGSET_NWORDS = __helpers.div(@as(c_int, 1024), @as(c_int, 8) * __helpers.sizeof(c_ulong));
pub const __NFDBITS = @as(c_int, 8) * __helpers.cast(c_int, __helpers.sizeof(__fd_mask));
pub inline fn __FD_ELT(d: anytype) @TypeOf(__helpers.div(d, __NFDBITS)) {
    _ = &d;
    return __helpers.div(d, __NFDBITS);
}
pub inline fn __FD_MASK(d: anytype) __fd_mask {
    _ = &d;
    return __helpers.cast(__fd_mask, @as(c_ulong, 1) << __helpers.rem(d, __NFDBITS));
}
pub inline fn __FDS_BITS(set: anytype) @TypeOf(set.*.fds_bits) {
    _ = &set;
    return set.*.fds_bits;
}
pub const FD_SETSIZE = __FD_SETSIZE;
pub const NFDBITS = __NFDBITS;
pub inline fn FD_SET(fd: anytype, fdsetp: anytype) @TypeOf(__FD_SET(fd, fdsetp)) {
    _ = &fd;
    _ = &fdsetp;
    return __FD_SET(fd, fdsetp);
}
pub inline fn FD_CLR(fd: anytype, fdsetp: anytype) @TypeOf(__FD_CLR(fd, fdsetp)) {
    _ = &fd;
    _ = &fdsetp;
    return __FD_CLR(fd, fdsetp);
}
pub inline fn FD_ISSET(fd: anytype, fdsetp: anytype) @TypeOf(__FD_ISSET(fd, fdsetp)) {
    _ = &fd;
    _ = &fdsetp;
    return __FD_ISSET(fd, fdsetp);
}
pub inline fn FD_ZERO(fdsetp: anytype) @TypeOf(__FD_ZERO(fdsetp)) {
    _ = &fdsetp;
    return __FD_ZERO(fdsetp);
}
pub const __blksize_t_defined = "";
pub const __blkcnt_t_defined = "";
pub const __fsblkcnt_t_defined = "";
pub const __fsfilcnt_t_defined = "";
pub const _BITS_PTHREADTYPES_COMMON_H = @as(c_int, 1);
pub const _THREAD_SHARED_TYPES_H = @as(c_int, 1);
pub const _BITS_PTHREADTYPES_ARCH_H = @as(c_int, 1);
pub const __SIZEOF_PTHREAD_ATTR_T = @as(c_int, 64);
pub const __SIZEOF_PTHREAD_MUTEX_T = @as(c_int, 48);
pub const __SIZEOF_PTHREAD_MUTEXATTR_T = @as(c_int, 8);
pub const __SIZEOF_PTHREAD_CONDATTR_T = @as(c_int, 8);
pub const __SIZEOF_PTHREAD_RWLOCK_T = @as(c_int, 56);
pub const __SIZEOF_PTHREAD_BARRIER_T = @as(c_int, 32);
pub const __SIZEOF_PTHREAD_BARRIERATTR_T = @as(c_int, 8);
pub const __SIZEOF_PTHREAD_COND_T = @as(c_int, 48);
pub const __SIZEOF_PTHREAD_RWLOCKATTR_T = @as(c_int, 8);
pub const __LOCK_ALIGNMENT = "";
pub const __ONCE_ALIGNMENT = "";
pub const _BITS_ATOMIC_WIDE_COUNTER_H = "";
pub const _THREAD_MUTEX_INTERNAL_H = @as(c_int, 1);
pub const __PTHREAD_MUTEX_HAVE_PREV = @as(c_int, 1);
pub const __PTHREAD_MUTEX_INITIALIZER = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/aarch64-linux-gnu/bits/struct_mutex.h:63:10
pub const _RWLOCK_INTERNAL_H = "";
pub inline fn __PTHREAD_RWLOCK_INITIALIZER(__flags: anytype) @TypeOf(__flags) {
    _ = &__flags;
    return blk: {
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        _ = @as(c_int, 0);
        break :blk __flags;
    };
}
pub const __ONCE_FLAG_INIT = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/aarch64-linux-gnu/bits/thread-shared-types.h:114:9
pub const __have_pthread_attr_t = @as(c_int, 1);
pub const _ALLOCA_H = @as(c_int, 1);
pub const __COMPAR_FN_T = "";
pub const __once_flag_defined = @as(c_int, 1);
pub const ONCE_FLAG_INIT = __ONCE_FLAG_INIT;
pub const _STRING_H = @as(c_int, 1);
pub const __GLIBC_USE_LIB_EXT2 = @as(c_int, 1);
pub const __GLIBC_USE_IEC_60559_BFP_EXT = @as(c_int, 1);
pub const __GLIBC_USE_IEC_60559_BFP_EXT_C23 = @as(c_int, 1);
pub const __GLIBC_USE_IEC_60559_EXT = @as(c_int, 1);
pub const __GLIBC_USE_IEC_60559_FUNCS_EXT = @as(c_int, 1);
pub const __GLIBC_USE_IEC_60559_FUNCS_EXT_C23 = @as(c_int, 1);
pub const __GLIBC_USE_IEC_60559_TYPES_EXT = @as(c_int, 1);
pub const __STDC_VERSION_STRING_H__ = @as(c_long, 202311);
pub const strdupa = @compileError("unable to translate macro: undefined identifier `__old`");
// /usr/include/string.h:216:10
pub const strndupa = @compileError("unable to translate macro: undefined identifier `__old`");
// /usr/include/string.h:226:10
pub const _STRINGS_H = @as(c_int, 1);
pub const _ERRNO_H = @as(c_int, 1);
pub const _BITS_ERRNO_H = @as(c_int, 1);
pub const _ASM_GENERIC_ERRNO_H = "";
pub const _ASM_GENERIC_ERRNO_BASE_H = "";
pub const EPERM = @as(c_int, 1);
pub const ENOENT = @as(c_int, 2);
pub const ESRCH = @as(c_int, 3);
pub const EINTR = @as(c_int, 4);
pub const EIO = @as(c_int, 5);
pub const ENXIO = @as(c_int, 6);
pub const E2BIG = @as(c_int, 7);
pub const ENOEXEC = @as(c_int, 8);
pub const EBADF = @as(c_int, 9);
pub const ECHILD = @as(c_int, 10);
pub const EAGAIN: c_int = switch (@import("builtin").os.tag) {
    .macos, .ios, .tvos, .watchos, .visionos, .freebsd, .netbsd, .openbsd, .dragonfly => 35,
    else => 11,
};
pub const ENOMEM = @as(c_int, 12);
pub const EACCES = @as(c_int, 13);
pub const EFAULT = @as(c_int, 14);
pub const ENOTBLK = @as(c_int, 15);
pub const EBUSY = @as(c_int, 16);
pub const EEXIST = @as(c_int, 17);
pub const EXDEV = @as(c_int, 18);
pub const ENODEV = @as(c_int, 19);
pub const ENOTDIR = @as(c_int, 20);
pub const EISDIR = @as(c_int, 21);
pub const EINVAL = @as(c_int, 22);
pub const ENFILE = @as(c_int, 23);
pub const EMFILE = @as(c_int, 24);
pub const ENOTTY = @as(c_int, 25);
pub const ETXTBSY = @as(c_int, 26);
pub const EFBIG = @as(c_int, 27);
pub const ENOSPC = @as(c_int, 28);
pub const ESPIPE = @as(c_int, 29);
pub const EROFS = @as(c_int, 30);
pub const EMLINK = @as(c_int, 31);
pub const EPIPE = @as(c_int, 32);
pub const EDOM = @as(c_int, 33);
pub const ERANGE = @as(c_int, 34);
pub const EDEADLK = @as(c_int, 35);
pub const ENAMETOOLONG = @as(c_int, 36);
pub const ENOLCK = @as(c_int, 37);
pub const ENOSYS = @as(c_int, 38);
pub const ENOTEMPTY = @as(c_int, 39);
pub const ELOOP = @as(c_int, 40);
pub const EWOULDBLOCK = EAGAIN;
pub const ENOMSG = @as(c_int, 42);
pub const EIDRM = @as(c_int, 43);
pub const ECHRNG = @as(c_int, 44);
pub const EL2NSYNC = @as(c_int, 45);
pub const EL3HLT = @as(c_int, 46);
pub const EL3RST = @as(c_int, 47);
pub const ELNRNG = @as(c_int, 48);
pub const EUNATCH = @as(c_int, 49);
pub const ENOCSI = @as(c_int, 50);
pub const EL2HLT = @as(c_int, 51);
pub const EBADE = @as(c_int, 52);
pub const EBADR = @as(c_int, 53);
pub const EXFULL = @as(c_int, 54);
pub const ENOANO = @as(c_int, 55);
pub const EBADRQC = @as(c_int, 56);
pub const EBADSLT = @as(c_int, 57);
pub const EDEADLOCK = EDEADLK;
pub const EBFONT = @as(c_int, 59);
pub const ENOSTR = @as(c_int, 60);
pub const ENODATA = @as(c_int, 61);
pub const ETIME = @as(c_int, 62);
pub const ENOSR = @as(c_int, 63);
pub const ENONET = @as(c_int, 64);
pub const ENOPKG = @as(c_int, 65);
pub const EREMOTE = @as(c_int, 66);
pub const ENOLINK = @as(c_int, 67);
pub const EADV = @as(c_int, 68);
pub const ESRMNT = @as(c_int, 69);
pub const ECOMM = @as(c_int, 70);
pub const EPROTO = @as(c_int, 71);
pub const EMULTIHOP = @as(c_int, 72);
pub const EDOTDOT = @as(c_int, 73);
pub const EBADMSG = @as(c_int, 74);
pub const EFSBADCRC = EBADMSG;
pub const EOVERFLOW = @as(c_int, 75);
pub const ENOTUNIQ = @as(c_int, 76);
pub const EBADFD = @as(c_int, 77);
pub const EREMCHG = @as(c_int, 78);
pub const ELIBACC = @as(c_int, 79);
pub const ELIBBAD = @as(c_int, 80);
pub const ELIBSCN = @as(c_int, 81);
pub const ELIBMAX = @as(c_int, 82);
pub const ELIBEXEC = @as(c_int, 83);
pub const EILSEQ = @as(c_int, 84);
pub const ERESTART = @as(c_int, 85);
pub const ESTRPIPE = @as(c_int, 86);
pub const EUSERS = @as(c_int, 87);
pub const ENOTSOCK = @as(c_int, 88);
pub const EDESTADDRREQ = @as(c_int, 89);
pub const EMSGSIZE = @as(c_int, 90);
pub const EPROTOTYPE = @as(c_int, 91);
pub const ENOPROTOOPT = @as(c_int, 92);
pub const EPROTONOSUPPORT = @as(c_int, 93);
pub const ESOCKTNOSUPPORT = @as(c_int, 94);
pub const EOPNOTSUPP = @as(c_int, 95);
pub const EPFNOSUPPORT = @as(c_int, 96);
pub const EAFNOSUPPORT = @as(c_int, 97);
pub const EADDRINUSE = @as(c_int, 98);
pub const EADDRNOTAVAIL = @as(c_int, 99);
pub const ENETDOWN = @as(c_int, 100);
pub const ENETUNREACH = @as(c_int, 101);
pub const ENETRESET = @as(c_int, 102);
pub const ECONNABORTED = @as(c_int, 103);
pub const ECONNRESET = @as(c_int, 104);
pub const ENOBUFS = @as(c_int, 105);
pub const EISCONN = @as(c_int, 106);
pub const ENOTCONN = @as(c_int, 107);
pub const ESHUTDOWN = @as(c_int, 108);
pub const ETOOMANYREFS = @as(c_int, 109);
pub const ETIMEDOUT = @as(c_int, 110);
pub const ECONNREFUSED = @as(c_int, 111);
pub const EHOSTDOWN = @as(c_int, 112);
pub const EHOSTUNREACH = @as(c_int, 113);
pub const EALREADY = @as(c_int, 114);
pub const EINPROGRESS = @as(c_int, 115);
pub const ESTALE = @as(c_int, 116);
pub const EUCLEAN = @as(c_int, 117);
pub const EFSCORRUPTED = EUCLEAN;
pub const ENOTNAM = @as(c_int, 118);
pub const ENAVAIL = @as(c_int, 119);
pub const EISNAM = @as(c_int, 120);
pub const EREMOTEIO = @as(c_int, 121);
pub const EDQUOT = @as(c_int, 122);
pub const ENOMEDIUM = @as(c_int, 123);
pub const EMEDIUMTYPE = @as(c_int, 124);
pub const ECANCELED = @as(c_int, 125);
pub const ENOKEY = @as(c_int, 126);
pub const EKEYEXPIRED = @as(c_int, 127);
pub const EKEYREVOKED = @as(c_int, 128);
pub const EKEYREJECTED = @as(c_int, 129);
pub const EOWNERDEAD = @as(c_int, 130);
pub const ENOTRECOVERABLE = @as(c_int, 131);
pub const ERFKILL = @as(c_int, 132);
pub const EHWPOISON = @as(c_int, 133);
pub const ENOTSUP = EOPNOTSUPP;
pub const __error_t_defined = @as(c_int, 1);
pub const _SYS_STAT_H = @as(c_int, 1);
pub const _BITS_STAT_H = @as(c_int, 1);
pub const _BITS_STRUCT_STAT_H = @as(c_int, 1);
pub const st_atime = @compileError("unable to translate macro: undefined identifier `st_atim`");
// /usr/include/aarch64-linux-gnu/bits/struct_stat.h:68:10
pub const st_mtime = @compileError("unable to translate macro: undefined identifier `st_mtim`");
// /usr/include/aarch64-linux-gnu/bits/struct_stat.h:69:10
pub const st_ctime = @compileError("unable to translate macro: undefined identifier `st_ctim`");
// /usr/include/aarch64-linux-gnu/bits/struct_stat.h:70:10
pub const _STATBUF_ST_BLKSIZE = "";
pub const _STATBUF_ST_RDEV = "";
pub const _STATBUF_ST_NSEC = "";
pub const __S_IFMT = __helpers.promoteIntLiteral(c_int, 0o170000, .octal);
pub const __S_IFDIR = @as(c_int, 0o040000);
pub const __S_IFCHR = @as(c_int, 0o020000);
pub const __S_IFBLK = @as(c_int, 0o060000);
pub const __S_IFREG = __helpers.promoteIntLiteral(c_int, 0o100000, .octal);
pub const __S_IFIFO = @as(c_int, 0o010000);
pub const __S_IFLNK = __helpers.promoteIntLiteral(c_int, 0o120000, .octal);
pub const __S_IFSOCK = __helpers.promoteIntLiteral(c_int, 0o140000, .octal);
pub inline fn __S_TYPEISMQ(buf: anytype) @TypeOf(buf.*.st_mode - buf.*.st_mode) {
    _ = &buf;
    return buf.*.st_mode - buf.*.st_mode;
}
pub inline fn __S_TYPEISSEM(buf: anytype) @TypeOf(buf.*.st_mode - buf.*.st_mode) {
    _ = &buf;
    return buf.*.st_mode - buf.*.st_mode;
}
pub inline fn __S_TYPEISSHM(buf: anytype) @TypeOf(buf.*.st_mode - buf.*.st_mode) {
    _ = &buf;
    return buf.*.st_mode - buf.*.st_mode;
}
pub const __S_ISUID = @as(c_int, 0o4000);
pub const __S_ISGID = @as(c_int, 0o2000);
pub const __S_ISVTX = @as(c_int, 0o1000);
pub const __S_IREAD = @as(c_int, 0o400);
pub const __S_IWRITE = @as(c_int, 0o200);
pub const __S_IEXEC = @as(c_int, 0o100);
pub const UTIME_NOW = (@as(c_long, 1) << @as(c_int, 30)) - @as(c_long, 1);
pub const UTIME_OMIT = (@as(c_long, 1) << @as(c_int, 30)) - @as(c_long, 2);
pub const S_IFMT = __S_IFMT;
pub const S_IFDIR = __S_IFDIR;
pub const S_IFCHR = __S_IFCHR;
pub const S_IFBLK = __S_IFBLK;
pub const S_IFREG = __S_IFREG;
pub const S_IFIFO = __S_IFIFO;
pub const S_IFLNK = __S_IFLNK;
pub const S_IFSOCK = __S_IFSOCK;
pub inline fn __S_ISTYPE(mode: anytype, mask: anytype) @TypeOf((mode & __S_IFMT) == mask) {
    _ = &mode;
    _ = &mask;
    return (mode & __S_IFMT) == mask;
}
pub inline fn S_ISDIR(mode: anytype) @TypeOf(__S_ISTYPE(mode, __S_IFDIR)) {
    _ = &mode;
    return __S_ISTYPE(mode, __S_IFDIR);
}
pub inline fn S_ISCHR(mode: anytype) @TypeOf(__S_ISTYPE(mode, __S_IFCHR)) {
    _ = &mode;
    return __S_ISTYPE(mode, __S_IFCHR);
}
pub inline fn S_ISBLK(mode: anytype) @TypeOf(__S_ISTYPE(mode, __S_IFBLK)) {
    _ = &mode;
    return __S_ISTYPE(mode, __S_IFBLK);
}
pub inline fn S_ISREG(mode: anytype) @TypeOf(__S_ISTYPE(mode, __S_IFREG)) {
    _ = &mode;
    return __S_ISTYPE(mode, __S_IFREG);
}
pub inline fn S_ISFIFO(mode: anytype) @TypeOf(__S_ISTYPE(mode, __S_IFIFO)) {
    _ = &mode;
    return __S_ISTYPE(mode, __S_IFIFO);
}
pub inline fn S_ISLNK(mode: anytype) @TypeOf(__S_ISTYPE(mode, __S_IFLNK)) {
    _ = &mode;
    return __S_ISTYPE(mode, __S_IFLNK);
}
pub inline fn S_ISSOCK(mode: anytype) @TypeOf(__S_ISTYPE(mode, __S_IFSOCK)) {
    _ = &mode;
    return __S_ISTYPE(mode, __S_IFSOCK);
}
pub inline fn S_TYPEISMQ(buf: anytype) @TypeOf(__S_TYPEISMQ(buf)) {
    _ = &buf;
    return __S_TYPEISMQ(buf);
}
pub inline fn S_TYPEISSEM(buf: anytype) @TypeOf(__S_TYPEISSEM(buf)) {
    _ = &buf;
    return __S_TYPEISSEM(buf);
}
pub inline fn S_TYPEISSHM(buf: anytype) @TypeOf(__S_TYPEISSHM(buf)) {
    _ = &buf;
    return __S_TYPEISSHM(buf);
}
pub const S_ISUID = __S_ISUID;
pub const S_ISGID = __S_ISGID;
pub const S_ISVTX = __S_ISVTX;
pub const S_IRUSR = __S_IREAD;
pub const S_IWUSR = __S_IWRITE;
pub const S_IXUSR = __S_IEXEC;
pub const S_IRWXU = (__S_IREAD | __S_IWRITE) | __S_IEXEC;
pub const S_IREAD = S_IRUSR;
pub const S_IWRITE = S_IWUSR;
pub const S_IEXEC = S_IXUSR;
pub const S_IRGRP = S_IRUSR >> @as(c_int, 3);
pub const S_IWGRP = S_IWUSR >> @as(c_int, 3);
pub const S_IXGRP = S_IXUSR >> @as(c_int, 3);
pub const S_IRWXG = S_IRWXU >> @as(c_int, 3);
pub const S_IROTH = S_IRGRP >> @as(c_int, 3);
pub const S_IWOTH = S_IWGRP >> @as(c_int, 3);
pub const S_IXOTH = S_IXGRP >> @as(c_int, 3);
pub const S_IRWXO = S_IRWXG >> @as(c_int, 3);
pub const ACCESSPERMS = (S_IRWXU | S_IRWXG) | S_IRWXO;
pub const ALLPERMS = ((((S_ISUID | S_ISGID) | S_ISVTX) | S_IRWXU) | S_IRWXG) | S_IRWXO;
pub const DEFFILEMODE = ((((S_IRUSR | S_IWUSR) | S_IRGRP) | S_IWGRP) | S_IROTH) | S_IWOTH;
pub const S_BLKSIZE = @as(c_int, 512);
pub const _LINUX_STAT_H = "";
pub const _LINUX_TYPES_H = "";
pub const _ASM_GENERIC_TYPES_H = "";
pub const _ASM_GENERIC_INT_LL64_H = "";
pub const __ASM_BITSPERLONG_H = "";
pub const __BITS_PER_LONG = @as(c_int, 64);
pub const __ASM_GENERIC_BITS_PER_LONG = "";
pub const __BITS_PER_LONG_LONG = @as(c_int, 64);
pub const _LINUX_POSIX_TYPES_H = "";
pub const _LINUX_STDDEF_H = "";
pub inline fn __struct_group_tag(TAG: anytype) @TypeOf(TAG) {
    _ = &TAG;
    return TAG;
}
pub const __struct_group = @compileError("unable to translate C expr: unexpected token 'union'");
// /usr/include/linux/stddef.h:32:9
pub const __DECLARE_FLEX_ARRAY = @compileError("unable to translate macro: undefined identifier `__empty_`");
// /usr/include/linux/stddef.h:53:9
pub inline fn __counted_by(m: anytype) void {
    _ = &m;
    return;
}
pub inline fn __counted_by_le(m: anytype) void {
    _ = &m;
    return;
}
pub inline fn __counted_by_be(m: anytype) void {
    _ = &m;
    return;
}
pub inline fn __counted_by_ptr(m: anytype) void {
    _ = &m;
    return;
}
pub const __kernel_nonstring = "";
pub const __FD_SETSIZE = @as(c_int, 1024);
pub const __ASM_POSIX_TYPES_H = "";
pub const __ASM_GENERIC_POSIX_TYPES_H = "";
pub const __bitwise = "";
pub const __bitwise__ = "";
pub const __aligned_u64 = @compileError("unable to translate macro: undefined identifier `aligned`");
// /usr/include/linux/types.h:50:9
pub const __aligned_s64 = @compileError("unable to translate macro: undefined identifier `aligned`");
// /usr/include/linux/types.h:51:9
pub const __aligned_be64 = @compileError("unable to translate macro: undefined identifier `aligned`");
// /usr/include/linux/types.h:52:9
pub const __aligned_le64 = @compileError("unable to translate macro: undefined identifier `aligned`");
// /usr/include/linux/types.h:53:9
pub const STATX_TYPE = @as(c_uint, 0x00000001);
pub const STATX_MODE = @as(c_uint, 0x00000002);
pub const STATX_NLINK = @as(c_uint, 0x00000004);
pub const STATX_UID = @as(c_uint, 0x00000008);
pub const STATX_GID = @as(c_uint, 0x00000010);
pub const STATX_ATIME = @as(c_uint, 0x00000020);
pub const STATX_MTIME = @as(c_uint, 0x00000040);
pub const STATX_CTIME = @as(c_uint, 0x00000080);
pub const STATX_INO = @as(c_uint, 0x00000100);
pub const STATX_SIZE = @as(c_uint, 0x00000200);
pub const STATX_BLOCKS = @as(c_uint, 0x00000400);
pub const STATX_BASIC_STATS = @as(c_uint, 0x000007ff);
pub const STATX_BTIME = @as(c_uint, 0x00000800);
pub const STATX_MNT_ID = @as(c_uint, 0x00001000);
pub const STATX_DIOALIGN = @as(c_uint, 0x00002000);
pub const STATX_MNT_ID_UNIQUE = @as(c_uint, 0x00004000);
pub const STATX_SUBVOL = @as(c_uint, 0x00008000);
pub const STATX_WRITE_ATOMIC = __helpers.promoteIntLiteral(c_uint, 0x00010000, .hex);
pub const STATX_DIO_READ_ALIGN = __helpers.promoteIntLiteral(c_uint, 0x00020000, .hex);
pub const STATX__RESERVED = __helpers.promoteIntLiteral(c_uint, 0x80000000, .hex);
pub const STATX_ALL = @as(c_uint, 0x00000fff);
pub const STATX_ATTR_COMPRESSED = @as(c_int, 0x00000004);
pub const STATX_ATTR_IMMUTABLE = @as(c_int, 0x00000010);
pub const STATX_ATTR_APPEND = @as(c_int, 0x00000020);
pub const STATX_ATTR_NODUMP = @as(c_int, 0x00000040);
pub const STATX_ATTR_ENCRYPTED = @as(c_int, 0x00000800);
pub const STATX_ATTR_AUTOMOUNT = @as(c_int, 0x00001000);
pub const STATX_ATTR_MOUNT_ROOT = @as(c_int, 0x00002000);
pub const STATX_ATTR_VERITY = __helpers.promoteIntLiteral(c_int, 0x00100000, .hex);
pub const STATX_ATTR_DAX = __helpers.promoteIntLiteral(c_int, 0x00200000, .hex);
pub const STATX_ATTR_WRITE_ATOMIC = __helpers.promoteIntLiteral(c_int, 0x00400000, .hex);
pub const __statx_timestamp_defined = @as(c_int, 1);
pub const __statx_defined = @as(c_int, 1);
pub const _FCNTL_H = @as(c_int, 1);
pub const __O_DIRECTORY = @as(c_int, 0o40000);
pub const __O_NOFOLLOW = __helpers.promoteIntLiteral(c_int, 0o100000, .octal);
pub const __O_DIRECT = __helpers.promoteIntLiteral(c_int, 0o200000, .octal);
pub const __O_LARGEFILE = @as(c_int, 0);
pub const F_GETLK64 = @as(c_int, 5);
pub const F_SETLK64 = @as(c_int, 6);
pub const F_SETLKW64 = @as(c_int, 7);
pub const __iovec_defined = @as(c_int, 1);
pub const O_ACCMODE = @as(c_int, 0o003);
pub const O_RDONLY = @as(c_int, 0o0);
pub const O_WRONLY = @as(c_int, 0o1);
pub const O_RDWR = @as(c_int, 0o2);
pub const O_CREAT = @as(c_int, 0o100);
pub const O_EXCL = @as(c_int, 0o200);
pub const O_NOCTTY = @as(c_int, 0o400);
pub const O_TRUNC = @as(c_int, 0o1000);
pub const O_APPEND = @as(c_int, 0o2000);
pub const O_NONBLOCK = @as(c_int, 0o4000);
pub const O_NDELAY = O_NONBLOCK;
pub const O_SYNC = __helpers.promoteIntLiteral(c_int, 0o4010000, .octal);
pub const O_FSYNC = O_SYNC;
pub const O_ASYNC = @as(c_int, 0o20000);
pub const __O_CLOEXEC = __helpers.promoteIntLiteral(c_int, 0o2000000, .octal);
pub const __O_NOATIME = __helpers.promoteIntLiteral(c_int, 0o1000000, .octal);
pub const __O_PATH = __helpers.promoteIntLiteral(c_int, 0o10000000, .octal);
pub const __O_DSYNC = @as(c_int, 0o10000);
pub const __O_TMPFILE = __helpers.promoteIntLiteral(c_int, 0o20000000, .octal) | __O_DIRECTORY;
pub const F_GETLK = F_GETLK64;
pub const F_SETLK = F_SETLK64;
pub const F_SETLKW = F_SETLKW64;
pub const F_OFD_GETLK = @as(c_int, 36);
pub const F_OFD_SETLK = @as(c_int, 37);
pub const F_OFD_SETLKW = @as(c_int, 38);
pub const O_LARGEFILE = __O_LARGEFILE;
pub const O_DIRECTORY = __O_DIRECTORY;
pub const O_NOFOLLOW = __O_NOFOLLOW;
pub const O_CLOEXEC = __O_CLOEXEC;
pub const O_DIRECT = __O_DIRECT;
pub const O_NOATIME = __O_NOATIME;
pub const O_PATH = __O_PATH;
pub const O_TMPFILE = __O_TMPFILE;
pub const O_DSYNC = __O_DSYNC;
pub const O_RSYNC = O_SYNC;
pub const F_DUPFD = @as(c_int, 0);
pub const F_GETFD = @as(c_int, 1);
pub const F_SETFD = @as(c_int, 2);
pub const F_GETFL = @as(c_int, 3);
pub const F_SETFL = @as(c_int, 4);
pub const __F_SETOWN = @as(c_int, 8);
pub const __F_GETOWN = @as(c_int, 9);
pub const F_SETOWN = __F_SETOWN;
pub const F_GETOWN = __F_GETOWN;
pub const __F_SETSIG = @as(c_int, 10);
pub const __F_GETSIG = @as(c_int, 11);
pub const __F_SETOWN_EX = @as(c_int, 15);
pub const __F_GETOWN_EX = @as(c_int, 16);
pub const F_SETSIG = __F_SETSIG;
pub const F_GETSIG = __F_GETSIG;
pub const F_SETOWN_EX = __F_SETOWN_EX;
pub const F_GETOWN_EX = __F_GETOWN_EX;
pub const F_SETLEASE = @as(c_int, 1024);
pub const F_GETLEASE = @as(c_int, 1025);
pub const F_NOTIFY = @as(c_int, 1026);
pub const F_DUPFD_QUERY = @as(c_int, 1027);
pub const F_CREATED_QUERY = @as(c_int, 1028);
pub const F_SETPIPE_SZ = @as(c_int, 1031);
pub const F_GETPIPE_SZ = @as(c_int, 1032);
pub const F_ADD_SEALS = @as(c_int, 1033);
pub const F_GET_SEALS = @as(c_int, 1034);
pub const F_GET_RW_HINT = @as(c_int, 1035);
pub const F_SET_RW_HINT = @as(c_int, 1036);
pub const F_GET_FILE_RW_HINT = @as(c_int, 1037);
pub const F_SET_FILE_RW_HINT = @as(c_int, 1038);
pub const F_DUPFD_CLOEXEC = @as(c_int, 1030);
pub const FD_CLOEXEC = @as(c_int, 1);
pub const FD_PIDFS_ROOT = -@as(c_int, 10002);
pub const F_RDLCK = @as(c_int, 0);
pub const F_WRLCK = @as(c_int, 1);
pub const F_UNLCK = @as(c_int, 2);
pub const F_EXLCK = @as(c_int, 4);
pub const F_SHLCK = @as(c_int, 8);
pub const LOCK_SH = @as(c_int, 1);
pub const LOCK_EX = @as(c_int, 2);
pub const LOCK_NB = @as(c_int, 4);
pub const LOCK_UN = @as(c_int, 8);
pub const LOCK_MAND = @as(c_int, 32);
pub const LOCK_READ = @as(c_int, 64);
pub const LOCK_WRITE = @as(c_int, 128);
pub const LOCK_RW = @as(c_int, 192);
pub const DN_ACCESS = @as(c_int, 0x00000001);
pub const DN_MODIFY = @as(c_int, 0x00000002);
pub const DN_CREATE = @as(c_int, 0x00000004);
pub const DN_DELETE = @as(c_int, 0x00000008);
pub const DN_RENAME = @as(c_int, 0x00000010);
pub const DN_ATTRIB = @as(c_int, 0x00000020);
pub const DN_MULTISHOT = __helpers.promoteIntLiteral(c_int, 0x80000000, .hex);
pub const F_SEAL_SEAL = @as(c_int, 0x0001);
pub const F_SEAL_SHRINK = @as(c_int, 0x0002);
pub const F_SEAL_GROW = @as(c_int, 0x0004);
pub const F_SEAL_WRITE = @as(c_int, 0x0008);
pub const F_SEAL_FUTURE_WRITE = @as(c_int, 0x0010);
pub const F_SEAL_EXEC = @as(c_int, 0x0020);
pub const RWH_WRITE_LIFE_NOT_SET = @as(c_int, 0);
pub const RWF_WRITE_LIFE_NOT_SET = RWH_WRITE_LIFE_NOT_SET;
pub const RWH_WRITE_LIFE_NONE = @as(c_int, 1);
pub const RWH_WRITE_LIFE_SHORT = @as(c_int, 2);
pub const RWH_WRITE_LIFE_MEDIUM = @as(c_int, 3);
pub const RWH_WRITE_LIFE_LONG = @as(c_int, 4);
pub const RWH_WRITE_LIFE_EXTREME = @as(c_int, 5);
pub const FAPPEND = O_APPEND;
pub const FFSYNC = O_FSYNC;
pub const FASYNC = O_ASYNC;
pub const FNONBLOCK = O_NONBLOCK;
pub const FNDELAY = O_NDELAY;
pub const __POSIX_FADV_DONTNEED = @as(c_int, 4);
pub const __POSIX_FADV_NOREUSE = @as(c_int, 5);
pub const POSIX_FADV_NORMAL = @as(c_int, 0);
pub const POSIX_FADV_RANDOM = @as(c_int, 1);
pub const POSIX_FADV_SEQUENTIAL = @as(c_int, 2);
pub const POSIX_FADV_WILLNEED = @as(c_int, 3);
pub const POSIX_FADV_DONTNEED = __POSIX_FADV_DONTNEED;
pub const POSIX_FADV_NOREUSE = __POSIX_FADV_NOREUSE;
pub const SYNC_FILE_RANGE_WAIT_BEFORE = @as(c_int, 1);
pub const SYNC_FILE_RANGE_WRITE = @as(c_int, 2);
pub const SYNC_FILE_RANGE_WAIT_AFTER = @as(c_int, 4);
pub const SYNC_FILE_RANGE_WRITE_AND_WAIT = (SYNC_FILE_RANGE_WRITE | SYNC_FILE_RANGE_WAIT_BEFORE) | SYNC_FILE_RANGE_WAIT_AFTER;
pub const SPLICE_F_MOVE = @as(c_int, 1);
pub const SPLICE_F_NONBLOCK = @as(c_int, 2);
pub const SPLICE_F_MORE = @as(c_int, 4);
pub const SPLICE_F_GIFT = @as(c_int, 8);
pub const _FALLOC_H_ = "";
pub const FALLOC_FL_ALLOCATE_RANGE = @as(c_int, 0x00);
pub const FALLOC_FL_KEEP_SIZE = @as(c_int, 0x01);
pub const FALLOC_FL_PUNCH_HOLE = @as(c_int, 0x02);
pub const FALLOC_FL_NO_HIDE_STALE = @as(c_int, 0x04);
pub const FALLOC_FL_COLLAPSE_RANGE = @as(c_int, 0x08);
pub const FALLOC_FL_ZERO_RANGE = @as(c_int, 0x10);
pub const FALLOC_FL_INSERT_RANGE = @as(c_int, 0x20);
pub const FALLOC_FL_UNSHARE_RANGE = @as(c_int, 0x40);
pub const FALLOC_FL_WRITE_ZEROES = @as(c_int, 0x80);
pub const MAX_HANDLE_SZ = @as(c_int, 128);
pub const AT_HANDLE_FID = AT_REMOVEDIR;
pub const AT_HANDLE_MNT_ID_UNIQUE = @as(c_int, 1);
pub const AT_HANDLE_CONNECTABLE = @as(c_int, 2);
pub const AT_EXECVE_CHECK = __helpers.promoteIntLiteral(c_int, 0x10000, .hex);
pub const _LINUX_OPENAT2_H = "";
pub const RESOLVE_NO_XDEV = @as(c_int, 0x01);
pub const RESOLVE_NO_MAGICLINKS = @as(c_int, 0x02);
pub const RESOLVE_NO_SYMLINKS = @as(c_int, 0x04);
pub const RESOLVE_BENEATH = @as(c_int, 0x08);
pub const RESOLVE_IN_ROOT = @as(c_int, 0x10);
pub const RESOLVE_CACHED = @as(c_int, 0x20);
pub const __glibc_has_open_how = @as(c_int, 1);
pub inline fn __OPEN_NEEDS_MODE(oflag: anytype) @TypeOf(((oflag & O_CREAT) != @as(c_int, 0)) or ((oflag & __O_TMPFILE) == __O_TMPFILE)) {
    _ = &oflag;
    return ((oflag & O_CREAT) != @as(c_int, 0)) or ((oflag & __O_TMPFILE) == __O_TMPFILE);
}
pub const R_OK = @as(c_int, 4);
pub const W_OK = @as(c_int, 2);
pub const X_OK = @as(c_int, 1);
pub const F_OK = @as(c_int, 0);
pub const AT_FDCWD = -@as(c_int, 100);
pub const AT_SYMLINK_NOFOLLOW = @as(c_int, 0x100);
pub const AT_REMOVEDIR = @as(c_int, 0x200);
pub const AT_SYMLINK_FOLLOW = @as(c_int, 0x400);
pub const AT_NO_AUTOMOUNT = @as(c_int, 0x800);
pub const AT_EMPTY_PATH = @as(c_int, 0x1000);
pub const AT_STATX_SYNC_TYPE = @as(c_int, 0x6000);
pub const AT_STATX_SYNC_AS_STAT = @as(c_int, 0x0000);
pub const AT_STATX_FORCE_SYNC = @as(c_int, 0x2000);
pub const AT_STATX_DONT_SYNC = @as(c_int, 0x4000);
pub const AT_RECURSIVE = __helpers.promoteIntLiteral(c_int, 0x8000, .hex);
pub const AT_EACCESS = @as(c_int, 0x200);
pub const F_ULOCK = @as(c_int, 0);
pub const F_LOCK = @as(c_int, 1);
pub const F_TLOCK = @as(c_int, 2);
pub const F_TEST = @as(c_int, 3);
pub const _UNISTD_H = @as(c_int, 1);
pub const _POSIX_VERSION = @as(c_long, 200809);
pub const __POSIX2_THIS_VERSION = @as(c_long, 200809);
pub const _POSIX2_VERSION = __POSIX2_THIS_VERSION;
pub const _POSIX2_C_VERSION = __POSIX2_THIS_VERSION;
pub const _POSIX2_C_BIND = __POSIX2_THIS_VERSION;
pub const _POSIX2_C_DEV = __POSIX2_THIS_VERSION;
pub const _POSIX2_SW_DEV = __POSIX2_THIS_VERSION;
pub const _POSIX2_LOCALEDEF = __POSIX2_THIS_VERSION;
pub const _XOPEN_VERSION = @as(c_int, 700);
pub const _XOPEN_XCU_VERSION = @as(c_int, 4);
pub const _XOPEN_XPG2 = @as(c_int, 1);
pub const _XOPEN_XPG3 = @as(c_int, 1);
pub const _XOPEN_XPG4 = @as(c_int, 1);
pub const _XOPEN_UNIX = @as(c_int, 1);
pub const _XOPEN_ENH_I18N = @as(c_int, 1);
pub const _XOPEN_LEGACY = @as(c_int, 1);
pub const _BITS_POSIX_OPT_H = @as(c_int, 1);
pub const _POSIX_JOB_CONTROL = @as(c_int, 1);
pub const _POSIX_SAVED_IDS = @as(c_int, 1);
pub const _POSIX_PRIORITY_SCHEDULING = @as(c_long, 200809);
pub const _POSIX_SYNCHRONIZED_IO = @as(c_long, 200809);
pub const _POSIX_FSYNC = @as(c_long, 200809);
pub const _POSIX_MAPPED_FILES = @as(c_long, 200809);
pub const _POSIX_MEMLOCK = @as(c_long, 200809);
pub const _POSIX_MEMLOCK_RANGE = @as(c_long, 200809);
pub const _POSIX_MEMORY_PROTECTION = @as(c_long, 200809);
pub const _POSIX_CHOWN_RESTRICTED = @as(c_int, 0);
pub const _POSIX_VDISABLE = @as(c_int, 0);
pub const _POSIX_NO_TRUNC = @as(c_int, 1);
pub const _XOPEN_REALTIME = @as(c_int, 1);
pub const _XOPEN_REALTIME_THREADS = @as(c_int, 1);
pub const _XOPEN_SHM = @as(c_int, 1);
pub const _POSIX_THREADS = @as(c_long, 200809);
pub const _POSIX_REENTRANT_FUNCTIONS = @as(c_int, 1);
pub const _POSIX_THREAD_SAFE_FUNCTIONS = @as(c_long, 200809);
pub const _POSIX_THREAD_PRIORITY_SCHEDULING = @as(c_long, 200809);
pub const _POSIX_THREAD_ATTR_STACKSIZE = @as(c_long, 200809);
pub const _POSIX_THREAD_ATTR_STACKADDR = @as(c_long, 200809);
pub const _POSIX_THREAD_PRIO_INHERIT = @as(c_long, 200809);
pub const _POSIX_THREAD_PRIO_PROTECT = @as(c_long, 200809);
pub const _POSIX_THREAD_ROBUST_PRIO_INHERIT = @as(c_long, 200809);
pub const _POSIX_THREAD_ROBUST_PRIO_PROTECT = -@as(c_int, 1);
pub const _POSIX_SEMAPHORES = @as(c_long, 200809);
pub const _POSIX_REALTIME_SIGNALS = @as(c_long, 200809);
pub const _POSIX_ASYNCHRONOUS_IO = @as(c_long, 200809);
pub const _POSIX_ASYNC_IO = @as(c_int, 1);
pub const _LFS_ASYNCHRONOUS_IO = @as(c_int, 1);
pub const _POSIX_PRIORITIZED_IO = @as(c_long, 200809);
pub const _LFS64_ASYNCHRONOUS_IO = @as(c_int, 1);
pub const _LFS_LARGEFILE = @as(c_int, 1);
pub const _LFS64_LARGEFILE = @as(c_int, 1);
pub const _LFS64_STDIO = @as(c_int, 1);
pub const _POSIX_SHARED_MEMORY_OBJECTS = @as(c_long, 200809);
pub const _POSIX_CPUTIME = @as(c_int, 0);
pub const _POSIX_THREAD_CPUTIME = @as(c_int, 0);
pub const _POSIX_REGEXP = @as(c_int, 1);
pub const _POSIX_READER_WRITER_LOCKS = @as(c_long, 200809);
pub const _POSIX_SHELL = @as(c_int, 1);
pub const _POSIX_TIMEOUTS = @as(c_long, 200809);
pub const _POSIX_SPIN_LOCKS = @as(c_long, 200809);
pub const _POSIX_SPAWN = @as(c_long, 200809);
pub const _POSIX_TIMERS = @as(c_long, 200809);
pub const _POSIX_BARRIERS = @as(c_long, 200809);
pub const _POSIX_MESSAGE_PASSING = @as(c_long, 200809);
pub const _POSIX_THREAD_PROCESS_SHARED = @as(c_long, 200809);
pub const _POSIX_MONOTONIC_CLOCK = @as(c_int, 0);
pub const _POSIX_CLOCK_SELECTION = @as(c_long, 200809);
pub const _POSIX_ADVISORY_INFO = @as(c_long, 200809);
pub const _POSIX_IPV6 = @as(c_long, 200809);
pub const _POSIX_RAW_SOCKETS = @as(c_long, 200809);
pub const _POSIX2_CHAR_TERM = @as(c_long, 200809);
pub const _POSIX_SPORADIC_SERVER = -@as(c_int, 1);
pub const _POSIX_THREAD_SPORADIC_SERVER = -@as(c_int, 1);
pub const _POSIX_TRACE = -@as(c_int, 1);
pub const _POSIX_TRACE_EVENT_FILTER = -@as(c_int, 1);
pub const _POSIX_TRACE_INHERIT = -@as(c_int, 1);
pub const _POSIX_TRACE_LOG = -@as(c_int, 1);
pub const _POSIX_TYPED_MEMORY_OBJECTS = -@as(c_int, 1);
pub const _POSIX_V7_ILP32_OFF32 = -@as(c_int, 1);
pub const _POSIX_V7_ILP32_OFFBIG = -@as(c_int, 1);
pub const _POSIX_V6_ILP32_OFF32 = -@as(c_int, 1);
pub const _POSIX_V6_ILP32_OFFBIG = -@as(c_int, 1);
pub const _XBS5_ILP32_OFF32 = -@as(c_int, 1);
pub const _XBS5_ILP32_OFFBIG = -@as(c_int, 1);
pub const _POSIX_V7_LPBIG_OFFBIG = -@as(c_int, 1);
pub const _POSIX_V6_LPBIG_OFFBIG = -@as(c_int, 1);
pub const _XBS5_LPBIG_OFFBIG = -@as(c_int, 1);
pub const _POSIX_V7_LP64_OFF64 = @as(c_int, 1);
pub const _POSIX_V6_LP64_OFF64 = @as(c_int, 1);
pub const _XBS5_LP64_OFF64 = @as(c_int, 1);
pub const STDIN_FILENO = @as(c_int, 0);
pub const STDOUT_FILENO = @as(c_int, 1);
pub const STDERR_FILENO = @as(c_int, 2);
pub const __socklen_t_defined = "";
pub const L_SET = SEEK_SET;
pub const L_INCR = SEEK_CUR;
pub const L_XTND = SEEK_END;
pub const _SC_PAGE_SIZE = _SC_PAGESIZE;
pub const _CS_POSIX_V6_WIDTH_RESTRICTED_ENVS = _CS_V6_WIDTH_RESTRICTED_ENVS;
pub const _CS_POSIX_V5_WIDTH_RESTRICTED_ENVS = _CS_V5_WIDTH_RESTRICTED_ENVS;
pub const _CS_POSIX_V7_WIDTH_RESTRICTED_ENVS = _CS_V7_WIDTH_RESTRICTED_ENVS;
pub const _GETOPT_POSIX_H = @as(c_int, 1);
pub const _GETOPT_CORE_H = @as(c_int, 1);
pub const TEMP_FAILURE_RETRY = @compileError("unable to translate macro: undefined identifier `__result`");
// /usr/include/unistd.h:1134:10
pub const _LINUX_CLOSE_RANGE_H = "";
pub const CLOSE_RANGE_UNSHARE = @as(c_uint, 1) << @as(c_int, 1);
pub const CLOSE_RANGE_CLOEXEC = @as(c_uint, 1) << @as(c_int, 2);
pub const JENT_MAJVERSION = @as(c_int, 3);
pub const JENT_MINVERSION = @as(c_int, 8);
pub const JENT_PATCHLEVEL = @as(c_int, 0);
pub const JENT_VERSION = ((JENT_MAJVERSION * __helpers.promoteIntLiteral(c_int, 1000000, .decimal)) + (JENT_MINVERSION * @as(c_int, 10000))) + (JENT_PATCHLEVEL * @as(c_int, 100));
pub const JENT_DISABLE_STIR = @as(c_int, 1) << @as(c_int, 0);
pub const JENT_DISABLE_UNBIAS = @as(c_int, 1) << @as(c_int, 1);
pub const JENT_DISABLE_MEMORY_ACCESS = @as(c_int, 1) << @as(c_int, 2);
pub const JENT_FORCE_INTERNAL_TIMER = @as(c_int, 1) << @as(c_int, 3);
pub const JENT_DISABLE_INTERNAL_TIMER = @as(c_int, 1) << @as(c_int, 4);
pub const JENT_FORCE_FIPS = @as(c_int, 1) << @as(c_int, 5);
pub const JENT_NTG1 = @as(c_int, 1) << @as(c_int, 6);
pub const JENT_CACHE_ALL = @as(c_int, 1) << @as(c_int, 7);
pub const JENT_FORCE_SECURE_MEM = @as(c_int, 1) << @as(c_int, 8);
pub const JENT_FLAGS_TO_MEMSIZE_SHIFT = @as(c_int, 27);
pub inline fn JENT_FLAGS_TO_MAX_MEMSIZE(val: anytype) @TypeOf(val >> JENT_FLAGS_TO_MEMSIZE_SHIFT) {
    _ = &val;
    return val >> JENT_FLAGS_TO_MEMSIZE_SHIFT;
}
pub inline fn JENT_MAX_MEMSIZE_TO_FLAGS(val: anytype) @TypeOf(val << JENT_FLAGS_TO_MEMSIZE_SHIFT) {
    _ = &val;
    return val << JENT_FLAGS_TO_MEMSIZE_SHIFT;
}
pub const JENT_MAX_MEMSIZE_1kB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 1)));
pub const JENT_MAX_MEMSIZE_2kB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 2)));
pub const JENT_MAX_MEMSIZE_4kB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 3)));
pub const JENT_MAX_MEMSIZE_8kB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 4)));
pub const JENT_MAX_MEMSIZE_16kB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 5)));
pub const JENT_MAX_MEMSIZE_32kB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 6)));
pub const JENT_MAX_MEMSIZE_64kB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 7)));
pub const JENT_MAX_MEMSIZE_128kB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 8)));
pub const JENT_MAX_MEMSIZE_256kB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 9)));
pub const JENT_MAX_MEMSIZE_512kB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 10)));
pub const JENT_MAX_MEMSIZE_1MB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 11)));
pub const JENT_MAX_MEMSIZE_2MB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 12)));
pub const JENT_MAX_MEMSIZE_4MB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 13)));
pub const JENT_MAX_MEMSIZE_8MB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 14)));
pub const JENT_MAX_MEMSIZE_16MB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 15)));
pub const JENT_MAX_MEMSIZE_32MB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 16)));
pub const JENT_MAX_MEMSIZE_64MB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 17)));
pub const JENT_MAX_MEMSIZE_128MB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 18)));
pub const JENT_MAX_MEMSIZE_256MB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 19)));
pub const JENT_MAX_MEMSIZE_512MB = JENT_MAX_MEMSIZE_TO_FLAGS(UINT32_C(@as(c_int, 20)));
pub const JENT_MAX_MEMSIZE_MAX = JENT_MAX_MEMSIZE_512MB;
pub const JENT_MAX_MEMSIZE_MASK = JENT_MAX_MEMSIZE_TO_FLAGS(__helpers.promoteIntLiteral(c_int, 0xffffffff, .hex));
pub const JENT_MAX_MEMSIZE_OFFSET = @as(c_int, 9);
pub const JENT_FLAGS_TO_HASHLOOP_SHIFT = @as(c_int, 23);
pub inline fn JENT_HASHLOOP_TO_FLAGS(val: anytype) @TypeOf(val << JENT_FLAGS_TO_HASHLOOP_SHIFT) {
    _ = &val;
    return val << JENT_FLAGS_TO_HASHLOOP_SHIFT;
}
pub const JENT_MAX_HASHLOOP_MASK = JENT_HASHLOOP_TO_FLAGS(@as(c_int, 0xf));
pub inline fn JENT_FLAGS_TO_HASHLOOP(val: anytype) @TypeOf((val >> JENT_FLAGS_TO_HASHLOOP_SHIFT) & @as(c_int, 0xf)) {
    _ = &val;
    return (val >> JENT_FLAGS_TO_HASHLOOP_SHIFT) & @as(c_int, 0xf);
}
pub const JENT_HASHLOOP_1 = JENT_HASHLOOP_TO_FLAGS(UINT32_C(@as(c_int, 1)));
pub const JENT_HASHLOOP_2 = JENT_HASHLOOP_TO_FLAGS(UINT32_C(@as(c_int, 2)));
pub const JENT_HASHLOOP_4 = JENT_HASHLOOP_TO_FLAGS(UINT32_C(@as(c_int, 3)));
pub const JENT_HASHLOOP_8 = JENT_HASHLOOP_TO_FLAGS(UINT32_C(@as(c_int, 4)));
pub const JENT_HASHLOOP_16 = JENT_HASHLOOP_TO_FLAGS(UINT32_C(@as(c_int, 5)));
pub const JENT_HASHLOOP_32 = JENT_HASHLOOP_TO_FLAGS(UINT32_C(@as(c_int, 6)));
pub const JENT_HASHLOOP_64 = JENT_HASHLOOP_TO_FLAGS(UINT32_C(@as(c_int, 7)));
pub const JENT_HASHLOOP_128 = JENT_HASHLOOP_TO_FLAGS(UINT32_C(@as(c_int, 8)));
pub const JENT_MAX_HASHLOOP = JENT_HASHLOOP_128;
pub const JENT_MIN_OSR = @as(c_int, 3);
pub const JENT_MAX_OSR = @as(c_int, 20);
pub const JENT_PRIVATE_STATIC = @compileError("unable to translate macro: undefined identifier `visibility`");
// jitterentropy.h:318:9
pub const JENT_INTERNAL = "";
pub const JENT_PTHREAD = "";
pub const JENT_UUID_STRLEN = @as(c_int, 37);
pub const ENOTIME = @as(c_int, 1);
pub const ECOARSETIME = @as(c_int, 2);
pub const ENOMONOTONIC = @as(c_int, 3);
pub const EMINVARIATION = @as(c_int, 4);
pub const EVARVAR = @as(c_int, 5);
pub const EMINVARVAR = @as(c_int, 6);
pub const EPROGERR = @as(c_int, 7);
pub const ESTUCK = @as(c_int, 8);
pub const EHEALTH = @as(c_int, 9);
pub const ERCT = @as(c_int, 10);
pub const EHASH = @as(c_int, 11);
pub const EMEM = @as(c_int, 12);
pub const EGCD = @as(c_int, 13);
pub const JENT_ERR_EINVAL = -@as(c_int, 1);
pub const JENT_ERR_RCT = -@as(c_int, 2);
pub const JENT_ERR_APT = -@as(c_int, 3);
pub const JENT_ERR_NOTIME = -@as(c_int, 4);
pub const JENT_ERR_LAG = -@as(c_int, 5);
pub const JENT_ERR_RCT_PERMANENT = -@as(c_int, 6);
pub const JENT_ERR_APT_PERMANENT = -@as(c_int, 7);
pub const JENT_ERR_LAG_PERMANENT = -@as(c_int, 8);
pub const JENT_ERR_RCT_MEM = -@as(c_int, 9);
pub const JENT_ERR_RCT_MEM_PERMANENT = -@as(c_int, 10);
pub const JENT_ERR_SELFTEST = -@as(c_int, 11);
pub const JENT_RCT_FAILURE = @as(c_int, 1);
pub const JENT_APT_FAILURE = @as(c_int, 2);
pub const JENT_LAG_FAILURE = @as(c_int, 4);
pub const JENT_RCT_MEM_FAILURE = @as(c_int, 8);
pub const JENT_PERMANENT_FAILURE_SHIFT = @as(c_int, 16);
pub inline fn JENT_PERMANENT_FAILURE(x: anytype) @TypeOf(x << JENT_PERMANENT_FAILURE_SHIFT) {
    _ = &x;
    return x << JENT_PERMANENT_FAILURE_SHIFT;
}
pub const JENT_RCT_FAILURE_PERMANENT = JENT_PERMANENT_FAILURE(JENT_RCT_FAILURE);
pub const JENT_APT_FAILURE_PERMANENT = JENT_PERMANENT_FAILURE(JENT_APT_FAILURE);
pub const JENT_LAG_FAILURE_PERMANENT = JENT_PERMANENT_FAILURE(JENT_LAG_FAILURE);
pub const JENT_RCT_MEM_FAILURE_PERMANENT = JENT_PERMANENT_FAILURE(JENT_RCT_MEM_FAILURE);
pub const _SYS_TIME_H = @as(c_int, 1);
pub const TIMEVAL_TO_TIMESPEC = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/aarch64-linux-gnu/sys/time.h:38:10
pub const TIMESPEC_TO_TIMEVAL = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/aarch64-linux-gnu/sys/time.h:42:10
pub inline fn timerisset(tvp: anytype) @TypeOf((tvp.*.tv_sec != 0) or (tvp.*.tv_usec != 0)) {
    _ = &tvp;
    return (tvp.*.tv_sec != 0) or (tvp.*.tv_usec != 0);
}
pub const timerclear = @compileError("unable to translate C expr: expected ')' instead got '='");
// /usr/include/aarch64-linux-gnu/sys/time.h:232:10
pub inline fn timercmp(a: anytype, b: anytype, CMP: anytype) @TypeOf(if (__helpers.cast(bool, a.*.tv_sec == b.*.tv_sec)) a.*.tv_usec ++ CMP(b).*.tv_usec else a.*.tv_sec ++ CMP(b).*.tv_sec) {
    _ = &a;
    _ = &b;
    _ = &CMP;
    return if (__helpers.cast(bool, a.*.tv_sec == b.*.tv_sec)) a.*.tv_usec ++ CMP(b).*.tv_usec else a.*.tv_sec ++ CMP(b).*.tv_sec;
}
pub const timeradd = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/aarch64-linux-gnu/sys/time.h:237:10
pub const timersub = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/aarch64-linux-gnu/sys/time.h:247:10
pub const _SYS_RESOURCE_H = @as(c_int, 1);
pub const RLIMIT_RSS = __RLIMIT_RSS;
pub const RLIMIT_OFILE = __RLIMIT_OFILE;
pub const RLIMIT_NPROC = __RLIMIT_NPROC;
pub const RLIMIT_MEMLOCK = __RLIMIT_MEMLOCK;
pub const RLIMIT_LOCKS = __RLIMIT_LOCKS;
pub const RLIMIT_SIGPENDING = __RLIMIT_SIGPENDING;
pub const RLIMIT_MSGQUEUE = __RLIMIT_MSGQUEUE;
pub const RLIMIT_NICE = __RLIMIT_NICE;
pub const RLIMIT_RTPRIO = __RLIMIT_RTPRIO;
pub const RLIMIT_RTTIME = __RLIMIT_RTTIME;
pub const RLIMIT_NLIMITS = __RLIMIT_NLIMITS;
pub const RLIM_NLIMITS = __RLIM_NLIMITS;
pub const RLIM_INFINITY = __helpers.cast(__rlim_t, -@as(c_int, 1));
pub const RLIM64_INFINITY = @as(c_ulonglong, 0xffffffffffffffff);
pub const RLIM_SAVED_MAX = RLIM_INFINITY;
pub const RLIM_SAVED_CUR = RLIM_INFINITY;
pub const RUSAGE_LWP = RUSAGE_THREAD;
pub const __rusage_defined = @as(c_int, 1);
pub const PRIO_MIN = -@as(c_int, 20);
pub const PRIO_MAX = @as(c_int, 20);
pub const JENT_MEMLOCK_SIZE = @as(c_ulonglong, 1) << @as(c_int, 20);
pub const JENT_SECMEM_SIZE = @as(c_ulonglong, 2) << @as(c_int, 20);
pub const JENT_UT_MAYBE_UNUSED = @compileError("unable to translate macro: undefined identifier `unused`");
// tests/unit/unit.h:56:10
pub const JENT_UT_FAIL = @compileError("unable to translate macro: undefined identifier `__LINE__`");
// tests/unit/unit.h:61:9
pub const JENT_UT_TRUE = @compileError("unable to translate C expr: unexpected token 'do'");
// tests/unit/unit.h:69:9
pub const JENT_UT_EQ = @compileError("unable to translate macro: undefined identifier `_g`");
// tests/unit/unit.h:77:9
pub const JENT_UT_NE = @compileError("unable to translate macro: undefined identifier `_g`");
// tests/unit/unit.h:88:9
pub const JENT_UT_MEM_EQ = @compileError("unable to translate C expr: unexpected token 'do'");
// tests/unit/unit.h:99:9
pub const JENT_UT_SKIP = @compileError("unable to translate C expr: unexpected token 'do'");
// tests/unit/unit.h:112:9
pub inline fn JENT_UT_SECURE_MEM_FORCED(flags: anytype) @TypeOf(((flags & ((JENT_FORCE_FIPS | JENT_NTG1) | JENT_FORCE_SECURE_MEM)) != 0) or (jent_fips_enabled() != 0)) {
    _ = &flags;
    return ((flags & ((JENT_FORCE_FIPS | JENT_NTG1) | JENT_FORCE_SECURE_MEM)) != 0) or (jent_fips_enabled() != 0);
}
pub inline fn JENT_UT_MACHINE_VERDICT_FLAGS(ret: anytype, flags: anytype) @TypeOf(!(jent_ut_strict() != 0) and ((((((((ret == ENOTIME) or (ret == ECOARSETIME)) or (ret == ENOMONOTONIC)) or (ret == EMINVARVAR)) or (ret == ESTUCK)) or (ret == EHEALTH)) or (ret == ERCT)) or ((ret == EMEM) and (JENT_UT_SECURE_MEM_FORCED(flags) != 0)))) {
    _ = &ret;
    _ = &flags;
    return !(jent_ut_strict() != 0) and ((((((((ret == ENOTIME) or (ret == ECOARSETIME)) or (ret == ENOMONOTONIC)) or (ret == EMINVARVAR)) or (ret == ESTUCK)) or (ret == EHEALTH)) or (ret == ERCT)) or ((ret == EMEM) and (JENT_UT_SECURE_MEM_FORCED(flags) != 0)));
}
pub const JENT_UT_NO_COLLECTOR = @compileError("unable to translate macro: undefined identifier `_f`");
// tests/unit/unit.h:190:9
pub const _JITTERENTROPY_ARCH_COMPAT_H = "";
pub const _BSD_SOURCE = "";
pub const _JITTERENTROPY_INTERNAL_H = "";
pub const _JITTERENTROPY_ARCH_ATOMIC_H = "";
pub const _JITTERENTROPY_ARCH_TIMER_H = "";
pub const _JITTERENTROPY_ARCH_MEMORY_H = "";
pub const JENT_ARCH_MEM_POSIX_MLOCK = "";
pub const _JITTERENTROPY_ARCH_CACHE_H = "";
pub const _JITTERENTROPY_ARCH_NCPU_H = "";
pub const JENT_NCPU_SET_MAX = @as(c_uint, 1) << @as(c_int, 16);
pub const _JITTERENTROPY_ARCH_FIPS_H = "";
pub const JENT_ARCH_FIPS_PROC = "";
pub const _JITTERENTROPY_ARCH_SCHED_H = "";
pub const _JITTERENTROPY_ARCH_RANDOM_H = "";
pub const JENT_RANDOM_GETRANDOM = "";
pub const JENT_RANDOM_AVAILABLE = "";
pub const _JITTERENTROPY_UUID_H = "";
pub const JENT_FALLTHROUGH = @compileError("unable to translate macro: undefined identifier `__fallthrough__`");
// src/jitterentropy-internal.h:156:11
pub const JENT_NO_SANITIZE_ADDRESS = @compileError("unable to translate macro: undefined identifier `__no_sanitize_address__`");
// src/jitterentropy-internal.h:166:11
pub const JENT_INT_MEASURE_CLOCK = UINT32_C(@as(c_int, 1)) << @as(c_int, 22);
pub const JENT_BUILD_BUG_ON = @compileError("unable to translate C expr: expected ')' instead got '['");
// src/jitterentropy-internal.h:228:9
pub inline fn JENT_ARRAY_SIZE(x: anytype) @TypeOf(__helpers.div(__helpers.sizeof(x), __helpers.sizeof(x[@as(usize, @intCast(@as(c_int, 0)))]))) {
    _ = &x;
    return __helpers.div(__helpers.sizeof(x), __helpers.sizeof(x[@as(usize, @intCast(@as(c_int, 0)))]));
}
pub inline fn JENT_STUCK_INIT_THRES(x: anytype) @TypeOf(__helpers.div(x * @as(c_int, 9), @as(c_int, 10))) {
    _ = &x;
    return __helpers.div(x * @as(c_int, 9), @as(c_int, 10));
}
pub const JENT_HEALTH_LAG_PREDICTOR = "";
pub const JENT_RANDOM_MEMACCESS = "";
pub const JENT_APT_MASK = UINT64_C(__helpers.promoteIntLiteral(c_int, 0xffffffffffffffff, .hex));
pub const JENT_DEFAULT_MEMORY_BITS = @as(c_int, 18);
pub const JENT_CACHE_SHIFT_BITS = @as(c_int, 0);
pub const JENT_MAX_AUTO_MEMSIZE = JENT_FLAGS_TO_MAX_MEMSIZE(JENT_MAX_MEMSIZE_MAX);
pub const JENT_MEM_ACC_LOOP_DEFAULT = @as(c_int, 128);
pub const JENT_MEM_ACC_LOOP_INIT = @as(c_int, 3);
pub const JENT_HASH_LOOP_DEFAULT = @as(c_int, 1);
pub const JENT_HASH_LOOP_INIT = @as(c_int, 3);
pub const JENT_SHA3_256_SIZE_DIGEST_BITS = @as(c_int, 256);
pub const JENT_SHA3_256_SIZE_DIGEST = JENT_SHA3_256_SIZE_DIGEST_BITS >> @as(c_int, 3);
pub inline fn JENT_SHA3_SIZE_BLOCK(bits: anytype) @TypeOf((@as(c_int, 1600) - (@as(c_int, 2) * bits)) >> @as(c_int, 3)) {
    _ = &bits;
    return (@as(c_int, 1600) - (@as(c_int, 2) * bits)) >> @as(c_int, 3);
}
pub const JENT_SHA3_256_SIZE_BLOCK = JENT_SHA3_SIZE_BLOCK(JENT_SHA3_256_SIZE_DIGEST_BITS);
pub const JENT_XDRBG_SIZE_STATE = @as(c_int, 64);
pub const ENTROPY_SAFETY_FACTOR = @as(c_int, 64) + @as(c_int, 1);
pub const DATA_SIZE_BITS = JENT_SHA3_256_SIZE_DIGEST_BITS;
pub const JENT_MEMORY_BLOCKSIZE = @as(c_int, 128);
pub inline fn JENT_MEMORY_BLOCKS(ec: anytype) @TypeOf(__helpers.div(ec.*.memmask + @as(c_int, 1), JENT_MEMORY_BLOCKSIZE)) {
    _ = &ec;
    return __helpers.div(ec.*.memmask + @as(c_int, 1), JENT_MEMORY_BLOCKSIZE);
}
pub const JENT_APT_WINDOW_SIZE = @as(c_int, 512);
pub const JENT_LAG_WINDOW_SIZE = @as(c_uint, 1) << @as(c_int, 17);
pub const JENT_LAG_HISTORY_SIZE = @as(c_int, 8);
pub const JENT_LAG_MASK = JENT_LAG_HISTORY_SIZE - @as(c_int, 1);
pub const JITTERENTROPY_BASE_H = "";
pub const JITTERENTROPY_GCD_H = "";
pub const JENT_GCD_CLOCK_PLATFORM = @as(c_int, 0);
pub const JENT_GCD_CLOCK_NOTIME = @as(c_int, 1);
pub const JENT_GCD_CLOCKS = @as(c_int, 2);
pub const JENT_GCD_SELFTEST_ELEM = @as(c_int, 10);
pub const JENT_GCD_SELFTEST_EXP = @as(c_ulonglong, 3);
pub const jent_gcd_add_value = @compileError("unable to translate C expr: unexpected token '='");
// src/jitterentropy-gcd.h:68:9
pub const JITTERENTROPY_HEALTH_H = "";
pub inline fn JENT_HEALTH_RCT_INTERMITTENT_CUTOFF(x: anytype) @TypeOf(x * @as(c_int, 30)) {
    _ = &x;
    return x * @as(c_int, 30);
}
pub inline fn JENT_HEALTH_RCT_PERMANENT_CUTOFF(x: anytype) @TypeOf(x * @as(c_int, 60)) {
    _ = &x;
    return x * @as(c_int, 60);
}
pub const JENT_STUCK_PRIME = @as(c_int, 2);
pub const JITTERENTROPY_NOISE_H = "";
pub const JITTERENTROPY_TIMER_H = "";
pub const JITTERENTROPY_SHA3_H = "";
pub const JENT_SHA_MAX_CTX_SIZE = __helpers.sizeof(struct_jent_sha_ctx);
pub inline fn HASH_CTX_ON_STACK(name: anytype) @TypeOf(struct_jent_sha_ctx ++ name) {
    _ = &name;
    return struct_jent_sha_ctx ++ name;
}
pub const _JITTERENTROPY_ARCH_THREAD_H = "";
pub const _PTHREAD_H = @as(c_int, 1);
pub const _SCHED_H = @as(c_int, 1);
pub const _BITS_SCHED_H = @as(c_int, 1);
pub const SCHED_OTHER = @as(c_int, 0);
pub const SCHED_FIFO = @as(c_int, 1);
pub const SCHED_RR = @as(c_int, 2);
pub const SCHED_NORMAL = @as(c_int, 0);
pub const SCHED_BATCH = @as(c_int, 3);
pub const SCHED_ISO = @as(c_int, 4);
pub const SCHED_IDLE = @as(c_int, 5);
pub const SCHED_DEADLINE = @as(c_int, 6);
pub const SCHED_EXT = @as(c_int, 7);
pub const SCHED_RESET_ON_FORK = __helpers.promoteIntLiteral(c_int, 0x40000000, .hex);
pub const SCHED_FLAG_RESET_ON_FORK = @as(c_int, 0x01);
pub const SCHED_FLAG_RECLAIM = @as(c_int, 0x02);
pub const SCHED_FLAG_DL_OVERRUN = @as(c_int, 0x04);
pub const SCHED_FLAG_KEEP_POLICY = @as(c_int, 0x08);
pub const SCHED_FLAG_KEEP_PARAMS = @as(c_int, 0x10);
pub const SCHED_FLAG_UTIL_CLAMP_MIN = @as(c_int, 0x20);
pub const SCHED_FLAG_UTIL_CLAMP_MAX = @as(c_int, 0x40);
pub const SCHED_FLAG_KEEP_ALL = SCHED_FLAG_KEEP_POLICY | SCHED_FLAG_KEEP_PARAMS;
pub const SCHED_FLAG_UTIL_CLAMP = SCHED_FLAG_UTIL_CLAMP_MIN | SCHED_FLAG_UTIL_CLAMP_MAX;
pub const _LINUX_SCHED_TYPES_H = "";
pub const SCHED_ATTR_SIZE_VER0 = @as(c_int, 48);
pub const SCHED_ATTR_SIZE_VER1 = @as(c_int, 56);
pub const CSIGNAL = @as(c_int, 0x000000ff);
pub const CLONE_VM = @as(c_int, 0x00000100);
pub const CLONE_FS = @as(c_int, 0x00000200);
pub const CLONE_FILES = @as(c_int, 0x00000400);
pub const CLONE_SIGHAND = @as(c_int, 0x00000800);
pub const CLONE_PIDFD = @as(c_int, 0x00001000);
pub const CLONE_PTRACE = @as(c_int, 0x00002000);
pub const CLONE_VFORK = @as(c_int, 0x00004000);
pub const CLONE_PARENT = __helpers.promoteIntLiteral(c_int, 0x00008000, .hex);
pub const CLONE_THREAD = __helpers.promoteIntLiteral(c_int, 0x00010000, .hex);
pub const CLONE_NEWNS = __helpers.promoteIntLiteral(c_int, 0x00020000, .hex);
pub const CLONE_SYSVSEM = __helpers.promoteIntLiteral(c_int, 0x00040000, .hex);
pub const CLONE_SETTLS = __helpers.promoteIntLiteral(c_int, 0x00080000, .hex);
pub const CLONE_PARENT_SETTID = __helpers.promoteIntLiteral(c_int, 0x00100000, .hex);
pub const CLONE_CHILD_CLEARTID = __helpers.promoteIntLiteral(c_int, 0x00200000, .hex);
pub const CLONE_DETACHED = __helpers.promoteIntLiteral(c_int, 0x00400000, .hex);
pub const CLONE_UNTRACED = __helpers.promoteIntLiteral(c_int, 0x00800000, .hex);
pub const CLONE_CHILD_SETTID = __helpers.promoteIntLiteral(c_int, 0x01000000, .hex);
pub const CLONE_NEWCGROUP = __helpers.promoteIntLiteral(c_int, 0x02000000, .hex);
pub const CLONE_NEWUTS = __helpers.promoteIntLiteral(c_int, 0x04000000, .hex);
pub const CLONE_NEWIPC = __helpers.promoteIntLiteral(c_int, 0x08000000, .hex);
pub const CLONE_NEWUSER = __helpers.promoteIntLiteral(c_int, 0x10000000, .hex);
pub const CLONE_NEWPID = __helpers.promoteIntLiteral(c_int, 0x20000000, .hex);
pub const CLONE_NEWNET = __helpers.promoteIntLiteral(c_int, 0x40000000, .hex);
pub const CLONE_IO = __helpers.promoteIntLiteral(c_int, 0x80000000, .hex);
pub const CLONE_NEWTIME = @as(c_int, 0x00000080);
pub const _BITS_TYPES_STRUCT_SCHED_PARAM = @as(c_int, 1);
pub const _BITS_CPU_SET_H = @as(c_int, 1);
pub const __CPU_SETSIZE = @as(c_int, 1024);
pub const __NCPUBITS = @as(c_int, 8) * __helpers.sizeof(__cpu_mask);
pub inline fn __CPUELT(cpu: anytype) @TypeOf(__helpers.div(cpu, __NCPUBITS)) {
    _ = &cpu;
    return __helpers.div(cpu, __NCPUBITS);
}
pub inline fn __CPUMASK(cpu: anytype) @TypeOf(__helpers.cast(__cpu_mask, @as(c_int, 1)) << __helpers.rem(cpu, __NCPUBITS)) {
    _ = &cpu;
    return __helpers.cast(__cpu_mask, @as(c_int, 1)) << __helpers.rem(cpu, __NCPUBITS);
}
pub const __CPU_ZERO_S = @compileError("unable to translate C expr: unexpected token 'do'");
// /usr/include/aarch64-linux-gnu/bits/cpu-set.h:46:10
pub const __CPU_SET_S = @compileError("unable to translate macro: undefined identifier `__cpu`");
// /usr/include/aarch64-linux-gnu/bits/cpu-set.h:58:9
pub const __CPU_CLR_S = @compileError("unable to translate macro: undefined identifier `__cpu`");
// /usr/include/aarch64-linux-gnu/bits/cpu-set.h:65:9
pub const __CPU_ISSET_S = @compileError("unable to translate macro: undefined identifier `__cpu`");
// /usr/include/aarch64-linux-gnu/bits/cpu-set.h:72:9
pub inline fn __CPU_COUNT_S(setsize: anytype, cpusetp: anytype) @TypeOf(__sched_cpucount(setsize, cpusetp)) {
    _ = &setsize;
    _ = &cpusetp;
    return __sched_cpucount(setsize, cpusetp);
}
pub const __CPU_EQUAL_S = @compileError("unable to translate macro: undefined identifier `__builtin_memcmp`");
// /usr/include/aarch64-linux-gnu/bits/cpu-set.h:84:10
pub const __CPU_OP_S = @compileError("unable to translate macro: undefined identifier `__dest`");
// /usr/include/aarch64-linux-gnu/bits/cpu-set.h:99:9
pub inline fn __CPU_ALLOC_SIZE(count: anytype) @TypeOf(__helpers.div((count + __NCPUBITS) - @as(c_int, 1), __NCPUBITS) * __helpers.sizeof(__cpu_mask)) {
    _ = &count;
    return __helpers.div((count + __NCPUBITS) - @as(c_int, 1), __NCPUBITS) * __helpers.sizeof(__cpu_mask);
}
pub inline fn __CPU_ALLOC(count: anytype) @TypeOf(__sched_cpualloc(count)) {
    _ = &count;
    return __sched_cpualloc(count);
}
pub inline fn __CPU_FREE(cpuset: anytype) @TypeOf(__sched_cpufree(cpuset)) {
    _ = &cpuset;
    return __sched_cpufree(cpuset);
}
pub const sched_priority = @compileError("unable to translate macro: undefined identifier `sched_priority`");
// /usr/include/sched.h:47:9
pub const __sched_priority = sched_priority;
pub const CPU_SETSIZE = __CPU_SETSIZE;
pub inline fn CPU_SET(cpu: anytype, cpusetp: anytype) @TypeOf(__CPU_SET_S(cpu, __helpers.sizeof(cpu_set_t), cpusetp)) {
    _ = &cpu;
    _ = &cpusetp;
    return __CPU_SET_S(cpu, __helpers.sizeof(cpu_set_t), cpusetp);
}
pub inline fn CPU_CLR(cpu: anytype, cpusetp: anytype) @TypeOf(__CPU_CLR_S(cpu, __helpers.sizeof(cpu_set_t), cpusetp)) {
    _ = &cpu;
    _ = &cpusetp;
    return __CPU_CLR_S(cpu, __helpers.sizeof(cpu_set_t), cpusetp);
}
pub inline fn CPU_ISSET(cpu: anytype, cpusetp: anytype) @TypeOf(__CPU_ISSET_S(cpu, __helpers.sizeof(cpu_set_t), cpusetp)) {
    _ = &cpu;
    _ = &cpusetp;
    return __CPU_ISSET_S(cpu, __helpers.sizeof(cpu_set_t), cpusetp);
}
pub inline fn CPU_ZERO(cpusetp: anytype) @TypeOf(__CPU_ZERO_S(__helpers.sizeof(cpu_set_t), cpusetp)) {
    _ = &cpusetp;
    return __CPU_ZERO_S(__helpers.sizeof(cpu_set_t), cpusetp);
}
pub inline fn CPU_COUNT(cpusetp: anytype) @TypeOf(__CPU_COUNT_S(__helpers.sizeof(cpu_set_t), cpusetp)) {
    _ = &cpusetp;
    return __CPU_COUNT_S(__helpers.sizeof(cpu_set_t), cpusetp);
}
pub inline fn CPU_SET_S(cpu: anytype, setsize: anytype, cpusetp: anytype) @TypeOf(__CPU_SET_S(cpu, setsize, cpusetp)) {
    _ = &cpu;
    _ = &setsize;
    _ = &cpusetp;
    return __CPU_SET_S(cpu, setsize, cpusetp);
}
pub inline fn CPU_CLR_S(cpu: anytype, setsize: anytype, cpusetp: anytype) @TypeOf(__CPU_CLR_S(cpu, setsize, cpusetp)) {
    _ = &cpu;
    _ = &setsize;
    _ = &cpusetp;
    return __CPU_CLR_S(cpu, setsize, cpusetp);
}
pub inline fn CPU_ISSET_S(cpu: anytype, setsize: anytype, cpusetp: anytype) @TypeOf(__CPU_ISSET_S(cpu, setsize, cpusetp)) {
    _ = &cpu;
    _ = &setsize;
    _ = &cpusetp;
    return __CPU_ISSET_S(cpu, setsize, cpusetp);
}
pub inline fn CPU_ZERO_S(setsize: anytype, cpusetp: anytype) @TypeOf(__CPU_ZERO_S(setsize, cpusetp)) {
    _ = &setsize;
    _ = &cpusetp;
    return __CPU_ZERO_S(setsize, cpusetp);
}
pub inline fn CPU_COUNT_S(setsize: anytype, cpusetp: anytype) @TypeOf(__CPU_COUNT_S(setsize, cpusetp)) {
    _ = &setsize;
    _ = &cpusetp;
    return __CPU_COUNT_S(setsize, cpusetp);
}
pub inline fn CPU_EQUAL(cpusetp1: anytype, cpusetp2: anytype) @TypeOf(__CPU_EQUAL_S(__helpers.sizeof(cpu_set_t), cpusetp1, cpusetp2)) {
    _ = &cpusetp1;
    _ = &cpusetp2;
    return __CPU_EQUAL_S(__helpers.sizeof(cpu_set_t), cpusetp1, cpusetp2);
}
pub inline fn CPU_EQUAL_S(setsize: anytype, cpusetp1: anytype, cpusetp2: anytype) @TypeOf(__CPU_EQUAL_S(setsize, cpusetp1, cpusetp2)) {
    _ = &setsize;
    _ = &cpusetp1;
    _ = &cpusetp2;
    return __CPU_EQUAL_S(setsize, cpusetp1, cpusetp2);
}
pub const CPU_AND = @compileError("unable to translate C expr: unexpected token ')'");
// /usr/include/sched.h:111:10
pub const CPU_OR = @compileError("unable to translate C expr: unexpected token '|'");
// /usr/include/sched.h:113:10
pub const CPU_XOR = @compileError("unable to translate C expr: unexpected token '^'");
// /usr/include/sched.h:115:10
pub const CPU_AND_S = @compileError("unable to translate C expr: unexpected token ')'");
// /usr/include/sched.h:117:10
pub const CPU_OR_S = @compileError("unable to translate C expr: unexpected token '|'");
// /usr/include/sched.h:119:10
pub const CPU_XOR_S = @compileError("unable to translate C expr: unexpected token '^'");
// /usr/include/sched.h:121:10
pub inline fn CPU_ALLOC_SIZE(count: anytype) @TypeOf(__CPU_ALLOC_SIZE(count)) {
    _ = &count;
    return __CPU_ALLOC_SIZE(count);
}
pub inline fn CPU_ALLOC(count: anytype) @TypeOf(__CPU_ALLOC(count)) {
    _ = &count;
    return __CPU_ALLOC(count);
}
pub inline fn CPU_FREE(cpuset: anytype) @TypeOf(__CPU_FREE(cpuset)) {
    _ = &cpuset;
    return __CPU_FREE(cpuset);
}
pub const _BITS_SETJMP_H = @as(c_int, 1);
pub const __jmp_buf_tag_defined = @as(c_int, 1);
pub const PTHREAD_MUTEX_INITIALIZER = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/pthread.h:90:9
pub const PTHREAD_RECURSIVE_MUTEX_INITIALIZER_NP = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/pthread.h:93:10
pub const PTHREAD_ERRORCHECK_MUTEX_INITIALIZER_NP = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/pthread.h:95:10
pub const PTHREAD_ADAPTIVE_MUTEX_INITIALIZER_NP = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/pthread.h:97:10
pub const PTHREAD_RWLOCK_INITIALIZER = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/pthread.h:114:10
pub const PTHREAD_RWLOCK_WRITER_NONRECURSIVE_INITIALIZER_NP = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/pthread.h:117:11
pub const PTHREAD_COND_INITIALIZER = @compileError("unable to translate C expr: unexpected token '{'");
// /usr/include/pthread.h:155:9
pub const PTHREAD_CANCELED = __helpers.cast(?*anyopaque, -@as(c_int, 1));
pub const PTHREAD_ONCE_INIT = @as(c_int, 0);
pub const PTHREAD_BARRIER_SERIAL_THREAD = -@as(c_int, 1);
pub const PTHREAD_ATTR_NO_SIGMASK_NP = -@as(c_int, 1);
pub const __cleanup_fct_attribute = "";
pub const pthread_cleanup_push = @compileError("unable to translate macro: undefined identifier `__cancel_buf`");
// /usr/include/pthread.h:681:10
pub const pthread_cleanup_pop = @compileError("unable to translate macro: undefined identifier `__cancel_buf`");
// /usr/include/pthread.h:702:10
pub const pthread_cleanup_push_defer_np = @compileError("unable to translate macro: undefined identifier `__cancel_buf`");
// /usr/include/pthread.h:716:11
pub const pthread_cleanup_pop_restore_np = @compileError("unable to translate macro: undefined identifier `__cancel_buf`");
// /usr/include/pthread.h:738:11
pub inline fn __sigsetjmp_cancel(env: anytype, savemask: anytype) @TypeOf(__sigsetjmp(__helpers.cast([*c]struct___jmp_buf_tag, __helpers.cast(?*anyopaque, env)), savemask)) {
    _ = &env;
    _ = &savemask;
    return __sigsetjmp(__helpers.cast([*c]struct___jmp_buf_tag, __helpers.cast(?*anyopaque, env)), savemask);
}
pub const UT_MIN_THREADS = @as(c_int, 4);
pub const UT_MAX_THREADS = @as(c_int, 8);
pub const UT_ROUNDS = @as(c_int, 3);
pub const UT_BLOCK = @as(c_int, 32);
pub const UT_REGISTRATIONS = @as(c_int, 16);
pub const UT_OSR_NOTIME = @as(c_int, 3);
pub const UT_OSR_TIMER = @as(c_int, 5);
pub const UT_NOTIME_ROUNDS = @as(c_int, 2);
pub const UT_TIMER_MAX_ROUNDS = @as(c_int, 4096);
pub const UT_FIRST_ALLOC_ROUNDS = @as(c_int, 8);
pub const timeval = struct_timeval;
pub const timex = struct_timex;
pub const tm = struct_tm;
pub const timespec = struct_timespec;
pub const itimerspec = struct_itimerspec;
pub const sigevent = struct_sigevent;
pub const __locale_struct = struct___locale_struct;
pub const _G_fpos_t = struct__G_fpos_t;
pub const _G_fpos64_t = struct__G_fpos64_t;
pub const _IO_marker = struct__IO_marker;
pub const _IO_FILE = struct__IO_FILE;
pub const _IO_codecvt = struct__IO_codecvt;
pub const _IO_wide_data = struct__IO_wide_data;
pub const _IO_cookie_io_functions_t = struct__IO_cookie_io_functions_t;
pub const obstack = struct_obstack;
pub const __pthread_internal_list = struct___pthread_internal_list;
pub const __pthread_internal_slist = struct___pthread_internal_slist;
pub const __pthread_mutex_s = struct___pthread_mutex_s;
pub const __pthread_rwlock_arch_t = struct___pthread_rwlock_arch_t;
pub const __pthread_cond_s = struct___pthread_cond_s;
pub const random_data = struct_random_data;
pub const drand48_data = struct_drand48_data;
pub const statx_timestamp = struct_statx_timestamp;
pub const flock = struct_flock;
pub const flock64 = struct_flock64;
pub const iovec = struct_iovec;
pub const __pid_type = enum___pid_type;
pub const f_owner_ex = struct_f_owner_ex;
pub const file_handle = struct_file_handle;
pub const open_how = struct_open_how;
pub const jent_sha_ctx = struct_jent_sha_ctx;
pub const rand_data = struct_rand_data;
pub const jent_notime_thread = struct_jent_notime_thread;
pub const __itimer_which = enum___itimer_which;
pub const itimerval = struct_itimerval;
pub const __rlimit_resource = enum___rlimit_resource;
pub const rlimit = struct_rlimit;
pub const rlimit64 = struct_rlimit64;
pub const __rusage_who = enum___rusage_who;
pub const rusage = struct_rusage;
pub const __priority_which = enum___priority_which;
pub const jent_startup_state = enum_jent_startup_state;
pub const jent_health_init_type = enum_jent_health_init_type;
pub const sched_attr = struct_sched_attr;
pub const sched_param = struct_sched_param;
pub const __jmp_buf_tag = struct___jmp_buf_tag;
pub const _pthread_cleanup_buffer = struct__pthread_cleanup_buffer;
pub const __cancel_jmp_buf_tag = struct___cancel_jmp_buf_tag;
pub const __pthread_cleanup_frame = struct___pthread_cleanup_frame;
pub const ut_worker = struct_ut_worker;
