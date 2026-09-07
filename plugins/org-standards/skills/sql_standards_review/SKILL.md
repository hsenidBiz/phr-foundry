---
name: sql_standards_review
description: "Use when a T-SQL/SQL Server script (query, proc, function, view, or migration) for the PeoplesHR/hSenid product line needs review or sign-off. Identifies whether the script targets the OLD hSenid HRM system or the NEW PeoplesHR PHR-X (.NET Core) system, then reviews it against that system's own standard."
---

# PeoplesHR / hSenid SQL Standards Review (Old & New Systems)

There are two products, each with its own SQL script standard document:

| | OLD system | NEW system |
|---|---|---|
| Product | hSenid HRM product line | PeoplesHR PHR-X |
| Platform | Older .NET Framework app | Newer .NET Core app |
| Standard doc title | "SQL Script Standards" (hSenid) | "PeoplesHR SQL Standards" |
| Version reviewed here | 2.0.0 (restructured 2026-08-10) | 2.0.0 (restructured, deduped, added MUST/SHOULD/MAY) |
| Rule categories | `NC-*` naming, `DEP-*` deployment/data-type, `PERF-*` performance (3 categories, ~35 rules total) | `NC-*` `FMT-*` `QRY-*` `AGG-*` `DTY-*` `PERF-*` `TXN-*` `ERR-*` `SEC-*` `CMT-*` `SPF-*` `VCM-*` `TST-*` (13 categories, ~100 rules) |
| Scope | Naming, data-type sizing/deployment idempotency, performance/sargability only | Everything OLD covers (reorganized under different IDs) **plus** formatting, query structure, aggregation, a centralized exception-logging framework, transactions, security, comment/metadata requirements (`MS_Description`, ER-diagram tags), stored-proc conventions, migration/version-control process, and testing sign-off |

**Rule-ID collision warning:** both standards independently use bare IDs like `NC-01`, `PERF-01` — there is no `CLDL2-`/product prefix in either source document. The *same ID string means a different rule* in each standard (e.g. OLD `NC-01` = "≤30 character names"; NEW `NC-01` = "singular object names"). **Always write the system name before the ID in a report — "OLD NC-01" / "NEW NC-01" — never a bare ID**, or the finding is ambiguous.

## Step 1 — Identify the system (do this before reviewing anything)

At v2.0.0, the two standards' naming styles no longer share a skeleton — this is now a strong, near-definitive signal, not a weak one. Check, in this order:

1. **Explicit statement** — the user says "old system" / "hSenid HRM" / ".NET Framework", or "new system" / "PHR-X" / ".NET Core". Always trust this over any inference.
2. **File/header metadata** — file path, repo/folder name, or a header comment naming the product or the standard doc itself (a comment citing "SQL Script Standards"/hSenid → OLD; citing "PeoplesHR SQL Standards"/PHR-X → NEW).
3. **Naming style** (now a strong tell — check this table):

   | Signal | OLD | NEW |
   |---|---|---|
   | Casing | UPPERCASE (`HS_HR_EMPLOYEE`, `EMP_NUMBER`) | lowercase `snake_case` (`employee`, `employee_id`) — applies uniformly, no exceptions |
   | Table/view prefix | `HS_` + module alias, e.g. `HS_OFB_EMP_DOC` | module alias only, lowercase, e.g. `ofb_exit_request` — **no `HS_`-equivalent prefix at all** |
   | View naming | Mandatory `VW_` prefix (`VW_HS_OFB_EMP_DOC_SUMMARY`) | **No view-prefix rule exists** — a view is named the same way as a table |
   | Procedure prefix | `SP_HS_<MODULE>_...` | `usp_<module>_...` — bare `sp_` is explicitly banned (SQL Server checks `master` first for `sp_*`) |
   | Function prefix | Not a formally numbered rule (seen only in examples, e.g. `FN_XX_X`) | `fn_<module>_...` is a numbered MUST (`NC-03`) |
   | Boolean/flag columns | No naming rule at all | `is_<predicate>_ind`, typed `BIT` (`NC-08`) |
   | Generic column names (`id`, `status`, `type`, `date`...) | Not addressed | Explicitly banned — must be entity-prefixed, e.g. `employee_id` not `id` (`NC-07`) |
   | UTC datetime columns | Not addressed | Mandatory `_utc` suffix + `DATETIME2` (`NC-09`–`NC-11`, `DTY-10`/`DTY-11`) |

   If identifiers are UPPERCASE with an `HS_` prefix → OLD. If they're lowercase `snake_case` with no `HS_` prefix → NEW. This alone resolves the great majority of cases.

