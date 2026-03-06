# C++ Reading Rules

Use these rules when the call chain depends on C++ language behavior rather than plain textual call order.

## 1. Dynamic dispatch first

- If a call goes through a base-class pointer or reference, resolve the actual object type before describing the method body.
- Check:
  - factory methods
  - `new ChildType(...)`
  - assignments into member pointers
  - `virtual` declarations
  - `override` in child classes
- Do not describe the base implementation as actual runtime behavior unless the code proves that the base version executes.

## 2. Raw pointers do not automatically imply ownership

- In this codebase, raw pointers often mean:
  - borrowed parameter
  - cached record
  - alias to shared runtime state
  - temporary handle managed elsewhere
- Infer ownership only when code shows one of these:
  - `new` paired with deletion responsibility
  - destructor cleanup
  - smart pointer ownership
  - explicit ownership comments or factory contract
- When ownership is unclear, describe the pointer as a referenced object or member alias, not as an owned object.

## 3. Constructors, destructors, and init methods can contain business behavior

- Check constructors and `InitData`-style methods for:
  - member pointer binding
  - default values
  - table handle binding
  - platform handle binding
  - side effects that change later dispatch or calculation
- Check destructors and scoped helpers when they may:
  - release locks
  - flush buffered work
  - close handles
  - trigger cleanup behavior

## 4. RAII affects behavior at scope boundaries

- Objects such as lock guards, scoped transactions, or wrapper handles may perform important work when entering or leaving scope.
- If a scoped object changes locking, exception safety, or cleanup behavior, mention it in the description.
- Do not reduce RAII helpers to “just boilerplate” if they change what is protected or when resources are released.

## 5. Member state can determine later execution

- If one method stores data into a member pointer or member object, later calls may depend on that state.
- Track at least these assignments when relevant:
  - `m_xxx = ...`
  - `InitData(...)` assigning member pointers
  - cached route, market, or bsflag values
- When describing a later call, use the effective member state rather than only the formal parameter list.

## 6. Template and static polymorphism are different from virtual dispatch

- If a pattern looks like CRTP or template dispatch, the called implementation may be fixed at compile time.
- Do not search for a virtual override if the mechanism is template instantiation or `static_cast<Derived*>(this)`.
- Conversely, do not mistake virtual dispatch for template specialization.

## 7. Macros and inline methods can hide real control flow

- Legacy C++ code often hides behavior in:
  - function-like macros
  - inline methods in headers
  - header-only helper classes
- If a macro or inline wrapper affects control flow, exception handling, locking, or parameter unpacking, inspect its expansion target or body before summarizing it.

## 8. Conditional compilation changes the executable path

- Always inspect surrounding `#if`, `#ifdef`, `#ifndef`, `#elif`, `#else`, and `#endif` blocks before describing a method body.
- A method may have:
  - different implementations under different macros
  - a declaration in one branch and a definition in another
  - entire code paths compiled out
- Determine the active compile-time branch from repository `CMakeLists.txt` and included `.cmake` files first.
- Describe only the active branch in the main procedure; inactive branches can be skipped unless the user asks.
- Do not combine multiple compile-time branches into one single behavior description.
- If the active compile-time branch cannot be confirmed, stop and ask the user immediately before continuing the affected flow.

## 9. Missing local definitions may still exist elsewhere

- If a method definition is not found beside the declaration, do a repository-wide symbol search before concluding that it is external or missing.
- Check for:
  - out-of-line definitions in other translation units
  - macro-generated wrappers
  - exported C symbols
  - shared-library indirection
  - dynamically loaded symbols
- Only call a definition unresolved after broader search still fails.
- In this codebase, also check whether the call is routed through an internal shared library or exported wrapper before marking it unresolved.

## 9.5 Wrapper phases may hide the actual logic

- If a method mainly delegates to another object, treat it as a wrapper regardless of its name.
- When such a method immediately calls a utility manager, process manager, helper, adapter, service object, or tool object, continue tracing into that downstream method.
- Stop only after you reach the method that performs the real calculation, query, write, status update, or availability check.

## 10. Empty implementations matter

- Before describing a helper as meaningful behavior, check whether it is actually empty, defaulted, or only delegates.
- If a method is empty in the current class but virtual in the hierarchy, verify whether a child override is the actual executed body.

## 11. Good wording

Good:

- `m_lpInstrBusinessBase` is assigned a child business object selected by `bsflag`, and the subsequent `RunDirect(...)` call executes the child override.
- `InitData(...)` stores transaction pointers into member fields, so later utility calls read shared state from those members.

Bad:

- `RunDirect(...)` executes the base-class logic.
- `m_pStockParam` owns the stock object.
