---
name: phx_debugger
description: Fixes an Azure DevOps bug end to end from its bug ID — reads the work item, delegates root cause and fix to the Superpowers systematic-debugging skill in subagents, then writes the RCA back and moves the status, gating on the developer's approval at each step. Use whenever a message carries an ADO bug ID or work item URL with a request to investigate, debug, root-cause or fix it — "fix bug 141827", "why is AB#141827 happening", a pasted _workitems/edit link. The bug ID is required; four hard gates (ADO MCP server, superpowers plugin, valid ID, work item in state New) stop the run before anything is read or touched.
---

# ❄️ PHX Debugger

Fix an Azure DevOps bug end to end, with the developer approving at each real decision — with root cause investigation driven by the **Superpowers `systematic-debugging`** skill.

Nothing here improvises: the investigation and the fix are `systematic-debugging`'s four phases, run in subagents under a single rule — *no fixes without root cause investigation first.* Phases 1–3 at Step 3, Phase 4 at Step 5, with your approval in between.

## The greeting

The developer should know immediately what they have started and what powers it.

**It comes after Step 0, not before it.** The banner names the bug by title, and you do not have the
title until Step 0e has fetched the work item — so the order is: gates (0a, 0c) → resolve the bug ID
(0d) → fetch the work item (0e) → clear the state gate (0f) → *then* this banner, immediately
followed by the confirmation gate in Step 0g. Never print it with a placeholder title, and **never
print it at all if any of the five gates stopped the run** — a banner above a refusal reads as though
the run started.

Print it exactly like this, filled in:

```
❄️ ─────────────────────────────────────────────── ❄️
     P H X   D E B U G G E R
     Azure DevOps bugs · powered by Superpowers
❄️ ─────────────────────────────────────────────── ❄️

  Bug         #<id> — <title>
  Code        <working directory>
  Mode        <mode>
  ADO access  <mcp server name> (MCP) — the only path, no CLI fallback
  Superpower  systematic-debugging, in a subagent — it finds the cause
              and writes the fix. I handle ADO, your gates and the RCA.
              Iron Law: root cause before any fix

  I stop and wait at the plan, and again after you test.
  Nothing is committed, pushed or PR'd unless you ask.
```

Warm, short and factual. Do not pad it, and never let it claim a step that has not run.

**Print it inside a fenced code block**, exactly as fenced above — the alignment is load-bearing and only a code fence preserves it. Never reproduce the banner as ordinary markdown, and never pad the indentation with `&nbsp;` or any other HTML entity: the terminal renders those literally and the title comes out as `&nbsp;&nbsp;&nbsp;&nbsp; P H X   D E B U G G E R`.

## ❄️ Marking where Superpowers is used

`systematic-debugging` does not run inside you — it runs in the subagents you spawn at Step 3 and
Step 5b. The developer must still see, at a glance, which parts of the run came from there. Wrap
those stretches in an ice-marked block:

> ❄️ **SUPERPOWERS · systematic-debugging** — *investigator subagent, Phases 1–3*
>
> …what it is being sent to look into, then what it found…
>
> ❄️ *end Phases 1–3 — root cause: `RequisitionsDA.cs:737` misreads the engine's `-1` sentinel*

Rules for the marker:

- **❄️ opens and closes** every superpowered stretch — the delegation at Step 3, the delegation at
  Step 5b, and the findings you relay from either. Never leave one unclosed.
- Name **which subagent and which phases** in the opening line and the **conclusion** in the closing
  one.
- Everything else — the ADO reads, the gates, the RCA, the status change — is your own work. Do not
  ice-mark it, or the marker stops meaning anything.
- One honest limit: a skill cannot set terminal colours, so the "frozen ice" is the ❄️ glyph, the
  blockquote and the bold header — not a literal blue. Say so plainly if asked.

## How this skill is invoked

It ships inside the `org-standards` plugin, so the slash command carries the plugin prefix:

```
/org-standards:phx_debugger <bugId or work item URL> [mode] [extra code paths]
```

It is equally valid to describe the job in plain language — *"fix ADO bug 141827"*. Both paths run
the same procedure from Step 0; nothing below is conditional on how you were called.

**The bug ID is the one required argument.** Everything else has a default. See Step 0d — a run
without an ID does not start.

### Where the code is

**The session's working directory is the codebase.** Claude Code is launched from the repository
being debugged, so there is no "path to the code" to ask for and none to guess at. Take the current
working directory as the code under investigation, confirm what it is with `git rev-parse
--show-toplevel`, and say which directory you are working in when you print the banner.

Do **not** ask the developer for a code path up front. If the working directory turns out to be the
wrong repository, that surfaces later and from the investigation, not from you: the investigator's
*find the true repository* check (`reference\debugging-brief.md`) compares the bug's symbols against
an org-wide code search and **stops, returning the mismatch**. You then put it to the developer — the
evidence points at repository X, you have Claude Code open on Y, do they want to reopen there or hand
you that path. It is a mismatch to raise, not a missing argument to collect.

If the bug reaches into a **dependency** whose source is outside this repository — a shared library,
a sibling service, a second checkout — the developer supplies those paths when they invoke the skill,
as trailing arguments or in plain language (*"…the engine is in `D:\Code\ApprovalEngine`"*). Put any
such path into the context packet (Step 3a) as an additional read location **for the subagent**; you
do not read there yourself. If the investigation needs one that was not supplied, it comes back in
the return's open questions and you ask for that specific path — a real question, not a guess.

## Modes

The mode sets how deep to go. Default is **balanced**. It changes *how much you verify* — never
whether a gate can be skipped, a finding invented, or something claimed unchecked.

| Mode | Scope |
|---|---|
| **quick** | Essentials only: read the bug, find the code path, root cause, short plan. **No branch sweep** — it costs one MCP call per branch now; say you skipped it. Narrow the search rather than widening it — this trades coverage for speed, never rigour, and it does **not** license asking the developer something the code would have answered. |
| **smart** | **Work only in the branch already checked out** in the working directory. No repo hunting, no branch sweep — the checkout is the answer. **No build and no test either** — the developer runs those — and nothing committed or pushed. Full reasoning depth inside that narrow scope. |
| **balanced** *(default)* | The full procedure below, at normal depth. |
| **advanced** | Thoroughness over speed. Trace the defect to the commit that introduced it, **prove** the affected version range rather than asserting it, sweep every branch, check siblings, surface risks the ticket does not mention. |

**`smart` suppresses the build.** The implementer normally builds the affected project (Step 5b); in
`smart` it must be told not to, and you hand back the diff with the build explicitly marked as not
run. Do not let that read as verified.

Most of what mode governs is investigation depth, and investigation is the subagent's. **Pass the
mode in the context packet** (Step 3a) and pass it again to the implementer;
`reference\debugging-brief.md` is what tells them what each mode means for the branch sweep, the
search breadth and the build. Treat that file as authoritative on those specifics rather than
restating them here. What mode changes for *you* is how much you relay and how hard you push back on
a thin return.

Depth of *procedure* is set here. Depth of *reasoning* is the session's model and effort, which a
skill cannot change — so if the bug is hard, say so and suggest the developer run `/model opus` and
raise effort. A narrow scope at high reasoning beats a wide scope at low.

## Plan mode

Analysis must be read-only, and implementation must not be. Manage that explicitly:

