# org-standards

PeoplesHR organization standards, packaged as a Claude Code plugin and
distributed through the [`phr-foundry`](../../README.md) marketplace.

> **Moved in `3.0.0`:** `hrm-deployment-script`, `hrm-notification` and
> `phx-debugger` now ship in the [`dev-kit`](../dev-kit/README.md) plugin. If you
> use them, `claude plugin install dev-kit@phr-foundry` — it installs alongside
> this plugin without conflict.

## Skills

| Skill                     | What it does                                                                 |
| ------------------------- | ----------------------------------------------------------------------------|
| `phx-sql-standards-review`| Review-only sign-off on a T-SQL script against the OLD hSenid HRM (.NET Framework) or NEW PeoplesHR PHR-X (.NET Core) SQL standard, auto-detecting which system it targets. Never edits the SQL. |
| `phx-product-context`     | Retrieves PeoplesHR module behaviour from the product documentation in WeKnora before answering, and cites the documents used. Technical voice; `Product Development` deep, `PeoplesHR Academy` shallow. |

Invoke either of them explicitly with its plugin-prefixed slash command —
`/org-standards:phx-sql-standards-review`, `/org-standards:phx-product-context` —
or let Claude load it automatically: `phx-sql-standards-review` when a T-SQL
script needs review or sign-off, `phx-product-context` whenever a question turns
on how a PeoplesHR module actually behaves.

`phx-product-context` has a prerequisite: `WEKNORA_MCP_TOKEN` in your own
environment, for the `weknora` MCP server below. See
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

> `phx-dbexplorer` is still declared here even though the skills that lean on it
> hardest — `hrm-notification` and `hrm-deployment-script` — moved to `dev-kit`, so a
> developer who wants schema browsing installs this plugin too.
>
> That is a **leftover, not the design.** Each plugin is meant to hold only what its
> own audience uses, and schema browsing is developer-only — so `phx-dbexplorer`
> belongs in `dev-kit`. It has not been moved because doing so re-registers the server
> for everyone already running it. See the audience rule in
> [`CLAUDE.md`](../../CLAUDE.md#rules).

> ⚠️ **Do not install `ba-kit` alongside this plugin.** Its `phx-business-context`
> skill searches the same two knowledge bases in the opposite order and answers in
> business rather than technical terms; with both present they compete on question
> wording and misroute. Anyone doing both jobs keeps `org-standards`.
> `dev-kit` is not affected — it ships no product-knowledge skill.

## Notes

- **Versioned by semver** in `plugin.json` (currently `3.0.0`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- Skills and two MCP servers: no agents or hooks.