4. **NEW-only fingerprints** — if *any* of these appear, the script is NEW regardless of naming, because OLD's standard has no equivalent concept at all (not "a looser version of it" — it is simply out of scope for OLD):
   - Calls `Logging.usp_LogException` and/or declares a `@correlation_id` parameter (centralized exception framework, §11 of NEW).
   - A `--@diagram: <ERGroup>` header comment, or `sp_addextendedproperty`/`sp_updateextendedproperty` calls setting `MS_Description`.
   - `SET XACT_ABORT ON` + `TRY/CATCH` + `XACT_STATE()` transaction pattern.
   - Explicit ANSI-only join enforcement discussion, ISNULL/NOT EXISTS-vs-NOT IN null-safety rules, ANSI window functions used for aggregate+detail — all points that OLD's standard (naming + data type/deployment + performance only) never legislates on.
   - Dynamic-SQL whitelisting + `QUOTENAME()` security pattern, or least-privilege account separation language.
5. **Weak legacy tells** (use only to form a hypothesis, never a silent decision): the deprecated `SYSOBJECTS` view instead of `sys.objects`/`sys.columns` leans OLD, but both standards' own examples have already been corrected to `sys.objects`, so treat this as very weak.
6. If none of this resolves it confidently, **ask the user** which system the script targets rather than guessing — a wrong guess either floods the report with false MUST violations (citing ~65 NEW-only rules against an OLD script) or lets a real problem through.

State the detected/assumed system as the first line of every report, with its basis, e.g.:
`System: NEW (PHR-X) — inferred from snake_case naming (employee_id, ofb_exit_request) and a Logging.usp_LogException call`
If inferred rather than told, invite correction: "flag it if this is actually the old hSenid HRM system."

## Step 2 — Apply the matching checklist

### OLD — hSenid HRM

Scope is narrow: naming, data types/deployment idempotency, and performance/sargability only. This standard does **not** define formatting, query-structure, aggregation, transaction, error-handling, security, comment/metadata, stored-procedure, migration-process, or testing rules. Don't invent violations in those areas for an OLD-system script — if asked about them, say plainly they aren't covered by this system's standard.

**Naming (`NC-*`)**

| ID | Level | Rule |
|---|---|---|
| NC-01 | SHOULD | Object/column names ≤ 30 chars (Oracle-interop precaution, not a SQL Server limit) |
| NC-02 | MUST | Singular object names — `HS_HR_EMPLOYEE`, not `...EMPLOYEES` |
| NC-03 | MUST | HRM-module tables prefixed `HS_` |
| NC-04 | MUST | Module-alias segment on tables/views, e.g. `HS_OFB_EMP_DOC` (singular) |
| NC-05 | MUST | View names start with `VW_` |
| NC-06 | MUST | Stored procs prefixed `SP_` + module alias, e.g. `SP_HS_OFB_PROCESS_EXIT` |
| NC-07 | MUST | Client/locale suffix appended after module alias, e.g. `HS_TNA_CLOCK_SMB`, `SP_HS_TNA_CLOCK_PHIL` |
| NC-08 | MUST | UPPERCASE identifiers throughout |

Note: OLD has no numbered rule for function-name prefixing (only seen informally in examples as `FN_XX_X`). Don't cite an ID for it — flag as an undocumented gap if asked, same as NEW's own documented gap.

**Data types & deployment (`DEP-*`)**

| ID | Level | Rule |
|---|---|---|
| DEP-01 | MUST | Data type sizes within engine limits (e.g. `VARCHAR` ≤ 8000 bytes outside `MAX`) |
| DEP-02 | MUST | FK column type/length matches the parent column exactly — check the parent's *current* size, don't assume it |
| DEP-03 | MUST | Existence check + `DROP` before `CREATE FUNCTION`/`VIEW`/`PROCEDURE`, every time |
| DEP-04 | MUST | Every script (create/alter/drop, table or otherwise) is idempotent/re-runnable |
| DEP-05 | MUST | `INSERT` lists explicit column names and is guarded by an existence check |
| DEP-06 | MUST | The existence-check `WHERE` backing a re-runnable `INSERT` tests the PK column(s) only |
| DEP-07 | MUST | Each column addition/change is its own `ALTER TABLE` statement, never combined |
| DEP-08 | MUST | Script batch ends with `GO` |
| DEP-09 | MUST | Existence checks (`IF EXISTS`/`IF NOT EXISTS`) select `1`, never `*` |