- **Call `EnterPlanMode` before Step 1.** Everything through Step 4 is investigation; in plan mode
  you physically cannot edit the developer's files, which is the guarantee that a half-formed idea
  never reaches their working tree.
- **The investigator subagent inherits that constraint and is told it explicitly** (Step 3b): it
  reads, it does not edit. Plan mode is the mechanism; the instruction is the belt to its braces.
- **Write the plan, then call `ExitPlanMode`** to present it for approval. Approval is what grants
  edit rights — which you then hand to the implementer subagent at Step 5b, not use yourself.

Do not ask the developer to toggle modes by hand. If you find yourself blocked from writing after
the plan was approved, you are still in plan mode — say so and exit it rather than retrying.

The sequence is fixed:

```
0a MCP gate ──missing──▶ stop     0c Superpowers gate ──missing──▶ stop
      │                                 │
      └────────────────▶ ───────────────┘
                        │
                        ▼
      0d bug ID ──none or malformed──▶ ask, wait
                        │
                        ▼
      0e fetch + validate the bug ──not found / not a Bug──▶ report the error, stop
                        │
                        ▼
      0f state gate ──state ≠ New──▶ stop
                        │
                        ▼
      greeting ─▶ 0g confirm this is the bug [STOP] ─▶ 1 read the bug in full
                                          │
                                          ▼
      2 SUFFICIENT? ──no──▶ comment on the ticket, stop
                 │yes
                 ▼
      3 delegate ──▶ ❄️ investigator subagent · systematic-debugging Phases 1–3
                 ◀── root cause + proposed fix + RCA material
                 │
                 ▼
      4 present the plan [STOP] ─▶ 5a branch ─▶ 5b delegate
                                      ──▶ ❄️ implementer subagent · Phase 4
                                      ◀── diff + build result
                 │
                 ▼
      5c hand back [STOP] ─▶ 5d assemble the RCA from both returns
                 ─▶ 6 RCA onto the work item ─▶ 7 status ─▶ done
```

You never read or edit source yourself. Steps 3 and 5b are where the code work happens, and both of
them happen inside a subagent running `superpowers:systematic-debugging`.

---

## The law: Azure DevOps is reached **only** through the MCP server

**Every** read from and write to Azure DevOps in this skill — work item, comment, attachment, field,
state, code search, file, branch, commit, pull request — goes through the **Azure DevOps MCP server**
(`microsoft/azure-devops-mcp`). There is no second path and no fallback.

This is not a preference. It is the condition on which the skill runs at all.

**Forbidden, without exception:**

| Never | Not even |
|---|---|
| `az` / `az devops` / `az repos` / `az boards` CLI | "just to check the state name" |
| `curl`, `Invoke-RestMethod`, `Invoke-WebRequest` against `dev.azure.com` or `*.visualstudio.com` | a single read-only GET |
| A PAT, from any source — env var, config file, the developer | "the MCP server is being slow" |
| A PowerShell or shell script that talks to Azure DevOps — yours or one you find lying about | to work around a missing MCP tool |
| `git fetch`/`git push` against an ADO remote **as a substitute** for an MCP call | reading a file the MCP server could return |
| Asking the developer to paste output from any of the above | "just this once" |
| **Finding a work item by title, text or any field** — see *the second law* below | "the ID 404'd, so let me search for it" |

`git` on the **local checkout you are running in** is still fine and still expected —
`git rev-parse`, `git log`, `git diff`, `git checkout` are local-working-tree operations, not Azure
DevOps API calls. The line is the network boundary: anything that talks to the ADO service goes
through MCP.

### The second law: work item lookup is **by ID only**

A work item enters this run in exactly one way: **you fetch it by its numeric ID.**
`wit_work_item` · `get`, or `wit_work_item` · `get_batch` for several at once. That is the whole
list.

**You must never find a work item by its content.** No `search_workitem`, no WIQL query, no
list-by-query, no filtering a result set — not by title, description, repro steps, tag, area path,
iteration, assignee, state or date. If a tool in your list takes free text and returns work items,
it is out of bounds for the entire run.

The IDs you are allowed to fetch are:

1. the ID from Step 0d — the one the developer gave you; and
2. any ID you read out of a `relations[]` link on a work item you already hold — a parent, a child,
   a "related" or a "duplicate of". Those arrive **as IDs**, so following them is still an ID
   lookup, and Step 1 depends on it: a bug copied across version lines routinely has an empty
   description and every useful detail on its sibling.

Nothing else. You do not go looking for a work item that nobody linked and nobody named.

#### This does **not** restrict code search

`search_code` by symbol name, error string, message template or setting key is not just allowed, it
is **mandatory** — it is how the investigator finds the true repository and traces the failing path
(`reference\debugging-brief.md`). The subagent inherits this law in full, and this carve-out with it.
The two rules sit side by side without conflict:

| Searching for… | |
|---|---|
| **work items** by their text | ❌ forbidden — for you and for the subagents |
| **code** by its text | ✅ required — the subagent's, not yours |

The distinction is the object, not the verb. Searching is fine; searching *for a work item* is not.

#### When the ID does not resolve, **stop** — do not go looking

This is the rule's whole reason for existing, so it does not bend. If `wit_work_item` · `get`
returns 404 or "work item does not exist":

- **Report the tool's own error verbatim**, say the ID did not resolve and name the likely reasons —
  a mistyped digit, a work item in a different Azure DevOps organization from the one your MCP
  server points at, or one your account cannot see.
- **Ask the developer to re-check the ID**, and wait. When they give you a corrected one, go back to
  Step 0e with it.
- **Do not post anything to Azure DevOps.** There is no valid work item to comment on — that is what
  the 404 means.
- **Do not search for it.** Not by the title the developer mentioned in chat, not by the words in
  their message, not "to check whether it was renumbered". The reflex to recover a failed lookup by
  full-text search is exactly what this law exists to stop: it finds a *similar* bug, the run
  proceeds confidently on the wrong one, and Step 6 writes an RCA onto somebody else's ticket. A
  wrong ticket is far more expensive than a stopped run.

### If the MCP server is missing, fail safely — do not improvise

If the server is not connected, or the specific tool you need is not exposed by it, you **stop**.
You do not reach for the CLI, you do not reach for REST, and you do not write a script to do it
instead. You say what was missing and what would fix it, and you end the run. A run that stops with
nothing done is a correct outcome here; a run that quietly used a PAT is not.

The same applies mid-run. If the MCP server drops out at Step 5, the run stops at Step 5 with the
work so far reported honestly — it does not finish over REST.

An earlier version of this skill reached Azure DevOps through a PAT-authenticated PowerShell script.
That path is gone, and so are the scripts. The org knowledge they carried — the PHR bug field
reference names, the HTML conventions, why RCA content never goes in `System.History`, why picklists
come from `allowedValues` — lives in this file and in `reference\rca-template.md`. If you find a
`config.json` holding a PAT left over from that era beside a developer's checkout, tell them to
revoke the token and delete the file. Do not use it.

---

## The rule that outranks the rest: ask, don't guess

**If you are in doubt, stop and ask the developer.** A wrong fix applied confidently is far more
expensive than a question. This is an explicit requirement of this skill, not a fallback.

### But exhaust the evidence first — asking is not an escape from investigation

A question is right when the answer **cannot be found in the code**. It is wrong when it is standing
in for work that has not been done, and it is the single most common way a run comes back weaker
than it should be.

