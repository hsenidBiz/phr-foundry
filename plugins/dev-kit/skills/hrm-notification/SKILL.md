---
name: hrm-notification
description: Build an email notification for any PeoplesHR/eHRM module using the Job Scheduler (HRM-JS45-SERVICE). Use when asked to send an alert, notification, reminder or email when something happens in a module — approval, submission, acknowledgement, expiry, escalation. Covers the four-view contract, the claim column, HS_HR_JS_TYPE / HS_HR_JS_MAIL_CONFIG rows and the HTML template.
---

# PeoplesHR notifications via the Job Scheduler

**PeoplesHR modules do not send email from the web application.** `HRM-JS45-SERVICE`
(`https://dev.azure.com/PeoplesHR/HRM/_git/HRM-JS45-SERVICE`) polls the database on a frequency and
sends. A notification is therefore **data, not code**: four views, one claim column, two configuration
rows and one HTML file.

**Write no C# for a notification.** If you find yourself adding a mail call to a service class, stop —
that is not how this product sends mail, and it will not survive a module upgrade.

---

## The mechanism

One **claim column** on the source table is the entire state machine. NULL means *not yet sent*. The
scheduler stamps it after a successful send, and `WHERE <claim> IS NULL` in every view is the only
thing that stops a row mailing twice.

Four views, joined by the scheduler on `JS_ID`:

| View | MUST return | Bound to |
|:---|:---|:---|
| `..._PEN` | `JS_ID` | `HS_HR_JS_TYPE.JSTYP_PENDING_VIEW_NAME` |
| `..._ADD` | `ADDRESS`, `TYPE` (`'FROM'` / `'TO'`), `JS_ID` | `HS_HR_JS_MAIL_CONFIG.JSMAILCON_ADDRESS_VIEW` |
| `..._DAT` | `JS_ID` + one column per `@TOKEN` in the HTML | `HS_HR_JS_MAIL_CONFIG.JSMAILCON_DATA_VIEW` |
| `..._UPD` | `JS_ID`, `JSHIS_ID` | `HS_HR_JS_TYPE.JSTYP_UPDATE_VIEW_NAME` |

> [!CAUTION]
> **All four views MUST carry byte-identical `WHERE` clauses.** If the predicates drift, a row appears
> in one view and not another, and the job either mails with empty merge fields or **never stamps the
> claim column and mails the same row on every pass, forever**.
>
> This failure is **silent** — all four views still compile and the job still runs. Never leave it to
> review; check it mechanically (see *Verification*).

The HTML body is a **file on the scheduler host**, referenced by **filename only** in
`JSMAILCON_BODY_TEXT`, with `JSMAILCON_ISHTML_FLG = 1`. Merge tokens are `@COLUMN_NAME`.

---

## Procedure

### 0. Check whether the job already exists — do this FIRST

The base product ships notifications for many modules already, and a client may have several more.
Building a duplicate, or repointing someone else's views, is the most expensive mistake here.

```sql
-- existing jobs whose pending view touches your table/module (adjust the LIKE)
SELECT T.JSTYP_ID, T.JSTYP_NAME, T.JSTYP_ISACTIVE_FLG, T.JSTYP_PENDING_VIEW_NAME,
       T.JSTYP_UPDATE_VIEW_NAME, T.JSTYP_LAST_DATE,
       M.JSMAILCON_ADDRESS_VIEW, M.JSMAILCON_DATA_VIEW, M.JSMAILCON_BODY_TEXT
FROM HS_HR_JS_TYPE T
LEFT JOIN HS_HR_JS_MAIL_CONFIG M ON M.JSMAILCON_ID = T.JSMAILCON_ID
WHERE T.JSTYP_PENDING_VIEW_NAME LIKE '%<YOUR_TABLE_FRAGMENT>%';

-- claim columns already on your source table: look for JSHIS_ID%
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '<YOUR_TABLE>' AND COLUMN_NAME LIKE 'JSHIS%';

-- the base view definitions, if any (the definition is where the real predicate lives)
SELECT TABLE_NAME, VIEW_DEFINITION FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_NAME LIKE '%<YOUR_TABLE_FRAGMENT>%';
```

Three outcomes:

- **An existing job already does what you need** → configure, do not build. Check `JSTYP_ISACTIVE_FLG`.
- **An existing job fires on a DIFFERENT event** → build a **second parallel quartet**. Never narrow an
  existing view's `WHERE` to fit your trigger: base views are shared by every client on that schema.
- **Nothing exists** → build from scratch.

Report which of the three it is before writing anything.

### 1. Settle these facts before writing SQL

| Fact | Why it decides the design |
|:---|:---|
| **Source table and its PK** | becomes `JS_ID` |
| **The trigger** — exactly which column values mean "send now" | becomes the shared `WHERE` clause |
| **Recipient** — requester? approver from `HS_HR_WF_MAIN`? HR? a fixed address? | shapes the `_ADD` view's joins |
| **Merge fields** the mail must show | become `_DAT` columns and `@TOKEN`s |
| **Which repo owns the module** | the HTML file goes in that repo's root `alerts/` folder |
| **Is the scheduler deployed for this client at all?** | if not, nothing sends and you must say so |

