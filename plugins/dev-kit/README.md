# dev-kit

PeoplesHR developer build tooling, packaged as a Claude Code plugin and
distributed through the [`phr-foundry`](../../README.md) marketplace.

These four skills used to ship inside `org-standards`. They moved here so the
hands-on build skills are installable on their own, separately from the
standards-and-knowledge skills that stayed behind.

## Skills

| Skill                     | What it does                                                                 |
| ------------------------- | ----------------------------------------------------------------------------|
| `hrm-deployment-script`   | Reformats SQL scripts into PHR standard format. **.NET Framework only.**    |
| `hrm-notification`        | Builds a module email notification on the `HRM-JS45-SERVICE` Job Scheduler — four views, claim column, `HS_HR_JS_*` rows, HTML template. Data, never C#. |
| `phx-debugger`            | Fixes an Azure DevOps bug end to end from its bug ID — investigation, fix plan, implementation, RCA and status. |
| `hrm-configuration-document` | Writes the house Configuration Document for a finished CR from developer notes — `.md`, branded `.docx` and PDF. Asks for every missing fact. |

Invoke any of them explicitly with its plugin-prefixed slash command —
`/dev-kit:hrm-deployment-script`, `/dev-kit:hrm-notification`,
`/dev-kit:phx-debugger 141827`, `/dev-kit:hrm-configuration-document` — or let
Claude load it automatically: `hrm-deployment-script` when you write, edit or
review SQL in a .NET Framework project, `hrm-notification` when you ask for an
alert, reminder or email to be sent when something happens in a module,
`phx-debugger` when a message carries an ADO bug ID with a request to investigate
or fix it, `hrm-configuration-document` when a finished CR needs its Configuration
Document.

## MCP servers

**None.** This plugin ships skills only.

Two of its skills work better with a database to inspect, and `phx-debugger`
requires an Azure DevOps MCP server, but none of those are declared here:

| What a skill wants | Where it comes from |
| --- | --- |
| Schema browsing for `hrm-notification`'s discovery and verification queries, and for `hrm-deployment-script` | The `phx-dbexplorer` MCP server, declared by [`org-standards`](../org-standards/README.md#mcp-servers) — a leftover placement, since schema browsing is developer-only. Install that plugin too if you want it, or point Claude at your database some other way. |
| Azure DevOps access for `phx-debugger` | Your **own** per-developer ADO MCP server, plus the `superpowers` plugin. Neither has ever shipped with a `phr-foundry` plugin — the org name and your sign-in are yours. See [`skills/phx-debugger/INSTALL.md`](skills/phx-debugger/INSTALL.md). |

`hrm-notification` will still run without a database, but it cannot then check
whether the notification job already exists, and cannot verify what it wrote.

## Install

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install dev-kit@phr-foundry
```

Safe to install alongside **either** `org-standards` or `ba-kit` — `dev-kit`
ships no product-knowledge skill, so it has nothing to misroute against
`phx-product-context` or `phx-business-context`. (Those two still must not be
installed together with each other.) Most developers will want
`dev-kit` **and** `org-standards`.

## Notes

- **Versioned by semver** in `plugin.json` (currently `1.0.0`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- Skills only: no MCP servers, no agents, no hooks.