Because you do not read the code yourself, this rule reaches you in two ways:

- **Before you ask about anything code-shaped, send it to the subagent instead.** "What does the
  engine return here?" is not a question for the developer, and it is not a question for you either
  — it is a task for the investigation. The same brief binds it: read the file end to end, follow
  the call chain out of this repo, open the binary when the logic is compiled, check the sibling
  module, re-read the attachments.
- **Before you pass on a question the subagent raised**, check it is genuinely the developer's to
  decide and not something the investigation could have settled. If it is the latter, send it back.

Only then ask. And ask about the thing that is genuinely the developer's to decide, not about the
fact nobody chased down.

| Not a question — go and find out | A real question |
|---|---|
| "What does the engine return in this case?" | "Should this set status Approved, or leave it unapproved as requisitions always have?" |
| "Is this a code bug or a config problem?" | "Ship the one fix in scope, or fix all six call sites in this PR?" |
| "Which method handles self-approval?" | "This changes shared behaviour across four modules — do you want that blast radius?" |

The left column is answered by a decompiler, a wider read, or one more search — send it back to the
subagent. The right column is answered only by a person, because it is a product decision.

**One decision point with your recommendation beats three open questions.** If you must raise
several, state the root cause definitively first, then ask — never present uncertainty about the
cause and a menu of directions at the same time. That reads as "I could not work it out".

### The triggers

Once the evidence is exhausted, ask — do not proceed on assumption — whenever:

- The bug could plausibly have **more than one root cause** and you cannot separate them from source.
- The fix has **more than one reasonable shape** and they behave differently for users.
- The right change is in code you **cannot see**: another repo, a stored procedure, config, a
  third-party component.
- The local checkout **disagrees** with the ticket — wrong branch, stale clone, symbol named in the
  bug that does not exist in the code.
- Fixing it properly means **changing shared behaviour** — a signature, a schema, an interface, a
  base class — and you cannot see every caller.
- The ticket asks for something that **contradicts** what the code appears designed to do.
- You would otherwise write the words *"probably"*, *"presumably"*, *"should be"* or *"I assume"*
  in a finding.

How to ask, so the answer is quick to give:

1. State what the investigation established, with `file:line`.
2. State precisely what could not be determined, and **why** — what was looked at that failed to settle it.
3. Give the options you see, each with its consequence.
4. Say which one you would choose and why.
5. Stop. Wait. Do not carry on with your preferred option while asking.

A question that reads *"which of these two, and here's what I'd pick"* takes ten seconds to answer.
*"I'm not sure, please advise"* takes ten minutes and gets a worse answer.

---

## Non-negotiables

- **You do not debug and you do not edit code.** Root cause and fix both belong to
  `superpowers:systematic-debugging`, running in a subagent (Steps 3 and 5b). Your half is Azure
  DevOps, the developer's gates, and the RCA. Doing a "quick look at the source" yourself is the one
  habit that breaks this skill — it produces a second, weaker investigation alongside the real one.
- **Verify before you claim.** Every factual statement about the code must come from the subagent's
  return, quoted as such. No recalled behaviour, no inference presented as fact, and nothing you
  added to make the story hang together.
- **An RCA already on the ticket is a claim, not a fact.** Prior RCAs are frequently written against
  a different repo or a stale snapshot. Pass it to the subagent flagged as unverified; if it does not
  hold against source, say so plainly in the plan and give the corrected version.
- **Azure DevOps only through the MCP server.** See *The law* above. No CLI, no REST, no script, no
  PAT. If the tool is not there, stop.
- **Work items are fetched by ID, never found by content.** See *the second law*. The ID the
  developer gave you, plus any ID reachable through a `relations[]` link — nothing else. An ID that
  does not resolve ends the run; it never becomes a title search.
- **The four Step 0 gates are absolute.** No ADO MCP server (0a), no `superpowers:systematic-debugging`
  (0c), no valid bug ID (0d), or a work item not in `New` (0f) each end the run with nothing read and
  nothing touched. None of them has a degraded mode, a "just this once", or a repair you apply
  yourself — and you never write to Azure DevOps to make a gate pass.
- **Never commit, push, or create a pull request** unless the developer explicitly approves that step.
- **Never write RCA content into `System.History`.** It belongs in the `Custom.*` fields.
- **Stop where the procedure says stop.** Presenting a plan and then implementing it in the same
  turn defeats the point of the gate.

## The Azure DevOps operations, as MCP tools

The server exposes **action-dispatch** tools: one tool name, an `action` parameter selecting the
operation. In Claude Code the tools appear as `mcp__<server>__<tool>`, where `<server>` is whatever
the developer named it in their MCP config — `mcp__ado__wit_work_item` if they used `ado`, the
recommended name. **Read the actual names from your tool list; never assume the prefix.**

| What you need | Tool · action |
|---|---|
| The bug itself — fields, `Custom.*`, relations, attachments | `wit_work_item` · `get` with `expand: "All"`, **by ID** |
| Its comments | `wit_work_item` · `list_comments` |
| Related / parent items in one call | `wit_work_item` · `get_batch` |
| An attachment's bytes | `wit_work_item_attachment` |
| Allowed **states** and **field allowed values** for the type | `wit_work_item` · `get_type` |
| Post a comment to a person | `wit_work_item_comment_write` · `add`, `format: "Html"` |
| Write RCA fields / move state | `wit_work_item_write` · `update` |
| Org-wide code search — finds the *real* repo | `search_code` |
| Repository inventory | `repo_repository` · `list` |
| Branch inventory | `repo_branch` · `list` |
| One file at one branch | `repo_file` · `get_content` |
| History for a file | `repo_search_commits` |
| Create a branch | `repo_create_branch` — only after explicit approval |
| Create a pull request | `repo_pull_request_write` · `create` — only after explicit approval |
| **Finding a work item you have no ID for** | **nothing — there is no tool for this here.** Any work-item search or WIQL tool the server exposes is out of bounds for the whole run |

### Three things that will bite you on the tools you use

1. **`wit_work_item_write` · `update` supports only `add`, `replace` and `remove`.** There is **no
   `test` op**, so the `/rev` concurrency guard the old script used is not available. See
   *Step 6* for what to do instead — do **not** solve this by going around the MCP server.
2. **`wit_work_item_attachment` takes an attachment GUID, not a URL**, and its `savePath` must be a
   **relative** path. Pull the GUID out of the relation URL:
   `…/_apis/wit/attachments/{attachmentId}`.
3. **`wit_work_item` · `get_type` is the only source of truth for states and picklist
   `allowedValues`.** Never type either from memory — this org has 21 states for Bug alone. See
   Steps 6 and 7.

The repository-side traps — `repo_file`'s `versionType` defaulting to `Commit`, `search_code`'s
`top: 5` default, and the fact that there is no single-call branch sweep any more — belong to the
subagent, and `reference\debugging-brief.md` carries them. They are not repeated here, so that they
cannot drift apart.

---

## Step 0 — Setup

### Step 0a — Is the Azure DevOps MCP server connected? **Hard gate**

Do this **first**, before the greeting. Everything downstream depends on it, and there is no
degraded mode to fall back to.

**Look at your own tool list.** Every tool this procedure calls must be present *before* you start —
a missing one discovered at Step 5 has already cost the developer their whole run. Check all of
these, matching on the suffix after the server prefix:

