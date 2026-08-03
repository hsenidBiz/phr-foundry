# Strict HRM-DB SQL Rules

Use these self-contained rules for every generated or reviewed deployment script. Apply strict patterns only to agent-generated `IF EXISTS` / `IF NOT EXISTS` conditions and required deployment scaffolding. Preserve every user-supplied SQL statement exactly. Never enhance, optimize, normalize, reformat, shorten, or replace supplied SQL.

## Deployment and traceability

- Work in `src/PeoplesHR/Current/<MODULE>/`. Name root scripts `<INDEX>_<CR|CRB|RM|QRB>_<FEATURE_ID>_<TASK_ID>_<MODULE>.sql`.
- Calculate the index from numeric root SQL files in that module only; ignore localization and malformed files. Register the exact file name exactly once in `src/PeoplesHR/Current/dep.xml`, immediately before the first Version record.
- Use matching BEGIN/END banners with creation date, module, type, task ID, and author.

## Source preservation

- Copy supplied statements unchanged. Do not add, remove, reorder, or rename columns, values, predicates, clauses, aliases, or batches.
- Do not treat examples in these references or the repository as canonical statement shapes.
- Add guards and scaffolding around the supplied SQL; do not reconstruct supplied SQL inside a preferred template.
- If supplied SQL already contains an unsafe or noncompliant guard, broad data change, or ambiguous key, stop and request corrected SQL rather than changing it.
- Before completion, compare source and output statements line by line and verify every `INSERT` has the same ordered columns and corresponding values.

## Generated data guards

- Never generate a blind `INSERT`. Use `IF NOT EXISTS` with the true business identity, never every inserted value. `HS_CLIENT_APPSETTING` uses `CA_PARENTID`, `CA_MODULEID`, and `CA_KEY`; `HS_SM_MNUITEM_V5` uses `MNUITEM_ID`.
- Generate an `UPDATE` guard using the full business key and target-state condition; provide before/after validation and a rollback note without changing the supplied `UPDATE`.
- Do not proceed with a broad `DELETE`. Prefer user-supplied deactivation SQL. A required delete needs explicit approval, dependency checks, exact keys, validation, and rollback.

## Generated DDL scaffolding

- Guard table creation with schema-aware `SYS.OBJECTS`. Guard column creation or alteration with `INFORMATION_SCHEMA.COLUMNS` scoped by schema, table, and column.
- Require an approved `--@diagram:` ER group for table/column DDL. Add rerunnable `MS_Description` blocks adjacent to the DDL; describe every created or modified column and describe a table only when the script creates it.
- Use `IF EXISTS` / `sp_updateextendedproperty` / `ELSE` / `sp_addextendedproperty`; never generate standalone `sp_addextendedproperty`.
- Emit the table description and every column description as separate, self-contained add-or-update blocks. Use literal table and column names in each block.
- Never stage descriptions in a temporary table, table variable, `VALUES` dataset, or similar structure. Never use a cursor, loop, dynamic SQL, or any iteration mechanism to apply descriptions. The diagram framework requires each column description to be defined individually.
- Guard object replacement with type-correct, schema-aware `SYS.OBJECTS` checks: `V`, `P`, `FN`/`IF`/`TF`, or `TR`. Preserve the supplied object definition and record dependency and permission risks.
- Guard indexes through `sys.indexes`; check for duplicate key-column indexes. Add named constraints only after metadata, referenced-object, and existing-data validation.

## Localization and HS_FORM_LABEL_MAP

- Ask whether languages beyond English are required for every label insert or update. If yes, collect languages/regions, then discover culture codes from relevant label statements in the target module before matching folders in other modules.
- Use unambiguous repository evidence automatically. Ask for a culture code only when evidence is absent or conflicts.
- Generate `HS_FORM_LABEL_MAP` insert guards with exactly this identity and no other predicates:

```sql
IF NOT EXISTS (
    SELECT 1
    FROM HS_FORM_LABEL_MAP
    WHERE FLM_LABEL_KEY = '<key>'
      AND FLM_LABEL_CULTURE = '<culture>'
      AND FLM_LABEL_TYPE = '<type>'
)
```

- Never alter the supplied English label statement. For a requested localized copy, preserve the complete statement shape and change only the culture and translated label value.
- Prepare a label validation query by key and type for the final response or PR review notes only. Never append an agent-generated validation `SELECT` to a root or localization SQL file.

## Required review evidence

- Provide validation queries for every changed object, row, label, index, constraint, and extended property in the final response or PR review notes.
- Do not write agent-generated validation, diagnostic, verification, or result-preview `SELECT` statements into deployment SQL files. A `SELECT` may remain in a deployment file only when it was part of the user's immutable source SQL or is structurally required inside a generated existence guard.
- Record risks and rollback for updates, deletes, drops, constraints, data-moving/defaulted DDL, and object replacement.
- Stop for ambiguous business keys, ER groups, localization scope, destructive intent, dependencies, descriptions, and exceptions.

## Approved ER groups

Absence; Attendance; Benefit Management; Canteen Management System; Chatbot; Common Controls; Dashboard; Data Import; Disciplinary; Document Management System; EHRM; EIM Admin; ELC; ESM; Eligibility Module; Employee Information; Enterprise Dashboard; Extension Manager; Formula Builder; Grievance; Job Scheduler; Offboarding; On Demand Reports; Onboarding; Org Chart; Payroll; Performance Assessment; Probation Evaluation; Recruitment; Report Navigator; Report Scheduler; Request Tracker; Simulator; Survey Tool; Template Designer; Time Sheet; Training & Development; Web Loan; Widgets; Workflow; Workforce Planning; Al Insight; Skill Map Workspace Assignment.
