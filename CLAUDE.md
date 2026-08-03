# CLAUDE.md

Internal Claude Code **plugin marketplace** for PeoplesHR, hosted on GitHub.
One repo holds both the catalog and the plugins.

- Marketplace: `phr-foundry` · Owner: PeoplesHR <sanuja.a@peopleshr.com>
- Repo: `https://github.com/hsenidBiz/phr-foundry`

## Layout
- `.claude-plugin/marketplace.json` — catalog (lists plugins + relative-path sources).
  **Must stay at the repo root** so `claude plugin marketplace add <repo-url>` can find it.
- `plugins/org-standards/` — the one plugin
  - `.claude-plugin/plugin.json` — manifest
  - `skills/hrm_sql_standards/SKILL.md` — its one skill: reformat SQL to PHR standard, **.NET Framework only**
- `.github/workflows/validate.yml` — runs `claude plugin validate .` on every PR into `main`
- `deps/`, `docs/`, `scripts/`, `src/` — Azure repo template dirs; leave in place.

## Rules
- **Version lives in `plugin.json` only** (currently `1.0.0`). Bump the semver on every
  release — users only receive updates when it changes. Do NOT also set `version` in the
  marketplace entry; when both are set, `plugin.json` silently wins.
- New plugins: add a `plugins/<name>/` dir + a `marketplace.json` entry with
  `source: "./plugins/<name>"`, and a `version` in the plugin's `plugin.json`.
- Skills only — no MCP servers, agents, or hooks.

## Validate
```
claude plugin validate .
```
