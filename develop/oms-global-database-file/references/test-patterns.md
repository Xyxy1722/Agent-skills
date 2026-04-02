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

## Existing cache-backed table tests

Cache hit / startup preload behavior:

- `oms-dao/src/test/java/com/citics/global/base/data/OmcSysconfigCacheLoadingTest.java`

What it proves:

- `AbstractCacheData`-based reads hit startup-loaded cache data
- `select(...)` and `selectAll()` can read from the cache without DB fallback

## Existing `SYS_MEMCACHE_TABLE` metadata test

Metadata source verification:

- `oms-dao/src/test/java/com/citics/global/base/data/SysMemcacheTableCacheMetaLoadingTest.java`
- `oms-dao/src/test/resources/sql/sys_memcache_table_schema.sql`

What it proves:

- `CacheMetaDao.xml` reads cache metadata from `SYS_MEMCACHE_TABLE`
- `DbCacheMetaLoader` converts those rows into `CacheMetaDto`

## Confirmed cache metadata chain

The current dependency sources confirm this flow:

1. `DbCacheMetaLoader.loadMeta()`
2. `CacheManageService.queryCacheMetaFromDb(...)`
3. `CacheMetaDao.xml` query on `SYS_MEMCACHE_TABLE`
4. `KaceCacheLoader.loadTableDataCache(...)` creates and loads caches from those metadata rows

So for cache-backed tables, test two things separately:

- the metadata row can be read from `SYS_MEMCACHE_TABLE`
- the concrete `AbstractCacheData` consumer can hit a startup-loaded cache

## `mvn test` rule

Primary validation command:

```bash
mvn -pl oms-dao test
```

If this fails because `oms-dao` still drags in old `oms-common` types:

- remove the `oms-common` dependency from `oms-dao/pom.xml`
- rewrite imports and MyBatis XML types to `com.citics.global.base.model`
- delete unrelated generated files that still depend on unavailable old types and are outside the current table scope
