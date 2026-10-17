# Android example app

A small app that builds the Jitter RNG into an Android app the way an app
would embed it: `app/build.gradle.kts` invokes `zig build` to cross-compile
`libjitterentropy.a` and `libjitterentropy-record.a` for `aarch64-linux-android`
and `x86_64-linux-android` and links them into a JNI library,
`libjitterentropy-jni.so`.
The app allocates one collector at start-up. On the *Output* tab one button
shows its `jent_status()` document, the other 32 bytes of its output in hex.
Both are also written to logcat under the tag `JitterEntropyExample`. On the
*Collector* tab three buttons replace the collector with a new one - without flags, in FIPS
(`JENT_FORCE_FIPS`) or in NTG.1 (`JENT_NTG1`) mode - after running the
power-on tests with the same flags. Both modes require the collector's state to
be locked and fail with EMEM where it cannot be. That is one page per collector,
a second with the timer thread and two more while the power-on tests run - 16 KiB
at most, which any `RLIMIT_MEMLOCK` an Android app gets holds: 64 KiB, which
`init.rc` sets since Android 14, and before that the kernel's default - 64 KiB
on mainline kernels before 5.16, 8 MiB since, or whatever the vendor kernel
chose (64 MiB on a Nexus 5X). The memory access region is never locked.

The *Timer thread* switch above those buttons allocates the next collector with
`JENT_FORCE_INTERNAL_TIMER`: its time stamps then come from the library's timer
thread, a thread counting in a loop, rather than from the platform clock. The
status document says which one a collector uses (`internalTimer`). The choice
is per collector: one allocated with the switch off uses the platform clock
again. NTG.1 forbids the timer thread and is unavailable while the switch is on.

The sliders below the switch set the next collector's initial oversampling
rate (3 to 20), memory size (automatic, or `JENT_MAX_MEMSIZE_1kB` to
`JENT_MAX_MEMSIZE_512MB`) and hash loop count (default, or `JENT_HASHLOOP_1`
to `JENT_HASHLOOP_128`). A health test failure raises the oversampling rate and
the hash loop count of the replacement collector, but not the memory size: the
increment in `jent_update_memsize()` applies only to a size the library derived
itself, so a memory size chosen here is the one the instance keeps. Leave it on
automatic to let the recovery grow it. The status document reports what a
collector runs with.

The *Record* tab records the raw noise data of the SP800-90B and NTG.1
entropy assessment in the app, in the default, FIPS or NTG.1 mode and with the
settings of the *Collector* tab, as the recording scripts of
`tests/raw-entropy/recording_userspace` do on a host, into the app's
`files/results-measurements`.
`tests/raw-entropy/recording_library/README.md` describes what it records, how to
copy it off the phone with `adb` and how to analyze it.

- `app/src/main/cpp/jitterentropy-jni.c` - the JNI binding
- `app/src/main/java/.../JitterEntropy.kt` - the Kotlin side of it, one
  collector per instance and the flags it is allocated with
- `app/src/main/java/.../CollectorViewModel.kt` - owns the collector across
  activity recreation; every call into the library runs on one background
  thread
- `app/src/main/java/.../Recorder.kt` - the recording of the *Record* tab,
  through `jent_record_raw()` of `libjitterentropy-record`, which
  `app/build.gradle.kts` builds with `-Drecording=true` and links
  beside `libjitterentropy`
- `app/src/main/java/.../MainActivity.kt` - the UI, in Jetpack Compose with
  Material 3

## Cross-compiling with `zig build`

To cross-compile `libjitterentropy.a` and `libjitterentropy-record.a` directly
with `zig build` against an Android NDK sysroot:

```sh
SYSROOT="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr"

for target in aarch64-linux-android x86_64-linux-android; do
  zig build \
    -Dtarget="$target" \
    -Dlinkage=static \
    -Drecording=true \
    -Dtools=false \
    -Dinclude-dirs="$SYSROOT/include:$SYSROOT/include/$target" \
    -Dlib-dirs="$SYSROOT/lib/$target/23:$SYSROOT/lib/$target" \
    --prefix "zig-out-$target"
done
```

## Building the app

Open this directory in Android Studio, or run `gradle assembleDebug` with a
Gradle the Android Gradle plugin in `build.gradle.kts` supports, `zig` in
`PATH`, and `ANDROID_HOME` pointing at an SDK. No Gradle wrapper is checked in.

## ndk-build

`Android.mk` builds the library alone, as `libjitterentropy.so`, for projects
built with ndk-build:

```
ndk-build NDK_PROJECT_PATH=null APP_BUILD_SCRIPT=$PWD/tests/android/Android.mk \
          APP_PLATFORM=android-21
```
