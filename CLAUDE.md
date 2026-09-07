# CLAUDE.md

Internal Claude Code **plugin marketplace** for PeoplesHR, hosted on GitHub.
One repo holds both the catalog and the plugins.

- Marketplace: `phr-foundry` · Owner: PeoplesHR <sanuja.a@peopleshr.com>
- Repo: `https://github.com/hsenidBiz/phr-foundry`

## Layout
- `.claude-plugin/marketplace.json` — catalog (lists plugins + relative-path sources).
  **Must stay at the repo root** so `claude plugin marketplace add <repo-url>` can find it.
- `plugins/org-standards/` — the one plugin
  - `.claude-plugin/plugin.json` — manifest. Also declares the plugin's one
    MCP server (see below).
  - `skills/hrm-deployment-script/SKILL.md` — its own skill: reformat SQL to PHR standard, **.NET Framework only**
  - `skills/phx-sql-standards-review/` — its own skill: review-only (never edits SQL) against
    either the OLD hSenid HRM (.NET Framework) or NEW PeoplesHR PHR-X (.NET Core) SQL
    standard, auto-detecting which system a script targets. Supporting files:
    `reference/OLD_SQL_Standards.md` and `reference/NEW_SQL_Standards.md`, the full source
    standards documents read by the skill during review. The whole folder ships together;
    `SKILL.md` alone is not the skill.
  - `skills/phx-debugger/SKILL.md` — its own skill: fix an Azure DevOps bug end to
    end from its bug ID. Supporting files: `INSTALL.md` (prerequisites the plugin
    deliberately does not ship — the `superpowers` plugin and a per-developer ADO
    MCP server) and `reference/` (`debugging-brief.md`, `rca-template.md`, both
    read by the subagents the skill spawns, not by the skill itself). The whole
    folder ships together; `SKILL.md` alone is not the skill.
  - MCP server `phx-dbexplorer` — schema-browsing tool for SQL Server/Postgres.
    Source lives in the separate public repo
    `https://github.com/hsenidBiz/phx-dbexplorer` (a .NET project, **not**
    vendored into this repo). `plugin.json`'s `mcpServers.phx-dbexplorer.command`
    runs it via `npx -y github:hsenidBiz/phx-dbexplorer`, which downloads the
    self-contained binary matching the developer's OS/arch from that repo's
    GitHub Releases on first use — no local .NET SDK/runtime, no npm registry
    publish step. Each developer must set `PHX_DB_TYPE` and
    `PHX_DB_CONNECTION_STRING` (and optionally `PHX_DB_SCHEMA_FILTER`) in their
    own shell environment before launching Claude Code — these are per-developer
    secrets and must never be committed to either repo.
- `.github/workflows/validate.yml` — runs `claude plugin validate .` on every PR into `main`
- `docs/` — Azure repo template dir, holds `docs/USAGE.md` (real content — see rule below).
  The other empty Azure template dirs (`deps/`, `scripts/`, `src/`) were removed since they
  held nothing but placeholder READMEs.

## Rules
- **Version lives in `plugin.json` only** (currently `2.9.0`). Bump the semver on every
  release — users only receive updates when it changes. Do NOT also set `version` in the
  marketplace entry; when both are set, `plugin.json` silently wins.
- **Skill names must start with `hrm-` or `phx-` and be kebab-case** — non-negotiable.
  The directory under `plugins/<plugin>/skills/` (which is also the skill's invocation
  name, e.g. `org-standards:hrm-my-skill`) must match `^(hrm|phx)-[a-z0-9]+(-[a-z0-9]+)*$`.
  Use `hrm-` for anything targeting the old .NET Framework HRM system, `phx-` for anything
  targeting PHR-X/.NET Core or general tooling. Enforced in CI by
  `.github/workflows/validate.yml`.
- **`docs/USAGE.md` must be updated in the same change whenever a skill is added, renamed,
  or removed** — non-negotiable. Add/update/remove its row in the relevant plugin's skill
  table (Plugin catalog section) and its own `#### What \`<skill>\` does` walkthrough
  (invocation, inputs, output). This is manual — `claude plugin validate .` does not check
  doc coverage, so a missed update won't fail CI, only reviewer eyes will catch it.
- New plugins: add a `plugins/<name>/` dir + a `marketplace.json` entry with
  `source: "./plugins/<name>"`, and a `version` in the plugin's `plugin.json`.
- Skills, plus the one `phx-dbexplorer` MCP server declared in `plugin.json` — no
  agents or hooks. Don't vendor the MCP server's source into this repo; it stays in
  its own repo and is fetched at run time via `npx github:...` (see Layout above).
- **No third-party marketplace dependencies.** `org-standards` previously declared
  `dependencies` on `superpowers` (`superpowers-dev`) and 14 `.NET` skill plugins
  (`dotnet-agent-skills`) — removed in the `2.0.0` release (see git history). Claude Code
  only auto-resolves a cross-marketplace dependency if the user has already run
  `claude plugin marketplace add` for that dependency's marketplace, so it was never a true
  one-shot install — developers still had to run extra `marketplace add` commands
  themselves, which defeated the point of bundling them. Don't re-add cross-marketplace
  `dependencies` unless Claude Code changes to auto-register unknown marketplaces on
  install.

## Validate
```
claude plugin validate .
```
