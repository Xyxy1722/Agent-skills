# Search Playbook

Use this file to find the entry point and the minimum set of code needed to write a function-level analysis document.

## 1. Find the target

If the user provides a function number:

```bash
rg -n "83300100|82006001|82002009" .
```

If the user provides a function name:

```bash
rg -n "DailyInstDirectNew|AresStockOrder|AtomInstrStkDirect" .
```

If the target may appear in declarations as well as definitions:

```bash
rg -n "^[A-Za-z_][A-Za-z0-9_:<>, *&]*DailyInstDirectNew\\s*\\(" .
```

If the definition is not found near the obvious files, broaden the search:

```bash
rg -n "\\bDailyInstDirectNew\\b" .
rg -n "extern \\\"C\\\"|EXPORT|IMPORT|__attribute__\\s*\\(\\(visibility|dlopen|dlsym|LoadLibrary|GetProcAddress|\\.so" .
```

Use the second search to detect cases where the call target may live behind:

- declaration-only headers
- exported symbols
- shared-library wrappers
- dynamic loading
- macro-generated declarations

If the codebase calls into an internal `.so` and a definition is not found locally, broaden the search before calling it unresolved:

```bash
rg -n "\\.so|dlopen|dlsym|LoadLibrary|GetProcAddress|extern \\\"C\\\"|EXPORT|IMPORT" .
rg -n "\\bTargetMethodName\\b" /path/to/related/modules /path/to/shared-libs/source
```

Search across sibling modules, exported wrappers, and library entry points, not just the current subdirectory.

## 2. Locate dispatch and route points

Prefer these searches early:

```bash
rg -n "switch|case .*83300100|GetBusinessRoute|RunBusiness|CallJstpx|RunDirectByMktcode" .
rg -n "BUS_FLAG_|MARKET_|JSTP_|STRUCTAtomRaiseException" .
```

These usually reveal:

- the external entry
- the business route split
- the market-specific branch
- the major flow class

## 2.5 Resolve actual C++ dispatch targets

When a call goes through a parent-class pointer or reference, do not read only the parent method.

Search for the assignment or factory first:

```bash
rg -n "CreateInstance\\(|new [A-Za-z_][A-Za-z0-9_]*\\(|= .*CreateInstance\\(" .
rg -n "virtual .*Run|override|public .*Base|: public" .
```

Typical workflow:

- find where the pointer or reference is assigned
- identify the actual child type selected in the current branch
- inspect the child implementation of the virtual method
- only fall back to the base implementation if the code proves that the base version executes

Typical examples in this codebase:

- `m_lpInstrBusinessBase = CreateInstance(...)`
- then `m_lpInstrBusinessBase->RunDirect(...)`
- actual behavior depends on which child class `CreateInstance(...)` returns

## 2.6 Check lifecycle and ownership cues

When behavior depends on stored members or scope guards, search for:

```bash
rg -n "InitData\\(|~[A-Za-z_][A-Za-z0-9_]*\\(|new [A-Za-z_][A-Za-z0-9_]*\\(|delete |lock_guard|unique_lock|scoped_lock|JSTP_LOCK_|TRY|CATCH" .
rg -n "m_[A-Za-z0-9_]+\\s*=\\s*|this->m_[A-Za-z0-9_]+\\s*=\\s*" .
```

These usually reveal:

- member binding that controls later calls
- object lifetime and cleanup behavior
- RAII-based lock or resource scope
- whether a raw pointer is borrowed or owned

## 2.7 Check conditional compilation first

Before trusting a local definition, inspect surrounding compile-time guards:

```bash
rg -n "^\\s*#\\s*(if|ifdef|ifndef|elif|else|endif)\\b|defined\\s*\\(" .
```

When a target method or branch is inside conditional compilation:

- inspect the surrounding `#if/#ifdef/#elif/#else/#endif` block
- record the controlling macro names
- avoid merging multiple compile-time branches into one runtime description
- if the active build condition is unknown, say which alternative branches exist

## 3. Find table access

Search for wrappers first, then one level deeper for the concrete table:

```bash
rg -n "Query[A-Za-z]+\\(|InitCache[A-Za-z]+\\(|writetable_[A-Za-z_]+\\(" .
rg -n "rtcm_|rtfa_|mem_" .
```

Common patterns in this codebase:

- `QueryStock` or `InitCacheStock` -> stock master data
- `QuerySecuid` or `InitCacheSecuid` -> account/security mapping
- `QueryBsconfig` or `InitCacheBsconfig` -> business configuration
- `QueryFund`, `QueryFundctrl`, `QueryAvlctrlmodel` -> fund and availability controls
- `writetable_...` -> persistent writes

When the wrapper name is generic, verify the actual table from:

- concrete table structs such as `CRtfa_instruction`
- serializers or send-table code that compares explicit table names

## 4. Find validation and amount logic

Use focused searches when the document needs check rules or amount calculations:

```bash
rg -n "Check|Valid|Avail|available|GetRealprice|GetAmtInstrqty|ConvertClearspeed" .
```

Pay special attention to:

- account resolution
- product, project, and secuid lookup
- market checks
- price and quantity calculation
- fund and holding availability checks
- process-manager or utility-manager handoff methods that hide the real leaf logic

## 5. Keep the main path readable

Expand a branch only if it changes:

- route selection
- account or market behavior
- database access
- amount or risk calculations
- write-back side effects

Summarize the rest with a short note instead of enumerating every helper.

## 6. Verify findings before writing conclusions

Before writing a concrete behavior description, verify:

- the branch is actually reachable for the target market or bsflag
- the wrapper resolves to the table or cache you listed
- the called method is not an empty implementation
- the current document is describing behavior, not intent
- the dynamic type is resolved when the call is virtual
- constructor, destructor, init, or RAII side effects are not being ignored
- compile-time guards around the described branch are not being ignored
- local definition misses have been checked with a global search
