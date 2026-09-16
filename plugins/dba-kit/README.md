# dba-kit

**Audience: DBAs.** Database tooling for PeoplesHR, packaged as a Claude Code
plugin and distributed through the [`phr-foundry`](../../README.md) marketplace.

> **New in `org-standards` `4.0.0`:** `phx-sql-standards-review` and the
> `phx-dbexplorer` MCP server moved out of `org-standards` and into this plugin.
> Nothing about either changed — only the slash-command prefix, from
> `/org-standards:phx-sql-standards-review` to
> `/dba-kit:phx-sql-standards-review`. Install with
> `claude plugin install dba-kit@phr-foundry`.

## Skills

| Skill                      | What it does                                                                |
| -------------------------- | --------------------------------------------------------------------------- |
| `phx-sql-standards-review` | Review-only sign-off on a T-SQL script against the OLD hSenid HRM (.NET Framework) or NEW PeoplesHR PHR-X (.NET Core) SQL standard, auto-detecting which system it targets. Never edits the SQL. |

Invoke it explicitly with its plugin-prefixed slash command —
`/dba-kit:phx-sql-standards-review` — or let Claude load it automatically
whenever a T-SQL script needs review or sign-off.

## MCP servers

| Server           | What it does                                                             |
| ---------------- | ------------------------------------------------------------------------ |
| `phx-dbexplorer` | Browses a SQL Server or Postgres schema — tables, procedures, functions.  |

`phx-dbexplorer`'s source lives in
[`hsenidBiz/phx-dbexplorer`](https://github.com/hsenidBiz/phx-dbexplorer) — a
public .NET repo, not vendored here — and is fetched at run time via
`npx -y github:hsenidBiz/phx-dbexplorer`, which pulls the prebuilt binary for
your OS/arch from that repo's GitHub Releases on first use. No .NET SDK or
runtime needed.

Set `PHX_DB_TYPE` and `PHX_DB_CONNECTION_STRING` (and optionally
`PHX_DB_SCHEMA_FILTER`) in your own shell **before** launching Claude Code —
these are per-developer database credentials and are never shipped with the
plugin. `PHX_DB_TYPE` must be exactly `mssql` or `postgres` (aliases
`sqlserver`/`postgresql` also work); anything else is rejected and the server
fails to start, showing up in `/mcp` as a bare reconnect error. Restart Claude
Code after setting or changing these — a running session won't pick them up.
See the [usage guide](../../docs/USAGE.md#phx-dbexplorer--database-schema-browsing)
for the full variable table.

## Installing alongside other plugins

`dba-kit` ships no product-knowledge skill, so it is safe next to any other
`phr-foundry` plugin. It is the plugin to install if you want schema browsing
for `dev-kit`'s `hrm-notification` and `hrm-deployment-script` — that is where
`phx-dbexplorer` now lives.

## Notes

- **Versioned by semver** in `plugin.json` (currently `1.0.0`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- One skill and one MCP server: no agents or hooks.
