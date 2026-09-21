# org-standards

PeoplesHR organization standards, packaged as a Claude Code plugin and
distributed through the [`phr-foundry`](../../README.md) marketplace.

**Audience: Business Analysts.** Since `5.0.0` this plugin carries the BA
product-knowledge skill; developers install [`dev-kit`](../dev-kit/README.md)
instead.

> **Moved in `5.0.0`:** `phx-product-context` now ships in the
> [`dev-kit`](../dev-kit/README.md) plugin, and `phx-business-context` moved
> here from [`ba-kit`](../ba-kit/README.md). If you used
> `/org-standards:phx-product-context`, install `dev-kit` and switch to
> `/dev-kit:phx-product-context` — and uninstall `org-standards`, because the
> two product-knowledge skills must not be installed together.
>
> **Moved in `4.0.0`:** `phx-sql-standards-review` and the `phx-dbexplorer` MCP
> server now ship in the [`dba-kit`](../dba-kit/README.md) plugin.
>
> **Moved in `3.0.0`:** `hrm-deployment-script`, `hrm-notification` and
> `phx-debugger` now ship in the [`dev-kit`](../dev-kit/README.md) plugin.

## Skills

| Skill                     | What it does                                                                 |
| ------------------------- | ----------------------------------------------------------------------------|
| `phx-business-context`    | Retrieves PeoplesHR module behaviour, user flows and product documentation from WeKnora before answering, and cites the documents it used. Answers in business terms, not code; `PeoplesHR Academy` deep, `Product Development` shallow. |

Invoke it explicitly with its plugin-prefixed slash command —
`/org-standards:phx-business-context` — or let Claude load it automatically: it
fires whenever PeoplesHR or one of its modules comes up while you write
requirements, design a solution or answer a client question.

`phx-business-context` has a prerequisite: `WEKNORA_MCP_TOKEN` in your own
environment, for the `weknora` MCP server below. See
[`skills/phx-business-context/INSTALL.md`](skills/phx-business-context/INSTALL.md).

## MCP servers

| Server            | What it does                                                        |
| ----------------- | ------------------------------------------------------------------- |
| `weknora`         | Read-only retrieval from the `PeoplesHR Academy` and `Product Development` WeKnora knowledge bases. |

`weknora` is a remote `type: "http"` server on the WeKnora VM
(`https://weknora.phrsandbox.dev/mcp`) — nothing is downloaded or run locally. Set
`WEKNORA_MCP_TOKEN` in your own environment and **then** restart Claude Code. It is
read-only because of the `retrieve`-only API key on the server, not because of the
tool list, which advertises all 28 WeKnora tools including writes.

> ⚠️ **Do not install `dev-kit` alongside this plugin.** Its
> `phx-product-context` skill searches the same two knowledge bases in the
> opposite order and answers technically rather than in business terms; with both
> present they compete on question wording and misroute. Anyone doing both jobs
> keeps `dev-kit`, whose skill keeps the business rationale as a secondary.
> `dba-kit` and `ba-kit` are not affected — neither ships a product-knowledge skill.

## Notes

- **Versioned by semver** in `plugin.json` (currently `5.0.0`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- One skill and one MCP server: no agents or hooks.
