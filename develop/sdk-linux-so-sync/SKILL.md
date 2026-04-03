---
name: sdk-linux-so-sync
description: Sync A8 SDK deliveries into project sdk directories. Compare shared libraries from a release sdk/linux directory into project sdk/linux directories by SHA256, require an explicit version for every updated .so, recreate symlinks, delete old versioned payloads for updated libraries, copy the release sdk/x64 contents into each target sdk/win64 directory, and verify the final linux and win64 contents match the release package. Use when updating cpp-demo/sdk and cpp-unit-testing/sdk from a delivered SDK package.
---

# SDK Linux SO Sync

Use this skill when a new A8 SDK delivery updates files under `sdk/linux` and `sdk/x64` and you need to sync them into this repository.

## Workflow

1. Use the bundled script `scripts/sync_sdk_linux_so.sh`.
2. Always pass the release directory with `--reference /path/to/sdk/linux`.
3. Run `--check-only` first to confirm which logical `*.so` files changed.
4. For every changed library, provide an explicit `--set-version libname.so=version`.
5. Run the real update.
6. Verify the logical symlink points to `libname.so.<version>` in each target `sdk/linux` directory.
7. Verify the target `sdk/linux` logical libraries match the release `sdk/linux`.
8. Verify the target `sdk/win64` files match the release `sdk/x64`.

## Rules

- The reference directory is the source of truth.
- Compare the SHA256 of the real payload file, not only the symlink name.
- Every updated `*.so` must have an explicit version suffix. Do not guess or omit it.
- After updating a library in a target directory, delete older versioned payload files for that same library and keep only:
  - `libname.so`
  - `libname.so.<new-version>`
- Derive the release Windows source directory as the sibling `x64/` directory next to the passed `sdk/linux` reference directory.
- For every target `sdk/linux` directory, derive the Windows target as its sibling `sdk/win64` directory.
- Copy all files from the release `sdk/x64` directory into each target `sdk/win64` directory, overwriting files with the same name.
- After syncing, verify each target `sdk/linux` logical `*.so` entry matches the release `sdk/linux` by SHA256 of the real payload file.
- After syncing, verify each target `sdk/win64` file matches the release `sdk/x64` by relative path and SHA256.
- Fail the run if linux or win64 verification finds a mismatch or missing file.
- Ignore these delivered-but-unused libraries unless the user explicitly asks otherwise:
  - `libhare_socket_efvi.so`
  - `libhare_socket_exanic.so`
  - `libhare_socket_instanta.so`
  - `libhare_socket_rdma.so`
  - `libhare_socket_td.so`

## Commands

Check only:

```bash
scripts/sync_sdk_linux_so.sh \
  --reference /home/fxy/citics-workflow/tmp/a8clientsdk_install_c++_2.1.20/sdk/linux \
  --check-only
```

Update with explicit versions:

```bash
scripts/sync_sdk_linux_so.sh \
  --reference /home/fxy/citics-workflow/tmp/a8clientsdk_install_c++_2.1.20/sdk/linux \
  --set-version liba8clientsdk.so=2.1.20 \
  --set-version libhare_socket.so=1.0.2 \
  --set-version libhare_socket_normal.so=1.0.2
```

## Notes

- Default targets are `cpp-demo/sdk/linux` and `cpp-unit-testing/sdk/linux` when they exist under the current working directory.
- If a changed library is missing a `--set-version`, the script exits with an error instead of prompting.
- If the release directory contains plain `.so` files instead of versioned symlinks, that is fine. The version still comes from the explicit `--set-version` values.
- When `--reference` is `/path/to/sdk/linux`, the script will also use `/path/to/sdk/x64` as the Windows source directory when that directory exists.
- The verification step checks only release files against target files. It does not delete extra unrelated files under `win64`.
