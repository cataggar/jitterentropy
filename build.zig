const std = @import("std");

const jitterentropy_version = std.SemanticVersion{
    .major = 3,
    .minor = 8,
    .patch = 0,
};

const lib_c_sources: []const []const u8 = &.{
    "src/jitterentropy-base.c",
    "src/jitterentropy-gcd.c",
    "src/jitterentropy-health.c",
    "src/jitterentropy-noise.c",
    "src/jitterentropy-sha3.c",
    "src/jitterentropy-status.c",
    "src/jitterentropy-timer.c",
    "src/jitterentropy-uuid.c",
    "arch/jitterentropy-arch-atomic.c",
    "arch/jitterentropy-arch-cache.c",
    "arch/jitterentropy-arch-fips.c",
    "arch/jitterentropy-arch-memory.c",
    "arch/jitterentropy-arch-ncpu.c",
    "arch/jitterentropy-arch-random.c",
    "arch/jitterentropy-arch-sched.c",
    "arch/jitterentropy-arch-thread.c",
    "arch/jitterentropy-arch-timer.c",
};

const unit_test_names: []const []const u8 = &.{
    "unit-sha3",
    "unit-gcd",
    "unit-arch-cache",
    "unit-arch-fips",
    "unit-arch-memory",
    "unit-arch-ncpu",
    "unit-arch-sched",
    "unit-arch-timer",
    "unit-uuid",
    "unit-base-api",
    "unit-base-config",
    "unit-base-gen",
    "unit-error",
    "unit-fault",
    "unit-notime",
    "unit-concurrency",
    "unit-zeroize",
};

const mock_unit_test_names: []const []const u8 = &.{
    "unit-mock",
    "unit-noise",
};

