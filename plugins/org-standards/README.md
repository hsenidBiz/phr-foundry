# org-standards

PeoplesHR organization standards, packaged as a Claude Code plugin and
distributed through the [`phr-foundry`](../../README.md) marketplace.

> **Moved in `4.0.0`:** `phx-sql-standards-review` and the `phx-dbexplorer` MCP
> server now ship in the [`dba-kit`](../dba-kit/README.md) plugin. If you use
> either, `claude plugin install dba-kit@phr-foundry` — it installs alongside
> this plugin without conflict, and the skill's prefix becomes
> `/dba-kit:phx-sql-standards-review`.
>
> **Moved in `3.0.0`:** `hrm-deployment-script`, `hrm-notification` and
> `phx-debugger` now ship in the [`dev-kit`](../dev-kit/README.md) plugin.

## Skills

| Skill                     | What it does                                                                 |
| ------------------------- | ----------------------------------------------------------------------------|
| `phx-product-context`     | Retrieves PeoplesHR module behaviour from the product documentation in WeKnora before answering, and cites the documents used. Technical voice; `Product Development` deep, `PeoplesHR Academy` shallow. |

Invoke it explicitly with its plugin-prefixed slash command —
`/org-standards:phx-product-context` — or let Claude load it automatically
whenever a question turns on how a PeoplesHR module actually behaves.

`phx-product-context` has a prerequisite: `WEKNORA_MCP_TOKEN` in your own
environment, for the `weknora` MCP server below. See
[`skills/phx-product-context/INSTALL.md`](skills/phx-product-context/INSTALL.md).

## MCP servers

| Server            | What it does                                                        |
| ----------------- | ------------------------------------------------------------------- |
| `weknora`         | Read-only retrieval from the `Product Development` and `PeoplesHR Academy` WeKnora knowledge bases. |

`weknora` is a remote `type: "http"` server on the WeKnora VM
(`https://weknora.phrsandbox.dev/mcp`) — nothing is downloaded or run locally. Set
`WEKNORA_MCP_TOKEN` in your own environment and **then** restart Claude Code. It is
read-only because of the `retrieve`-only API key on the server, not because of the
tool list, which advertises all 28 WeKnora tools including writes.

> ⚠️ **Do not install `ba-kit` alongside this plugin.** Its `phx-business-context`
> skill searches the same two knowledge bases in the opposite order and answers in
> business rather than technical terms; with both present they compete on question
> wording and misroute. Anyone doing both jobs keeps `org-standards`.
> `dev-kit` and `dba-kit` are not affected — neither ships a product-knowledge skill.

## Notes

- **Versioned by semver** in `plugin.json` (currently `4.0.0`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- One skill and one MCP server: no agents or hooks.
