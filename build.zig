const std = @import("std");

const jitterentropy_version = std.SemanticVersion{
    .major = 3,
    .minor = 8,
    .patch = 0,
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
    extra_include_dirs: ?[]const u8,
    extra_lib_dirs: ?[]const u8,
    sanitizers: bool,
    tsan: bool,
    fuzzing: bool,
    coverage: bool,
    coverage_rt_file: ?std.Build.LazyPath,
};

fn installLibrary(
    b: *std.Build,
    library: *std.Build.Step.Compile,
    linkage: std.builtin.LinkMode,
    os_tag: std.Target.Os.Tag,
    native_target: bool,
    archive_name: []const u8,
) void {
    _ = linkage;
    _ = os_tag;
    _ = native_target;
    _ = archive_name;
    b.installArtifact(library);
}

pub fn build(b: *std.Build) void {
    var target = b.standardTargetOptions(.{});
    if (target.query.isNative() and target.result.os.tag == .linux and target.result.isGnuLibC()) {
        const host_glibc = detectHostGnuLibCVersion(b, target.result);
        if (host_glibc.order(.{ .major = 2, .minor = 31, .patch = 0 }) == .lt) {
            target = b.resolveTargetQuery(.{
                .cpu_arch = target.result.cpu.arch,
                .cpu_model = .native,
                .os_tag = .linux,
                .abi = target.result.abi,
                .glibc_version = host_glibc,
            });
        }
    }
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

    const extra_include_dirs = b.option(
        []const u8,
        "include-dirs",
        "Colon-separated extra include directories for external crypto libraries",
    );

    const extra_lib_dirs = b.option(
        []const u8,
        "lib-dirs",
        "Colon-separated extra library directories for external crypto libraries",
    );

    const install_tests = b.option(
        bool,
        "install-tests",
        "Install unit and link test executables into zig-out/bin (default: false)",
    ) orelse false;

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
        .extra_include_dirs = extra_include_dirs,
        .extra_lib_dirs = extra_lib_dirs,
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
    build_options.addOption(ExternalCrypto, "external_crypto", external_crypto);
    build_options.addOption(?[]const u8, "aarch64_nstime_register", aarch64_nstime_register);
    build_options.addOption(bool, "export_public_api", true);
    build_options.addOption(bool, "export_internals", false);
    build_options.addOption(bool, "weak_internals", false);
    build_options.addOption(bool, "export_random_data", true);

    const internal_build_options = b.addOptions();
    internal_build_options.addOption(bool, "internal_timer", internal_timer);
    internal_build_options.addOption(bool, "mock_timer", mock_timer);
    internal_build_options.addOption(bool, "raw_memory_access", raw_memory_access);
    internal_build_options.addOption(bool, "stack_protector", stack_protector);
    internal_build_options.addOption(std.builtin.LinkMode, "linkage", .static);
    internal_build_options.addOption(ExternalCrypto, "external_crypto", external_crypto);
    internal_build_options.addOption(?[]const u8, "aarch64_nstime_register", aarch64_nstime_register);
    internal_build_options.addOption(bool, "export_public_api", false);
    internal_build_options.addOption(bool, "export_internals", true);
    internal_build_options.addOption(bool, "weak_internals", false);
    internal_build_options.addOption(bool, "export_random_data", true);

    const mock_build_options = b.addOptions();
    mock_build_options.addOption(bool, "internal_timer", internal_timer);
    mock_build_options.addOption(bool, "mock_timer", true);
    mock_build_options.addOption(bool, "raw_memory_access", raw_memory_access);
    mock_build_options.addOption(bool, "stack_protector", stack_protector);
    mock_build_options.addOption(std.builtin.LinkMode, "linkage", .static);
    mock_build_options.addOption(ExternalCrypto, "external_crypto", external_crypto);
    mock_build_options.addOption(?[]const u8, "aarch64_nstime_register", aarch64_nstime_register);
    mock_build_options.addOption(bool, "export_public_api", false);
    mock_build_options.addOption(bool, "export_internals", true);
    mock_build_options.addOption(bool, "weak_internals", false);
    mock_build_options.addOption(bool, "export_random_data", true);

    const record_build_options = b.addOptions();
    record_build_options.addOption(bool, "internal_timer", internal_timer);
    record_build_options.addOption(bool, "mock_timer", mock_timer);
    record_build_options.addOption(bool, "raw_memory_access", raw_memory_access);
    record_build_options.addOption(bool, "stack_protector", stack_protector);
    record_build_options.addOption(std.builtin.LinkMode, "linkage", linkage);
    record_build_options.addOption(ExternalCrypto, "external_crypto", external_crypto);
    record_build_options.addOption(?[]const u8, "aarch64_nstime_register", aarch64_nstime_register);
    record_build_options.addOption(bool, "export_public_api", false);
    record_build_options.addOption(bool, "export_internals", false);
    record_build_options.addOption(bool, "weak_internals", true);
    record_build_options.addOption(bool, "export_random_data", true);

    const override_build_options = b.addOptions();
    override_build_options.addOption(bool, "internal_timer", internal_timer);
    override_build_options.addOption(bool, "mock_timer", mock_timer);
    override_build_options.addOption(bool, "raw_memory_access", raw_memory_access);
    override_build_options.addOption(bool, "stack_protector", stack_protector);
    override_build_options.addOption(std.builtin.LinkMode, "linkage", .static);
    override_build_options.addOption(ExternalCrypto, "external_crypto", external_crypto);
    override_build_options.addOption(?[]const u8, "aarch64_nstime_register", aarch64_nstime_register);
    override_build_options.addOption(bool, "export_public_api", false);
    override_build_options.addOption(bool, "export_internals", true);
    override_build_options.addOption(bool, "weak_internals", false);
    override_build_options.addOption(bool, "export_random_data", false);

    const record_options = b.addOptions();
    record_options.addOption(bool, "raw_memory_access", raw_memory_access);

    const os_tag = target.result.os.tag;
    const recording_tool_options = b.addOptions();
    recording_tool_options.addOption(bool, "libgcrypt", external_crypto == .libgcrypt);
    recording_tool_options.addOption(
        bool,
        "openssl",
        external_crypto == .openssl or external_crypto == .awslc,
    );
    recording_tool_options.addOption(
        bool,
        "cpu_pinning",
        os_tag == .linux or os_tag == .freebsd or os_tag == .netbsd or
            os_tag == .windows,
    );
    const c_flags = getCFlags(b, target, opts, &.{}) catch @panic("OOM");

    const zig_core_mod = createCModule(b, target, .Debug, opts, if (os_tag == .windows) null else true);
    zig_core_mod.root_source_file = b.path("src/root.zig");
    zig_core_mod.addOptions("build_options", internal_build_options);
    configureIncludePaths(b, zig_core_mod);
    configureCommonDefines(b, zig_core_mod, target, opts, .static, false);
    const zig_core_lib = b.addLibrary(.{
        .name = "jitterentropy-zig-core",
        .linkage = .static,
        .root_module = zig_core_mod,
        .use_llvm = true,
    });

    const override_core_mod = createCModule(b, target, .Debug, opts, if (os_tag == .windows) null else true);
    override_core_mod.root_source_file = b.path("src/root.zig");
    override_core_mod.addOptions("build_options", override_build_options);
    configureIncludePaths(b, override_core_mod);
    configureCommonDefines(b, override_core_mod, target, opts, .static, false);
    configureSystemLibraries(override_core_mod, target, opts);

    var mock_opts = opts;
    mock_opts.mock_timer = true;
    const zig_core_mock_mod = createCModule(b, target, .Debug, mock_opts, if (os_tag == .windows) null else true);
    zig_core_mock_mod.root_source_file = b.path("src/root.zig");
    zig_core_mock_mod.addOptions("build_options", mock_build_options);
    configureIncludePaths(b, zig_core_mock_mod);
    configureCommonDefines(b, zig_core_mock_mod, target, mock_opts, .static, false);
    const zig_core_mock_lib = b.addLibrary(.{
        .name = "jitterentropy-zig-core-mock",
        .linkage = .static,
        .root_module = zig_core_mock_mod,
        .use_llvm = true,
    });

    const lib_mod = createCModule(b, target, .Debug, opts, if (os_tag == .windows) null else true);
    lib_mod.root_source_file = b.path("src/root.zig");
    lib_mod.addOptions("build_options", build_options);
    configureIncludePaths(b, lib_mod);
    configureCommonDefines(b, lib_mod, target, opts, linkage, true);
    configureSystemLibraries(lib_mod, target, opts);
    const lib = b.addLibrary(.{
        .name = "jitterentropy",
        .linkage = linkage,
        .version = jitterentropy_version,
        .root_module = lib_mod,
        .use_llvm = true,
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
    installLibrary(b, lib, linkage, os_tag, target.query.isNative(), "libjitterentropy.a");

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
        const rec_core_mod = createCModule(b, target, .Debug, opts, if (os_tag == .windows) null else true);
        rec_core_mod.root_source_file = b.path("src/root.zig");
        rec_core_mod.addOptions("build_options", record_build_options);
        configureIncludePaths(b, rec_core_mod);
        configureCommonDefines(b, rec_core_mod, target, opts, linkage, false);
        configureSystemLibraries(rec_core_mod, target, opts);

        const rec_mod = createCModule(b, target, .Debug, opts, if (os_tag == .windows) null else true);
        rec_mod.root_source_file = b.path("tests/raw-entropy/recording_library/record_lib.zig");
        rec_mod.addImport("jent", rec_core_mod);
        rec_mod.addOptions("record_options", record_options);
        configureIncludePaths(b, rec_mod);
        rec_mod.addIncludePath(b.path("tests/raw-entropy/recording_library"));
        configureCommonDefines(b, rec_mod, target, opts, linkage, false);
        if (os_tag == .windows) {
            if (linkage == .dynamic) {
                rec_mod.addCMacro("JENT_RECORD_BUILDING_DLL", "1");
            } else {
                rec_mod.addCMacro("JENT_RECORD_STATIC_LIB", "1");
            }
        }
        configureSystemLibraries(rec_mod, target, opts);

        const rec_lib = b.addLibrary(.{
            .name = "jitterentropy-record",
            .linkage = linkage,
            .version = jitterentropy_version,
            .root_module = rec_mod,
            .use_llvm = true,
        });
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
        installLibrary(
            b,
            rec_lib,
            linkage,
            os_tag,
            target.query.isNative(),
            "libjitterentropy-record.a",
        );
        b.installFile(
            "doc/jitterentropy-record.3",
            "share/man/man3/jitterentropy-record.3",
        );

        if (linkage == .dynamic and (os_tag == .linux or os_tag.isDarwin())) {
            addCheckExportsTest(b, test_step, rec_lib, "tests/raw-entropy/recording_library/record.lds");
        }

        const colink_mod = createCModule(b, target, optimize, opts, null);
        colink_mod.root_source_file = b.path("tests/raw-entropy/recording_library/record_colink.zig");
        configureIncludePaths(b, colink_mod);
        colink_mod.addIncludePath(b.path("tests/raw-entropy/recording_library"));
        configureCommonDefines(b, colink_mod, target, opts, linkage, false);
        if (os_tag == .windows and linkage == .static) {
            colink_mod.addCMacro("JENT_RECORD_STATIC_LIB", "1");
        }
        colink_mod.linkLibrary(lib);
        colink_mod.linkLibrary(rec_lib);
        const colink_exe = b.addExecutable(.{
            .name = "record-colink",
            .root_module = colink_mod,
        });
        const run_colink = addSkipAwareTestRun(b, test_runner_exe, colink_exe, tsan_options);
        test_step.dependOn(&run_colink.step);
    }

    if (enable_kernel_lib) {
        if (os_tag != .linux) {
            std.debug.panic("-Dkernel-lib=true requires a Linux target", .{});
        }
        const kern_mod = b.createModule(.{
            .root_source_file = b.path("linux_kernel/userspace/jitterentropy-kernel.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .pic = true,
        });

        const kern_lib = b.addLibrary(.{
            .name = "jitterentropy-kernel",
            .linkage = linkage,
            .version = jitterentropy_version,
            .root_module = kern_mod,
            .use_llvm = true,
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

        const jitter_rng_mod = b.createModule(.{
            .root_source_file = b.path("linux_kernel/userspace/jitter_rng.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
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
        const rngd_mod = b.createModule(.{
            .root_source_file = b.path("rngd/jitterentropy-rngd.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .sanitize_c = if (opts.sanitizers) .full else .off,
            .sanitize_thread = if (opts.tsan) true else null,
            .omit_frame_pointer = if (opts.sanitizers or opts.tsan or opts.coverage) false else null,
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

    const internal_api_mod = b.createModule(.{
        .root_source_file = b.path("src/internal.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    internal_api_mod.addOptions("build_options", internal_build_options);

    const gcd_mod = createCModule(b, target, optimize, opts, null);
    gcd_mod.root_source_file = b.path("tests/gcd/gcd.zig");
    gcd_mod.addImport("jent", internal_api_mod);
    gcd_mod.linkLibrary(zig_core_lib);
    configureSystemLibraries(gcd_mod, target, opts);
    const gcd_exe = b.addExecutable(.{
        .name = "gcd",
        .root_module = gcd_mod,
    });

    const health_mod = createCModule(b, target, optimize, opts, null);
    health_mod.root_source_file = b.path("tests/health/health.zig");
    health_mod.addImport("jent", override_core_mod);
    configureSystemLibraries(health_mod, target, opts);
    const health_exe = b.addExecutable(.{
        .name = "jitterentropy-health",
        .root_module = health_mod,
    });

    const flags_exe = addZigToolExecutable(
        b,
        "jitterentropy-flags",
        "tests/raw-entropy/recording_userspace/jitterentropy_flags.zig",
        target,
        optimize,
        opts,
        linkage,
        recording_tool_options,
        null,
    );

    if (enable_tools) {
        b.installArtifact(gcd_exe);
        b.installArtifact(health_exe);
        b.installArtifact(flags_exe);

        const rng_exe = addZigToolExecutable(
            b,
            "jitterentropy-rng",
            "tests/raw-entropy/recording_userspace/jitterentropy_rng.zig",
            target,
            optimize,
            opts,
            linkage,
            recording_tool_options,
            lib,
        );
        configureInstallRPath(rng_exe.root_module, os_tag, linkage);
        b.installArtifact(rng_exe);

        const osr_exe = addZigToolExecutable(
            b,
            "jitterentropy-osr",
            "tests/raw-entropy/recording_userspace/jitterentropy_osr.zig",
            target,
            optimize,
            opts,
            linkage,
            recording_tool_options,
            lib,
        );
        configureInstallRPath(osr_exe.root_module, os_tag, linkage);
        b.installArtifact(osr_exe);

        if (recording_lib) |rec_lib| {
            const hashtime_mod = createCModule(b, target, optimize, opts, null);
            hashtime_mod.root_source_file =
                b.path("tests/raw-entropy/recording_userspace/jitterentropy_hashtime.zig");
            hashtime_mod.addOptions("tool_options", recording_tool_options);
            hashtime_mod.linkLibrary(rec_lib);
            configureCryptoLibraries(hashtime_mod, opts);
            const hashtime_exe = b.addExecutable(.{
                .name = "jitterentropy-hashtime",
                .root_module = hashtime_mod,
            });
            configureInstallRPath(hashtime_exe.root_module, os_tag, linkage);
            b.installArtifact(hashtime_exe);
        }

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

        const cpuinfo_mod = createCModule(b, target, optimize, opts, null);
        cpuinfo_mod.root_source_file =
            b.path("tests/raw-entropy/recording_userspace/jitterentropy-cpuinfo.zig");
        const cpuinfo_exe = b.addExecutable(.{
            .name = "jitterentropy-cpuinfo",
            .root_module = cpuinfo_mod,
        });
        if (os_tag == .windows) {
            cpuinfo_exe.root_module.linkSystemLibrary("advapi32", .{ .use_pkg_config = .no });
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
            const getraw_mod = b.createModule(.{
                .root_source_file = b.path("tests/raw-entropy/recording_runtime_kernelspace/getrawentropy.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            });
            const getraw_exe = b.addExecutable(.{
                .name = "getrawentropy",
                .root_module = getraw_mod,
            });
            b.installArtifact(getraw_exe);

            const status_mod = b.createModule(.{
                .root_source_file = b.path("tests/chardev/jitterentropy-chardev-status.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
            });
            const status_exe = b.addExecutable(.{
                .name = "jitterentropy-chardev-status",
                .root_module = status_mod,
            });
            b.installArtifact(status_exe);

            const fields_mod = b.createModule(.{
                .root_source_file = b.path("tests/chardev/jitterentropy-chardev-fields.zig"),
                .target = target,
                .optimize = optimize,
                .link_libc = true,
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
    run_flags_encode.expectStdOutEqual(if (os_tag == .windows) "1518338112\r\n" else "1518338112\n");
    test_step.dependOn(&run_flags_encode.step);

    const run_flags_mixed = b.addRunArtifact(flags_exe);
    applyTestEnv(run_flags_mixed, tsan_options);
    run_flags_mixed.addArg("JeNt_NtG1");
    run_flags_mixed.expectStdOutEqual(if (os_tag == .windows) "64\r\n" else "64\n");
    test_step.dependOn(&run_flags_mixed.step);

    const FlagsFailCase = struct {
        args: []const []const u8,
        stderr: []const u8,
    };
    const flags_fail_cases: []const FlagsFailCase = &.{
        .{
            .args = &.{ "--decode", "0x200" },
            .stderr = if (os_tag == .windows) "refused: reserved bits 0x00000200 set\r\n" else "refused: reserved bits 0x00000200 set\n",
        },
        .{
            .args = &.{ "--ntg1", "--force-internal-timer" },
            .stderr = if (os_tag == .windows) "refused: JENT_FORCE_INTERNAL_TIMER with JENT_NTG1\r\n" else "refused: JENT_FORCE_INTERNAL_TIMER with JENT_NTG1\n",
        },
        .{
            .args = &.{ "JENT_HASHLOOP_1", "JENT_HASHLOOP_2" },
            .stderr = if (os_tag == .windows) "JENT_HASHLOOP_2: field already set\r\n" else "JENT_HASHLOOP_2: field already set\n",
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
        \\#include "jitterentropy.h"
        \\#ifndef JENT_INT_MEASURE_CLOCK
        \\#define JENT_INT_MEASURE_CLOCK (1 << 22)
        \\#endif
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
    );

    const zig_test_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .sanitize_c = if (opts.sanitizers) .full else .off,
        .sanitize_thread = opts.tsan,
    });
    zig_test_mod.addOptions("build_options", internal_build_options);
    configureIncludePaths(b, zig_test_mod);
    configureCommonDefines(b, zig_test_mod, target, opts, .static, false);
    configureSystemLibraries(zig_test_mod, target, opts);
    zig_test_mod.addCSourceFile(.{
        .file = abi_test_helper_c,
        .flags = c_flags,
    });
    if (opts.coverage_rt_file) |cov_rt| {
        zig_test_mod.addCSourceFile(.{
            .file = cov_rt,
            .flags = &.{ "-std=gnu11", "-O2", "-fvisibility=hidden" },
        });
    }

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

    const cache_api_mod = b.createModule(.{
        .root_source_file = b.path("src/arch/cache.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    for (unit_test_names) |ut_name| {
        const ut_exe = addUnitTestExecutable(
            b,
            ut_name,
            target,
            optimize,
            opts,
            zig_core_lib,
            false,
            zig_harness_mod,
            internal_api_mod,
            cache_api_mod,
        );
        if (install_tests or (opts.tsan and std.mem.eql(u8, ut_name, "unit-concurrency"))) {
            b.installArtifact(ut_exe);
        }
        const run_ut = addSkipAwareTestRun(b, test_runner_exe, ut_exe, tsan_options);
        test_step.dependOn(&run_ut.step);
    }

    if (os_tag == .linux) {
        const ut_kern_lib_mod = b.createModule(.{
            .root_source_file = b.path("linux_kernel/userspace/jitterentropy-kernel.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        const ut_kern_mod = b.createModule(.{
            .root_source_file = b.path("tests/unit/unit-kernel-lib.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        ut_kern_mod.addImport("jitterentropy_kernel", ut_kern_lib_mod);
        const ut_kern = b.addExecutable(.{
            .name = "unit-kernel-lib",
            .root_module = ut_kern_mod,
        });
        if (install_tests) {
            b.installArtifact(ut_kern);
        }
        const run_ut_kern = addSkipAwareTestRun(b, test_runner_exe, ut_kern, tsan_options);
        test_step.dependOn(&run_ut_kern.step);
    }

    for (mock_unit_test_names) |ut_name| {
        const ut_exe = addUnitTestExecutable(
            b,
            ut_name,
            target,
            optimize,
            opts,
            zig_core_mock_lib,
            true,
            zig_harness_mod,
            internal_api_mod,
            cache_api_mod,
        );
        if (install_tests) {
            b.installArtifact(ut_exe);
        }
        const run_ut = addSkipAwareTestRun(b, test_runner_exe, ut_exe, tsan_options);
        test_step.dependOn(&run_ut.step);
    }

    const fuzz_api_impl_mod = b.createModule(.{
        .root_source_file = b.path("tests/fuzz/fuzz_api.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    const fuzz_api_mod = createCModule(b, target, optimize, opts, null);
    fuzz_api_mod.root_source_file = b.path("tests/fuzz/fuzz_api_standalone.zig");
    fuzz_api_mod.addImport("fuzz_api", fuzz_api_impl_mod);
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

    const fuzz_health_impl_mod = b.createModule(.{
        .root_source_file = b.path("tests/fuzz/fuzz_health.zig"),
        .target = target,
        .optimize = .Debug,
    });
    fuzz_health_impl_mod.addImport("jent", override_core_mod);
    const fuzz_health_mod = createCModule(b, target, .Debug, opts, null);
    fuzz_health_mod.root_source_file = b.path("tests/fuzz/fuzz_health_standalone.zig");
    fuzz_health_mod.addImport("fuzz_health", fuzz_health_impl_mod);
    configureSystemLibraries(fuzz_health_mod, target, opts);
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

        const fuzz_api_lib_mod = b.createModule(.{
            .root_source_file = b.path("tests/fuzz/fuzz_api.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        });
        const fuzz_api_lib = b.addLibrary(.{
            .name = "fuzz-api-harness",
            .linkage = .static,
            .root_module = fuzz_api_lib_mod,
        });
        const fuzz_api_fuzzer_mod = createCModule(b, target, optimize, opts, null);
        fuzz_api_fuzzer_mod.linkLibrary(fuzz_api_lib);
        fuzz_api_fuzzer_mod.linkLibrary(lib);
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

        const fuzz_health_lib_mod = createCModule(b, target, .Debug, opts, null);
        fuzz_health_lib_mod.root_source_file = b.path("tests/fuzz/fuzz_health.zig");
        fuzz_health_lib_mod.addImport("jent", override_core_mod);
        const fuzz_health_lib = b.addLibrary(.{
            .name = "fuzz-health-harness",
            .linkage = .static,
            .root_module = fuzz_health_lib_mod,
        });
        const fuzz_health_fuzzer_mod = createCModule(b, target, optimize, opts, null);
        fuzz_health_fuzzer_mod.linkLibrary(fuzz_health_lib);
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
    configureIncludePaths(b, linktest_mod);
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
    if (install_tests) {
        b.installArtifact(linktest_exe);
    }
    const run_linktest = b.addRunArtifact(linktest_exe);
    applyTestEnv(run_linktest, tsan_options);
    run_linktest.expectExitCode(0);
    test_step.dependOn(&run_linktest.step);

    if (opts.coverage) {
        const cov_step = b.step("coverage", "Run tests and generate HTML coverage report in zig-out/coverage");
        const cov_cmd = b.addSystemCommand(&.{ "bash", "-c" });
        cov_cmd.addArg(
            \\set -e
            \\for opt in "" "--all-caches" "--force-internal-timer" "--force-fips" "--ntg1"; do
            \\  ./zig-out/bin/jitterentropy-rng 256 $opt > /dev/null 2>&1 || true
            \\done
            \\mkdir -p zig-out/coverage
            \\gcov_tool=""
            \\if command -v llvm-cov >/dev/null 2>&1; then
            \\  gcov_tool="--gcov-executable 'llvm-cov gcov'"
            \\elif command -v xcrun >/dev/null 2>&1 && xcrun --find llvm-cov >/dev/null 2>&1; then
            \\  gcov_tool="--gcov-executable '$(xcrun --find llvm-cov) gcov'"
            \\fi
            \\if gcovr --gcov-ignore-parse-errors suspicious_hits.warn --version >/dev/null 2>&1; then
            \\  parse_errors=suspicious_hits.warn
            \\else
            \\  parse_errors=all
            \\fi
            \\ignore_errors=""
            \\if gcovr --gcov-ignore-errors=no_working_dir_found --version >/dev/null 2>&1; then
            \\  ignore_errors="--gcov-ignore-errors=no_working_dir_found"
            \\fi
            \\exclude_tests=""
            \\if compgen -G "src/*.c" >/dev/null; then
            \\  exclude_tests='--exclude "tests/"'
            \\fi
            \\eval gcovr \
            \\  --root . \
            \\  .zig-cache \
            \\  $gcov_tool \
            \\  $ignore_errors \
            \\  --gcov-ignore-parse-errors "$parse_errors" \
            \\  --merge-mode-functions merge-use-line-min \
            \\  $exclude_tests \
            \\  --exclude "linux_kernel/" \
            \\  --html-details zig-out/coverage/index.html \
            \\  --print-summary
        );
        cov_cmd.step.dependOn(b.getInstallStep());
        cov_cmd.step.dependOn(test_step);
        cov_step.dependOn(&cov_cmd.step);
    }
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
        .sanitize_c = if (opts.sanitizers) .full else .off,
        .sanitize_thread = if (opts.tsan) true else null,
        .omit_frame_pointer = if (opts.sanitizers or opts.tsan or opts.coverage) false else null,
    });
    if (opts.extra_include_dirs) |inc_dirs| {
        var it = std.mem.splitScalar(u8, inc_dirs, ':');
        while (it.next()) |dir| {
            if (dir.len > 0) {
                mod.addSystemIncludePath(.{ .cwd_relative = dir });
            }
        }
    }
    if (opts.extra_lib_dirs) |lib_dirs| {
        var it = std.mem.splitScalar(u8, lib_dirs, ':');
        while (it.next()) |dir| {
            if (dir.len > 0) {
                mod.addLibraryPath(.{ .cwd_relative = dir });
                mod.addRPath(.{ .cwd_relative = dir });
            }
        }
    }
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

fn detectHostGnuLibCVersion(b: *std.Build, host: std.Target) std.SemanticVersion {
    if (std.process.run(b.allocator, b.graph.io, .{
        .argv = &.{ "getconf", "GNU_LIBC_VERSION" },
    })) |res| {
        if (res.term == .exited and res.term.exited == 0) {
            const out = std.mem.trim(u8, res.stdout, " \t\r\n");
            if (std.mem.startsWith(u8, out, "glibc ")) {
                if (std.Target.Query.parseVersion(out["glibc ".len..])) |ver| {
                    return ver;
                } else |_| {}
            }
        }
    } else |_| {}

    if (host.dynamic_linker.get()) |dl_path| {
        var link_buf: [std.fs.max_path_bytes]u8 = undefined;
        if (std.Io.Dir.readLinkAbsolute(b.graph.io, dl_path, &link_buf)) |n| {
            const base = std.fs.path.basename(link_buf[0..n]);
            if (std.mem.startsWith(u8, base, "ld-") and std.mem.endsWith(u8, base, ".so")) {
                if (std.Target.Query.parseVersion(base["ld-".len .. base.len - ".so".len])) |ver| {
                    return ver;
                } else |_| {}
            }
        } else |_| {}
    }

    return host.os.version_range.linux.glibc;
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
        .sanitize_c = .off,
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
        mod.linkSystemLibrary("bcrypt", .{ .use_pkg_config = .no });
    } else if (opts.internal_timer and !target.result.abi.isAndroid() and os_tag != .freebsd) {
        mod.linkSystemLibrary("pthread", .{ .use_pkg_config = .no });
    }
    configureCryptoLibraries(mod, opts);
}

fn addZigToolExecutable(
    b: *std.Build,
    name: []const u8,
    src_path: []const u8,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    opts: BuildOptions,
    linkage: std.builtin.LinkMode,
    tool_options: *std.Build.Step.Options,
    lib: ?*std.Build.Step.Compile,
) *std.Build.Step.Compile {
    const mod = createCModule(b, target, optimize, opts, null);
    mod.root_source_file = b.path(src_path);
    mod.addOptions("tool_options", tool_options);
    configureCommonDefines(b, mod, target, opts, linkage, false);
    if (lib) |library| {
        mod.linkLibrary(library);
        configureCryptoLibraries(mod, opts);
    }
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
    zig_core_lib: *std.Build.Step.Compile,
    enable_mock_timer: bool,
    harness_mod: *std.Build.Module,
    internal_mod: *std.Build.Module,
    cache_mod: *std.Build.Module,
) *std.Build.Step.Compile {
    const mod = createCModule(b, target, optimize, opts, null);
    mod.linkLibrary(zig_core_lib);
    mod.addImport("test_harness", harness_mod);
    mod.addImport("jent_internal", internal_mod);
    mod.addImport("internal", internal_mod);
    mod.addImport("jent", internal_mod);
    mod.addImport("cache", cache_mod);
    configureSystemLibraries(mod, target, opts);
    _ = enable_mock_timer;
    const zig_name = std.mem.replaceOwned(u8, b.allocator, name, "-", "_") catch @panic("OOM");
    const src_rel = std.fmt.allocPrint(
        b.allocator,
        "tests/unit/{s}.zig",
        .{zig_name},
    ) catch @panic("OOM");
    mod.root_source_file = b.path(src_rel);
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
    const EfiTargetSpec = struct {
        arch: std.Target.Cpu.Arch,
        boot_name: []const u8,
    };
    const specs: []const EfiTargetSpec = &.{
        .{
            .arch = .x86_64,
            .boot_name = "BOOTX64.EFI",
        },
        .{
            .arch = .aarch64,
            .boot_name = "BOOTAA64.EFI",
        },
    };

    for (specs) |spec| {
        const uefi_target = b.resolveTargetQuery(.{
            .cpu_arch = spec.arch,
            .os_tag = .uefi,
            .abi = .msvc,
        });

        const efi_mod = b.createModule(.{
            .root_source_file = b.path("tests/efi/jitterentropy-efi.zig"),
            .target = uefi_target,
            .optimize = .Debug,
            .link_libc = false,
            .pic = true,
            .red_zone = if (spec.arch == .x86_64) false else null,
            .stack_check = false,
            .stack_protector = false,
        });

        const efi_build_options = b.addOptions();
        efi_build_options.addOption(bool, "internal_timer", true);
        efi_build_options.addOption(bool, "mock_timer", false);
        efi_build_options.addOption(bool, "raw_memory_access", false);
        efi_build_options.addOption(bool, "stack_protector", false);
        efi_build_options.addOption(std.builtin.LinkMode, "linkage", .static);
        efi_build_options.addOption(ExternalCrypto, "external_crypto", .none);
        efi_build_options.addOption(?[]const u8, "aarch64_nstime_register", null);
        efi_build_options.addOption(bool, "export_public_api", true);
        efi_build_options.addOption(bool, "export_internals", false);
        efi_build_options.addOption(bool, "weak_internals", false);
        efi_build_options.addOption(bool, "export_random_data", true);

        const efi_core_mod = b.createModule(.{
            .root_source_file = b.path("src/root.zig"),
            .target = uefi_target,
            .optimize = .Debug,
            .link_libc = false,
            .pic = true,
            .red_zone = if (spec.arch == .x86_64) false else null,
            .stack_check = false,
            .stack_protector = false,
        });
        efi_core_mod.addOptions("build_options", efi_build_options);
        const efi_core = b.addLibrary(.{
            .name = b.fmt("jitterentropy-efi-core-{s}", .{@tagName(spec.arch)}),
            .linkage = .static,
            .root_module = efi_core_mod,
            .use_llvm = true,
        });
        efi_mod.linkLibrary(efi_core);

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

