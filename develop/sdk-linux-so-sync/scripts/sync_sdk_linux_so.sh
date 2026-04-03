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
  7. Copy all files from the sibling reference x64 directory into each target sibling win64 directory.
  8. Verify the final target sdk/linux and sdk/win64 contents match the release package.
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

REFERENCE_SDK_DIR="$(dirname "$REFERENCE_DIR")"
REFERENCE_WIN64_DIR="$REFERENCE_SDK_DIR/x64"

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

verify_linux_target() {
    local target_dir="$1"
    local failed=0
    local lib ref_real ref_sha target_real target_sha

    echo "Verifying Linux target: $target_dir"
    for lib in "${logical_libs[@]}"; do
        if is_ignored_lib "$lib"; then
            continue
        fi

        ref_real="$(resolve_real_file "$REFERENCE_DIR/$lib")" || {
            echo "[ERROR] Could not resolve reference entry during verify: $REFERENCE_DIR/$lib" >&2
            return 1
        }
        ref_sha="$(sha256_of "$ref_real")"

        if [[ ! -e "$target_dir/$lib" && ! -L "$target_dir/$lib" ]]; then
            echo "[VERIFY][MISS] $target_dir : $lib" >&2
            failed=1
            continue
        fi

        target_real="$(resolve_real_file "$target_dir/$lib")" || {
            echo "[VERIFY][ERR ] $target_dir : $lib resolve failed" >&2
            failed=1
            continue
        }
        target_sha="$(sha256_of "$target_real")"

        if [[ "$ref_sha" == "$target_sha" ]]; then
            printf '  [VERIFY][OK ] %-28s sha256=%s\n' "$lib" "$ref_sha"
        else
            printf '  [VERIFY][BAD] %-28s reference=%s target=%s\n' "$lib" "$ref_sha" "$target_sha" >&2
            failed=1
        fi
    done

    return "$failed"
}

verify_win64_target() {
    local target_win64_dir="$1"
    local failed=0
    local rel ref_file target_file ref_sha target_sha

    if [[ ! -d "$REFERENCE_WIN64_DIR" ]]; then
        return 0
    fi

    echo "Verifying win64 target: $target_win64_dir"
    while IFS= read -r rel; do
        [[ -z "$rel" ]] && continue
        ref_file="$REFERENCE_WIN64_DIR/$rel"
        target_file="$target_win64_dir/$rel"

        if [[ ! -f "$target_file" ]]; then
            echo "[VERIFY][MISS] $target_win64_dir : $rel" >&2
            failed=1
            continue
        fi

        ref_sha="$(sha256_of "$ref_file")"
        target_sha="$(sha256_of "$target_file")"

        if [[ "$ref_sha" == "$target_sha" ]]; then
            printf '  [VERIFY][OK ] %s\n' "$rel"
        else
            printf '  [VERIFY][BAD] %s reference=%s target=%s\n' "$rel" "$ref_sha" "$target_sha" >&2
            failed=1
        fi
    done < <(cd "$REFERENCE_WIN64_DIR" && find . -type f | sort | sed 's#^\./##')

    return "$failed"
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
if [[ -d "$REFERENCE_WIN64_DIR" ]]; then
    echo "Reference x64 dir:   $REFERENCE_WIN64_DIR"
fi
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

if [[ "$CHECK_ONLY" -eq 1 ]]; then
    if [[ ${#changed_pairs[@]} -eq 0 ]]; then
        echo "No .so updates detected."
    else
        echo "Detected updates:"
        for pair in "${changed_pairs[@]}"; do
            IFS='|' read -r target_dir lib <<<"$pair"
            echo "  - $target_dir : $lib"
        done
    fi
    exit 0
fi

if [[ ${#changed_pairs[@]} -eq 0 ]]; then
    echo "No .so updates detected."
else
    echo "Detected updates:"
    for pair in "${changed_pairs[@]}"; do
        IFS='|' read -r target_dir lib <<<"$pair"
        echo "  - $target_dir : $lib"
    done

    for lib in "${!CHANGED_LIBS[@]}"; do
        if [[ -z "${LIB_VERSIONS[$lib]:-}" ]]; then
            echo "Missing explicit version: --set-version ${lib}=<version>" >&2
            exit 1
        fi
    done

    echo
    echo "Applying Linux .so update"

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
fi

if [[ -d "$REFERENCE_WIN64_DIR" ]]; then
    echo
    echo "Applying x64 -> win64 copy"

    for target_dir in "${TARGET_DIRS[@]}"; do
        target_sdk_dir="$(dirname "$target_dir")"
        target_win64_dir="$target_sdk_dir/win64"
        mkdir -p "$target_win64_dir"
        cp -a "$REFERENCE_WIN64_DIR"/. "$target_win64_dir"/
        echo "[DONE] $REFERENCE_WIN64_DIR -> $target_win64_dir"
    done
else
    echo
    echo "Reference x64 directory not found, skipping win64 copy: $REFERENCE_WIN64_DIR"
fi

echo
echo "Verifying final sync"

verify_failed=0
for target_dir in "${TARGET_DIRS[@]}"; do
    verify_linux_target "$target_dir" || verify_failed=1
    target_sdk_dir="$(dirname "$target_dir")"
    target_win64_dir="$target_sdk_dir/win64"
    verify_win64_target "$target_win64_dir" || verify_failed=1
done

echo
if [[ "$verify_failed" -ne 0 ]]; then
    echo "SDK sync verification failed." >&2
    exit 1
fi

echo "SDK sync completed and verified."
exit 0
