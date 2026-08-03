# hrm_sql_standards

Prepares and reviews PeoplesHR **HRM-DB** MSSQL deployment scripts. It packages
user-supplied SQL under `src/PeoplesHR/Current/`, adds rerunnable guards and
deployment scaffolding, registers new root scripts in `dep.xml`, handles requested
localization, and performs PR-readiness checks. Supplied SQL is preserved exactly —
the skill never enhances, optimizes, or reformats it.

This skill ships inside the **`org-standards`** plugin, distributed via the
**`phr-foundry`** marketplace. Install and invoke it through Claude Code:

```shell
/plugin install org-standards@phr-foundry
```

Invoke explicitly with `/org-standards:hrm_sql_standards`, or let Claude load it
automatically when you create, convert, or review HRM-DB deployment SQL. Do not copy
`SKILL.md` on its own — the skill needs the whole folder, including `references/`.

## Prerequisites

- Complete source SQL is mandatory for creation or conversion.
- User name, feature ID, task ID, module/folder, and work-item type (`CR`, `CRB`,
  `RM`, or `QRB`) are mandatory.
- For an `HS_FORM_LABEL_MAP` insert or update, state whether other languages are
  required and list them when the answer is yes.

Provide prerequisites in any order. When information is missing, the skill asks once
for all missing items, then proceeds directly — no input-summary or confirmation gate.

## Input template

````text
Use /org-standards:hrm_sql_standards to create an HRM-DB deployment script.

User name:
Feature ID:
Task ID:
Module/folder:
Work-item type: CR | CRB | RM | QRB

For HS_FORM_LABEL_MAP inserts or updates:
Are other languages required? No | Yes
Required languages/regions: <complete only when Yes>

SQL:
```sql
<paste the complete SQL here>
```
````

## Minimal-input example

You may begin with only SQL:

```text
Use /org-standards:hrm_sql_standards to create a deployment script.

INSERT INTO HS_FORM_LABEL_MAP (...)
VALUES (...);
```

The skill responds with one consolidated request for the missing deployment details,
then inspects the repository and creates the changes immediately. It adds the strict
label guard around the unchanged insert; it does not replace your columns or values
with an example shape.
