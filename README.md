# verify-16k-page-align

[![npm version](https://img.shields.io/npm/v/verify-16k-page-align.svg)](https://www.npmjs.com/package/verify-16k-page-align)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
[![Linux Only](https://img.shields.io/badge/platform-linux-lightgrey)](#platform-support)

A shell script and npm package to verify if your Android APK/AAB native libraries are aligned to 16KB (0x4000) memory pages. This is required for compatibility with Android 15+ devices and Google Play submissions after **November 1, 2025** ([see official docs](https://developer.android.com/guide/practices/page-sizes?hl=pt-br)).

---

## Features

- Checks all native `.so` libraries in APK/AAB for 16KB page alignment
- Works with both APK and AAB files
- Uses `readelf` or `llvm-readelf` (auto-detects)
- Fast, zero dependencies (besides unzip/readelf)
- CLI and npm global install
- Clear pass/fail output for CI/CD

---

## Why 16KB Page Alignment?

Starting with Android 15, many devices will use 16KB memory pages for improved performance and reliability. All apps targeting Android 15+ and distributed via Google Play **must** ensure their native libraries (`.so` files) are 16KB aligned. See:
- [Android Developers: 16 KB Page Size](https://developer.android.com/guide/practices/page-sizes?hl=pt-br)
- [Google Play Blog: Prepare for 16 KB page size](https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html)
- [Medium: Android 15 Mandatory 16KB Memory Page Size](https://devharshmittal.medium.com/android-15-is-raising-the-bar-mandatory-16kb-memory-page-size-what-developers-need-to-know-4dd81ec58f67)
- [Reddit discussion](https://www.reddit.com/r/brdev/comments/1nl3fx4/android_15_seus_apps_j%C3%A1_est%C3%A3o_prontos_para_16kb/)

**Benefits:**
- Faster app launches (3–30% improvement)
- Lower battery usage
- Reduced memory fragmentation
- Required for Play Store submission (from Nov 2025)

---

## Installation

### Shell script (one-liner)
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/hotbrainstech/verify-16k-page-align/main/src/verify-16k-page-align.sh)"
```

### NPM global install
```sh
sudo npm i -g verify-16k-page-align
```

---

## Usage


### Check an APK or AAB file
By default, only `arm64-v8a` libraries are checked. To also check `x86_64` libraries, add `x86` as a second argument.

```sh
# Default: check arm64-v8a only
verify-16k-page-align <path-to-apk-or-aab>

# Check arm64-v8a and x86_64
verify-16k-page-align <path-to-apk-or-aab> x86
```

Or, if using the raw script:
```sh
# Default: check arm64-v8a only
sh ./src/verify-16k-page-align.sh <path-to-apk-or-aab>

# Check arm64-v8a and x86_64
sh ./src/verify-16k-page-align.sh <path-to-apk-or-aab> x86
```

Or, make the script executable and run directly:
```sh
chmod +x ./src/verify-16k-page-align.sh
# Default: check arm64-v8a only
./src/verify-16k-page-align.sh <path-to-apk-or-aab>
# Check arm64-v8a and x86_64
./src/verify-16k-page-align.sh <path-to-apk-or-aab> x86
```

#### Example output
```
Using readelf: /usr/bin/readelf
Inspecting: app-release.apk
Found 3 native libraries
[OK]   lib/arm64-v8a/libfoo.so aligned to 16KB (no 0x1000 LOAD segments detected).
[FAIL] lib/arm64-v8a/libbar.so has LOAD segment aligned to 0x1000 (4KB).

One or more native libraries are not 16KB aligned.
Ensure AGP >= 8.5.1, NDK r27+, and rebuild any third-party .so with 16KB page alignment.
```

#### CI/CD Example
Add to your pipeline to fail builds if any library is not 16KB aligned.

---

## How It Works

1. Extracts all `.so` files from your APK/AAB
2. Uses `readelf` or `llvm-readelf` to inspect ELF program headers
3. Flags any library with a LOAD segment aligned to 4KB (0x1000)
4. Passes if all LOAD segments are aligned to 16KB (0x4000)

---

## Platform Support

- Linux only (uses bash, unzip, readelf)
- Not supported on Windows or macOS

---

## Requirements

- unzip
- readelf or llvm-readelf (from binutils or Android NDK)

---

## Migration Guide

If your app or any dependency uses native code:
- **Update your build tools:** Use Android Gradle Plugin (AGP) >= 8.5.1 and NDK r27+ (prefer r28+)
- **Recompile all native libraries** with 16KB alignment
- **Remove hardcoded page size assumptions** (replace `4096`/`0x1000`/`PAGE_SIZE` with `sysconf(_SC_PAGESIZE)`)
- **Check all third-party .so files** for compliance
- **Test on Android 15+ emulators or real devices**

See [official migration steps](https://developer.android.com/guide/practices/page-sizes?hl=pt-br#compile-16-kb-alignment) and [Medium migration guide](https://devharshmittal.medium.com/android-15-is-raising-the-bar-mandatory-16kb-memory-page-size-what-developers-need-to-know-4dd81ec58f67).

---

## Troubleshooting

- If you see `[FAIL] ... has LOAD segment aligned to 0x1000 (4KB)`, update and rebuild the affected library.
- For AGP < 8.5.1, use `packagingOptions.jniLibs.useLegacyPackaging true` in `build.gradle` (not recommended).
- For NDK < r27, set linker flags: `-Wl,-z,max-page-size=16384` and `-Wl,-z,common-page-size=16384`.

---

## FAQ

**Q: Does this work for Java/Kotlin-only apps?**
A: No need—Java/Kotlin-only apps do not use native libraries and are already compatible.

**Q: What if my library is not 16KB aligned?**
A: Update your build tools and recompile. Contact third-party vendors for updated .so files.

**Q: Can I use this on macOS or Windows?**
A: No, Linux only. Use a Linux VM or Docker if needed.

**Q: Is this required for Play Store submission?**
A: Yes, for Android 15+ apps after Nov 1, 2025.

---

## 🤝 Contributing

Pull requests and issues are welcome! See [GitHub Issues](https://github.com/hotbrainstech/verify-16k-page-align/issues).

---

## References & Further Reading
- [Android 16KB Page Size Docs](https://developer.android.com/guide/practices/page-sizes?hl=pt-br)
- [Google Play Blog](https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html)
- [Medium: Migration Guide](https://devharshmittal.medium.com/android-15-is-raising-the-bar-mandatory-16kb-memory-page-size-what-developers-need-to-know-4dd81ec58f67)
- [Reddit: brdev discussion](https://www.reddit.com/r/brdev/comments/1nl3fx4/android_15_seus_apps_j%C3%A1_est%C3%A3o_prontos_para_16kb/)

## Show your support

Give a ⭐️ if this project helps you!

Or buy me a coffee 🙌🏾

<a href="https://www.buymeacoffee.com/hebertcisco">
  <img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=hebertcisco&button_colour=FFDD00&font_colour=000000&font_family=Inter&outline_colour=000000&coffee_colour=ffffff" />
</a>

## 📝 License

Copyright © 2025 [@hotbrainstech](https://github.com/hotbrainstech).

This project is [MIT](LICENSE) licensed.