**Performance & sargability (`PERF-*`)** — a predicate is sargable when SQL Server can seek an index on it; this is the highest-leverage category in this standard.

| ID | Level | Rule |
|---|---|---|
| PERF-01 | MUST | No function/calculation/conversion on an indexed column in `WHERE`/`JOIN...ON`/`HAVING` (`UPPER()`, `YEAR()`, `ISNULL(col,...)`, concatenation, etc.) — rewrite as a sargable range or move the op to the constant side |
| PERF-02 | MUST | No leading-wildcard `LIKE '%x'`/`'%x%'` — use Full-Text Search instead; trailing wildcard `'x%'` is fine |
| PERF-03 | MUST | Parameter/variable type matches the column exactly (type, length, precision) — avoids implicit conversion; a `CONVERT_IMPLICIT` warning on the plan is the tell |
| PERF-04 | MUST | Never `SELECT *` |
| PERF-05 | MUST | `EXISTS`, never `COUNT(*) > 0`, for existence checks |
| PERF-06 | SHOULD | `UNION ALL` over `UNION` when result sets are known disjoint |
| PERF-07 | SHOULD | Prefer positive, rewritable logic over `<>`/`NOT IN`/`NOT LIKE` where feasible |
| PERF-08 | MUST | Apply the most selective filters early — in a CTE/subquery — not after a join/aggregation |
| PERF-09 | MUST | Index the columns actually used in `WHERE`/`JOIN`/`ORDER BY`/`GROUP BY` |
| PERF-10 | SHOULD | Name only needed columns so a covering index (`INCLUDE`) can satisfy the query without a key lookup |
| PERF-11 | SHOULD | Avoid `OR` across different columns — consider `UNION ALL` of two seekable queries |
| PERF-12 | SHOULD | Clustered index = narrow, unique, ever-increasing key (`BIGINT IDENTITY`); never a random GUID as the clustering key — GUID only as a secondary unique column |
| PERF-13 | SHOULD | Use `sys.dm_db_index_usage_stats` periodically to find and drop high-write/near-zero-read indexes |
| PERF-14 | SHOULD | A single-column index on a 2–3-value flag isn't selective enough to seek on — use `INCLUDE`, a composite key, or a filtered index instead |
| PERF-15 | SHOULD | Prefer a set-based `JOIN` + aggregation over a correlated subquery (re-executes per outer row) |
| PERF-16 | MUST | Right-sized data types for a genuinely bounded domain (e.g. `TINYINT` for age) |
| PERF-17 | SHOULD | `VARCHAR` over `CHAR` unless the value is genuinely fixed-width |
| PERF-18 | MUST | Aggregates (`MAX`/`MIN`/`SUM`/`COUNT`/`AVG`) against a large OLTP table must be backed by filtering + a supporting index or partition-pruning strategy — never an unfiltered full-table aggregate |

### NEW — PeoplesHR PHR-X

Scope covers everything OLD covers (under different IDs and casing conventions) plus ten additional categories. `snake_case` applies to every identifier — tables, views, columns, procedures, functions, params, variables — with no PascalCase exception anywhere.

**Naming (`NC-*`)**

| ID | Level | Rule |
|---|---|---|
| NC-01 | MUST | Singular objects |
| NC-02 | MUST | Module-alias prefix on tables/views, lowercase, e.g. `ofb_exit_request` |
| NC-03 | MUST | Functions prefixed `fn_<module>_`, e.g. `fn_ofb_calculate_notice_period` |
| NC-04 | MUST | Procedures prefixed `usp_<module>_` — never bare `sp_` |
| NC-05 | MUST | Client/locale suffix after module alias, e.g. `ofb_smb_`, `ofb_phil_` |
| NC-06 | MUST | Columns `snake_case` |
| NC-07 | MUST | No bare generic column names (`id`, `status`, `type`, `date`, `amount`...) — prefix with the entity/business concept (see full noun table in the source doc §4.2) |
| NC-08 | MUST | Boolean/flag columns named `is_<predicate>_ind`, typed `BIT` |
| NC-09 | MUST | UTC datetime columns suffixed `_utc` |
| NC-10 | MUST | Never leave a UTC-valued column ambiguously named (`created_date` etc.) without the `_utc` suffix |
| NC-11 | MUST | Don't apply `_utc` to a column that intentionally stores local/non-UTC time |
| NC-12 | SHOULD | Date-only columns named `<purpose>_date` |