If the trigger or recipient is ambiguous, ask. Everything else you can decide.

### 2. Claim column

```sql
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
               WHERE TABLE_NAME = '<TABLE>' AND COLUMN_NAME = '<CLAIM_COL>')
BEGIN
    ALTER TABLE <TABLE> ADD <CLAIM_COL> numeric(18) NULL;
    PRINT 'Added column <CLAIM_COL>';
END
ELSE PRINT 'Column <CLAIM_COL> already exists - skipped';
GO
```

- Name it `JSHIS_ID_<EVENT>` — the house convention (`JSHIS_ID_ACKNOW`, `JSHIS_ID_ALERT`).
- **Match the type of the claim column already on that table** if there is one. Old samples use
  `varchar(100)`; most real ones are `numeric(18)`. The table's own neighbour wins over any sample.
- **No backfill, normally.** A backfill stamps historic rows as "already notified". Decide explicitly
  and say which you chose: leaving them NULL means they all mail on the first pass.

### 3. The four views

Use `reference/views-template.sql`. Non-negotiable rules:

- The `WHERE` clause is **written once and pasted four times**, unchanged.
- Compare `varchar` flag columns to **strings** (`= '1'`), never to integer literals. Comparing a
  varchar column to an int makes SQL Server convert the *column*, which throws on the first
  non-numeric value anyone stores.
- **Format dates in the view**: `CONVERT(varchar, <col>, 103)`. The scheduler does no formatting — an
  unformatted datetime reaches the recipient as `2026-08-24 14:31:07.123`.
- Joins that could **drop** a row (a missing branch, a missing designation) must be `LEFT` with a
  `COALESCE` default. A row present in `_PEN` but absent from `_DAT` is predicate drift by another name.
