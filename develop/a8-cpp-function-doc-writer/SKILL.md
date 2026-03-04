---
name: a8-cpp-function-doc-writer
description: Trace RTFA/A8 C and C++ trading code for a specific function number, entry function, or business flow and write structured Markdown documentation. Use when Codex needs to analyze .cpp/.cc/.cxx/.h/.hpp files, follow the main call chain, describe what each call does, identify involved tables and macros, resolve actual C++ dispatch targets, and produce or update function-level analysis docs with sections such as Involved tables, Procedure, and detailed bottom-level method behavior.
---

# Function Doc Writer

Use this skill to produce function-level analysis documents for the RTFA/JSTP trading codebase.

Treat the output as an engineering analysis document, not a generic code summary. Use Chinese to write the document unless the user asks for a different language.

Do not judge whether a method should change. Focus on describing what the current code does.

## Quick Start

1. Find the target entry by function number, function name, or dispatch point.
2. Expand the main call chain first; do not exhaustively enumerate every branch.
3. Record concrete code references for each confirmed step.
4. For every call in the chain, describe what the callee does in the current flow.
5. For bottom-level methods that are not expanded further, describe the internal behavior in more detail.
6. Draft the document with the template in `assets/function-doc-template.md`.

Read `references/search-playbook.md` before doing code discovery. Read `references/annotation-rules.md` before writing method descriptions.
Read `references/cpp-reading-rules.md` when the flow depends on inheritance, raw pointers, constructors, destructors, RAII guards, templates, or macro-heavy wrappers.

Use `scripts/new_doc.py` to generate a new Markdown skeleton when the user wants a fresh document file.

## Workflow

### 1. Confirm the target

- Accept any of these as the starting anchor:
  - function number such as `83300100`
  - entry function such as `DailyInstDirectNew`
  - business flow label such as `OrderIns`
- If the user gives only a function number, search for dispatchers, exports, or handlers that mention it.
- If multiple candidates exist, choose the one that matches the surrounding business context and state the assumption.

### 2. Discover the entry and route points

- Start from high-signal code locations:
  - external interface or exported handler
  - dispatcher `switch` or route function
  - business manager and flow classes
  - parameter unpack and validation layers
- Capture the first stable path from entry to the main business execution point.
- Prefer the dominant path used in production over helper noise.
- If a method definition is not found near the declaration or call site, perform a broader repository search before concluding that the implementation is missing. Include declaration-only matches, exported symbols, wrapper macros, and shared-library usage clues.

### 3. Expand the main call chain

- Follow the call chain in execution order.
- Keep the chain shallow enough to stay readable. Expand a branch only when it affects:
  - business routing
  - account lookup
  - table reads or writes
  - amount, price, or availability checks
  - market-specific logic
  - actual runtime dispatch target
- For each call, add a short behavior description immediately after the file reference.
- When a method is not expanded further, describe its behavior in more detail than higher-level wrapper methods.
- Do not stop at phase wrappers such as `DoDirectBusinessHold()` orchestration methods if they immediately hand off to utility managers, process managers, or tool classes. Continue tracing into those utility/process classes until you reach the methods that perform the real checks, calculations, queries, or writes.
- Collapse repetitive or irrelevant branches into a short note such as `TODO: other bsflag branches not expanded`.

### 4. Identify data and rule dependencies

- Record only dependencies that are evidenced by code:
  - database tables and cache objects
  - config records
  - macros and enums
  - route decisions
  - key validations
- Do not infer a table solely from naming conventions. Require an explicit query, write, cache init, struct, or helper call that ties the table to the flow.
- When the code goes through wrappers such as `QueryXxx`, `InitCacheXxx`, or `writetable_xxx`, trace one level deeper to determine the actual table.
- When wrapper names are generic, keep tracing until the real table name is confirmed from a table struct, manager, key builder, or serialized table name such as `rtfa_instruction` or `rtfa_instructstock`.
- For `Involved macros / enums`, do not list names only. Include the source file and the effective macro content, enum value, or compile-time branch meaning that matters for the current flow.

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
- Keep bullet indentation stable and readable.
- Put file references inline using backticks in the document body if that matches existing project style.
- Describe behavior, not design intent.
- If a call is affected by conditional compilation, state the relevant compile-time condition before describing the branch body.
- Distinguish wrapper methods from effective business methods:
  - wrapper methods can be summarized briefly
  - bottom-level methods should describe actual reads, writes, checks, calculations, and object mutations
- For delegating phase methods, keep tracing until the document reaches the utility/process implementation that does the real work; do not stop at the phase method itself.
- If a conclusion is uncertain, state that the exact runtime behavior is unresolved instead of guessing.

## Output Rules

- Favor repository style over generic formatting.
- Keep the summary short. Spend most of the effort on the call chain and method behavior.
- Use exact function names, macro names, class names, and table names from code.
- Keep line references when available; they make review faster.
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
- `scripts/new_doc.py`
  Use to scaffold a new Markdown file from the template.

## Deliverable Checklist

- Confirm the target function number or entry function.
- Confirm the main call chain is represented in order.
- Confirm each important call has a behavior description.
- Confirm each listed table, macro, and route decision is evidenced by code.
- Confirm each listed macro or enum includes source and effective content, not just the symbol name.
- Confirm wrapper table names have been traced to the real table names.
- Confirm bottom-level methods are described more concretely than wrapper methods.
- Confirm phase methods that delegate into utility/process classes have been traced down to the utility/process implementation.
- Confirm C++ dynamic dispatch targets are resolved before describing virtual method behavior.
- Confirm unresolved definitions have been searched globally before treating them as missing.
- Confirm conditional-compilation guards have been checked for the described path.
- Confirm the final document matches nearby repository examples in tone and structure.
