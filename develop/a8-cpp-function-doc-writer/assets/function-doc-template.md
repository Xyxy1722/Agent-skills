# <function-id>-<function-name>

## Summary

- <one or two lines on what this function or flow does>
- 当前文档重点展开 `<route/market/bsflag scope>`；未展开 `<major branch families>`

## Involved tables

- 读取表（主流程）
  - `<table-name>`
    - `<caller> -> <Query/InitCache helper> -> <manager/record>`，见 `<path:line>`
  - `<table-name>`（条件读取：`<trigger condition>`）
    - `<caller> -> <Query/InitCache helper> -> <manager/record>`，见 `<path:line>`
- 写入表（主流程）
  - `<table-name>`
    - `<caller> -> <writetable/WriteCache helper> -> <manager/record>`，见 `<path:line>`
  - `<table-name>`（条件写入：`<trigger condition>`）
    - `<caller> -> <writetable/WriteCache helper> -> <manager/record>`，见 `<path:line>`

## Involved macros / enums

- <macro-or-enum>

## Entry

- <entry function> -> `<path:line>`
- <if available: function-number/export-macro binding chain> -> `<path:line>`

## Procedure

- <top-level function or route> -> `<path:line>`
  - <next call> -> `<path:line>` <一句话描述这个调用做了什么>
  - <leaf call> -> `<path:line>` <如果这里不再下钻，在此节点写清楚内部查询/写表涉及的键字段+表名、短路/空实现、比较公式、字段回写和异常条件>

## TODO

- <deliberately skipped branch family>
- <later refinement only if really needed>
