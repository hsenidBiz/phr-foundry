# org-standards

PeoplesHR product knowledge for **every role**, packaged as a Claude Code plugin
and distributed through the [`phr-foundry`](../../README.md) marketplace.

**Audience: everyone.** Developers install it next to
[`dev-kit`](../dev-kit/README.md); Business Analysts install it next to
[`ba-kit`](../ba-kit/README.md). It conflicts with nothing.

> **Merged in `6.0.0`:** the developer `phx-product-context` (from `dev-kit`) and
> the BA `phx-business-context` (from here) are now one skill,
> `phx-product-context`, rewritten from scratch. If you used
> `/org-standards:phx-business-context` or `/dev-kit:phx-product-context`, switch
> to `/org-standards:phx-product-context`. The plugin no longer declares the
> `weknora` MCP server and no longer needs `WEKNORA_MCP_TOKEN`.
>
> **Moved in `4.0.0`:** `phx-sql-standards-review` and the `phx-dbexplorer` MCP
> server now ship in the [`dba-kit`](../dba-kit/README.md) plugin.
>
> **Moved in `3.0.0`:** `hrm-deployment-script`, `hrm-notification` and
> `phx-debugger` now ship in the [`dev-kit`](../dev-kit/README.md) plugin.

## Skills

| Skill                     | What it does                                                                 |
| ------------------------- | ----------------------------------------------------------------------------|
| `phx-product-context`     | Acquires grounded, cited PeoplesHR context from the four WeKnora knowledge bases — `PeoplesHR Module Behaviour Brief`, `PeoplesHR Findings-Register`, `Product Development`, `PeoplesHR Academy` — before solution engineering, PRD / FRD writing or requirement elicitation. One search per base, in parallel, weighted by the task; hands back a context brief with sources, disagreements, known findings and gaps. |

Invoke it explicitly with `/org-standards:phx-product-context`, or let Claude load
it automatically: it fires when you design a feature, write an SDD or plan a
change, when you write a PRD or FRD or elicit requirements, and whenever the work
turns on how a PeoplesHR module actually behaves.

## What it needs

The **weknora-peopleshr-product-knowledge** MCP server, connected in your own
Claude Code (`/mcp`) or as a connector in Claude Desktop. This plugin deliberately
does not declare it. Without it the skill stops and says so, rather than answering
from general knowledge.

## Notes

- **Versioned by semver** in `plugin.json` (currently `6.0.0`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- One skill, no MCP server: no agents or hooks.