**Formatting & style (`FMT-*`)**

| ID | Level | Rule |
|---|---|---|
| FMT-01 | MUST | Keywords and built-in functions UPPERCASE (`SELECT`, `COUNT`, `GETDATE`) |
| FMT-02 | MUST | Identifiers `snake_case` |
| FMT-03 | MUST | 4-space indent, never tabs |
| FMT-04 | MUST | Each major clause (`SELECT`/`FROM`/`WHERE`/`GROUP BY`/`ORDER BY`/each `JOIN`) starts its own line |
| FMT-05 | SHOULD | One column per line once the `SELECT` list has more than 2–3 columns |
| FMT-06 | SHOULD | Long `AND`/`OR` chains break onto separate lines, operator leading |
| FMT-07 | SHOULD | Leading commas |
| FMT-08 | MUST | Each `JOIN` on its own line, `ON` indented on the next line |
| FMT-09 | MUST | Always alias tables once more than one is in scope; consistent alias per table |
| FMT-10 | MUST | Single space around operators |
| FMT-11 | MUST | Explicit parentheses whenever `AND`/`OR` are mixed |
| FMT-12 | MUST | Terminate every statement with a semicolon |
| FMT-13 | MUST | Subqueries indented one level deeper than the parent statement |
| FMT-14 | SHOULD | CTEs preferred over deeply nested subqueries |

**Query structure & joins (`QRY-*`)**

| ID | Level | Rule |
|---|---|---|
| QRY-01 | MUST | Never `SELECT *` |
| QRY-02 | MUST | Once >1 table, every column reference is alias-qualified |
| QRY-03 | SHOULD | Alias computed/expression columns with `AS` |
| QRY-04 | MUST | Explicit ANSI join syntax only — comma-joins with the condition in `WHERE` are banned |
| QRY-05 | MUST | Always state the join type explicitly (`INNER JOIN`, not bare `JOIN`) |
| QRY-06 | MUST | Every `JOIN` has an `ON` clause |
| QRY-07 | MUST | Avoid `RIGHT JOIN` — rewrite as `LEFT JOIN` by swapping table order |
| QRY-08 | SHOULD | Avoid `FULL JOIN` unless genuinely needed (document why when used) |
| QRY-09 | SHOULD | `FROM` starts with the driving/primary table; join order doesn't affect the optimizer, only readability |
| QRY-10 | MUST | Verify a 1:many join isn't silently multiplying rows before aggregating (fan-out) — pre-aggregate in a CTE first if in doubt |
| QRY-11 | MUST | Join columns indexed on both sides and matching in type/length exactly |
| QRY-12 | MUST | For a `LEFT JOIN`, be deliberate about filter placement — `ON` keeps unmatched left rows, `WHERE` turns it into an inner join |
| QRY-13 | MUST | Parenthesize mixed `AND`/`OR` in `WHERE` for explicit precedence |
| QRY-14 | SHOULD | One condition per line, most selective first (readability only) |
| QRY-15 | MUST | `IS NULL`/`IS NOT NULL`, never `= NULL`/`<> NULL` |
| QRY-16 | MUST | Remember `NULL = NULL` is `UNKNOWN`, not `TRUE` |
| QRY-17 | SHOULD | Explicit `ISNULL()`/`COALESCE()` for defaults rather than relying on implicit behavior |
| QRY-18 | MUST | `NOT EXISTS`, not `NOT IN`, against a subquery that can return `NULL` |
| QRY-19 | SHOULD | `IN (...)` over chained `OR` on the same column |
| QRY-20 | SHOULD | `BETWEEN`/explicit range over `OR`-chained range checks |
| QRY-21 | SHOULD | Avoid `OR` across different columns — consider `UNION ALL` of two seekable queries |

