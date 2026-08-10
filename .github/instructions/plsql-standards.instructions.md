---
applyTo: "**/*.sql"
description: "RSL EDP PL/SQL Coding Standards - applied when editing or reviewing Oracle PL/SQL scripts, packages, procedures, materialized views, and logical views"
---

# RSL EDP PL/SQL Coding Standards

> Source: RSL EDP PLSQL Coding Standards.docx  
> Scope: All Oracle PL/SQL code — packages, standalone procedures, materialized views, logical views.

---

## 1. General Guidelines

- Break complex logic into modular subprograms (separate procedures/functions).
- Use consistent naming for clarity and traceability (see Section 4).
- Always include robust exception handling (see Section 8).
- Comment thoughtfully — clarify intent, not just syntax.
- **Never use `SELECT *`**; always specify only the required columns.
- Use constants or configuration tables instead of hardcoding values directly in packages or procedures.
- Use global constants and global variables to promote consistency, reduce redundancy, and simplify maintenance.
- Use `%TYPE` to declare a variable with the same data type as a column in a table.

---

## 2. Scope

These guidelines apply to all developers writing PL/SQL code for Oracle-based applications or data workflows in EDP.

---

## 3. Naming Conventions

### 3.1 Header Comments — Remove Stale Dependencies

**Remove** any `Used DB Objects:` / `Dependencies:` lists from code header comments — they become outdated and mislead maintainers.

❌ Before:
```sql
-- Used DB Objects: vw_fct_claim_payment_detail_r, dim_grp_party_r
```
✅ After: (remove the line entirely)

---

### 3.2 Variable Naming — Global vs Local

**Global Variables** (shared across multiple procedures/functions within a package):
- Prefix with `g` to indicate global scope.
- Type indicators: `gv_` for VARCHAR2, `gn_` for NUMBER, `gt_` for TIMESTAMP.

**Local Variables** (used only within a single procedure or function):
- Prefix with `l` to indicate local scope.
- Type indicators: `lv_` for VARCHAR2, `ln_` for NUMBER, `lt_` for TIMESTAMP.

**Format**: `[scope][type]_[name]`
- Scope prefixes: `g` = global, `l` = local
- Type prefixes: `v` = varchar/char, `n` = number/integer, `t` = timestamp

**Best Practices**:
- Avoid using global variables unless necessary for sharing across procedures.
- Keep variable names descriptive yet concise.
- **Do NOT use `_r` suffix** for variables defined in packages — `_r` suffix is reserved for table column names.

---

### 3.3 Constants

Use the `CONSTANT` keyword for values that do not change:
```sql
lc_proc_name  CONSTANT VARCHAR2(100) := 'PROC_NAME';
lc_schema     CONSTANT VARCHAR2(30)  := 'EDP';
```

---

### 3.4 Integer Data Types

All count-related fields that store integer values should use `INTEGER`, not `NUMBER`:
```sql
ln_count  INTEGER := 0;   -- ✅
ln_count  NUMBER  := 0;   -- ❌ for count fields
```

---

### 3.5 %TYPE Usage

Declare variables that correspond to table columns using `%TYPE`:
```sql
-- ✅
lv_status  schema.table_name.column_name%TYPE;

-- ❌
lv_status  VARCHAR2(20);
```

---

## 4. Commenting Standards

- **Start each procedure, function, or block** with a purpose comment.
- Use inline comments `--` sparingly; only when truly clarifying.
- Block comments `/* ... */` should annotate non-trivial logic.
- **For any enhancement**: include a block comment with date, author, and change description.
- Avoid unnecessary or redundant comments.
- If someone modifies the code, they **must** add a comment at the beginning of the modified section with date, author, and description.
- **Remove duplicate messaging**: do not use consecutive logging/print statements — combine them.

---

## 5. Indentation & Formatting

- Use **2 spaces** per indentation level.
- Keep lines **≤ 100 characters** wide.
- Add blank lines between logical code blocks.
- Include `BEGIN...END` even for simple code units.

---

## 6. SQL Aliases

Always use the **`AS` keyword** when assigning aliases to column names and table names:
```sql
-- ✅
SELECT col1 AS alias1 FROM table1 AS t1
-- ❌
SELECT col1 alias1 FROM table1 t1
```

---

## 7. Performance Best Practices

- Use `FORALL` and `BULK COLLECT` for large UPDATE/DELETE operations only.
- For large datasets use direct-path INSERT: `INSERT /*+ APPEND */`.
- Index tables involved in frequent joins or filters.
- **Avoid `SELECT *`** in production code.
- Use appropriate and minimal data types to reduce memory and I/O overhead.
- **Avoid implicit data type conversions** in comparisons and joins:
  ```sql
  -- ✅ Use direct comparison (allows index usage)
  WHERE tableA.column1 = tableB.column1
  -- ❌ Avoid TO_CHAR/TO_NUMBER wrapping in join conditions
  WHERE TO_CHAR(tableA.column1) = tableB.column1
  ```
- Partition large tables to improve query performance.
- **Avoid unnecessary COMMITs inside loops** to reduce redo/undo overhead.
- Avoid excessive logging or debug output in production code.
- Include code modularization; avoid repetitive logic — rebuild as reusable procedures/functions.
- **Remove commented-out code** that is no longer required.
- Optimize SQL: evaluate `INNER JOIN` first, then `LEFT`/`RIGHT JOIN` as needed; use `EXPLAIN PLAN`.

---

## 8. Exception Handling

- **Mandatory**: handle specific exception types first (`NO_DATA_FOUND`, `TOO_MANY_ROWS`) before using `WHEN OTHERS` as a fallback.
- Log exceptions using a centralized logging procedure or table. Include procedure name, parameters, and error context.
- For new development, check with the lead if a logging mechanism exists — do not create duplicate logging objects.
- Use `RAISE_APPLICATION_ERROR` to return custom error messages to the calling environment from child procedures.
- Use `SQLCODE` and `SQLERRM` to capture and log error codes and messages.
- **Never use `WHEN OTHERS THEN NULL`** — it hides errors and makes debugging impossible.

Standard exception block pattern:
```sql
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    -- handle specific case
    RAISE_APPLICATION_ERROR(-20001, 'No data found: ' || SQLERRM);
  WHEN TOO_MANY_ROWS THEN
    RAISE_APPLICATION_ERROR(-20002, 'Too many rows: ' || SQLERRM);
  WHEN OTHERS THEN
    -- centralized logging
    pkg_log.log_error(lc_proc_name, SQLCODE, SQLERRM);
    RAISE_APPLICATION_ERROR(-20000, 'Unexpected error in ' || lc_proc_name || ': ' || SQLERRM);
END;
```

---

## 9. Testing & Validation

- Validate input parameters and expected output.
- Use realistic mock data for unit testing.
- Document boundary and edge cases in test coverage.
- Include a logging mechanism to capture execution details and errors during test runs.
- For RPT tables, add log to `SSL_PACKAGE_LOG_TABLE` / `RSLI_LOG`.

---

## 10. Violation Severity Reference

| Severity | Examples |
|----------|---------|
| **CRITICAL** | `WHEN OTHERS THEN NULL`, `SELECT *` in production, missing exception handling |
| **HIGH**     | Wrong variable naming convention, missing `RAISE_APPLICATION_ERROR`, no `SQLCODE`/`SQLERRM` |
| **MEDIUM**   | Missing purpose comment, stale dependency headers, no `AS` for aliases, hardcoded values |
| **LOW**      | Lines > 100 chars, indentation style, redundant comments, `_r` suffix on package variables |