const BuildOptions = struct {
    internal_timer: bool,
    mock_timer: bool,
    stack_protector: bool,
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const linkage = b.option(
        std.builtin.LinkMode,
        "linkage",
        "Library linkage mode (default: static)",
    ) orelse .static;

    const internal_timer = b.option(
        bool,
        "internal-timer",
        "Compile with the internal thread-based timer (default: true)",
    ) orelse true;

    const mock_timer = b.option(
        bool,
        "mock-timer",
        "Allow the time source to be replaced by a caller-supplied callback (for testing only, default: false)",
    ) orelse false;

    const stack_protector = b.option(
        bool,
        "stack-protector",
        "Compile with stack protector enabled (default: true)",
    ) orelse true;

    const enable_tools = b.option(
        bool,
        "tools",
        "Build and install the recording and validation tools (default: true)",
    ) orelse true;

    const enable_recording = b.option(
        bool,
        "recording",
        "Also build and install libjitterentropy-record (default: false)",
    ) orelse false;

    const enable_kernel_lib = b.option(
        bool,
        "kernel-lib",
        "Also build and install libjitterentropy-kernel and jitter_rng (Linux only, default: false)",
    ) orelse false;

    const enable_rngd = b.option(
        bool,
        "rngd",
        "Also build and install jitterentropy-rngd (Linux only, default: false)",
    ) orelse false;

    const rngd_sbindir = b.option(
        []const u8,
        "rngd-sbindir",
        "Path to sbin directory in jitterentropy.service ExecStart (default: /usr/local/sbin)",
    ) orelse "/usr/local/sbin";

    const raw_memory_access = b.option(
        bool,
        "raw-memory-access",
        "Build jitterentropy-hashtime to measure raw memory access instead of SHA3 hash loop (default: false)",
    ) orelse false;

    const opts = BuildOptions{
        .internal_timer = internal_timer,
        .mock_timer = mock_timer,
        .stack_protector = stack_protector,
    };

    const os_tag = target.result.os.tag;
    const c_flags = getCFlags(b, target, opts, &.{}) catch @panic("OOM");

    const lib_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .pic = if (os_tag == .windows) null else true,
    });
    configureIncludePaths(b, lib_mod);
    configureCommonDefines(lib_mod, target, opts, linkage);
    configureSystemLibraries(lib_mod, target, opts);
    lib_mod.addCSourceFiles(.{
        .files = lib_c_sources,
        .flags = c_flags,
    });

    const lib = b.addLibrary(.{
        .name = "jitterentropy",
        .linkage = linkage,
        .version = jitterentropy_version,
        .root_module = lib_mod,
    });
    if (linkage == .dynamic and os_tag != .windows and !os_tag.isDarwin()) {
        lib.setVersionScript(b.path("version.lds"));
    }
    lib.installHeader(b.path("jitterentropy.h"), "jitterentropy.h");
    b.installArtifact(lib);

    const lib_manpages: []const []const u8 = &.{
        "jitterentropy.3",
        "jent_entropy_collector_alloc.3",
        "jent_entropy_init.3",
        "jent_entropy_switch_notime_impl.3",
        "jent_read_entropy.3",
        "jent_set_fips_failure_callback.3",
        "jent_status.3",
    };
    for (lib_manpages) |page| {
        const src_page = std.fmt.allocPrint(b.allocator, "doc/{s}", .{page}) catch @panic("OOM");
        const dest_page = std.fmt.allocPrint(b.allocator, "share/man/man3/{s}", .{page}) catch @panic("OOM");
        b.installFile(src_page, dest_page);
    }
    if (os_tag == .linux) {
        b.installFile("doc/jitter_rng.4", "share/man/man4/jitter_rng.4");
    }

    const test_step = b.step("test", "Run jitterentropy test suite");

    if (enable_recording) {
        const rec_mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .pic = if (os_tag == .windows) null else true,
        });
        configureIncludePaths(b, rec_mod);
        rec_mod.addIncludePath(b.path("tests/raw-entropy/recording_library"));
        configureCommonDefines(rec_mod, target, opts, linkage);
        if (os_tag == .windows) {
            if (linkage == .dynamic) {
                rec_mod.addCMacro("JENT_RECORD_BUILDING_DLL", "1");
            } else {
                rec_mod.addCMacro("JENT_RECORD_STATIC_LIB", "1");
            }
        }
        configureSystemLibraries(rec_mod, target, opts);
        rec_mod.addCSourceFile(.{
            .file = b.path("tests/raw-entropy/recording_library/jitterentropy-record-lib.c"),
            .flags = c_flags,
        });

        const rec_lib = b.addLibrary(.{
            .name = "jitterentropy-record",
            .linkage = linkage,
            .version = jitterentropy_version,
            .root_module = rec_mod,
        });
        if (linkage == .dynamic and os_tag != .windows and !os_tag.isDarwin()) {
            rec_lib.setVersionScript(b.path("tests/raw-entropy/recording_library/record.lds"));
        }
        rec_lib.installHeader(
            b.path("tests/raw-entropy/recording_library/jitterentropy-record.h"),
            "jitterentropy-record.h",
        );
        b.installArtifact(rec_lib);
        b.installFile(
            "doc/jitterentropy-record.3",
            "share/man/man3/jitterentropy-record.3",
        );

        const colink_mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        configureIncludePaths(b, colink_mod);
        colink_mod.addIncludePath(b.path("tests/raw-entropy/recording_library"));
        configureCommonDefines(colink_mod, target, opts, linkage);
        if (os_tag == .windows and linkage == .static) {
            colink_mod.addCMacro("JENT_RECORD_STATIC_LIB", "1");
        }
        colink_mod.addCSourceFile(.{
            .file = b.path("tests/raw-entropy/recording_library/record-colink.c"),
            .flags = c_flags,
        });
        colink_mod.linkLibrary(lib);
        colink_mod.linkLibrary(rec_lib);
        const colink_exe = b.addExecutable(.{
            .name = "record-colink",
            .root_module = colink_mod,
        });
        const colink_wf = b.addWriteFiles();
        _ = colink_wf.add(".keep", "");
        const run_colink = b.addRunArtifact(colink_exe);
        run_colink.setCwd(colink_wf.getDirectory());
        run_colink.addArg("record-colink");
        run_colink.expectExitCode(0);
        test_step.dependOn(&run_colink.step);
    }

    if (enable_kernel_lib) {
        if (os_tag != .linux) {
            std.debug.panic("-Dkernel-lib=true requires a Linux target", .{});
        }
        const kern_mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .pic = true,
        });
        kern_mod.addIncludePath(b.path("linux_kernel/userspace"));
        kern_mod.addIncludePath(b.path("linux_kernel"));
        kern_mod.addCSourceFile(.{
            .file = b.path("linux_kernel/userspace/jitterentropy-kernel.c"),
            .flags = c_flags,
        });

        const kern_lib = b.addLibrary(.{
            .name = "jitterentropy-kernel",
            .linkage = linkage,
            .version = jitterentropy_version,
            .root_module = kern_mod,
        });
        if (linkage == .dynamic) {
            kern_lib.setVersionScript(b.path("linux_kernel/userspace/kernel.lds"));
        }
        kern_lib.installHeader(
            b.path("linux_kernel/userspace/jitterentropy-kernel.h"),
            "jitterentropy-kernel.h",
        );
        kern_lib.installHeader(
            b.path("linux_kernel/jitterentropy_uapi.h"),
            "jitterentropy_uapi.h",
        );
        b.installArtifact(kern_lib);

        const jitter_rng_mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        jitter_rng_mod.addIncludePath(b.path("linux_kernel/userspace"));
        jitter_rng_mod.addIncludePath(b.path("linux_kernel"));
        jitter_rng_mod.addCSourceFile(.{
            .file = b.path("linux_kernel/userspace/jitter_rng.c"),
            .flags = c_flags,
        });
        jitter_rng_mod.linkLibrary(kern_lib);

        const jitter_rng_exe = b.addExecutable(.{
            .name = "jitter_rng",
            .root_module = jitter_rng_mod,
        });
        b.installArtifact(jitter_rng_exe);
        b.installFile(
            "doc/jitterentropy-kernel.3",
            "share/man/man3/jitterentropy-kernel.3",
        );
        b.installFile(
            "doc/jitter_rng.1",
            "share/man/man1/jitter_rng.1",
        );
    }

    if (enable_rngd) {
        if (os_tag != .linux) {
            std.debug.panic("-Drngd=true requires a Linux target", .{});
        }
        const rngd_mod = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        configureIncludePaths(b, rngd_mod);
        configureCommonDefines(rngd_mod, target, opts, linkage);
        rngd_mod.addCSourceFile(.{
            .file = b.path("rngd/jitterentropy-rngd.c"),
            .flags = c_flags,
        });
        rngd_mod.linkLibrary(lib);

        const rngd_exe = b.addExecutable(.{
            .name = "jitterentropy-rngd",
            .root_module = rngd_mod,
        });
        const install_rngd = b.addInstallArtifact(rngd_exe, .{
            .dest_dir = .{ .override = .{ .custom = "sbin" } },
        });
        b.getInstallStep().dependOn(&install_rngd.step);
        b.installFile(
            "doc/jitterentropy-rngd.1",
            "share/man/man1/jitterentropy-rngd.1",
        );

        const service_template = @embedFile("rngd/jitterentropy.service.in");
        const service_rendered = std.mem.replaceOwned(
            u8,
            b.allocator,
            service_template,
            "@PATH@",
            rngd_sbindir,
        ) catch @panic("OOM");
        const rngd_wf = b.addWriteFiles();
        const service_file = rngd_wf.add("jitterentropy.service", service_rendered);
        b.getInstallStep().dependOn(
            &b.addInstallFile(service_file, "lib/systemd/system/jitterentropy.service").step,
        );

        const run_rngd_ver = b.addRunArtifact(rngd_exe);
        run_rngd_ver.addArg("--version");
        run_rngd_ver.expectExitCode(0);
        run_rngd_ver.expectStdErrEqual(
            "Version jitterentropy-rngd 3.8.0\nVersion Jitterentropy Core 3080000\n",
        );
        test_step.dependOn(&run_rngd_ver.step);
    }

    const gcd_exe = addAbsorbingExecutable(b, "gcd", target, optimize, opts, c_flags, &.{
        "tests/gcd/gcd.c",
        "src/jitterentropy-gcd.c",
        "arch/jitterentropy-arch-memory.c",
        "arch/jitterentropy-arch-atomic.c",
    }, false, false);

    const health_exe = addAbsorbingExecutable(b, "jitterentropy-health", target, optimize, opts, c_flags, &.{
        "tests/health/health.c",
    }, false, false);

    const flags_exe = addToolExecutable(
        b,
        "jitterentropy-flags",
        "tests/raw-entropy/recording_userspace/jitterentropy-flags.c",
        target,
        optimize,
        opts,
        linkage,
        c_flags,
        null,
        false,
    );

    const cpuinfo_mod = b.createModule(.{
        .root_source_file = b.path("tests/raw-entropy/recording_userspace/jitterentropy-cpuinfo.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    if (os_tag == .windows) {
        cpuinfo_mod.linkSystemLibrary("advapi32", .{});
    }
    const cpuinfo_exe = b.addExecutable(.{
        .name = "jitterentropy-cpuinfo",
        .root_module = cpuinfo_mod,
    });

    if (enable_tools) {
        b.installArtifact(gcd_exe);
        b.installArtifact(health_exe);
        b.installArtifact(flags_exe);
        b.installArtifact(cpuinfo_exe);

        const rng_exe = addToolExecutable(
            b,
            "jitterentropy-rng",
            "tests/raw-entropy/recording_userspace/jitterentropy-rng.c",
            target,
            optimize,
            opts,
            linkage,
            c_flags,
            lib,
            os_tag != .windows,
        );
        b.installArtifact(rng_exe);

        const osr_exe = addToolExecutable(
            b,
            "jitterentropy-osr",
            "tests/raw-entropy/recording_userspace/jitterentropy-osr.c",
            target,
            optimize,
            opts,
            linkage,
            c_flags,
            lib,
            os_tag != .windows,
        );
        b.installArtifact(osr_exe);

        const hashtime_exe = addAbsorbingExecutable(
            b,
            "jitterentropy-hashtime",
            target,
            optimize,
            opts,
            c_flags,
            &.{"tests/raw-entropy/recording_userspace/jitterentropy-hashtime.c"},
            true,
            os_tag != .windows,
        );
        if (raw_memory_access) {
            hashtime_exe.root_module.addCMacro("JENT_TEST_MEASURE_RAW_MEMORY_ACCESS", "1");
        }
        b.installArtifact(hashtime_exe);

        const tool_manpages: []const []const u8 = &.{
            "jitterentropy-rng.1",
            "jitterentropy-osr.1",
            "jitterentropy-hashtime.1",
            "jitterentropy-flags.1",
        };
        for (tool_manpages) |page| {
            const src_page = std.fmt.allocPrint(b.allocator, "doc/{s}", .{page}) catch @panic("OOM");
            const dest_page = std.fmt.allocPrint(b.allocator, "share/man/man1/{s}", .{page}) catch @panic("OOM");
            b.installFile(src_page, dest_page);
        }

        const extractlsb_exe = addToolExecutable(
            b,
            "extractlsb",
            "tests/raw-entropy/extractlsb.c",
            target,
            optimize,
            opts,
            linkage,
            c_flags,
            null,
            false,
        );
        b.installArtifact(extractlsb_exe);

        if (os_tag == .linux) {
            const getraw_mod = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            });
            getraw_mod.addIncludePath(b.path("."));
            getraw_mod.addIncludePath(b.path("linux_kernel"));
            getraw_mod.addCMacro("RAW_DATATYPE_U64", "1");
            getraw_mod.addCSourceFile(.{
                .file = b.path("tests/raw-entropy/recording_runtime_kernelspace/getrawentropy.c"),
                .flags = c_flags,
            });
            const getraw_exe = b.addExecutable(.{
                .name = "getrawentropy",
                .root_module = getraw_mod,
            });
            b.installArtifact(getraw_exe);

            const status_mod = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            });
            status_mod.addIncludePath(b.path("linux_kernel"));
            status_mod.addCSourceFile(.{
                .file = b.path("tests/chardev/jitterentropy-chardev-status.c"),
                .flags = c_flags,
            });
            const status_exe = b.addExecutable(.{
                .name = "jitterentropy-chardev-status",
                .root_module = status_mod,
            });
            b.installArtifact(status_exe);

            const fields_mod = b.createModule(.{
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            });
            fields_mod.addIncludePath(b.path("."));
            fields_mod.addIncludePath(b.path("linux_kernel"));
            fields_mod.addCSourceFile(.{
                .file = b.path("tests/chardev/jitterentropy-chardev-fields.c"),
                .flags = c_flags,
            });
            const fields_exe = b.addExecutable(.{
                .name = "jitterentropy-chardev-fields",
                .root_module = fields_mod,
            });
            b.installArtifact(fields_exe);
        }
    }

    const run_gcd = b.addRunArtifact(gcd_exe);
    run_gcd.expectExitCode(0);
    test_step.dependOn(&run_gcd.step);

    var osr: u32 = 3;
    while (osr <= 20) : (osr += 1) {
        const run_health = b.addRunArtifact(health_exe);
        run_health.addArg(std.fmt.allocPrint(b.allocator, "{d}", .{osr}) catch @panic("OOM"));
        run_health.expectExitCode(0);
        test_step.dependOn(&run_health.step);
    }

    const health_failure_vectors: []const []const u8 = &.{
        "tests/health/testdata/rct-intermittent.txt",
        "tests/health/testdata/rct-permanent.txt",
        "tests/health/testdata/lag-intermittent.txt",
        "tests/health/testdata/lag-permanent.txt",
        "tests/health/testdata/apt-intermittent.txt",
        "tests/health/testdata/apt-permanent.txt",
    };
    for (health_failure_vectors) |vec_path| {
        const run_health_vec = b.addRunArtifact(health_exe);
        run_health_vec.addArg("--replay");
        run_health_vec.addFileArg(b.path(vec_path));
        run_health_vec.expectExitCode(1);
        test_step.dependOn(&run_health_vec.step);
    }

    const run_health_clean = b.addRunArtifact(health_exe);
    run_health_clean.addArg("--replay");
    run_health_clean.addFileArg(b.path("tests/health/testdata/no-failure.txt"));
    run_health_clean.expectExitCode(0);
    test_step.dependOn(&run_health_clean.step);

    const run_flags_encode = b.addRunArtifact(flags_exe);
    run_flags_encode.addArgs(&.{ "ntg1", "JENT_MAX_MEMSIZE_1MB", "--hloopcnt", "4" });
    run_flags_encode.expectStdOutEqual("1518338112\n");
    test_step.dependOn(&run_flags_encode.step);

    const run_flags_mixed = b.addRunArtifact(flags_exe);
    run_flags_mixed.addArg("JeNt_NtG1");
    run_flags_mixed.expectStdOutEqual("64\n");
    test_step.dependOn(&run_flags_mixed.step);

    const cpuinfo_unit_mod = b.createModule(.{
        .root_source_file = b.path("tests/raw-entropy/recording_userspace/jitterentropy-cpuinfo.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    if (os_tag == .windows) {
        cpuinfo_unit_mod.linkSystemLibrary("advapi32", .{});
    }
    const cpuinfo_unit_tests = b.addTest(.{
        .root_module = cpuinfo_unit_mod,
    });
    const run_cpuinfo_unit_tests = b.addRunArtifact(cpuinfo_unit_tests);
    test_step.dependOn(&run_cpuinfo_unit_tests.step);

    const run_cpuinfo = b.addRunArtifact(cpuinfo_exe);
    run_cpuinfo.expectExitCode(0);
    test_step.dependOn(&run_cpuinfo.step);

    const run_cpuinfo_summary = b.addRunArtifact(cpuinfo_exe);
    run_cpuinfo_summary.addArg("--summary");
    run_cpuinfo_summary.expectExitCode(0);
    test_step.dependOn(&run_cpuinfo_summary.step);

    const run_cpuinfo_json = b.addRunArtifact(cpuinfo_exe);
    run_cpuinfo_json.addArg("--json");
    run_cpuinfo_json.expectExitCode(0);
    test_step.dependOn(&run_cpuinfo_json.step);

    const run_cpuinfo_help = b.addRunArtifact(cpuinfo_exe);
    run_cpuinfo_help.addArg("--help");
    run_cpuinfo_help.expectExitCode(0);
    test_step.dependOn(&run_cpuinfo_help.step);

    const FlagsFailCase = struct {
        args: []const []const u8,
        stderr: []const u8,
    };
    const flags_fail_cases: []const FlagsFailCase = &.{
        .{
            .args = &.{ "--decode", "0x200" },
            .stderr = "refused: reserved bits 0x00000200 set\n",
        },
        .{
            .args = &.{ "--ntg1", "--force-internal-timer" },
            .stderr = "refused: JENT_FORCE_INTERNAL_TIMER with JENT_NTG1\n",
        },
        .{
            .args = &.{ "JENT_HASHLOOP_1", "JENT_HASHLOOP_2" },
            .stderr = "JENT_HASHLOOP_2: field already set\n",
        },
    };
    for (flags_fail_cases) |case| {
        const run_flags_fail = b.addRunArtifact(flags_exe);
        run_flags_fail.addArgs(case.args);
        run_flags_fail.expectExitCode(1);
        run_flags_fail.expectStdErrEqual(case.stderr);
        test_step.dependOn(&run_flags_fail.step);
    }

    for (unit_test_names) |ut_name| {
        const ut_exe = addUnitTestExecutable(b, ut_name, target, optimize, opts, c_flags, false);
        const run_ut = b.addRunArtifact(ut_exe);
        run_ut.expectExitCode(0);
        test_step.dependOn(&run_ut.step);
    }

    if (os_tag == .linux) {
        const ut_kern = addUnitTestExecutable(b, "unit-kernel-lib", target, optimize, opts, c_flags, false);
        const run_ut_kern = b.addRunArtifact(ut_kern);
        run_ut_kern.expectExitCode(0);
        test_step.dependOn(&run_ut_kern.step);
    }

    for (mock_unit_test_names) |ut_name| {
        const ut_exe = addUnitTestExecutable(b, ut_name, target, optimize, opts, c_flags, true);
        const run_ut = b.addRunArtifact(ut_exe);
        run_ut.expectExitCode(0);
        test_step.dependOn(&run_ut.step);
    }

    const fuzz_api_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    configureIncludePaths(b, fuzz_api_mod);
    configureCommonDefines(fuzz_api_mod, target, opts, linkage);
    fuzz_api_mod.addCMacro("JENT_FUZZ_STANDALONE", "1");
    fuzz_api_mod.addCSourceFile(.{
        .file = b.path("tests/fuzz/fuzz-api.c"),
        .flags = c_flags,
    });
    fuzz_api_mod.linkLibrary(lib);
    const fuzz_api_exe = b.addExecutable(.{
        .name = "fuzz-api-standalone",
        .root_module = fuzz_api_mod,
    });
    const run_fuzz_api = b.addRunArtifact(fuzz_api_exe);
    run_fuzz_api.expectExitCode(0);
    test_step.dependOn(&run_fuzz_api.step);

    const fuzz_health_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    configureIncludePaths(b, fuzz_health_mod);
    configureCommonDefines(fuzz_health_mod, target, opts, .static);
    fuzz_health_mod.addCMacro("JENT_FUZZ_STANDALONE", "1");
    fuzz_health_mod.addCSourceFile(.{
        .file = b.path("tests/fuzz/fuzz-health.c"),
        .flags = c_flags,
    });
    const fuzz_health_exe = b.addExecutable(.{
        .name = "fuzz-health-standalone",
        .root_module = fuzz_health_mod,
    });
    const run_fuzz_health = b.addRunArtifact(fuzz_health_exe);
    run_fuzz_health.expectExitCode(0);
    test_step.dependOn(&run_fuzz_health.step);

    const linktest_mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    configureCommonDefines(linktest_mod, target, opts, linkage);
    linktest_mod.addCSourceFile(.{
        .file = b.path("tests/linking/jitterentropy-linktest.c"),
        .flags = c_flags,
    });
    linktest_mod.linkLibrary(lib);
    const linktest_exe = b.addExecutable(.{
        .name = "jitterentropy-linktest",
        .root_module = linktest_mod,
    });
    const run_linktest = b.addRunArtifact(linktest_exe);
    run_linktest.expectExitCode(0);
    test_step.dependOn(&run_linktest.step);
}

fn configureIncludePaths(b: *std.Build, mod: *std.Build.Module) void {
    mod.addIncludePath(b.path("."));
    mod.addIncludePath(b.path("src"));
    mod.addIncludePath(b.path("arch"));
}

fn configureCommonDefines(
    mod: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    opts: BuildOptions,
    linkage: std.builtin.LinkMode,
) void {
    if (opts.internal_timer) {
        mod.addCMacro("JENT_CONF_ENABLE_INTERNAL_TIMER", "1");
    }
    if (opts.mock_timer) {
        mod.addCMacro("JENT_CONF_ENABLE_MOCK_TIMER", "1");
    }
    if (target.result.os.tag == .haiku) {
        mod.addCMacro("B_USE_POSITIVE_POSIX_ERRORS", "1");
    }
    if (target.result.os.tag == .windows) {
        if (linkage == .dynamic) {
            mod.addCMacro("JENT_BUILDING_DLL", "1");
        } else {
            mod.addCMacro("JENT_STATIC_LIB", "1");
        }
    }
}

fn configureSystemLibraries(
    mod: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    opts: BuildOptions,
) void {
    const os_tag = target.result.os.tag;
    if (os_tag == .windows) {
        mod.linkSystemLibrary("bcrypt", .{});
    } else if (opts.internal_timer and !target.result.abi.isAndroid() and os_tag != .freebsd) {
        mod.linkSystemLibrary("pthread", .{});
    }
}

fn addAbsorbingExecutable(
    b: *std.Build,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    opts: BuildOptions,
    c_flags: []const []const u8,
    files: []const []const u8,
    needs_system_libs: bool,
    needs_libm: bool,
) *std.Build.Step.Compile {
    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    configureIncludePaths(b, mod);
    mod.addIncludePath(b.path("tests"));
    configureCommonDefines(mod, target, opts, .static);
    mod.addCMacro("JENT_STATIC_LIB", "1");
    if (needs_system_libs) {
        configureSystemLibraries(mod, target, opts);
    }
    if (needs_libm) {
        mod.linkSystemLibrary("m", .{});
    }
    mod.addCSourceFiles(.{
        .files = files,
        .flags = c_flags,
    });
    return b.addExecutable(.{
        .name = name,
        .root_module = mod,
    });
}

fn addToolExecutable(
    b: *std.Build,
    name: []const u8,
    src_path: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    opts: BuildOptions,
    linkage: std.builtin.LinkMode,
    c_flags: []const []const u8,
    lib: ?*std.Build.Step.Compile,
    needs_libm: bool,
) *std.Build.Step.Compile {
    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    configureIncludePaths(b, mod);
    mod.addIncludePath(b.path("tests"));
    configureCommonDefines(mod, target, opts, linkage);
    if (lib) |l| {
        mod.linkLibrary(l);
    }
    if (needs_libm) {
        mod.linkSystemLibrary("m", .{});
    }
    mod.addCSourceFile(.{
        .file = b.path(src_path),
        .flags = c_flags,
    });
    return b.addExecutable(.{
        .name = name,
        .root_module = mod,
    });
}

fn addUnitTestExecutable(
    b: *std.Build,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    opts: BuildOptions,
    c_flags: []const []const u8,
    enable_mock_timer: bool,
) *std.Build.Step.Compile {
    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    configureIncludePaths(b, mod);
    mod.addIncludePath(b.path("tests"));
    configureCommonDefines(mod, target, opts, .static);
    mod.addCMacro("JENT_STATIC_LIB", "1");
    if (enable_mock_timer) {
        mod.addCMacro("JENT_CONF_ENABLE_MOCK_TIMER", "1");
    }
    configureSystemLibraries(mod, target, opts);
    const src_rel = std.fmt.allocPrint(b.allocator, "tests/unit/{s}.c", .{name}) catch @panic("OOM");
    mod.addCSourceFile(.{
        .file = b.path(src_rel),
        .flags = c_flags,
    });
    return b.addExecutable(.{
        .name = name,
        .root_module = mod,
    });
}

fn getCFlags(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    opts: BuildOptions,
    extra: []const []const u8,
) ![]const []const u8 {
    var list: std.ArrayListUnmanaged([]const u8) = .empty;
    // -O0 is mandatory: the entropy collection core refuses to compile with __OPTIMIZE__
    try list.appendSlice(b.allocator, &.{
        "-std=gnu11",
        "-O0",
        "-fwrapv",
        "-fvisibility=hidden",
        "-Wall",
        "-Wextra",
        "-pedantic",
        "-Wcast-align",
        "-Wmissing-field-initializers",
        "-Wshadow",
        "-Wswitch-enum",
        "-Wconversion",
    });

    const os_tag = target.result.os.tag;
    const arch = target.result.cpu.arch;
    if (opts.stack_protector and os_tag != .haiku) {
        try list.appendSlice(b.allocator, &.{
            "-fstack-protector-strong",
            "--param",
            "ssp-buffer-size=4",
        });
    }
    if (arch == .x86_64 or arch == .x86 or arch == .aarch64) {
        try list.append(b.allocator, "-fzero-call-used-regs=used");
    }
    try list.appendSlice(b.allocator, extra);
    return list.toOwnedSlice(b.allocator);
}
