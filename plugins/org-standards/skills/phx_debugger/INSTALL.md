# ❄️ Setting up the `phx_debugger` skill

`phx_debugger` fixes an Azure DevOps bug end to end from its bug ID, with root cause investigation
driven by the **Superpowers `systematic-debugging`** skill.

**You do not install the skill itself.** It ships inside the `org-standards` plugin — if you have the
plugin, you already have the skill. This page covers only the two things `org-standards` deliberately
does *not* ship, because both are per-developer: the Superpowers plugin, and your Azure DevOps MCP
server.

Takes about five minutes, once.

> Installing the `org-standards` plugin is covered in [`docs/USAGE.md`](../../../../docs/USAGE.md).
> Do **not** also copy this folder into `%USERPROFILE%\.claude\skills\` — that registers the same
> skill twice and the two copies drift apart.

---

## What you need

| | | |
|---|---|---|
| **Claude Code** | `npm install -g @anthropic-ai/claude-code` | needs Node.js |
| **Signed in** | `claude auth login` | opens a browser |
| **`org-standards` plugin** | `claude plugin install org-standards@phr-foundry` | ships this skill |
| **Superpowers plugin** | `/plugin install superpowers@claude-plugins-official` | **required** — see step 1 |
| **Azure DevOps MCP server** | `@azure-devops/mcp` | **required** — see step 2. The *only* way this skill talks to ADO |
| **Azure CLI** | `winget install --id Microsoft.AzureCLI -e` | how the MCP server authenticates — `az login` |
| **Git** | `winget install --id Git.Git -e` | used on your local checkout to produce the diff |

> **No PAT.** Earlier versions of this skill stored an Azure DevOps personal access token and called
> the REST API from PowerShell. That path is gone — the scripts with it. Authentication is now the
> MCP server's job, and the skill will refuse to run without it rather than falling back. If you set
> up a PAT for an older version, revoke it in Azure DevOps and delete any `config.json` still sitting
> in an old copy of the skill folder.

## 1. ❄️ Install the Superpowers plugin

This skill runs its investigation through `superpowers:systematic-debugging`. In Claude Code:

```
/plugin install superpowers@claude-plugins-official
```

Then **restart Claude Code** — a freshly installed plugin does not register in the session that
installed it.

Confirm it worked by typing `/` and looking for `systematic-debugging` in the list. `phx_debugger`
checks this itself before it does anything else, and stops with that same instruction if the skill
is not there.

It will **not** quietly run without the superpower, and there is no non-superpowered mode to fall
back to. If the plugin is missing, the run ends having read nothing and touched nothing.

## 2. Connect the Azure DevOps MCP server

**This is not optional.** Every read and write this skill performs against Azure DevOps — the bug,
its comments, its attachments, code search, branches, the RCA, the status change — goes through this
server. There is no CLI path, no REST path and no PAT path behind it. Without the server the skill
prints what is missing and stops.

`org-standards` does not ship it, because the organization name and your sign-in are yours. Add it to
your MCP config — either `.mcp.json` at the root of the repo you work in, or your user config so it
is available everywhere:

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

Replace `PeoplesHR` with your organization's name — the segment after `dev.azure.com/` in your ADO
URL. Naming the server **`ado`** is recommended; the skill reads its own tool list either way, but
`ado` is what the documentation assumes.

Sign in so the server can authenticate:

```powershell
az login
```

Then **restart Claude Code** and check with `/mcp` — `ado` should be listed as connected. Typing `/`
is not enough here; MCP servers are started at launch.

Your account's own Azure DevOps permissions apply — the server does not widen them. If you cannot
read a repository in the browser, the skill cannot read it either.

## 3. Use it

**Open Claude Code in the repository you are debugging** — the working directory is the codebase, so
there is no code path to pass:

```
/org-standards:phx_debugger 141827
/org-standards:phx_debugger 141827 smart
```

Or just describe it — *"fix ADO bug 141827"*. Either way the message must carry the **bug ID**; that
is the one required argument, and the skill will not go looking for a work item by title.

If the bug reaches into a dependency whose source lives outside this repository, add that path when
you invoke — *"…the approval engine is in `D:\Code\ApprovalEngine`"*.

Before it investigates anything it shows you the work item it fetched — title, state, a short summary
and what is attached — and waits for you to confirm it is the right bug.

**The bug has to be in `New`.** If the work item is in any other state — `Active`, `Resolved`,
`Closed`, anything — the run stops before the investigation starts and tells you what state it found.
A bug that has left `New` usually has someone's work on it already, and this skill would splice a
second RCA into fields they are writing and move a state they are relying on. If the state is simply
wrong, move it back to `New` in Azure DevOps yourself and run it again — the skill will not do that
for you.

**Modes** — `quick` (essentials only), `smart` (work only in the branch you have checked out; no
repo hunting, no build, no push), `balanced` (default, full procedure), `advanced` (proves the
version range, sweeps every branch, traces the introducing commit).

Mode sets how deep the *procedure* goes. How hard it *thinks* is the session's model and effort —
for a difficult bug run `/model opus` first. A narrow scope at high reasoning beats a wide scope at
low, which is why `smart` on Opus is often the strongest combination.

---

## What it does, in order

0. **Checks its four gates** — the Azure DevOps MCP server is connected, the Superpowers plugin is
   available, the bug ID you gave is a valid work item ID, and the work item is in state `New`. Any
   one of them missing ends the run right there, having read nothing and touched nothing.
1. **Reads the bug** — description, repro steps, acceptance criteria, comments, parent and every
   related link. A bug copied across version lines often has an empty description and all its
   detail on the sibling, so the links get read before anything is called missing.
2. **Assesses whether there is enough to troubleshoot.** The test is *"can I identify a specific
   code path to investigate"*, not *"is every field filled in"*.
   - **If not:** it asks *you* first — it lists exactly what it checked and the specific questions
     blocking it, and stops. Answer any of them and it re-assesses and carries on; you never wait on
     a ticket comment for something you already know. If you can't answer either, tell it to post
     the questions as a comment on the work item — **insufficient information to debug** — and it
     stops there. It will not comment unless you ask it to, and will not change the state without
     being asked.
3. ❄️ **Hands the bug to `systematic-debugging`** — the superpowered step, and the one that does the
   actual debugging. `phx_debugger` packages up everything it learned about the bug and spawns a
   **subagent** that runs the superpower's four phases under one Iron Law: *no fixes without root
   cause investigation first*. That subagent reads the error exactly, traces the bad value back to
   where it originates, compares against a module that handles the same case correctly, then states
   one hypothesis and tests it. It also finds the real repository rather than trusting the one you
   happen to be standing in, because local clones go stale. Everything done under the superpower is
   marked with ❄️ so you can see exactly where it applied.
4. **Presents a fix plan and stops** for your approval.
5. **Hands the approved plan to a second subagent**, which makes the one fix, edits byte-precisely so
   the diff contains only the intended change, and builds. `phx_debugger` handles the branch itself,
   then gives you the diff to test. It loops until you confirm it works — and problems go back to the
   subagent, never to a side-fix by the outer skill.
6. **Writes the full RCA** into the work item's `Custom.*` fields, following the RCA template, as a
   single patch. Existing content is appended to, never overwritten; it re-reads the item immediately
   before writing and again after, and tells you if somebody edited it in between. (The MCP patch API
   has no `test` operation, so that read-compare-read is the guard — not a true atomic check.) That
   includes the three classification dropdowns —
   Root Cause Category, Root Cause and Bug Type Classification — chosen from the real allowed values
   and put to you for confirmation first.
7. **Moves the status** — it reads the allowed states from your process template first, proposes
   one, and asks before setting it.
8. **Summarises**, including anything still open.

## What is in this folder

```
skills\phx_debugger\
    SKILL.md               the procedure itself
    INSTALL.md             this page
    reference\debugging-brief.md   the brief both subagents read
    reference\rca-template.md      the eleven RCA fields, and where each comes from
