# org-standards

PeoplesHR organization standards, packaged as a Claude Code plugin and
distributed through the [`phr-foundry`](../../README.md) marketplace.

## Skills

| Skill                | What it does                                                                 |
| -------------------- | --------------------------------------------------------------------------- |
| `hrm_sql_standards`  | Reformats SQL scripts into PHR standard format. **.NET Framework only.**     |

Invoke it explicitly with `/org-standards:hrm_sql_standards`, or let Claude load
it automatically when you write, edit, or review SQL in a .NET Framework project.

## Notes

- **Versioned by semver** in `plugin.json` (currently `1.0.0`); bump it on each
  release that should reach users. See the root
  [README](../../README.md#versioning-manual-semver-in-pluginjson).
- Skills only for now: no MCP servers, agents, or hooks.
