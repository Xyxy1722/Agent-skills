---
name: oms-global-database-file
description: "Transform and validate generated database-layer files in the oms-global repository. Use when working on generated `oms-dao` or related `oms-common` table files such as `BaseDao`, `Dao`, `BaseData`, `Data`, `PageParam`, `Model`, MyBatis XML, and DAO/cache tests, especially for recovering field comments from OMS1.0, adding DAO SQL and cache-loading tests, isolating `oms-dao` from `oms-common` so `mvn -pl oms-dao test` passes, and finally moving model classes from `com.citics.global.base.model` to `com.citics.global.common.model`."
---

# OMS Global Database File

## Overview

Use this skill for generated table code in `oms-global`, mainly under `oms-dao`, when the task is not pure codegen but post-generation cleanup, validation, and migration.

Treat current naming as `omc*`. Treat OMS1.0 naming as `omsc*` and map between them by dropping the extra `s` in the current project name.

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

### 2. Recover field comments from OMS1.0

For files that enumerate fields, especially `Model`, `PageParam`, and generated `BaseData` comments:

- Search OMS1.0 first for the old corresponding `Omsc*` model class.
- Copy field comments only when the old class clearly has the same field and the same meaning.
- If OMS1.0 has no matching class or no useful field comment, leave the generated comment unchanged.
- Do not invent business semantics.

Read [references/comment-recovery.md](references/comment-recovery.md) before doing large comment recovery work.

### 3. Add tests

Always add or update tests for generated database files.

For normal DAO coverage:

- Reuse the current pattern based on `DaoTestSupport`.
- Validate mapper XML and generated SQL behavior, not private implementation details.
- Cover representative CRUD and query paths such as `insert`, `selectByPrimaryKey`, `selectAll`, `selectByParam`, `selectPage`, `update`, `updateAllField`, and `delete` when those methods exist.

For cache-backed tables:

- Add a cache-hit test proving startup-loaded cache data is visible through `AbstractCacheData` accessors such as `select(...)` and `selectAll()`.
- Add a separate metadata test proving cache metadata is loaded from `SYS_MEMCACHE_TABLE`.

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

Do not require `mvn compile` for this final step if `oms-common` is still not in a compilable baseline. The point of this phase is package movement and reference updates, not full repo compilation.

## Guardrails

- Prefer the current repo's already-running test patterns over inventing new infrastructure.
- Keep controller/service concerns out of this skill; it is for generated database-layer files.
- Preserve `AbstractCacheData` behavior for cache-backed tables. Do not replace key-based reads with full-table scans.
- When testing cache metadata loading, separate:
  - metadata source verification from `SYS_MEMCACHE_TABLE`
  - cache hit verification for a concrete cache-backed table
- If a generated file is obviously outside the current migration scope and blocks `oms-dao` tests because of old `oms-common` dependencies, delete it rather than partially porting unrelated business code.
