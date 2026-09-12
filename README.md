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
│   ├── org-standards/            # Developer plugin
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json       # Manifest (version: 2.11.0 — see Versioning); also
│   │   │                         # declares the phx-dbexplorer and weknora MCP servers
│   │   ├── skills/
│   │   │   ├── hrm-deployment-script/
│   │   │   │   └── SKILL.md       # PHR SQL deployment-script standards, .NET Framework only
│   │   │   ├── phx-sql-standards-review/
│   │   │   │   └── SKILL.md       # Review-only OLD/NEW SQL standards sign-off
│   │   │   ├── phx-debugger/
│   │   │   │   └── SKILL.md       # Azure DevOps bug fixing, end to end
│   │   │   ├── hrm-notification/
│   │   │   │   └── SKILL.md       # Job Scheduler email notifications
│   │   │   └── phx-product-context/
│   │   │       └── SKILL.md       # PeoplesHR product knowledge from WeKnora (developer)
│   │   └── README.md
│   └── ba-kit/                   # Business Analyst plugin — never install both
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

## What's in `org-standards`

The plugin ships five skills of its own, plus two MCP servers.

| Source | Skill(s) / MCP server | Notes |
| --- | --- | --- |
| **This repo (own skill)** | `hrm-deployment-script` | PHR-specific: reformat/scaffold HRM-DB MSSQL deployment SQL, **.NET Framework only**. |
| **This repo (own skill)** | `phx-sql-standards-review` | Review-only sign-off on a T-SQL script against either the OLD hSenid HRM (.NET Framework) or NEW PeoplesHR PHR-X (.NET Core) SQL standard, auto-detecting which system it targets. Never edits the SQL. |
| **This repo (own skill)** | `phx-debugger` | Fixes an Azure DevOps bug end to end from its bug ID — investigation, fix plan, implementation, RCA, status change. Needs the `superpowers` plugin and a per-developer Azure DevOps MCP server. |
| **This repo (own skill)** | `hrm-notification` | Builds a module email notification on the `HRM-JS45-SERVICE` Job Scheduler — four views, claim column, `HS_HR_JS_*` config rows, HTML template. A notification is **data, not code**. |
| **This repo (own skill)** | `phx-product-context` | Grounds any answer about PeoplesHR module behaviour in the product documentation held in WeKnora, and cites the documents used. Searches `Product Development` deep and `PeoplesHR Academy` shallow, and answers technically. Needs `WEKNORA_MCP_TOKEN`. |
| **Separate repo, fetched at run time** | `phx-dbexplorer` (MCP server) | Schema browsing for SQL Server/Postgres. Source: [`hsenidBiz/phx-dbexplorer`](https://github.com/hsenidBiz/phx-dbexplorer) — a **public** .NET repo, not vendored here. `plugin.json` runs it via `npx -y github:hsenidBiz/phx-dbexplorer`, which pulls the prebuilt binary for your OS/arch from that repo's GitHub Releases on first use (the repo must stay public — the download is unauthenticated). |
| **Remote server on the WeKnora VM** | `weknora` (MCP server) | Read-only retrieval from the `Product Development` and `PeoplesHR Academy` knowledge bases at `https://weknora.phrsandbox.dev/mcp`. A `type: "http"` server — nothing is downloaded or run locally. Read-only is enforced by a `retrieve`-only API key on the server, not by the advertised tool list. |

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

Point Claude Code at the GitHub repo, then install the plugin:

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install org-standards@phr-foundry
```

Each skill is namespaced under the plugin, so invoke it with:

```shell
/org-standards:hrm-deployment-script
/org-standards:phx-sql-standards-review
/org-standards:phx-debugger <bug-id>
/org-standards:hrm-notification
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
    "org-standards@phr-foundry": true
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

## Versioning: manual semver in `plugin.json`

Each plugin declares an explicit `version` in its `plugin.json` (`org-standards`
is at `2.11.0`, `ba-kit` at `1.0.0`). Claude Code resolves a plugin's version from
the first of these that is set:

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
/plugin install org-standards@phr-foundry
/reload-plugins
```

### Validate before you commit

```shell
claude plugin validate .
```

Or from inside a Claude Code session: `/plugin validate .`

## Adding another plugin later

1. Create `plugins/<new-plugin>/.claude-plugin/plugin.json` (name required;
   set a `version`, e.g. `1.0.0`, and bump it on each release).
2. Add an entry to the `plugins` array in `.claude-plugin/marketplace.json`
   with a `name` and a `source` of `./plugins/<new-plugin>`.
3. Add a section for it under **Plugin catalog** in [`docs/USAGE.md`](docs/USAGE.md),
   so users have a guide for the new skills.
4. Run `claude plugin validate .` and open a PR into `main` — the GitHub
   Actions workflow validates it automatically.
