#!/usr/bin/env bash
set -euo pipefail

# Verifies that all native .so libraries inside an APK/AAB are aligned to 16KB (0x4000) pages.
# Usage: scripts/verify-16k-page-align.sh <path-to-apk-or-aab>

ARCHIVE_PATH=${1:-}
if [[ -z "$ARCHIVE_PATH" ]]; then
  echo "Usage: $0 <path-to-apk-or-aab>"
  exit 2
fi

if [[ ! -f "$ARCHIVE_PATH" ]]; then
  echo "File not found: $ARCHIVE_PATH"
  exit 2
fi

tmpdir=$(mktemp -d)
cleanup() { rm -rf "$tmpdir" || true; }
trap cleanup EXIT

# Pick readelf or llvm-readelf
READELF_BIN=""
if command -v readelf >/dev/null 2>&1; then
  READELF_BIN=$(command -v readelf)
elif command -v llvm-readelf >/dev/null 2>&1; then
  READELF_BIN=$(command -v llvm-readelf)
else
  # Try NDK llvm-readelf, if ANDROID_NDK_ROOT provided
  if [[ -n "${ANDROID_NDK_ROOT:-}" ]] && [[ -x "$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf" ]]; then
    READELF_BIN="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf"
  fi
fi

if [[ -z "$READELF_BIN" ]]; then
  echo "readelf/llvm-readelf not found. Ensure binutils or NDK llvm-readelf is installed."
  exit 3
fi

echo "Using readelf: $READELF_BIN"

echo "Inspecting: $ARCHIVE_PATH"

# List .so entries inside the archive
if [[ "$ARCHIVE_PATH" == *.apk ]]; then
  mapfile -t SO_ENTRIES < <(unzip -Z1 "$ARCHIVE_PATH" | grep -E '^lib/[^/]+/[^/]+\.so$' || true)
elif [[ "$ARCHIVE_PATH" == *.aab ]]; then
  # AAB layout: <module>/lib/<abi>/*.so (commonly base/lib/...)
  mapfile -t SO_ENTRIES < <(unzip -Z1 "$ARCHIVE_PATH" | grep -E '(^|.*/)(lib)/[^/]+/[^/]+\.so$' || true)
else
  echo "Unknown file extension. Provide .apk or .aab"
  exit 2
fi

if [[ ${#SO_ENTRIES[@]} -eq 0 ]]; then
  echo "No .so libraries found in archive. Nothing to verify."
  exit 0
fi

echo "Found ${#SO_ENTRIES[@]} native libraries"

FAILED=0
for entry in "${SO_ENTRIES[@]}"; do
  # Extract to temp file
  out="$tmpdir/$(basename "$entry")"
  unzip -p "$ARCHIVE_PATH" "$entry" > "$out"

  # Check program headers for LOAD alignment entries. Fail if any LOAD has 0x1000 alignment.
  if "$READELF_BIN" -l "$out" | awk '/Program Headers:/,0' | grep -E '^ +LOAD' | grep -q '0x1000'; then
    echo "[FAIL] $entry has LOAD segment aligned to 0x1000 (4KB)."
    FAILED=1
  else
    echo "[OK]   $entry aligned to 16KB (no 0x1000 LOAD segments detected)."
  fi
done

if [[ $FAILED -ne 0 ]]; then
  echo "\nOne or more native libraries are not 16KB aligned."
  echo "Ensure AGP >= 8.5.1, NDK r27+, and rebuild any third-party .so with 16KB page alignment."
  exit 4
fi

echo "\nAll native libraries appear 16KB aligned."
exit 0