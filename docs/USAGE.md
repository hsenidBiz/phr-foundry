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
claude plugin install org-standards@phr-foundry
```

The same commands work as slash commands inside a Claude Code session
(`/plugin marketplace add ...`, `/plugin install ...`).

**If the first command hangs or fails on authentication**, your machine has no
cached GitHub credentials. Use the URL with the account prefix so Git knows
which account to prompt for:

```shell
claude plugin marketplace add https://hsenidBiz@github.com/hsenidBiz/phr-foundry
```

### Make it automatic for a whole project

Add this to the project's `.claude/settings.json` and commit it. Anyone who
trusts the project gets the marketplace registered and `org-standards` enabled
automatically. `enabledPlugins` only enables an **already-installed** plugin,
though — it does not install it — so the first person on the project still
has to run `claude plugin install org-standards@phr-foundry` once:

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
claude plugin update org-standards
```

You will **only** receive a new version when the maintainer bumps `version` in
the plugin's `plugin.json`. New commits alone do not reach you — if you expect a
change and don't see it, ask the maintainer whether the semver was bumped.

## 4. Uninstall

```shell
claude plugin uninstall org-standards
```

---

## Plugin catalog

### `org-standards` — PeoplesHR organization standards

| Skill | Use it for |
| --- | --- |
| `hrm_sql_standards` | Creating, converting, and PR-reviewing re-runnable **HRM-DB MSSQL deployment scripts** and their `dep.xml` registration. |

| MCP server | Use it for |
| --- | --- |
| `phx-dbexplorer` | Letting Claude browse your **SQL Server or PostgreSQL** schema — tables, columns, indexes, foreign keys, stored procedures, functions — without writing SQL by hand. |

#### What `hrm_sql_standards` does

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
/org-standards:hrm_sql_standards
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

#### `phx-dbexplorer` — database schema browsing

Source: [`hsenidBiz/phx-dbexplorer`](https://github.com/hsenidBiz/phx-dbexplorer)
(a separate public repo — not vendored into `phr-foundry`). Installing the
`org-standards` plugin registers it, but Claude Code only launches it via
`npx -y github:hsenidBiz/phx-dbexplorer` the first time you use a tool that
needs it, and it needs your database credentials to do anything.

**You must set these yourself before it will work** — the plugin ships
`plugin.json` wired to read them from your own shell environment, it does not
supply values for you. Set them in your shell profile, never commit them
anywhere (`PHX_DB_CONNECTION_STRING` carries your DB password), and restart
Claude Code afterward so it picks up the new values:

| Variable | Required | Description |
| --- | --- | --- |
| `PHX_DB_TYPE` | Yes | `mssql` or `postgres` |
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

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `claude plugin marketplace add` hangs or fails | No cached GitHub credentials — use the `https://hsenidBiz@github.com/...` form, or sign in via Git Credential Manager first. |
| Slash command not found after install | Run `/reload-plugins`, or restart the session. |
| An expected fix isn't there after updating | The maintainer likely didn't bump `version` in `plugin.json`. Commits alone don't ship. |
| Skill behaves oddly when copied by hand | Don't copy `SKILL.md` on its own — the skill needs its whole folder including `references/`. Install via the marketplace instead. |
| `phx-dbexplorer` tool calls fail with a config error | Set `PHX_DB_TYPE` and `PHX_DB_CONNECTION_STRING` in your shell before starting Claude Code — they're per-developer and not shipped with the plugin. |
| `phx-dbexplorer` fails to start with "No releases found" | The upstream repo has no tagged release yet, or `PHX_DBEXPLORER_VERSION` points at a tag that doesn't exist. Check [its Releases page](https://github.com/hsenidBiz/phx-dbexplorer/releases). |

## Reporting a problem

Open a PR or an issue against
[`PHR-Foundry`](https://github.com/hsenidBiz/phr-foundry), or
contact PeoplesHR &lt;sanuja.a@peopleshr.com&gt;.