```

`debugging-brief.md` is the standing brief for the `systematic-debugging` subagents: the Iron Law,
how the four phases land on a PeoplesHR bug, the source work, the rules they inherit, and exactly
what they must return. It is why the outer skill can stay out of the debugging entirely.

There are no scripts. The retired PAT-based PowerShell implementation has been removed — the
PHR-specific field reference names, comment formatting and RCA conventions it documented now live in
`SKILL.md` and `reference\rca-template.md`.

## Three things it will not do

**It will not touch Azure DevOps except through the MCP server.** No `az devops`, no `curl`, no
PowerShell REST call, no personal access token — not as a fallback, not "just this once", not if you
ask it to. If the server is missing or a call fails, it tells you and stops. That is the point: one
audited path in and out of ADO, with your own identity on every call.

**It will not guess.** If a bug has two plausible causes, the fix has two reasonable shapes, or the
answer lies in code it cannot see, it stops and asks you — with what it established, what it could
not, the options, and which it would choose. Answering takes seconds; an unnoticed wrong assumption
costs a day.

**It will not commit, push, or open a pull request** unless you explicitly tell it to. Applied
changes sit in your working tree for you to review.

## Troubleshooting

| Symptom | Cause |
|---|---|
| "Needs the Azure DevOps MCP server" | Step 2 not done, or Claude Code not restarted since. Check `/mcp` |
| `/mcp` shows `ado` failing to start | Usually the org name in `args` is wrong — it is the segment after `dev.azure.com/`, not the full URL. Node.js must also be on `PATH` for `npx` |
| ADO calls fail with an auth error | Run `az login` again; the token has expired. Restart Claude Code afterwards |
| ADO calls fail with "not found" on a repo you can see | The MCP server uses *your* identity — check you are signed in as the right account and to the right tenant |
| It refuses to use `az devops` even when asked | Working as designed. See *Three things it will not do* |
| `Insufficient information` on a bug you think is fine | It asks you before it comments — read the questions, and if you know the answers just reply and it carries on. Only say "comment on the ticket" when the reporter is the one who has to answer |
| A state change is rejected | Your process template does not allow that transition from the current state. It will say so and ask |
| Skill not found | The `org-standards` plugin is not installed, or Claude Code has not been restarted since it was. `claude plugin list` should show it |
| "Needs the Superpowers plugin" | Step 1 not done — run `/plugin install superpowers@claude-plugins-official` and **restart** |
| "Only starts on a bug in `New`" | The work item has left `New`, so somebody is likely already working it. Move it back in Azure DevOps if the state is wrong, then run again — the skill will not change it for you |
| "Cannot use that bug ID" | What you passed is not a positive integer. It will not guess at a repair — give it the plain ID or the `_workitems/edit/<id>` URL |
| No ❄️ markers in the output | It ran without the superpower. That should be impossible — report it |
