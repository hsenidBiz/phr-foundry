# SQL Script Standards

**Conventions & Standards for SQL Scripts**

Proprietary Information Of hSenid Business Solutions PLC.

This document contains information proprietary to hSenid Business Solutions PLC, and may not be reproduced, disclosed or used in whole or in part without permission in writing from hSenid Business Solutions PLC.

© 2025 hSenid Business Solutions PLC.

---

## Document Control

**Document properties**

| Field | Value |
| --- | --- |
| **Owner** | TBD |
| **Version** | 2.0.0 |
| **Effective Date** | TBD *(the source document carried two conflicting dates — see [Appendix D](#appendix-d-editorial-notes--corrections-applied-during-this-restructure))* |
| **Review Frequency** | Annually, or whenever a significant change occurs |
| **Document Name** | Conventions and Standards for SQL Scripts |
| **Document ID** | TBD |
| **Classification** | Internal |

**Version History**

| Version | Prepared by | Reviewed by | Authorized by | Date | Description |
| --- | --- | --- | --- | --- | --- |
| 0.1.0 | Naveen Warnakulasuriya | Chinthaka Nayomal | Chinthaka Nayomal | 2025-03-05 | Initial draft. *(Note: the source Document Control table listed this as Version 1.0.0 while Version History only ever recorded a 0.1.0 row — the numbers never reconciled. Carried forward here as 0.1.0 to match the only recorded history entry; see Appendix D.)* |
| 2.0.0 | Ayub Sourjah | TBD | TBD | 2026-08-10 | Full restructure: reorganized into a MUST/SHOULD/MAY standard with stable rule IDs, resolved naming/versioning/section-numbering inconsistencies, deduplicated repeated performance rules, fixed broken example syntax, and added a machine-readable `rules.json` export. See [Appendix D](#appendix-d-editorial-notes--corrections-applied-during-this-restructure) for the full list of corrections. |

**Distribution list**

**Placement:** Shared folder location

---

## Table of Contents

1. [Purpose & Scope](#1-purpose--scope)
2. [How to Use This Document](#2-how-to-use-this-document)
3. [Definitions & Acronyms](#3-definitions--acronyms)
4. [Naming Conventions](#4-naming-conventions)
5. [Script Execution & Deployment Standards](#5-script-execution--deployment-standards)
6. [Performance & Sargability](#6-performance--sargability)
7. [Responsibilities](#7-responsibilities)
- [Appendix A: Quick-Reference Checklist](#appendix-a-quick-reference-checklist)
- [Appendix B: Acronyms](#appendix-b-acronyms)
- [Appendix C: Supporting Document Templates](#appendix-c-supporting-document-templates)
- [Appendix D: Editorial Notes — Corrections Applied During This Restructure](#appendix-d-editorial-notes--corrections-applied-during-this-restructure)

---

## 1. Purpose & Scope

Every programming language has its own coding conventions. In specific business software products, due to their architecture, there are additional coding conventions and practices defined to maintain a certain quality bar or a limitation that should be upheld consistently. At hSenid, developers should maintain these standards alongside any product-specific script conventions provided, in order to respect known limitations and improve overall quality.

This document provides conventions for developers to follow. They relate to SQL script naming, deployment/execution safety, and performance. These conventions are reviewed in the Azure SQL script repository by the DBA team to ensure and maintain quality.

**Applies to:** all development teams involved in developing changes to the product's features who write or publish SQL scripts.

**Enforcement:** SQL scripts pushed to the Azure SQL script repository are reviewed by the DBA team against this standard before merge.

## 2. How to Use This Document

Every rule is tagged with one of three enforcement levels, per [RFC 2119](https://www.ietf.org/rfc/rfc2119.txt) convention:

| Tag | Meaning |
| --- | --- |
| **[MUST]** | Non-negotiable. A violation should block review/DBA sign-off. |
| **[SHOULD]** | Strong default. Deviating is acceptable only with a documented reason in the script. |
| **[MAY]** | A judgment call or optional technique — use it when it fits the situation. |

Each rule carries a short, stable ID (e.g. `NC-01`) so it can be referenced in code review comments and in [Appendix A](#appendix-a-quick-reference-checklist). A machine-readable export of every `[MUST]` rule is maintained alongside this document as `CLDL2SQL_SCRIPT_CONVENTION.rules.json`, for tooling and AI coding agents that want structured access instead of parsing markdown. If the two ever disagree, this document is authoritative.

Code examples use fenced ```sql blocks. Where a "Bad" example is shown, the "Good" example immediately after it is the required fix.

## 3. Definitions & Acronyms

See [Appendix B](#appendix-b-acronyms) for the full acronym table.

## 4. Naming Conventions

### 4.1 Object Naming (Tables, Views, Functions, Procedures)

- **[MUST] `NC-01`** Object names — including column names — must not exceed 30 characters. This originates from older Oracle databases, which truncate names beyond 30 characters by default; the limit is applied to both Oracle and SQL Server objects for cross-platform consistency.
- **[MUST] `NC-02`** Object names are singular, not plural. `HS_HR_EMPLOYEE` is correct; `HS_HR_EMPLOYEES` is not. This is a common relational convention, not one specific to hSenid products.
- **[MUST] `NC-03`** Tables belonging to HRM modules are prefixed `HS_`, e.g. an object name takes the shape `HS_XX_XX`.
- **[MUST] `NC-04`** Tables and views also carry a module-alias segment identifying the owning module. For example, an object created for the off-boarding module carries the alias `OFB`, giving a name such as `HS_OFB_EMP_DOC`.
- **[MUST] `NC-05`** View names always start with the alias `VW_`, so different object types remain visually distinct and conflict-free.
- **[MUST] `NC-06`** Stored procedures are prefixed `SP_`, followed by the module alias, e.g. `SP_HS_OFB_PROCESS_EXIT`.
- **[MUST] `NC-07`** Client- or localization-specific scripts carry an additional suffix appended after the module alias, identifying the client or locale. For example, for client "Sampath Bank" an object name would look like `HS_TNA_CLOCK_SMB`. For a Philippines-specific localization, a stored procedure would look like `SP_HS_TNA_CLOCK_PHIL`, using the alias `PHIL` to indicate the Philippines localization — so anyone reading the script name alone can tell what it relates to.
- **[MUST] `NC-08`** Table (and other object) names are written in uppercase, e.g. `HS_HR_EMPLOYEE`.

```sql
-- Good
CREATE TABLE HS_OFB_EMP_DOC ( ... );
CREATE VIEW VW_HS_OFB_EMP_DOC_SUMMARY AS ( ... );
CREATE PROCEDURE SP_HS_OFB_PROCESS_EXIT ( ... ) AS ( ... );
CREATE TABLE HS_TNA_CLOCK_SMB ( ... );        -- Sampath Bank-specific
CREATE PROCEDURE SP_HS_TNA_CLOCK_PHIL ( ... ) AS ( ... );  -- Philippines localization
```

## 5. Script Execution & Deployment Standards

This section covers standards that prevent repeatable deployment errors, particularly at script execution time.

### 5.1 Data Types

- **[MUST] `DEP-01`** Data type sizes must stay within the range the engine actually supports. For example, SQL Server's non-`MAX` `VARCHAR` has a maximum length of 8000 bytes — declaring a length beyond what a type supports is invalid and must be avoided.
- **[MUST] `DEP-02`** A foreign key column's data type — including length — must match its parent column exactly. A mismatch is a genuine deployment-time failure mode if not handled deliberately, not merely a style nit.

```sql
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE NAME = 'HS_HR_PF_GOAL_KPI_MONTHLY' AND TYPE = 'U')
BEGIN
    IF (SELECT max_length FROM sys.columns
        WHERE name = 'EMP_NUMBER'
            AND object_id IN (SELECT object_id FROM sys.objects WHERE name = 'HS_HR_EMPLOYEE' AND type = 'U')) = 8
    BEGIN
        CREATE TABLE HS_HR_PF_GOAL_KPI_MONTHLY (
            KPI_SEQID INT NOT NULL,
            EVAL_ID INT NOT NULL,
            EMP_NUMBER VARCHAR(8) NOT NULL,
            GOAL_ID INT NOT NULL,
            GOAL_VERSION_NO SMALLINT NOT NULL,
            KPI_MONTH VARCHAR(200) NULL,
            KPI_TARGET_BENCHMARK NUMERIC(18, 2) NULL,
            CUT_OFF_MARK NUMERIC(18, 2) NULL,
            PRIMARY KEY (KPI_SEQID, EVAL_ID, EMP_NUMBER, GOAL_ID, GOAL_VERSION_NO),
            FOREIGN KEY (EVAL_ID, EMP_NUMBER, GOAL_ID, GOAL_VERSION_NO)
                REFERENCES HS_HR_PF_GOAL (EVAL_ID, EMP_NUMBER, GOAL_ID, GOAL_VERSION_NO)
        );
    END
    ELSE
    BEGIN
        -- HS_HR_EMPLOYEE.EMP_NUMBER was VARCHAR(6) before the width was widened to VARCHAR(8) above
        CREATE TABLE HS_HR_PF_GOAL_KPI_MONTHLY (
            KPI_SEQID INT NOT NULL,
            EVAL_ID INT NOT NULL,
            EMP_NUMBER VARCHAR(6) NOT NULL,
            GOAL_ID INT NOT NULL,
            GOAL_VERSION_NO SMALLINT NOT NULL,
            KPI_MONTH VARCHAR(200) NULL,
            KPI_TARGET_BENCHMARK NUMERIC(18, 2) NULL,
            CUT_OFF_MARK NUMERIC(18, 2) NULL,
            PRIMARY KEY (KPI_SEQID, EVAL_ID, EMP_NUMBER, GOAL_ID, GOAL_VERSION_NO),
            FOREIGN KEY (EVAL_ID, EMP_NUMBER, GOAL_ID, GOAL_VERSION_NO)
                REFERENCES HS_HR_PF_GOAL (EVAL_ID, EMP_NUMBER, GOAL_ID, GOAL_VERSION_NO)
        );
    END
END
GO
```

### 5.2 Existence Checks Before Create/Drop

- **[MUST] `DEP-03`** Creating a function, view, or stored procedure must be preceded by a check for its existence and a drop, every time, before the `CREATE`.

```sql
IF EXISTS (SELECT 1 FROM sys.objects WHERE name = 'FN_XX_X' AND type = 'FN')
    DROP FUNCTION FN_XX_X;
GO

CREATE FUNCTION FN_XX_X (@PARAM INT)
RETURNS INT
AS
BEGIN
    RETURN (@PARAM);
END
GO
```

### 5.3 Re-runnable (Idempotent) Scripts

- **[MUST] `DEP-04`** At deployment time, every script must be able to re-run without error. As shown for procedure/view creation, the same applies to table creation, alteration, and drops — the whole point is that the script can be executed again in a deployment pipeline without an exception occurring.

```sql
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'HS_TD_XX_XX' AND type = 'U')
BEGIN
    CREATE TABLE HS_TD_XX_XX ( ... );
END;
GO
```

### 5.4 Inserts

- **[MUST] `DEP-05`** Any `INSERT` statement must explicitly list its target column names and must be guarded by an existence check so it is re-runnable. A bare `INSERT INTO table VALUES (...)` without a column list is not acceptable.
- **[MUST] `DEP-06`** When the existence check backing a re-runnable `INSERT` is written, its `WHERE` clause must test the primary key column(s) only — no other attribute — unless a documented special scenario requires otherwise.

```sql
-- Good
IF NOT EXISTS (SELECT 1 FROM HS_HR_EMPLOYEE WHERE EMP_NUMBER = '00001')
BEGIN
    INSERT INTO HS_HR_EMPLOYEE (EMP_NUMBER, NAME)
    VALUES ('00001', 'Sam');
END;
GO

-- Bad — no explicit column list; silently breaks if column order/count changes
IF NOT EXISTS (SELECT 1 FROM HS_HR_EMPLOYEE WHERE EMP_NUMBER = '00001')
BEGIN
    INSERT INTO HS_HR_EMPLOYEE
    VALUES ('00001', 'Sam');
END;
GO
```

### 5.5 Alterations

- **[MUST] `DEP-07`** When performing alterations, attribute changes must not be combined into a single statement — each column addition/change is its own `ALTER TABLE` statement.

```sql
-- Bad
ALTER TABLE HS_HR_EMPLOYEE
ADD COLUMN AGE, YEAR_OF_EXP SMALLINT;

-- Good
ALTER TABLE HS_HR_EMPLOYEE
ADD AGE SMALLINT;

ALTER TABLE HS_HR_EMPLOYEE
ADD YEAR_OF_EXP SMALLINT;
```

### 5.6 Batch Separators

- **[MUST] `DEP-08`** Every SQL Server script ends its batch with the `GO` keyword, so script execution boundaries are handled properly and consistently.

### 5.7 Existence-Check Result Sets

- **[MUST] `DEP-09`** An existence-check query written as `IF EXISTS(...)` / `IF NOT EXISTS(...)` selects `1`, never `*` — the result set is discarded either way, so resolving every column is wasted work.

```sql
-- Bad
IF NOT EXISTS (SELECT * FROM sys.objects WHERE name = 'OBJECT_NAME')

-- Good
IF NOT EXISTS (SELECT 1 FROM sys.objects WHERE name = 'OBJECT_NAME')
```

## 6. Performance & Sargability

A predicate is **sargable** when SQL Server can use an index seek to evaluate it. This is the highest-leverage category of standard in this document.

### 6.1 No Functions on Indexed Columns

- **[MUST] `PERF-01`** Never apply `LTRIM`, `RTRIM`, `UPPER`, `LOWER`, `CONVERT`, `CAST`, `YEAR()`, `ISNULL(column, ...)`, string concatenation (`column + ''`), or any other scalar function or calculation directly to an indexed column in `WHERE`, `JOIN ... ON`, or `HAVING` — it forces a scan of every row instead of an index seek. Rewrite as a sargable range, or move the operation to the constant/parameter side instead.

```sql
-- Bad
WHERE UPPER(DEPARTMENT_CODE) = 'HR'

-- Good — store/compare in a consistent case, or use a case-insensitive collation
WHERE DEPARTMENT_CODE = 'HR'
```

```sql
-- Bad — function on the column forces a scan of every row to evaluate YEAR(ORDER_DATE)
SELECT ORDER_ID FROM HS_XX_ORDER WHERE YEAR(ORDER_DATE) = 2024;

-- Good — rewritten as a sargable range so the optimizer can seek
SELECT ORDER_ID FROM HS_XX_ORDER WHERE ORDER_DATE >= '2024-01-01' AND ORDER_DATE < '2025-01-01';
```

### 6.2 Avoid Leading Wildcards

- **[MUST] `PERF-02`** `LIKE '%value'` or `LIKE '%value%'` cannot seek — avoid these unless Full-Text Search is used instead. A trailing wildcard (`LIKE 'value%'`) can still seek on the prefix and remains acceptable.

```sql
-- Bad
WHERE LAST_NAME LIKE '%son'

-- Acceptable — can still seek on the prefix
WHERE LAST_NAME LIKE 'John%'

-- Better for genuine free-text search patterns
CREATE FULLTEXT INDEX ON HS_XX_CUSTOMER(LAST_NAME) KEY INDEX PK_CUSTOMER;

-- Note: still names only the columns needed, per PERF-04 — no SELECT *, even in a "Good" example
SELECT CUSTOMER_ID, LAST_NAME FROM HS_XX_CUSTOMER WHERE CONTAINS(LAST_NAME, '"*son"');
```

### 6.3 Match Data Types Exactly (Avoid Implicit Conversion)

- **[MUST] `PERF-03`** Parameter and variable data types must match the column's data type exactly, including length and precision. A mismatch forces an implicit conversion — usually on the column side — which blocks an index seek. Check the execution plan for a `CONVERT_IMPLICIT` warning on the seek/scan operator; that is the tell-tale sign.

```sql
-- Bad — column is VARCHAR(20), variable is NVARCHAR — implicit conversion on the column side
DECLARE @Code NVARCHAR(20) = N'HR001';
WHERE DEPARTMENT_CODE = @Code

-- Good
DECLARE @Code VARCHAR(20) = 'HR001';
WHERE DEPARTMENT_CODE = @Code
```

### 6.4 Avoid SELECT *

- **[MUST] `PERF-04`** Always select only the columns needed. `SELECT *` prevents covering indexes from being used and pulls unnecessary I/O.

```sql
-- Bad
SELECT * FROM HS_HR_EMPLOYEE WHERE DEPARTMENT_CODE = 'HR';

-- Good
SELECT EMP_NUMBER, FIRST_NAME, LAST_NAME
FROM HS_HR_EMPLOYEE
WHERE DEPARTMENT_CODE = 'HR';
```

### 6.5 EXISTS Over COUNT(*)

- **[MUST] `PERF-05`** Use `EXISTS` for existence checks, never `COUNT(*)` — `EXISTS` stops at the first match instead of counting every row.

```sql
-- Bad
IF (SELECT COUNT(*) FROM HS_HR_EMPLOYEE WHERE DEPARTMENT_CODE = 'HR') > 0

-- Good
IF EXISTS (SELECT 1 FROM HS_HR_EMPLOYEE WHERE DEPARTMENT_CODE = 'HR')
```

### 6.6 UNION ALL Over UNION

- **[SHOULD] `PERF-06`** Use `UNION ALL` instead of `UNION` when the result sets are known to be disjoint — `UNION` forces an unnecessary dedupe sort.

```sql
-- Bad — dedupes even though the two sets can't overlap
SELECT ORDER_ID FROM HS_XX_ORDER WHERE ORDER_TYPE = 'Online'
UNION
SELECT ORDER_ID FROM HS_XX_ORDER WHERE ORDER_TYPE = 'InStore';

-- Good
SELECT ORDER_ID FROM HS_XX_ORDER WHERE ORDER_TYPE = 'Online'
UNION ALL
SELECT ORDER_ID FROM HS_XX_ORDER WHERE ORDER_TYPE = 'InStore';
```

### 6.7 Avoid Non-Sargable Negatives

- **[SHOULD] `PERF-07`** `<>`, `NOT IN`, and `NOT LIKE` often force scans. Prefer positive, rewritable logic where feasible.

```sql
-- Bad
WHERE DEPARTMENT_CODE <> 'HR'

-- Better where feasible — rewrite as a positive range/list
WHERE DEPARTMENT_CODE IN ('IT', 'FIN', 'OPS')
```

### 6.8 Filter Early, Filter Narrow

- **[MUST] `PERF-08`** Apply the most selective filters as early as possible — in a CTE/subquery — rather than filtering after a large join or aggregation.

```sql
-- Bad — joins the full table then filters
SELECT e.EMP_NUMBER, d.DEPARTMENT_NAME
FROM HS_HR_EMPLOYEE e
INNER JOIN HS_HR_DEPARTMENT d ON e.DEPARTMENT_CODE = d.DEPARTMENT_CODE
WHERE e.IS_ACTIVE_FLAG = 1;

-- Good — filter before joining
SELECT ae.EMP_NUMBER, d.DEPARTMENT_NAME
FROM (
    SELECT EMP_NUMBER, DEPARTMENT_CODE
    FROM HS_HR_EMPLOYEE
    WHERE IS_ACTIVE_FLAG = 1
) ae
INNER JOIN HS_HR_DEPARTMENT d ON ae.DEPARTMENT_CODE = d.DEPARTMENT_CODE;
```

### 6.9 Indexing for Sargable Predicates

- **[MUST] `PERF-09`** An index only helps if the query can seek into it. Create indexes on columns used in `WHERE`, `JOIN`, `ORDER BY`, and `GROUP BY`.

```sql
-- Index to support a common filter
CREATE NONCLUSTERED INDEX IX_ORDER_CUSTOMER_ID_ORDER_DATE
    ON HS_XX_ORDER (CUSTOMER_ID, ORDER_DATE)
    INCLUDE (TOTAL_AMOUNT, STATUS);

-- Supports: WHERE CUSTOMER_ID = @CUSTOMER_ID AND ORDER_DATE >= @FROM_DATE
-- and covers TOTAL_AMOUNT/STATUS so SQL Server doesn't need a key lookup back to the clustered index.
```

### 6.10 Covering Index Awareness

- **[SHOULD] `PERF-10`** For a frequent, performance-critical query, name only the columns actually needed so a covering index (with `INCLUDE`) can fully satisfy it without a key lookup back to the clustered index.

```sql
-- Bad — index only covers CUSTOMER_ID, ORDER_DATE; query still needs a Key Lookup
SELECT CUSTOMER_ID, ORDER_DATE, TOTAL_AMOUNT, STATUS
FROM HS_XX_ORDER
WHERE CUSTOMER_ID = 1001;
-- Plan: Index Seek + Key Lookup for TOTAL_AMOUNT/STATUS (expensive on large result sets)

-- Good — INCLUDE the extra columns so it's a covering index
CREATE NONCLUSTERED INDEX IX_ORDER_CUSTOMER_ID
    ON HS_XX_ORDER (CUSTOMER_ID)
    INCLUDE (ORDER_DATE, TOTAL_AMOUNT, STATUS);
-- Plan: Index Seek only, no lookup
```

### 6.11 Avoid OR Across Different Columns

- **[SHOULD] `PERF-11`** `OR` across different columns often prevents efficient index use. Consider `UNION ALL` of two seekable queries instead.

```sql
-- Bad — optimizer may scan
WHERE DEPARTMENT_CODE = 'HR' OR MANAGER_ID = 105

-- Better — two seekable queries combined
SELECT EMP_NUMBER FROM HS_HR_EMPLOYEE WHERE DEPARTMENT_CODE = 'HR'
UNION ALL
SELECT EMP_NUMBER FROM HS_HR_EMPLOYEE WHERE MANAGER_ID = 105;
```

### 6.12 Clustered Index Choice

- **[SHOULD] `PERF-12`** Prefer a narrow, unique, ever-increasing key (e.g. an `IDENTITY` int/bigint) as the clustered index. Wide or random clustered keys (like a GUID) fragment pages and bloat every non-clustered index, since the clustering key is stored in each of them. For large SQL Server tables specifically, always use `BIGINT IDENTITY` as the clustered primary key, and use a GUID only as a secondary unique identifier for integration purposes.

```sql
-- Bad — random GUID as clustering key
CREATE TABLE HS_XX_ORDER (
    ORDER_ID UNIQUEIDENTIFIER DEFAULT NEWID() PRIMARY KEY CLUSTERED,
    ...
);
-- Random inserts cause page splits and fragmentation

-- Good — surrogate identity, GUID as a normal unique column if needed
CREATE TABLE HS_XX_ORDER (
    ORDER_ID BIGINT IDENTITY(1,1) PRIMARY KEY CLUSTERED,
    ORDER_GUID UNIQUEIDENTIFIER DEFAULT NEWID() NOT NULL,
    ...
);
CREATE UNIQUE NONCLUSTERED INDEX UX_ORDER_GUID ON HS_XX_ORDER(ORDER_GUID);
```

### 6.13 Avoid Over-Indexing

- **[SHOULD] `PERF-13`** Every index speeds up reads but slows down `INSERT`/`UPDATE`/`DELETE`, since each write must maintain every index. Use `sys.dm_db_index_usage_stats` periodically to find indexes with high writes and near-zero seeks/scans, and drop them.

```sql
SELECT
    OBJECT_NAME(s.object_id) AS TABLE_NAME,
    i.name AS INDEX_NAME,
    s.user_seeks, s.user_scans, s.user_lookups, s.user_updates
FROM sys.dm_db_index_usage_stats s
JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
ORDER BY s.user_updates DESC;
```

### 6.14 Low-Cardinality Columns

- **[SHOULD] `PERF-14`** A single-column index on a bit/gender/status flag with only 2-3 distinct values usually isn't selective enough for the optimizer to use — it will scan instead of seek. These columns are more useful as a second key column, an `INCLUDE`, or a filtered index for a specific skewed value.

```sql
-- Most rows have IS_DELETED = 0; only a few have IS_DELETED = 1
CREATE NONCLUSTERED INDEX IX_ORDER_IS_DELETED
    ON HS_XX_ORDER (IS_DELETED)
    WHERE IS_DELETED = 1; -- filtered index, small and highly selective
```

### 6.15 Correlated Subqueries vs. JOIN

- **[SHOULD] `PERF-15`** Prefer a set-based `JOIN` with aggregation over a correlated subquery, which re-executes once per outer row.

```sql
-- Bad — subquery re-executed per outer row
SELECT c.CUSTOMER_ID, c.NAME,
    (SELECT SUM(o.TOTAL_AMOUNT) FROM HS_XX_ORDER o WHERE o.CUSTOMER_ID = c.CUSTOMER_ID) AS TOTAL_AMOUNT
FROM HS_XX_CUSTOMER c;

-- Good — set-based aggregation with a join
SELECT c.CUSTOMER_ID, c.NAME, SUM(o.TOTAL_AMOUNT) AS TOTAL_AMOUNT
FROM HS_XX_CUSTOMER c
LEFT JOIN HS_XX_ORDER o ON o.CUSTOMER_ID = c.CUSTOMER_ID
GROUP BY c.CUSTOMER_ID, c.NAME;
```

### 6.16 Right-Sized Data Types

- **[MUST] `PERF-16`** Use appropriately small types where the domain is genuinely bounded — for example, a human age realistically fits `0`–`255`, so `TINYINT` is the appropriate type rather than defaulting to a larger one.
- **[SHOULD] `PERF-17`** Prefer `VARCHAR` over `CHAR` unless the value is genuinely fixed-width — `CHAR` pads to its declared length and wastes space otherwise. Use `CHAR` only with care, since `VARCHAR` is the better default.

### 6.17 Guard Aggregates on Large OLTP Tables

- **[MUST] `PERF-18`** Aggregate functions (`MAX`, `MIN`, `SUM`, `COUNT`, `AVG`) must not be executed against large OLTP tables without proper filtering and indexing — an unfiltered aggregate causes a full table scan, high I/O, and performance degradation for other concurrent workloads. Every aggregate query must be supported by an appropriate index or a partition-pruning strategy.

## 7. Responsibilities

| # | Task | Responsibility |
| --- | --- | --- |
| 7.1 | Maintain SQL script naming conventions | DBA Team & Developer Team |
| 7.2 | Create SQL scripts according to the given standards | Developer Team |
| 7.3 | Maintain better-performing queries | DBA Team & Developer Team |

**Table 1: Responsibilities — SQL Script standard maintenance**

---

## Appendix A: Quick-Reference Checklist

Every rule below is a **[MUST]** from the body of this document, listed by ID for fast lookup during review. A machine-readable export — `{id, level, category, section, summary}` per rule — is maintained alongside this document at `CLDL2SQL_SCRIPT_CONVENTION.rules.json`, for tooling and AI agents that want structured access instead of parsing markdown. If the two ever disagree, this document is authoritative.

**Naming:** `NC-01` ≤30 character names · `NC-02` singular objects · `NC-03`/`NC-04` `HS_` + module-alias prefix · `NC-05` `VW_` view prefix · `NC-06` `SP_` procedure prefix · `NC-07` client/locale suffix · `NC-08` uppercase names

**Script execution & deployment:** `DEP-01` data types within engine range · `DEP-02` FK type matches parent exactly · `DEP-03` check-and-drop before create · `DEP-04` idempotent/re-runnable scripts · `DEP-05` explicit column list + guarded inserts · `DEP-06` PK-only existence check for re-runnable inserts · `DEP-07` one attribute per `ALTER TABLE` statement · `DEP-08` `GO` batch separator required · `DEP-09` `SELECT 1` not `SELECT *` in existence checks

**Performance:** `PERF-01` no functions on indexed columns · `PERF-02` no leading wildcards · `PERF-03` matching data types (no implicit conversion) · `PERF-04` no `SELECT *` · `PERF-05` `EXISTS` not `COUNT(*)` · `PERF-08` filter early · `PERF-09` index sargable predicates · `PERF-16` right-sized types · `PERF-18` guard aggregates on large OLTP tables

## Appendix B: Acronyms

| Acronym | Meaning |
| --- | --- |
| HBS | hSenid Business Solutions PLC. |
| DB | Database |
| DBA | Database Administrator |

**Table 2: Acronyms**

## Appendix C: Supporting Document Templates

| Document | Template Name | Template |
| --- | --- | --- |
| | | |

**Table 3: Supporting Document Templates**

## Appendix D: Editorial Notes — Corrections Applied During This Restructure

This appendix records every substantive correction made while reframing the source document, so the change is auditable rather than silent. It is not itself a standard.

1. **Duplicate performance rules consolidated.** The source stated several performance rules twice under different numbering (e.g. "No Functions on Indexed Columns" and "4.4.16 Non-sargable predicates"; "Avoid Leading Wildcards" and "4.4.21"; "Match Data Types Exactly" and "4.4.17"; "EXISTS over COUNT(*)" and "4.4.18"; "UNION ALL" and "4.4.7"/"4.4.19"; "Clustered index choice" and "4.4.25"; "Covering index awareness" and "4.4.12"). Each pair has been merged into a single rule (`PERF-01`, `PERF-02`, `PERF-03`, `PERF-05`, `PERF-06`, `PERF-12`, `PERF-09`/`PERF-10` respectively), keeping the more detailed of the two original write-ups.
2. **Section-numbering collision.** The source used the prefix `4.4.x` twice for two unrelated things — the performance bullet list (`4.4.6` through `4.4.27`) and, separately, the Responsibilities matrix items (`4.4.1`–`4.4.3`). It also referenced `4.3.2.2` with no corresponding `4.3.1`/`4.3.2.1`. Numbering has been replaced with the stable rule-ID scheme (`NC-`, `DEP-`, `PERF-`) used throughout this document, which doesn't depend on section position.
3. **Broken cross-reference.** The Definitions section said "Please refer to the Table 4 in the acronym section," but the acronym table is Table 3 (now Table 2 in this restructure) — Table 4 does not exist. Corrected to reference the correct table.
4. **Version number mismatch.** Document Control listed Version 1.0.0 while Version History only ever recorded a 0.1.0 row for that same content, with different dates given in each place (17 Feb 2025 vs. 5 Mar 2025). Neither could be resolved without more information, so both fields are marked TBD/flagged rather than guessed — see the Version History table above.
5. **Data-type example contradiction.** In the foreign-key type-matching example, the prose stated the old `EMP_NUMBER` size was `VARCHAR(4)` while the T-SQL example's `ELSE` branch actually created `VARCHAR(6)`. Resolved in favor of the code, per your confirmation — the prose now says `VARCHAR(6)`, and the table name typo `HS_HS_EMPLOYEE` has been corrected to `HS_HR_EMPLOYEE`.
6. **Broken example syntax.** Several code examples used Word's curly/smart quotes (`'…'`) instead of valid SQL straight quotes, which do not compile — e.g. `WHERE NAME='FN_XX_X'`, `CREATE TABLE HS_TD_XX_XX'()`. The `CREATE FUNCTION` example was also incomplete (`CREATE FN_XX_XX ... RETURN()` is not valid syntax — missing the `FUNCTION` keyword, a return type, and a valid `RETURN` expression). All examples in §5 have been corrected to valid, runnable T-SQL, using placeholder object names consistent with the naming convention in §4.
7. **Legacy vs. modern catalog views.** The source mixed the deprecated `SYSOBJECTS` compatibility view with the modern `sys.objects`/`sys.columns` catalog views across different examples. Standardized on `sys.objects`/`sys.columns` throughout, consistent with current SQL Server versions (2022+).
8. **Self-contradicting naming example.** The example given for the module-alias rule (`NC-04`) was `HS_OFB_EMP_DOCS`, which itself violates the singular-naming rule (`NC-02`) two bullets above it. Corrected to `HS_OFB_EMP_DOC`.
9. **Undocumented stored-procedure convention.** The source never stated a naming rule for stored procedures, but one example used `SP_HS_TNA_CLOCK_PHIL`. Per your confirmation, this has been formalized as an explicit rule (`NC-06`) rather than left implicit.
10. **Re-runnable insert rule relocated.** The source stated the "primary-key-only in the `IF NOT EXISTS` `WHERE` clause" rule under Performance (item 24 in the source numbering), but it is a deployment/idempotency concern rather than a query-performance one. Moved to §5.4 (`DEP-06`) and cross-referenced from the performance section's scope note.
11. **Truncated source content.** The source document's final performance bullet ("At the deployment, when writing queries such as with if exists...") cut off mid-sentence and mid-example (`IF NOT EXISTS(SELECT * FROM SYSOBJECTS WHERE NAME= 'OBJECTNAME')` ... `IF NOT EXISTS(SELECT 1 FROM SYSOBJECTS W`), followed by a stray, empty numbered list item. The underlying rule ("use `SELECT 1`, not `SELECT *`, in existence checks") was already fully expressed earlier in the source's own idempotent-script and re-runnable-insert examples, so it has been captured cleanly as `DEP-09` without needing to guess at the missing text.
12. **Inconsistent identifier casing in illustrative examples — resolved.** §4 mandates uppercase, underscore-delimited, `HS_`-prefixed object names, but the source's own Performance section examples used an unrelated mixed-case style (`DepartmentCode`, `EmployeeID`, `Orders`) with no module prefix. All identifiers in §6 have now been normalized to match §4: real, already-established entities reuse the exact names used elsewhere in this document (`HS_HR_EMPLOYEE`, `EMP_NUMBER`), while generic illustrative tables not tied to a specific module reuse the `HS_XX_` placeholder pattern already established by `NC-03`/`DEP-03` (e.g. `HS_XX_ORDER`, `HS_XX_CUSTOMER`) — singular per `NC-02`, uppercase per `NC-08`.
13. **Declared categories vs. actual structure.** The source's introduction stated conventions fall into three areas — "Naming conventions," "Performances," and "Limitations" — but "Limitations" was never given as its own section; its content was folded into an unlabeled "Other standards" section together with unrelated deployment/idempotency material. This restructure replaces "Other standards" with the explicit §5 "Script Execution & Deployment Standards," which is what that content actually covers.
14. **`SELECT *` inside a "Good" example.** While normalizing §6.2's Full-Text Search example, the source's own "Good" example used `SELECT * FROM dbo.Customers WHERE CONTAINS(...)` — directly contradicting `PERF-04` ("never use `SELECT *`") two subsections later in the same document. Corrected to name explicit columns, consistent with `PERF-04`.


