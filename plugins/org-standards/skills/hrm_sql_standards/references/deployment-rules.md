# Portable HRM-DB Deployment Rules

- Work under `src/PeoplesHR/Current/<MODULE>/`. Calculate indexes from numeric-prefixed SQL files in that module root only; ignore nested localization files. Preserve observed suffix and zero-padding style.
- Use only `CR`, `CRB`, `RM`, or `QRB`. Register each new root script by exact filename once in `src/PeoplesHR/Current/dep.xml`, immediately before the first Version entry.
- Add standard BEGIN/END traceability banners around the unchanged source SQL.
- Treat supplied SQL as immutable. Do not enhance, optimize, normalize, reformat, shorten, or rebuild it from an example. Add only generated guards and required deployment scaffolding.
- Use real business identities in generated guards: parent/module/key for `HS_CLIENT_APPSETTING`; label key/culture/type for `HS_FORM_LABEL_MAP`; `MNUITEM_ID` for `HS_SM_MNUITEM_V5`.
- Stop and request corrected source SQL for broad or unsafe updates/deletes, ambiguous business keys, or noncompliant user-supplied guards. Do not silently repair the statement.
- Generate DDL guards through `INFORMATION_SCHEMA.COLUMNS`, `SYS.OBJECTS`, `sys.indexes`, or constraint metadata as appropriate. Add required diagram and extended-property scaffolding without changing the supplied DDL.
- Define table and column `MS_Description` values in separate, self-contained add-or-update blocks. Repeat the complete block per column; never use temporary tables, table variables, datasets, cursors, loops, dynamic SQL, or shared iteration.
- Preserve supplied procedure, view, function, and trigger definitions. Add type-correct replacement guards and disclose dependency or permission risks.
- For label changes, collect English-only or required languages/regions. Discover cultures from relevant `HS_FORM_LABEL_MAP` statements in the target module first and other modules second; ask only when evidence is missing or conflicting.
- For localized copies, retain the source column/value shape and change only culture and translated label value.
- Keep generated validation and diagnostic queries in the final response or PR notes. Do not append them to root or localization SQL files unless they were supplied by the user; existence-guard subqueries are the only generated `SELECT` statements allowed in those files.
- Validate all changes using repository search, file inspection, XML inspection, and final diffs. Check the source SQL line by line against the root script before reporting completion.
- Approved ER groups: Absence; Attendance; Benefit Management; Canteen Management System; Chatbot; Common Controls; Dashboard; Data Import; Disciplinary; Document Management System; EHRM; EIM Admin; ELC; ESM; Eligibility Module; Employee Information; Enterprise Dashboard; Extension Manager; Formula Builder; Grievance; Job Scheduler; Offboarding; On Demand Reports; Onboarding; Org Chart; Payroll; Performance Assessment; Probation Evaluation; Recruitment; Report Navigator; Report Scheduler; Request Tracker; Simulator; Survey Tool; Template Designer; Time Sheet; Training & Development; Web Loan; Widgets; Workflow; Workforce Planning; Al Insight; Skill Map Workspace Assignment.
