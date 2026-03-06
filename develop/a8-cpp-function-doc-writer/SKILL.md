---
name: a8-cpp-function-doc-writer
description: Trace RTFA/A8 C and C++ trading code for a specific function number, entry function, or business flow and write structured Markdown documentation. Use when Codex needs to analyze .cpp/.cc/.cxx/.h/.hpp files, follow the main call chain, describe what each call does, identify involved tables and macros, resolve actual C++ dispatch targets, and produce or update function-level analysis docs with sections such as Involved tables and Procedure, with leaf-method details merged into Procedure nodes.
---

# Function Doc Writer

Use this skill to produce function-level analysis documents for the RTFA/JSTP trading codebase.

Treat the output as an engineering analysis document, not a generic code summary. Use Chinese to write the document unless the user asks for a different language.

Do not judge whether a method should change. Focus on describing what the current code does.

## Quick Start

1. Find the target entry by function number, function name, or dispatch point.
2. Expand the main call chain first; do not exhaustively enumerate every branch.
3. State document scope explicitly (expanded market/route/`bsflag` branches and intentionally skipped branch families).
4. Record concrete code references for each confirmed step.
5. For every call in the chain, describe what the callee does in the current flow.
6. For bottom-level methods that are not expanded further, describe the internal behavior in more detail, and place those details directly under the corresponding Procedure node.
7. When a `Procedure` node reads or writes a table, explicitly record operation type, key fields, and the real table name in that node.
8. Draft the document with the template in `assets/function-doc-template.md`.
9. Before finalizing, compare the draft against `examples/83300100-DailyInstDirectNew.md`; if a similar node in the draft is materially thinner than the example, expand it.

Read `references/search-playbook.md` before doing code discovery. Read `references/annotation-rules.md` before writing method descriptions.
Read `references/cpp-reading-rules.md` when the flow depends on inheritance, raw pointers, constructors, destructors, RAII guards, templates, or macro-heavy wrappers.

Use `scripts/new_doc.py` to generate a new Markdown skeleton when the user wants a fresh document file.
Use `examples/83300100-DailyInstDirectNew.md` as the preferred style example for structure and granularity.

## Workflow

### 1. Confirm the target

- Accept any of these as the starting anchor:
  - function number such as `83300100`
  - entry function such as `DailyInstDirectNew`
  - business flow label such as `OrderIns`
- If the user gives only a function number, search for dispatchers, exports, or handlers that mention it.
- If multiple candidates exist, choose the one that matches the surrounding business context and state the assumption.
- When the function number is available from code exports/registration, use code as the source of truth:
  - exported function declarations
  - export/registration macros
  - dispatch registration comments near export points
- If function-number evidence conflicts across files, explicitly note the conflict and ask the user before finalizing the document.

### 2. Discover the entry and route points

- Start from high-signal code locations:
  - external interface or exported handler
  - dispatcher `switch` or route function
  - business manager and flow classes
  - parameter unpack and validation layers
- Capture the first stable path from entry to the main business execution point.
- Prefer the dominant path used in production over helper noise.
- If a method definition is not found near the declaration or call site, perform a broader repository search before concluding that the implementation is missing. Include declaration-only matches, exported symbols, wrapper macros, and shared-library usage clues.
- Before expanding macro-heavy or `#if`-guarded code paths, confirm the active compile conditions from repository `CMakeLists.txt` and included `.cmake` files first.
- Focus the main flow on active compile branches only; skip inactive branches unless the user asks for explicit branch comparison.
- If active compile conditions cannot be confirmed, stop and ask the user immediately before continuing the affected flow.

### 3. Expand the main call chain

- Follow the call chain in execution order.
- Align branch scope with the user target first:
  - if the user specifies required `bsflag`/market/route branches, expand those branches first
  - do not expand unrelated branch families by default
- Keep the chain shallow enough to stay readable. Expand a branch only when it affects:
  - business routing
  - account lookup
  - table reads or writes
  - amount, price, or availability checks
  - market-specific logic
  - actual runtime dispatch target
- For each call, add a short behavior description immediately after the file reference.
- For each call that reads or writes data, describe at least:
  - read/write operation type (`Query`/`InitCache`/`insert`/`update`/`delta-write`)
  - key fields or filter fields used by that operation
  - actual table name proved by code
- When a method is not expanded further, describe its behavior in more detail than higher-level wrapper methods.
- For leaf methods that are not expanded further, include concrete behavior in execution order. Prefer covering:
  - branch trigger condition for the current path
  - key inputs and field mutations
  - query/write keys and table interactions
  - calculations or validations
  - throw/return conditions and error codes (when present)
