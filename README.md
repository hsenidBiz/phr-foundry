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
│       │   └── plugin.json       # Manifest (version: 1.1.0 — see Versioning). Also
│       │                         # declares `dependencies` on third-party skill plugins.
│       ├── skills/
│       │   └── hrm_sql_standards/
│       │       └── SKILL.md       # The one skill this plugin ships itself
│       └── README.md
├── .github/
│   └── workflows/
│       └── validate.yml          # CI: runs `claude plugin validate .` on PRs into main
└── docs/
    ├── README.md                 # (Azure repo template file — reserved)
    └── USAGE.md                  # User-facing install/update/usage guide
```

## What's in `org-standards`

The plugin ships one skill of its own, plus 15 third-party skill plugins pulled in as
`dependencies` — installing `org-standards` installs all of it in one shot, and the
dependencies always track their upstream marketplace's latest release (no vendoring, no
manual re-sync).

| Source | Skill(s) | Notes |
| --- | --- | --- |
| **This repo (own skill)** | `hrm_sql_standards` | PHR-specific: reformat/scaffold HRM-DB MSSQL deployment SQL, **.NET Framework only**. |
| [obra/superpowers](https://github.com/obra/superpowers) (`superpowers`) | TDD, systematic debugging, brainstorming, code-review/collaboration workflows | Dependency, marketplace `superpowers-dev`. |
| [dotnet/skills](https://github.com/dotnet/skills) (`dotnet`, `dotnet-advanced`, `dotnet-data`, `dotnet-diag`, `dotnet-nuget`, `dotnet-upgrade`, `dotnet-maui`, `dotnet-ai`, `dotnet-template-engine`, `dotnet-test`, `dotnet-test-migration`, `dotnet-aspnetcore`, `dotnet-blazor`, `dotnet11`) | General .NET/C# development, testing, upgrades, ASP.NET Core, Blazor, MAUI, package management | Dependency, marketplace `dotnet-agent-skills`. `dotnet-msbuild` was deliberately excluded — it bundles an MCP server, which conflicts with this repo's skills-only rule. |

Both external marketplaces are allowlisted in `.claude-plugin/marketplace.json` via
`allowCrossMarketplaceDependenciesOn` — required for a cross-marketplace dependency to
resolve at all. See [`CLAUDE.md`](CLAUDE.md#third-party-skill-dependencies) for the
maintainer-facing rules on adding more (what disqualifies a candidate, e.g. bundled MCP
servers or non-installable skills), and
[`docs/USAGE.md`](docs/USAGE.md#plugin-catalog) for the user-facing catalog.

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
`1.1.0`). Claude Code resolves a plugin's version from the first of these that
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
