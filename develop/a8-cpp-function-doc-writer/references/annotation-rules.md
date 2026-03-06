# Annotation Rules

Use these rules to keep the document factual and reviewable.

## Core Principle

Describe what the code does. Do not evaluate whether the code should change.

## Description granularity

### High-level wrappers

Use one short sentence when the method mainly delegates work.

Example:

- `RunBusiness(...)` continues the transaction flow and dispatches into the business handler.

### Bottom-level methods

Use a more detailed description when the method is not expanded further or is effectively the last meaningful step in the chain.

Describe concrete behavior such as:

- parameter unpacking
- field assignment
- object initialization
- condition checks
- table queries
- table writes
- price, quantity, or amount calculations
- return conditions
- error throws
- state mutation on input or member objects

For unexpanded leaf methods in `Procedure`, include at least:

- branch trigger condition for the current path
- key input fields and key output/state mutations
- database read/write keys and actual table names (if any)
- important calculations or validations
- throw/return conditions (include error code when available)
- short-circuit/no-op/empty implementation behavior when present
- miss-handling behavior such as must-hit throw, miss-then-init-then-requery, or key-exists-then-update

When calculation or availability checks are the core behavior, include the concrete comparison formula and operands.

When an unexpanded leaf method still contains multiple material operations, do not compress it into one sentence. Use ordered sub-bullets in code order so a reviewer can match the document back to the source quickly.

Common triggers for sub-bullets:

- loops over instruction rows, stock rows, cache rows, or result rows
- cache-init helpers that query, synthesize a default record, write it, then requery
- validation methods that perform several distinct checks with different return paths
- utility/process methods that mutate several fields before delegating downstream

Example:

- `InitSysconfigBase(...)` reads the first `rtcm_sysconfig` record and checks whether `run_status` is `'0'`; otherwise it reports that the trading system is unavailable.

## Procedure database-detail rules

When a `Procedure` node touches database/cache data, do not stop at a vague statement such as "query config" or "write instruction table".

Always include these three elements in that node:

- operation type (`Query` / `InitCache` / `insert` / `update` / `delta-write`)
- key fields used by the query/write path
- actual table name resolved from code (`rtcm_*` / `rtfa_*` etc.)

Good:

- `QueryBsconfig(mktCode, bsflag, projectType)` reads `rtcm_bsconfig`, then caches pointer in `m_objCache.m_pBsconfig`.

Bad:

- queries bsconfig table and loads config.

When the path is `query miss -> build default record -> write -> requery`, describe all four stages and include the important initialized fields of the default record when the code sets them explicitly.

## Summary and scope rules

In `Summary`, include one explicit scope statement:

- what route/market/`bsflag` branches are expanded in this document
- what major branch families are intentionally not expanded

This scope statement must be consistent with the `TODO` section.

## Placement rules

- Put leaf-method detail directly under the matching call node in `Procedure`.
- Do not create a standalone `Bottom-level methods` section by default.
- Do not create a standalone `Key checks` section by default.
- Use separate extra sections only when the user explicitly asks for that document format.
- Keep file references on every top-level `Procedure` bullet and on materially important child bullets; do not rely on one parent reference to cover a long subtree.

## Fact wording

- Prefer direct factual wording.
- Write what is executed in the current path.
- Avoid speculative intent such as "probably used for" unless clearly marked as uncertain.

Good:

- `InitCacheStock(...)` loads stock data through `QueryStock(...)`.

Bad:

- `InitCacheStock(...)` may be intended for later stock processing.

## Dynamic dispatch rules

Never assume the declared type is the executed type.

When you see a parent-class pointer or reference:

- find where the object is created or assigned
- identify whether the target method is virtual
- inspect the actual child type if it can be resolved
- describe the child implementation, not the parent declaration

Common patterns to trace:

- `base_ptr = CreateInstance(...)`
- `base_ptr = new ChildType(...)`
- factory return selected by `if`, `switch`, `bsflag`, market, or route
- member pointer initialized in one method and invoked in another

If the runtime type cannot be resolved from available code:

- say the dynamic dispatch target is unresolved
- avoid paraphrasing the base implementation as if it were executed

## Table listing rules

Add a table to `Involved tables` only when one of these is true:

- a query helper reads it
- a write helper writes it
- a cache initializer loads it
- a struct or record tied to the flow clearly maps to it

Do not add a table merely because a similarly named variable exists.

`Involved tables` is not write-only:

- include tables read by query/cache-init/lookup steps in the described path
- include tables written by insert/update/delta-write steps in the described path

Prefer this listing shape:

- `读取表（主流程）`
- `写入表（主流程）`
- optional conditional marker such as `（条件读取：...）` or `（条件写入：...）`

For each table entry, include one evidence chain such as:

- `caller -> Query/InitCache/writetable wrapper -> manager/record type`, plus file references

If a helper uses a generic wrapper name such as `writetable_xxx`, `QueryXxx`, `SaveXxx`, or `InitCacheXxx`, do not stop there. Trace one level deeper until the actual table name is confirmed from:

- a concrete table struct or record type
- a table key string or serialized table name
- a manager, serializer, SQL fragment, or explicit table-name comparison

Prefer the real table name in the document, not the wrapper suffix.

## Macro and enum listing rules

Do not list a macro or enum name by itself.

For each listed macro or enum, include:

- the source file
- the effective value, definition, or branch condition
- one short note on how it affects the current flow

Good:

- `BUS_FLAG_INS_DIRI` -> `comm/trddefine.h`; value `40103`; marks the direct-instruction path.

Bad:

- `BUS_FLAG_INS_DIRI`

When a macro affects control flow (lock, transaction, branch, callback gate, third-call gate, etc.):

- include the macro definition source and expansion target
- include the compile-time condition that makes this macro/branch active in the current project build, based on `CMakeLists.txt` and included `.cmake` files
- describe only the active branch behavior for the current analysis target
- do not spend time expanding inactive compile branches unless the user explicitly asks for branch comparison

If the active compile condition cannot be confirmed from repository evidence (project files, build scripts, compile flags, or existing build config), stop and ask the user immediately before continuing that flow segment.

## Route-key rewrite rules

If a route key is rewritten before dispatch (for example `bsflag`, market, order type, route code):

- record the rewrite only when it affects the user-requested branch scope
- skip unrelated rewrite branches by default

## Expansion rules

Expand a node when it affects feature understanding.

Good candidates:

- entry function
- route decisions
- parameter unpack
- key validation
- market or bsflag branch
- table read or write
- risk, amount, or availability calculation
- dynamic dispatch resolution
- utility/process/helper methods that do the real work behind high-level wrappers, phase methods, or orchestration methods

Do not expand:

- obvious boilerplate
- macros with no impact on behavior
- repeated init calls that do not alter conclusions

If a wrapper delegates into a downstream method that contains the first real query, write, calculation, or status mutation, the downstream method is the one that needs the detail density. Do not spend more words on the wrapper than on the downstream leaf.

## Wording rules

- Use exact identifiers from code.
- Use short sentences for wrapper methods.
- Use more detail for bottom-level methods.
- For DB-related nodes in `Procedure`, include key fields and table names explicitly.
- Keep bottom-level detail in the `Procedure` tree.
- If code behavior is suspicious (for example assignment in condition), describe literal runtime behavior and avoid inferring intent.
- Use `dispatch unresolved` or `not expanded` instead of guessing.
- If a sentence could describe many different methods, it is too generic for an unexpanded leaf. Replace it with code-specific conditions, fields, keys, mutations, or formulas.

## TODO rules

Use `TODO` for intentionally skipped branch families and follow-up deep dives.
