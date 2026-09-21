# PHR-Foundry

Internal Claude Code **plugin marketplace** for **PeoplesHR**, hosted on GitHub.
This repository holds both the marketplace catalog (`.claude-plugin/marketplace.json`)
and the plugins it distributes (`plugins/`).

- **Marketplace name:** `phr-foundry`
- **Owner:** PeoplesHR &lt;sanuja.a@peopleshr.com&gt;
- **Repo:** `https://github.com/hsenidBiz/phr-foundry`

## Repository layout

```
.
├── .claude-plugin/
│   └── marketplace.json          # Catalog: lists every plugin and its source
├── plugins/
│   ├── dev-kit/                  # Developer build tooling — skills only, no MCP servers
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json       # Manifest (version: 1.0.0 — see Versioning)
│   │   ├── skills/
│   │   │   ├── hrm-deployment-script/
│   │   │   │   └── SKILL.md       # PHR SQL deployment-script standards, .NET Framework only
│   │   │   ├── hrm-notification/
│   │   │   │   └── SKILL.md       # Job Scheduler email notifications
│   │   │   ├── phx-debugger/
│   │   │   │   └── SKILL.md       # Azure DevOps bug fixing, end to end
│   │   │   └── hrm-configuration-document/
│   │   │       └── SKILL.md       # CR Configuration Document (.md/.docx/PDF)
│   │   └── README.md
│   ├── dba-kit/                  # Database tooling for DBAs
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json       # Manifest (version: 1.0.0 — see Versioning); also
│   │   │                         # declares the phx-dbexplorer MCP server
│   │   ├── skills/
│   │   │   └── phx-sql-standards-review/
│   │   │       └── SKILL.md       # Review-only OLD/NEW SQL standards sign-off
│   │   └── README.md
│   ├── org-standards/            # Product-knowledge plugin
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json       # Manifest (version: 4.0.0 — see Versioning); also
│   │   │                         # declares the weknora MCP server
│   │   ├── skills/
│   │   │   └── phx-product-context/
│   │   │       └── SKILL.md       # PeoplesHR product knowledge from WeKnora (developer)
│   │   └── README.md
│   └── ba-kit/                   # Business Analyst plugin — never install with org-standards
│       ├── .claude-plugin/
│       │   └── plugin.json       # Manifest (version: 1.0.0); declares the weknora MCP server
│       ├── skills/
│       │   └── phx-business-context/
│       │       └── SKILL.md       # PeoplesHR product knowledge from WeKnora (BA)
│       └── README.md
├── .github/
│   └── workflows/
│       └── validate.yml          # CI: runs `claude plugin validate .` on PRs into main
└── docs/
    ├── README.md                 # (Azure repo template file — reserved)
    └── USAGE.md                  # User-facing install/update/usage guide
```

## Plugin boundaries: one audience per plugin

Every skill and MCP server lives in the plugin whose **audience** it serves. This is
the rule for deciding where a new thing goes, and it is not negotiable:

| Plugin | Audience | Holds |
| --- | --- | --- |
| `dev-kit` | Developers only | Skills and MCP servers no other role would ever invoke |
| `dba-kit` | DBAs only | Same test, for database work — SQL review and schema browsing |
| `ba-kit` | Business Analysts only | Same test, for BAs |
| `org-standards` | **Everyone** | Only what every role can use, whatever their job |

A new domain gets its **own** plugin under `plugins/`, never a corner of an existing
one. The test is *who would ever invoke this* — not which plugin already declares the
supporting server. A developer-only skill belongs in `dev-kit` even when its MCP
server sits elsewhere. When a server is genuinely needed by two audiences — `weknora`
today — each plugin that needs it declares it; the duplicate declarations resolve to
one server at run time and are the intended cost of clean boundaries.

