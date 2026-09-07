# PeoplesHR SQL Standards

**Conventions & Standards for SQL Scripts (SQL Server / T-SQL)**

## Document Control

| Field                | Value                                             |
| -------------------- | ------------------------------------------------- |
| **Owner**            | Chinthaka Nayomal                                 |
| **Version**          | 2.0.0                                             |
| **Effective Date**   | TBD                                               |
| **Review Frequency** | Annually, or whenever a significant change occurs |
| **Document Name**    | PeoplesHR SQL Standards                           |
| **Document ID**      | TBD                                               |
| **Classification**   | Internal                                          |

**Version History**

| Version | Prepared by            | Reviewed by       | Authorized by     | Date       | Description                                                                                                                                                                                                  |
| ------- | ---------------------- | ----------------- | ----------------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1.0.0   | Naveen Warnakulasuriya | Chinthaka Nayomal | Chinthaka Nayomal | 2025-03-05 | Initial policy document                                                                                                                                                                                      |
| 1.1.0   | Chinthaka Nayomal      |                   |                   | 2026-11-06 | Added performance, security, and naming detail                                                                                                                                                               |
| 2.0.0   | Ayub Sourjah           |                   |                   | TBD        | Full restructure: deduplicated content, resolved naming-convention conflict (standardized on `snake_case`), added MUST/SHOULD/MAY enforcement levels, split core standards from deep-dive reference material |

---

## Table of Contents

