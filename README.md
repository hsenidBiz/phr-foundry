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
│   ├── dev-kit/                  # Developer tooling — build skills + developer product knowledge
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json       # Manifest (version: 2.1.0 — see Versioning); also
│   │   │                         # declares the weknora MCP server
│   │   ├── skills/
│   │   │   ├── hrm-deployment-script/
│   │   │   │   └── SKILL.md       # PHR SQL deployment-script standards, .NET Framework only
│   │   │   ├── hrm-notification/
│   │   │   │   └── SKILL.md       # Job Scheduler email notifications
│   │   │   ├── phx-debugger/
│   │   │   │   └── SKILL.md       # Azure DevOps bug fixing, end to end
│   │   │   ├── hrm-configuration-document/
│   │   │   │   └── SKILL.md       # CR Configuration Document (.md/.docx/PDF)
│   │   │   ├── phx-product-context/
│   │   │   │   └── SKILL.md       # PeoplesHR product knowledge from WeKnora (developer)
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
│   ├── org-standards/            # BA product-knowledge plugin — never install with dev-kit
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json       # Manifest (version: 5.0.0 — see Versioning); also
│   │   │                         # declares the weknora MCP server
│   │   ├── skills/
│   │   │   └── phx-business-context/
│   │   │       └── SKILL.md       # PeoplesHR product knowledge from WeKnora (BA)
│   │   └── README.md
│   └── ba-kit/                   # Business Analyst tooling — the FRD authoring skill
│       ├── .claude-plugin/
│       │   └── plugin.json       # Manifest (version: 2.1.0); declares the weknora MCP server
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
| `org-standards` | Business Analysts | The BA product-knowledge skill, `phx-business-context` |

A new domain gets its **own** plugin under `plugins/`, never a corner of an existing
one. The test is *who would ever invoke this* — not which plugin already declares the
supporting server. A developer-only skill belongs in `dev-kit` even when its MCP
server sits elsewhere. When a server is genuinely needed by two audiences — `weknora`
today — each plugin that needs it declares it; the duplicate declarations resolve to
one server at run time and are the intended cost of clean boundaries.

