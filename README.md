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
│   ├── dev-kit/                  # Developer tooling — the build and design skills
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json       # Manifest (version: 3.0.0 — see Versioning)
│   │   ├── skills/
│   │   │   ├── hrm-deployment-script/
│   │   │   │   └── SKILL.md       # PHR SQL deployment-script standards, .NET Framework only
│   │   │   ├── hrm-notification/
│   │   │   │   └── SKILL.md       # Job Scheduler email notifications
│   │   │   ├── phx-debugger/
│   │   │   │   └── SKILL.md       # Azure DevOps bug fixing, end to end
│   │   │   ├── hrm-configuration-document/
│   │   │   │   └── SKILL.md       # CR Configuration Document (.md/.docx/PDF)
│   │   │   └── phx-write-sdd/
│   │   │       └── SKILL.md       # Architecture / Solution Design Document (ARCH-)
│   │   └── README.md
│   ├── dba-kit/                  # Database tooling for DBAs
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json       # Manifest (version: 1.0.0 — see Versioning); also
│   │   │                         # declares the phx-dbexplorer MCP server
│   │   ├── skills/
│   │   │   └── phx-sql-standards-review/
│   │   │       └── SKILL.md       # Review-only OLD/NEW SQL standards sign-off
│   │   └── README.md
│   ├── org-standards/            # Product knowledge for every role
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json       # Manifest (version: 6.0.0 — see Versioning)
│   │   ├── skills/
│   │   │   └── phx-product-context/
│   │   │       └── SKILL.md       # PeoplesHR product knowledge from the WeKnora KBs
│   │   └── README.md
│   └── ba-kit/                   # Business Analyst tooling — the FRD authoring skill
│       ├── .claude-plugin/
│       │   └── plugin.json       # Manifest (version: 3.0.0 — see Versioning)
│       ├── skills/
│       │   └── phx-write-frd/
│       │       └── SKILL.md       # Feature Requirements Document (FRD-)
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
| `ba-kit` | Business Analysts only | Same test, for BAs — the FRD authoring skill, `phx-write-frd` |
| `org-standards` | Every role | The shared product-knowledge skill, `phx-product-context` |

A new domain gets its **own** plugin under `plugins/`, never a corner of an existing
one. The test is *who would ever invoke this* — not which plugin already declares the
supporting server. A developer-only skill belongs in `dev-kit` even when its MCP
server sits elsewhere. When a server is genuinely needed by two audiences, each
plugin that needs it declares it; the duplicate declarations resolve to one server
at run time and are the intended cost of clean boundaries.

