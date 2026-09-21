# ba-kit

Reserved home for PeoplesHR **Business Analyst** skills, packaged as a Claude
Code plugin and distributed through the [`phr-foundry`](../../README.md)
marketplace.

> **Empty since `2.0.0`.** `phx-business-context`, its only skill, moved to the
> [`org-standards`](../org-standards/README.md) plugin. Business Analysts should
> install `org-standards` and use `/org-standards:phx-business-context`. This
> plugin is kept as the slot for future BA-only skills; there is no reason to
> install it today.

## Skills

None at present.

## MCP servers

| Server    | What it does                                                              |
| --------- | ------------------------------------------------------------------------- |
| `weknora` | Read-only retrieval from the `PeoplesHR Academy` and `Product Development` knowledge bases in WeKnora. Kept declared here for the BA skills that will land in this plugin. |

It needs `WEKNORA_MCP_TOKEN` in your own environment — a shared token handed out
through your credential channel, never committed here. Set it, **then** restart
Claude Code.

## Notes

- **Versioned by semver** in `plugin.json` (currently `2.0.0`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- No skills, one MCP server: no agents or hooks.