**Aggregation & grouping (`AGG-*`)**

| ID | Level | Rule |
|---|---|---|
| AGG-01 | MUST | Every non-aggregated `SELECT` column appears in `GROUP BY`, written explicitly |
| AGG-02 | MUST | Filter in `WHERE` before grouping; `HAVING` only for conditions on the aggregate itself |
| AGG-03 | SHOULD | `SELECT DISTINCT`, not a purposeless `GROUP BY`, when no aggregate function is used |
| AGG-04 | MUST | Pre-aggregate each one-to-many table independently before joining (fan-out — same issue as `QRY-10`) |
| AGG-05 | MUST | Choose `COUNT(*)`/`COUNT(column)`/`COUNT(DISTINCT column)` deliberately |
| AGG-06 | SHOULD | Don't add extra `GROUP BY` columns "just in case" — changes result granularity |
| AGG-07 | SHOULD | Use a window function (`OVER (PARTITION BY ...)`) instead of a correlated subquery when an aggregate is needed alongside detail rows |
| AGG-08 | MUST | `GROUP BY` treats all `NULL`s as one group — handle explicitly if they should be excluded/labeled |
| AGG-09 | SHOULD | Remember logical processing order (`FROM→WHERE→GROUP BY→HAVING→SELECT→ORDER BY`) — a `SELECT`-list alias can't be used in `WHERE`/`GROUP BY` |

**Data types & casting (`DTY-*`)**

| ID | Level | Rule |
|---|---|---|
| DTY-01 | MUST | Parameter/variable type matches the column exactly (type, length, precision) |
| DTY-02 | MUST | Never mix `VARCHAR`/`NVARCHAR` for the same logical value |
| DTY-03 | MUST | The same logical column uses an identical type everywhere it appears across tables |
| DTY-04 | MUST | Never convert on the column side of a predicate — convert the literal/parameter side |
| DTY-05 | SHOULD | `CAST` over `CONVERT` unless a style parameter (e.g. date formatting) is needed |
| DTY-06 | MUST | Smallest numeric type that safely covers the realistic range — no defaulting to `BIGINT`/oversized `DECIMAL` |
| DTY-07 | SHOULD | Size string columns to a realistic maximum; `MAX` only for genuinely unbounded content |
| DTY-08 | MUST | FK column matches the parent's type and length exactly |
| DTY-09 | MUST | `DECIMAL`/`NUMERIC` for all currency values — never `FLOAT`/`REAL` |
| DTY-10 | MUST | `DATETIME2` by default for all date/time columns — legacy `DATETIME` banned in new development |
| DTY-11 | MUST | System-generated UTC timestamps stored as `DATETIME2` suffixed `_utc` |
| DTY-12 | SHOULD | `DATETIMEOFFSET` only when the original submitter/external time-zone offset must be preserved — don't suffix these `_utc` |
| DTY-13 | MUST | `NVARCHAR` for all user-entered/business/multilingual text (Unicode support) |
| DTY-14 | SHOULD | Avoid `VARCHAR` unless there's a specific, documented technical justification |
| DTY-15 | MAY | Character-based PK columns may stay `VARCHAR` for legacy/integration reasons — document the exception |
| DTY-16 | MUST | Verify a narrowing type conversion can't silently truncate/round data; make truncation explicit and visible |

**Performance & indexing (`PERF-*`)** — the day-to-day rules; execution-plan reading, DMV queries, parameter sniffing, partitioning, and batch/bulk patterns are deep-dive reference material in the source doc's Appendix A, not daily checklist items.

