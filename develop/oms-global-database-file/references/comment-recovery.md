# Comment Recovery

## Purpose

Use the appropriate upstream project as the source of truth for generated field comments when current generated comments are weak or wrong: OMS1.0 for most `omc*` tables, `eqd-trade` for `omc_eqd*` tables, and RTFA for `rtfa_*` tables.

Before going to upstream sources, check whether the previous generated file in the current repo already has a useful field comment. If the regenerated field still has the same meaning, prefer reusing that old local comment rather than replacing it mechanically.

## OMS1.0 lookup order

1. Look in:

`~/citics-workflow/OMS1.0/trade-app/modules/oms-common/src/main/java/com/szkingdom/oms/common/base/model`

2. Find the old `Omsc*` model corresponding to the current `Omc*` class.

Examples:

- current `OmcSysconfig` -> old `OmscSysconfig`
- current `OmcBsconfig` -> old `OmscBsconfig`

3. Copy field comments only when:

- the field name matches directly, or
- the field name changed in a trivial generator-style way and the semantic match is obvious

4. If no comment is present in OMS1.0, do not invent one.

## OMC_EQD table lookup

For `omc_eqd*` tables, use `~/citics-workflow/eqd-trade` before OMS1.0.

Map the current table name to the corresponding EQD table by dropping the `omc_` prefix.

Examples:

- current `OMC_EQD_CONTRACT_INFO` -> upstream `EQD_CONTRACT_INFO`

Preferred lookup order:

1. Previous generated file in the current repo, if the field meaning is still the same
2. `eqd-trade` table model, mapper XML, or import SQL for the corresponding `EQD_*` table
3. `eqd-trade` dict/reference docs such as `docs/Dict字典表.md` when the field is a coded domain value
4. OMS1.0 only if the field still clearly belongs to the same business concept and `eqd-trade` has no reliable comment source

Copy comments only when the `eqd-trade` source clearly supports the same field meaning. For transformed OMC fields that do not exist upstream, leave the generated comment unchanged unless a direct same-domain mapping is obvious from current mapper XML or import SQL.

## Search patterns

Use `rg` against the primary upstream source first.

Useful patterns:

```bash
rg -n "EQD_CONTRACT_INFO|PARTY_SHORTNAME|RISK_VALID_TYPE|TRADE_SUB_NODE" ~/citics-workflow/eqd-trade -g '*.java' -g '*.xml' -g '*.md'
rg -n "class OmscSysconfig|private .* sysDate|private .* trdEnddate" ~/citics-workflow/OMS1.0/trade-app/modules/oms-common/src/main/java
rg -n "class OmscBsconfig|private .* bsflag|private .* canCancelFlag" ~/citics-workflow/OMS1.0/trade-app/modules/oms-common/src/main/java
```

If the model path misses, broaden to all Java sources in OMS1.0:

```bash
rg -n "class Omsc<TableName>|<fieldName>" ~/citics-workflow/OMS1.0 -g '*.java'
```

## What to update

Prefer updating:

- model field comments
- page param field comments
- obvious generated class-level table descriptions when OMS1.0 has a better one

Usually do not spend time rewriting:

- boilerplate getter/setter comments
- generic generated method comments unless the task explicitly asks for them

## Local old-file priority

Use this order when recovering comments:

1. Previous generated file in the current repo, if the field name and meaning are still the same
2. Upstream `eqd-trade` sources for `omc_eqd*`
3. Upstream RTFA header / RTFA SQL for `rtfa_*`
4. Upstream OMS1.0 model for other `omc*`

Do not carry old comments forward when the regenerated field semantics changed. In that case, prefer the upstream source that matches the new field meaning, or leave the generated comment unchanged if no reliable source exists.

## RTFA table lookup

For `rtfa_*` tables, use `~/citics-workflow/rtfa` instead of OMS1.0 as the comment source. RTFA files are GBK encoded; decode with GBK and write UTF-8 comments into `oms-global`.

Preferred lookup order:

1. Generated table header: `~/citics-workflow/rtfa/rtfa-release/lbm/tables/rtfa_<table>.h`
2. Disk or load table headers under `rtfa-release/lbm/` only when the primary table header is missing or incomplete
3. Database init SQL such as `rtfa-release/database/init/create table.sql` only when a column comment clearly maps to the generated Java field

When reading C++ headers, map member names to Java fields by removing the generator prefix and lowercasing the first semantic token. Examples:

- `m_nProjectId` -> `projectId`
- `m_dbAdjAmt` -> `adjAmt`
- `m_szCcyType` -> `ccyType`
- `m_cTrdPositionDirect` -> `trdPositionDirect`

If the RTFA SQL column name differs from the current generated Java/MyBatis name, do not force a comment match unless the meaning is obvious from a current mapper XML or table header.
