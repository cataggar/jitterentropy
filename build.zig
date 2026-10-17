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

const ExternalCrypto = enum {
    none,
    awslc,
    openssl,
    libgcrypt,
};

const BuildOptions = struct {
    internal_timer: bool,
    mock_timer: bool,
    stack_protector: bool,
    external_crypto: ExternalCrypto,
    aarch64_nstime_register: ?[]const u8,
    sanitizers: bool,
    tsan: bool,
    fuzzing: bool,
    coverage: bool,
    coverage_rt_file: ?std.Build.LazyPath,
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

    const external_crypto = b.option(
        ExternalCrypto,
        "external-crypto",
        "External cryptographic library for SHA3-256 and secure memory (none, awslc, openssl, libgcrypt; default: none)",
    ) orelse .none;

    const aarch64_nstime_register = b.option(
        []const u8,
        "aarch64-nstime-register",
        "System register to read for nanosecond time on AArch64 (default: CNTVCT_EL0)",
    );

    const sanitizers = b.option(
        bool,
        "sanitizers",
        "Enable C undefined behavior sanitizer (default: false)",
    ) orelse false;

    const tsan = b.option(
        bool,
        "tsan",
        "Enable ThreadSanitizer (default: false)",
    ) orelse false;

    const fuzzing = b.option(
        bool,
        "fuzzing",
        "Build fuzzing harnesses fuzz-api and fuzz-health (default: false)",
    ) orelse false;

    const coverage = b.option(
        bool,
        "coverage",
        "Enable gcov/llvm-cov code coverage instrumentation (default: false)",
    ) orelse false;

    const enable_efi = b.option(
        bool,
        "efi",
        "Build freestanding UEFI applications BOOTX64.EFI and BOOTAA64.EFI (default: false)",
    ) orelse false;

    if (sanitizers and tsan) {
        std.debug.panic("-Dsanitizers=true and -Dtsan=true cannot be enabled together", .{});
    }

    verifyVersionScript(
        b,
        "jitterentropy.h",
        "version.lds",
        "JENT_PRIVATE_STATIC",
        &.{ "jent_ntg1_init", "jent_ntg1_entropy_init_ex", "jent_ntg1_entropy_collector_alloc" },
    );
    verifyLinktestCalls(b, "version.lds", "tests/linking/jitterentropy-linktest.c");
    verifyVersionScript(
        b,
        "tests/raw-entropy/recording_library/jitterentropy-record.h",
        "tests/raw-entropy/recording_library/record.lds",
        "JENT_RECORD_API",
        &.{},
    );
    verifyVersionScript(
        b,
        "linux_kernel/userspace/jitterentropy-kernel.h",
        "linux_kernel/userspace/kernel.lds",
        "JENT_KERNEL_API",
        &.{},
    );
    verifyLinktestCalls(
        b,
        "linux_kernel/userspace/kernel.lds",
        "tests/unit/unit-kernel-lib.c",
    );

    const coverage_rt_file: ?std.Build.LazyPath = if (coverage) blk: {
        const cov_wf = b.addWriteFiles();
        break :blk cov_wf.add("jent_gcov_rt.c", gcov_runtime_c_source);
    } else null;

    const opts = BuildOptions{
        .internal_timer = internal_timer,
        .mock_timer = mock_timer,
        .stack_protector = stack_protector,
        .external_crypto = external_crypto,
        .aarch64_nstime_register = aarch64_nstime_register,
        .sanitizers = sanitizers,
        .tsan = tsan,
        .fuzzing = fuzzing,
        .coverage = coverage,
        .coverage_rt_file = coverage_rt_file,
    };

    if (enable_efi) {
        addEfiTargets(b);
    }

    const build_options = b.addOptions();
    build_options.addOption(bool, "internal_timer", internal_timer);
    build_options.addOption(bool, "mock_timer", mock_timer);
    build_options.addOption(bool, "raw_memory_access", raw_memory_access);
    build_options.addOption(bool, "stack_protector", stack_protector);
    build_options.addOption(std.builtin.LinkMode, "linkage", linkage);

    const mock_build_options = b.addOptions();
    mock_build_options.addOption(bool, "internal_timer", internal_timer);
    mock_build_options.addOption(bool, "mock_timer", true);
    mock_build_options.addOption(bool, "raw_memory_access", raw_memory_access);
    mock_build_options.addOption(bool, "stack_protector", stack_protector);
    mock_build_options.addOption(std.builtin.LinkMode, "linkage", .static);

    const record_options = b.addOptions();
    record_options.addOption(bool, "raw_memory_access", raw_memory_access);

    const os_tag = target.result.os.tag;
    const c_flags = getCFlags(b, target, opts, &.{}) catch @panic("OOM");

    const zig_core_mod = createCModule(b, target, optimize, opts, if (os_tag == .windows) null else true);
    zig_core_mod.root_source_file = b.path("src/root.zig");
    zig_core_mod.addOptions("build_options", build_options);
    configureIncludePaths(b, zig_core_mod);
    configureCommonDefines(b, zig_core_mod, target, opts, .static, false);
    const zig_core_lib = b.addLibrary(.{
        .name = "jitterentropy-zig-core",
        .linkage = .static,
        .root_module = zig_core_mod,
    });

    var mock_opts = opts;
    mock_opts.mock_timer = true;
    const zig_core_mock_mod = createCModule(b, target, optimize, mock_opts, if (os_tag == .windows) null else true);
    zig_core_mock_mod.root_source_file = b.path("src/root.zig");
    zig_core_mock_mod.addOptions("build_options", mock_build_options);
    configureIncludePaths(b, zig_core_mock_mod);
    configureCommonDefines(b, zig_core_mock_mod, target, mock_opts, .static, false);
    const zig_core_mock_lib = b.addLibrary(.{
        .name = "jitterentropy-zig-core-mock",
        .linkage = .static,
        .root_module = zig_core_mock_mod,
    });

    const lib_mod = createCModule(b, target, optimize, opts, if (os_tag == .windows) null else true);
    lib_mod.root_source_file = b.path("src/root.zig");
    lib_mod.addOptions("build_options", build_options);
    configureIncludePaths(b, lib_mod);
    configureCommonDefines(b, lib_mod, target, opts, linkage, true);
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
    if (linkage == .dynamic) {
        if (os_tag.isDarwin()) {
            lib.install_name = b.fmt(
                "@rpath/libjitterentropy.{d}.dylib",
                .{jitterentropy_version.major},
            );
        } else if (os_tag != .windows) {
            lib.setVersionScript(b.path("version.lds"));
        }
    }
    lib.installHeader(b.path("jitterentropy.h"), "jitterentropy.h");
    b.installArtifact(lib);

    installPkgConfig(b, target, opts, linkage);

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
    const test_runner_exe = addTestRunnerExecutable(b, target);
    const tsan_options: ?[]const u8 = if (opts.tsan)
        "halt_on_error=1:suppressions=tests/tsan.supp"
    else
        null;

    if (linkage == .dynamic and (os_tag == .linux or os_tag.isDarwin())) {
        addCheckExportsTest(b, test_step, lib, "version.lds");
    }

    var recording_lib: ?*std.Build.Step.Compile = null;
    if (enable_recording) {
        const rec_lib = addRecordingLibrary(
            b,
            target,
            optimize,
            opts,
            record_options,
            c_flags,
            linkage,
            raw_memory_access,
        );
        recording_lib = rec_lib;
        if (linkage == .dynamic) {
            if (os_tag.isDarwin()) {
                rec_lib.install_name = b.fmt(
                    "@rpath/libjitterentropy-record.{d}.dylib",
                    .{jitterentropy_version.major},
                );
            } else if (os_tag != .windows) {
                rec_lib.setVersionScript(b.path("tests/raw-entropy/recording_library/record.lds"));
            }
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

        if (linkage == .dynamic and (os_tag == .linux or os_tag.isDarwin())) {
            addCheckExportsTest(b, test_step, rec_lib, "tests/raw-entropy/recording_library/record.lds");
        }

        const colink_mod = createCModule(b, target, optimize, opts, null);
        colink_mod.root_source_file =
            b.path("tests/raw-entropy/recording_library/record_colink.zig");
        colink_mod.linkLibrary(lib);
        colink_mod.linkLibrary(rec_lib);
        const colink_exe = b.addExecutable(.{
            .name = "record-colink",
            .root_module = colink_mod,
        });
        const run_colink = addSkipAwareTestRun(b, test_runner_exe, colink_exe, tsan_options);
        run_colink.addArg(".zig-cache/record-colink");
        test_step.dependOn(&run_colink.step);
    }

    if (enable_kernel_lib) {
        if (os_tag != .linux) {
            std.debug.panic("-Dkernel-lib=true requires a Linux target", .{});
        }
        const kern_mod = createCModule(b, target, optimize, opts, true);
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
            addCheckExportsTest(b, test_step, kern_lib, "linux_kernel/userspace/kernel.lds");
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

        const jitter_rng_mod = createCModule(b, target, optimize, opts, null);
        jitter_rng_mod.addIncludePath(b.path("linux_kernel/userspace"));
        jitter_rng_mod.addIncludePath(b.path("linux_kernel"));
        jitter_rng_mod.addCSourceFile(.{
            .file = b.path("linux_kernel/userspace/jitter_rng.c"),
            .flags = c_flags,
        });
        jitter_rng_mod.linkLibrary(kern_lib);
        configureInstallRPath(jitter_rng_mod, os_tag, linkage);

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
        const rngd_mod = createCModule(b, target, optimize, opts, null);
        configureIncludePaths(b, rngd_mod);
        configureCommonDefines(b, rngd_mod, target, opts, linkage, false);
        rngd_mod.addCSourceFile(.{
            .file = b.path("rngd/jitterentropy-rngd.c"),
            .flags = c_flags,
        });
        rngd_mod.linkLibrary(lib);
        configureInstallRPath(rngd_mod, os_tag, linkage);

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
        applyTestEnv(run_rngd_ver, tsan_options);
        run_rngd_ver.addArg("--version");
        run_rngd_ver.expectExitCode(0);
        run_rngd_ver.expectStdErrEqual(
            "Version jitterentropy-rngd 3.8.0\nVersion Jitterentropy Core 3080000\n",
        );
        test_step.dependOn(&run_rngd_ver.step);
    }

    const gcd_exe = addAbsorbingExecutable(b, "gcd", target, optimize, opts, zig_core_lib, c_flags, &.{
        "tests/gcd/gcd.c",
        "src/jitterentropy-gcd.c",
        "arch/jitterentropy-arch-memory.c",
        "arch/jitterentropy-arch-atomic.c",
    }, false, false);
    configureCryptoLibraries(gcd_exe.root_module, opts);

    const health_exe = addAbsorbingExecutable(b, "jitterentropy-health", target, optimize, opts, zig_core_lib, c_flags, &.{
        "tests/health/health.c",
        "src/jitterentropy-health.c",
        "arch/jitterentropy-arch-atomic.c",
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

    if (enable_tools) {
        b.installArtifact(gcd_exe);
        b.installArtifact(health_exe);
        b.installArtifact(flags_exe);

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
        configureInstallRPath(rng_exe.root_module, os_tag, linkage);
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
        configureInstallRPath(osr_exe.root_module, os_tag, linkage);
        b.installArtifact(osr_exe);

        const hashtime_record_linkage: std.builtin.LinkMode =
            if (recording_lib != null) linkage else .static;
        const hashtime_record_lib = recording_lib orelse addRecordingLibrary(
            b,
            target,
            optimize,
            opts,
            record_options,
            c_flags,
            .static,
            raw_memory_access,
        );
        const hashtime_mod = createCModule(b, target, optimize, opts, null);
        configureIncludePaths(b, hashtime_mod);
        hashtime_mod.addIncludePath(b.path("tests"));
        hashtime_mod.addIncludePath(b.path("tests/raw-entropy/recording_library"));
        configureCommonDefines(b, hashtime_mod, target, opts, linkage, false);
        configureCryptoLibraries(hashtime_mod, opts);
        hashtime_mod.linkLibrary(hashtime_record_lib);
        if (hashtime_record_linkage == .static) {
            hashtime_mod.addCMacro("JENT_RECORD_STATIC_LIB", "1");
        }
        if (os_tag == .linux or os_tag == .freebsd or os_tag == .netbsd or
            os_tag == .windows)
        {
            hashtime_mod.addCMacro("JENT_HAVE_CPU_PINNING", "1");
        }
        hashtime_mod.addCSourceFile(.{
            .file = b.path("tests/raw-entropy/recording_userspace/jitterentropy-hashtime.c"),
            .flags = c_flags,
        });
        const hashtime_exe = b.addExecutable(.{
            .name = "jitterentropy-hashtime",
            .root_module = hashtime_mod,
        });
        configureInstallRPath(hashtime_exe.root_module, os_tag, linkage);
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

        const cpuinfo_exe = addToolExecutable(
            b,
            "jitterentropy-cpuinfo",
            "tests/raw-entropy/recording_userspace/jitterentropy-cpuinfo.c",
            target,
            optimize,
            opts,
            linkage,
            c_flags,
            null,
            false,
        );
        if (os_tag == .windows) {
            cpuinfo_exe.root_module.linkSystemLibrary("advapi32", .{});
        }
        b.installArtifact(cpuinfo_exe);

        const extractlsb_mod = createCModule(b, target, optimize, opts, null);
        extractlsb_mod.root_source_file = b.path("tests/raw-entropy/extractlsb.zig");
        const extractlsb_exe = b.addExecutable(.{
            .name = "extractlsb",
            .root_module = extractlsb_mod,
        });
        b.installArtifact(extractlsb_exe);

        if (os_tag == .linux) {
            const getraw_mod = createCModule(b, target, optimize, opts, null);
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

            const status_mod = createCModule(b, target, optimize, opts, null);
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

            const fields_mod = createCModule(b, target, optimize, opts, null);
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
    applyTestEnv(run_gcd, tsan_options);
    run_gcd.expectExitCode(0);
    test_step.dependOn(&run_gcd.step);

    var osr: u32 = 3;
    while (osr <= 20) : (osr += 1) {
        const run_health = b.addRunArtifact(health_exe);
        applyTestEnv(run_health, tsan_options);
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
        applyTestEnv(run_health_vec, tsan_options);
        run_health_vec.addArg("--replay");
        run_health_vec.addFileArg(b.path(vec_path));
        run_health_vec.expectExitCode(1);
        test_step.dependOn(&run_health_vec.step);
    }

    const run_health_clean = b.addRunArtifact(health_exe);
    applyTestEnv(run_health_clean, tsan_options);
    run_health_clean.addArg("--replay");
    run_health_clean.addFileArg(b.path("tests/health/testdata/no-failure.txt"));
    run_health_clean.expectExitCode(0);
    test_step.dependOn(&run_health_clean.step);

    const run_flags_encode = b.addRunArtifact(flags_exe);
    applyTestEnv(run_flags_encode, tsan_options);
    run_flags_encode.addArgs(&.{ "ntg1", "JENT_MAX_MEMSIZE_1MB", "--hloopcnt", "4" });
    run_flags_encode.expectStdOutEqual("1518338112\n");
    test_step.dependOn(&run_flags_encode.step);

    const run_flags_mixed = b.addRunArtifact(flags_exe);
    applyTestEnv(run_flags_mixed, tsan_options);
    run_flags_mixed.addArg("JeNt_NtG1");
    run_flags_mixed.expectStdOutEqual("64\n");
    test_step.dependOn(&run_flags_mixed.step);

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
        applyTestEnv(run_flags_fail, tsan_options);
        run_flags_fail.addArgs(case.args);
        run_flags_fail.expectExitCode(1);
        run_flags_fail.expectStdErrEqual(case.stderr);
        test_step.dependOn(&run_flags_fail.step);
    }

    const abi_test_wf = b.addWriteFiles();
    const abi_test_helper_c = abi_test_wf.add("jent_abi_test_helper.c",
        \\#include <stddef.h>
        \\#include "jitterentropy-internal.h"
        \\
        \\size_t jent_test_sizeof_sha_ctx(void) { return sizeof(struct jent_sha_ctx); }
        \\size_t jent_test_alignof_sha_ctx(void) { return _Alignof(struct jent_sha_ctx); }
        \\size_t jent_test_offsetof_sha_ctx(int field_id) {
        \\    switch (field_id) {
        \\        case 0: return offsetof(struct jent_sha_ctx, state);
        \\        case 1: return offsetof(struct jent_sha_ctx, msg_len);
        \\        case 2: return offsetof(struct jent_sha_ctx, partial);
        \\        case 3: return offsetof(struct jent_sha_ctx, xdrbg_block);
        \\        case 4: return offsetof(struct jent_sha_ctx, r);
        \\        case 5: return offsetof(struct jent_sha_ctx, rword);
        \\        case 6: return offsetof(struct jent_sha_ctx, digestsize);
        \\        case 7: return offsetof(struct jent_sha_ctx, padding);
        \\        default: return (size_t)-1;
        \\    }
        \\}
        \\
        \\size_t jent_test_sizeof_rand_data(void) { return sizeof(struct rand_data); }
        \\size_t jent_test_alignof_rand_data(void) { return _Alignof(struct rand_data); }
        \\size_t jent_test_offsetof_rand_data(int field_id) {
        \\    switch (field_id) {
        \\        case 0: return offsetof(struct rand_data, hash_state);
        \\        case 1: return offsetof(struct rand_data, prev_time);
        \\        case 2: return offsetof(struct rand_data, flags);
        \\        case 3: return offsetof(struct rand_data, osr);
        \\        case 4: return offsetof(struct rand_data, uuid);
        \\        case 5: return offsetof(struct rand_data, reinit_count);
        \\        case 6: return offsetof(struct rand_data, read_invocations);
        \\        case 7: return offsetof(struct rand_data, bytes_output);
        \\        case 8: return offsetof(struct rand_data, startup_state);
        \\        case 9: return offsetof(struct rand_data, mem);
        \\        case 10: return offsetof(struct rand_data, memmask);
        \\        case 11: return offsetof(struct rand_data, memlocation);
        \\        case 12: return offsetof(struct rand_data, memaccessloops);
        \\        case 13: return offsetof(struct rand_data, hashloopcnt);
        \\        case 14: return offsetof(struct rand_data, rct_count);
        \\        case 15: return offsetof(struct rand_data, rct_cutoff);
        \\        case 16: return offsetof(struct rand_data, rct_cutoff_permanent);
        \\        case 17: return offsetof(struct rand_data, apt_cutoff);
        \\        case 18: return offsetof(struct rand_data, apt_cutoff_permanent);
        \\        case 19: return offsetof(struct rand_data, apt_observations);
        \\        case 20: return offsetof(struct rand_data, apt_count);
        \\        case 21: return offsetof(struct rand_data, apt_base);
        \\        case 22: return offsetof(struct rand_data, health_failure);
        \\        case 23: return offsetof(struct rand_data, rct_mem_ctr);
        \\        case 24: return offsetof(struct rand_data, rct_mem_nosr);
        \\        case 25: return offsetof(struct rand_data, rct_mem_count);
        \\        case 26: return offsetof(struct rand_data, rct_mem_cutoff);
        \\        case 27: return offsetof(struct rand_data, rct_mem_cutoff_permanent);
        \\        case 28: return offsetof(struct rand_data, selftest_failed);
        \\#ifdef JENT_CONF_ENABLE_INTERNAL_TIMER
        \\        case 29: return offsetof(struct rand_data, notime_interrupt);
        \\        case 30: return offsetof(struct rand_data, notime_timer);
        \\        case 31: return offsetof(struct rand_data, notime_prev_timer);
        \\        case 32: return offsetof(struct rand_data, notime_thread_ctx);
        \\#endif
        \\        case 33: return offsetof(struct rand_data, jent_common_timer_gcd);
        \\        case 34: return offsetof(struct rand_data, lag_global_cutoff);
        \\        case 35: return offsetof(struct rand_data, lag_global_cutoff_permanent);
        \\        case 36: return offsetof(struct rand_data, lag_local_cutoff);
        \\        case 37: return offsetof(struct rand_data, lag_local_cutoff_permanent);
        \\        case 38: return offsetof(struct rand_data, lag_prediction_success_count);
        \\        case 39: return offsetof(struct rand_data, lag_prediction_success_run);
        \\        case 40: return offsetof(struct rand_data, lag_best_predictor);
        \\        case 41: return offsetof(struct rand_data, lag_observations);
        \\        case 42: return offsetof(struct rand_data, lag_delta_history);
        \\        case 43: return offsetof(struct rand_data, lag_scoreboard);
        \\        default: return (size_t)-1;
        \\    }
        \\}
        \\
        \\size_t jent_test_sizeof_notime_thread(void) { return sizeof(struct jent_notime_thread); }
        \\size_t jent_test_alignof_notime_thread(void) { return _Alignof(struct jent_notime_thread); }
        \\size_t jent_test_offsetof_notime_thread(int field_id) {
        \\    switch (field_id) {
        \\        case 0: return offsetof(struct jent_notime_thread, jent_notime_init);
        \\        case 1: return offsetof(struct jent_notime_thread, jent_notime_fini);
        \\        case 2: return offsetof(struct jent_notime_thread, jent_notime_start);
        \\        case 3: return offsetof(struct jent_notime_thread, jent_notime_stop);
        \\        default: return (size_t)-1;
        \\    }
        \\}
        \\
        \\size_t jent_test_sizeof_notime_ctx(void) {
        \\#ifdef JENT_CONF_ENABLE_INTERNAL_TIMER
        \\    return sizeof(struct jent_notime_ctx);
        \\#else
        \\    return 0;
        \\#endif
        \\}
        \\size_t jent_test_alignof_notime_ctx(void) {
        \\#ifdef JENT_CONF_ENABLE_INTERNAL_TIMER
        \\    return _Alignof(struct jent_notime_ctx);
        \\#else
        \\    return 0;
        \\#endif
        \\}
        \\
        \\unsigned int jent_test_c_uint_const(int id) {
        \\    switch (id) {
        \\        case 0: return JENT_MAJVERSION;
        \\        case 1: return JENT_MINVERSION;
        \\        case 2: return JENT_PATCHLEVEL;
        \\        case 3: return JENT_VERSION;
        \\        case 4: return JENT_DISABLE_STIR;
        \\        case 5: return JENT_DISABLE_UNBIAS;
        \\        case 6: return JENT_DISABLE_MEMORY_ACCESS;
        \\        case 7: return JENT_FORCE_INTERNAL_TIMER;
        \\        case 8: return JENT_DISABLE_INTERNAL_TIMER;
        \\        case 9: return JENT_FORCE_FIPS;
        \\        case 10: return JENT_NTG1;
        \\        case 11: return JENT_CACHE_ALL;
        \\        case 12: return JENT_FORCE_SECURE_MEM;
        \\        case 13: return JENT_INT_MEASURE_CLOCK;
        \\        case 14: return JENT_MAX_MEMSIZE_1kB;
        \\        case 15: return JENT_MAX_MEMSIZE_2kB;
        \\        case 16: return JENT_MAX_MEMSIZE_4kB;
        \\        case 17: return JENT_MAX_MEMSIZE_8kB;
        \\        case 18: return JENT_MAX_MEMSIZE_16kB;
        \\        case 19: return JENT_MAX_MEMSIZE_32kB;
        \\        case 20: return JENT_MAX_MEMSIZE_64kB;
        \\        case 21: return JENT_MAX_MEMSIZE_128kB;
        \\        case 22: return JENT_MAX_MEMSIZE_256kB;
        \\        case 23: return JENT_MAX_MEMSIZE_512kB;
        \\        case 24: return JENT_MAX_MEMSIZE_1MB;
        \\        case 25: return JENT_MAX_MEMSIZE_2MB;
        \\        case 26: return JENT_MAX_MEMSIZE_4MB;
        \\        case 27: return JENT_MAX_MEMSIZE_8MB;
        \\        case 28: return JENT_MAX_MEMSIZE_16MB;
        \\        case 29: return JENT_MAX_MEMSIZE_32MB;
        \\        case 30: return JENT_MAX_MEMSIZE_64MB;
        \\        case 31: return JENT_MAX_MEMSIZE_128MB;
        \\        case 32: return JENT_MAX_MEMSIZE_256MB;
        \\        case 33: return JENT_MAX_MEMSIZE_512MB;
        \\        case 34: return JENT_MAX_MEMSIZE_MAX;
        \\        case 35: return (unsigned int)JENT_MAX_MEMSIZE_MASK;
        \\        case 36: return JENT_MAX_MEMSIZE_OFFSET;
        \\        case 37: return JENT_MAX_HASHLOOP_MASK;
        \\        case 38: return JENT_HASHLOOP_1;
        \\        case 39: return JENT_HASHLOOP_2;
        \\        case 40: return JENT_HASHLOOP_4;
        \\        case 41: return JENT_HASHLOOP_8;
        \\        case 42: return JENT_HASHLOOP_16;
        \\        case 43: return JENT_HASHLOOP_32;
        \\        case 44: return JENT_HASHLOOP_64;
        \\        case 45: return JENT_HASHLOOP_128;
        \\        case 46: return JENT_MAX_HASHLOOP;
        \\        case 47: return JENT_RCT_FAILURE;
        \\        case 48: return JENT_APT_FAILURE;
        \\        case 49: return JENT_LAG_FAILURE;
        \\        case 50: return JENT_RCT_MEM_FAILURE;
        \\        case 51: return JENT_RCT_FAILURE_PERMANENT;
        \\        case 52: return JENT_APT_FAILURE_PERMANENT;
        \\        case 53: return JENT_LAG_FAILURE_PERMANENT;
        \\        case 54: return JENT_RCT_MEM_FAILURE_PERMANENT;
        \\        default: return 0xffffffffu;
        \\    }
        \\}
        \\
        \\int jent_test_c_int_const(int id) {
        \\    switch (id) {
        \\        case 0: return ENOTIME;
        \\        case 1: return ECOARSETIME;
        \\        case 2: return ENOMONOTONIC;
        \\        case 3: return EMINVARIATION;
        \\        case 4: return EVARVAR;
        \\        case 5: return EMINVARVAR;
        \\        case 6: return EPROGERR;
        \\        case 7: return ESTUCK;
        \\        case 8: return EHEALTH;
        \\        case 9: return ERCT;
        \\        case 10: return EHASH;
        \\        case 11: return EMEM;
        \\        case 12: return EGCD;
        \\        case 13: return JENT_ERR_EINVAL;
        \\        case 14: return JENT_ERR_RCT;
        \\        case 15: return JENT_ERR_APT;
        \\        case 16: return JENT_ERR_NOTIME;
        \\        case 17: return JENT_ERR_LAG;
        \\        case 18: return JENT_ERR_RCT_PERMANENT;
        \\        case 19: return JENT_ERR_APT_PERMANENT;
        \\        case 20: return JENT_ERR_LAG_PERMANENT;
        \\        case 21: return JENT_ERR_RCT_MEM;
        \\        case 22: return JENT_ERR_RCT_MEM_PERMANENT;
        \\        case 23: return JENT_ERR_SELFTEST;
        \\        default: return 0x7fffffff;
        \\    }
        \\}
        \\
        \\unsigned int jent_test_c_max_memsize_to_flags(unsigned int val) { return JENT_MAX_MEMSIZE_TO_FLAGS(val); }
        \\unsigned int jent_test_c_flags_to_max_memsize(unsigned int flags) { return JENT_FLAGS_TO_MAX_MEMSIZE(flags); }
        \\unsigned int jent_test_c_hashloop_to_flags(unsigned int val) { return JENT_HASHLOOP_TO_FLAGS(val); }
        \\unsigned int jent_test_c_flags_to_hashloop(unsigned int flags) { return JENT_FLAGS_TO_HASHLOOP(flags); }
        \\uint64_t jent_test_c_udiv64(uint64_t dividend, uint64_t divisor) { return jent_udiv64(dividend, divisor); }
        \\uint64_t jent_test_c_umod64(uint64_t dividend, uint64_t divisor) { return jent_umod64(dividend, divisor); }
        \\
        \\void jent_test_c_set_sha_initially_seeded(struct jent_sha_ctx *ctx, uint8_t val) {
        \\    ctx->initially_seeded = val ? 1 : 0;
        \\}
        \\uint8_t jent_test_c_get_sha_initially_seeded(const struct jent_sha_ctx *ctx) {
        \\    return ctx->initially_seeded;
        \\}
        \\
        \\void jent_test_c_set_rand_bitfield(struct rand_data *ec, int field_id, unsigned int val) {
        \\    switch (field_id) {
        \\        case 0: ec->apt_base_set = val ? 1 : 0; break;
        \\        case 1: ec->is_fips_enabled = val ? 1 : 0; break;
        \\        case 2: ec->enable_notime = val ? 1 : 0; break;
        \\        case 3: ec->max_mem_set = val ? 1 : 0; break;
        \\        case 4: ec->in_recovery = val ? 1 : 0; break;
        \\        case 5: ec->stuck_prime = val & 3u; break;
        \\#ifdef JENT_CONF_ENABLE_INTERNAL_TIMER
        \\        case 6: ec->notime_running = val ? 1 : 0; break;
        \\#endif
        \\        default: break;
        \\    }
        \\}
        \\unsigned int jent_test_c_get_rand_bitfield(const struct rand_data *ec, int field_id) {
        \\    switch (field_id) {
        \\        case 0: return ec->apt_base_set;
        \\        case 1: return ec->is_fips_enabled;
        \\        case 2: return ec->enable_notime;
        \\        case 3: return ec->max_mem_set;
        \\        case 4: return ec->in_recovery;
        \\        case 5: return ec->stuck_prime;
        \\#ifdef JENT_CONF_ENABLE_INTERNAL_TIMER
        \\        case 6: return ec->notime_running;
        \\#endif
        \\        default: return 0;
        \\    }
        \\}
    );

    const zig_test_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    zig_test_mod.addOptions("build_options", build_options);
    configureIncludePaths(b, zig_test_mod);
    configureCommonDefines(b, zig_test_mod, target, opts, .static, false);
    configureSystemLibraries(zig_test_mod, target, opts);
    zig_test_mod.addCSourceFiles(.{
        .files = lib_c_sources,
        .flags = c_flags,
    });
    zig_test_mod.addCSourceFile(.{
        .file = abi_test_helper_c,
        .flags = c_flags,
    });

    const zig_unit_tests = b.addTest(.{
        .name = "zig-unit-tests",
        .root_module = zig_test_mod,
    });
    const run_zig_unit_tests = b.addRunArtifact(zig_unit_tests);
    applyTestEnv(run_zig_unit_tests, tsan_options);
    test_step.dependOn(&run_zig_unit_tests.step);

    const zig_harness_mod = b.createModule(.{
        .root_source_file = b.path("tests/unit/test_harness.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const zig_harness_tests = b.addTest(.{
        .name = "zig-harness-tests",
        .root_module = zig_harness_mod,
    });
    const run_zig_harness_tests = b.addRunArtifact(zig_harness_tests);
    test_step.dependOn(&run_zig_harness_tests.step);

    for (unit_test_names) |ut_name| {
        const ut_exe = addUnitTestExecutable(b, ut_name, target, optimize, opts, zig_core_lib, c_flags, false);
        const run_ut = addSkipAwareTestRun(b, test_runner_exe, ut_exe, tsan_options);
        test_step.dependOn(&run_ut.step);
    }

    if (os_tag == .linux) {
        const ut_kern = addUnitTestExecutable(b, "unit-kernel-lib", target, optimize, opts, null, c_flags, false);
        const run_ut_kern = addSkipAwareTestRun(b, test_runner_exe, ut_kern, tsan_options);
        test_step.dependOn(&run_ut_kern.step);
    }

    for (mock_unit_test_names) |ut_name| {
        const ut_exe = addUnitTestExecutable(b, ut_name, target, optimize, opts, zig_core_mock_lib, c_flags, true);
        const run_ut = addSkipAwareTestRun(b, test_runner_exe, ut_exe, tsan_options);
        test_step.dependOn(&run_ut.step);
    }

    const fuzz_api_mod = createCModule(b, target, optimize, opts, null);
    configureIncludePaths(b, fuzz_api_mod);
    configureCommonDefines(b, fuzz_api_mod, target, opts, linkage, false);
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
    if (opts.fuzzing or opts.sanitizers) {
        b.installArtifact(fuzz_api_exe);
    }
    const run_fuzz_api = b.addRunArtifact(fuzz_api_exe);
    applyTestEnv(run_fuzz_api, tsan_options);
    run_fuzz_api.expectExitCode(0);
    test_step.dependOn(&run_fuzz_api.step);

    const fuzz_health_mod = createCModule(b, target, optimize, opts, null);
    fuzz_health_mod.linkLibrary(zig_core_lib);
    configureIncludePaths(b, fuzz_health_mod);
    configureCommonDefines(b, fuzz_health_mod, target, opts, .static, false);
    fuzz_health_mod.addCMacro("JENT_FUZZ_STANDALONE", "1");
    fuzz_health_mod.addCSourceFiles(.{
        .files = &.{
            "tests/fuzz/fuzz-health.c",
            "src/jitterentropy-health.c",
            "arch/jitterentropy-arch-atomic.c",
        },
        .flags = c_flags,
    });
    const fuzz_health_exe = b.addExecutable(.{
        .name = "fuzz-health-standalone",
        .root_module = fuzz_health_mod,
    });
    if (opts.fuzzing or opts.sanitizers) {
        b.installArtifact(fuzz_health_exe);
    }
    const run_fuzz_health = b.addRunArtifact(fuzz_health_exe);
    applyTestEnv(run_fuzz_health, tsan_options);
    run_fuzz_health.expectExitCode(0);
    test_step.dependOn(&run_fuzz_health.step);

    if (opts.fuzzing) {
        const fuzz_wf = b.addWriteFiles();
        const fuzz_driver_file = fuzz_wf.add("jent_fuzz_driver.c", fuzz_driver_c_source);

        const fuzz_api_fuzzer_mod = createCModule(b, target, optimize, opts, null);
        configureIncludePaths(b, fuzz_api_fuzzer_mod);
        configureCommonDefines(b, fuzz_api_fuzzer_mod, target, opts, linkage, false);
        fuzz_api_fuzzer_mod.addCSourceFile(.{
            .file = b.path("tests/fuzz/fuzz-api.c"),
            .flags = c_flags,
        });
        fuzz_api_fuzzer_mod.addCSourceFile(.{
            .file = fuzz_driver_file,
            .flags = c_flags,
        });
        fuzz_api_fuzzer_mod.linkLibrary(lib);
        const fuzz_api_fuzzer_exe = b.addExecutable(.{
            .name = "fuzz-api",
            .root_module = fuzz_api_fuzzer_mod,
        });
        b.installArtifact(fuzz_api_fuzzer_exe);
        const run_fuzz_api_fuzzer = b.addRunArtifact(fuzz_api_fuzzer_exe);
        applyTestEnv(run_fuzz_api_fuzzer, tsan_options);
        run_fuzz_api_fuzzer.addArg("-runs=64");
        run_fuzz_api_fuzzer.expectExitCode(0);
        test_step.dependOn(&run_fuzz_api_fuzzer.step);

        const fuzz_health_fuzzer_mod = createCModule(b, target, optimize, opts, null);
        fuzz_health_fuzzer_mod.linkLibrary(zig_core_lib);
        configureIncludePaths(b, fuzz_health_fuzzer_mod);
        configureCommonDefines(b, fuzz_health_fuzzer_mod, target, opts, .static, false);
        fuzz_health_fuzzer_mod.addCSourceFiles(.{
            .files = &.{
                "tests/fuzz/fuzz-health.c",
                "src/jitterentropy-health.c",
                "arch/jitterentropy-arch-atomic.c",
            },
            .flags = c_flags,
        });
        fuzz_health_fuzzer_mod.addCSourceFile(.{
            .file = fuzz_driver_file,
            .flags = c_flags,
        });
        const fuzz_health_fuzzer_exe = b.addExecutable(.{
            .name = "fuzz-health",
            .root_module = fuzz_health_fuzzer_mod,
        });
        b.installArtifact(fuzz_health_fuzzer_exe);
        const run_fuzz_health_fuzzer = b.addRunArtifact(fuzz_health_fuzzer_exe);
        applyTestEnv(run_fuzz_health_fuzzer, tsan_options);
        run_fuzz_health_fuzzer.addArg("-runs=64");
        run_fuzz_health_fuzzer.expectExitCode(0);
        test_step.dependOn(&run_fuzz_health_fuzzer.step);
    }

    const linktest_mod = createCModule(b, target, optimize, opts, null);
    configureCommonDefines(b, linktest_mod, target, opts, linkage, false);
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
    applyTestEnv(run_linktest, tsan_options);
    run_linktest.expectExitCode(0);
    test_step.dependOn(&run_linktest.step);
}

fn createCModule(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    opts: BuildOptions,
    pic: ?bool,
) *std.Build.Module {
    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .pic = pic,
        .sanitize_c = if (opts.sanitizers) .full else null,
        .sanitize_thread = if (opts.tsan) true else null,
        .omit_frame_pointer = if (opts.sanitizers or opts.tsan or opts.coverage) false else null,
    });
    if (opts.coverage_rt_file) |cov_rt| {
        mod.addCSourceFile(.{
            .file = cov_rt,
            .flags = &.{ "-std=gnu11", "-O2", "-fvisibility=hidden" },
        });
    }
    return mod;
}

fn configureInstallRPath(
    mod: *std.Build.Module,
    os_tag: std.Target.Os.Tag,
    linkage: std.builtin.LinkMode,
) void {
    if (linkage == .dynamic) {
        if (os_tag.isDarwin()) {
            mod.addRPathSpecial("@loader_path/../lib");
        } else if (os_tag != .windows) {
            mod.addRPathSpecial("$ORIGIN/../lib");
        }
    }
}

fn applyTestEnv(run: *std.Build.Step.Run, tsan_options: ?[]const u8) void {
    if (tsan_options) |tsan_opt| {
        run.setEnvironmentVariable("TSAN_OPTIONS", tsan_opt);
    }
}

fn addTestRunnerExecutable(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
) *std.Build.Step.Compile {
    const wf = b.addWriteFiles();
    const runner_c = wf.add("jent_test_runner.c", test_runner_c_source);
    const mod = b.createModule(.{
        .target = target,
        .optimize = .Debug,
        .link_libc = true,
    });
    mod.addCSourceFile(.{
        .file = runner_c,
        .flags = &.{ "-std=gnu11", "-O2" },
    });
    return b.addExecutable(.{
        .name = "jent-test-runner",
        .root_module = mod,
    });
}

fn addSkipAwareTestRun(
    b: *std.Build,
    runner_exe: *std.Build.Step.Compile,
    test_exe: *std.Build.Step.Compile,
    tsan_options: ?[]const u8,
) *std.Build.Step.Run {
    const run = b.addRunArtifact(runner_exe);
    run.setName(b.fmt("run test {s}", .{test_exe.name}));
    run.producer = test_exe;
    run.addArtifactArg(test_exe);
    applyTestEnv(run, tsan_options);
    run.expectExitCode(0);
    return run;
}

fn addCheckExportsTest(
    b: *std.Build,
    test_step: *std.Build.Step,
    lib: *std.Build.Step.Compile,
    lds_sub_path: []const u8,
) void {
    const check_cmd = b.addSystemCommand(&.{"bash"});
    check_cmd.setName(b.fmt("check-exports-{s}", .{lib.name}));
    check_cmd.addFileArg(b.path(".github/scripts/check-exports.sh"));
    check_cmd.addArtifactArg(lib);
    check_cmd.addFileArg(b.path(lds_sub_path));
    check_cmd.expectExitCode(0);
    _ = check_cmd.captureStdErr(.{});
    test_step.dependOn(&check_cmd.step);
}

fn installPkgConfig(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    opts: BuildOptions,
    linkage: std.builtin.LinkMode,
) void {
    const os_tag = target.result.os.tag;
    var libs_private: std.ArrayListUnmanaged(u8) = .empty;
    if (linkage == .static) {
        if (opts.stack_protector and os_tag != .windows and os_tag != .haiku) {
            libs_private.appendSlice(b.allocator, " -fstack-protector-strong") catch @panic("OOM");
        }
        if (os_tag == .windows) {
            libs_private.appendSlice(b.allocator, " -lbcrypt") catch @panic("OOM");
        }
        if (opts.internal_timer and os_tag != .windows and !target.result.abi.isAndroid()) {
            libs_private.appendSlice(b.allocator, " -pthread") catch @panic("OOM");
        }
    }

    const crypto_pc: []const u8 = switch (opts.external_crypto) {
        .none => "",
        .awslc, .openssl => " libcrypto",
        .libgcrypt => " libgcrypt",
    };
    const requires = if (linkage == .dynamic) crypto_pc else "";
    const requires_private = if (linkage == .static) crypto_pc else "";
    const cflags_extra = if (os_tag == .windows and linkage == .static) " -DJENT_STATIC_LIB" else "";

    const pc_content = std.fmt.allocPrint(
        b.allocator,
        \\prefix=${{pcfiledir}}/../..
        \\exec_prefix=${{prefix}}
        \\libdir=${{prefix}}/lib
        \\includedir=${{prefix}}/include
        \\
        \\Name: jitterentropy
        \\Description: Hardware RNG based on CPU timing jitter
        \\Version: {d}.{d}.{d}
        \\URL: https://www.chronox.de/jent/
        \\Libs: -L${{libdir}} -ljitterentropy
        \\Libs.private:{s}
        \\Requires:{s}
        \\Requires.private:{s}
        \\Cflags: -I${{includedir}}{s}
        \\
    ,
        .{
            jitterentropy_version.major,
            jitterentropy_version.minor,
            jitterentropy_version.patch,
            libs_private.items,
            requires,
            requires_private,
            cflags_extra,
        },
    ) catch @panic("OOM");

    const pc_wf = b.addWriteFiles();
    const pc_file = pc_wf.add("jitterentropy.pc", pc_content);
    b.getInstallStep().dependOn(
        &b.addInstallFileWithDir(pc_file, .{ .custom = "lib/pkgconfig" }, "jitterentropy.pc").step,
    );
}

fn configureIncludePaths(b: *std.Build, mod: *std.Build.Module) void {
    mod.addIncludePath(b.path("."));
    mod.addIncludePath(b.path("src"));
    mod.addIncludePath(b.path("arch"));
}

fn configureCommonDefines(
    b: *std.Build,
    mod: *std.Build.Module,
    target: std.Build.ResolvedTarget,
    opts: BuildOptions,
    linkage: std.builtin.LinkMode,
    is_building_lib: bool,
) void {
    if (opts.internal_timer) {
        mod.addCMacro("JENT_CONF_ENABLE_INTERNAL_TIMER", "1");
    }
    if (opts.mock_timer) {
        mod.addCMacro("JENT_CONF_ENABLE_MOCK_TIMER", "1");
    }
    switch (opts.external_crypto) {
        .none => {},
        .awslc => mod.addCMacro("AWSLC", "1"),
        .openssl => mod.addCMacro("OPENSSL", "1"),
        .libgcrypt => mod.addCMacro("LIBGCRYPT", "1"),
    }
    if (opts.aarch64_nstime_register) |reg| {
        const quoted = if (reg.len >= 2 and reg[0] == '"' and reg[reg.len - 1] == '"')
            reg
        else
            std.fmt.allocPrint(b.allocator, "\"{s}\"", .{reg}) catch @panic("OOM");
        mod.addCMacro("AARCH64_NSTIME_REGISTER", quoted);
    }
    if (target.result.os.tag == .haiku) {
        mod.addCMacro("B_USE_POSITIVE_POSIX_ERRORS", "1");
    }
    if (target.result.os.tag == .windows) {
        if (linkage == .static) {
            mod.addCMacro("JENT_STATIC_LIB", "1");
        } else if (is_building_lib) {
            mod.addCMacro("JENT_BUILDING_DLL", "1");
        }
    }
}

fn configureCryptoLibraries(mod: *std.Build.Module, opts: BuildOptions) void {
    switch (opts.external_crypto) {
        .none => {},
        .awslc, .openssl => mod.linkSystemLibrary("crypto", .{ .use_pkg_config = .no }),
        .libgcrypt => mod.linkSystemLibrary("gcrypt", .{ .use_pkg_config = .no }),
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
    configureCryptoLibraries(mod, opts);
}

fn addRecordingLibrary(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    opts: BuildOptions,
    record_options: *std.Build.Step.Options,
    c_flags: []const []const u8,
    linkage: std.builtin.LinkMode,
    raw_memory_access: bool,
) *std.Build.Step.Compile {
    const mod = createCModule(
        b,
        target,
        optimize,
        opts,
        if (target.result.os.tag == .windows) null else true,
    );
    mod.root_source_file =
        b.path("tests/raw-entropy/recording_library/record_lib.zig");
    mod.addOptions("record_options", record_options);
    configureIncludePaths(b, mod);
    mod.addIncludePath(b.path("tests/raw-entropy/recording_library"));
    configureCommonDefines(b, mod, target, opts, linkage, false);
    if (raw_memory_access) {
        mod.addCMacro("JENT_TEST_MEASURE_RAW_MEMORY_ACCESS", "1");
    }
    configureSystemLibraries(mod, target, opts);
    mod.addCSourceFile(.{
        .file = b.path("tests/raw-entropy/recording_library/record_core.c"),
        .flags = c_flags,
    });
    return b.addLibrary(.{
        .name = "jitterentropy-record",
        .linkage = linkage,
        .version = jitterentropy_version,
        .root_module = mod,
    });
}

fn addAbsorbingExecutable(
    b: *std.Build,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    opts: BuildOptions,
    zig_core_lib: *std.Build.Step.Compile,
    c_flags: []const []const u8,
    files: []const []const u8,
    needs_system_libs: bool,
    needs_libm: bool,
) *std.Build.Step.Compile {
    const mod = createCModule(b, target, optimize, opts, null);
    mod.linkLibrary(zig_core_lib);
    configureIncludePaths(b, mod);
    mod.addIncludePath(b.path("tests"));
    configureCommonDefines(b, mod, target, opts, .static, false);
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
    const mod = createCModule(b, target, optimize, opts, null);
    configureIncludePaths(b, mod);
    mod.addIncludePath(b.path("tests"));
    configureCommonDefines(b, mod, target, opts, linkage, false);
    if (lib) |l| {
        mod.linkLibrary(l);
        configureCryptoLibraries(mod, opts);
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

fn excludedSourcesForUnitTest(name: []const u8) []const []const u8 {
    if (std.mem.eql(u8, name, "unit-arch-cache")) {
        return &.{"arch/jitterentropy-arch-cache.c"};
    }
    if (std.mem.eql(u8, name, "unit-arch-ncpu")) {
        return &.{"arch/jitterentropy-arch-ncpu.c"};
    }
    if (std.mem.eql(u8, name, "unit-zeroize")) {
        return &.{"arch/jitterentropy-arch-memory.c"};
    }
    if (std.mem.eql(u8, name, "unit-fault")) {
        return &.{
            "arch/jitterentropy-arch-memory.c",
            "arch/jitterentropy-arch-ncpu.c",
            "arch/jitterentropy-arch-thread.c",
            "arch/jitterentropy-arch-timer.c",
            "arch/jitterentropy-arch-cache.c",
            "arch/jitterentropy-arch-fips.c",
            "arch/jitterentropy-arch-random.c",
        };
    }
    if (std.mem.eql(u8, name, "unit-notime")) {
        return &.{
            "arch/jitterentropy-arch-memory.c",
            "arch/jitterentropy-arch-ncpu.c",
            "arch/jitterentropy-arch-thread.c",
            "arch/jitterentropy-arch-timer.c",
        };
    }
    return &.{};
}

fn addLibrarySourcesExcluding(
    b: *std.Build,
    mod: *std.Build.Module,
    c_flags: []const []const u8,
    excluded: []const []const u8,
) void {
    for (lib_c_sources) |src| {
        var skip = false;
        for (excluded) |ex| {
            if (std.mem.eql(u8, src, ex)) {
                skip = true;
                break;
            }
        }
        if (!skip) {
            mod.addCSourceFile(.{
                .file = b.path(src),
                .flags = c_flags,
            });
        }
    }
}

fn addUnitTestExecutable(
    b: *std.Build,
    name: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    opts: BuildOptions,
    zig_core_lib: ?*std.Build.Step.Compile,
    c_flags: []const []const u8,
    enable_mock_timer: bool,
) *std.Build.Step.Compile {
    const mod = createCModule(b, target, optimize, opts, null);
    if (zig_core_lib) |core_lib| {
        mod.linkLibrary(core_lib);
        addLibrarySourcesExcluding(b, mod, c_flags, excludedSourcesForUnitTest(name));
    }
    configureIncludePaths(b, mod);
    mod.addIncludePath(b.path("tests"));
    configureCommonDefines(b, mod, target, opts, .static, false);
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
    if (opts.sanitizers) {
        try list.appendSlice(b.allocator, &.{
            "-fsanitize=undefined",
            "-fno-sanitize=function",
            "-fno-sanitize-recover=all",
            "-fno-omit-frame-pointer",
            "-g",
        });
    }
    if (opts.tsan) {
        try list.appendSlice(b.allocator, &.{
            "-fsanitize=thread",
            "-fno-omit-frame-pointer",
            "-g",
        });
    }
    if (opts.coverage) {
        try list.appendSlice(b.allocator, &.{
            "--coverage",
            "-g",
        });
    }
    try list.appendSlice(b.allocator, extra);
    return list.toOwnedSlice(b.allocator);
}

fn extractLdsExports(allocator: std.mem.Allocator, lds_content: []const u8) [][]const u8 {
    var list: std.ArrayListUnmanaged([]const u8) = .empty;
    var lines = std.mem.splitScalar(u8, lds_content, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (std.mem.startsWith(u8, line, "jent_") and std.mem.endsWith(u8, line, ";")) {
            const sym = std.mem.trim(u8, line[0 .. line.len - 1], " \t\r");
            list.append(allocator, sym) catch @panic("OOM");
        }
    }
    return list.toOwnedSlice(allocator) catch @panic("OOM");
}

fn extractHeaderExports(
    allocator: std.mem.Allocator,
    header_content: []const u8,
    macro_name: []const u8,
    exclude: []const []const u8,
) [][]const u8 {
    var list: std.ArrayListUnmanaged([]const u8) = .empty;
    var lines = std.mem.splitScalar(u8, header_content, '\n');
    var expect_fn_decl = false;
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (expect_fn_decl) {
            expect_fn_decl = false;
            const paren_idx = std.mem.indexOfScalar(u8, line, '(') orelse continue;
            var end = paren_idx;
            while (end > 0 and (line[end - 1] == ' ' or line[end - 1] == '\t')) : (end -= 1) {}
            var start = end;
            while (start > 0 and isIdentChar(line[start - 1])) : (start -= 1) {}
            if (start < end) {
                const fn_name = line[start..end];
                if (std.mem.startsWith(u8, fn_name, "jent_")) {
                    var excluded = false;
                    for (exclude) |ex| {
                        if (std.mem.eql(u8, fn_name, ex)) {
                            excluded = true;
                            break;
                        }
                    }
                    if (!excluded) {
                        list.append(allocator, fn_name) catch @panic("OOM");
                    }
                }
            }
        } else if (std.mem.eql(u8, line, macro_name)) {
            expect_fn_decl = true;
        }
    }
    return list.toOwnedSlice(allocator) catch @panic("OOM");
}

fn isIdentChar(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_';
}

fn stringLessThan(_: void, a: []const u8, b: []const u8) bool {
    return std.mem.order(u8, a, b) == .lt;
}

fn verifyVersionScript(
    b: *std.Build,
    comptime header_path: []const u8,
    comptime script_path: []const u8,
    macro_name: []const u8,
    exclude: []const []const u8,
) void {
    const header_content = @embedFile(header_path);
    const script_content = @embedFile(script_path);

    const header_fns = extractHeaderExports(b.allocator, header_content, macro_name, exclude);
    const script_fns = extractLdsExports(b.allocator, script_content);

    std.mem.sort([]const u8, header_fns, {}, stringLessThan);
    std.mem.sort([]const u8, script_fns, {}, stringLessThan);

    var match = header_fns.len == script_fns.len;
    if (match) {
        for (header_fns, script_fns) |h, s| {
            if (!std.mem.eql(u8, h, s)) {
                match = false;
                break;
            }
        }
    }
    if (!match) {
        std.debug.panic(
            "{s} is out of date with {s}: header has {d} exports, script has {d}",
            .{ script_path, header_path, header_fns.len, script_fns.len },
        );
    }
}

fn hasFunctionCall(source_content: []const u8, fn_name: []const u8) bool {
    var pos: usize = 0;
    while (std.mem.indexOfPos(u8, source_content, pos, fn_name)) |idx| {
        pos = idx + fn_name.len;
        if (idx > 0 and isIdentChar(source_content[idx - 1])) continue;
        var after = pos;
        while (after < source_content.len and (source_content[after] == ' ' or source_content[after] == '\t')) : (after += 1) {}
        if (after < source_content.len and source_content[after] == '(') {
            return true;
        }
    }
    return false;
}

fn verifyLinktestCalls(
    b: *std.Build,
    comptime script_path: []const u8,
    comptime source_path: []const u8,
) void {
    const script_content = @embedFile(script_path);
    const source_content = @embedFile(source_path);
    const script_fns = extractLdsExports(b.allocator, script_content);

    for (script_fns) |fn_name| {
        if (!hasFunctionCall(source_content, fn_name)) {
            std.debug.panic(
                "{s} does not call exported function {s} from {s}",
                .{ source_path, fn_name, script_path },
            );
        }
    }
}

fn addEfiTargets(b: *std.Build) void {
    const wf = b.addWriteFiles();
    _ = wf.add("include/efi.h", efi_h_source);
    _ = wf.add("include/efilib.h", efilib_h_source);
    _ = wf.add("include/sys/types.h", "typedef __PTRDIFF_TYPE__ ssize_t;\n");
    _ = wf.add("include/sys/stat.h", "#pragma once\n");
    _ = wf.add("include/fcntl.h", "#pragma once\n");
    _ = wf.add("include/unistd.h", "#pragma once\n");
    _ = wf.add("include/time.h", "#pragma once\n");
    _ = wf.add("include/errno.h", efi_errno_h_source);
    _ = wf.add("include/stdlib.h", efi_stdlib_h_source);
    _ = wf.add("include/string.h", efi_string_h_source);
    _ = wf.add("include/stdio.h", efi_stdio_h_source);
    const efi_support_c = wf.add("efi_support.c", efi_support_c_source);
    const efi_inc_dir = wf.getDirectory().path(b, "include");

    const EfiTargetSpec = struct {
        arch: std.Target.Cpu.Arch,
        boot_name: []const u8,
        extra_flags: []const []const u8,
    };
    const specs: []const EfiTargetSpec = &.{
        .{
            .arch = .x86_64,
            .boot_name = "BOOTX64.EFI",
            .extra_flags = &.{"-mno-red-zone"},
        },
        .{
            .arch = .aarch64,
            .boot_name = "BOOTAA64.EFI",
            .extra_flags = &.{"-mno-outline-atomics"},
        },
    };

    for (specs) |spec| {
        const uefi_target = b.resolveTargetQuery(.{
            .cpu_arch = spec.arch,
            .os_tag = .uefi,
            .abi = .msvc,
        });
        var efi_flags_list: std.ArrayListUnmanaged([]const u8) = .empty;
        efi_flags_list.appendSlice(b.allocator, &.{
            "-std=gnu11",
            "-O0",
            "-ffreestanding",
            "-fno-stack-protector",
            "-fshort-wchar",
            "-fwrapv",
            "-U_MSC_VER",
            "-U_MSC_BUILD",
            "-U_MSC_FULL_VER",
            "-U_WIN32",
            "-U_WIN64",
            "-fgnuc-version=4.2.1",
            "-Wall",
            "-Wextra",
        }) catch @panic("OOM");
        efi_flags_list.appendSlice(b.allocator, spec.extra_flags) catch @panic("OOM");
        const efi_flags = efi_flags_list.toOwnedSlice(b.allocator) catch @panic("OOM");

        const efi_mod = b.createModule(.{
            .target = uefi_target,
            .optimize = .Debug,
            .link_libc = false,
            .pic = true,
            .red_zone = if (spec.arch == .x86_64) false else null,
            .stack_check = false,
            .stack_protector = false,
        });
        efi_mod.addIncludePath(efi_inc_dir);
        configureIncludePaths(b, efi_mod);
        efi_mod.addCMacro("JENT_CONF_ENABLE_INTERNAL_TIMER", "1");
        efi_mod.addCSourceFiles(.{
            .files = lib_c_sources,
            .flags = efi_flags,
        });
        efi_mod.addCSourceFile(.{
            .file = b.path("tests/efi/jitterentropy-efi.c"),
            .flags = efi_flags,
        });
        efi_mod.addCSourceFile(.{
            .file = efi_support_c,
            .flags = efi_flags,
        });

        const efi_exe = b.addExecutable(.{
            .name = spec.boot_name[0 .. spec.boot_name.len - 4],
            .root_module = efi_mod,
        });
        efi_exe.entry = .{ .symbol_name = "efi_main" };
        efi_exe.subsystem = .efi_application;

        const dest_flat = std.fmt.allocPrint(b.allocator, "efi/{s}", .{spec.boot_name}) catch @panic("OOM");
        const dest_esp = std.fmt.allocPrint(b.allocator, "efi/EFI/BOOT/{s}", .{spec.boot_name}) catch @panic("OOM");
        b.getInstallStep().dependOn(&b.addInstallFile(efi_exe.getEmittedBin(), dest_flat).step);
        b.getInstallStep().dependOn(&b.addInstallFile(efi_exe.getEmittedBin(), dest_esp).step);
    }
}

const test_runner_c_source =
    \\#include <stdlib.h>
    \\#include <string.h>
    \\#if defined(_WIN32)
    \\#include <process.h>
    \\int main(int argc, char **argv) {
    \\    if (argc < 2) return 2;
    \\    intptr_t rc = _spawnv(_P_WAIT, argv[1], (const char *const *)&argv[1]);
    \\    if (rc < 0) return 127;
    \\    const char *strict = getenv("JENT_UT_STRICT");
    \\    if (rc == 77 && (!strict || strict[0] == '\0' || strcmp(strict, "0") == 0))
    \\        return 0;
    \\    return (int)rc;
    \\}
    \\#else
    \\#include <sys/types.h>
    \\#include <sys/wait.h>
    \\#include <unistd.h>
    \\int main(int argc, char **argv) {
    \\    if (argc < 2) return 2;
    \\    pid_t pid = fork();
    \\    if (pid < 0) return 127;
    \\    if (pid == 0) {
    \\        execv(argv[1], &argv[1]);
    \\        _exit(127);
    \\    }
    \\    int status = 0;
    \\    if (waitpid(pid, &status, 0) < 0) return 127;
    \\    if (WIFEXITED(status)) {
    \\        int rc = WEXITSTATUS(status);
    \\        const char *strict = getenv("JENT_UT_STRICT");
    \\        if (rc == 77 && (!strict || strict[0] == '\0' || strcmp(strict, "0") == 0))
    \\            return 0;
    \\        return rc;
    \\    }
    \\    if (WIFSIGNALED(status)) return 128 + WTERMSIG(status);
    \\    return 1;
    \\}
    \\#endif
;

const fuzz_driver_c_source =
    \\#include <stdint.h>
    \\#include <stddef.h>
    \\#include <stdio.h>
    \\#include <stdlib.h>
    \\#include <string.h>
    \\#include <time.h>
    \\
    \\int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size);
    \\
    \\static uint64_t prng_state = 0x853c49e6748fea9bULL;
    \\static uint64_t next_u64(void) {
    \\    uint64_t x = prng_state;
    \\    x ^= x >> 12;
    \\    x ^= x << 25;
    \\    x ^= x >> 27;
    \\    prng_state = x;
    \\    return x * 0x2545f4914f6cdd1dULL;
    \\}
    \\
    \\int main(int argc, char **argv) {
    \\    long max_total_time = 0;
    \\    size_t max_len = 4096;
    \\    long max_runs = -1;
    \\    const char *corpus_dir = NULL;
    \\    for (int i = 1; i < argc; i++) {
    \\        if (strncmp(argv[i], "-max_total_time=", 16) == 0) {
    \\            max_total_time = atol(argv[i] + 16);
    \\        } else if (strncmp(argv[i], "-max_len=", 9) == 0) {
    \\            size_t v = (size_t)atol(argv[i] + 9);
    \\            if (v > 0 && v <= 65536) max_len = v;
    \\        } else if (strncmp(argv[i], "-runs=", 6) == 0) {
    \\            max_runs = atol(argv[i] + 6);
    \\        } else if (argv[i][0] != '-') {
    \\            corpus_dir = argv[i];
    \\        }
    \\    }
    \\    uint8_t *buf = (uint8_t *)malloc(max_len ? max_len : 1);
    \\    if (!buf) return 1;
    \\    LLVMFuzzerTestOneInput(buf, 0);
    \\    time_t start = time(NULL);
    \\    long runs = 1;
    \\    while (1) {
    \\        if (max_runs >= 0 && runs >= max_runs) break;
    \\        if (max_total_time > 0 && (long)(time(NULL) - start) >= max_total_time) break;
    \\        if (max_runs < 0 && max_total_time <= 0 && runs >= 256) break;
    \\        size_t len = (size_t)(next_u64() % (max_len + 1));
    \\        for (size_t j = 0; j < len; j++) {
    \\            buf[j] = (uint8_t)(next_u64() & 0xff);
    \\        }
    \\        LLVMFuzzerTestOneInput(buf, len);
    \\        runs++;
    \\    }
    \\    if (corpus_dir) {
    \\        char path[1024];
    \\        int n = snprintf(path, sizeof(path), "%s/seed-0", corpus_dir);
    \\        if (n > 0 && (size_t)n < sizeof(path)) {
    \\            FILE *f = fopen(path, "wb");
    \\            if (f) {
    \\                fwrite(buf, 1, max_len < 64 ? max_len : 64, f);
    \\                fclose(f);
    \\            }
    \\        }
    \\    }
    \\    free(buf);
    \\    return 0;
    \\}
;

const gcov_runtime_c_source =
    \\#include <stdint.h>
    \\#include <stdio.h>
    \\#include <stdlib.h>
    \\
    \\typedef void (*gcov_fn)(void);
    \\struct gcov_Node {
    \\    gcov_fn writeout;
    \\    gcov_fn reset;
    \\    struct gcov_Node *next;
    \\};
    \\static struct gcov_Node *gcov_head = NULL;
    \\static int gcov_atexit_registered = 0;
    \\static FILE *gcda_file = NULL;
    \\
    \\static void gcov_writeout_all(void) {
    \\    for (struct gcov_Node *n = gcov_head; n; n = n->next) {
    \\        if (n->writeout) n->writeout();
    \\    }
    \\}
    \\
    \\__attribute__((weak, visibility("hidden")))
    \\void llvm_gcov_init(gcov_fn writeout, gcov_fn reset) {
    \\    struct gcov_Node *node = (struct gcov_Node *)malloc(sizeof(*node));
    \\    if (!node) return;
    \\    node->writeout = writeout;
    \\    node->reset = reset;
    \\    node->next = gcov_head;
    \\    gcov_head = node;
    \\    if (!gcov_atexit_registered) {
    \\        gcov_atexit_registered = 1;
    \\        atexit(gcov_writeout_all);
    \\    }
    \\}
    \\
    \\__attribute__((weak, visibility("hidden")))
    \\void llvm_gcda_start_file(const char *orig_filename, uint32_t version, uint32_t checksum) {
    \\    gcda_file = fopen(orig_filename, "wb");
    \\    if (!gcda_file) return;
    \\    const char magic[4] = { 'a', 'd', 'c', 'g' };
    \\    fwrite(magic, 1, 4, gcda_file);
    \\    fwrite(&version, 4, 1, gcda_file);
    \\    fwrite(&checksum, 4, 1, gcda_file);
    \\}
    \\
    \\__attribute__((weak, visibility("hidden")))
    \\void llvm_gcda_emit_function(uint32_t ident, uint32_t func_checksum, uint32_t cfg_checksum) {
    \\    if (!gcda_file) return;
    \\    uint32_t hdr[5] = { 0x01000000U, 3U, ident, func_checksum, cfg_checksum };
    \\    fwrite(hdr, 4, 5, gcda_file);
    \\}
    \\
    \\__attribute__((weak, visibility("hidden")))
    \\void llvm_gcda_emit_arcs(uint32_t num_counters, uint64_t *counters) {
    \\    if (!gcda_file) return;
    \\    uint32_t hdr[2] = { 0x01a10000U, num_counters * 2U };
    \\    fwrite(hdr, 4, 2, gcda_file);
    \\    for (uint32_t i = 0; i < num_counters; i++) {
    \\        uint32_t lo = (uint32_t)(counters[i] & 0xffffffffULL);
    \\        uint32_t hi = (uint32_t)(counters[i] >> 32);
    \\        fwrite(&lo, 4, 1, gcda_file);
    \\        fwrite(&hi, 4, 1, gcda_file);
    \\    }
    \\}
    \\
    \\__attribute__((weak, visibility("hidden")))
    \\void llvm_gcda_summary_info(void) {
    \\    if (!gcda_file) return;
    \\    uint32_t summary[4] = { 0xa1000000U, 2U, 1U, 0U };
    \\    fwrite(summary, 4, 4, gcda_file);
    \\}
    \\
    \\__attribute__((weak, visibility("hidden")))
    \\void llvm_gcda_end_file(void) {
    \\    if (!gcda_file) return;
    \\    uint32_t eof[2] = { 0U, 0U };
    \\    fwrite(eof, 4, 2, gcda_file);
    \\    fclose(gcda_file);
    \\    gcda_file = NULL;
    \\}
;

const efi_errno_h_source =
    \\#pragma once
    \\#define EPERM 1
    \\#define ENOENT 2
    \\#define ESRCH 3
    \\#define EINTR 4
    \\#define EIO 5
    \\#define EAGAIN 11
    \\#define ENOMEM 12
    \\#define EACCES 13
    \\#define EFAULT 14
    \\#define EINVAL 22
    \\#define ENOSYS 38
    \\#define EOPNOTSUPP 95
    \\#define ENOTSUP EOPNOTSUPP
    \\#define ECANCELED 125
;

const efi_stdlib_h_source =
    \\#pragma once
    \\#include <stddef.h>
    \\void *malloc(size_t size);
    \\void free(void *ptr);
;

const efi_string_h_source =
    \\#pragma once
    \\#include <stddef.h>
    \\void *memcpy(void *dst, const void *src, size_t n);
    \\void *memset(void *dst, int c, size_t n);
    \\size_t strlen(const char *s);
;

const efi_stdio_h_source =
    \\#pragma once
    \\#include <stddef.h>
    \\int snprintf(char *buf, size_t size, const char *fmt, ...);
;

const efi_h_source =
    \\#pragma once
    \\#include <stdarg.h>
    \\#include <stddef.h>
    \\#include <stdint.h>
    \\
    \\#if defined(__x86_64__)
    \\#define EFIAPI __attribute__((ms_abi))
    \\#else
    \\#define EFIAPI
    \\#endif
    \\
    \\typedef __WCHAR_TYPE__ CHAR16;
    \\typedef size_t UINTN;
    \\typedef uint64_t UINT64;
    \\typedef int64_t INT64;
    \\typedef size_t EFI_STATUS;
    \\typedef void *EFI_HANDLE;
    \\
    \\#define EFI_SUCCESS ((EFI_STATUS)0)
    \\#define EFI_DEVICE_ERROR ((EFI_STATUS)((1ULL << 63) | 7ULL))
    \\#define EFI_OUT_OF_RESOURCES ((EFI_STATUS)((1ULL << 63) | 9ULL))
    \\
    \\typedef enum {
    \\    EfiResetCold = 0,
    \\    EfiResetWarm = 1,
    \\    EfiResetShutdown = 2,
    \\    EfiResetPlatformSpecific = 3
    \\} EFI_RESET_TYPE;
    \\
    \\typedef enum {
    \\    EfiReservedMemoryType = 0,
    \\    EfiLoaderCode = 1,
    \\    EfiLoaderData = 2,
    \\    EfiBootServicesCode = 3,
    \\    EfiBootServicesData = 4
    \\} EFI_MEMORY_TYPE;
    \\
    \\typedef struct {
    \\    uint64_t Signature;
    \\    uint32_t Revision;
    \\    uint32_t HeaderSize;
    \\    uint32_t CRC32;
    \\    uint32_t Reserved;
    \\} EFI_TABLE_HEADER;
    \\
    \\struct _SIMPLE_TEXT_OUTPUT_INTERFACE;
    \\typedef EFI_STATUS (EFIAPI *EFI_TEXT_RESET)(struct _SIMPLE_TEXT_OUTPUT_INTERFACE *This, uint8_t ExtendedVerification);
    \\typedef EFI_STATUS (EFIAPI *EFI_TEXT_OUTPUT_STRING)(struct _SIMPLE_TEXT_OUTPUT_INTERFACE *This, const CHAR16 *String);
    \\
    \\typedef struct _SIMPLE_TEXT_OUTPUT_INTERFACE {
    \\    EFI_TEXT_RESET Reset;
    \\    EFI_TEXT_OUTPUT_STRING OutputString;
    \\    void *TestString;
    \\    void *QueryMode;
    \\    void *SetMode;
    \\    void *SetAttribute;
    \\    void *ClearScreen;
    \\    void *SetCursorPosition;
    \\    void *EnableCursor;
    \\    void *Mode;
    \\} SIMPLE_TEXT_OUTPUT_INTERFACE;
    \\
    \\typedef EFI_STATUS (EFIAPI *EFI_ALLOCATE_POOL)(EFI_MEMORY_TYPE PoolType, UINTN Size, void **Buffer);
    \\typedef EFI_STATUS (EFIAPI *EFI_FREE_POOL)(void *Buffer);
    \\
    \\typedef struct {
    \\    EFI_TABLE_HEADER Hdr;
    \\    void *RaiseTPL;
    \\    void *RestoreTPL;
    \\    void *AllocatePages;
    \\    void *FreePages;
    \\    void *GetMemoryMap;
    \\    EFI_ALLOCATE_POOL AllocatePool;
    \\    EFI_FREE_POOL FreePool;
    \\} EFI_BOOT_SERVICES;
    \\
    \\typedef void (EFIAPI *EFI_RESET_SYSTEM)(EFI_RESET_TYPE ResetType, EFI_STATUS ResetStatus, UINTN DataSize, CHAR16 *ResetData);
    \\
    \\typedef struct {
    \\    EFI_TABLE_HEADER Hdr;
    \\    void *GetTime;
    \\    void *SetTime;
    \\    void *GetWakeupTime;
    \\    void *SetWakeupTime;
    \\    void *SetVirtualAddressMap;
    \\    void *ConvertPointer;
    \\    void *GetVariable;
    \\    void *GetNextVariableName;
    \\    void *SetVariable;
    \\    void *GetNextHighMonotonicCount;
    \\    EFI_RESET_SYSTEM ResetSystem;
    \\} EFI_RUNTIME_SERVICES;
    \\
    \\typedef struct {
    \\    EFI_TABLE_HEADER Hdr;
    \\    CHAR16 *FirmwareVendor;
    \\    uint32_t FirmwareRevision;
    \\    EFI_HANDLE ConsoleInHandle;
    \\    void *ConIn;
    \\    EFI_HANDLE ConsoleOutHandle;
    \\    SIMPLE_TEXT_OUTPUT_INTERFACE *ConOut;
    \\    EFI_HANDLE StandardErrorHandle;
    \\    SIMPLE_TEXT_OUTPUT_INTERFACE *StdErr;
    \\    EFI_RUNTIME_SERVICES *RuntimeServices;
    \\    EFI_BOOT_SERVICES *BootServices;
    \\    UINTN NumberOfTableEntries;
    \\    void *ConfigurationTable;
    \\} EFI_SYSTEM_TABLE;
    \\
    \\#define uefi_call_wrapper(func, va_num, ...) func(__VA_ARGS__)
;

const efilib_h_source =
    \\#pragma once
    \\#include <efi.h>
    \\
    \\extern EFI_RUNTIME_SERVICES *RT;
    \\
    \\void InitializeLib(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable);
    \\void *AllocatePool(UINTN Size);
    \\void FreePool(void *Buffer);
    \\UINTN Print(const CHAR16 *fmt, ...);
;

const efi_support_c_source =
    \\#include <efi.h>
    \\#include <efilib.h>
    \\#include <stdarg.h>
    \\
    \\static EFI_SYSTEM_TABLE *ST = NULL;
    \\static EFI_BOOT_SERVICES *BS = NULL;
    \\EFI_RUNTIME_SERVICES *RT = NULL;
    \\
    \\void InitializeLib(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    \\    (void)ImageHandle;
    \\    ST = SystemTable;
    \\    BS = SystemTable ? SystemTable->BootServices : NULL;
    \\    RT = SystemTable ? SystemTable->RuntimeServices : NULL;
    \\}
    \\
    \\void *AllocatePool(UINTN Size) {
    \\    void *p = NULL;
    \\    if (!BS || BS->AllocatePool(EfiBootServicesData, Size, &p) != EFI_SUCCESS)
    \\        return NULL;
    \\    return p;
    \\}
    \\
    \\void FreePool(void *Buffer) {
    \\    if (BS && Buffer)
    \\        BS->FreePool(Buffer);
    \\}
    \\
    \\void *memcpy(void *dst, const void *src, size_t n) {
    \\    uint8_t *d = (uint8_t *)dst;
    \\    const uint8_t *s = (const uint8_t *)src;
    \\    for (size_t i = 0; i < n; i++) d[i] = s[i];
    \\    return dst;
    \\}
    \\
    \\void *memset(void *dst, int c, size_t n) {
    \\    uint8_t *d = (uint8_t *)dst;
    \\    for (size_t i = 0; i < n; i++) d[i] = (uint8_t)c;
    \\    return dst;
    \\}
    \\
    \\static void efi_putc(CHAR16 ch, CHAR16 *buf, size_t *pos, size_t cap) {
    \\    if (ch == L'\n') {
    \\        if (*pos + 2 >= cap && ST && ST->ConOut) {
    \\            buf[*pos] = 0;
    \\            ST->ConOut->OutputString(ST->ConOut, buf);
    \\            *pos = 0;
    \\        }
    \\        buf[(*pos)++] = L'\r';
    \\    }
    \\    if (*pos + 1 >= cap && ST && ST->ConOut) {
    \\        buf[*pos] = 0;
    \\        ST->ConOut->OutputString(ST->ConOut, buf);
    \\        *pos = 0;
    \\    }
    \\    buf[(*pos)++] = ch;
    \\}
    \\
    \\static void efi_put_uint(uint64_t val, unsigned int base, int width, CHAR16 pad, CHAR16 *buf, size_t *pos, size_t cap) {
    \\    CHAR16 tmp[32];
    \\    int n = 0;
    \\    do {
    \\        unsigned int d = (unsigned int)(val % base);
    \\        tmp[n++] = (CHAR16)(d < 10 ? (L'0' + d) : (L'a' + (d - 10)));
    \\        val /= base;
    \\    } while (val > 0);
    \\    while (n < width) {
    \\        efi_putc(pad, buf, pos, cap);
    \\        width--;
    \\    }
    \\    while (n > 0) {
    \\        efi_putc(tmp[--n], buf, pos, cap);
    \\    }
    \\}
    \\
    \\UINTN Print(const CHAR16 *fmt, ...) {
    \\    CHAR16 buf[256];
    \\    size_t pos = 0;
    \\    va_list ap;
    \\    va_start(ap, fmt);
    \\    for (; *fmt; fmt++) {
    \\        if (*fmt != L'%') {
    \\            efi_putc(*fmt, buf, &pos, sizeof(buf) / sizeof(buf[0]));
    \\            continue;
    \\        }
    \\        fmt++;
    \\        CHAR16 pad = L' ';
    \\        if (*fmt == L'0') {
    \\            pad = L'0';
    \\            fmt++;
    \\        }
    \\        int width = 0;
    \\        while (*fmt >= L'0' && *fmt <= L'9') {
    \\            width = width * 10 + (int)(*fmt - L'0');
    \\            fmt++;
    \\        }
    \\        if (*fmt == L'c') {
    \\            CHAR16 c = (CHAR16)va_arg(ap, int);
    \\            efi_putc(c, buf, &pos, sizeof(buf) / sizeof(buf[0]));
    \\        } else if (*fmt == L's') {
    \\            const CHAR16 *s = va_arg(ap, const CHAR16 *);
    \\            if (!s) s = L"(null)";
    \\            while (*s) efi_putc(*s++, buf, &pos, sizeof(buf) / sizeof(buf[0]));
    \\        } else if (*fmt == L'd') {
    \\            int v = va_arg(ap, int);
    \\            uint64_t u;
    \\            if (v < 0) {
    \\                efi_putc(L'-', buf, &pos, sizeof(buf) / sizeof(buf[0]));
    \\                u = (uint64_t)(-(int64_t)v);
    \\            } else {
    \\                u = (uint64_t)v;
    \\            }
    \\            efi_put_uint(u, 10, width, pad, buf, &pos, sizeof(buf) / sizeof(buf[0]));
    \\        } else if (*fmt == L'u') {
    \\            unsigned int v = va_arg(ap, unsigned int);
    \\            efi_put_uint(v, 10, width, pad, buf, &pos, sizeof(buf) / sizeof(buf[0]));
    \\        } else if (*fmt == L'x') {
    \\            unsigned int v = va_arg(ap, unsigned int);
    \\            efi_put_uint(v, 16, width, pad, buf, &pos, sizeof(buf) / sizeof(buf[0]));
    \\        } else if (*fmt) {
    \\            efi_putc(*fmt, buf, &pos, sizeof(buf) / sizeof(buf[0]));
    \\        } else {
    \\            break;
    \\        }
    \\    }
    \\    va_end(ap);
    \\    if (pos > 0 && ST && ST->ConOut) {
    \\        buf[pos] = 0;
    \\        ST->ConOut->OutputString(ST->ConOut, buf);
    \\    }
    \\    return pos;
    \\}
    \\
    \\EFI_STATUS EFIAPI efi_main(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable);
    \\EFI_STATUS EFIAPI EfiMain(EFI_HANDLE ImageHandle, EFI_SYSTEM_TABLE *SystemTable) {
    \\    return efi_main(ImageHandle, SystemTable);
    \\}
    \\
    \\void __chkstk(void) {}
;
