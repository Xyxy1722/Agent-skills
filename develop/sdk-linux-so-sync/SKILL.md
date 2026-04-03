---
name: sdk-linux-so-sync
description: Sync A8 Linux SDK shared libraries from a release sdk/linux directory into project sdk/linux directories by comparing SHA256, requiring an explicit version for every updated .so, recreating symlinks, and deleting old versioned payloads for the updated libraries. Use when updating cpp-demo/sdk/linux and cpp-unit-testing/sdk/linux from a delivered SDK package.
---

# SDK Linux SO Sync

Use this skill when a new A8 SDK delivery updates files under `sdk/linux` and you need to sync the shared libraries into this repository.

## Workflow

1. Use the bundled script `scripts/sync_sdk_linux_so.sh`.
2. Always pass the release directory with `--reference /path/to/sdk/linux`.
3. Run `--check-only` first to confirm which logical `*.so` files changed.
4. For every changed library, provide an explicit `--set-version libname.so=version`.
5. Run the real update.
6. Verify the logical symlink points to `libname.so.<version>` in each target directory.

## Rules

- The reference directory is the source of truth.
- Compare the SHA256 of the real payload file, not only the symlink name.
- Every updated `*.so` must have an explicit version suffix. Do not guess or omit it.
- After updating a library in a target directory, delete older versioned payload files for that same library and keep only:
  - `libname.so`
  - `libname.so.<new-version>`
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