- When an unexpanded leaf method contains multiple material steps, write 3-6 ordered sub-bullets under that node instead of compressing everything into one sentence.
- When a leaf method loops over instruction rows, stock rows, cache lists, or result rows, record the iteration object, per-iteration field mutations, and the downstream call triggered for each item.
- If the actual path contains short-circuit return, empty implementation, or no-op branch, write that explicitly instead of skipping it.
- If a query/write path has mandatory-hit behavior, miss-then-init-then-requery behavior, or insert-vs-update selection by key existence, document that behavior explicitly.
- For cache-init or query helpers with miss-then-init-then-requery behavior, describe the full sequence: first query, default-record field initialization, write helper, second query, and final miss failure if present.
- For amount/availability checks, write the effective comparison formula and both sides of the comparison, not only "do availability check".
- Keep all leaf-method detail inside `Procedure`; do not create a separate `Bottom-level methods` section unless the user explicitly asks for that format.
- Do not stop at orchestration or phase-wrapper methods just because their names look high-level. If a method mainly delegates to utility managers, process managers, service objects, helper classes, adapters, or tool classes, continue tracing downstream until you reach the methods that perform the real checks, calculations, queries, writes, or status changes.
- Collapse repetitive or irrelevant branches into a short note such as `TODO: other bsflag branches not expanded`.

### 4. Identify data and rule dependencies

- Record only dependencies that are evidenced by code:
  - database tables and cache objects
  - config records
  - macros and enums
  - route decisions
  - key validations
- Do not infer a table solely from naming conventions. Require an explicit query, write, cache init, struct, or helper call that ties the table to the flow.
- `Involved tables` must include both:
  - tables read by query/cache-init/lookup steps in the described flow
  - tables written by insert/update/delta-write steps
- In `Involved tables`, organize entries as read-group and write-group, and mark conditional entries with trigger reason when applicable.
- For each listed table, include one evidence chain in the form `caller -> wrapper -> manager/record`, with file references.
- When the code goes through wrappers such as `QueryXxx`, `InitCacheXxx`, or `writetable_xxx`, trace one level deeper to determine the actual table.
- When wrapper names are generic, keep tracing until the real table name is confirmed from a table struct, manager, schema binding, key builder, SQL fragment, serializer, or explicit table-name string. Do not assume any specific table prefix such as `rtfa_` or `rtcm_`; use whatever exact table name the code proves.
- For `Involved macros / enums`, do not list names only. Include the source file and the effective macro content, enum value, or compile-time branch meaning that matters for the current flow.
- For route-key rewriting (such as `bsflag` normalization, market remap, or order-type rewrite), record it only when it affects the user-requested branch scope. Do not document unrelated rewrite branches.

### 5. Resolve actual C++ execution targets

- Do not assume the implementation from the declared type is the implementation that actually runs.
- When a parent-class pointer or reference points to a child object, resolve the actual object type before describing behavior.
- Check these patterns carefully:
  - factory methods such as `CreateInstance(...)`
  - assignments from `new ChildType(...)`
  - virtual methods and `override`
  - member pointers set in a previous step, then invoked later
- If the runtime type is confirmed, describe the child implementation.
- If the runtime type cannot be confirmed from code, explicitly write that the dispatch target is unresolved. Do not silently describe the base-class method as actual behavior.

### 6. Interpret C++ object and lifetime behavior

- Distinguish owning pointers from non-owning aliases.
- In this codebase, raw pointers often represent borrowed objects or cached records, not ownership. Do not infer ownership unless code shows `new`, `delete`, destructor cleanup, smart pointer ownership, or factory lifetime rules.
- Check constructors, destructors, and init methods for side effects that affect later calls.
- Treat RAII helpers as behavior, not decoration:
  - lock guards affect lock lifetime
  - scoped objects may commit, unlock, close, or release resources at scope exit
- If a method stores a pointer or reference into a member, record that later behavior depends on the stored target.
- If templates or CRTP-like patterns appear, confirm whether the call is resolved statically or virtually before describing the executed body.

### 7. Write the document

- Use `assets/function-doc-template.md` as the starting structure.
- Default section set is `Summary`, `Involved tables`, `Involved macros / enums`, `Entry`, `Procedure`, `TODO`.
- Do not add `Key checks` or a standalone `Bottom-level methods` section unless the user requests those sections explicitly.
- Keep bullet indentation stable and readable.
- Put file references inline using backticks in the document body if that matches existing project style.
- Describe behavior, not design intent.
- In `Summary`, include one explicit scope line such as "current document expands X route and Y/Z branches; other branches are not expanded".
- In `Entry`, when function-number dispatch evidence exists, include the mapping chain from function number/export macro to actual entry implementation.
- In `Procedure`, do not write generic DB text such as "query config table". Write concrete statements like "query `rtcm_bsconfig` by `(mktCode, bsflag, projectType)` via `QueryBsconfig(...)`".
- If a call is affected by conditional compilation, state the relevant compile-time condition before describing the branch body.
- For conditional compilation, document the confirmed active condition for this project. Do not merge multiple compile branches into one behavior description.
- Distinguish wrapper methods from effective business methods:
  - wrapper methods can be summarized briefly
  - bottom-level methods should describe actual reads, writes, checks, calculations, and object mutations