| ID | Level | Rule |
|---|---|---|
| PERF-01 | MUST | Never wrap an indexed column in a function/calculation/conversion in `WHERE`/`JOIN...ON`/`HAVING` |
| PERF-02 | MUST | Avoid leading-wildcard `LIKE` — use Full-Text Search for genuine free-text |
| PERF-03 | MUST | Never `SELECT *` (restates `QRY-01`) |
| PERF-04 | SHOULD | For a frequent, performance-critical query, use `INCLUDE` for a covering index |
| PERF-05 | MUST | `IF EXISTS (SELECT 1 ...)`, never `COUNT(*) > 0` |
| PERF-06 | SHOULD | `UNION ALL` over `UNION` when disjoint |
| PERF-07 | SHOULD | Prefer positive logic over `<>`/`NOT IN`/`NOT LIKE`/`NOT EXISTS` where feasible |
| PERF-08 | MUST | Match parameter/variable types to column types exactly (restates `DTY-01`) — watch for `CONVERT_IMPLICIT` in the plan |
| PERF-09 | MUST | Apply the most selective filters early, in a CTE/subquery, before a join or aggregation |
| PERF-10 | MUST | Sargable predicates need a matching index on `WHERE`/`JOIN`/`ORDER BY`/`GROUP BY` columns |
| PERF-11 | SHOULD | Narrow, unique, ever-increasing clustered key (`IDENTITY INT`/`BIGINT`); never a random GUID as the clustering key |
| PERF-12 | SHOULD | Use `sys.dm_db_index_usage_stats` to find and drop high-write/near-zero-read indexes |
| PERF-13 | SHOULD | Low-cardinality column (2–3 values) needs a filtered index or `INCLUDE`, not a plain single-column index |
| PERF-14 | MUST | Right-sized types for a bounded domain (e.g. `TINYINT`); `VARCHAR` over `CHAR` unless fixed-width |
| PERF-15 | MUST | Aggregates against a large OLTP table must be filtered and backed by an index or partition-pruning strategy |

**Transactions & concurrency (`TXN-*`)** — has no equivalent in OLD.

| ID | Level | Rule |
|---|---|---|
| TXN-01 | MUST | Every `BEGIN TRANSACTION` has a `COMMIT`/`ROLLBACK` on every code path, including errors (`TRY/CATCH`) |
| TXN-02 | MUST | Check `XACT_STATE()` before rolling back in `CATCH` (`1`=active/committable, `-1`=doomed, `0`=none) |
| TXN-03 | MUST | Keep transactions short — only the actual DML belongs inside `BEGIN`/`COMMIT`, never external calls or unbounded work |
| TXN-04 | MUST | `SET XACT_ABORT ON` at the top of every data-modifying procedure |
| TXN-05 | SHOULD | SQL Server doesn't truly nest transactions — use `SAVE TRANSACTION` (savepoints) for partial rollback |
| TXN-06 | MUST | Never wrap a row-by-row loop over many rows in one transaction — batch and commit incrementally |
| TXN-07 | SHOULD | Choose isolation level deliberately; prefer RCSI at the database level over habitual `WITH (NOLOCK)` hints |
| TXN-08 | SHOULD | Treat deadlocks as expected under concurrency — retry logic catching error 1205 |

**Error handling (`ERR-*`)** — centralized exception framework, no equivalent in OLD. This is one of the strongest NEW fingerprints.

| ID | Level | Rule |
|---|---|---|
| ERR-01 | MUST | Every data-modifying procedure uses `TRY...CATCH` |
| ERR-02 | MUST | Every `CATCH` block calls `Logging.usp_LogException` (the *only* approved entry point — direct inserts into logging tables are prohibited) |
| ERR-03 | MUST | Every procedure declares `@correlation_id NVARCHAR(50) = NULL` and forwards it unchanged to `Logging.usp_LogException` |
| ERR-04 | MUST | Roll back before logging in `CATCH` |
| ERR-05 | MUST | Log input parameters plus a meaningful business-context message, not a restated SQL error |
| ERR-06 | SHOULD | Split complex procedures into multiple logical `TRY/CATCH` blocks, each logging/rethrowing independently |
| ERR-07 | MUST | Never return raw SQL Server error details to an external caller — log full detail server-side, surface a generic message externally |

**Security (`SEC-*`)** — no equivalent in OLD.