1. [Purpose & Scope](#1-purpose--scope)
2. [How to Use This Document](#2-how-to-use-this-document)
3. [Definitions & Acronyms](#3-definitions--acronyms)
4. [Naming Conventions](#4-naming-conventions)
5. [Formatting & Style](#5-formatting--style)
6. [Query Structure & Joins](#6-query-structure--joins)
7. [Aggregation & Grouping](#7-aggregation--grouping)
8. [Data Types & Casting](#8-data-types--casting)
9. [Performance & Indexing](#9-performance--indexing)
10. [Transactions & Concurrency](#10-transactions--concurrency)
11. [Error Handling](#11-error-handling)
12. [Security](#12-security)
13. [Comments & Documentation](#13-comments--documentation)
14. [Stored Procedures & Functions](#14-stored-procedures--functions)
15. [Version Control & Migration Management](#15-version-control--migration-management)
16. [Testing & Validation](#16-testing--validation)
17. [Responsibilities](#17-responsibilities)
- [Appendix A: Performance Deep-Dive Reference](#appendix-a-performance-deep-dive-reference)
- [Appendix B: Quick-Reference Checklist (for Code Review & AI Agents)](#appendix-b-quick-reference-checklist-for-code-review--ai-agents)
- [Appendix C: ER Diagram Module Groups](#appendix-c-er-diagram-module-groups)
- [Appendix D: Acronyms](#appendix-d-acronyms)

---

## 1. Purpose & Scope

Every language and product platform accumulates conventions beyond generic best practice — limitations or quality bars specific to how the product is built and run. This document is that layer for SQL at PeoplesHR/hSenid: it defines how T-SQL (SQL Server) is written, named, structured, and reviewed across all product modules.

**Applies to:** all development teams and implementation engineers writing or publishing SQL scripts against PeoplesHR databases — application queries, stored procedures, functions, views, and migration scripts.

**Enforcement:** SQL scripts pushed to the Azure SQL script repository are reviewed by the DBA team against this standard before merge.

This document is also written to be consumed by AI coding agents performing code generation or code review. Rules are tagged with an explicit enforcement level and a stable ID (see [Section 2](#2-how-to-use-this-document) and [Appendix B](#appendix-b-quick-reference-checklist-for-code-review--ai-agents)) so both humans and agents can distinguish a hard blocker from a judgment call.

## 2. How to Use This Document

Every rule is tagged with one of three enforcement levels, per [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt) convention:

| Tag          | Meaning                                                                                                                 |
| ------------ | ----------------------------------------------------------------------------------------------------------------------- |
| **[MUST]**   | Non-negotiable. A violation should block PR approval / DBA sign-off.                                                    |
| **[SHOULD]** | Strong default. Deviating is acceptable only with a documented reason (see §13.7 — document deviations from standards). |
| **[MAY]**    | A judgment call or optional technique — use it when it fits the situation.                                              |

Each rule also carries a short ID (e.g. `NC-01`) so it can be referenced in code review comments and in [Appendix B](#appendix-b-quick-reference-checklist-for-code-review--ai-agents). Deep implementation detail that isn't itself a standard (how to read an execution plan, DMV queries, parameter-sniffing fixes) lives in [Appendix A](#appendix-a-performance-deep-dive-reference) so the core standard stays scannable.

Code examples use fenced ```sql blocks throughout. Where a "Bad" example is shown, the "Good" example immediately after it is the required fix.

## 3. Definitions & Acronyms

See [Appendix D](#appendix-d-acronyms) for the full acronym table.

## 4. Naming Conventions

**Casing standard:** PeoplesHR SQL objects use **`snake_case`** — lowercase words separated by underscores — for every identifier: tables, views, columns, stored procedures, functions, parameters, and variables. This applies uniformly; there is no PascalCase exception anywhere in the schema or in T-SQL code.

### 4.1 Object Naming (Tables, Views, Functions, Procedures)

- **[MUST] `NC-01`** Object names are singular, not plural. `employee_master` is correct; `employee_masters` is not. This is a standard relational convention, not a PeoplesHR-specific one.
- **[MUST] `NC-02`** Tables and views include a module-alias prefix identifying the owning module, e.g. the off-boarding module uses `ofb_`, giving names like `ofb_exit_request`.
- **[MUST] `NC-03`** Functions are prefixed `fn_<module>_`, e.g. `fn_ofb_calculate_notice_period`.
- **[MUST] `NC-04`** Stored procedures are prefixed `usp_<module>_`, e.g. `usp_ofb_process_exit`. Never use the bare `sp_` prefix — SQL Server checks the master database first for anything named `sp_*`, adding lookup overhead, and it visually collides with system procedures.
- **[MUST] `NC-05`** Client- or localization-specific scripts carry an additional suffix identifying the client or locale, appended after the module alias, e.g. `ofb_smb_` for a Sampath Bank-specific object, or `ofb_phil_` for a Philippines-localization object. This lets any developer identify scope from the object name alone.

```sql
-- Good
CREATE TABLE ofb_exit_request ( ... );
CREATE FUNCTION fn_ofb_calculate_notice_period ( ... );
CREATE PROCEDURE usp_ofb_process_exit ( ... );
CREATE TABLE ofb_smb_exit_checklist ( ... );   -- Sampath Bank–specific
CREATE TABLE ofb_phil_exit_checklist ( ... );  -- Philippines localization
```

### 4.2 Column Naming

- **[MUST] `NC-06`** Columns use `snake_case`, e.g. `department_code`, `hire_date`.
- **[MUST] `NC-07`** Never use bare, single-word generic identifiers as a column name. Prefix with the entity/business concept it belongs to. This avoids ambiguity once a column is seen out of table context (in a join result, a log, or a report) and prevents name collisions across joined tables.

| Category       | Avoid (generic)                                                         | Use instead                                                                                                                                                 | Example                                                                    |
| -------------- | ----------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| Identity/key   | `id`, `code`, `key`, `no`, `number`, `ref`, `reference`, `guid`, `uuid` | `<entity>_id`, `<entity>_code`, `<entity>_key`, `<entity>_no`, `<entity>_number`, `<entity>_ref`, `<entity>_reference_no`, `<entity>_guid`, `<entity>_uuid` | `employee_id`, `department_code`, `invoice_no`, `payment_ref`              |
| Status/state   | `status`, `state`, `flag`                                               | `<entity>_status_code`                                                                                                                                      | `employee_status_code`, `approval_status_code`                             |
| Type/category  | `type`, `category`, `class`, `group`, `kind`                            | `<entity>_type_code`, `<entity>_category_code`, `<entity>_class_code`, `<entity>_group_code`, `<entity>_kind_code`                                          | `leave_type_code`, `pay_group_code`                                        |
| Date/time      | `date`, `time`, `datetime`, `created`, `updated`, `modified`            | `<purpose>_date`, `<purpose>_time`, `created_date_time` / `created_by`, etc. (see §4.4 for the UTC-specific rule)                                           | `effective_date`, `termination_date`                                       |
| User/audit     | `user`, `created_by`, `updated_by`, `modified_by`                       | `<purpose>_user_id`, `created_by_user_id`, `updated_by_user_id`, `modified_by_user_id`                                                                      | `created_by_user_id`, `approved_by_user_id`                                |
| Value/amount   | `value`, `amount`, `total`, `sum`, `count`, `data`                      | `<entity>_value`, `<entity>_amount`, `<entity>_total_amount`, `<entity>_sum_amount`, `<entity>_count`                                                       | `gross_salary_amount`, `net_pay_amount`, `leave_balance_days`              |
| Relational     | `parent_id`, `child_id`                                                 | the actual business relationship name                                                                                                                       | `manager_employee_id`, `reporting_employee_id`, `assigned_location_id`     |
| System/generic | `record`, `entity`, `object`, `item`, `detail`, `info`, `data`          | the actual business noun                                                                                                                                    | `employee_detail`, `payroll_transaction`, `order_item`, `employee_contact` |

```sql
-- Bad
SELECT id, status, amount FROM payroll_transaction;

-- Good
SELECT employee_id, employee_status_code, net_pay_amount FROM payroll_transaction;
```

### 4.3 Boolean / Indicator Columns

- **[MUST] `NC-08`** Boolean/flag columns are named `is_<predicate>_ind` and are typed `BIT`. Use this consistently instead of ad hoc `*_flag` or `*_indicator` names.

| Avoid              | Use instead        | Meaning                |
| ------------------ | ------------------ | ---------------------- |
| `active_flag`      | `is_active_ind`    | Record is active       |
| `delete_flag`      | `is_deleted_ind`   | Record is soft-deleted |
| `approved_flag`    | `is_approved_ind`  | Record is approved     |
| `status_indicator` | `is_enabled_ind`   | Feature is enabled     |
| `yes_no_flag`      | `is_mandatory_ind` | Value is mandatory     |

### 4.4 Date & Time Columns

- **[MUST] `NC-09`** Every column storing a UTC date/time value is suffixed `_utc` — e.g. `created_at_utc`, `approved_utc`, `login_utc`. This removes ambiguity across time zones and simplifies integrations and reporting. See §8.4 for the accompanying data-type rule (`DATETIME2`).
- **[MUST] `NC-10`** Never use an ambiguous name like `created_date`, `created_time`, or `created_datetime` for a value that is actually stored in UTC — it must carry the `_utc` suffix instead.
- **[MUST] `NC-11`** Do not apply `_utc` to a column that intentionally stores local/non-UTC time (see §8.4's `DATETIMEOFFSET` exception).
- **[SHOULD] `NC-12`** Date-only (no time component) purpose-named columns use `<purpose>_date`, e.g. `effective_date`, `termination_date`.

## 5. Formatting & Style

### 5.1 Casing

- **[MUST] `FMT-01`** SQL keywords (`SELECT`, `FROM`, `WHERE`, `JOIN`, `AND`, `OR`, `GROUP BY`, `ORDER BY`) and built-in functions (`COUNT`, `SUM`, `GETDATE`, `ISNULL`) are UPPERCASE.
- **[MUST] `FMT-02`** Identifiers (tables, columns, aliases) are `snake_case`, per §4.

```sql
-- Bad
select employeeid, firstname from employee where isactiveflag = 1;

-- Good
SELECT
    employee_id
    , first_name
FROM employee
WHERE is_active_ind = 1;
```

### 5.2 Indentation & Line Breaks

- **[MUST] `FMT-03`** Indent with 4 spaces, never tabs, to avoid misalignment across editors.
- **[MUST] `FMT-04`** Each major clause (`SELECT`, `FROM`, `WHERE`, `GROUP BY`, `ORDER BY`, each `JOIN`) starts on its own line.
- **[SHOULD] `FMT-05`** Use one column per line in the `SELECT` list once there are more than 2–3 columns.
- **[SHOULD] `FMT-06`** Break long `AND`/`OR` chains onto separate lines, with the logical operator leading the new line.

```sql
-- Bad
SELECT employee_id, first_name, last_name, department_code, hire_date FROM employee WHERE is_active_ind = 1 AND department_code = 'HR' AND hire_date >= '2024-01-01';

-- Good
SELECT
    employee_id
    , first_name
    , last_name
    , department_code
    , hire_date
FROM employee
WHERE is_active_ind = 1
    AND department_code = 'HR'
    AND hire_date >= '2024-01-01';
```

### 5.3 Comma Placement

- **[SHOULD] `FMT-07`** Use leading commas (comma at the start of the next line) — this produces cleaner diffs in version control, since adding/removing a column only touches one line.

### 5.4 JOIN Formatting & Aliasing

- **[MUST] `FMT-08`** Each `JOIN` is on its own line, with its `ON` condition indented on the following line.
- **[MUST] `FMT-09`** Always alias tables once more than one table is in scope, using a short, meaningful, consistent alias (e.g. always `e` for `employee`, always `d` for `department`) applied the same way across the codebase.

```sql
-- Good
SELECT
    e.employee_id
    , d.department_name
FROM employee e
INNER JOIN department d
    ON e.department_code = d.department_code;
```

### 5.5 Operators, Parentheses, Semicolons

- **[MUST] `FMT-10`** Use a single space around operators (`=`, `<`, `>`, `+`, etc.).
- **[MUST] `FMT-11`** Use parentheses to make operator precedence explicit whenever `AND`/`OR` are mixed, even when not strictly required by precedence rules — see §6.3.
- **[MUST] `FMT-12`** Terminate every statement with a semicolon. Some statements (`THROW`, CTEs) require it, and it keeps parsing/readability consistent everywhere else.

```sql
-- Bad
WHERE salary>50000 AND (bonus_amount+salary)<100000

-- Good
WHERE salary > 50000
    AND (bonus_amount + salary) < 100000;
```

### 5.6 Subqueries & CTEs

- **[MUST] `FMT-13`** Indent subqueries one level deeper than their parent statement.
- **[SHOULD] `FMT-14`** Prefer CTEs (`WITH`) over deeply nested subqueries for readability.

```sql
WITH active_employee AS
(
    SELECT
        employee_id
        , department_code
    FROM employee
    WHERE is_active_ind = 1
)
SELECT
    ae.employee_id
    , d.department_name
FROM active_employee ae
INNER JOIN department d
    ON ae.department_code = d.department_code;
```

## 6. Query Structure & Joins

### 6.1 SELECT Lists & Column Qualification

- **[MUST] `QRY-01`** Never use `SELECT *` in application code, views, or stored procedures — always name columns explicitly. An unbounded column list breaks callers silently when the underlying table changes shape, and it defeats covering indexes (§9).
- **[MUST] `QRY-02`** Once a query involves more than one table, every column reference must be qualified with its table alias — even if currently unambiguous — so a later column addition on another joined table can't silently break the query.
- **[SHOULD] `QRY-03`** Alias computed/expression columns clearly with `AS`.

```sql
-- Bad
SELECT * FROM employee;

SELECT employee_id, department_name
FROM employee e
INNER JOIN department d ON e.department_code = d.department_code;

-- Good
SELECT
    e.employee_id
    , e.first_name + ' ' + e.last_name AS full_name
    , d.department_name
FROM employee e
INNER JOIN department d
    ON e.department_code = d.department_code;
```

### 6.2 Joins

- **[MUST] `QRY-04`** Use explicit ANSI join syntax (`INNER JOIN` / `LEFT JOIN` / `FULL JOIN`) only. Comma-separated tables in `FROM` with the join condition in `WHERE` are banned — a missing `WHERE` condition silently produces a cartesian product, and it's harder to catch in review than a join with no `ON`.
- **[MUST] `QRY-05`** Always state the join type explicitly (`INNER JOIN`, not bare `JOIN`) so intent is unambiguous.
- **[MUST] `QRY-06`** Every `JOIN` must have an `ON` clause. A join without one silently produces a cartesian product — flag it in code review with no exceptions.
- **[MUST] `QRY-07`** Avoid `RIGHT JOIN` entirely; rewrite as a `LEFT JOIN` by swapping table order, so every developer only has to reason about one outer-join direction.
- **[SHOULD] `QRY-08`** Avoid `FULL JOIN` unless the business requirement genuinely needs unmatched rows from both sides (e.g. a reconciliation report) — document why when used (§13.7).
- **[SHOULD] `QRY-09`** Start `FROM` with the primary/driving table — the one the query is conceptually about — and add joins in the order data logically depends on them, so the query reads top-down like a story. This is purely for human readability: join order in `FROM` does not affect the optimizer's chosen execution plan.
- **[MUST] `QRY-10`** When joining a one-to-many relationship and then aggregating, verify the join isn't silently multiplying rows before the aggregate runs (**fan-out**). Aggregate each one-to-many relationship independently in a CTE/subquery first if there's any doubt, then join the pre-aggregated results.
- **[MUST] `QRY-11`** Join columns must be indexed on both sides and match in data type/length exactly — a type mismatch on a join key forces an implicit conversion and a scan on the larger table (see §9.3).

```sql
-- Bad — fan-out: joining two one-to-many tables before aggregating overcounts
SELECT
    e.employee_id
    , SUM(p.salary_amount) AS total_salary
FROM employee e
INNER JOIN pay_history p ON e.employee_id = p.employee_id
INNER JOIN leave_request l ON e.employee_id = l.employee_id
GROUP BY e.employee_id;

-- Good — aggregate each one-to-many relationship separately, then join the results
SELECT
    e.employee_id
    , ph.total_salary
    , lr.leave_count
FROM employee e
INNER JOIN (
    SELECT employee_id, SUM(salary_amount) AS total_salary
    FROM pay_history
    GROUP BY employee_id
) ph ON e.employee_id = ph.employee_id
INNER JOIN (
    SELECT employee_id, COUNT(*) AS leave_count
    FROM leave_request
    GROUP BY employee_id
) lr ON e.employee_id = lr.employee_id;
```

**Filter placement changes join semantics — be deliberate (`QRY-12`, [MUST]):** for a `LEFT JOIN`, a filter on the joined (right) table belongs in the `ON` clause if unmatched left rows should still be returned; it belongs in `WHERE` only if it should exclude them entirely (this effectively turns the outer join into an inner join).

```sql
-- Keeps all employees; only restricts which department rows match
FROM employee e
LEFT JOIN department d
    ON e.department_code = d.department_code
    AND d.region_code = 'APAC';

-- Excludes employees with no APAC-region department match at all
FROM employee e
LEFT JOIN department d
    ON e.department_code = d.department_code
WHERE d.region_code = 'APAC';
```

### 6.3 WHERE Clause Organization

- **[MUST] `QRY-13`** Group related `AND`/`OR` conditions with parentheses so precedence is explicit, never implicit (duplicate of `FMT-11`, restated here because it's most often violated in `WHERE`).
- **[SHOULD] `QRY-14`** One condition per line, with the logical operator leading the line. Put the most selective condition first for human readability (the optimizer doesn't care about order).

```sql
-- Bad — ambiguous precedence
WHERE department_code = 'HR' OR department_code = 'IT' AND is_active_ind = 1

-- Good — explicit precedence
WHERE (department_code = 'HR' OR department_code = 'IT')
    AND is_active_ind = 1
```

### 6.4 NULL Handling

- **[MUST] `QRY-15`** Never use `= NULL` or `<> NULL` — both always evaluate to `UNKNOWN` and silently return zero rows with no error. Always use `IS NULL` / `IS NOT NULL`.
- **[MUST] `QRY-16`** Remember `NULL = NULL` is `UNKNOWN`, not `TRUE`, when comparing two nullable columns. If two `NULL`s should be treated as equal, write that explicitly.
- **[SHOULD] `QRY-17`** Use `ISNULL()` / `COALESCE()` explicitly when a default is needed for `NULL`s, rather than relying on implicit behavior. Be deliberate about `COUNT(*)` (all rows) vs `COUNT(column)` (non-`NULL` only) — see §7.5.
- **[MUST] `QRY-18`** `NOT IN` is dangerous against a subquery that can return `NULL` — a single `NULL` in the subquery result silently makes the entire `NOT IN` return zero rows. Use `NOT EXISTS` instead, which is `NULL`-safe.

```sql
-- Bad — returns zero rows if manager_id contains any NULL
WHERE employee_id NOT IN (SELECT manager_id FROM employee)

-- Good
WHERE NOT EXISTS (
    SELECT 1 FROM employee m WHERE m.manager_id = employee.employee_id
);
```

### 6.5 IN / OR / BETWEEN

- **[SHOULD] `QRY-19`** Prefer `IN (...)` over chained `OR` on the same column, for readability and consistent index usage.
- **[SHOULD] `QRY-20`** Prefer `BETWEEN` (or an explicit range comparison) over `OR`-chained range checks — `BETWEEN` is inclusive on both ends, so confirm that matches the business rule.
- **[SHOULD] `QRY-21`** Avoid `OR` across *different* columns where possible — it often prevents efficient index use. Consider `UNION ALL` of two seekable queries instead (see §9).

```sql
-- Bad
WHERE department_code = 'HR' OR department_code = 'IT' OR department_code = 'FIN'

-- Good
WHERE department_code IN ('HR', 'IT', 'FIN')
```

## 7. Aggregation & Grouping

- **[MUST] `AGG-01`** Every non-aggregated column in the `SELECT` list must appear in `GROUP BY`. Don't rely on database-specific leniency — write it explicitly.
- **[MUST] `AGG-02`** Filter rows in `WHERE` before grouping; reserve `HAVING` strictly for conditions on the aggregate result itself. A row-level condition placed in `HAVING` forces the engine to aggregate rows that could have been excluded earlier.
- **[SHOULD] `AGG-03`** If a query only needs distinct values with no aggregate function, use `SELECT DISTINCT`, not a purposeless `GROUP BY` — it states intent clearly and can be more efficient.
- **[MUST] `AGG-04`** When joining a one-to-many relationship and then aggregating, pre-aggregate each one-to-many table independently before joining (fan-out — see `QRY-10`, the same rule restated in the grouping context since it's a very common source of silently-wrong totals).
- **[MUST] `AGG-05`** Choose `COUNT(*)` (all rows, including `NULL`s), `COUNT(column)` (non-`NULL` values only), or `COUNT(DISTINCT column)` (unique non-`NULL` values) deliberately based on what's being measured — don't default to `COUNT(*)` out of habit.
- **[SHOULD] `AGG-06`** Don't add extra `GROUP BY` columns "just in case" — every extra grouping column silently changes result granularity.
- **[SHOULD] `AGG-07`** When an aggregate value is needed alongside non-aggregated detail rows (not collapsed), use a window function (`OVER (PARTITION BY ...)`) instead of a correlated subquery — simpler and normally faster, since the subquery form re-executes per outer row.
- **[MUST] `AGG-08`** `GROUP BY` treats all `NULL`s in a column as a single group. If `NULL`s should be excluded or labeled distinctly, handle that explicitly (e.g. `ISNULL(department_code, 'UNASSIGNED')`).
- **[SHOULD] `AGG-09`** Remember SQL Server's logical processing order — `FROM → WHERE → GROUP BY → HAVING → SELECT → ORDER BY`. A `SELECT`-list alias cannot be referenced in `WHERE` or `GROUP BY` because those clauses are logically evaluated first; group by the underlying expression instead.

```sql
-- Bad — row-level filter placed in HAVING, forces unnecessary aggregation of excluded rows
SELECT department_code, COUNT(*) AS employee_count
FROM employee
GROUP BY department_code
HAVING department_code = 'HR' AND COUNT(*) > 5;

-- Good — row filter in WHERE, aggregate filter in HAVING
SELECT department_code, COUNT(*) AS employee_count
FROM employee
WHERE department_code = 'HR'
GROUP BY department_code
HAVING COUNT(*) > 5;
```

```sql
-- Window function instead of a correlated subquery
SELECT
    e.employee_id
    , e.department_code
    , e.salary_amount
    , AVG(e.salary_amount) OVER (PARTITION BY e.department_code) AS dept_avg_salary
FROM employee e;
```

## 8. Data Types & Casting

### 8.1 Matching Types

- **[MUST] `DTY-01`** Parameter and variable types must match the column's data type, length, and precision exactly. A mismatch forces an implicit conversion — typically on the column side — which blocks index seeks (see §9.4).
- **[MUST] `DTY-02`** Never mix `VARCHAR` and `NVARCHAR` for the same logical value; standardize on one type per column/domain across the schema (see §8.5 for which one).
- **[MUST] `DTY-03`** The same logical column (e.g. `employee_id` as a foreign key) must use the identical type everywhere it appears across related tables — inconsistent types force a conversion on every join.
- **[MUST] `DTY-04`** Never convert on the column side of a predicate (`WHERE CONVERT(...) = @value`) — convert the literal/parameter side instead. This is the single most common cause of an accidental table scan (see §9.4).
- **[SHOULD] `DTY-05`** Prefer `CAST` over `CONVERT` for straightforward conversions — it's ANSI-standard and more portable. Use `CONVERT` only when its style parameter is needed (e.g. specific date formatting).

```sql
-- Bad — column is VARCHAR(20), variable is NVARCHAR: implicit conversion, blocks index seek
DECLARE @department_code NVARCHAR(20) = N'HR001';
SELECT * FROM employee WHERE department_code = @department_code;

-- Good
DECLARE @department_code VARCHAR(20) = 'HR001';
SELECT * FROM employee WHERE department_code = @department_code;
```

### 8.2 Sizing

- **[MUST] `DTY-06`** Use the smallest numeric type that safely covers the realistic data range — don't default to `BIGINT` or `DECIMAL(38,10)` "just in case." Oversized types waste storage, memory, and index space.
- **[SHOULD] `DTY-07`** Size string columns to a realistic maximum. Only use `VARCHAR(MAX)`/`NVARCHAR(MAX)` when content is genuinely unbounded (free-text notes, JSON payloads) — unbounded types can prevent certain index usage.
- **[MUST] `DTY-08`** Foreign key columns must match the parent column's data type and length exactly. A mismatch (e.g. parent `VARCHAR(200)` vs. child `VARCHAR(400)`) is a real deployment-time failure mode, not just a style nit — reconcile it before the constraint is added, not after.

### 8.3 Money

- **[MUST] `DTY-09`** Use `DECIMAL`/`NUMERIC` for all currency values, sized to realistic precision (e.g. `DECIMAL(12,2)`). Never use `FLOAT`/`REAL` for money — they are approximate types and introduce rounding errors in financial calculations.

### 8.4 Date & Time Types

- **[MUST] `DTY-10`** All date/time columns use `DATETIME2` by default. The legacy `DATETIME` type must not be used in new development — `DATETIME2` has a larger range, higher precision, better storage efficiency, and better ANSI/ISO compliance.
- **[MUST] `DTY-11`** Store all system-generated timestamps in UTC, in a `DATETIME2` column suffixed `_utc` (§4.4).
- **[SHOULD] `DTY-12`** Use `DATETIMEOFFSET` only when the application must preserve the original time-zone offset supplied by a user, external system, or a regulatory requirement — e.g. an employee self-service submission from a specific country, an audit record proving original local time, or an integration receiving timestamps from external systems across time zones. Do not suffix these columns `_utc`.

```sql
created_at_utc        DATETIME2       -- system-generated, always UTC
submission_datetime   DATETIMEOFFSET  -- must preserve the submitter's original offset
```

### 8.5 Unicode Strings

- **[MUST] `DTY-13`** Use `NVARCHAR` for all textual data intended to store user-entered, business, or multilingual text — names, descriptions, comments, addresses, messages, document references. This ensures full Unicode support (Sinhala, Tamil, Arabic, Chinese, Japanese, and other character sets) and prevents corruption.
- **[SHOULD] `DTY-14`** Avoid `VARCHAR` unless there is a specific, documented technical justification (see exception below).
- **[MAY] `DTY-15`** Primary-key columns using character-based identifiers may remain `VARCHAR` for legacy compatibility, external system integration, or storage optimization. Document the exception during design review.

| Column               | Recommended type                                 |
| -------------------- | ------------------------------------------------ |
| `employee_name`      | `NVARCHAR(200)`                                  |
| `address_line_1`     | `NVARCHAR(500)`                                  |
| `department_name`    | `NVARCHAR(200)`                                  |
| `remarks`            | `NVARCHAR(MAX)`                                  |
| `email_address`      | `NVARCHAR(320)`                                  |
| `employee_code` (PK) | `VARCHAR(20)` *(exception — legacy/integration)* |

### 8.6 Truncation Awareness

- **[MUST] `DTY-16`** Converting from a larger/more precise type to a smaller one (`DECIMAL(18,4)` → `DECIMAL(10,2)`, `NVARCHAR(100)` → `VARCHAR(50)`) can silently truncate or round data. Verify the target type can safely hold the source data, and make truncation an explicit, visible decision (e.g. `LEFT(notes, 50)`), never an implicit one.

## 9. Performance & Indexing

This section covers the **MUST/SHOULD**-level rules every engineer applies day to day. Execution-plan reading, DMV queries, parameter sniffing, partitioning, and batch/bulk operation detail are reference material, not daily rules — see [Appendix A](#appendix-a-performance-deep-dive-reference).

### 9.1 Sargability

A predicate is **sargable** when SQL Server can use an index seek to evaluate it. This is the single highest-leverage performance rule in this document.

- **[MUST] `PERF-01`** Never wrap an indexed column in a function, calculation, or conversion inside `WHERE`, `JOIN ... ON`, or `HAVING`. This includes `YEAR(col)`, `UPPER(col)`, `LTRIM(col)`, `ISNULL(col, x)`, `CONVERT(..., col)`, and arithmetic on the column (`col * 12 > x`). Rewrite as a range or move the operation to the constant/parameter side.

```sql
-- Bad — function on column blocks index seek
WHERE YEAR(hire_date) = 2024

-- Good — rewritten as a sargable range
WHERE hire_date >= '2024-01-01' AND hire_date < '2025-01-01'
```

```sql
-- Bad — arithmetic on the column side
WHERE salary_amount * 12 > 600000

-- Good — move the calculation to the constant side
WHERE salary_amount > 600000 / 12
```

- **[MUST] `PERF-02`** Avoid leading-wildcard `LIKE` (`LIKE '%value'`, `LIKE '%value%'`) — it cannot seek. A trailing wildcard (`LIKE 'John%'`) can still seek on the prefix. For genuine free-text search, use Full-Text Search (`CONTAINS`/`FREETEXT`) instead.

### 9.2 Selecting Only What's Needed

- **[MUST] `PERF-03`** Never use `SELECT *` (restated from `QRY-01` — it's a performance rule as much as a maintainability one: it prevents covering indexes from satisfying the query and pulls unnecessary I/O).
- **[SHOULD] `PERF-04`** For a frequent, performance-critical query, name only the columns actually needed so a covering index (with `INCLUDE`) can fully satisfy it without a key lookup back to the clustered index.

### 9.3 Existence, Set Operations, Negatives

- **[MUST] `PERF-05`** Use `IF EXISTS (SELECT 1 ...)` for existence checks, never `IF (SELECT COUNT(*) ...) > 0` — `EXISTS` stops at the first match instead of counting every row.
- **[SHOULD] `PERF-06`** Use `UNION ALL` instead of `UNION` when the result sets are known to be disjoint — plain `UNION` forces an implicit sort/dedupe pass that isn't needed.
- **[SHOULD] `PERF-07`** Prefer positive, rewritable logic over `<>`, `NOT IN`, `NOT LIKE`, `NOT EXISTS` where feasible — negatives are often non-sargable and force a scan.

```sql
-- Bad
IF (SELECT COUNT(*) FROM employee WHERE department_code = 'HR') > 0

-- Good
IF EXISTS (SELECT 1 FROM employee WHERE department_code = 'HR')
```

### 9.4 Implicit Conversions

- **[MUST] `PERF-08`** Match parameter/variable types to column types exactly (restated from `DTY-01` in the performance context — this is the most common accidental-scan cause in the codebase). Check the execution plan for a `CONVERT_IMPLICIT` warning on the seek/scan operator; that's the tell-tale sign.

### 9.5 Filtering Early

- **[MUST] `PERF-09`** Apply the most selective filters as early as possible — in a CTE/subquery before a join or aggregation — rather than filtering the full joined/aggregated result afterward.

```sql
-- Bad — joins the full table, then filters
SELECT e.employee_id, d.department_name
FROM employee e
INNER JOIN department d ON e.department_code = d.department_code
WHERE e.is_active_ind = 1;

-- Good — filter before the join
SELECT ae.employee_id, d.department_name
FROM (
    SELECT employee_id, department_code
    FROM employee
    WHERE is_active_ind = 1
) ae
INNER JOIN department d ON ae.department_code = d.department_code;
```

### 9.6 Indexing & Data Type Choices

- **[MUST] `PERF-10`** Sargable predicates need a matching index. Create indexes on columns used in `WHERE`, `JOIN`, `ORDER BY`, and `GROUP BY`.
- **[SHOULD] `PERF-11`** Prefer a narrow, unique, ever-increasing clustered key (typically an `IDENTITY INT`/`BIGINT`). Wide or random clustered keys (a `UNIQUEIDENTIFIER`/GUID) fragment pages and bloat every non-clustered index, because the clustering key is stored in each of them. For large tables specifically, use `BIGINT IDENTITY` as the clustered primary key, and keep a GUID only as a secondary unique column for integration purposes if one is needed.
- **[SHOULD] `PERF-12`** Use `sys.dm_db_index_usage_stats` periodically to find indexes with high writes and near-zero seeks/scans, and drop them — every index speeds up reads but slows every `INSERT`/`UPDATE`/`DELETE` (see Appendix A for the query).
- **[SHOULD] `PERF-13`** A single-column index on a low-cardinality column (a bit/status flag with only 2–3 distinct values) usually isn't selective enough for the optimizer to seek on — it will scan instead. Use it as a secondary key column, an `INCLUDE`, or a filtered index targeting a specific skewed value.
- **[MUST] `PERF-14`** Use appropriately small types where the domain is genuinely bounded (e.g. `TINYINT` for a 0–255 range) rather than defaulting to a larger type. Prefer `VARCHAR` over `CHAR` unless the value is genuinely fixed-width — `CHAR` pads and wastes space otherwise.
- **[MUST] `PERF-15`** Aggregate functions (`MAX`, `MIN`, `SUM`, `COUNT`, `AVG`) must not run against large OLTP tables without proper filtering and a supporting index or partition-pruning strategy — an unfiltered aggregate on a large table causes a full scan, high I/O, and measurable degradation for other concurrent workloads.

## 10. Transactions & Concurrency

- **[MUST] `TXN-01`** Every `BEGIN TRANSACTION` must have a corresponding `COMMIT` or `ROLLBACK` on every code path, including error paths — wrap in `TRY/CATCH` (see §11) so a failure never leaves a transaction open and locks held.
- **[MUST] `TXN-02`** Check `XACT_STATE()` before rolling back in a `CATCH` block rather than calling `ROLLBACK` unconditionally, especially in nested procedure calls. `XACT_STATE() = 1` is an active, committable transaction; `-1` is active but doomed (must roll back); `0` means no active transaction (a `ROLLBACK` here would itself error).
- **[MUST] `TXN-03`** Keep transactions as short as possible. Only the actual data-modification statements belong inside `BEGIN`/`COMMIT` — never an external call, a long computation, or anything with variable/unbounded duration, since all of that holds locks for however long it takes.
- **[MUST] `TXN-04`** `SET XACT_ABORT ON` at the top of every stored procedure that modifies data — it ensures a runtime error automatically rolls back the entire transaction rather than leaving it partially committed, as a safety net alongside `TRY/CATCH`.
- **[SHOULD] `TXN-05`** SQL Server does not truly nest transactions — an inner `COMMIT` only decrements `@@TRANCOUNT`, and an inner `ROLLBACK` rolls back the *entire* outer transaction, not just the inner scope. Use `SAVE TRANSACTION` (savepoints) where partial rollback control is genuinely needed.
- **[MUST] `TXN-06`** Never wrap a row-by-row loop (cursor or `WHILE`) processing many rows inside a single transaction — batch and commit incrementally instead (see Appendix A for the batching pattern), or the loop holds locks and grows the log for its entire duration.
- **[SHOULD] `TXN-07`** Choose the isolation level deliberately rather than leaving every query on the implicit default; document any deviation. Enable **Read Committed Snapshot Isolation (RCSI)** at the database level for high-concurrency OLTP systems rather than reaching for query-level `WITH (NOLOCK)` hints as a habitual "make it faster" fix — `NOLOCK` allows dirty (uncommitted, possibly-rolled-back) reads, while RCSI gives readers a consistent versioned snapshot without blocking.
- **[SHOULD] `TXN-08`** Treat deadlocks as expected under concurrency, not exceptional bugs — wrap deadlock-prone operations with retry logic that specifically catches error 1205 (see Appendix A for the retry pattern).

```sql
-- Standard pattern for a data-modifying procedure
CREATE OR ALTER PROCEDURE usp_hr_update_employee_department
    @employee_id INT
    , @department_code VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        UPDATE employee SET department_code = @department_code WHERE employee_id = @employee_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END
```

## 11. Error Handling

PeoplesHR uses a **centralized SQL Server exception management framework** that standardizes how exceptions are captured, logged, correlated to the originating .NET request, and forwarded to Azure Application Insights.

**Architecture (for context, not something developers modify):**

1. **Database logging schema** — structured exception metadata in `Logging.ExceptionLog`, configuration in `Logging.Config`.
2. **Central logging procedure** — `Logging.usp_LogException` is the **only** approved entry point for logging SQL exceptions. Direct inserts into logging tables are prohibited.
3. **.NET exception forwarder** — a background worker forwards logged exceptions to Application Insights (at-least-once delivery, ~60s polling interval, 100-record batch size, both configurable).

Developers interact **only** with layer 2.

### Mandatory rules

- **[MUST] `ERR-01`** Every stored procedure that modifies data uses `TRY...CATCH`.
- **[MUST] `ERR-02`** Every `CATCH` block calls `Logging.usp_LogException`.
- **[MUST] `ERR-03`** Every stored procedure declares and forwards a `@correlation_id NVARCHAR(50) = NULL` parameter unchanged to `Logging.usp_LogException`. This links a SQL exception to the parent .NET request trace (`Activity.TraceId`) in Application Insights.
- **[MUST] `ERR-04`** Transactions are rolled back inside `CATCH` before logging (see `TXN-01`/`TXN-02`).
- **[MUST] `ERR-05`** Input parameters are captured and logged, and the custom message is a meaningful business-context description — not a restatement of the SQL error.
- **[SHOULD] `ERR-06`** Complex procedures are split into multiple logical `TRY/CATCH` blocks (header insert, child record insert, post-processing, result retrieval), each logging and rethrowing independently — this produces cleaner, more actionable telemetry than one large block.
- **[MUST] `ERR-07`** Never return raw SQL Server error details to an external caller (`THROW;` alone in a public-facing `CATCH`) — log full detail server-side, but surface a generic, safe message externally, since raw errors can leak schema/table/query structure to an attacker (see §12).

**What is captured automatically** — developers do not need to capture: database name, error number/severity/state/line, session ID, host name, application name, login name, transaction count, or timestamp. `Logging.usp_LogException` captures all of this internally.

```sql
DECLARE @base_input_params NVARCHAR(4000) = CONCAT(
    N'employee_code=', ISNULL(@employee_code, N'NULL'),
    N'; leave_type_code=', ISNULL(@leave_type_code, N'NULL'),
    N'; start_date=', ISNULL(CONVERT(NVARCHAR(10), @start_date, 120), N'NULL')
);

DECLARE
    @error_object NVARCHAR(128)
    , @custom_error_message NVARCHAR(4000)
    , @error_severity INT
    , @input_parameters NVARCHAR(4000);

BEGIN TRY
    BEGIN TRANSACTION;
        -- business logic
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

    SET @error_object = COALESCE(ERROR_PROCEDURE(), N'schema.procedure_name');
    SET @custom_error_message = N'Descriptive business message';
    SET @error_severity = ERROR_SEVERITY();
    SET @input_parameters = CONCAT(@base_input_params, N'; employee_id=', ISNULL(CONVERT(NVARCHAR(20), @employee_id), N'NULL'));

    EXEC Logging.usp_LogException
         @object_name      = @error_object
        , @custom_message   = @custom_error_message
        , @input_parameters = @input_parameters
        , @correlation_id   = @correlation_id
        , @severity         = @error_severity
        , @rethrow_error    = 0;

    THROW;
END CATCH;
```

**`@rethrow_error` guidelines:**

| Scenario                | `@rethrow_error`         |
| ----------------------- | ------------------------ |
| Critical failure        | `1` (default)            |
| Warning / informational | `0`                      |
| Non-blocking validation | Contextual (usually `0`) |

**Verification only** (not part of application logic): `SELECT * FROM Logging.ExceptionLog WHERE correlation_id = @correlation_id;`

## 12. Security

- **[MUST] `SEC-01`** Every value from user input, application code, or an external system is passed as a parameter — never concatenated into a SQL string. This is the primary defense against SQL injection.
- **[MUST] `SEC-02`** If dynamic SQL is genuinely unavoidable (e.g. a dynamic table/column name for a generic search), the *structure* may be built dynamically, but every *value* is still parameterized via `sp_executesql` — never concatenated.
- **[MUST] `SEC-03`** When a table name, column name, or sort direction must be dynamic, validate it against a fixed whitelist before building the SQL string — identifiers can't be parameterized like values, so whitelisting is the substitute control.
- **[MUST] `SEC-04`** Wrap any unavoidable dynamic identifier in `QUOTENAME()` as a required second layer of defense, even after whitelisting.
- **[SHOULD] `SEC-05`** Prefer a static, parameterized query over dynamic SQL whenever the query shape doesn't actually need to change — dynamic SQL is harder to review, harder to secure, and produces less reusable execution plans.

```sql
-- Bad — vulnerable to SQL injection; if @department_code = ''' OR '1'='1' -- this returns every row
DECLARE @sql NVARCHAR(MAX) = 'SELECT * FROM employee WHERE department_code = ''' + @department_code + '''';
EXEC (@sql);

-- Good
SELECT employee_id, first_name, last_name
FROM employee
WHERE department_code = @department_code;
```

```sql
-- Whitelisting a dynamic sort column, then QUOTENAME as a second layer of defense
DECLARE @sort_column VARCHAR(50) =
    CASE @sort_column
        WHEN 'first_name' THEN 'first_name'
        WHEN 'last_name'  THEN 'last_name'
        WHEN 'hire_date'  THEN 'hire_date'
        ELSE 'employee_id'  -- safe default if input doesn't match a known column
    END;

DECLARE @sql NVARCHAR(MAX) = N'SELECT * FROM employee ORDER BY ' + QUOTENAME(@sort_column);
EXEC sp_executesql @sql;
```

### Access control

- **[MUST] `SEC-06`** Application/service accounts get least-privilege access only — typically `EXECUTE` on specific stored procedures, or `SELECT`/`INSERT`/`UPDATE` on specific tables. Never `db_owner`, `sysadmin`, or blanket `db_datawriter`/`db_datareader` unless the app genuinely needs full read/write on every table.
- **[SHOULD] `SEC-07`** Route application data access through stored procedures with `EXECUTE` permission rather than granting direct DML on tables — this centralizes validation and lets you control exactly what operations are possible.
- **[MUST] `SEC-08`** Use distinct accounts per function — application, reporting/read-only, and administrative/DBA — never one shared high-privilege login across all purposes.
- **[MUST] `SEC-09`** Never hard-code credentials, connection strings, or API keys in T-SQL scripts or source control. Use integrated/managed identity authentication or an external secrets manager.
- **[SHOULD] `SEC-10`** Use Dynamic Data Masking or column-level permissions on sensitive fields (salary, national ID, bank details) so accounts without a genuine need can't view them even with table-level `SELECT`.
- **[MUST] `SEC-11`** Never surface raw SQL Server error details to an external caller (duplicate of `ERR-07` — repeated here because it's fundamentally a security control, not just an error-handling nicety).
- **[SHOULD] `SEC-12`** Enable auditing (SQL Server Audit, or an application-level audit table) on tables containing sensitive or regulated data, capturing who changed what and when — required for compliance, not just security.

## 13. Comments & Documentation

- **[MUST] `CMT-01`** Every script, stored procedure, function, or view starts with a standard header block: object name, purpose, author, created date, module, and a change-history table.

```sql
-- =============================================
-- Object:      usp_hr_update_employee_department
-- Purpose:     Updates an employee's department and syncs related pay records
-- Author:      J. Perera
-- Created:     2026-07-21
-- Module:      Employee Information
-- =============================================
-- Change History:
-- Date         Author          Description
-- ----------   -------------   -----------------------------------------
-- 2026-07-21   J. Perera       Initial version
-- 2026-08-05   A. Silva        Added validation for inactive employees
-- =============================================
```

- **[MUST] `CMT-02`** Any script that creates or alters a table or table-related column includes a `--@diagram: <ERGroup>` tag at the top, identifying the owning module for the ER diagram. See [Appendix C](#appendix-c-er-diagram-module-groups) for the full list of valid module names.

```sql
--@diagram: Payroll
```

- **[MUST] `CMT-03`** Every newly created or modified table has an `MS_Description` extended property set, using the standard update-else-add pattern.
- **[MUST] `CMT-04`** Every newly added or modified column has a column-level `MS_Description` set, describing business meaning, valid values/format, and any dependency other systems have on it — not a restatement of the column name.
- **[MUST] `CMT-05`** When a column's meaning or valid values change, the `MS_Description` update is part of the *same* PR — a stale description actively misleads, which is worse than no description.

```sql
-- Table description
IF EXISTS (
    SELECT 1
    FROM sys.extended_properties ep
    INNER JOIN sys.tables t ON ep.major_id = t.object_id
    INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
    WHERE s.name = 'dbo' AND t.name = 'employee' AND ep.name = 'MS_Description'
)
BEGIN
    EXEC sp_updateextendedproperty
        @name = N'MS_Description',
        @value = N'Stores core employee master data including personal and employment details',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE',  @level1name = N'employee';
END
ELSE
BEGIN
    EXEC sp_addextendedproperty
        @name = N'MS_Description',
        @value = N'Stores core employee master data including personal and employment details',
        @level0type = N'SCHEMA', @level0name = N'dbo',
        @level1type = N'TABLE',  @level1name = N'employee';
END
```

```sql
-- Column description — bad: restates the name, adds no value
@value = N'Department code'

-- Good: explains meaning, format, and constraints
@value = N'FK to department.department_code. 3-letter code (e.g. HR, ITX, FIN). Required for active employees; NULL only permitted for terminated employees per HR-002.'
```

- **[MUST] `CMT-06`** Inline comments explain **why**, not what — business reasoning or non-obvious intent, never a restatement of the SQL. A comment that narrates the code adds noise, not value.
- **[MUST] `CMT-07`** Any logic that isn't self-evident from reading the SQL — a workaround for a known issue, a regulatory rule, a deliberately "wrong-looking" join — is documented so a future developer doesn't "fix" it and reintroduce a bug.
- **[MUST] `CMT-08`** If a script or query must break a standard in this document (uses `NOLOCK`, uses `RIGHT JOIN`, uses `SELECT *`), a comment explains why the exception is justified, so it reads as a deliberate decision, not an oversight in review.

```sql
-- Bad — restates the obvious
-- Update the department code
UPDATE employee SET department_code = @department_code WHERE employee_id = @employee_id;

-- Good — explains the non-obvious business reason
-- Department must be updated before payroll sync runs at midnight, otherwise the
-- employee is excluded from this month's pay run (see JIRA-4521)
UPDATE employee SET department_code = @department_code WHERE employee_id = @employee_id;
```

- **[SHOULD] `CMT-09`** Break long migration or batch scripts into clearly labeled sections (`-- SECTION 1: Schema changes`, etc.) so structure can be scanned without reading every line.
- **[MUST] `CMT-10`** Don't leave large blocks of commented-out dead code in committed scripts "just in case" — version control already preserves history. If the reasoning matters, note it briefly in a live comment and rely on git history for the rest.

## 14. Stored Procedures & Functions

- **[MUST] `SPF-01`** Naming follows §4.1 (`usp_<module>_<verb><entity>`, `fn_<module>_<name>`) — never the bare `sp_` prefix.
- **[MUST] `SPF-02`** Parameter names mirror the column/entity naming convention (`snake_case`, same terms as the schema) so a reader can map parameters to columns instantly.
- **[MUST] `SPF-03`** Required parameters are listed before optional parameters with defaults — SQL Server requires this order, and it documents intent.
- **[SHOULD] `SPF-04`** `OUTPUT` parameters are marked explicitly in both the declaration and the header comment, and are used only for genuinely returned values (IDs, status codes) — not as a substitute for a proper result set.
- **[SHOULD] `SPF-05`** `RETURN` carries a simple status code only (`0` = success is the SQL Server convention; document non-zero codes in the header). Actual data comes back via a result set or `OUTPUT` parameter, never via `RETURN`.
- **[MUST] `SPF-06`** Each stored procedure has one well-defined responsibility. Avoid a large procedure branching heavily on a `@mode`/`@action_type` parameter — split into separate, purpose-named procedures instead, and compose larger workflows from an orchestrating parent procedure that calls them.
- **[SHOULD] `SPF-07`** Prefer inline table-valued functions (`RETURNS TABLE ... RETURN (SELECT ...)`) over multi-statement TVFs or scalar UDFs. Inline TVFs expand into the calling query and can use indexes normally; multi-statement TVFs and scalar functions called per-row are treated as a black box by the optimizer and are often much slower.
- **[MUST] `SPF-08`** Every procedure includes `SET NOCOUNT ON;` — reduces unnecessary "N rows affected" network round-trips and avoids interfering with `@@ROWCOUNT` usage.
- **[MUST] `SPF-09`** The header block (`CMT-01`) is required on every procedure/function, including small "utility" ones — no exceptions.
- **[MUST] `SPF-10`** Never `SELECT *` inside a procedure (restated — a procedure's output shape must be a stable, explicit contract; `SELECT *` silently changes shape if the underlying table's columns change).

```sql
CREATE OR ALTER PROCEDURE usp_hr_get_employee_by_id
    @employee_id INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT employee_id, first_name, last_name, department_code, hire_date
    FROM employee
    WHERE employee_id = @employee_id;
END
```

## 15. Version Control & Migration Management

- **[MUST] `VCM-01`** Every schema-changing script must be **idempotent** — check whether the change already exists before applying it (table creation, column addition, index creation, constraint addition), so re-running the script (accidental retry, redeploy) doesn't error or duplicate the change.
- **[MUST] `VCM-02`** Stored procedures, functions, and views use `CREATE OR ALTER` (SQL Server 2016 SP1+) instead of a drop-and-recreate pattern — it's idempotent by design and preserves existing permissions, which a `DROP` does not.
- **[MUST] `VCM-03`** Any re-runnable `INSERT` uses an `IF NOT EXISTS` check scoped to the primary key only in its `WHERE` clause (not other attributes, except in a documented special scenario), and explicitly lists column names in the `INSERT` — never a bare `INSERT INTO table VALUES (...)`, since that silently breaks if the table's column order or count changes.
- **[MUST] `VCM-04`** Every forward migration has a corresponding rollback script, checked in together in the same PR, that reverses it. If a rollback would destroy data (e.g. dropping a populated column), archive the data first rather than silently discarding it.
- **[MUST] `VCM-05`** Migration scripts are named to sort naturally in execution order (a date/version prefix plus a short description), e.g. `V2026.07.21.001__AddMiddleNameToEmployee.sql`.
- **[MUST] `VCM-06`** Each migration script represents one atomic, logical change (one table, one feature) — not several unrelated schema changes bundled together. This makes rollback, review, and troubleshooting far easier.
- **[MUST] `VCM-07`** Once a migration has run in any shared environment (QA, UAT, Production), it is never edited — create a new migration script to correct or extend it instead. Editing history breaks reproducibility across environments.
- **[SHOULD] `VCM-08`** Maintain a migration history table (or rely on a tool like Flyway/DbUp/Liquibase) so any environment can be queried to confirm exactly which scripts have run.
- **[MUST] `VCM-09`** Any structural migration includes both the `--@diagram: <ERGroup>` tag (`CMT-02`) and the `MS_Description` update (`CMT-03`/`CMT-04`) in the same script — not as a separate follow-up change.
- **[MUST] `VCM-10`** When writing existence-check queries at deployment time (`IF NOT EXISTS (SELECT ...)`), select `1`, never `*` — `SELECT *` here forces unnecessary column resolution for a query whose result is discarded anyway.

```sql
-- Bad
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name = 'object_name')

-- Good
IF NOT EXISTS (SELECT 1 FROM sysobjects WHERE name = 'object_name')
```

```sql
-- Idempotent column addition
IF NOT EXISTS (
    SELECT 1 FROM sys.columns
    WHERE object_id = OBJECT_ID('dbo.employee') AND name = 'middle_name'
)
BEGIN
    ALTER TABLE dbo.employee ADD middle_name VARCHAR(50) NULL;
END
```

```sql
-- Re-runnable insert: PK-only existence check, explicit column list
IF NOT EXISTS (SELECT 1 FROM hs_hr_employee WHERE emp_number = '00001')
BEGIN
    INSERT INTO hs_hr_employee (emp_number, name)
    VALUES ('00001', 'Sam');
END;
GO
```

## 16. Testing & Validation

- **[MUST] `TST-01`** Test against realistic data volumes, not just an empty or tiny dev table — a query that performs fine at 100 rows can behave completely differently at production scale.
- **[MUST] `TST-02`** For any `UPDATE`/`DELETE`/`INSERT` migration, capture the expected affected-row count before running and compare it against the actual — don't assume the change did what was intended without checking.
- **[MUST] `TST-03`** Explicitly test edge cases in every test pass: `NULL` values in nullable columns, empty string vs. `NULL`, and boundary dates (start/end of a range) — these are the most common source of production bugs.
- **[SHOULD] `TST-04`** Before replacing an existing query/report with an optimized version, run both side-by-side against the same data and diff the results (`EXCEPT` both directions) — a faster query that returns wrong data is worse than a slow, correct one.
- **[MUST] `TST-05`** Capture the **actual** execution plan (not just estimated) against representative data volumes before a query or procedure goes to production. See Appendix A for the checklist of what to look for.
- **[SHOULD] `TST-06`** For procedures expected to run under concurrent load, test with simulated concurrent executions, not just a single sequential run, to catch blocking, deadlocks, or lock escalation that won't appear in isolated testing.
- **[MUST] `TST-07`** After a migration or bulk data change, explicitly verify foreign keys, unique constraints, and check constraints are satisfied — don't assume `WITH NOCHECK` or bulk-loaded data is automatically valid.
- **[MUST] `TST-08`** Test the rollback script, not just the forward migration, in a non-production environment: run forward → verify state → run rollback → verify it matches the pre-migration baseline exactly.
- **[SHOULD] `TST-09`** Wrap key business-logic procedures in a repeatable automated test harness (e.g. tSQLt) run as part of CI/CD, not just manually before release.

**Definition of done for a database change (`TST-10`, [MUST]):** idempotency confirmed, rollback tested, execution plan reviewed, `MS_Description` present, `--@diagram` tag present, and regression tests pass. Treat this as a checklist, not a judgment call.

## 17. Responsibilities

| #    | Task                                              | Responsibility             |
| ---- | ------------------------------------------------- | -------------------------- |
| 17.1 | Maintain SQL naming conventions                   | DBA team & developer teams |
| 17.2 | Write SQL scripts to this standard                | Developer teams            |
| 17.3 | Review scripts against this standard before merge | DBA team                   |
| 17.4 | Maintain and tune query/index performance         | DBA team & developer teams |

---

## Appendix A: Performance Deep-Dive Reference

This appendix is reference material for diagnosing and tuning — not a checklist of standards to apply to every script. Pull from it when a query is slow, a deployment needs sign-off on a performance-sensitive change, or you're investigating a production issue.

### A.1 Reading Execution Plans

- **Table/Index Scan** on a large table usually means a missing or unusable index.
- **Key Lookup** next to a Seek means the index isn't covering; consider adding `INCLUDE` columns.
- A large gap between **Estimated** and **Actual** rows indicates stale statistics or a parameter-sniffing issue.
- High-cost **Sort**/**Hash Match** operators suggest a pre-sorting index, or a smaller result set before the sort.
- A warning icon on an operator usually means implicit conversion, a tempdb spill, or missing statistics.

```sql
SET STATISTICS IO, TIME ON;
-- run the query
SET STATISTICS IO, TIME OFF;
-- review logical reads per table and CPU/elapsed time
```

### A.2 Keeping Statistics Fresh

```sql
-- Update stats for one table with a full scan
UPDATE STATISTICS dbo.orders WITH FULLSCAN;

-- Check auto-update settings at the database level
SELECT name, is_auto_update_stats_on, is_auto_create_stats_on
FROM sys.databases
WHERE name = DB_NAME();
```

### A.3 Parameter Sniffing

The first execution of a stored procedure compiles a plan optimized for that call's parameter values. If later calls pass very different values (a highly selective ID vs. a very common one), the cached plan can be a poor fit for them — symptom: one proc call is fast, another with different parameters is very slow despite identical logic.

```sql
-- Fix 1: force recompilation per execution (higher CPU, always an optimal plan)
ALTER PROCEDURE dbo.usp_get_orders_by_customer @customer_id INT
AS
BEGIN
    SELECT order_id, order_date, total_amount
    FROM dbo.orders
    WHERE customer_id = @customer_id
    OPTION (RECOMPILE);
END
```

```sql
-- Fix 2: optimize for a typical/average value
SELECT order_id FROM dbo.orders WHERE customer_id = @customer_id
OPTION (OPTIMIZE FOR (@customer_id UNKNOWN));
```

```sql
-- Fix 3: local variable forces a density-based (average) estimate
ALTER PROCEDURE dbo.usp_get_orders_by_customer @customer_id INT
AS
BEGIN
    DECLARE @id INT = @customer_id;
    SELECT order_id FROM dbo.orders WHERE customer_id = @id;
END
```

### A.4 Covering Indexes

```sql
-- Index only covers customer_id, order_date — TotalAmount/Status require a Key Lookup
CREATE NONCLUSTERED INDEX ix_orders_customer_id
    ON dbo.orders (customer_id);

SELECT customer_id, order_date, total_amount, status
FROM dbo.orders
WHERE customer_id = 1001;
-- Plan: Index Seek + Key Lookup (expensive on large result sets)

-- Good — INCLUDE the extra columns so the index fully covers the query
CREATE NONCLUSTERED INDEX ix_orders_customer_id
    ON dbo.orders (customer_id)
    INCLUDE (order_date, total_amount, status);
-- Plan: Index Seek only, no lookup
```

### A.5 Finding Unused / Over-Written Indexes

```sql
SELECT
    OBJECT_NAME(s.object_id) AS table_name
    , i.name AS index_name
    , s.user_seeks, s.user_scans, s.user_lookups, s.user_updates
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
ORDER BY s.user_updates DESC;
```

### A.6 Filtered Indexes for Low-Cardinality Columns

```sql
-- Most rows have is_deleted_ind = 0; only a few have is_deleted_ind = 1
CREATE NONCLUSTERED INDEX ix_orders_is_deleted
    ON dbo.orders (is_deleted_ind)
    WHERE is_deleted_ind = 1;   -- small and highly selective
```

### A.7 Partitioning Large Tables

Partitioning by a date range lets the optimizer eliminate whole partitions instead of scanning the entire table, and turns archiving old data into a metadata operation (`SWITCH`) instead of a slow `DELETE`.

```sql
CREATE PARTITION FUNCTION pf_order_date (DATE)
    AS RANGE RIGHT FOR VALUES ('2023-01-01', '2024-01-01', '2025-01-01');

CREATE PARTITION SCHEME ps_order_date
    AS PARTITION pf_order_date ALL TO ([PRIMARY]);

CREATE TABLE dbo.orders (
    order_id INT IDENTITY(1,1)
    , order_date DATE NOT NULL
    , ...
) ON ps_order_date(order_date);
```

### A.8 Diagnosing Blocking

```sql
SELECT blocking_session_id, session_id, wait_type, wait_time, wait_resource
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;
```

### A.9 Deadlock Retry Pattern

```sql
DECLARE @retry_count INT = 0;

WHILE @retry_count < 3
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;
        UPDATE inventory SET quantity = quantity - 1 WHERE product_id = @product_id;
        COMMIT TRANSACTION;
        BREAK;  -- success, exit retry loop
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;

        IF ERROR_NUMBER() = 1205  -- deadlock victim
        BEGIN
            SET @retry_count += 1;
            WAITFOR DELAY '00:00:00.100';
        END
        ELSE
            THROW;  -- rethrow any non-deadlock error immediately
    END CATCH;
END
```

### A.10 Batch & Bulk Operations

A single `DELETE`/`UPDATE` touching millions of rows is one giant transaction, grows the log heavily, and can escalate to a table lock. Batch it instead:

```sql
WHILE 1 = 1
BEGIN
    BEGIN TRANSACTION;

    DELETE TOP (5000) FROM dbo.audit_log WHERE log_date < '2023-01-01';

    COMMIT TRANSACTION;

    IF @@ROWCOUNT = 0 BREAK;
END
```

For bulk loads, use `BULK INSERT`/`SqlBulkCopy` rather than row-by-row inserts:

```sql
BULK INSERT dbo.staging_orders
FROM 'D:\imports\orders.csv'
WITH (
    FIELDTERMINATOR = ','
    , ROWTERMINATOR = '\n'
    , TABLOCK           -- reduces lock overhead for the bulk load
    , BATCHSIZE = 10000
);
```

### A.11 Plan Caching

```sql
-- Bad — every call is a distinct, non-reusable plan; also SQL-injectable
DECLARE @sql NVARCHAR(MAX) = 'SELECT * FROM dbo.orders WHERE customer_id = ' + CAST(@customer_id AS VARCHAR);
EXEC (@sql);

-- Good — parameterized, plan is reused across calls
EXEC sp_executesql
    N'SELECT * FROM dbo.orders WHERE customer_id = @id',
    N'@id INT', @id = @customer_id;
```

### A.12 Avoiding N+1 from Application Code

```csharp
// Bad — one query per loop iteration
foreach (var customer in customers) {
    var orders = db.Query("SELECT * FROM orders WHERE customer_id = @id", customer.Id);
}

// Good — one set-based query
var ids = customers.Select(c => c.Id).ToList();
var orders = db.Query("SELECT * FROM orders WHERE customer_id IN @ids", new { ids });
```

### A.13 Correlated Subqueries vs. Joins

```sql
-- Bad — subquery re-executed per outer row
SELECT c.customer_id, c.name,
    (SELECT SUM(o.total_amount) FROM dbo.orders o WHERE o.customer_id = c.customer_id) AS total
FROM dbo.customers c;

-- Good — set-based aggregation with a join
SELECT c.customer_id, c.name, SUM(o.total_amount) AS total
FROM dbo.customers c
LEFT JOIN dbo.orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.name;
```

### A.14 Execution Plan Review Checklist

Before sign-off on a performance-sensitive change, confirm:

- No **Table Scan**/**Index Scan** on a large table where a seek should be possible.
- No unexpected **Key Lookup** (indicates a missing covering index).
- No **implicit conversion** warning on a seek/scan operator.
- No disproportionately costly **Sort**/**Hash Match** operator.
- **Estimated vs. Actual** row counts are reasonably close.
- No **spill to tempdb** (visible on Sort/Hash operators — indicates an undersized memory grant).

## Appendix B: Quick-Reference Checklist (for Code Review & AI Agents)

Every rule below is a **[MUST]** from the body of this document, listed by ID for fast lookup during review. If code violates one of these, it should not be approved without an explicit, documented exception (§13.8, `CMT-08`).

**Naming:** `NC-01` singular objects · `NC-02`–`NC-05` module/client/locale prefixes · `NC-06`–`NC-11` snake_case columns, no bare generic names, `is_..._ind` booleans, `_utc` suffix rules

**Formatting:** `FMT-01`/`FMT-02` casing · `FMT-03`/`FMT-04` indentation & clause line breaks · `FMT-08`/`FMT-09` join formatting & aliasing · `FMT-10`–`FMT-12` operator spacing, explicit parens, semicolons

**Query structure:** `QRY-01`/`QRY-02` no `SELECT *`, always qualify columns · `QRY-04`–`QRY-07`/`QRY-10`–`QRY-12` ANSI joins only, explicit type, `ON` required, no `RIGHT JOIN`, watch fan-out, deliberate filter placement · `QRY-13` explicit precedence · `QRY-15`/`QRY-16`/`QRY-18` `IS NULL` not `= NULL`, `NOT EXISTS` not `NOT IN`

**Aggregation:** `AGG-01` full `GROUP BY` list · `AGG-02` `WHERE` vs `HAVING` · `AGG-04` pre-aggregate before joining · `AGG-05` deliberate `COUNT` variant · `AGG-08` explicit `NULL` grouping

**Data types:** `DTY-01`–`DTY-04` exact type matching, no column-side conversion · `DTY-06`/`DTY-08` sized types, FK type match · `DTY-09` `DECIMAL` for money · `DTY-10`/`DTY-11` `DATETIME2` + `_utc` · `DTY-13` `NVARCHAR` for text · `DTY-16` truncation awareness

**Performance:** `PERF-01`/`PERF-02` sargable predicates, no leading wildcards · `PERF-03` no `SELECT *` · `PERF-05` `EXISTS` not `COUNT(*)` · `PERF-08` type matching · `PERF-09` filter early · `PERF-14`/`PERF-15` right-sized types, guarded aggregates on large tables

**Transactions:** `TXN-01`–`TXN-04`/`TXN-06` paired commit/rollback, `XACT_STATE()` check, short transactions, `XACT_ABORT ON`, no per-row-loop transactions

**Error handling:** `ERR-01`–`ERR-05`/`ERR-07` `TRY/CATCH` + `Logging.usp_LogException` + `@correlation_id`, rollback before log, no raw errors to callers

**Security:** `SEC-01`–`SEC-04`/`SEC-06`/`SEC-08`/`SEC-09`/`SEC-11` parameterize everything, whitelist + `QUOTENAME` dynamic identifiers, least privilege, separate accounts, no hard-coded credentials, no raw errors externally

**Documentation:** `CMT-01`–`CMT-08` header block, `--@diagram` tag, `MS_Description` on tables/columns kept current, why-not-what comments, document deviations

**Stored procs:** `SPF-01`–`SPF-03`/`SPF-06`/`SPF-08`–`SPF-10` naming, param naming/order, single responsibility, `SET NOCOUNT ON`, header required, no `SELECT *`

**Migrations:** `VCM-01`–`VCM-07`/`VCM-09`/`VCM-10` idempotent, `CREATE OR ALTER`, PK-only re-runnable inserts with explicit columns, rollback script required, sortable naming, one change per script, never edit a deployed script, diagram tag + `MS_Description` in the same script, `SELECT 1` not `SELECT *` in existence checks

**Testing:** `TST-01`–`TST-03`/`TST-05`/`TST-07`/`TST-08`/`TST-10` realistic data volumes, row-count validation, edge cases, actual execution plan reviewed, constraints validated post-migration, rollback tested, definition-of-done checklist

## Appendix C: ER Diagram Module Groups

Valid values for the `--@diagram: <ERGroup>` tag (`CMT-02`):

Absence · Attendance · Benefit Management · Canteen Management System · Chatbot · Common Controls · Dashboard · Data Import · Disciplinary · Document Management System · EHRM · EIM Admin · ELC · ESM · Eligibility Module · Employee Information · Enterprise Dashboard · Extension Manager · Formula Builder · Grievance · Job Scheduler · Offboarding · On Demand Reports · Onboarding · Org Chart · Payroll · Performance Assessment · Probation Evaluation · Recruitment · Report Navigator · Report Scheduler · Request Tracker · Simulator · Survey Tool · Template Designer · Time Sheet · Training & Development · Web Loan · Widgets · Workflow · Workforce Planning · AI Insight · Skill Map Workspace Assignment

## Appendix D: Acronyms

| Acronym | Meaning                           |
| ------- | --------------------------------- |
| HBS     | hSenid Business Solutions PLC.    |
| DB      | Database                          |
| DBA     | Database Administrator            |
| RCSI    | Read Committed Snapshot Isolation |
| TVF     | Table-Valued Function             |
| UDF     | User-Defined Function             |
| DMV     | Dynamic Management View           |
| ER      | Entity-Relationship               |
