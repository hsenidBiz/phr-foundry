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
│   └── org-standards/            # One plugin
│       ├── .claude-plugin/
│       │   └── plugin.json       # Manifest (version: 2.4.0 — see Versioning);
│       │                         # also declares the phx-dbexplorer MCP server
│       ├── skills/
│       │   ├── hrm_sql_standards/
│       │   │   └── SKILL.md       # PHR SQL deployment-script standards
│       │   └── phx_debugger/
│       │       └── SKILL.md       # Azure DevOps bug fixing, end to end
│       └── README.md
├── .github/
│   └── workflows/
│       └── validate.yml          # CI: runs `claude plugin validate .` on PRs into main
└── docs/
    ├── README.md                 # (Azure repo template file — reserved)
    └── USAGE.md                  # User-facing install/update/usage guide
```

## What's in `org-standards`

The plugin ships one skill of its own, plus one MCP server.

| Source | Skill(s) / MCP server | Notes |
| --- | --- | --- |
| **This repo (own skill)** | `hrm_sql_standards` | PHR-specific: reformat/scaffold HRM-DB MSSQL deployment SQL, **.NET Framework only**. |
| **Separate repo, fetched at run time** | `phx-dbexplorer` (MCP server) | Schema browsing for SQL Server/Postgres. Source: [`hsenidBiz/phx-dbexplorer`](https://github.com/hsenidBiz/phx-dbexplorer) — a **public** .NET repo, not vendored here. `plugin.json` runs it via `npx -y github:hsenidBiz/phx-dbexplorer`, which pulls the prebuilt binary for your OS/arch from that repo's GitHub Releases on first use (the repo must stay public — the download is unauthenticated). |

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

The skill is namespaced under the plugin, so invoke it with:

```shell
/org-standards:hrm_sql_standards
```

Claude also loads the skill automatically when you work on SQL in a
.NET Framework project (see the skill's `description`).

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

## Versioning: manual semver in `plugin.json`

Each plugin declares an explicit `version` in its `plugin.json` (currently
`2.4.0`). Claude Code resolves a plugin's version from the first of these that
is set:

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