| ID | Level | Rule |
|---|---|---|
| SEC-01 | MUST | Every value from user/app/external input is parameterized — never concatenated into SQL |
| SEC-02 | MUST | If dynamic SQL is unavoidable, structure may be dynamic but every value is still parameterized via `sp_executesql` |
| SEC-03 | MUST | A dynamic table/column/sort identifier is validated against a fixed whitelist |
| SEC-04 | MUST | Wrap any unavoidable dynamic identifier in `QUOTENAME()` as a second layer of defense |
| SEC-05 | SHOULD | Prefer a static parameterized query over dynamic SQL when the shape doesn't need to change |
| SEC-06 | MUST | Least-privilege service accounts only — never `db_owner`/`sysadmin`/blanket `db_datawriter`/`db_datareader` |
| SEC-07 | SHOULD | Route data access through stored procedures with `EXECUTE` permission rather than direct table DML |
| SEC-08 | MUST | Distinct accounts per function (app / reporting / admin) — never one shared high-privilege login |
| SEC-09 | MUST | Never hard-code credentials/connection strings/API keys — use managed identity or a secrets manager |
| SEC-10 | SHOULD | Dynamic Data Masking or column-level permissions on sensitive fields (salary, national ID, bank details) |
| SEC-11 | MUST | Never surface raw SQL error details externally (duplicates `ERR-07`) |
| SEC-12 | SHOULD | Enable auditing on tables with sensitive/regulated data |

**Comments & documentation (`CMT-*`)** — the `MS_Description`/`--@diagram` requirements have no equivalent in OLD and are a strong fingerprint.

| ID | Level | Rule |
|---|---|---|
| CMT-01 | MUST | Standard header block on every script/proc/function/view: object, purpose, author, created date, module, change-history table |
| CMT-02 | MUST | `--@diagram: <ERGroup>` tag at the top of any script creating/altering a table or table column (valid module names in source doc Appendix C) |
| CMT-03 | MUST | `MS_Description` extended property set on every newly created/modified table (update-else-add pattern) |
| CMT-04 | MUST | `MS_Description` set on every newly added/modified column, describing business meaning/valid values/dependencies — not a restatement of the name |
| CMT-05 | MUST | An `MS_Description` update for a changed column meaning ships in the *same* PR as the change |
| CMT-06 | MUST | Inline comments explain *why*, never restate *what* the SQL does |
| CMT-07 | MUST | Non-obvious logic (workarounds, regulatory rules, deliberately odd joins) is documented so it isn't "fixed" later |
| CMT-08 | MUST | Any standard exception (`NOLOCK`, `RIGHT JOIN`, `SELECT *`) carries a comment justifying it |
| CMT-09 | SHOULD | Long migration/batch scripts broken into labeled sections |
| CMT-10 | MUST | No large blocks of commented-out dead code — rely on version control history instead |

**Stored procedures & functions (`SPF-*`)**

| ID | Level | Rule |
|---|---|---|
| SPF-01 | MUST | Naming follows §4 (`usp_<module>_...`/`fn_<module>_...`, never bare `sp_`) |
| SPF-02 | MUST | Parameter names mirror the column/entity naming convention |
| SPF-03 | MUST | Required parameters listed before optional/defaulted ones |
| SPF-04 | SHOULD | `OUTPUT` parameters marked explicitly in declaration and header comment; used only for genuinely returned values |
| SPF-05 | SHOULD | `RETURN` carries a simple status code only — data comes back via result set or `OUTPUT` |
| SPF-06 | MUST | One well-defined responsibility per procedure — avoid a `@mode`/`@action_type` branching monolith; compose via an orchestrating parent instead |
| SPF-07 | SHOULD | Prefer inline table-valued functions over multi-statement TVFs or scalar UDFs (the optimizer treats the latter as a black box) |
| SPF-08 | MUST | `SET NOCOUNT ON;` in every procedure |
| SPF-09 | MUST | Header block (`CMT-01`) required on every procedure/function, including small utility ones |
| SPF-10 | MUST | Never `SELECT *` inside a procedure — output shape must be a stable, explicit contract |

**Version control & migration management (`VCM-*`)**

| ID | Level | Rule |
|---|---|---|
| VCM-01 | MUST | Every schema-changing script is idempotent (checks before applying create/alter/add/drop) |
| VCM-02 | MUST | Procedures/functions/views use `CREATE OR ALTER` — never drop-and-recreate (preserves permissions) |
| VCM-03 | MUST | Re-runnable `INSERT` uses a PK-only `IF NOT EXISTS` guard and an explicit column list |
| VCM-04 | MUST | Every forward migration ships a corresponding rollback script in the same PR; archive data before a destructive rollback |
| VCM-05 | MUST | Migration scripts named to sort in execution order (date/version prefix + description) |
| VCM-06 | MUST | Each migration script is one atomic, logical change |
| VCM-07 | MUST | Once a migration has run in any shared environment, it is never edited — create a new migration instead |
| VCM-08 | SHOULD | Maintain a migration history table or use a tool (Flyway/DbUp/Liquibase) to confirm what's run where |
| VCM-09 | MUST | `--@diagram` tag and `MS_Description` update ship in the *same* script as a structural migration, not a follow-up |
| VCM-10 | MUST | Existence checks select `1`, never `*` |