> **`org-standards` no longer means "everyone".** It was realigned in `5.0.0`:
> `phx-product-context` moved to `dev-kit`, where its developer-only audience
> belongs, and `phx-business-context` moved in from `ba-kit`. `org-standards` is
> now the Business Analyst home for *product knowledge*, while `ba-kit` holds the
> BA's own tooling — `phx-write-frd` since `2.1.0`. A Business Analyst installs
> both. The consequence is that the never-install-together pair is now **`dev-kit`
> and `org-standards`**. See [`CLAUDE.md`](CLAUDE.md#rules).

## What's in `dev-kit`

The hands-on build skills, the developer product-knowledge skill and the solution
design authoring skill. Six skills and one MCP server — see
[`plugins/dev-kit/README.md`](plugins/dev-kit/README.md) for what each one wants
from your environment.

| Source | Skill | Notes |
| --- | --- | --- |
| **This repo (own skill)** | `hrm-deployment-script` | PHR-specific: reformat/scaffold HRM-DB MSSQL deployment SQL, **.NET Framework only**. |
| **This repo (own skill)** | `hrm-notification` | Builds a module email notification on the `HRM-JS45-SERVICE` Job Scheduler — four views, claim column, `HS_HR_JS_*` config rows, HTML template. A notification is **data, not code**. |
| **This repo (own skill)** | `phx-debugger` | Fixes an Azure DevOps bug end to end from its bug ID — investigation, fix plan, implementation, RCA, status change. Needs the `superpowers` plugin and a per-developer Azure DevOps MCP server. |
| **This repo (own skill)** | `hrm-configuration-document` | Writes the organization-standard Configuration Document for a finished CR from developer notes — house `.md`, branded `.docx` and PDF for the SharePoint library. Asks the developer for every missing fact. |
| **This repo (own skill)** | `phx-product-context` | Grounds any answer about PeoplesHR module behaviour in the product documentation held in WeKnora, and cites the documents used. Searches `Product Development` deep and `PeoplesHR Academy` shallow, and answers technically. Needs `WEKNORA_MCP_TOKEN`. |
| **This repo (own skill)** | `phx-write-sdd` | Authors the **SDD — Architecture / Solution Design Document** (`ARCH-` prefix) against the template and sample read live from the PHR-X project wiki on every run. Resolves every cross-module touchpoint the linked FRD left open into a technical decision. Never invents a table, column, endpoint or name — it stops and asks. Needs a per-developer Azure DevOps MCP server. |
| **Remote server on the WeKnora VM** | `weknora` (MCP server) | Read-only retrieval from the `Product Development` and `PeoplesHR Academy` knowledge bases at `https://weknora.phrsandbox.dev/mcp`. A `type: "http"` server — nothing is downloaded or run locally. Read-only is enforced by a `retrieve`-only API key on the server, not by the advertised tool list. |

The first four shipped in `org-standards` up to `2.11.1` and moved here in
`org-standards` `3.0.0`. `phx-product-context` moved here in `org-standards`
`5.0.0` / `dev-kit` `2.0.0`. Nothing about any of the skills themselves changed —
only the slash-command prefix, from `/org-standards:` to `/dev-kit:`.
`phx-write-sdd` is new in `dev-kit` `2.1.0`.

`hrm-notification` and `hrm-deployment-script` are much more useful with a
database to inspect, which is what `dba-kit`'s `phx-dbexplorer` gives them — so
install both plugins if you want that. The Azure DevOps server that `phx-debugger`
and `phx-write-sdd` both need was always yours to add and still is — it is the
same server for both. `phx-write-sdd`'s business companion, `phx-write-frd`, ships
in `ba-kit`; see [Installing as a Business
Analyst](#installing-as-a-business-analyst).

> ⚠️ **Install `dev-kit` or `org-standards`, never both** — see the warning under
> [What's in `org-standards`](#whats-in-org-standards) below.
>
> **Before `weknora` will work**, you must set `WEKNORA_MCP_TOKEN` in your own
> environment — one token shared by the whole team, handed out through your
> credential channel and **never committed to this public repo**. Set it and
> **then** restart Claude Code: Windows reads user environment variables at
> process start, so a session that was already running reports a
> missing-variable warning for `weknora` even though the token is stored
> correctly. See
> [`INSTALL.md`](plugins/dev-kit/skills/phx-product-context/INSTALL.md).

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

**The Business Analyst plugin.** One skill of its own, plus one MCP server.

| Source | Skill / MCP server | Notes |
| --- | --- | --- |
| **This repo (own skill)** | `phx-business-context` | Answers PeoplesHR questions in business terms — what the user sees, the process, the rules and the configuration — grounded in the product documentation held in WeKnora, and citing the documents used. Searches `PeoplesHR Academy` deep and `Product Development` shallow. Needs `WEKNORA_MCP_TOKEN`. |
| **Remote server on the WeKnora VM** | `weknora` (MCP server) | Read-only retrieval from the `Product Development` and `PeoplesHR Academy` knowledge bases at `https://weknora.phrsandbox.dev/mcp`. A `type: "http"` server — nothing is downloaded or run locally. Read-only is enforced by a `retrieve`-only API key on the server, not by the advertised tool list. |

`phx-business-context` moved here from `ba-kit` in `org-standards` `5.0.0`, at
the same time `phx-product-context` moved out to `dev-kit`. The skill itself is
unchanged — only the prefix, from `/ba-kit:` to `/org-standards:`.

> ⚠️ **Install `org-standards` or `dev-kit`, never both.**
> `phx-business-context` and `phx-product-context` search the same two knowledge
> bases in opposite orders and answer in different voices. With both present they
> compete on question wording and misroute. Business Analysts take
> `org-standards`; developers take `dev-kit`; anyone genuinely doing both jobs
> takes `dev-kit`, whose developer skill keeps the business rationale as a
> secondary.
>
> This applies **only** to that pair. `dba-kit` and `ba-kit` ship no
> product-knowledge skill, so both are safe alongside either one — a BA who also
> writes deployment SQL can take `org-standards` + `dba-kit`.

> **Before `weknora` will work**, you must set `WEKNORA_MCP_TOKEN` in your own
> environment — one token shared by the whole team, handed out through your
> credential channel and **never committed to this public repo**. Set it and
> **then** restart Claude Code: Windows reads user environment variables at
> process start, so a session that was already running reports a
> missing-variable warning for `weknora` even though the token is stored
> correctly. See
> [`INSTALL.md`](plugins/org-standards/skills/phx-business-context/INSTALL.md).

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
want `dev-kit` and `dba-kit` — **not** `org-standards`, which is the Business
Analyst plugin and conflicts with `dev-kit`:

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install dev-kit@phr-foundry
claude plugin install dba-kit@phr-foundry
```

Each skill is namespaced under its **own** plugin, so invoke it with:

```shell
/dev-kit:hrm-deployment-script
/dev-kit:hrm-notification
/dev-kit:phx-debugger <bug-id>
/dev-kit:hrm-configuration-document
/dev-kit:phx-product-context
/dev-kit:phx-write-sdd
/dba-kit:phx-sql-standards-review
/org-standards:phx-business-context
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
    "dba-kit@phr-foundry": true
  }
}
```

## Installing as a Business Analyst

Business Analysts install `org-standards` instead of `dev-kit`:

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install org-standards@phr-foundry
```

That gives you `phx-business-context` and the `weknora` MCP server — see
[What's in `org-standards`](#whats-in-org-standards) above and
[`plugins/org-standards/README.md`](plugins/org-standards/README.md). You also
need `WEKNORA_MCP_TOKEN`.

**Install `ba-kit` as well.** It was an empty reserved slot from `2.0.0`, when
`phx-business-context` moved out of it into `org-standards`, until `2.1.0` filled
it with `phx-write-frd` — the skill that authors the **FRD — Feature Requirements
Document** against the template held in the PHR-X project wiki:

```shell
claude plugin install ba-kit@phr-foundry
```

The two do not compete: only product-knowledge skills misroute against each
other, and `phx-write-frd` is not one. It needs your **own** per-developer Azure
DevOps MCP server — the FRD template lives in the wiki and there is no local copy.
See [`plugins/ba-kit/README.md`](plugins/ba-kit/README.md) and
[`INSTALL.md`](plugins/ba-kit/skills/phx-write-frd/INSTALL.md).

`phx-write-frd`'s technical companion, `phx-write-sdd`, ships in `dev-kit` — the
SDD is the Solutioning Engineer's document, not the BA's. A BA does **not** install
`dev-kit` for it; that would pull in `phx-product-context` and misroute against
`phx-business-context`.

## Versioning: manual semver in `plugin.json`

Each plugin declares an explicit `version` in its `plugin.json` (`dev-kit` is at
`2.1.0`, `org-standards` at `5.0.0`, `ba-kit` at `2.1.0`, `dba-kit` at `1.0.0`). Claude Code resolves a
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