| Tool | Used at |
|---|---|
| `wit_work_item` | 0e, 1, 6, 7 — fetch, comments, `get_type` |
| `wit_work_item_write` | 6, 7 — RCA fields, state |
| `wit_work_item_comment_write` | 2 — the insufficient-information comment |
| `wit_work_item_attachment` | 1 — attachments are **not** optional reading |
| `search_code` | 3 — the subagent finds the true repository |
| `repo_file` | 3 — reading a file at a branch |
| `repo_branch` | 3, 5a — the branch sweep and the naming convention |

`repo_search_commits`, `repo_create_branch` and `repo_pull_request_write` are used conditionally; if
they are absent, say so at the point they are needed rather than failing the gate.

Note the server prefix you actually see (`mcp__ado__…`, `mcp__azure-devops__…`, whatever it is) and
use it for the rest of the run. Match on the **suffix**, and match it exactly — `wit_work_item` and
`wit_work_item_write` are two different tools, and seeing one is not seeing the other.

**Do not "verify" by calling a CLI or REST endpoint.** The tool list is the check. If ADO tools are
absent from it, the server is not connected — there is nothing further to test.

**If any required tool is absent, stop here.** Not "start and see how far it gets" — the run ends at
this line, with nothing read and nothing touched. Print this, name which of the seven tools were
missing, and end the run:

> ❄️ **PHX Debugger needs the Azure DevOps MCP server**
>
> Missing from my tool list: `<the ones you could not find>`.
>
> Every Azure DevOps operation in this skill goes through it, by design — there is no PAT path, no
> `az devops` path and no REST path to fall back on. I have not read your bug or touched your code.
>
> Add it to your MCP config (`.mcp.json` in the repo, or your user config):
>
> ```json
> {
>   "mcpServers": {
>     "ado": {
>       "command": "npx",
>       "args": ["-y", "@azure-devops/mcp", "<your-org-name>"]
>     }
>   }
> }
> ```
>
> Sign in to Azure first (`az login`, or the auth method your org uses), then **restart Claude Code**
> and run `/org-standards:phx_debugger` again. `/mcp` will show `ado` as connected when it is ready.
>
> Setup detail is in this skill's `INSTALL.md`.

**Never negotiate around this gate.** Not if the developer says "just use the CLI this once", not if
they offer you a PAT, not if the bug is urgent. If they ask for a fallback path, say plainly that
this skill does not have one and that `az devops` is theirs to run in their own terminal — you will
not run it and will not act on ADO data obtained that way.

If the tools are present but a **call** fails — auth expired, org wrong, project not found — report
the tool's own error verbatim, say what it means, and stop. A failing MCP call is never a reason to
switch transport.

### Step 0b — Which project?

Most tools take a `project`. You do not know it yet, and you must not guess it: get it from the work
item itself in Step 0e (`System.TeamProject`), and reuse that value everywhere afterwards. If a tool
needs a project *before* you have fetched the bug, use `core_list_projects` and ask the developer
rather than picking one.

### ❄️ Step 0c — Is Superpowers available? **Hard gate**

This skill depends on the `superpowers` plugin. Check before the greeting, so a missing plugin is
caught in the first five seconds rather than at Step 3.

**Your own skill list is the check.** The one name that matters is `superpowers:systematic-debugging`
— not "some superpowers skill is present", not a similarly named debugging skill from another
plugin. If that exact skill is offered, you are ready; go on to Step 0d. Do not probe the plugin
cache directory to "confirm" it: a plugin that is on disk but not in your skill list is not usable in
this session either way, so the two cases have the same answer.

**If it is not listed, stop here** and print this:

> ❄️ **PHX Debugger needs the Superpowers plugin**
>
> This skill runs its root cause investigation through `superpowers:systematic-debugging`, which is
> not available in this session. Install it:
>
> ```
> /plugin install superpowers@claude-plugins-official
> ```
>
> Then **restart Claude Code** and run `/org-standards:phx_debugger` again — a freshly installed
> plugin does not register in the session that installed it, so if you have already run that command,
> the restart is the missing step.
>
> I have not read your bug or touched your code.

**Never silently fall back.** There is no non-superpowered mode of this skill, and you must not
improvise one by investigating ad hoc under this name. The developer chose the superpowered version;
if it is unavailable they are entitled to know they did not get it. Stop and let them fix it.

### Step 0d — The bug ID. **Hard gate**

**This skill runs on a bug ID and nothing else.** No ID, no run. No *valid* ID, no run either.

Read the invoking message and extract exactly one work item ID. Accept any of these forms and
normalise to a bare integer:

| Written as | ID |
|---|---|
| `141827` | `141827` |
| `#141827`, `AB#141827`, `Bug 141827` | `141827` |
| `https://dev.azure.com/<org>/<project>/_workitems/edit/141827` | `141827` |
| the same URL with `?...` query string or trailing `/` | `141827` |

#### What counts as a valid ID

A work item ID is **a positive integer and nothing else**. After normalising, it must match
`^[1-9][0-9]*$`. Reject anything that does not, and reject it *here* — not by sending it to Azure
DevOps to see what happens:

| Given | Verdict |
|---|---|
| `141827` | ✅ valid |
| `0`, `-4` | ❌ not a work item ID |
| `141827.0`, `14 18 27`, `141,827` | ❌ not an integer — do not "clean it up" into one |
| `141827abc`, `AB#`, `#`, `bug` | ❌ malformed |
| `1e5`, `0x2298B` | ❌ not decimal notation; do not evaluate it |
| an empty string after stripping `#` / `AB#` | ❌ treat as no ID at all |
| a URL with no numeric final segment | ❌ malformed — the ID is the last path segment of `_workitems/edit/<n>` |
| an ID longer than 9 digits | ❌ implausible; ask rather than fetch |

**A malformed ID is a stop, not a repair.** Do not strip stray characters, round a decimal, drop a
comma or take the digits out of `141827abc` and proceed. A silently "corrected" ID is a valid ID for
*some other* work item, and Step 6 then writes an RCA onto it. Print the malformed-ID stop below,
quote back exactly what you were given, say why it is not a work item ID, and **wait**.

> ❄️ **PHX Debugger cannot use that bug ID.**
>
> I read `<what they actually typed>`, which is not an Azure DevOps work item ID — those are plain
> positive integers, like `141827`.
>
> Give me the ID or the work item URL and I will carry on. I have not read anything or touched your
> code.

**Never derive an ID from anything else.** Not from the current git branch name, not from a folder
name, not from a commit message, and not from "the bug we were discussing" earlier in the
conversation. If the developer refers back to an earlier bug, ask them to restate the number. The
reason is Step 6: a misidentified work item gets somebody else's RCA written onto it, which is the
most expensive mistake this skill can make and the hardest to notice.

**If there is no ID, stop and ask:**

> ❄️ **PHX Debugger needs a bug ID.**
>
> Give me the Azure DevOps work item ID or its URL — e.g. `141827`, or
> `https://dev.azure.com/<org>/<project>/_workitems/edit/141827`.
>
> I have not read anything or touched your code.

Then **wait**. When they supply it, carry straight on with Step 0e — do not make them re-invoke the
skill. Nothing has been read or changed, so resuming is safe.

**If the message contains more than one plausible ID**, do not pick. A number that is part of a path
or a version string (`HRM-WIDGET45-MVC`, `v4.5.2`) is not a work item ID, so it usually resolves
itself — but if two genuine candidates remain, name both and ask which.

