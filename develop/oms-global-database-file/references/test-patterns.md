# Test Patterns

## Goal

Use the existing `oms-dao` tests as the default pattern. Do not invent a new test harness if the current one already covers the need.

## Existing DAO test pattern

Main helper:

- `oms-dao/src/test/java/com/citics/global/base/dao/support/DaoTestSupport.java`

Representative DAO tests:

- `oms-dao/src/test/java/com/citics/global/base/dao/OmcBsconfigDaoTest.java`
- `oms-dao/src/test/java/com/citics/global/base/dao/OmcSysconfigDaoTest.java`

Pattern:

1. Create an H2-backed context with `DaoTestSupport.createContext(...)`.
2. Load schema SQL from `oms-dao/src/test/resources/sql/*.sql`.
3. Load the generated mapper XML under `mybatis/base` and `mybatis`.
4. Assert generated SQL behavior through the mapper interface.

Preferred file shape:

1. Create one DAO test class per table family, named after the mapper interface, such as `OmcFundacctExtDaoTest`.
2. Keep that class focused on one generated table family and its CRUD/query paths.
3. Do not combine multiple generated table families into one DAO smoke test file. If a grouped DAO smoke test exists, split it back into per-table files.

## Existing cache-backed table tests

Cache hit / startup preload behavior:

- `oms-dao/src/test/java/com/citics/global/base/data/OmcSysconfigCacheLoadingTest.java`

What it proves:

- `AbstractCacheData`-based reads hit startup-loaded cache data
- `select(...)` and `selectAll()` can read from the cache without DB fallback

Default prefix rule:

- `omc*` tables: add one dedicated cache-hit test file per cache-backed table, named `Omc<Table>CacheLoadingTest.java`.
- `oms*` and `rtfa*` tables: do not add cache-hit tests by default. If the code suggests cache-hit coverage might be needed, list that conclusion and ask the user before writing tests.

Preferred pattern for confirmed `omc*` cache-backed tables:

1. Copy the shape of `OmcSysconfigCacheLoadingTest`.
2. Create one dedicated file per table, named `Omc<Table>CacheLoadingTest.java`.
3. Keep each file focused on one table's cache name, key shape, preload rows, and `AbstractCacheData` accessor behavior.
4. Do not group multiple tables into a shared cache-hit test file. If a grouped file exists, split it into per-table tests.

## Existing `SYS_MEMCACHE_TABLE` metadata test

Metadata source verification:

- `oms-dao/src/test/java/com/citics/global/base/data/SysMemcacheTableCacheMetaLoadingTest.java`
- `oms-dao/src/test/resources/sql/sys_memcache_table_schema.sql`

What it proves:

- `CacheMetaDao.xml` reads cache metadata from `SYS_MEMCACHE_TABLE`
- `DbCacheMetaLoader` converts those rows into `CacheMetaDto`

Preferred pattern for confirmed `omc*` cache-backed tables:

1. Reuse `SysMemcacheTableCacheMetaLoadingTest`.
2. Add the new table's `SYS_MEMCACHE_TABLE` row setup there.
3. Add explicit assertions there for the new cache name, key, SQL, and row type.
4. Do not create another aggregated metadata test class for the same purpose.

For `oms*` and `rtfa*` tables, do not extend `SysMemcacheTableCacheMetaLoadingTest` unless the user explicitly confirms cache metadata coverage is required.

## Confirmed cache metadata chain

The current dependency sources confirm this flow:

1. `DbCacheMetaLoader.loadMeta()`
2. `CacheManageService.queryCacheMetaFromDb(...)`
3. `CacheMetaDao.xml` query on `SYS_MEMCACHE_TABLE`
4. `KaceCacheLoader.loadTableDataCache(...)` creates and loads caches from those metadata rows

So for cache-backed tables, test two things separately:

- the metadata row can be read from `SYS_MEMCACHE_TABLE`
- the concrete `AbstractCacheData` consumer can hit a startup-loaded cache

The split should be:

- one dedicated `Omc<Table>CacheLoadingTest` per confirmed `omc*` cache-backed table
- one shared `SysMemcacheTableCacheMetaLoadingTest` extended table by table for confirmed `omc*` cache metadata

## `mvn test` rule

Primary validation command:

```bash
mvn -pl oms-dao test
```

If this fails because `oms-dao` still drags in old `oms-common` types:

- remove the `oms-common` dependency from `oms-dao/pom.xml`
- rewrite imports and MyBatis XML types to `com.citics.global.base.model`
- delete unrelated generated files that still depend on unavailable old types and are outside the current table scope
