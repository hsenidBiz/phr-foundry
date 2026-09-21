# ba-kit

PeoplesHR tooling for **Business Analysts**, packaged as a Claude Code plugin and
distributed through the [`phr-foundry`](../../README.md) marketplace.

> **No longer empty.** `ba-kit` shipped no skills between `2.0.0`, when
> `phx-business-context` moved to the [`org-standards`](../org-standards/README.md)
> plugin, and `2.1.0`, which fills the reserved slot with `phx-write-frd`.
>
> Business Analysts want **both**: `org-standards` for
> `/org-standards:phx-business-context`, and `ba-kit` for
> `/ba-kit:phx-write-frd`. The two do not compete — only product-knowledge skills
> misroute against each other, and `phx-write-frd` is not one.

## Skills

| Skill            | What it does                                                                 |
| ---------------- | ---------------------------------------------------------------------------- |
| `phx-write-frd`  | Authors the **FRD — Feature Requirements Document**, the business/functional document for a PeoplesHR feature (`FRD-` prefix). Reads the template and sample live from the PHR-X project wiki on every run; never invents content, and stops to ask when a section has no input. Writes a markdown file to your repo; publishing to the wiki is a separate, explicitly approved step. |

Invoke it explicitly with `/ba-kit:phx-write-frd`, or let Claude load it
automatically — when you ask for an FRD to be written, edited, reviewed,
converted or published, when a message carries an `FRD-` document ID or a link to
an FRD page in the PeoplesHR wiki, or when you finish a requirements or grilling
session and ask for it to be written up.

`phx-write-frd` has a prerequisite this plugin deliberately does not ship: your
**own** per-developer Azure DevOps MCP server. The FRD template lives in the wiki,
there is no local copy, and the skill stops rather than working from a remembered
structure. See
[`skills/phx-write-frd/INSTALL.md`](skills/phx-write-frd/INSTALL.md).

Its technical companion, `phx-write-sdd`, ships in
[`dev-kit`](../dev-kit/README.md) — the SDD is the Solutioning Engineer's
document, not the BA's.

## MCP servers

| Server    | What it does                                                              |
| --------- | ------------------------------------------------------------------------- |
| `weknora` | Read-only retrieval from the `PeoplesHR Academy` and `Product Development` knowledge bases in WeKnora. Declared here for the BA skills that will land in this plugin; nothing in `ba-kit` calls it today. |

It needs `WEKNORA_MCP_TOKEN` in your own environment — a shared token handed out
through your credential channel, never committed here. Set it, **then** restart
Claude Code.

## Install

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install ba-kit@phr-foundry
claude plugin install org-standards@phr-foundry
```

Safe alongside `dba-kit` too. Do **not** install `dev-kit` and `org-standards`
together — that is the pair that misroutes.

## Notes

- **Versioned by semver** in `plugin.json` (currently `2.1.0`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- One skill and one MCP server: no agents, no hooks.