Set the **mode** from the message if one of `quick` / `smart` / `balanced` / `advanced` appears **as
a standalone argument or as a plain instruction about depth** — not merely because the word occurs.
*"fix 141827 smart"* and *"be quick about it"* set the mode; *"the smart card module"* and *"an
advanced search screen"* do not. If it is genuinely ambiguous, take the default and say which mode
you are running in — the banner shows it, so a wrong reading is visible immediately. Otherwise it is
`balanced`. Note any extra dependency code paths the developer supplied.

### Step 0e — Validate the ID against Azure DevOps

An ID that parses is not an ID that exists. Fetch it before you commit to it:

`wit_work_item` · `get` with `expand: "All"`. This is the same call Step 1 uses — one fetch serves
both, so do not call it twice.

Four things to check on the response, in order:

1. **It resolved.** A 404 or "work item does not exist" means the ID is wrong, or it belongs to an
   organization your MCP server is not pointed at. **Report the tool's own error verbatim and stop.**
   Do not search for it by any other means — see *the second law: work item lookup is by ID only*,
   which spells out exactly what to do here.
2. **It is a bug.** Read `System.WorkItemType`. If it is a Task, User Story, Feature or anything
   else, say what it actually is and ask whether to continue — this skill's RCA fields, its
   classification dropdowns and its state list are all Bug-shaped, and much of Steps 6–7 will not fit
   another type.
3. **Read `System.State` and hold it for Step 0f.** Do not act on it yet, and do not print the
   banner before that gate has passed.
4. **Note `System.TeamProject` and `rev`.** The project is what every later tool call needs (Step 0b),
   and the rev is your concurrency baseline for Step 6.

### Step 0f — The bug must be in **`New`**. **Hard gate**

**This skill fixes bugs that nobody has started.** If `System.State` is anything other than `New`,
the run stops here.

The reason is not bookkeeping. A bug that has left `New` has someone else's work on it — an active
assignee mid-investigation, a fix already in review, a resolution somebody signed off. Everything
this skill does downstream is destructive to that: Step 6 splices into RCA fields another developer
is writing, Step 7 moves a state QA is relying on, and Step 5 puts a second, independent fix into a
tree that may already contain the first. Re-debugging a closed bug also burns a full investigation
on a defect that no longer exists in the code.

The check is exact: `System.State == "New"`, matched literally against the value on the work item.

- **Do not normalise.** `new`, `New `, `To Do`, `Proposed`, `Active`, `Open` and `Approved` are all
  *not* `New`. If your org's process template genuinely calls the initial state something else, that
  is a change to make in this file deliberately — not a match to loosen at run time.
- **Do not move it into `New` to satisfy the gate.** Writing `System.State = New` so the run can
  proceed defeats the entire point and destroys the real state. There is no circumstance in which
  this skill sets a state at Step 0.
- **Do not negotiate it.** "It's only in Active because I opened it", "I'm the assignee anyway",
  "just this once" — the answer is the same. If the developer wants the run anyway, the thing they
  change is the work item, in Azure DevOps, themselves, deliberately; then they re-invoke.

**If the state is not `New`, print this and end the run.** No banner above it, nothing written to
Azure DevOps, no investigation:

> ❄️ **PHX Debugger only starts on a bug in `New`.**
>
> **#\<id\> — \<title\>** is in **`<state>`**, assigned to **\<assignee, or "nobody"\>**.
>
> A bug that has left `New` usually has work on it already — an investigation in progress, a fix in
> review, or a resolution somebody signed off. Running this skill over that would splice a second
> RCA into fields someone else is writing and move a state they are relying on, so I stop here
> instead.
>
> If this bug genuinely is untouched and the state is wrong, move it back to `New` in Azure DevOps
> and run me again. If you want the investigation without the ADO writes, say so and I will tell you
> what I can do — but I will not proceed on this work item as it stands.
>
> I have not read your bug in full and have not touched your code.

Then **stop**. Do not offer to continue in a "read-only mode" you then improvise, and do not start
the investigation while waiting for a reply. If the developer fixes the state and asks again, go
back to Step 0e and re-fetch — the item has changed, so the response you are holding is stale.

Only once this gate passes: print the greeting banner, with the real title and the working directory
in it.

### Step 0g — Confirm this is the right bug. **STOP**

Before any investigation, show the developer what you actually fetched and get their go-ahead. This
is cheap insurance: it catches a transposed digit, a bug from the wrong version line, or a URL pasted
from the wrong browser tab — all while nothing has been read and nothing touched.

Present a short block, not a data dump:

- **`#<id> — <title>`**
- **Type · State · Assigned to · Area path · `System.TeamProject`**
- **What the bug says**, in two or three sentences of your own words, from the description and repro
  steps. Strip the HTML; do not paste raw markup. If the description is empty, say so plainly and
  name what it links to (*"no description; parent #119235 and related #140306"*) — that is a real
  signal about where the detail lives.
- **What is attached**, by count and name — *"3 attachments: `error.png`, `trace.log`, `steps.docx`"*.
  You have not read them yet; you read them in Step 1.
- **How many comments** there are.

Then ask one question: **"Is this the bug you want me to fix?"** and **wait**.

- **Yes** → Step 1, and read it all properly.
- **No / wrong one** → take the corrected ID and go back to Step 0e — **and through 0f again**. A
  replacement bug gets the same state gate as the first one; it does not inherit the first one's
  pass. Do not carry any impression of the discarded work item forward.

Do not merge this into a longer message that also starts the investigation. It is a stop.

## Step 1 — Read the bug properly

**Call `EnterPlanMode` first.** Steps 1–4 are investigation and must not be able to touch the
developer's files.

Two things in this stretch are not file edits and are not blocked by it, so do them without leaving
plan mode: **reading** through the MCP server, and saving attachments to a scratch directory (below).
One thing *is* a write and needs care: the insufficient-information **comment** at Step 2. If plan
mode blocks that MCP call, call `ExitPlanMode` first — presenting the verdict and the comment you
intend to post *is* the plan at that point — then post it and end the run. Do not skip the comment,
and do not silently drop back into investigating.

You already have the work item from Step 0e — reuse that response rather than fetching it again. Now
read it *fully*, and pull in what the first fetch did not cover. Then
`wit_work_item` · `list_comments` — comments are a separate call and are frequently where the real
detail lives.

Read all of it — title, description, repro steps, expected vs actual, acceptance criteria, severity,
area/iteration, tags, every `Custom.*` field that has content, **the comments, the parent, and every
related link**. Note `System.TeamProject` and the `rev`; you need both later.

These are the fields that carry a PHR bug. Reference names are **exact and case-sensitive**, and
`get` returns them flat under `fields`:

| | Reference name |
|---|---|
| Title · State · Type | `System.Title` · `System.State` · `System.WorkItemType` |
| Project · Area · Iteration | `System.TeamProject` · `System.AreaPath` · `System.IterationPath` |
| Assigned to · Created by · Tags | `System.AssignedTo` · `System.CreatedBy` · `System.Tags` |
| Severity · Priority | `Microsoft.VSTS.Common.Severity` · `Microsoft.VSTS.Common.Priority` |
| Description · Repro steps · Acceptance criteria | `System.Description` · `Microsoft.VSTS.TCM.ReproSteps` · `Microsoft.VSTS.Common.AcceptanceCriteria` |
| Parent | `System.Parent` |
| The RCA narrative and classification fields | `Custom.*` — see Step 6 and `reference\rca-template.md` |

