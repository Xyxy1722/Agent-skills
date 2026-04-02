# Comment Recovery

## Purpose

Use OMS1.0 as the source of truth for generated field comments when current generated comments are weak or wrong.

## Primary lookup order

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

## Search patterns

Use `rg` against OMS1.0 first.

Useful patterns:

```bash
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
