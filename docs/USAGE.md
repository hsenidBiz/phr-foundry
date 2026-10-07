# Using PHR-Foundry plugins

A short, practical guide for engineers. If you only want to *use* the plugins,
this page is all you need — the [root README](../README.md) covers maintaining
the marketplace itself.

> **Keep this page current.** When a plugin or skill is added, renamed, or
> removed, update the [Plugin catalog](#plugin-catalog) below in the same PR.

Repo layout note: the empty Azure template dirs `deps/`, `scripts/`, and `src/`
have been removed from the repo — they held nothing but placeholder READMEs.
`docs/` (this guide) is the only one that remains, since it holds real content.
See the [root README](../README.md#repository-layout) for the current layout.

---

## 1. Install

You need this once per machine. Point Claude Code at the repo URL — no clone
required.

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install dev-kit@phr-foundry
claude plugin install dba-kit@phr-foundry
claude plugin install org-standards@phr-foundry
```

`dev-kit` carries the build skills (deployment scripts, notifications, the ADO bug
fixer, the configuration document, the SDD); `dba-kit` carries the SQL standards
review and the `phx-dbexplorer` MCP server; `org-standards` carries
`phx-product-context`, the product-knowledge skill every role shares. Most
developers want all three.

The same commands work as slash commands inside a Claude Code session
(`/plugin marketplace add ...`, `/plugin install ...`).

**Business Analysts install `org-standards` and `ba-kit`**, which carries the FRD
authoring skill `phx-write-frd`:

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install org-standards@phr-foundry
claude plugin install ba-kit@phr-foundry
```

> **No plugin conflicts with another.** Up to `org-standards` `5.0.0` there were two
> product-knowledge skills — `phx-product-context` in `dev-kit` and
> `phx-business-context` in `org-standards` — that misrouted against each other, so
> the two plugins could not be installed together. `org-standards` `6.0.0` merged
> them into one `phx-product-context`, and that rule is gone: install whatever
> matches the work you do.

**If the first command hangs or fails on authentication**, your machine has no
cached GitHub credentials. Use the URL with the account prefix so Git knows
which account to prompt for:

```shell
claude plugin marketplace add https://hsenidBiz@github.com/hsenidBiz/phr-foundry
```

### Make it automatic for a whole project

Add this to the project's `.claude/settings.json` and commit it. Anyone who
trusts the project gets the marketplace registered and the developer plugins
enabled automatically. `enabledPlugins` only enables an **already-installed**
plugin, though — it does not install it — so the first person on the project still
has to run the `claude plugin install` commands once:

```json
{
  "extraKnownMarketplaces": {
    "phr-foundry": {
      "source": {
        "source": "git",
        "url": "https://github.com/hsenidBiz/phr-foundry"
      }
    }
  },
  "enabledPlugins": {
    "dev-kit@phr-foundry": true,
    "dba-kit@phr-foundry": true,
    "org-standards@phr-foundry": true
  }
}
```

## 2. Check what you have

```shell
claude plugin list                  # installed plugins and versions
claude plugin marketplace list      # marketplaces Claude Code knows about
```

## 3. Update

```shell
claude plugin marketplace update phr-foundry
claude plugin update dev-kit
claude plugin update dba-kit
claude plugin update org-standards
```

You will **only** receive a new version when the maintainer bumps `version` in
the plugin's `plugin.json`. New commits alone do not reach you — if you expect a
change and don't see it, ask the maintainer whether the semver was bumped.

## 4. Uninstall

```shell
claude plugin uninstall dev-kit
claude plugin uninstall dba-kit
claude plugin uninstall org-standards
```

---

## Plugin catalog

Each plugin serves one audience: `dev-kit` is for developers, `dba-kit` is for
database work, `ba-kit` is for Business Analysts, and `org-standards` is for every
role — it holds the shared product-knowledge skill. Install `org-standards` plus the
ones that match your role — and `dba-kit` if you touch the database.

### `dev-kit` — PeoplesHR developer build tooling

| Skill | Use it for |
| --- | --- |
| `hrm-deployment-script` | Creating, converting, and PR-reviewing re-runnable **HRM-DB MSSQL deployment scripts** and their `dep.xml` registration. |
| `hrm-notification` | Building an **email notification for any module** on the `HRM-JS45-SERVICE` Job Scheduler — the four views, the claim column, the `HS_HR_JS_*` configuration rows and the HTML template. Needs access to the client database. |
| `phx-debugger` | Fixing an **Azure DevOps bug end to end** from its ID — root cause investigation, fix plan, implementation, RCA onto the work item, status change. Needs the `superpowers` plugin and an Azure DevOps MCP server (see below). |
| `hrm-configuration-document` | Writing the **organization-standard Configuration Document** for a finished CR — turns rough developer notes into the house `.md`, then a branded `.docx` and PDF for the SharePoint "Module's Configuration Docs" library. Needs Python with `python-docx`; the PDF step needs Word on Windows. |
| `phx-write-sdd` | Writing the **Architecture / Solution Design Document** (`ARCH-`) for a feature — the technical companion to the BA's FRD. Reads the template and sample live from the PHR-X wiki every run, resolves the FRD's cross-module touchpoints into technical decisions, and never invents a table, column or endpoint. Needs an Azure DevOps MCP server (see below). |

| MCP server | Use it for |
| --- | --- |
| *(not shipped)* | `hrm-notification` and `hrm-deployment-script` want a database — install `dba-kit` too and use its [`phx-dbexplorer`](#phx-dbexplorer--database-schema-browsing). `phx-debugger` and `phx-write-sdd` both need your own Azure DevOps MCP server, which no `phr-foundry` plugin has ever shipped — it is the same server for both. |

> **The first four moved here from `org-standards` in its `3.0.0` release.** The
> skills themselves are unchanged; only the slash-command prefix changed, from
> `/org-standards:` to `/dev-kit:`.
>
> **`phx-product-context` left in `dev-kit` `3.0.0`.** It was merged with
> `phx-business-context` and now ships in
> [`org-standards`](#org-standards--peopleshr-product-knowledge-for-every-role) for
> every role. Install that plugin and use `/org-standards:phx-product-context`.
> `dev-kit` no longer declares the `weknora` MCP server.

#### What `hrm-deployment-script` does

Given SQL you supply, it packages that SQL as a deployment file under
`src/PeoplesHR/Current/<MODULE>/`, wraps it in re-runnable guards, adds
traceability banners, registers the new root script in `dep.xml`, and generates
localization files when you ask for them.

**It never rewrites your SQL.** No optimization, no normalization, no
reformatting — your statements are copied through byte-for-byte and only
deployment scaffolding is added around them. If a required safety guard can't be
applied without changing your SQL, it stops and asks you for corrected source.

#### How to invoke it

Explicitly:

```
/dev-kit:hrm-deployment-script
```

Or just describe the work — Claude loads the skill on its own when you're
creating, converting, or reviewing HRM-DB deployment SQL.

#### What it needs from you

Mandatory for creating or converting a script:

- The **complete source SQL** (it will not invent business SQL from a prose
  description)
- User name
- Feature ID
- Task ID
- Module / folder
- Work-item type — one of `CR`, `CRB`, `RM`, `QRB`

Additionally, if your SQL inserts into or updates `HS_FORM_LABEL_MAP`, say
whether other languages are required and list them.

You don't have to supply all of this up front. Paste the SQL and the skill will
ask once for everything missing, then proceed straight to the work — there's no
extra confirmation step after that.

#### Copy-paste template

````text
Use /dev-kit:hrm-deployment-script to create an HRM-DB deployment script.

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

#### Review-only mode

Say so explicitly — e.g. *"review these deployment files for PR readiness"* —
and it checks filenames and indexes, guards, banners, source-SQL preservation,
localization shape, and `dep.xml` placement without creating anything.

#### What you get back

A report covering: the metadata used, the index it detected, the file it created
and its `dep.xml` registration, the guards it added, a line-by-line confirmation
that your SQL is unchanged, localization results, validation queries (reported to
you, never written into the deployment files), and any risks or blockers.

---

#### What `hrm-notification` does

```
/dev-kit:hrm-notification
```

Plain language works too — *"send the approver an email when a claim is
submitted"*, *"remind staff whose probation expires next week"*. Anything that
asks for an alert, notification, reminder or email out of a module loads it.

**A PeoplesHR notification is data, not code.** The web application does not send
mail; `HRM-JS45-SERVICE` polls the database on a frequency and sends. So the
deliverable is four views, one claim column, two configuration rows and one HTML
file — and the skill will refuse to add a mail call to a C# service class, which
would not survive a module upgrade anyway.

**It checks whether the job already exists first**, before writing anything. The
base product ships notifications for many modules and a client may have added
more, so it queries `HS_HR_JS_TYPE` / `HS_HR_JS_MAIL_CONFIG` and reports which of
three situations you are in: an existing job already does this (configure it), an
existing job fires on a different event (build a second parallel set of views), or
nothing exists (build from scratch). It will **not** narrow an existing base
view's `WHERE` clause to fit your trigger — those views are shared by every
client on the schema.

#### What it needs from you

The source table and its primary key, the exact column values that mean "send
now", who receives the mail (requester, approver from `HS_HR_WF_MAIN`, HR, a fixed
address), the merge fields the mail must show, and which repo owns the module. If
the trigger or the recipient is ambiguous it asks; everything else it decides.

It also needs a database to inspect, for both the discovery queries and the
verification. The intended way to give it one is the
[`phx-dbexplorer`](#phx-dbexplorer--database-schema-browsing) MCP server — which
lives in `dba-kit`, not here, so install that plugin alongside `dev-kit`.

#### What you get back

The guarded claim-column `ALTER`, the four views (`_PEN`, `_ADD`, `_DAT`, `_UPD`)
sharing one byte-identical `WHERE` clause, the `HS_PR_PARAMETERS` sender row, the
`HS_HR_JS_TYPE` and `HS_HR_JS_MAIL_CONFIG` rows, an HTML template for the module
repo's `alerts/` folder, and the verification queries — including the mechanical
check that the four views have not drifted apart, which is the failure mode that
silently mails the same row on every pass, forever.

**Two things it cannot do for you**, and says so in the deliverable:

1. **Deploy the HTML template to the scheduler host's alert directory.** If the
   file is absent the job sends an empty body **and still stamps the claim
   column**, so the row cannot be retried without clearing the claim by hand.
2. **Confirm `HRM-JS45-SERVICE` is actually running against that database.** If it
   is not, rows accumulate unclaimed and nothing is sent, with no error anywhere.

> If you previously hand-copied this skill into your own `~/.claude/skills/`,
> delete that copy once the plugin ships it — otherwise both load and your skill
> list shows two near-identical entries.

---

#### What `phx-debugger` does

Open Claude Code in the repository you are debugging, then give it a bug ID:

```
/dev-kit:phx-debugger 141827
```

Plain language works too — *"fix ADO bug 141827"*. Either way the message must
carry the **bug ID**: it is the one required argument, the skill looks the work
item up by ID, and it will not go hunting for it by title. There is no code path
to pass — the working directory *is* the codebase. Add a path only for a
dependency that lives outside this repository.

**The project defaults to `HRM`.** Name one only when the bug lives elsewhere —
*"bug 141827 in Payroll"*, or paste the work item URL, which carries the project
in its path. If the ID is not in the project it tried, it says so explicitly —
*"Bug #141827 was not found in the `HRM` project"* — with the Azure DevOps error,
and waits for you to give it the right project name (or a corrected ID) before
fetching again. It never sweeps other projects looking for the ID.

Before investigating, it shows you what it fetched — title, state, a short
summary, attachment names — and **waits** for you to confirm it is the right bug.

**It moves the status twice.** Once it has read the bug and confirmed there is
enough to troubleshoot, it sets the work item to `Under Investigation`, so the
board shows the bug is being worked — a bug it cannot investigate is left exactly
as it found it. Later, once the fix is written and you confirm it works, it asks
and moves the work item to `Dev In Progress`. It does not gate on the state it
found — if the bug looks like someone else is already on it, it says so and
leaves the decision to you.

It reads the work item — description, comments, linked items and every attachment
— and decides whether there is enough to troubleshoot. If there is not, it asks
**you** first: it lists what it checked and the specific questions blocking it,
and waits. Answer any of them and it re-assesses and carries on — no waiting on
the reporter for something you already know. Only if you cannot answer either do
you tell it to post the questions as a comment on the work item, which ends the
run — and that comment always **@mentions whoever reported the bug**, so the
questions reach them instead of waiting to be noticed. It tells you who it will
mention before you agree, and never comments on the ticket unprompted. Then it **hands the bug to
the Superpowers `systematic-debugging` skill**, running in a subagent, which finds
the root cause and later writes the fix. `phx-debugger` itself never debugs and
never edits code: it owns Azure DevOps, your approval gates and the RCA. It
**stops** for you to approve the fix plan, and stops again for you to test the
diff. When it asks about the branch it also asks **where you will test the fix**
— the URL or site — so it can build the project that actually deploys the change
rather than only the project that contains it, and before handing the diff back
it checks by content hash that the binary the running app loads is the one it
just built. If it cannot confirm that, it tells you plainly that you may be
testing a stale binary. After you confirm the fix works it writes the full RCA into the work item's
`Custom.*` fields and moves the status to `Dev In Progress`, asking before each. It never commits,
pushes or opens a PR unless you say so.

There are no modes. How wide to search and whether to sweep the branches is the
investigation's call, and it reports what it checked and what it skipped.

**Four hard gates run before anything else** — a connected Azure DevOps MCP
server, the `superpowers` plugin, a valid bug ID, and a work item that actually
resolves. Any one of them failing ends the run with an explanation, having read
nothing and touched nothing. The two you install once:

1. The **`superpowers` plugin**:
   `/plugin install superpowers@claude-plugins-official`, then restart.
2. An **Azure DevOps MCP server**, which `dev-kit` deliberately does *not*
   ship — the org name and your sign-in are per-developer. Add it yourself:

   ```json
   {
     "mcpServers": {
       "ado": {
         "command": "npx",
         "args": ["-y", "@azure-devops/mcp", "PeoplesHR"]
       }
     }
   }
   ```

   Then `az login` and restart Claude Code. `/mcp` should show `ado` connected.

**Every** Azure DevOps operation goes through that server. The skill will not use
`az devops`, REST or a personal access token as a fallback — not even if you ask
it to. Calls run as *your* identity, so your existing ADO permissions apply
unchanged. Full prerequisites and troubleshooting:
[`plugins/dev-kit/skills/phx-debugger/INSTALL.md`](../plugins/dev-kit/skills/phx-debugger/INSTALL.md).
You do not install the skill separately — it arrives with `dev-kit`.

---

#### What `hrm-configuration-document` does

```
/dev-kit:hrm-configuration-document
```

Plain language works too — *"write the config doc for CR 116712"*, *"turn these
notes into a configuration guide"*. It also loads when you ask it to review or
update an existing configuration document.

It turns the notes a developer writes after finishing a CR into the house
Configuration Document: a `.md` in the standard structure and voice, a branded
`.docx` built from it, and a PDF for the SharePoint library. The audience is
implementation, support and client teams, so it strips code references (files,
classes, branches, PR numbers) and anything that looks like a credential.

**Every fact comes from the developer.** It never guesses a default value, a data
type, a navigation path, who configures a setting, or a user-facing message. When
one is missing it asks — one question at a time, with suggested answers and a
"leave it TBD" option. `[TBD - confirm with developer]` appears in the document
only where you chose TBD. It always asks whether there are screenshots, even when
you say you are in a hurry.

#### What it needs from you

- Your notes: rough English is fine. `assets/developer-input-template.md` in the
  skill folder lists what a complete set covers.
- Answers to its questions about the facts your notes leave out.
- Screenshots, if there are any, with one line saying what each shows.

To build the output:

- **Python** with `python -m pip install --user python-docx` for the `.docx`.
- **Microsoft Word on Windows** for the PDF. Without Word, open the `.docx`,
  update fields (Ctrl+A, F9) and save it as PDF yourself.

#### What you get back

- `<Release>-<WorkItemID>-<Module>-<Short Title>-Doc.md`, plus the same-named
  `.docx` and `.pdf`. The builder generates the cover, copyright page, table of
  contents, heading numbers, header and footer.
- The tier it chose (T1/T2/T3), which decides the required sections.
- A **Removed from notes** list (code references and secrets it took out). If it
  found an exposed password, rotate it.
- The TBD items, if you chose any.

The copyright page uses the official hSenid Business Solutions PLC wording,
kept in `assets/house.json` (one paragraph per line). Change it there, not in
the document.

---

#### What `phx-write-sdd` does

Authors the **SDD — Architecture / Solution Design Document**, the technical design
document for a PeoplesHR feature (`ARCH-` prefix). Drafted by the Solutioning
Engineer, accountable to the Solution Architect. Its business companion is the FRD,
which `ba-kit`'s [`phx-write-frd`](#what-phx-write-frd-does) writes.

**The template is not in the plugin.** The template and the filled sample are read
live from the PHR-X project wiki on **every run**, through your Azure DevOps MCP
server. There is no local copy, and no CLI, REST or PAT fallback — so a change to
the organization's standard reaches everyone the moment it is published, and a run
that cannot reach the wiki produces nothing rather than working from a remembered
structure.

#### How to invoke it

```
/dev-kit:phx-write-sdd
```

Or just describe it — *"write the solution design for the leave-encashment
feature"*. It also fires at the end of an architecture or grilling session when you
ask for the discussion to be written up, captured, or turned into an SDD: the
session transcript, and any ADRs or `CONTEXT.md` it produced, are legitimate input.

#### What it needs from you

**The first thing it does is ask.** It reads the wiki template, maps what you have
supplied onto the template's sections, and comes back with **one consolidated
question** listing every section it has no input for — by number. It waits for your
answers before drafting anything, rather than drafting the covered half and asking
about the rest.

Expect to be asked for:

| | |
| --- | --- |
| **The linked FRD** | §5 is the point of this document — every cross-module touchpoint the FRD recorded has to be resolved into a technical decision here. Without the FRD it asks rather than reconstructing the touchpoints. |
| **Document Control** | The SDD ID (`ARCH-<MODULE>-<YYYY>-<NNN>`), feature name, Solutioning Engineer and Solution Architect names, version, linked FRD ID, target wiki path. A design session never supplies these. |
| **The as-is schema** | Read from a repository file you name. It will not infer table or column names from a module name. |

It will not allocate the next document number for you, and it will **not** derive
the SDD's ID from the FRD's — the numbers often match, but that is a convention,
not a rule it may apply.

#### What you get back

A **markdown file in your repository** — `docs/sdd/<ARCH-ID>-<kebab-case-feature-name>.md`
by convention, or wherever your repo already keeps SDDs. Not a wall of text in the
chat: a 16-section document pasted into a conversation cannot be reviewed, diffed
or version-controlled.

**Writing the file is not publishing.** Nothing reaches the wiki until you ask for
it explicitly, and even then the skill shows you the exact path and content and
stops for your approval before any write — a wiki page is visible to the whole
organization the moment it lands. After publishing it re-reads the page to confirm
what actually landed, and says so plainly if someone else edited it in between.

Nothing in the document is invented. Where it has no input it stops and asks, and
it will not launder a guess by labelling it `[PROPOSED]`, `TBD` or `TODO`, or by
filing it under Open Questions — that table is for decisions the team genuinely has
not made, not for inputs you were never asked for.

Full prerequisites and troubleshooting:
[`plugins/dev-kit/skills/phx-write-sdd/INSTALL.md`](../plugins/dev-kit/skills/phx-write-sdd/INSTALL.md).
If you already set the Azure DevOps MCP server up for `phx-debugger`, you are done —
it is the same server.

---

### `dba-kit` — PeoplesHR database tooling

| Skill | Use it for |
| --- | --- |
| `phx-sql-standards-review` | Review-only sign-off on a T-SQL script against either the **OLD hSenid HRM** (.NET Framework) or **NEW PeoplesHR PHR-X** (.NET Core) SQL standard, auto-detecting which system it targets. Never edits the SQL. |

| MCP server | Use it for |
| --- | --- |
| `phx-dbexplorer` | Letting Claude browse your **SQL Server or PostgreSQL** schema — tables, columns, indexes, foreign keys, stored procedures, functions — without writing SQL by hand. |

> **Both moved here from `org-standards` in its `4.0.0` release.** The skill itself
> is unchanged; only the slash-command prefix changed, from
> `/org-standards:phx-sql-standards-review` to
> `/dba-kit:phx-sql-standards-review`. `phx-dbexplorer` now registers under
> `dba-kit`, so if you were using it through `org-standards`, run
> `claude plugin install dba-kit@phr-foundry` and restart Claude Code.

> `dev-kit`'s `hrm-notification` and `hrm-deployment-script` want a database to
> inspect — `phx-dbexplorer` is what gives them one, which is why most developers
> install `dba-kit` alongside `dev-kit`.

#### What `phx-sql-standards-review` does

Review-only sign-off on a T-SQL script — it never edits your SQL, only reports
against the standard. There are two independent standards, one per system:
the **OLD hSenid HRM** (.NET Framework) standard covers naming, data
types/deployment idempotency, and performance only; the **NEW PeoplesHR
PHR-X** (.NET Core) standard covers all of that plus formatting, query
structure, aggregation, transactions, centralized exception logging,
security, comments/metadata, stored-procedure conventions, and testing
sign-off.

It identifies which system your script targets before reviewing anything —
from an explicit statement, file/header metadata, or naming style (OLD is
`UPPERCASE` with an `HS_` prefix; NEW is lowercase `snake_case` with no
prefix) — and asks rather than guesses if the signal is ambiguous. Every
finding in the report is prefixed with the system name (e.g. "NEW ERR-03",
"OLD DEP-06"), because both standards reuse the same bare rule IDs for
unrelated rules.

#### How to invoke it

Explicitly:

```
/dba-kit:phx-sql-standards-review
```

Or describe the work — e.g. *"review this stored proc for PR sign-off"* —
and Claude loads the skill on its own when T-SQL needs review.

#### What it needs from you

The **complete SQL script** to review. If the target system isn't obvious
from an explicit statement, file path, or naming style, it asks which system
before reviewing rather than guessing.

#### What you get back

A report with: the detected/confirmed system and its basis, a verdict
(`BLOCKED (N must-fix items)` / `PASS (no MUST violations)` / `PASS WITH
SHOULD-LEVEL NOTES`), a table of MUST violations (rule ID, offending
line/snippet, problem, fix), SHOULD-level notes for undocumented deviations,
and any MAY-level judgment notes worth flagging.

---

### `org-standards` — PeoplesHR product knowledge for every role

| Skill | Use it for |
| --- | --- |
| `phx-product-context` | Acquiring **grounded, cited PeoplesHR context** before you work — solution engineering for developers, PRD / FRD writing and requirement elicitation for Business Analysts. Searches the four WeKnora knowledge bases through the weknora-peopleshr-product-knowledge MCP server you connect yourself (see below). |

This plugin declares no MCP server.

> **New in `6.0.0`.** The developer `phx-product-context` (from `dev-kit`) and the BA
> `phx-business-context` (from here) were merged into this one skill and rewritten
> from scratch. `/dev-kit:phx-product-context` and
> `/org-standards:phx-business-context` are both now
> `/org-standards:phx-product-context`. The old `weknora` server declaration and
> `WEKNORA_MCP_TOKEN` are gone.
>
> Looking for `hrm-deployment-script`, `hrm-notification` or `phx-debugger`? They
> moved to [`dev-kit`](#dev-kit--peopleshr-developer-build-tooling) in `3.0.0`.
> `phx-sql-standards-review` and `phx-dbexplorer` moved to
> [`dba-kit`](#dba-kit--peopleshr-database-tooling) in `4.0.0`.

#### What `phx-product-context` does

```
/org-standards:phx-product-context
```

You will rarely type that. It fires on its own when you design a feature, write an
SDD, plan a change, write a PRD or FRD, elicit requirements, or otherwise depend on
how a PeoplesHR module actually behaves. It skips itself for work with no PeoplesHR
behaviour in it — formatting, renaming, a generic language question.

**Where it looks.** Four WeKnora knowledge bases, each for a different kind of truth:

| Knowledge base | What it gives you |
| --- | --- |
| `PeoplesHR Module Behaviour Brief` | How a module **actually** behaves, derived from its code and database — rules, states, edge cases, data and integrations. Statements carry IDs (`MBB-ABS-BEH-042`) and a publication state (`Verified`, `Unverified (Derived)`, `Disputed`, `Retired`). |
| `PeoplesHR Findings-Register` | Gaps, inconsistencies and open questions found in that reading (`MBB-ABS-FND-004`). Observations, mostly untriaged, and restricted. |
| `Product Development` | PRDs, requirement docs, solution and technical blueprints, configuration docs, release test cases. |
| `PeoplesHR Academy` | End-user guides, module overviews, configuration guides, release notes. |

**How it searches.** It turns your task into product-vocabulary queries, checks
which modules have a brief and a register, then searches the four bases **one call
each, in parallel** — so `Product Development`'s large test-case suites cannot crowd
the others out. It weights them by the task: solution engineering leads with the
Brief and `Product Development`; requirements work leads with Academy and the Brief.
Then it drills into the strongest hits and follows identifiers across bases — a
table named in a statement, a statement cited by a finding, a work item named in a
PRD.

**What you get back.** A compact context brief per question: what the sources say,
with document titles and statement or finding IDs; where they disagree (usually
as-built against as-intended — a design risk for a developer, a stakeholder question
for a BA); the known findings in the area; and the gaps no knowledge base covers. The
task you asked for then carries on from that grounding.

**Findings stay where they belong.** When the work ends in a document for wide
circulation — a PRD, an FRD, a wiki page — it references a finding by ID and
business consequence and leaves security detail in the restricted register.

**When nothing is documented, it says so** and treats the behaviour as unknown,
rather than filling the gap from general HRM knowledge.

#### What `phx-product-context` needs from you

The **weknora-peopleshr-product-knowledge** MCP server, connected in your own
Claude Code (`/mcp`) or as a connector in Claude Desktop. The plugin deliberately
does not ship it. Without it, the skill stops and tells you so.

---

#### `phx-dbexplorer` — database schema browsing

Source: [`hsenidBiz/phx-dbexplorer`](https://github.com/hsenidBiz/phx-dbexplorer)
(a separate public repo — not vendored into `phr-foundry`). Installing the
`dba-kit` plugin registers it, but Claude Code only launches it via
`npx -y github:hsenidBiz/phx-dbexplorer` the first time you use a tool that
needs it, and it needs your database credentials to do anything.

**You must set these yourself before it will work** — the plugin ships
`plugin.json` wired to read them from your own shell environment, it does not
supply values for you. Set them in your shell profile, never commit them
anywhere (`PHX_DB_CONNECTION_STRING` carries your DB password), and restart
Claude Code afterward so it picks up the new values:

| Variable | Required | Description |
| --- | --- | --- |
| `PHX_DB_TYPE` | Yes | `mssql` or `postgres` exactly (aliases `sqlserver`/`postgresql` also accepted) — other values like `MSSQLDB` are rejected |
| `PHX_DB_CONNECTION_STRING` | Yes | Full connection string for your target database |
| `PHX_DB_SCHEMA_FILTER` | No | Comma-separated schemas to expose (default: `dbo` for SQL Server, `public` for Postgres) |

Example (adjust the connection string to your own database):

```shell
export PHX_DB_TYPE=mssql
export PHX_DB_CONNECTION_STRING="Server=localhost,1433;Database=MyDb;User Id=sa;Password=YourPassword;TrustServerCertificate=True;"
export PHX_DB_SCHEMA_FILTER=dbo,hr
```

On Windows (PowerShell), use `$env:PHX_DB_TYPE = "mssql"` etc. instead, or set
them permanently via System Properties → Environment Variables.

First use downloads a self-contained binary for your OS/arch to
`~/.cache/phx-dbexplorer-mcp/<version>/` — no .NET SDK or runtime needed.
Later calls reuse that cache. See that repo's README for the full tool list
(`list_tables`, `get_table_schema`, `list_stored_procedures`, etc.) and for
pinning a specific version via `PHX_DBEXPLORER_VERSION`.

---

### `ba-kit` — PeoplesHR tooling for Business Analysts

| Skill | Use it for |
| --- | --- |
| `phx-write-frd` | Writing the **Feature Requirements Document** (`FRD-`) for a feature — the business/functional document the whole delivery hangs off. Reads the template and sample live from the PHR-X wiki every run, and never invents a metric, persona, priority or acceptance criterion. Needs an Azure DevOps MCP server (see below). |

| MCP server | Use it for |
| --- | --- |
| *(not shipped)* | `phx-write-frd` needs your own Azure DevOps MCP server, which no `phr-foundry` plugin has ever shipped. |

> **Business Analysts install `ba-kit` and
> [`org-standards`](#org-standards--peopleshr-product-knowledge-for-every-role)**,
> which carries `phx-product-context`. `ba-kit` stopped declaring the `weknora` MCP
> server in `3.0.0` — nothing in it called the server.

#### What `phx-write-frd` does

Authors the **FRD — Feature Requirements Document**, the business/functional
document for a PeoplesHR feature (`FRD-` prefix). Drafted by the Business Analyst,
accountable to the Product Owner, consulted by the Solutioning Engineer. Its
technical companion is the SDD, which `dev-kit`'s
[`phx-write-sdd`](#what-phx-write-sdd-does) writes.

**The template is not in the plugin.** The template and the filled sample are read
live from the PHR-X project wiki on **every run**, through your Azure DevOps MCP
server. There is no local copy, and no CLI, REST or PAT fallback — so a change to
the organization's standard reaches everyone the moment it is published, and a run
that cannot reach the wiki produces nothing rather than working from a remembered
structure.

#### How to invoke it

```
/ba-kit:phx-write-frd
```

Or just describe it — *"write an FRD for the leave-encashment feature"*. It also
fires at the end of a requirements or grilling session when you ask for the
discussion to be written up, captured, or turned into an FRD: the session
transcript, and any ADRs or `CONTEXT.md` it produced, are legitimate input.

#### What `phx-write-frd` needs from you

**The first thing it does is ask.** It reads the wiki template, maps what you have
supplied onto the template's sections, and comes back with **one consolidated
question** listing every section it has no input for — by number. It waits for your
answers before drafting anything, rather than drafting the covered half and asking
about the rest.

Expect to be asked for **Document Control** in particular: the FRD ID
(`FRD-<MODULE>-<YYYY>-<NNN>`), feature name, BA and Product Owner names, version,
roadmap or epic reference, the linked SDD, and the target wiki path. A design
session never states these. It will not allocate the next document number for you.

A caution worth knowing about: in a grilling session the skill proposes a
recommended answer to every question and you accept, reject or reshape it. **Only
your answer is input.** A recommendation left unanswered when the session moved on
is still a guess, and promoting it into the FRD would launder a suggestion into a
requirement — FRD acceptance criteria become TDD test cases, so a target nobody
agreed to gets built against.

#### What you get back

A **markdown file in your repository** — `docs/frd/<FRD-ID>-<kebab-case-feature-name>.md`
by convention, or wherever your repo already keeps FRDs. Not a wall of text in the
chat: a 16-section document pasted into a conversation cannot be reviewed, diffed
or version-controlled.

**Writing the file is not publishing.** Nothing reaches the wiki until you ask for
it explicitly, and even then the skill shows you the exact path and content and
stops for your approval before any write — a wiki page is visible to the whole
organization the moment it lands.

It stays on the business side of the line: §9 records the *business need* for each
cross-module touchpoint and deliberately leaves the mechanism open, and §8 is data
in business terms. Direct DB access vs. internal API vs. ADAB, and table and column
names, are the SDD's call. Every §9 touchpoint you write becomes a row the SDD must
resolve.

Full prerequisites and troubleshooting:
[`plugins/ba-kit/skills/phx-write-frd/INSTALL.md`](../plugins/ba-kit/skills/phx-write-frd/INSTALL.md).

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `claude plugin marketplace add` hangs or fails | No cached GitHub credentials — use the `https://hsenidBiz@github.com/...` form, or sign in via Git Credential Manager first. |
| Slash command not found after install | Run `/reload-plugins`, or restart the session. |
| `/org-standards:hrm-deployment-script`, `:hrm-notification`, `:phx-debugger` or `:hrm-configuration-document` not found | Those four moved to `dev-kit` in `org-standards` `3.0.0`. Run `claude plugin install dev-kit@phr-foundry` and use the `/dev-kit:` prefix. |
| `/org-standards:phx-sql-standards-review` not found, or `phx-dbexplorer` gone after an update | Both moved to `dba-kit` in `org-standards` `4.0.0`. Run `claude plugin install dba-kit@phr-foundry`, use the `/dba-kit:` prefix, and restart Claude Code so the MCP server re-registers. |
| `/dev-kit:phx-product-context`, `/org-standards:phx-business-context` or `/ba-kit:phx-business-context` not found after an update | All merged into `/org-standards:phx-product-context` in `org-standards` `6.0.0`. Run `claude plugin install org-standards@phr-foundry` and use that. |
| An expected fix isn't there after updating | The maintainer likely didn't bump `version` in `plugin.json`. Commits alone don't ship. |
| Skill behaves oddly when copied by hand | Don't copy `SKILL.md` on its own — the skill needs its whole folder including `references/`. Install via the marketplace instead. |
| `phx-debugger` stops saying it needs the Azure DevOps MCP server | You have not added an ADO MCP server, or have not restarted Claude Code since. Check `/mcp`. This is by design — the skill has no non-MCP fallback, and `dev-kit` declares no MCP server. |
| `phx-write-sdd` or `phx-write-frd` stops saying it cannot read the template | Same cause and same fix as the row above — both read the template live from the PHR-X wiki through your own ADO MCP server, and neither has a local copy to fall back on. If the error is a 403 rather than a missing server, your account has no PHR-X wiki access; if it is a 404, the template page has moved and you need to give the skill its new location. |
| `phx-write-sdd` or `phx-write-frd` comes back with a long list of questions instead of a document | Working as designed — those are template sections it has no input for. Answer them and it carries on. It will not fill them with guesses, or file them as "Open Questions" and deliver anyway. |
| A document was written but the wiki page never appeared | Working as designed — writing the repo file is not publishing. Ask for it to be published explicitly; the skill will show you the exact path and content and stop for approval first. |
| `phx-write-sdd` refuses to write §5 | It needs the linked FRD. §5 resolves the FRD's cross-module touchpoints into technical decisions, and it will not reconstruct them from the feature description. |
| `phx-debugger` stops saying it needs Superpowers | Run `/plugin install superpowers@claude-plugins-official` and restart. |
| A notification mails the same row on every scheduler pass | The four views' `WHERE` clauses have drifted, so the `_UPD` view never returns the row and the claim column is never stamped. Run the predicate check in `hrm-notification`'s verification step. |
| A notification arrives with empty merge fields | Same cause — the row is in `_PEN` but not in `_DAT`. Compare the four `WHERE` clauses; they must be byte-identical. |
| A notification arrives with `@TOKEN` printed literally | That token has no matching column in the `_DAT` view. An unmatched token is not an error — it renders as written. |
| Rows sit unclaimed and nothing is ever sent, with no error | Either the HTML template was never deployed to the scheduler host's alert directory, or `HRM-JS45-SERVICE` is not running against that database. Neither is visible from SQL. |
| `hrm-configuration-document` stops at `check_doc.py` errors | Fix each ERROR it lists. It rejects any TBD you did not choose, leftover skeleton tokens, code references, credentials, and screenshot placeholders when you said there are none. |
| `build_docx.py` fails with `No module named 'docx'` | Run `python -m pip install --user python-docx`. |
| The PDF step reports "Microsoft Word is not available" | `export_pdf.ps1` needs Word on Windows. Open the `.docx`, update fields (Ctrl+A, F9) and save as PDF manually. |
| The table of contents or page numbers are blank in the `.docx` | Fields are not refreshed until Word updates them. Run `export_pdf.ps1`, or press Ctrl+A, F9 in Word. |
| `hrm-notification` or `hrm-deployment-script` has no database to inspect | `dev-kit` declares no database MCP server. Install `dba-kit` too — it declares `phx-dbexplorer` — and set `PHX_DB_TYPE` and `PHX_DB_CONNECTION_STRING`. |
| `phx-dbexplorer` tool calls fail with a config error | Set `PHX_DB_TYPE` and `PHX_DB_CONNECTION_STRING` in your shell before starting Claude Code — they're per-developer and not shipped with the plugin. |
| `/mcp` shows `phx-dbexplorer` failing to reconnect (`-32000`) | Usually an invalid `PHX_DB_TYPE` (e.g. `MSSQLDB` for SQL Server) — the server rejects anything other than `mssql`/`sqlserver` or `postgres`/`postgresql` and exits immediately. Fix the value and fully restart Claude Code (env var changes aren't picked up by an already-running session). |
| `phx-product-context` stops saying the WeKnora server is not connected | Connect the weknora-peopleshr-product-knowledge MCP server in Claude Code (`/mcp`) or as a Claude Desktop connector, then start a new session. The plugin does not ship it. |
| `claude mcp list` still shows a `weknora` server needing `WEKNORA_MCP_TOKEN` | Left over from before `org-standards` `6.0.0` / `dev-kit` `3.0.0` / `ba-kit` `3.0.0`. Update all three plugins; the declaration is gone and the variable can be deleted. |
| WeKnora returns `503` with a JSON body | The WeKnora VM is in maintenance mode. Nothing to fix client-side; try again shortly. |
| `phx-dbexplorer` fails to start with "No releases found" | The upstream repo has no tagged release yet, or `PHX_DBEXPLORER_VERSION` points at a tag that doesn't exist. Check [its Releases page](https://github.com/hsenidBiz/phx-dbexplorer/releases). |

## Reporting a problem

Open a PR or an issue against
[`PHR-Foundry`](https://github.com/hsenidBiz/phr-foundry), or
contact PeoplesHR &lt;sanuja.a@peopleshr.com&gt;.
