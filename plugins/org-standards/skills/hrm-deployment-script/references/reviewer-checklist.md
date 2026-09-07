# DB Approver Best Practices

Confirm module/folder, work metadata, index evidence, filename, exact `dep.xml` placement, traceability banners, and source-SQL preservation. Never replace supplied SQL with a preferred example shape.

| Change | Reviewer expectation |
| --- | --- |
| Insert | Unchanged source statement inside a business-key `IF NOT EXISTS` generated when needed |
| Update | Unchanged source statement; full-key/state guard, before/after query, and rollback evidence |
| Delete | Stop for explicit approval, exact keys, dependencies, validation, and rollback |
| DDL | Unchanged source DDL with generated schema guard, diagram tag, and one separate description block per table/column |
| Object replacement | Unchanged definition with correct-type replacement guard and risk disclosure |
| Index/constraint | Unchanged source statement with metadata and data checks |

For every supplied statement, compare source and output line by line. For each `INSERT`, verify identical column count, order, value count, and corresponding values. Additional localized label statements may change only the culture and translated label value.

Reject description implementations that use temporary tables, table variables, datasets, cursors, loops, dynamic SQL, or any iteration mechanism. Require an explicit add-or-update block with literal names for each described column.

Require validation for changed objects/rows, confirmed localization scope for labels, exact unique deployment registration, and risks/rollback notes. Keep validation queries in the review output, not deployment or localization files. Reject any agent-added standalone `SELECT` that is not part of the user's source SQL or a generated existence guard. Stop for ambiguous keys, ER groups, localization evidence, destructive intent, dependencies, or any required change to user-supplied SQL.
