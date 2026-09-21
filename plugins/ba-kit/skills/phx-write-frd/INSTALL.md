# Setting up the `phx-write-frd` skill

`phx-write-frd` authors the **FRD — Feature Requirements Document**, the business/functional
document for a PeoplesHR feature (`FRD-` prefix), against the template held in the PHR-X project
wiki.

**You do not install the skill itself.** It ships inside the `ba-kit` plugin — if you have the
plugin, you already have the skill. This page covers the one thing `ba-kit` deliberately does *not*
ship, because it is per-developer: your Azure DevOps MCP server.

Takes about five minutes, once.

> Installing the `ba-kit` plugin is covered in [`docs/USAGE.md`](../../../../docs/USAGE.md).
> Do **not** also copy this folder into `%USERPROFILE%\.claude\skills\` — that registers the same
> skill twice and the two copies drift apart.

---

## What you need

| | | |
|---|---|---|
| **Claude Code** | `npm install -g @anthropic-ai/claude-code` | needs Node.js |
| **Signed in** | `claude login` (or `/login` in a session) | opens a browser |
| **`ba-kit` plugin** | `claude plugin install ba-kit@phr-foundry` | ships this skill |
| **Azure DevOps MCP server** | `@azure-devops/mcp` | **required** — see below. The *only* way this skill reaches the wiki |
| **Azure CLI** | `winget install --id Microsoft.AzureCLI -e` | how the MCP server authenticates — `az login` |
| **PHR-X wiki access** | your own ADO account | you must be able to open the wiki in a browser |

## Connect the Azure DevOps MCP server

**This is not optional.** The FRD template and sample live in the PHR-X wiki and are read live on
**every run** — there is no local template copy, and no CLI, REST or PAT fallback. Without the
server the skill reports what is missing and stops, having produced nothing.

`ba-kit` does not ship it, because the organization name and your sign-in are yours. Add it to
`.mcp.json` at the root of the repo you work in, or to your user MCP config so it is available
everywhere:

```json
{
  "mcpServers": {
    "ado": {
      "command": "npx",
      "args": ["-y", "@azure-devops/mcp", "PeoplesHR"]
    }
  }
}
```

Naming the server **`ado`** is recommended; the skill reads its own tool list either way, but `ado`
is what the documentation assumes.

Sign in so the server can authenticate:

```powershell
az login
```

Then **restart Claude Code** and check `/mcp` shows `ado` connected. Typing `/` is not enough —
MCP servers start at launch.

Use the **local** server shown above. Claude Code cannot authenticate to the remote
`mcp.dev.azure.com` endpoint — Microsoft Entra does not support the dynamic client registration it
would need.

Your account's own Azure DevOps permissions apply; the server does not widen them. If you cannot
read the PHR-X wiki in a browser, the skill cannot read it either.

## Use it

```
/ba-kit:phx-write-frd
```

Or just describe it — *"write an FRD for the leave-encashment feature"*, or, at the end of a design
or grilling session, *"turn that into an FRD"*.

The usual run: the skill reads the wiki template and sample, maps what you have supplied onto the
template's sections, then comes back with **one consolidated question** listing every section it
does not have input for — by number. It waits for your answers before drafting anything.

Expect to be asked for Document Control in particular: the FRD ID (`FRD-<MODULE>-<YYYY>-<NNN>`),
feature name, BA and Product Owner names, version, roadmap/epic reference, the linked SDD, and the
target wiki path. A design session almost never supplies those.

The deliverable is a **markdown file in your repository** — by convention
`docs/frd/<FRD-ID>-<kebab-case-feature-name>.md`, or wherever your repo already keeps FRDs. Writing
that file is **not** publishing: nothing reaches the wiki until you ask for it explicitly, and the
skill stops for your approval on the exact path and content before any write.

## What it will not do

**It will not invent document content.** Names, dates, IDs, metrics, personas, priorities,
acceptance criteria and approval decisions all come from you or from a source you named. Where it
has no input it stops and asks rather than guessing — and it will not launder a guess by labelling
it `[PROPOSED]`, `TBD` or `TODO`, or by filing it under Open Questions.

**It will not reach Azure DevOps except through the MCP server.** No `az devops`, no `curl`, no
REST call, no PAT — not as a fallback, not if you ask.

**It will not publish without showing you first.** A wiki page is visible to the whole organization
the moment it is written, so the exact path and content go past you for approval, every time.

**It will not prescribe technical mechanisms.** Direct DB access vs. internal API vs. ADAB, and
table and column names, are the SDD's call — see `phx-write-sdd` in the `dev-kit` plugin.

## What is in this folder

```
skills\phx-write-frd\
    SKILL.md      the procedure itself
    INSTALL.md    this page
```

There are no reference files: the template and sample are read from the wiki on every run, by
design, so that a change to the standard reaches everyone immediately.

## Troubleshooting

| Symptom | Cause |
|---|---|
| "Needs the Azure DevOps MCP server" | The server is not connected, or Claude Code has not been restarted since you added it. Check `/mcp` |
| `/mcp` shows `ado` failing to start | Usually the org name in `args` is wrong — it is the segment after `dev.azure.com/`, not the full URL. Node.js must also be on `PATH` for `npx` |
| Wiki calls fail with an auth error | Run `az login` again; the token has expired. Restart Claude Code afterwards |
| "Could not read the FRD template" with a 404 | The template page has moved, been renamed or been re-IDed. Give the skill its new location |
| "Could not read the FRD template" with a 403 | Your account has no access to the PHR-X wiki. Ask for it |
| It stops and asks a long list of questions | Working as designed — those are sections it has no input for. Answer them and it carries on |
| It refuses to use `az devops` even when asked | Working as designed. See *What it will not do* |
| Skill not found | The `ba-kit` plugin is not installed, or Claude Code has not been restarted since it was. `claude plugin list` should show it |
| It wrote a file but nothing appeared in the wiki | Working as designed — writing the file is not publishing. Ask for it to be published explicitly |
