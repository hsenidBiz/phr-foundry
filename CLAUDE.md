# CLAUDE.md

Internal Claude Code **plugin marketplace** for PeoplesHR, hosted on GitHub.
One repo holds both the catalog and the plugins.

- Marketplace: `phr-foundry` · Owner: PeoplesHR <sanuja.a@peopleshr.com>
- Repo: `https://github.com/hsenidBiz/phr-foundry`

## Layout
- `.claude-plugin/marketplace.json` — catalog (lists plugins + relative-path sources).
  **Must stay at the repo root** so `claude plugin marketplace add <repo-url>` can find it.
- `plugins/org-standards/` — the one plugin
  - `.claude-plugin/plugin.json` — manifest. Also declares `dependencies` on curated
    third-party skill plugins (see below) — installing `org-standards` auto-installs them.
  - `skills/hrm_sql_standards/SKILL.md` — its own skill: reformat SQL to PHR standard, **.NET Framework only**
- `.github/workflows/validate.yml` — runs `claude plugin validate .` on every PR into `main`
- `docs/` — Azure repo template dir, holds `docs/USAGE.md` (real content — see rule below).
  The other empty Azure template dirs (`deps/`, `scripts/`, `src/`) were removed since they
  held nothing but placeholder READMEs.

## Rules
- **Version lives in `plugin.json` only** (currently `1.1.0`). Bump the semver on every
  release — users only receive updates when it changes. Do NOT also set `version` in the
  marketplace entry; when both are set, `plugin.json` silently wins.
- New plugins: add a `plugins/<name>/` dir + a `marketplace.json` entry with
  `source: "./plugins/<name>"`, and a `version` in the plugin's `plugin.json`.
- Skills only — no MCP servers, agents, or hooks. This also gates which third-party
  plugins can be added as **dependencies**: only pure-skill plugins qualify (e.g. we
  deliberately excluded `dotnet-msbuild` from the `dotnet-agent-skills` marketplace
  because it bundles an MCP server). Don't add a dependency that brings one in without
  revisiting this rule first.

## Third-party skill dependencies
`org-standards/.claude-plugin/plugin.json` depends on plugins from two external
marketplaces to give developers a one-shot install of general-purpose skills alongside
PHR's own:
- `superpowers` from `superpowers-dev` (https://github.com/obra/superpowers) — TDD,
  debugging, and collaboration-workflow skills.
- 14 `.NET` skill plugins from `dotnet-agent-skills` (https://github.com/dotnet/skills) —
  `dotnet`, `dotnet-advanced`, `dotnet-data`, `dotnet-diag`, `dotnet-nuget`,
  `dotnet-upgrade`, `dotnet-maui`, `dotnet-ai`, `dotnet-template-engine`, `dotnet-test`,
  `dotnet-test-migration`, `dotnet-aspnetcore`, `dotnet-blazor`, `dotnet11`.

Both external marketplaces are listed in the root `marketplace.json`'s
`allowCrossMarketplaceDependenciesOn` — required or cross-marketplace dependencies fail
to resolve. Dependency entries are unversioned (bare `name`/`marketplace` pairs), so they
always track the upstream marketplace's latest tagged release — no manual sync needed
when the upstream authors ship updates.

Considered and rejected: `microsoftdocs/mcp` (bundles an MCP server — violates the
skills-only rule), `anthropics/skills` `doc-coauthoring` (not independently installable —
bundled inside a 12-skill `example-skills` plugin), and `github/awesome-copilot`
`skills/dotnet-best-practices` (that repo is a GitHub Copilot marketplace, not a Claude
Code one — the skill isn't packaged as an installable Claude Code plugin at all).

## Validate
```
claude plugin validate .
```