- Keep file references dense enough for review:
  - every top-level `Procedure` bullet should have a file reference
  - every materially important child bullet should also keep its own file reference instead of relying on the parent bullet
- When a leaf node contains a loop, a multi-step initializer, or a miss-handling sequence, mirror the code order with sub-bullets so the document can be cross-checked line by line.
- For delegating wrapper methods, keep tracing until the document reaches the downstream implementation that does the real work; do not stop merely because a method name sounds like a complete phase.
- If a conclusion is uncertain, state that the exact runtime behavior is unresolved instead of guessing.
- If code behavior looks suspicious (for example assignment in condition), record literal code behavior and avoid inferring author intent.
- Use `TODO` to list intentionally unexpanded branch families and deferred deep dives.
- Before delivering, compare `Summary`, `Involved tables`, `Entry`, and `Procedure` against `examples/83300100-DailyInstDirectNew.md` and close obvious detail gaps for the same kind of node.

## Output Rules

- Favor repository style over generic formatting.
- Keep the summary short. Spend most of the effort on the call chain and method behavior.
- Use exact function names, macro names, class names, and table names from code.
- Keep line references when available; they make review faster.
- If a leaf-node sentence could be reused for many methods, it is too generic; replace it with code-specific conditions, fields, keys, table names, or formulas.
- Avoid these failure modes:
  - dumping every transitive callee without prioritization
  - mixing assumptions into factual steps
  - listing broad tables with no evidence
  - describing a base-class implementation before confirming the actual dynamic type
  - hiding dispatch uncertainty instead of marking it

## Resource Map

- `references/search-playbook.md`
  Use for repository-specific discovery heuristics and common `rg` patterns.
- `references/annotation-rules.md`
  Use for deciding how to describe each node and how detailed a leaf method description should be.
- `references/cpp-reading-rules.md`
  Use for C++-specific interpretation rules: dynamic dispatch, ownership, RAII, constructors, and template-based dispatch.
- `assets/function-doc-template.md`
  Use as the default Markdown skeleton for new docs.
- `examples/83300100-DailyInstDirectNew.md`
  Use as the primary style example for table listing detail and Procedure granularity.
- `scripts/new_doc.py`
  Use to scaffold a new Markdown file from the template.

## Deliverable Checklist

- Confirm the target function number or entry function.
- Confirm the main call chain is represented in order.
- Confirm each important call has a behavior description.
- Confirm each `Procedure` node with DB access states operation type, key fields, and actual table name.
- Confirm each listed table, macro, and route decision is evidenced by code.
- Confirm `Involved tables` includes read-path tables as well as write-path tables for the documented flow.
- Confirm `Involved tables` entries are grouped by read/write and conditional entries include trigger reasons.
- Confirm each listed table has an evidence chain (`caller -> wrapper -> manager/record`) with file references.
- Confirm each listed macro or enum includes source and effective content, not just the symbol name.
- Confirm wrapper table names have been traced to the real table names.
- Confirm bottom-level methods are described more concretely than wrapper methods.
- Confirm each unexpanded leaf method includes branch condition, key field mutations, and key checks/calculations.
- Confirm multi-step leaf methods are expanded with ordered sub-bullets instead of one generic sentence.
- Confirm loops describe iteration object, per-item mutations, and per-item downstream calls when those details affect the flow.
- Confirm leaf details explicitly capture short-circuit/no-op behavior and miss-handling behavior where present.
- Confirm miss-then-init-then-requery flows include default-record field initialization and final miss failure behavior.
- Confirm amount/availability leaves include explicit comparison formula and operands.
- Confirm leaf-method detail is merged into `Procedure` nodes, not moved to a separate chapter.
- Confirm `Summary` and `TODO` are consistent with branch scope (expanded vs intentionally skipped).
- Confirm phase methods that delegate into utility/process classes have been traced down to the utility/process implementation.
- Confirm C++ dynamic dispatch targets are resolved before describing virtual method behavior.
- Confirm unresolved definitions have been searched globally before treating them as missing.
- Confirm conditional-compilation guards have been checked for the described path.
- Confirm active compile conditions were identified from build evidence; if unresolved, the analysis must pause and ask the user.
- Confirm every top-level `Procedure` node and materially important child node has its own file reference.
- Confirm the draft was compared against `examples/83300100-DailyInstDirectNew.md` and similar nodes are not materially thinner than the example.
- Confirm the final document matches nearby repository examples in tone and structure.
