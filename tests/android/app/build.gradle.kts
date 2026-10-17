plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.plugin.compose")
}

android {
    namespace = "de.chronox.jitterentropy.example"
    compileSdk = 37
    // Pinned rather than left to AGP's default so that the SDK flake.nix
    // composes is the one the build finds; neither may download anything.
    buildToolsVersion = "37.0.0"
    ndkVersion = "29.0.14206865"

    defaultConfig {
        applicationId = "de.chronox.jitterentropy.example"
        // What Compose requires. The library itself goes lower: the
        // ndk-build target in flake.nix builds it at API 21.
        minSdk = 23
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"

        ndk {
            abiFilters += listOf("arm64-v8a", "x86_64")
        }
    }

    sourceSets {
        getByName("main") {
            jniLibs.srcDirs(layout.buildDirectory.dir("zigJniLibs"))
        }
    }

    buildFeatures {
        compose = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

val buildNativeWithZig by tasks.registering {
    val outDir = layout.buildDirectory.dir("zigJniLibs")
    outputs.dir(outDir)
    doLast {
        val jentRoot = rootDir.parentFile
        val ndkDir = android.ndkDirectory
        val hostTag = if (System.getProperty("os.name").lowercase().contains("mac")) "darwin-x86_64" else "linux-x86_64"
        val sysroot = ndkDir.resolve("toolchains/llvm/prebuilt/$hostTag/sysroot/usr")
        val targets = mapOf(
            "arm64-v8a" to "aarch64-linux-android",
            "x86_64" to "x86_64-linux-android",
        )
        for ((abi, zigTarget) in targets) {
            val prefixDir = layout.buildDirectory.dir("zigPrefix/$abi").get().asFile
            val abiLibDir = outDir.get().asFile.resolve(abi)
            abiLibDir.mkdirs()
            val archTriple = if (abi == "arm64-v8a") "aarch64-linux-android" else "x86_64-linux-android"
            val incDirs = "${sysroot.resolve("include")}:${sysroot.resolve("include/$archTriple")}"
            val libDirs = "${sysroot.resolve("lib/$archTriple/23")}:${sysroot.resolve("lib/$archTriple")}"
            project.exec {
                workingDir = jentRoot
                commandLine(
                    "zig", "build",
                    "-Dtarget=$zigTarget",
                    "-Dlinkage=static",
                    "-Drecording=true",
                    "-Dtools=false",
                    "-Dinclude-dirs=$incDirs",
                    "-Dlib-dirs=$libDirs",
                    "--prefix", prefixDir.absolutePath,
                )
            }
            project.exec {
                workingDir = projectDir
                commandLine(
                    "zig", "cc",
                    "-target", zigTarget,
                    "-shared", "-fPIC", "-O2",
                    "-I${prefixDir.resolve("include")}",
                    "-I${sysroot.resolve("include")}",
                    "-I${sysroot.resolve("include/$archTriple")}",
                    "-L${libDirs.replace(":", " -L")}",
                    "src/main/cpp/jitterentropy-jni.c",
                    prefixDir.resolve("lib/libjitterentropy.a").absolutePath,
                    prefixDir.resolve("lib/libjitterentropy-record.a").absolutePath,
                    "-o", abiLibDir.resolve("libjitterentropy-jni.so").absolutePath,
                )
            }
        }
    }
}

tasks.named("preBuild") {
    dependsOn(buildNativeWithZig)
}

dependencies {
    implementation(platform("androidx.compose:compose-bom:2026.09.00"))
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.13.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.11.0")
}
