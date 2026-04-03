#!/usr/bin/env bash

set -euo pipefail

DEFAULT_TARGET_DIRS=(
    "cpp-demo/sdk/linux"
    "cpp-unit-testing/sdk/linux"
)
DEFAULT_IGNORE_LIBS=(
    "libhare_socket_efvi.so"
    "libhare_socket_exanic.so"
    "libhare_socket_instanta.so"
    "libhare_socket_rdma.so"
    "libhare_socket_td.so"
)

REFERENCE_DIR=""
TARGET_DIRS=()
IGNORE_LIBS=("${DEFAULT_IGNORE_LIBS[@]}")
CHECK_ONLY=0

declare -A LIB_VERSIONS

usage() {
    cat <<'EOF'
Usage:
  scripts/sync_sdk_linux_so.sh --reference DIR [--target DIR ...] [--set-version LIB=VERSION ...] [--check-only]

Defaults:
  --target     cpp-demo/sdk/linux
  --target     cpp-unit-testing/sdk/linux
  ignored new libs:
               libhare_socket_efvi.so
               libhare_socket_exanic.so
               libhare_socket_instanta.so
               libhare_socket_rdma.so
               libhare_socket_td.so

Behavior:
  1. Use the reference directory as the source of truth.
  2. Compare all logical *.so entries by SHA256 of the real payload file.
  3. If updates are found, require an explicit --set-version for each changed library.
  4. Copy the reference payload as libxxx.so.<version>.
  5. Recreate libxxx.so -> libxxx.so.<version>.
  6. Delete older libxxx.so.* payload files for the updated library in each target directory.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --reference|--source)
            REFERENCE_DIR="$2"
            shift 2
            ;;
        --target)
            TARGET_DIRS+=("$2")
            shift 2
            ;;
        --set-version)
            if [[ "$2" != *=* ]]; then
                echo "Invalid --set-version value: $2" >&2
                exit 1
            fi
            LIB_VERSIONS["${2%%=*}"]="${2#*=}"
            shift 2
            ;;
        --check-only)
            CHECK_ONLY=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ -z "$REFERENCE_DIR" ]]; then
    echo "--reference is required." >&2
    usage >&2
    exit 1
fi

if [[ ${#TARGET_DIRS[@]} -eq 0 ]]; then
    for dir in "${DEFAULT_TARGET_DIRS[@]}"; do
        if [[ -d "$dir" ]]; then
            TARGET_DIRS+=("$dir")
        fi
    done
fi

if [[ ${#TARGET_DIRS[@]} -eq 0 ]]; then
    echo "No target directories found. Pass --target explicitly." >&2
    exit 1
fi

if [[ ! -d "$REFERENCE_DIR" ]]; then
    echo "Reference directory does not exist: $REFERENCE_DIR" >&2
    exit 1
fi

for dir in "${TARGET_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        echo "Target directory does not exist: $dir" >&2
        exit 1
    fi
done

resolve_real_file() {
    local path="$1"
    if [[ ! -e "$path" && ! -L "$path" ]]; then
        return 1
    fi
    readlink -f "$path"
}

sha256_of() {
    local path="$1"
    sha256sum "$path" | awk '{print $1}'
}

is_ignored_lib() {
    local lib="$1"
    local ignored
    for ignored in "${IGNORE_LIBS[@]}"; do
        if [[ "$ignored" == "$lib" ]]; then
            return 0
        fi
    done
    return 1
}

logical_libs=()
while IFS= read -r file; do
    logical_libs+=("$(basename "$file")")
done < <(find "$REFERENCE_DIR" -maxdepth 1 \( -type f -o -type l \) -name '*.so' | sort)

if [[ ${#logical_libs[@]} -eq 0 ]]; then
    echo "No logical *.so entries found in reference: $REFERENCE_DIR" >&2
    exit 1
fi

changed_pairs=()
declare -A CHANGED_LIBS

echo "Reference directory: $REFERENCE_DIR"
for dir in "${TARGET_DIRS[@]}"; do
    echo "Target directory:    $dir"
done
echo

for target_dir in "${TARGET_DIRS[@]}"; do
    echo "Comparing against target: $target_dir"
    for lib in "${logical_libs[@]}"; do
        if is_ignored_lib "$lib"; then
            printf '  [SKIP]   %-28s ignored by policy\n' "$lib"
            continue
        fi

        ref_real="$(resolve_real_file "$REFERENCE_DIR/$lib")" || {
            echo "[ERROR] Could not resolve reference entry: $REFERENCE_DIR/$lib" >&2
            exit 1
        }
        ref_sha="$(sha256_of "$ref_real")"

        target_real=""
        if [[ -e "$target_dir/$lib" || -L "$target_dir/$lib" ]]; then
            target_real="$(resolve_real_file "$target_dir/$lib")" || true
        fi

        if [[ -n "$target_real" && -f "$target_real" ]]; then
            target_sha="$(sha256_of "$target_real")"
        else
            target_sha="MISSING"
        fi

        if [[ "$ref_sha" == "$target_sha" ]]; then
            printf '  [OK]     %-28s sha256=%s\n' "$lib" "$ref_sha"
        else
            printf '  [UPDATE] %-28s reference=%s target=%s\n' "$lib" "$ref_sha" "$target_sha"
            changed_pairs+=("${target_dir}|${lib}")
            CHANGED_LIBS["$lib"]=1
        fi
    done
    echo
done

if [[ ${#changed_pairs[@]} -eq 0 ]]; then
    echo "No .so updates detected."
    exit 0
fi

echo "Detected updates:"
for pair in "${changed_pairs[@]}"; do
    IFS='|' read -r target_dir lib <<<"$pair"
    echo "  - $target_dir : $lib"
done

if [[ "$CHECK_ONLY" -eq 1 ]]; then
    exit 0
fi

for lib in "${!CHANGED_LIBS[@]}"; do
    if [[ -z "${LIB_VERSIONS[$lib]:-}" ]]; then
        echo "Missing explicit version: --set-version ${lib}=<version>" >&2
        exit 1
    fi
done

echo
echo "Applying update"

for pair in "${changed_pairs[@]}"; do
    IFS='|' read -r target_dir lib <<<"$pair"
    ref_real="$(resolve_real_file "$REFERENCE_DIR/$lib")"
    version="${LIB_VERSIONS[$lib]}"
    dst_versioned="$target_dir/$lib.$version"
    dst_link="$target_dir/$lib"

    cp -pf "$ref_real" "$dst_versioned"
    ln -sfn "$(basename "$dst_versioned")" "$dst_link"

    while IFS= read -r old_file; do
        [[ -z "$old_file" ]] && continue
        [[ "$(basename "$old_file")" == "$(basename "$dst_versioned")" ]] && continue
        rm -f "$old_file"
        echo "[DEL ] $target_dir : $(basename "$old_file")"
    done < <(find "$target_dir" -maxdepth 1 -type f -name "$lib.*" | sort)

    echo "[DONE] $target_dir : $lib"
    echo "       copied to $(basename "$dst_versioned")"
    echo "       linked  $(basename "$dst_link") -> $(basename "$dst_versioned")"
done

echo
echo "SDK .so update completed."
