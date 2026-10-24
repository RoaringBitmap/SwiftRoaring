# Fuzzing

libFuzzer + AddressSanitizer target.

**Scope: only APIs documented as safe on untrusted bytes.** APIs documented to trust their input are not fuzzed: bad bytes may crash them by design.

## Run

```sh
cd Fuzz
swift build -c release --sanitize=fuzzer --sanitize=address
mkdir -p corpus
.build/release/SwiftRoaringFuzz -max_total_time=120 corpus
```

Linux images from swift.org work as is. On macOS, Xcode's toolchain lacks libFuzzer: use the `swift` from a swift.org toolchain, e.g. `~/Library/Developer/Toolchains/swift-6.4.1-RELEASE.xctoolchain/usr/bin/swift`.