`Custom.*` fields vary by process template, so read whatever the response actually carries rather
than expecting a fixed set. The MCP server returns the raw work item — no flattening, no HTML
stripping — so **you** do that sorting now:

- `relations[]` entries whose `url` ends `/workItems/<n>` are **linked work items** — follow them.
- `relations[]` entries with `rel: "AttachedFile"` are **attachments** — `attributes.name` is the
  file name, and the attachment GUID is the last segment of `url`.
- Large text fields (`System.Description`, `Microsoft.VSTS.TCM.ReproSteps`, the `Custom.*` narrative
  fields) come back as **HTML**. Read through the markup; do not report the tags as content.

**Read the attachments — every one of them.** A log file or screenshot on the ticket routinely names
the exact failing path: the URL, the message template, the timestamp. Ignoring them and inferring
from the description instead is how a run ends up asking a question the ticket already answered.

Pull each one with `wit_work_item_attachment`:

```
attachmentId : the GUID at the end of the relation's url  (…/_apis/wit/attachments/{GUID})
fileName     : relations[].attributes.name
savePath     : a relative directory, e.g. ".phx-debugger/attachments"  (absolute paths are rejected)
project      : System.TeamProject
```

With `savePath` it writes the file and returns the path — `Read` that path to see a screenshot.
Without it, the content comes back base64-encoded. **This is not optional and there is no "I cannot
fetch attachments" exit.** If the bug you are given has no description of its own, follow its links
and read *their* attachments too.

`savePath` is relative to the working directory, which is the developer's repository — so it lands
in their tree. Keep everything under one directory named for this skill, tell them at Step 8 that it
is there, and **never `git add` it**. If the repo has a `.gitignore` and that directory is not
already ignored, say so rather than editing their `.gitignore` uninvited. Ticket attachments can
carry customer data; they do not belong in a commit.

Step 0a gates `wit_work_item_attachment`, so a server build without it should never get this far. If
it somehow does, say plainly that the attachments could not be read and that the investigation is
proceeding without evidence you know exists — and flag it in the return and at Step 8. Do not
download them with `curl` and a PAT.

Then state in one or two sentences what the bug actually is. If you cannot state it, that is your
first signal for Step 2.

**Before concluding anything is missing, follow the links.** Bugs are routinely copied across
version lines with an empty description, where every detail lives on the sibling or the parent
defect. A ticket that looks empty is often complete once you read what it points at. Fetch the
related items — `wit_work_item` · `get_batch` takes all the IDs at once — and check whether a
sibling has already been fixed — if so, this is a **port**, not
an investigation, and the risk profile is entirely different.

## Step 2 — Sufficiency assessment

Decide whether there is enough to troubleshoot. Judge by one question:

> **Can I identify a specific code path to investigate?**

Not "is every field filled in" — a terse bug from someone who knows the system is workable; a
verbose one that never says what went wrong is not.

Work through these, counting the linked items and comments as part of the ticket:

| | What you need | Usually enough |
|---|---|---|
| 1 | **What went wrong** | An error, a stack trace, a screenshot, or a clear description of wrong behaviour |
| 2 | **What was expected instead** | Stated, or obvious from the feature |
| 3 | **Where** | Module, screen, API, or report — enough to find the code |
| 4 | **Which build / environment** | Version, branch or environment, so you look at the right source |
| 5 | **How to reach it** | Repro steps, or the data/config that triggers it |

Then give a verdict.

### If SUFFICIENT

Say so in one line, note anything thin that you will have to infer, and go to Step 3.

### If INSUFFICIENT

Do not guess, and do not start reading code hoping something turns up.

1. **Post a comment on the work item** with `wit_work_item_comment_write` · `add`. Pass
   **`format: "Html"`** — the default is Markdown, and the HTML below renders as literal tags
   without it. It must name exactly what is missing and
   what would unblock it — a generic "insufficient information" comment is useless to the reporter
   and will come back unanswered. Say what you *did* check, including the linked items, so nobody
   repeats your work.

   ```html
   <b>Insufficient information to debug</b><br><br>
   I could not identify a code path to investigate from this work item.<br><br>
   <b>Checked:</b> description, repro steps, acceptance criteria, 3 comments,
   parent #119235, related #140306.<br><br>
   <b>To proceed I need:</b>
   <ol>
     <li>The exact error message or stack trace, or a screenshot of the failure</li>
     <li>The build or environment where it reproduces (this says "Main", but the module
         ships from three release lines)</li>
     <li>The steps or the record that triggers it — it does not reproduce on a new request</li>
   </ol>
   ```

2. **Report it to the developer**, and say what you would need. Do not change the state unless they
   ask — moving someone else's ticket is their call, not yours. If they do want it moved, read the
   states from `wit_work_item` · `get_type` first and propose a target from that list.

3. **Stop.** The run ends here.