> **The repo predates this rule and does not fully comply yet.**
> `phx-sql-standards-review` and `phx-dbexplorer` were realigned out of
> `org-standards` into `dba-kit` in `org-standards` `4.0.0`. `phx-product-context`
> is still developer-only but remains in `org-standards` — moving it breaks
> slash-command prefixes for everyone already using it. The rule governs
> **additions**; realigning what is left is a deliberate, separately-agreed
> change. See [`CLAUDE.md`](CLAUDE.md#rules).

## What's in `dev-kit`

The hands-on build skills. Three skills, **no MCP servers** — see
[`plugins/dev-kit/README.md`](plugins/dev-kit/README.md) for what each one wants
from your environment.

| Source | Skill | Notes |
| --- | --- | --- |
| **This repo (own skill)** | `hrm-deployment-script` | PHR-specific: reformat/scaffold HRM-DB MSSQL deployment SQL, **.NET Framework only**. |
| **This repo (own skill)** | `hrm-notification` | Builds a module email notification on the `HRM-JS45-SERVICE` Job Scheduler — four views, claim column, `HS_HR_JS_*` config rows, HTML template. A notification is **data, not code**. |
| **This repo (own skill)** | `phx-debugger` | Fixes an Azure DevOps bug end to end from its bug ID — investigation, fix plan, implementation, RCA, status change. Needs the `superpowers` plugin and a per-developer Azure DevOps MCP server. |
| **This repo (own skill)** | `hrm-configuration-document` | Writes the organization-standard Configuration Document for a finished CR from developer notes — house `.md`, branded `.docx` and PDF for the SharePoint library. Asks the developer for every missing fact. |

These four shipped in `org-standards` up to `2.11.1` and moved here in
`org-standards` `3.0.0`. Nothing about the skills themselves changed — only the
slash-command prefix, from `/org-standards:` to `/dev-kit:`.

`dev-kit` declares no MCP servers of its own. `hrm-notification` and
`hrm-deployment-script` are much more useful with a database to inspect, which is
what `dba-kit`'s `phx-dbexplorer` gives them — so install both plugins if you
want that. `phx-debugger`'s Azure DevOps server was always yours to add and still
is.

## What's in `dba-kit`

The database half. One skill and one MCP server, for DBAs and anyone else doing
database work — see [`plugins/dba-kit/README.md`](plugins/dba-kit/README.md).

| Source | Skill / MCP server | Notes |
| --- | --- | --- |
| **This repo (own skill)** | `phx-sql-standards-review` | Review-only sign-off on a T-SQL script against either the OLD hSenid HRM (.NET Framework) or NEW PeoplesHR PHR-X (.NET Core) SQL standard, auto-detecting which system it targets. Never edits the SQL. |
| **Separate repo, fetched at run time** | `phx-dbexplorer` (MCP server) | Schema browsing for SQL Server/Postgres. Source: [`hsenidBiz/phx-dbexplorer`](https://github.com/hsenidBiz/phx-dbexplorer) — a **public** .NET repo, not vendored here. `plugin.json` runs it via `npx -y github:hsenidBiz/phx-dbexplorer`, which pulls the prebuilt binary for your OS/arch from that repo's GitHub Releases on first use (the repo must stay public — the download is unauthenticated). |

Both shipped in `org-standards` up to `3.0.0` and moved here in `org-standards`
`4.0.0`. Nothing about the skill itself changed — only the slash-command prefix,
from `/org-standards:phx-sql-standards-review` to
`/dba-kit:phx-sql-standards-review`. `phx-dbexplorer` re-registers under
`dba-kit`, so install this plugin if you were relying on it through
`org-standards`.

> **Before `phx-dbexplorer` will work**, you must set `PHX_DB_TYPE`,
> `PHX_DB_CONNECTION_STRING`, and optionally `PHX_DB_SCHEMA_FILTER` in your own
> shell environment — these are per-developer database credentials and are
> never shipped with the plugin. `PHX_DB_TYPE` must be exactly `mssql` or
> `postgres` (aliases `sqlserver`/`postgresql` also work) — anything else,
> e.g. `MSSQLDB`, is rejected and the MCP server fails to start, which shows
> up in `/mcp` as a bare reconnect error. Restart Claude Code after setting
> or changing these — an already-running session won't pick up the new
> values. See the [usage guide's Plugin catalog](docs/USAGE.md#plugin-catalog)
> for the full variable table.

## What's in `org-standards`

The product-knowledge half. One skill of its own, plus one MCP server.

| Source | Skill / MCP server | Notes |
| --- | --- | --- |
| **This repo (own skill)** | `phx-product-context` | Grounds any answer about PeoplesHR module behaviour in the product documentation held in WeKnora, and cites the documents used. Searches `Product Development` deep and `PeoplesHR Academy` shallow, and answers technically. Needs `WEKNORA_MCP_TOKEN`. |
| **Remote server on the WeKnora VM** | `weknora` (MCP server) | Read-only retrieval from the `Product Development` and `PeoplesHR Academy` knowledge bases at `https://weknora.phrsandbox.dev/mcp`. A `type: "http"` server — nothing is downloaded or run locally. Read-only is enforced by a `retrieve`-only API key on the server, not by the advertised tool list. |

> **Before `weknora` will work**, you must set `WEKNORA_MCP_TOKEN` in your own
> environment — one token shared by the whole team, handed out through your
> credential channel and **never committed to this public repo**. Set it and
> **then** restart Claude Code: Windows reads user environment variables at
> process start, so a session that was already running reports a
> missing-variable warning for `weknora` even though the token is stored
> correctly. See
> [`INSTALL.md`](plugins/org-standards/skills/phx-product-context/INSTALL.md).

We do not bundle third-party *plugins* as `dependencies` — Claude Code only auto-resolves a
cross-marketplace dependency if the user has already added that dependency's marketplace,
so it isn't a true one-shot install and just pushes extra `marketplace add` commands onto
users anyway. See [`CLAUDE.md`](CLAUDE.md#rules) for the rule against re-adding this. (This
doesn't apply to `phx-dbexplorer` above, which isn't a Claude Code plugin/marketplace at
all — it's a plain MCP server binary fetched via `npx`.)

## Install from this repository

> Using the plugins rather than maintaining them? See the
> **[usage guide](docs/USAGE.md)** — install, update, and how to drive each skill.

Point Claude Code at the GitHub repo, then install the plugins. Most developers
want `dev-kit`, `org-standards` and `dba-kit`:

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install dev-kit@phr-foundry
claude plugin install org-standards@phr-foundry
claude plugin install dba-kit@phr-foundry
```

Each skill is namespaced under its **own** plugin, so invoke it with:

```shell
/dev-kit:hrm-deployment-script
/dev-kit:hrm-notification
/dev-kit:phx-debugger <bug-id>
/dba-kit:phx-sql-standards-review
/org-standards:phx-product-context
```

Claude also loads a skill automatically when its `description` matches the
work — e.g. `hrm-deployment-script` when you work on SQL in a .NET Framework
project. See the [usage guide](docs/USAGE.md) for the full walkthrough of each.

To have the marketplace offered automatically when someone trusts a project,
add it to that project's `.claude/settings.json`:

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
    "org-standards@phr-foundry": true,
    "dba-kit@phr-foundry": true
  }
}
```

## `ba-kit` — the Business Analyst plugin

Business Analysts install `ba-kit` instead of `org-standards`:

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install ba-kit@phr-foundry
```

It ships one skill, `phx-business-context`, and the same `weknora` MCP server.
The skill answers PeoplesHR questions in business terms — what the user sees, the
process, the rules and the configuration — leading with the `PeoplesHR Academy`
knowledge base and using `Product Development` for the intent behind it. It also
needs `WEKNORA_MCP_TOKEN`. See
[`plugins/ba-kit/README.md`](plugins/ba-kit/README.md).

> ⚠️ **Install `ba-kit` or `org-standards`, never both.**
> `phx-business-context` and `phx-product-context` search the same two knowledge
> bases in opposite orders and answer in different voices. With both present they
> compete on question wording and misroute. Anyone genuinely doing both jobs takes
> `org-standards`, whose developer skill keeps the business rationale as a
> secondary.
>
> This applies **only** to that pair. `dev-kit` and `dba-kit` ship no
> product-knowledge skill, so both are safe alongside either one — a BA who also
> writes deployment SQL can take `ba-kit` + `dev-kit` + `dba-kit`.

## Versioning: manual semver in `plugin.json`

Each plugin declares an explicit `version` in its `plugin.json` (`dev-kit` is at
`1.0.0`, `org-standards` at `4.0.0`, `ba-kit` at `1.0.0`, `dba-kit` at `1.0.0`). Claude Code resolves a
plugin's version from the first of these that is set:

1. `version` in the plugin's `plugin.json` ← **we use this**
2. `version` in the plugin's marketplace entry
3. the git commit SHA of the plugin's source

Because `plugin.json` sets `version`, that string is the version. **Users only
receive updates when the version changes**, so bump the semver on every release
that should reach users. Pushing commits without bumping `version` leaves
existing users on the cached copy.

> Set `version` in `plugin.json` **only** — not also in the marketplace entry.
> When both are set, `plugin.json` silently wins, so a stale marketplace version
> can mask the one you intended.

## Develop and test locally

From the directory that **contains** this repository, start Claude Code and run:

```shell
/plugin marketplace add ./PHR-Foundry
/plugin install dev-kit@phr-foundry
/plugin install org-standards@phr-foundry
/plugin install dba-kit@phr-foundry
/reload-plugins
```

### Validate before you commit

```shell
claude plugin validate .
```

Or from inside a Claude Code session: `/plugin validate .`

## Adding another plugin later

1. **Name its audience in one word first.** If you can't, the boundary is wrong —
   see [Plugin boundaries](#plugin-boundaries-one-audience-per-plugin). Put that
   audience in the plugin's `description` and the first line of its `README.md`.
2. Create `plugins/<new-plugin>/.claude-plugin/plugin.json` (name required;
   set a `version`, e.g. `1.0.0`, and bump it on each release).
3. Add an entry to the `plugins` array in `.claude-plugin/marketplace.json`
   with a `name` and a `source` of `./plugins/<new-plugin>`.
4. Add a section for it under **Plugin catalog** in [`docs/USAGE.md`](docs/USAGE.md),
   so users have a guide for the new skills.
5. Run `claude plugin validate .` and open a PR into `main` — the GitHub
   Actions workflow validates it automatically.
