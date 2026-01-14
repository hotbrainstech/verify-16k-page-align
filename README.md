# verify-16k-page-align

[![npm version](https://img.shields.io/npm/v/verify-16k-page-align.svg)](https://www.npmjs.com/package/verify-16k-page-align)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE.md)
[![Linux/macOS](https://img.shields.io/badge/platform-linux%20%7C%20macOS-lightgrey)](#platform-support)

A shell script and npm package to verify if your Android APK/AAB/APEX native libraries are aligned to 16KB or 64KB memory pages. This is required for compatibility with Android 15+ devices and Google Play submissions after **November 1, 2025** ([see official docs](https://developer.android.com/guide/practices/page-sizes?hl=pt-br)).

---

## Table of Contents

- [Features](#features)
- [Why 16KB Page Alignment?](#why-16kb-page-alignment)
- [Installation](#installation)
- [Usage](#usage)
- [CI/CD Integration](#cicd-integration)
- [How It Works](#how-it-works)
- [Platform Support](#platform-support)
- [Requirements](#requirements)
- [Migration Guide](#migration-guide)
- [Troubleshooting](#troubleshooting)
- [FAQ](#faq)
- [Contributing](#contributing)
- [References](#references-further-reading)
- [Support](#show-your-support)
- [License](#license)

---

## Features

- Checks all native `.so` libraries in **APK**, **AAB**, and **APEX** files for 16KB or 64KB page alignment.
- Supports scanning extracted directories containing native libraries.
- Uses `objdump` to analyze ELF program headers.
- **CI/CD Ready**: Returns exit code `1` on failure, `0` on success.
- Includes APK zip-alignment verification (requires Android build-tools 35.0.0-rc3+).
- Fast, zero dependencies (besides unzip/objdump).
- CLI and npm global install.
- Supports both `arm64-v8a` and `x86_64` architectures.

---

## Why 16KB Page Alignment?

Starting with Android 15, many devices will use 16KB memory pages for improved performance and reliability. All apps targeting Android 15+ and distributed via Google Play **must** ensure their native libraries (`.so` files) are 16KB or 64KB aligned. See:
- [Android Developers: 16 KB Page Size](https://developer.android.com/guide/practices/page-sizes?hl=pt-br)
- [Google Play Blog: Prepare for 16 KB page size](https://android-developers.googleblog.com/2025/05/prepare-play-apps-for-devices-with-16kb-page-size.html)
- [Medium: Android 15 Mandatory 16KB Memory Page Size](https://devharshmittal.medium.com/android-15-is-raising-the-bar-mandatory-16kb-memory-page-size-what-developers-need-to-know-4dd81ec58f67)

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

### Check an APK, AAB, or APEX file
By default, only `arm64-v8a` libraries are checked. To also check `x86_64` libraries, add `x86` as a second argument.

#### Using NPM package
```sh
# Default: check arm64-v8a only
verify-16k-page-align path/to/app.apk
verify-16k-page-align path/to/app.aab

# Check arm64-v8a and x86_64
verify-16k-page-align path/to/app.apk x86
```

#### Using local script
Make sure the script is executable:
```sh
chmod +x ./src/verify-16k-page-align.sh

# Run
./src/verify-16k-page-align.sh path/to/app.apk
```

### Check a directory
You can also run the script against a directory containing extracted native libraries (must follow `lib/arm64-v8a/` structure).

```sh
verify-16k-page-align path/to/extracted/libs
```

### Example Output

```
=== APK zip-alignment ===
lib/arm64-v8a/libfoo.so: 16384 (OK - 16KB aligned)
lib/arm64-v8a/libbar.so: 4096 (BAD - 4KB aligned)
Verification FAILED
=========================

=== ELF alignment ===
lib/arm64-v8a/libfoo.so: ALIGNED (2**14)
lib/arm64-v8a/libbar.so: UNALIGNED (2**12)
Found 1 unaligned libs (only arm64-v8a/x86_64 libs need to be aligned).
=====================
```

---

## CI/CD Integration

This tool is designed for CI/CD pipelines. It returns a non-zero exit code if verification fails.

### GitHub Actions Example

```yaml
name: Verify 16KB Alignment

on: [push, pull_request]

jobs:
  verify-alignment:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      # Install dependencies (objdump is usually present, but just in case)
      - name: Install dependencies
        run: sudo apt-get update && sudo apt-get install -y binutils unzip

      - name: Install verify-16k-page-align
        run: sudo npm i -g verify-16k-page-align

      - name: Verify APK
        run: verify-16k-page-align path/to/your-app-release.apk
```

---

## How It Works

1. **Extraction**:
   - For **APK/AAB**: Unzips `lib/` directory to a temporary location.
   - For **APEX**: Uses `deapexer` to extract contents.
2. **APK Zip Alignment**: If checking an APK and `zipalign` is available (build-tools 35.0.0-rc3+), verifies 16KB zip alignment.
3. **ELF Analysis**: Scans all `.so` files using `objdump` to inspect ELF program headers.
4. **Validation**: Checks if `LOAD` segments are aligned to 16KB (`2**14`) or 64KB (`2**16`).
5. **Result**: 
   - Prints status for each library.
   - Exits with `1` if any unaligned libraries are found.

---

## Platform Support

- **Linux** (Ubuntu, Debian, Fedora, etc.)
- **macOS** (requires GNU binutils)
- **Windows** (Not supported directly; use WSL2)

---

## Requirements

- `unzip` (for extracting APK/AAB contents)
- `objdump` (from binutils, for ELF analysis)
- `zipalign` (Optional: from Android build-tools 35.0.0-rc3+, for zip alignment check)
- `deapexer` (Optional: for APEX file support)

### macOS additional requirement
macOS `objdump` may not support all flags. Install GNU binutils:

```sh
brew install binutils
# Ensure gobjdump is in your PATH or linked as objdump
```

---

## Migration Guide

If your app or any dependency uses native code:
1. **Update your build tools:** Use Android Gradle Plugin (AGP) >= 8.5.1 and NDK r27+ (prefer r28+).
2. **Recompile all native libraries** with 16KB alignment.
3. **Remove hardcoded page size assumptions** (replace `4096`/`0x1000`/`PAGE_SIZE` with `sysconf(_SC_PAGESIZE)`).
4. **Check all third-party .so files** for compliance.
5. **Test on Android 15+ emulators or real devices**.

See [official migration steps](https://developer.android.com/guide/practices/page-sizes?hl=pt-br#compile-16-kb-alignment).

---

## Troubleshooting

- **`UNALIGNED (2**12)`**: The library is 4KB aligned. You must rebuild it with NDK r27+ or add linker flags.
- **`command not found: verify-16k-page-align`**: Ensure npm global bin is in your PATH, or use the shell script directly.
- **`objdump: command not found`**: Install `binutils`.
- **`Permission denied`**: Run `chmod +x verify-16k-page-align.sh` before executing.

---

## FAQ

**Q: Does this work for Java/Kotlin-only apps?**
A: No need—Java/Kotlin-only apps do not use native libraries and are already compatible.

**Q: What if my library is not 16KB aligned?**
A: Update your build tools and recompile. Contact third-party vendors for updated .so files.

**Q: Can I use this on macOS?**
A: Yes, install `binutils` via Homebrew.

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

## Show your support

Give a ⭐️ if this project helps you!

Or buy me a coffee 🙌🏾

<a href="https://www.buymeacoffee.com/hebertcisco">
  <img src="https://img.buymeacoffee.com/button-api/?text=Buy me a coffee&emoji=&slug=hebertcisco&button_colour=FFDD00&font_colour=000000&font_family=Inter&outline_colour=000000&coffee_colour=ffffff" />
</a>

## 📝 License

Copyright © 2025 [@hotbrainstech](https://github.com/hotbrainstech).

This project is [MIT](LICENSE) licensed.
