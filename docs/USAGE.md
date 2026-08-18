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
| `phx_debugger` | Fixing an **Azure DevOps bug end to end** from its ID — root cause investigation, fix plan, implementation, RCA onto the work item, status change. Needs the `superpowers` plugin and an Azure DevOps MCP server (see below). |

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

#### What `phx_debugger` does

Open Claude Code in the repository you are debugging, then give it a bug ID:

```
/org-standards:phx_debugger 141827
```

Plain language works too — *"fix ADO bug 141827"*. Either way the message must
carry the **bug ID**: it is the one required argument, the skill looks the work
item up by ID, and it will not go hunting for it by title. There is no code path
to pass — the working directory *is* the codebase. Add a path only for a
dependency that lives outside this repository.

Before investigating, it shows you what it fetched — title, state, a short
summary, attachment names — and **waits** for you to confirm it is the right bug.

**It moves the status twice.** As soon as you confirm the bug it sets the work
item to `Under Investigation`, before it reads anything, so the board shows the
bug is being worked. Later, once the fix is written and you confirm it works, it
asks and moves the work item to `Dev In Progress`. It does not gate on the state
it found — if the bug looks like someone else is already on it, it says so and
leaves the decision to you.

It reads the work item — description, comments, linked items and every attachment
— and decides whether there is enough to troubleshoot. If there is not, it asks
**you** first: it lists what it checked and the specific questions blocking it,
and waits. Answer any of them and it re-assesses and carries on — no waiting on
the reporter for something you already know. Only if you cannot answer either do
you tell it to post the questions as a comment on the work item, which ends the
run. It never comments on the ticket unprompted. Then it **hands the bug to
the Superpowers `systematic-debugging` skill**, running in a subagent, which finds
the root cause and later writes the fix. `phx_debugger` itself never debugs and
never edits code: it owns Azure DevOps, your approval gates and the RCA. It
**stops** for you to approve the fix plan, and stops again for you to test the
diff. After you confirm the fix works it writes the full RCA into the work item's
`Custom.*` fields and moves the status to `Dev In Progress`, asking before each. It never commits,
pushes or opens a PR unless you say so.

Modes: `quick`, `smart` (work only in the checked-out branch), `balanced`
(default), `advanced`.

**Three hard gates run before anything else** — a connected Azure DevOps MCP
server, the `superpowers` plugin, and a valid bug ID. Any one of them missing
ends the run with an explanation, having read nothing and touched nothing. The two you install once:

1. The **`superpowers` plugin**:
   `/plugin install superpowers@claude-plugins-official`, then restart.
2. An **Azure DevOps MCP server**, which `org-standards` deliberately does *not*
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
[`plugins/org-standards/skills/phx_debugger/INSTALL.md`](../plugins/org-standards/skills/phx_debugger/INSTALL.md).
You do not install the skill separately — it arrives with `org-standards`.

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

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `claude plugin marketplace add` hangs or fails | No cached GitHub credentials — use the `https://hsenidBiz@github.com/...` form, or sign in via Git Credential Manager first. |
| Slash command not found after install | Run `/reload-plugins`, or restart the session. |
| An expected fix isn't there after updating | The maintainer likely didn't bump `version` in `plugin.json`. Commits alone don't ship. |
| Skill behaves oddly when copied by hand | Don't copy `SKILL.md` on its own — the skill needs its whole folder including `references/`. Install via the marketplace instead. |
| `phx_debugger` stops saying it needs the Azure DevOps MCP server | You have not added an ADO MCP server, or have not restarted Claude Code since. Check `/mcp`. This is by design — the skill has no non-MCP fallback. |
| `phx_debugger` stops saying it needs Superpowers | Run `/plugin install superpowers@claude-plugins-official` and restart. |
| `phx-dbexplorer` tool calls fail with a config error | Set `PHX_DB_TYPE` and `PHX_DB_CONNECTION_STRING` in your shell before starting Claude Code — they're per-developer and not shipped with the plugin. |
| `/mcp` shows `phx-dbexplorer` failing to reconnect (`-32000`) | Usually an invalid `PHX_DB_TYPE` (e.g. `MSSQLDB` for SQL Server) — the server rejects anything other than `mssql`/`sqlserver` or `postgres`/`postgresql` and exits immediately. Fix the value and fully restart Claude Code (env var changes aren't picked up by an already-running session). |
| `phx-dbexplorer` fails to start with "No releases found" | The upstream repo has no tagged release yet, or `PHX_DBEXPLORER_VERSION` points at a tag that doesn't exist. Check [its Releases page](https://github.com/hsenidBiz/phx-dbexplorer/releases). |

## Reporting a problem

Open a PR or an issue against
[`PHR-Foundry`](https://github.com/hsenidBiz/phr-foundry), or
contact PeoplesHR &lt;sanuja.a@peopleshr.com&gt;.
