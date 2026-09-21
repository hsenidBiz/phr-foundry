# dev-kit

PeoplesHR developer build tooling, packaged as a Claude Code plugin and
distributed through the [`phr-foundry`](../../README.md) marketplace.

The four build skills used to ship inside `org-standards`. They moved here so the
hands-on build skills are installable on their own. `phx-product-context`, the
developer product-knowledge skill, joined them in `2.0.0` — it was always
developer-only and now sits with the rest of the developer tooling.

## Skills

| Skill                     | What it does                                                                 |
| ------------------------- | ----------------------------------------------------------------------------|
| `hrm-deployment-script`   | Reformats SQL scripts into PHR standard format. **.NET Framework only.**    |
| `hrm-notification`        | Builds a module email notification on the `HRM-JS45-SERVICE` Job Scheduler — four views, claim column, `HS_HR_JS_*` rows, HTML template. Data, never C#. |
| `phx-debugger`            | Fixes an Azure DevOps bug end to end from its bug ID — investigation, fix plan, implementation, RCA and status. |
| `hrm-configuration-document` | Writes the house Configuration Document for a finished CR from developer notes — `.md`, branded `.docx` and PDF. Asks for every missing fact. |
| `phx-product-context`     | Retrieves PeoplesHR module behaviour from the product documentation in WeKnora before answering, and cites the documents used. Technical voice; `Product Development` deep, `PeoplesHR Academy` shallow. |

Invoke any of them explicitly with its plugin-prefixed slash command —
`/dev-kit:hrm-deployment-script`, `/dev-kit:hrm-notification`,
`/dev-kit:phx-debugger 141827`, `/dev-kit:hrm-configuration-document`,
`/dev-kit:phx-product-context` — or let Claude load it automatically:
`hrm-deployment-script` when you write, edit or review SQL in a .NET Framework
project, `hrm-notification` when you ask for an alert, reminder or email to be
sent when something happens in a module, `phx-debugger` when a message carries an
ADO bug ID with a request to investigate or fix it, `hrm-configuration-document`
when a finished CR needs its Configuration Document, `phx-product-context`
whenever a question turns on how a PeoplesHR module actually behaves.

`phx-product-context` has a prerequisite: `WEKNORA_MCP_TOKEN` in your own
environment, for the `weknora` MCP server below. See
[`skills/phx-product-context/INSTALL.md`](skills/phx-product-context/INSTALL.md).

## MCP servers

| Server            | What it does                                                        |
| ----------------- | ------------------------------------------------------------------- |
| `weknora`         | Read-only retrieval from the `Product Development` and `PeoplesHR Academy` WeKnora knowledge bases. Backs `phx-product-context`; you never call it directly. |

`weknora` is a remote `type: "http"` server on the WeKnora VM
(`https://weknora.phrsandbox.dev/mcp`) — nothing is downloaded or run locally. Set
`WEKNORA_MCP_TOKEN` in your own environment and **then** restart Claude Code. It is
read-only because of the `retrieve`-only API key on the server, not because of the
tool list, which advertises all 28 WeKnora tools including writes.

Two other skills work better with a database to inspect, and `phx-debugger`
requires an Azure DevOps MCP server. Neither is declared here:

| What a skill wants | Where it comes from |
| --- | --- |
| Schema browsing for `hrm-notification`'s discovery and verification queries, and for `hrm-deployment-script` | The `phx-dbexplorer` MCP server, declared by [`dba-kit`](../dba-kit/README.md#mcp-servers). Install that plugin too if you want it, or point Claude at your database some other way. |
| Azure DevOps access for `phx-debugger` | Your **own** per-developer ADO MCP server, plus the `superpowers` plugin. Neither has ever shipped with a `phr-foundry` plugin — the org name and your sign-in are yours. See [`skills/phx-debugger/INSTALL.md`](skills/phx-debugger/INSTALL.md). |

`hrm-notification` will still run without a database, but it cannot then check
whether the notification job already exists, and cannot verify what it wrote.

## Install

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install dev-kit@phr-foundry
```

> ⚠️ **Do not install `org-standards` alongside this plugin.** Since `2.0.0` it is
> `dev-kit` that ships `phx-product-context`, and `org-standards` that ships
> `phx-business-context`. The two search the same knowledge bases in opposite
> orders and answer in different voices; with both present they compete on
> question wording and misroute. Developers take `dev-kit`; Business Analysts take
> `org-standards`; anyone genuinely doing both jobs takes `dev-kit`, whose skill
> keeps the business rationale as a secondary.

`dba-kit` and `ba-kit` are not affected — neither ships a product-knowledge
skill. Most developers will want `dev-kit` and `dba-kit`.

## Notes

- **Versioned by semver** in `plugin.json` (currently `2.0.0`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- Five skills and one MCP server: no agents, no hooks.
