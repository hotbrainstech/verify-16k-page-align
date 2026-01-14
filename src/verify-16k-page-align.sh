#!/bin/bash
progname="${0##*/}"
progname="${progname%.sh}"

# usage: check_elf_alignment.sh [path to *.so files|path to *.apk]

cleanup_trap() {
  if [ -n "${tmp}" -a -d "${tmp}" ]; then
    rm -rf ${tmp}
  fi
  exit $1
}

usage() {
  echo "Host side script to check the ELF alignment of shared libraries."
  echo "Shared libraries are reported ALIGNED when their ELF regions are"
  echo "16 KB or 64 KB aligned. Otherwise they are reported as UNALIGNED."
  echo
  echo "Usage: ${progname} [input-path|input-APK|input-AAB|input-APEX]"
}


# Parse arguments
if [ ${#} -lt 1 ] || [ ${#} -gt 2 ]; then
  usage
  exit
fi

case "${1}" in
  --help|-h|'-?')
    usage
    exit
    ;;
  *)
    dir="${1}"
    ;;
esac

if ! [ -f "${dir}" -o -d "${dir}" ]; then
  echo "Invalid file: ${dir}" >&2
  exit 1
fi

# Set architecture filter
arch_filter="arm64-v8a"
if [ ${#} -eq 2 ] && [ "${2}" = "x86" ]; then
  arch_filter="arm64-v8a|x86_64"
fi

if [[ "${dir}" == *.apk ]] || [[ "${dir}" == *.aab ]]; then
  trap 'cleanup_trap' EXIT

  echo
  echo "Recursively analyzing $dir"
  echo

  if [[ "${dir}" == *.apk ]]; then
    if { zipalign --help 2>&1 | grep -q "\-P <pagesize_kb>"; }; then
      echo "=== APK zip-alignment ==="
      zipalign -v -c -P 16 4 "${dir}" | egrep "lib/(${arch_filter})|Verification"
      echo "========================="
    else
      echo "NOTICE: Zip alignment check requires build-tools version 35.0.0-rc3 or higher."
      echo "  You can install the latest build-tools by running the below command"
      echo "  and updating your \$PATH:"
      echo
      echo "    sdkmanager \"build-tools;35.0.0-rc3\""
    fi
  fi

  dir_filename=$(basename "${dir}")
  tmp=$(mktemp -d -t "${dir_filename%.*}_out_XXXXX")
  unzip -q "${dir}" "lib/*" -d "${tmp}"
  dir="${tmp}"
fi

if [[ "${dir}" == *.apex ]]; then
  trap 'cleanup_trap' EXIT

  echo
  echo "Recursively analyzing $dir"
  echo

  dir_filename=$(basename "${dir}")
  tmp=$(mktemp -d -t "${dir_filename%.apex}_out_XXXXX")
  deapexer extract "${dir}" "${tmp}" || { echo "Failed to deapex." && exit 1; }
  dir="${tmp}"
fi

RED="\e[31m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

unaligned_libs=()

echo
echo "=== ELF alignment ==="


matches="$(find "${dir}" -type f | egrep "lib/(${arch_filter})/.*\.so$")"
IFS=$'\n'
for match in $matches; do
  # We could recursively call this script or rewrite it to though.
  [[ "${match}" == *".apk" ]] && echo "WARNING: doesn't recursively inspect .apk file: ${match}"
  [[ "${match}" == *".apex" ]] && echo "WARNING: doesn't recursively inspect .apex file: ${match}"

  [[ $(file "${match}") == *"ELF"* ]] || continue

  res="$(objdump -p "${match}" | grep LOAD | awk '{ print $NF }' | head -1)"
  if [[ $res =~ 2\*\*(1[4-9]|[2-9][0-9]|[1-9][0-9]{2,}) ]]; then
    echo -e "${match}: ${GREEN}ALIGNED${ENDCOLOR} ($res)"
  else
    echo -e "${match}: ${RED}UNALIGNED${ENDCOLOR} ($res)"
    unaligned_libs+=("${match}")
  fi
done

if [ ${#unaligned_libs[@]} -gt 0 ]; then
  echo -e "${RED}Found ${#unaligned_libs[@]} unaligned libs (only arm64-v8a/x86_64 libs need to be aligned).${ENDCOLOR}"
  echo "====================="
  exit 1
elif [ -n "${dir_filename}" ]; then
  echo -e "ELF Verification Successful"
fi
echo "====================="