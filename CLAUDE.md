# CLAUDE.md

Internal Claude Code **plugin marketplace** for PeoplesHR, hosted on GitHub.
One repo holds both the catalog and the plugins.

- Marketplace: `phr-foundry` · Owner: PeoplesHR <sanuja.a@peopleshr.com>
- Repo: `https://github.com/hsenidBiz/phr-foundry`

## Layout
- `.claude-plugin/marketplace.json` — catalog (lists plugins + relative-path sources).
  **Must stay at the repo root** so `claude plugin marketplace add <repo-url>` can find it.
- `plugins/org-standards/` — the one plugin
  - `.claude-plugin/plugin.json` — manifest.
  - `skills/hrm_sql_standards/SKILL.md` — its own skill: reformat SQL to PHR standard, **.NET Framework only**
- `.github/workflows/validate.yml` — runs `claude plugin validate .` on every PR into `main`
- `docs/` — Azure repo template dir, holds `docs/USAGE.md` (real content — see rule below).
  The other empty Azure template dirs (`deps/`, `scripts/`, `src/`) were removed since they
  held nothing but placeholder READMEs.

## Rules
- **Version lives in `plugin.json` only** (currently `2.0.0`). Bump the semver on every
  release — users only receive updates when it changes. Do NOT also set `version` in the
  marketplace entry; when both are set, `plugin.json` silently wins.
- New plugins: add a `plugins/<name>/` dir + a `marketplace.json` entry with
  `source: "./plugins/<name>"`, and a `version` in the plugin's `plugin.json`.
- Skills only — no MCP servers, agents, or hooks.
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