> **`org-standards` is the shared plugin again, as of `6.0.0`.** The developer
> `phx-product-context` (from `dev-kit`) and the BA `phx-business-context` were
> merged into one `phx-product-context`, used by developers doing solution
> engineering and by Business Analysts writing a PRD or eliciting requirements. It
> lives in `org-standards`, which every role now installs. With only one
> product-knowledge skill left, nothing misroutes and **every plugin is safe
> alongside every other**. See [`CLAUDE.md`](CLAUDE.md#rules).

## What's in `dev-kit`

The hands-on build skills and the solution design authoring skill. Five skills and
no MCP server — see
[`plugins/dev-kit/README.md`](plugins/dev-kit/README.md) for what each one wants
from your environment.

| Source | Skill | Notes |
| --- | --- | --- |
| **This repo (own skill)** | `hrm-deployment-script` | PHR-specific: reformat/scaffold HRM-DB MSSQL deployment SQL, **.NET Framework only**. |
| **This repo (own skill)** | `hrm-notification` | Builds a module email notification on the `HRM-JS45-SERVICE` Job Scheduler — four views, claim column, `HS_HR_JS_*` config rows, HTML template. A notification is **data, not code**. |
| **This repo (own skill)** | `phx-debugger` | Fixes an Azure DevOps bug end to end from its bug ID — investigation, fix plan, implementation, RCA, status change. Needs the `superpowers` plugin and a per-developer Azure DevOps MCP server. |
| **This repo (own skill)** | `hrm-configuration-document` | Writes the organization-standard Configuration Document for a finished CR from developer notes — house `.md`, branded `.docx` and PDF for the SharePoint library. Asks the developer for every missing fact. |
| **This repo (own skill)** | `phx-write-sdd` | Authors the **SDD — Architecture / Solution Design Document** (`ARCH-` prefix) against the template and sample read live from the PHR-X project wiki on every run. Resolves every cross-module touchpoint the linked FRD left open into a technical decision. Never invents a table, column, endpoint or name — it stops and asks. Needs a per-developer Azure DevOps MCP server. |

The first four shipped in `org-standards` up to `2.11.1` and moved here in
`org-standards` `3.0.0`; nothing about them changed but the slash-command prefix,
from `/org-standards:` to `/dev-kit:`. `phx-write-sdd` is new in `dev-kit` `2.1.0`.
`phx-product-context` lived here from `2.0.0` until `3.0.0`, when it was merged with
`phx-business-context` and moved to `org-standards` — install that plugin alongside
this one to keep it.

`hrm-notification` and `hrm-deployment-script` are much more useful with a
database to inspect, which is what `dba-kit`'s `phx-dbexplorer` gives them — so
install both plugins if you want that. The Azure DevOps server that `phx-debugger`
and `phx-write-sdd` both need was always yours to add and still is — it is the
same server for both. `phx-write-sdd`'s business companion, `phx-write-frd`, ships
in `ba-kit`; see [Installing as a Business
Analyst](#installing-as-a-business-analyst).

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

**Product knowledge, for every role.** One skill, no MCP server of its own.

| Source | Skill | Notes |
| --- | --- | --- |
| **This repo (own skill)** | `phx-product-context` | Acquires grounded, cited PeoplesHR context before solution engineering (developers) or PRD / FRD writing and requirement elicitation (Business Analysts). Searches the four WeKnora knowledge bases — `PeoplesHR Module Behaviour Brief`, `PeoplesHR Findings-Register`, `Product Development`, `PeoplesHR Academy` — one call per base, in parallel, weighted by the task. Needs the **weknora-peopleshr-product-knowledge** MCP server connected in your own Claude Code or Claude Desktop. |

New in `6.0.0`: it merges the old developer `phx-product-context` (`dev-kit`) and the
BA `phx-business-context` (`org-standards`) into one skill, rewritten from scratch.
The plugin no longer declares the old `weknora` MCP server, and
`WEKNORA_MCP_TOKEN` is no longer needed.

> **Before `phx-product-context` will work**, connect the
> weknora-peopleshr-product-knowledge MCP server in Claude Code (`/mcp`) or as a
> connector in Claude Desktop. The plugin deliberately does not ship it. Without
> it the skill stops and says so rather than answering from general knowledge.

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
want `dev-kit`, `dba-kit` and `org-standards`:

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install dev-kit@phr-foundry
claude plugin install dba-kit@phr-foundry
claude plugin install org-standards@phr-foundry
```

Each skill is namespaced under its **own** plugin, so invoke it with:

```shell
/dev-kit:hrm-deployment-script
/dev-kit:hrm-notification
/dev-kit:phx-debugger <bug-id>
/dev-kit:hrm-configuration-document
/dev-kit:phx-write-sdd
/dba-kit:phx-sql-standards-review
/org-standards:phx-product-context
/ba-kit:phx-write-frd
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
    "dba-kit@phr-foundry": true,
    "org-standards@phr-foundry": true
  }
}
```

## Installing as a Business Analyst

Business Analysts install `org-standards` and `ba-kit`:

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install org-standards@phr-foundry
claude plugin install ba-kit@phr-foundry
```

`org-standards` gives you `phx-product-context` — see
[What's in `org-standards`](#whats-in-org-standards) above. `ba-kit` gives you
`phx-write-frd`, the skill that authors the **FRD — Feature Requirements Document**
against the template held in the PHR-X project wiki. It needs your **own**
per-developer Azure DevOps MCP server — the FRD template lives in the wiki and there
is no local copy. See [`plugins/ba-kit/README.md`](plugins/ba-kit/README.md) and
[`INSTALL.md`](plugins/ba-kit/skills/phx-write-frd/INSTALL.md).

`phx-write-frd`'s technical companion, `phx-write-sdd`, ships in `dev-kit` — the
SDD is the Solutioning Engineer's document, not the BA's. Anyone doing both jobs can
install every plugin; none of them conflict.

## Versioning: manual semver in `plugin.json`

Each plugin declares an explicit `version` in its `plugin.json` (`dev-kit` is at
`3.0.0`, `org-standards` at `6.0.0`, `ba-kit` at `3.0.0`, `dba-kit` at `1.0.0`). Claude Code resolves a
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
/plugin install dba-kit@phr-foundry
/plugin install ba-kit@phr-foundry
/plugin install org-standards@phr-foundry
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
