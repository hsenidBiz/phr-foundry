# org-standards

PeoplesHR organization standards, packaged as a Claude Code plugin and
distributed through the [`phr-foundry`](../../README.md) marketplace.

## Skills

| Skill                     | What it does                                                                 |
| ------------------------- | ----------------------------------------------------------------------------|
| `hrm-deployment-script`   | Reformats SQL scripts into PHR standard format. **.NET Framework only.**    |
| `phx-sql-standards-review`| Review-only sign-off on a T-SQL script against the OLD hSenid HRM (.NET Framework) or NEW PeoplesHR PHR-X (.NET Core) SQL standard, auto-detecting which system it targets. Never edits the SQL. |
| `phx-debugger`            | Fixes an Azure DevOps bug end to end from its bug ID — investigation, fix plan, implementation, RCA and status. |
| `hrm-notification`        | Builds a module email notification on the `HRM-JS45-SERVICE` Job Scheduler — four views, claim column, `HS_HR_JS_*` rows, HTML template. Data, never C#. |
| `phx-product-context`     | Retrieves PeoplesHR module behaviour from the product documentation in WeKnora before answering, and cites the documents used. Technical voice; `Product Development` deep, `PeoplesHR Academy` shallow. |

Invoke any of them explicitly with its plugin-prefixed slash command —
`/org-standards:hrm-deployment-script`, `/org-standards:phx-sql-standards-review`,
`/org-standards:phx-debugger 141827`, `/org-standards:hrm-notification`,
`/org-standards:phx-product-context` — or let Claude load it automatically:
`hrm-deployment-script` when you write, edit or review SQL in a .NET Framework
project, `phx-sql-standards-review` when a T-SQL script needs review or sign-off,
`phx-debugger` when a message carries an ADO bug ID with a request to investigate
or fix it, `hrm-notification` when you ask for an alert, reminder or email to be
sent when something happens in a module, `phx-product-context` whenever a question
turns on how a PeoplesHR module actually behaves.

`phx-debugger` has prerequisites the plugin deliberately does not ship — the
`superpowers` plugin and your own Azure DevOps MCP server. See
[`skills/phx-debugger/INSTALL.md`](skills/phx-debugger/INSTALL.md).

`phx-product-context` needs one too: `WEKNORA_MCP_TOKEN` in your own environment,
for the `weknora` MCP server below. See
[`skills/phx-product-context/INSTALL.md`](skills/phx-product-context/INSTALL.md).

## MCP servers

| Server            | What it does                                                        |
| ----------------- | ------------------------------------------------------------------- |
| `phx-dbexplorer`  | Browses a SQL Server or Postgres schema — tables, procedures, functions. |
| `weknora`         | Read-only retrieval from the `Product Development` and `PeoplesHR Academy` WeKnora knowledge bases. |

`phx-dbexplorer`'s source lives in
[`hsenidBiz/phx-dbexplorer`](https://github.com/hsenidBiz/phx-dbexplorer) and is
fetched at run time; set `PHX_DB_TYPE` and `PHX_DB_CONNECTION_STRING` in your own
shell before launching Claude Code.

`weknora` is a remote `type: "http"` server on the WeKnora VM
(`https://weknora.phrsandbox.dev/mcp`) — nothing is downloaded or run locally. Set
`WEKNORA_MCP_TOKEN` in your own environment and **then** restart Claude Code. It is
read-only because of the `retrieve`-only API key on the server, not because of the
tool list, which advertises all 28 WeKnora tools including writes.

> ⚠️ **Do not install `ba-kit` alongside this plugin.** Its `phx-business-context`
> skill searches the same two knowledge bases in the opposite order and answers in
> business rather than technical terms; with both present they compete on question
> wording and misroute. Anyone doing both jobs keeps `org-standards`.

## Notes

- **Versioned by semver** in `plugin.json` (currently `2.11.0`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- Skills and two MCP servers: no agents or hooks.
