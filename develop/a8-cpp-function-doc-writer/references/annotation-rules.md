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

Example:

- `InitSysconfigBase(...)` reads the first `rtcm_sysconfig` record and checks whether `run_status` is `'0'`; otherwise it reports that the trading system is unavailable.

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

If a helper uses a generic wrapper name such as `writetable_instruction`, do not stop there. Trace one level deeper until the actual table name is confirmed from:

- a concrete table struct such as `CRtfa_instruction`
- a table key string such as `rtfa_instruction.xxx`
- a manager, serializer, or explicit table-name comparison

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
- utility/process methods that do the real work behind phase methods such as `DoDirectBusinessHold()` or `DealDirectData()`

Do not expand:

- obvious boilerplate
- macros with no impact on behavior
- repeated init calls that do not alter conclusions

## Wording rules

- Use exact identifiers from code.
- Use short sentences for wrapper methods.
- Use more detail for bottom-level methods.
- Use `dispatch unresolved` or `not expanded` instead of guessing.