- Joins that **must** exist (the recipient's employee row) stay `INNER`: no employee row means no
  address, and dropping the row from all four views leaves the claim NULL so it retries.
- Guard each view with `IF OBJECT_ID(...) IS NOT NULL DROP VIEW ...` so a re-run replaces rather than
  fails. Note in the script that this is the one non-additive part.
- **Naming.** Follow the client's convention. Many client-specific PeoplesHR objects carry a client
  suffix (a short client code, e.g. `_ABCD`); check what the neighbouring views in that database use. Without
  it, your views look like base objects to the next upgrade.

### 4. The HTML template

Copy `reference/alert-template.html` into the **module repo's root `alerts/` folder** — the product
convention (`HRM-ELC45-MVC/alerts/`, `HRM-BENEFIT45-MVC/alerts/`, `HRM-OFFBOARDING35-WEB/alerts/`).
Create the folder if the repo has none.

- Every `@TOKEN` must match a `_DAT` column name **exactly**. An unmatched token is not an error — it
  renders **literally** in the delivered mail.
- **English only.** The scheduler reads a flat file and has no culture dimension, so
  `HS_FORM_LABEL_MAP` localisation does not reach the mail body. If the module is localised, record
  this as a deliberate divergence rather than letting it look like an oversight.

### 5. Configuration rows

Use `reference/config-template.sql`.

- `JSMAILCON_ID` and `JSTYP_ID` are `numeric(18)` **non-identity** PKs. Compute both with
  `COALESCE(MAX(id) + 1, 0)`. A bare `MAX(id) + 1` yields NULL against a non-nullable PK on an empty
  table — old samples get this wrong for `HS_HR_JS_TYPE` while getting it right for the mail config.
- The `FROM` address comes from an `HS_PR_PARAMETERS` row that the `_ADD` view selects as a scalar.
  **Give each job its own parameter key.** Sharing one means changing one notification's sender
  silently changes the other's. Seed it guarded — an unguarded insert duplicates on re-run, and
  `PAR_NAME` is a `varchar(50)` primary key.
- Guard the whole block on **`JSTYP_PENDING_VIEW_NAME`**, not on `JSTYP_NAME`. The view name binds the
  job to the scenario; the display name can be edited in the Job Scheduler UI, and a guard on it lets a
  re-run after a rename create a second copy of everything.
- `JSFREQ_ID` must reference an existing `HS_HR_JS_FREQUENCY` row — check what is there rather than
  assuming `1`.

### 6. Verification

Run every one of these. Do not report success on the strength of the script parsing.

```sql
-- 1. all four views exist
SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME IN (<the four>);   -- expect 4

-- 2. THE PREDICATE CHECK - the silent one. Expect 4.
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS
WHERE TABLE_NAME LIKE '<view prefix>%'
  AND VIEW_DEFINITION LIKE '%<the exact shared WHERE clause>%';

-- 3. the job is wired to all four views and active
SELECT T.JSTYP_NAME, T.JSTYP_ISACTIVE_FLG, M.JSMAILCON_BODY_TEXT
FROM HS_HR_JS_TYPE T INNER JOIN HS_HR_JS_MAIL_CONFIG M ON M.JSMAILCON_ID = T.JSMAILCON_ID
WHERE T.JSTYP_PENDING_VIEW_NAME = '<..._PEN>';

-- 4. the sender resolves (NULL or blank means mail with no FROM)
SELECT PAR_VALUE FROM HS_PR_PARAMETERS WHERE PAR_NAME = '<your key>';

-- 5. the four views AGREE on a live row - trigger one, then run this
SELECT 'PEN' AS V, JS_ID FROM <..._PEN>
UNION ALL SELECT 'ADD', JS_ID FROM <..._ADD>
UNION ALL SELECT 'DAT', JS_ID FROM <..._DAT>
UNION ALL SELECT 'UPD', JS_ID FROM <..._UPD>
ORDER BY JS_ID, V;
-- expect 5 rows per pending item: PEN/DAT/UPD once each, ADD twice (FROM + TO)
```

Also, mechanically both ways: **every `@TOKEN` in the HTML has a `_DAT` column, and no `_DAT` column
except `JS_ID` lacks a token.**

And `SET PARSEONLY ON` over every `GO`-separated batch of the script.

End to end, once deployed: trigger the event, confirm **one** mail arrives at the right address, confirm
the claim column is stamped, then **run the job again and confirm no second mail**. That last one is the
whole point of the claim column and is worth proving deliberately.

### 7. Hand over what is outside the database

State both of these explicitly in the deliverable — a script that "passes" while these are undone looks
finished and is not:

1. **The HTML template must be deployed to the scheduler host's alert directory.** If it is absent the
   job sends an empty body **and still stamps the claim column**, so the failure cannot be retried per
   row except by clearing the claim by hand.
2. **`HRM-JS45-SERVICE` must actually be running against that database.** If it is not, rows accumulate
   unclaimed and nothing sends, with no error anywhere.

---

## Traps

Collected from real defects in shipped sample scripts. Check each before handing over.

| Trap | What happens |
|:---|:---|
| A typo between the `INFORMATION_SCHEMA` guard and the `ALTER TABLE ADD` column name | Guard passes, wrong column added, every view references a column that does not exist. A real sample ships `JSHIS_ID_ALERT` vs `JSHIS_ID_ALER`. |
| Bare `MAX(JSTYP_ID) + 1` | NULL into a non-nullable PK on an empty table |
| Unguarded `INSERT INTO HS_PR_PARAMETERS` | PK violation on the second run |
| Predicates drift between the four views | Silent: empty merge fields, or mails forever |
| `varchar` flag compared to an int literal | Conversion error on the first non-numeric value |
| Unformatted datetime in `_DAT` | Raw `yyyy-MM-dd HH:mm:ss.fff` in the mail |
| Copying the sample's recipient join | The Benefit sample mails the **approver**. Most notifications want the **requester**. Check the requirement wording. |
| Repointing a base view to fit your trigger | Silently removes that notification for every client on the schema |
| Assuming the scheduler runs in this environment | Everything "works" and nothing is ever sent |
| Adding a backfill by reflex | Marks historic rows as already notified, or mails all of them at once |

## Reference files

- `reference/views-template.sql` — the four views, parameterised
- `reference/config-template.sql` — claim column, parameter row, `HS_HR_JS_*` rows
- `reference/alert-template.html` — the house alert layout with merge tokens

## Schema notes

`HS_HR_JS_TYPE` — `JSTYP_ID numeric(18)` PK non-identity, `JSTYP_NAME`, `JSTYP_ACTION int`,
`JSTYP_PENDING_VIEW_NAME`, `JSMAILCON_ID`, `JSFREQ_ID`, `JSTYP_ISPROCESSING_FLG smallint`,
`JSTYP_UPDATE_VIEW_NAME`, `JSTYP_ISACTIVE_FLG smallint`, plus `JSTYP_NEXT_DATE` / `JSTYP_LAST_DATE`
and optional `JSSMSCON_ID` / `JSCALCON_ID` / `SPCON_ID` / `REFCON_ID` for non-mail job types.

`HS_HR_JS_MAIL_CONFIG` — `JSMAILCON_ID numeric(18)` PK non-identity, `JSMAILCON_NAME`,
`JSMAILCON_SUBJECT`, `JSMAILCON_ADDRESS_VIEW`, `JSMAILCON_DATA_VIEW`,
`JSMAILCON_DATA_REPEATED_VIEW`, `JSMAILCON_ISHTML_FLG smallint`, `JSMAILCON_BODY_TEXT varchar(200)`,
`JSMAILCON_ATTATCHMENT_VIEW`, `JSMAILCON_SUBJECT_VIEW`, and report fields
`JSMAILCON_IS_REPORT` / `_REPORT_NAME` / `_REPORT_PARAVIEW` / `_RPRT_EXPT_TYP_EXT`.

`HS_HR_JS_FREQUENCY` — `JSFREQ_ID`, `JSFREQ_TYPE int`, `JSFREQ_FREQUENCY numeric(10,2)`, `JSFREQ_DESC`.

`HS_PR_PARAMETERS` — `PAR_NAME varchar(50)` PK, `PAR_VALUE varchar(250)`.

Target SQL Server compatibility is often **110** on these databases: no `STRING_AGG`, `STRING_SPLIT`,
`TRIM` or `OPENJSON`. Check before using them.