**Testing & validation (`TST-*`)**

| ID | Level | Rule |
|---|---|---|
| TST-01 | MUST | Test against realistic data volumes, not an empty/tiny dev table |
| TST-02 | MUST | Capture expected vs. actual affected-row count for `UPDATE`/`DELETE`/`INSERT` migrations |
| TST-03 | MUST | Explicitly test edge cases: `NULL`s, empty string vs `NULL`, boundary dates |
| TST-04 | SHOULD | Diff old vs. optimized query results side-by-side (`EXCEPT` both directions) before replacing |
| TST-05 | MUST | Capture the *actual* execution plan against representative volume before production |
| TST-06 | SHOULD | Test under simulated concurrent load, not just sequential, for procedures expecting concurrency |
| TST-07 | MUST | Verify FKs/unique/check constraints after a migration or bulk change — don't assume `NOCHECK`-loaded data is valid |
| TST-08 | MUST | Test the rollback script too: forward → verify → rollback → verify matches baseline |
| TST-09 | SHOULD | Automated test harness (e.g. tSQLt) run in CI/CD for key business-logic procedures |
| TST-10 | MUST | Definition of done: idempotency confirmed, rollback tested, execution plan reviewed, `MS_Description` present, `--@diagram` tag present, regression tests pass |

## Step 3 — Review process

1. Read the whole script before flagging anything — several rules (fan-out via `QRY-10`/`AGG-04`, `PERF-15`/OLD `PERF-18`'s "large OLTP table" judgment, `ERR-*`'s full exception flow) only make sense once the full context is visible.
2. Confirm the system (Step 1) and state it, with basis, as the first line of the report.
3. Walk only the checklist for that system. Never cite a NEW-only category (`FMT-*`, `QRY-*`, `AGG-*`, `TXN-*`, `ERR-*`, `SEC-*`, `CMT-*`, `SPF-*`, `VCM-*`, `TST-*`) against an OLD-system script — those categories don't exist in OLD's standard, and flagging them there is a false violation, not thoroughness.
4. For every real violation, capture: system-qualified rule ID (e.g. "NEW ERR-03", "OLD DEP-06"), severity, the offending line/snippet, and a concrete fix. Pull the corrected pattern from the tables above, or from the source document's own example blocks when a rewrite isn't self-evident from the rule text alone.
5. A `SHOULD` item passes if the script already documents the deviation in a comment explaining why (NEW `CMT-08` codifies this explicitly; apply the same courtesy to OLD scripts even though OLD has no matching numbered rule for it).
6. For NEW scripts specifically, don't forget the categories that are easy to skim past because they read like architecture rather than syntax: `ERR-*` (every data-modifying proc needs `TRY/CATCH` + `Logging.usp_LogException` + `@correlation_id`), `CMT-02`–`CMT-05` (`--@diagram` tag + `MS_Description`), and `TXN-04` (`XACT_ABORT ON`). These are cheap to miss and are exactly the kind of thing DBA sign-off checks for.

## Report format

1. **System** — one line: which system, and whether it was stated, inferred (name the signal), or confirmed after asking.
2. **Verdict** — `BLOCKED (N must-fix items)` / `PASS (no MUST violations)` / `PASS WITH SHOULD-LEVEL NOTES`.
3. **MUST violations** (blockers) — table: `Rule ID | Line/snippet | Problem | Fix`.
4. **SHOULD notes** — same format, undocumented deviations only; note they pass if the author adds a justifying comment.
5. **MAY / judgment notes** — only if something stands out as a clear misuse.

Keep it direct and actionable: quote the exact offending line, give the corrected line, and always prefix the rule ID with the system name (`OLD` or `NEW`) so there's never ambiguity about which standard produced a given finding — the two standards reuse the same bare IDs for different rules. Don't restate the whole standard — only the rules actually implicated by the script under review.