If the ticket is workable but one specific detail is missing, that is a question for the developer
(see *ask, don't guess*), not an insufficiency verdict. Ask them first — they often know the answer
without going back to QA.

## ❄️ Step 3 — Hand the bug to `systematic-debugging`

**You do not debug.** Not here, not anywhere in this skill. Finding the root cause is
`superpowers:systematic-debugging`'s job, and it runs in a **subagent** you spawn with the bug's
context. Your job in this step is to assemble that context, delegate, and check what comes back is
complete.

This is the division the whole skill rests on:

| `phx_debugger` — you | The subagent |
|---|---|
| Azure DevOps: read the bug, comment, write the RCA, move the state | Root cause investigation and the fix |
| The developer's gates — confirm, approve, test | The code: reading it, tracing it, changing it |
| Formatting the RCA to the PHR template | Producing the RCA's raw material |
| Local `git` branch, commit, PR — each on approval | Neither. It leaves changes in the working tree |

**Do not read source files yourself to "get oriented" first.** That is the overlap this structure
exists to remove: two half-investigations, one of them uninformed by the superpower's method. Your
evidence about the code is what the subagent returns.

### 3a — Assemble the context packet

Everything the subagent needs, from what you read in Steps 0e–2. It cannot see your conversation,
and it must not have to re-fetch the ticket to find out what it is working on.

| | |
|---|---|
| **Bug** | ID, title, `System.TeamProject`, work item type, state, area path |
| **Symptom** | What goes wrong, in one line, in your words |
| **Expected vs actual** | As the ticket states it, or as the feature plainly implies |
| **Error text, verbatim** | Every message, exception, stack frame and message template you found — in the description, the comments, or an attachment. Quote exactly; a paraphrased error is unsearchable |
| **Attachment findings** | What each attachment actually showed. You read them in Step 1; the subagent cannot re-read a screenshot you have already interpreted, so pass the finding, and the saved path if you have one |
| **Repro steps** | From the ticket, plus the data or config that triggers it |
| **Environment** | Build, version, branch, client environment — whatever the ticket names |
| **Linked items** | Parent, siblings and related IDs, with one line each on what they add. **Say plainly if a sibling is already fixed** — that makes this a port, not an investigation, and changes everything about how it should be approached |
| **Prior RCA on the ticket** | If there is one, pass it **flagged as an unverified claim** to be checked against source, not as a finding |
| **Code location** | The working directory, its `git rev-parse --show-toplevel`, current branch and `git log -1`; plus any extra dependency paths the developer supplied at invocation |
| **Mode** | `quick` / `smart` / `balanced` / `advanced`, and what it means for the branch sweep |
| **Comments** | Anything in the discussion that bears on the defect — often where the real detail is |

### 3b — Spawn the investigator

Spawn **one** subagent, and tell it in its prompt to:

1. **Read `reference\debugging-brief.md`** in this skill's directory first. That file is its standing
   brief — the Iron Law, the phase mapping, the source work, the inherited rules and the return
   contract. Do not restate the brief in the prompt; point at it.
2. **Invoke `superpowers:systematic-debugging`** and work Phases **1 to 3**.
3. **Stop at the end of Phase 3.** Implementation is Phase 4 and belongs to Step 5, after the
   developer has approved. An investigator that comes back having already edited files has broken
   the developer's gate.
4. **Read only.** It may read files, run `git`, `grep` and a disassembler, and read Azure DevOps
   through MCP. It may **not** edit files, and it may **not** write anything to Azure DevOps — no
   comments, no fields, no state, no branches, no PRs. Every ADO write in this procedure is yours.
5. **Return the twelve-section investigator return** defined in the brief.

Then pass the context packet.

❄️ Say that you are delegating, and to what — the developer should see the superpower being used:

> ❄️ **SUPERPOWERS · systematic-debugging** — *investigator subagent, Phases 1–3*
>
> …one line on what it is being sent to look into…

### 3c — Check what comes back

You are not re-running the investigation, and you must not go and read the code to "confirm" it —
that is the overlap again. You are checking the return is **usable**:

- **Is `rootCauseEstablished` true?** If not, go to *If the cause could not be established* below.
- **Is the root cause stated as a fact, with `file:line`?** A return that says *"probably"*,
  *"presumably"* or *"it may be a configuration issue"* has not finished Phase 3.
- **Are sections 2–11 filled?** Every one of them feeds an RCA field — `reference\rca-template.md`
  maps which goes where, and §2 and §3 are what `Custom.Evidence` is built from. A blank
  *Hypotheses* or *Analysis method* becomes a blank RCA field when you assemble at Step 5d, which is
  the half-done RCA reviewers complain about. `NOT ESTABLISHED` with a reason is acceptable; silence
  is not.
- **Is the proposed fix one change addressing that cause**, rather than a guard over the symptom or
  a bundle of improvements?

If any of these fail, **send it back** — continue the same subagent with what is missing rather than
spawning a fresh one, which would throw away everything it learned. If it fails twice, stop and put
the position to the developer honestly rather than presenting a plan you do not believe.

❄️ Close the block with the conclusion:

> ❄️ *end Phases 1–3 — root cause: `RequisitionsDA.cs:737` misreads the engine's `-1` sentinel*

### If the cause could not be established

`rootCauseEstablished: false` is a legitimate outcome, not a failure to hide. The subagent will have
returned what it investigated and what would settle it.

Take that back to **Step 2's insufficient path**: post a comment on the work item built around what
was actually investigated and the specific thing that would unblock it. That comment is far more
valuable to the reporter than the original verdict would have been. Then report to the developer and
stop.

## Step 4 — Fix plan · **STOP**

The plan is the subagent's findings, presented by you. You are the developer's interface, not a
second opinion — do not soften a definitive root cause into a maybe, and do not add a cause of your
own that the investigation did not produce.

Lead with the **root cause as a settled fact**. If the return left it as a candidate, you should have
sent it back in Step 3c; do not present two causes and let the developer choose between them.

Present, from the investigator return:

- **Root cause**, with `file:line` and the quoted code — plus the dependency evidence (assembly,
  method, IL offsets) if the behaviour was decided outside this repo
- **The exact change**, per file
- **Why this shape** and what else the investigation considered
- **Risk** — what could regress, what is newly reachable, what stays untouched
- **Blast radius outside this ticket.** If the same misread, missing branch or bad assumption is
  live at other call sites, list them with `file:line`, say plainly they are **not** in this change,
  and recommend whether to ship the one fix or all of them. This is often the most valuable thing in
  the plan, and nobody will find it later.
- **Branch impact**, if it swept — and if it did not, say which mode skipped it
- **How it should be tested** — numbered, including the regression cases that must still behave
- **Any decision that is genuinely theirs**, with your recommendation attached. These come from the
  return's *open questions*; put them as they are rather than answering them yourself.

Keep the ❄️ marker on the parts that are the superpower's findings, so it stays clear which of this
is investigation and which is you.

Then call **`ExitPlanMode`** and wait.

If they want changes, **take that back to the investigator subagent** — continue it with their
feedback rather than revising the plan yourself. A plan you edited but nobody re-investigated is
exactly the split-brain this structure removes. Loop until approved.

## Step 5 — Implement, through `systematic-debugging` · **STOP**

Approval grants edit rights — but not to you. **The fix is Phase 4, and Phase 4 belongs to the
superpower**, in a second subagent.

### 5a — Branch first, and that part *is* yours

Local `git` and Azure DevOps writes are the parent's, because each needs the developer's explicit
approval and a PR is an ADO write.

Read the existing branch names with `repo_branch` · `list` for the convention rather than assuming
one, propose a name, and ask before creating it. If they tell you to work directly on the current
branch, do that — but say plainly that a PR needs a source branch distinct from its target.

A **local** branch is `git checkout -b` in the working tree, and that is normally what you want. A
branch **in Azure DevOps** is `repo_create_branch` — server-side, and only after explicit approval. A
pull request is `repo_pull_request_write` · `create`, likewise only on explicit approval. Never
`git push` to an ADO remote as a way of creating the branch the MCP server would have created.

Do all of this **before** you spawn the implementer, so it edits on the right branch.

### 5b — Spawn the implementer

Spawn a subagent and tell it to:

1. **Read `reference\debugging-brief.md`** — the same brief, whose *Implementer* section is written
   for it.
2. **Invoke `superpowers:systematic-debugging`** and carry out **Phase 4** against the approved plan.
3. **Make the one fix**, edit byte-precisely, build the affected project, and leave the changes in
   the working tree.
4. **Not branch, commit, push or open a PR** — those are yours, above.
5. **Return the six-section implementer return** from the brief.

Pass it the context packet from Step 3a, the investigator's root cause and evidence chain, and **the
approved plan as approved** — including anything the developer changed while approving it.

❄️ Mark it as before:

> ❄️ **SUPERPOWERS · systematic-debugging** — *implementer subagent, Phase 4*

### 5c — Hand back, and **stop**

Give the developer the diff, the build result, and how to verify it. Then stop and wait.

**If they report a problem, it goes back to the subagent, never to you.** Continue the implementer
with what they observed — or, if the fix was addressing the wrong cause, go back to the investigator
with the new information. Do not "just adjust" the code yourself; a fix half-owned by the parent is
a fix nobody investigated.

The superpower's rule carries: after three failed attempts, stop and question the design with the
developer rather than trying a fourth.

Loop until they confirm it works. **Do not write the RCA before they confirm** — an RCA for a fix
that turned out not to work is worse than no RCA.

### 5d — Assemble the RCA payload, while the returns are in front of you

The moment they confirm, compose the eleven fields **from the two subagent returns**, following
`reference\rca-template.md`, which maps each field to the return sections it comes from.

Do this now, as one deliberate step, and not as an afterthought inside Step 6. The reason is
concrete: the returns are structured evidence you were handed, and by the time you are mid-patch you
will be tempted to write the RCA from your impression of the run instead. An RCA reconstructed from
memory is how *Hypotheses* ends up as one line and *Analysis method* ends up as "traced the code".

While assembling:

- **Every field traces to a return section.** If you find yourself writing a sentence that came from
  neither return, stop — either it is unverified, or the investigation did not cover it.
- **A `NOT ESTABLISHED` in a return stays honest in the field.** Write what was investigated and what
  would settle it. Do not smooth it into confident prose.
- **Nothing in the RCA may contradict the diff.** The fix description comes from the implementer, not
  from the plan — if the implementation deviated, the RCA records what was actually done.
- **The developer's own test result belongs in `Custom.Testing`.** What they confirmed at 5c is
  evidence; what was merely recommended is not.

Hold the assembled payload. Step 6 patches it.

## Step 6 — RCA onto the work item

You assembled the payload in Step 5d from the subagent returns, following
`reference\rca-template.md` — which says, per field, exactly which return sections feed it. This step
writes it.

Fill **every** field. A half-filled RCA is a recurring complaint from reviewers, and with the returns
in hand there is no excuse for one: if a field is thin, the fix is to go back to the subagent, not to
pad it.

**Eleven narrative fields**, all HTML-typed: `Custom.InitialFindings`, `Custom.ToolsandTechniques`,
`Custom.Hypotheses`, `Custom.AnalysisMethod`, `Custom.FixDescription`, `Custom.Evidence`,
`Custom.Testing`, `Custom.ImpactedArea`, `Custom.DeploymentPlan`, `Custom.PreventiveActions`,
`Custom.LessonsLearned`.

**Three classification dropdowns** — see below. All fourteen go in **one** `wit_work_item_write` ·
`update` call, as one `updates` array of `{op, path, value}` with `path` of the form
`/fields/Custom.Evidence`.

Three things that will bite you on the narrative fields:

- **They are HTML-typed.** Plain text with newlines renders as one run-on blob. Write real HTML —
  `<b>`, `<br>`, `<ul><li>`, `<pre>` for code.
- **Append, never overwrite.** If a field already has content, splice yours in and keep theirs. Guard
  for idempotence so a re-run cannot duplicate a section.
- **There is no `/rev` concurrency test through MCP.** The `updates` op set is `add`/`replace`/
  `remove` only — the guard the old script used cannot be expressed. Do not go around the server to
  get it back. Instead:

  1. **Re-read immediately before you patch** — `wit_work_item` · `get` — and compare `rev` with the
     one you noted in Step 0e. Changed? Someone edited the item while you worked: re-read the field
     contents, re-splice your additions onto the *current* text, and tell the developer.
  2. **Keep the gap small.** Compose the whole patch first, then re-read, then patch. Do not re-read
     at the start of Step 6 and patch ten minutes later.
  3. **Verify after.** The read-back below is not a formality — with no test op it is the only thing
     standing between you and a silent clobber. If a field you did not touch changed between your
     two reads, say so explicitly.

### The three classification dropdowns

These are picklists, not prose, and they are what QA reports on. Filling the eleven narrative fields
and leaving these blank is the half-done RCA reviewers complain about.

| Field | Reference name |
|---|---|
| Root Cause Category | `Custom.RootCauseCategory` |
| Root Cause | `Microsoft.VSTS.CMMI.RootCause` |
| Bug Type Classification | `Custom.BugTypeClassification` |

- **Never type a value from memory** — the same rule as state names. Call `wit_work_item` ·
  `get_type` with `workItemType: "Bug"` (or whatever `System.WorkItemType` says) and the item's
  project. The response carries the type's `fields[]`; find each dropdown by `referenceName` and
  choose only from its `allowedValues`. Nothing else is legal; prose in one of these fails with a
  400 that reads like an invalid field reference.
- **If `get_type` does not return `allowedValues` for a picklist, stop and ask the developer** for
  the permitted values. Do not fetch them from the REST fields endpoint, and do not guess from the
  values you have seen on other tickets. A wrong classification is worse than a blank one — see
  below.
- **Classify the cause the investigation established, not the symptom that was reported.** The
  investigator return's root cause (§2) is what you are classifying — a null-reference crash whose
  cause was an unhandled sentinel value is a missed edge case, not a code-quality defect. If you
  cannot map the established cause onto any allowed value, say so rather than reaching for the value
  that matches the symptom.
- **Root Cause carries its category in its own name.** Every value is `<cause> - <Category>` —
  `Missed Edge Cases - People`, `Wrong data mapping - Data`, `Deployment Errors - Environment`.
  So decide `Custom.RootCauseCategory` first, then pick a Root Cause whose suffix **matches it**.
  A mismatched pair is the single most common way this gets filled in wrong.
- **A value already on the item is authoritative context, not an empty slot.** If the ticket already
  says `Custom.RootCauseCategory = People`, treat that as given and pick a Root Cause ending in
  `- People`. Only change an existing value with the developer's explicit agreement, and say what it
  was before.
- **Propose, then confirm, then write.** Give all three as one short block — the value, and one line
  on why it fits what the investigation actually established. Wait for the developer. Only then
  patch. These get counted in reports, so a wrong one is worse than a blank one.
- **If nothing in `allowedValues` genuinely fits, leave that field unset and say so** rather than
  forcing the nearest match.
- `Microsoft.VSTS.CMMI.RootCause` is a 255-char string and cannot hold prose. The narrative root
  cause still heads `Custom.Evidence`.

Then **re-read the item** — `wit_work_item` · `get` — and confirm every field landed and nothing else
moved. Report the rev change, the per-field character counts for the eleven, and the three dropdowns
as `before → after`.

## Step 7 — Status

1. Call `wit_work_item` · `get_type` and read its `states[]`. Never type a state name from memory —
   this org has 21 for Bug alone. (If you already called `get_type` in Step 6, reuse that response
   rather than calling again.)
2. Propose the target that matches what actually happened, and say why.
3. **Confirm with the developer**, then `wit_work_item_write` · `update` with two operations in one
   call:

   ```
   { "op": "add", "path": "/fields/System.State",   "value": "<state from states[]>" }
   { "op": "add", "path": "/fields/System.History", "value": "<short note: what was done, by whom>" }
   ```

   A History note **is** what `System.History` is for — unlike RCA content, which never goes there.
4. Report the transition, `from → to`, from the response.

If the transition is rejected, the process template does not allow it from the current state. Report
that plainly and ask which state they want rather than trying alternatives at random.

## Step 8 — Done

Summarise in the chat:

- What was wrong, and the fix, in two lines
- Files changed, and whether they are committed (by default they are **not**)
- The RCA rev change
- The status transition
- **Anything still open** — an unproven version range, a defect found on other branches, a PR not
  raised, a question the developer still owes an answer to
- **Anything the investigation itself flagged as unresolved** — a `NOT ESTABLISHED` section, a branch
  sweep it skipped for the mode, a rejected hypothesis worth revisiting. Do not quietly drop these
  because the fix worked

If something the developer did not ask about matters — the defect is live on eight other branches,
the RCA on the ticket is wrong, the checkout they are working in is stale — say it here plainly. That is
often the most valuable thing this run produces.
