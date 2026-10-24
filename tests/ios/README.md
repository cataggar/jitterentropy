# iOS example app

A small SwiftUI app that builds the Jitter RNG into an iOS app the way an app
would embed it: `zig build` cross-compiles `libjitterentropy.a` and
`libjitterentropy-record.a` for iOS (`aarch64-ios`, `aarch64-ios-simulator`,
`x86_64-ios-simulator`), and `jitterentropy-bridging.h`
makes its C API visible to Swift. The app allocates one collector at start-up.
On the *Output* tab one button shows its `jent_status()` document, the other 32
bytes of its output in hex. Both are also written to the system log. On the
*Collector* tab three buttons replace the collector with a new one - without flags, in FIPS (`JENT_FORCE_FIPS`) or in
NTG.1 (`JENT_NTG1`) mode - after running the power-on tests with the same
flags. Both modes require the collector's state to be locked and fail with
EMEM where it cannot be; the memory access region is never locked.

The *Timer thread* toggle above those buttons allocates the next collector with
`JENT_FORCE_INTERNAL_TIMER`: its time stamps then come from the library's timer
thread, a thread counting in a loop, rather than from the platform clock. The
status document says which one a collector uses (`internalTimer`). The choice
is per collector: one allocated with the toggle off uses the platform clock
again. NTG.1 forbids the timer thread and is unavailable while the toggle is on.

The steppers below the toggle set the next collector's initial oversampling
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
`tests/raw-entropy/recording_userspace` do on a host, into
`Documents/results-measurements`, which the Files app and the Finder show.
`tests/raw-entropy/recording_library/README.md` describes what it records, how to
copy it off the phone and how to analyze it.

- `Collector.swift` - one collector and the flags it is allocated with; every
  call into the library runs on its serial queue
- `Recorder.swift` - the recording of the *Record* tab, through
  `jent_record_raw()` of `libjitterentropy-record`, built with
  `zig build -Drecording=true` and linked beside `libjitterentropy`
- `JitterEntropyExampleApp.swift` - the UI

## Cross-compiling with `zig build`

Use `zig build` on macOS with the Xcode iOS / iOS Simulator SDK paths to build
`libjitterentropy.a` and `libjitterentropy-record.a` for device (`aarch64-ios`)
and simulator (`aarch64-ios-simulator`, `x86_64-ios-simulator`):

```sh
IOS_SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
SIM_SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"

zig build \
  -Dtarget=aarch64-ios \
  -Dlinkage=static \
  -Drecording=true \
  -Dtools=false \
  -Dinclude-dirs="$IOS_SDK/usr/include" \
  -Dlib-dirs="$IOS_SDK/usr/lib" \
  --prefix zig-out-aarch64-ios

for target in aarch64-ios-simulator x86_64-ios-simulator; do
  zig build \
    -Dtarget="$target" \
    -Dlinkage=static \
    -Drecording=true \
    -Dtools=false \
    -Dinclude-dirs="$SIM_SDK/usr/include" \
    -Dlib-dirs="$SIM_SDK/usr/lib" \
    --prefix "zig-out-$target"
done
```

## Building the app bundle

Compile the Swift sources against `jitterentropy-bridging.h` and the
`zig build` static libraries using `xcrun --sdk iphonesimulator swiftc` (or
`iphoneos` for device builds):

```sh
APP_DIR="build-ios/JitterEntropyExample.app"
mkdir -p "$APP_DIR"

xcrun --sdk iphonesimulator swiftc \
  -target arm64-apple-ios16.0-simulator \
  -import-objc-header tests/ios/jitterentropy-bridging.h \
  -I zig-out-aarch64-ios-simulator/include \
  tests/ios/Collector.swift \
  tests/ios/Recorder.swift \
  tests/ios/JitterEntropyExampleApp.swift \
  zig-out-aarch64-ios-simulator/lib/libjitterentropy.a \
  zig-out-aarch64-ios-simulator/lib/libjitterentropy-record.a \
  -o "$APP_DIR/JitterEntropyExample"

sed 's/@MACOSX_BUNDLE_GUI_IDENTIFIER@/de.chronox.jitterentropy.example/g; s/@MACOSX_BUNDLE_EXECUTABLE_NAME@/JitterEntropyExample/g; s/@MACOSX_BUNDLE_BUNDLE_NAME@/JitterEntropyExample/g; s/@MACOSX_BUNDLE_SHORT_VERSION_STRING@/1.0/g; s/@MACOSX_BUNDLE_BUNDLE_VERSION@/1/g' \
  tests/ios/Info.plist.in > "$APP_DIR/Info.plist"
```

To run it in a booted simulator:

```sh
xcrun simctl install booted "$APP_DIR"
xcrun simctl launch --console booted de.chronox.jitterentropy.example
```
