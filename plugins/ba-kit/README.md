# ba-kit

PeoplesHR product knowledge for **Business Analysts**, packaged as a Claude Code
plugin and distributed through the [`phr-foundry`](../../README.md) marketplace.

## Skills

| Skill                   | What it does                                                                 |
| ----------------------- | ---------------------------------------------------------------------------- |
| `phx-business-context`  | Retrieves PeoplesHR module behaviour, user flows and product documentation from WeKnora before answering, and cites the documents it used. Answers in business terms, not code. |

Invoke it explicitly with `/ba-kit:phx-business-context`, or let Claude load it
automatically — it fires whenever PeoplesHR or one of its modules comes up while
you write requirements, design a solution or answer a client question.

## MCP servers

| Server    | What it does                                                              |
| --------- | ------------------------------------------------------------------------- |
| `weknora` | Read-only retrieval from the `PeoplesHR Academy` and `Product Development` knowledge bases in WeKnora. |

It needs `WEKNORA_MCP_TOKEN` in your own environment — a shared token handed out
through your credential channel, never committed here. Set it, **then** restart
Claude Code. See
[`skills/phx-business-context/INSTALL.md`](skills/phx-business-context/INSTALL.md).

## Do not install `org-standards` alongside this

`org-standards` ships `phx-product-context`, the developer counterpart, which
searches the same two knowledge bases in the opposite order and answers
technically. The two compete on question wording and misroute if both are
present. Install one or the other — never both.

## Notes

- **Versioned by semver** in `plugin.json` (currently `1.0.0`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- One skill and one MCP server: no agents or hooks.
