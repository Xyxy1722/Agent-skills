---
name: oms-global-database-file
description: "Transform and validate generated database-layer files in the oms-global repository. Use when working on generated `oms-dao` or related `oms-common` table files such as `BaseDao`, `Dao`, `BaseData`, `Data`, `PageParam`, `Model`, MyBatis XML, and DAO/cache tests, especially for recovering field comments from OMS1.0 or RTFA GBK sources for `rtfa_*` tables, adding DAO SQL and cache-loading tests, isolating `oms-dao` from `oms-common` so `mvn -pl oms-dao test` passes, and finally moving model classes from `com.citics.global.base.model` to `com.citics.global.common.model`."
---

# OMS Global Database File

## Overview

Use this skill for generated table code in `oms-global`, mainly under `oms-dao`, when the task is not pure codegen but post-generation cleanup, validation, and migration.

Treat current naming as `omc*`. Treat OMS1.0 naming as `omsc*` and map between them by dropping the extra `s` in the current project name.

For `omc_eqd*` tables, treat `~/citics-workflow/eqd-trade` as the primary comment source instead of OMS1.0. Map the current table name to the corresponding EQD table by dropping the `omc_` prefix, for example `OMC_EQD_CONTRACT_INFO` -> `EQD_CONTRACT_INFO`.

For `rtfa_*` tables, treat the RTFA project under `~/citics-workflow/rtfa` as the primary comment source instead of OMS1.0. RTFA generated headers and SQL are GBK encoded; always decode them as GBK and write UTF-8 comments into `oms-global`.

## Workflow

### 1. Scope the table and generated files

Identify the table family first. Check:

- `oms-dao/src/main/java/.../dao/base/*BaseDao.java`
- `oms-dao/src/main/java/.../dao/*Dao.java`
- `oms-dao/src/main/java/.../data/base/*BaseData.java`
- `oms-dao/src/main/java/.../data/*Data.java`
- `oms-dao/src/main/java/.../model/*Model.java`
- `oms-dao/src/main/java/.../model/*PageParam.java`
- `oms-dao/src/main/resources/mybatis/base/*BaseDao.xml`
- `oms-dao/src/main/resources/mybatis/*Dao.xml`
- `oms-dao/src/test/java/...`

Check whether the table is a normal DAO-only table or a cache-backed table extending `AbstractCacheData`.

### 2. Recover field comments from source projects

For files that enumerate fields, especially `Model`, `PageParam`, and generated `BaseData` comments:

- If the previous generated file in the current repo already has a useful field comment and the field still has the same meaning after regeneration, reuse that old local comment first.
- For `omc_eqd*` tables, search `~/citics-workflow/eqd-trade` first for the corresponding `EQD_*` table, model, mapper XML, dict docs, or other same-domain source that clearly describes the field meaning.
- For `rtfa_*` tables, search `~/citics-workflow/rtfa` first. Prefer generated table headers such as `rtfa-release/lbm/tables/rtfa_<table>.h`; fall back to RTFA database init SQL only when the header has no matching field. Decode RTFA files with GBK and write UTF-8 comments into the current project.
- For `omc*` tables, search OMS1.0 first for the old corresponding `Omsc*` model class.
- Copy field comments only when the old class, RTFA header, or RTFA SQL clearly has the same field and the same meaning.
- When both the old local file and upstream source have usable comments, prefer:
  - old local file comment when it already matches the regenerated field semantics
  - upstream source comment when the regenerated field is new or the old local comment is stale
- If no matching source or useful field comment exists, leave the generated comment unchanged.
- Do not invent business semantics.

Read [references/comment-recovery.md](references/comment-recovery.md) before doing large comment recovery work.

### 3. Add tests

Always add or update tests for generated database files.

For normal DAO coverage:

- Reuse the current pattern based on `DaoTestSupport`.
- Validate mapper XML and generated SQL behavior, not private implementation details.
- Cover representative CRUD and query paths such as `insert`, `selectByPrimaryKey`, `selectAll`, `selectByParam`, `selectPage`, `update`, `updateAllField`, and `delete` when those methods exist.

