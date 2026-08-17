# org-standards

PeoplesHR organization standards, packaged as a Claude Code plugin and
distributed through the [`phr-foundry`](../../README.md) marketplace.

## Skills

| Skill                | What it does                                                                 |
| -------------------- | --------------------------------------------------------------------------- |
| `hrm_sql_standards`  | Reformats SQL scripts into PHR standard format. **.NET Framework only.**     |
| `phx_debugger`       | Fixes an Azure DevOps bug end to end from its bug ID — investigation, fix plan, implementation, RCA and status. |

Invoke either explicitly with its plugin-prefixed slash command —
`/org-standards:hrm_sql_standards`, `/org-standards:phx_debugger 141827` — or let
Claude load it automatically: `hrm_sql_standards` when you write, edit or review
SQL in a .NET Framework project, `phx_debugger` when a message carries an ADO bug
ID with a request to investigate or fix it.

`phx_debugger` has prerequisites the plugin deliberately does not ship — the
`superpowers` plugin and your own Azure DevOps MCP server. See
[`skills/phx_debugger/INSTALL.md`](skills/phx_debugger/INSTALL.md).

## MCP servers

| Server            | What it does                                                        |
| ----------------- | ------------------------------------------------------------------- |
| `phx-dbexplorer`  | Browses a SQL Server or Postgres schema — tables, procedures, functions. |

Its source lives in [`hsenidBiz/phx-dbexplorer`](https://github.com/hsenidBiz/phx-dbexplorer)
and is fetched at run time; set `PHX_DB_TYPE` and `PHX_DB_CONNECTION_STRING` in
your own shell before launching Claude Code.

## Notes

- **Versioned by semver** in `plugin.json` (currently `2.2.1`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- Skills and one MCP server: no agents or hooks.