Table-prefix test policy:

- `omc*` tables: add or update normal DAO tests and, when the table extends `AbstractCacheData`, add one dedicated cache-hit test file named `Omc<Table>CacheLoadingTest`.
- `oms*` tables: add or update normal DAO tests only. Do not add cache-hit tests by default.
- `rtfa*` tables: add or update normal DAO tests only. Do not add cache-hit tests by default.
- If a non-`omc*` table appears to need cache-hit coverage, stop and list the conclusion for user confirmation before adding the test.

For confirmed `omc*` cache-backed tables:

- Create one dedicated cache-loading test class per table, named `Omc<Table>CacheLoadingTest`.
- Model each new cache-loading test on `OmcSysconfigCacheLoadingTest`. Prove startup-loaded cache data is visible through `AbstractCacheData` accessors such as `select(...)` and `selectAll()`.
- Do not group multiple cache-backed tables into a shared data test such as `OmcCachedTablesLoadingTest` or `OmcReferenceTableCacheLoadingTest`. If such a grouped test already exists, split it back into per-table test classes.
- Keep cache metadata verification centralized in `SysMemcacheTableCacheMetaLoadingTest`.
- When adding a new cache-backed `omc*` table, extend `SysMemcacheTableCacheMetaLoadingTest` with that table's `SYS_MEMCACHE_TABLE` row and assertions instead of creating another aggregated metadata test file.

Read [references/test-patterns.md](references/test-patterns.md) for the concrete patterns already running in this repo.

### 4. Run `oms-dao` tests and isolate `oms-dao` if needed

Run:

```bash
mvn -pl oms-dao test
```

If `oms-dao` still depends on `oms-common` and that blocks tests:

- Remove the `oms-common` dependency from `oms-dao/pom.xml`.
- Rewrite imports from `com.citics.global.common.model` to `com.citics.global.base.model` while `oms-dao` is isolated.
- Fix MyBatis XML `resultMap` types and test imports to match the isolated package.
- If some generated files still depend on missing `oms-common` types and are outside the current migration scope, delete those generated files in `oms-dao` so the module can test cleanly.

Keep the cleanup minimal and targeted to getting `mvn -pl oms-dao test` green.

### 5. Move models into `oms-common` last

After `oms-dao` tests are green, do the package migration step:

- Move model classes from `com.citics.global.base.model` to `com.citics.global.common.model`.
- Update all imports that reference those model classes.
- Delete the original `oms-dao/src/main/java/.../base/model/*` files for the tables you moved. This step is a real move, not a copy. Do not leave duplicate `base.model` and `common.model` versions of the same generated table class.

Do not require `mvn compile` for this final step if `oms-common` is still not in a compilable baseline. The point of this phase is package movement and reference updates, not full repo compilation.

## Guardrails

- Prefer the current repo's already-running test patterns over inventing new infrastructure.
- Keep controller/service concerns out of this skill; it is for generated database-layer files.
- Preserve `AbstractCacheData` behavior for cache-backed tables. Do not replace key-based reads with full-table scans.
- When testing cache metadata loading, separate:
  - metadata source verification from `SYS_MEMCACHE_TABLE`
  - cache hit verification for a concrete cache-backed table
- For `omc*` cache-backed tables, prefer one test file per table for cache-hit behavior and one shared `SysMemcacheTableCacheMetaLoadingTest` for metadata rows. For `oms*` and `rtfa*` tables, do not add cache-hit tests unless the user explicitly confirms they are required.
- If a generated file is obviously outside the current migration scope and blocks `oms-dao` tests because of old `oms-common` dependencies, delete it rather than partially porting unrelated business code.
- If code generation recreates `com.citics.global.base.model` files for tables that were already migrated, treat them as stale duplicates: recover comments if needed for the isolated `oms-dao` phase, but remove them again after the final move to `oms-common`.
