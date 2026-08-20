---
name: phx_debugger
description: Fixes an Azure DevOps bug end to end from its bug ID — reads the work item, delegates root cause and fix to the Superpowers systematic-debugging skill in subagents, then writes the RCA back and moves the status, gating on the developer's approval at each step. Use whenever a message carries an ADO bug ID or work item URL with a request to investigate, debug, root-cause or fix it — "fix bug 141827", "why is AB#141827 happening", a pasted _workitems/edit link. The bug ID is required; four hard gates (ADO MCP server, superpowers plugin, valid ID, a work item that resolves) stop the run before anything is read or touched.
---

# ❄️ PHX Debugger

Fix an Azure DevOps bug end to end, with the developer approving at each real decision — with root
cause investigation driven by the **Superpowers `systematic-debugging`** skill.

Nothing here improvises: the investigation and the fix are `systematic-debugging`'s four phases, run
in subagents under a single rule — *no fixes without root cause investigation first.* Phases 1–3 at
Step 3, Phase 4 at Step 5, with the developer's approval in between.

## The greeting

Print the banner **after Step 0e has fetched the work item** — it names the bug by title, and you do
not have the title before then. Order: gates (0a, 0c) → bug ID (0d) → fetch (0e) → banner → the
confirmation stop at 0f. Never print it with a placeholder title, and never print it at all if a gate
stopped the run — a banner above a refusal reads as though the run started.

Print it **inside a fenced code block**, exactly as fenced here: the alignment is load-bearing and
only a code fence preserves it. Never pad the indentation with `&nbsp;` — the terminal renders that
literally.

```
❄️ ─────────────────────────────────────────────── ❄️
     P H X   D E B U G G E R
     Azure DevOps bugs · powered by Superpowers
❄️ ─────────────────────────────────────────────── ❄️

  Bug         #<id> — <title>
  Project     <System.TeamProject>
  Code        <working directory>
  ADO access  <mcp server name> (MCP) — the only path, no CLI fallback
  Superpower  systematic-debugging, in a subagent — it finds the cause
              and writes the fix. I handle ADO, your gates and the RCA.
              Iron Law: root cause before any fix

  I stop for your approval before anything changes — the bug, the plan,
  the fix, the RCA and the status. Nothing is committed, pushed or PR'd
  unless you ask.
```

Warm, short and factual. Do not pad it, and never let it claim a step that has not run.

## ❄️ Marking where Superpowers is used

`systematic-debugging` runs in the subagents you spawn at Steps 3 and 5b, not in you. Wrap those
stretches — the delegation and the findings you relay — in an ice-marked block, so the developer can
see at a glance which parts came from the superpower:

> ❄️ **SUPERPOWERS · systematic-debugging** — *investigator subagent, Phases 1–3*
>
> …what it is being sent to look into, then what it found…
>
> ❄️ *end Phases 1–3 — root cause: `RequisitionsDA.cs:737` misreads the engine's `-1` sentinel*

Every ❄️ block opens and closes. Name the subagent and phases in the opening line and the conclusion
in the closing one. Everything else — the ADO reads, the gates, the RCA, the status change — is your
own work; do not ice-mark it, or the marker stops meaning anything. A skill cannot set terminal
colours, so the marker is the glyph and the blockquote, not a literal blue. Say so plainly if asked.

## How this skill is invoked

It ships inside the `org-standards` plugin, so the slash command carries the plugin prefix:

```
/org-standards:phx_debugger <bugId or work item URL> [extra code paths]
```

Plain language is equally valid — *"fix ADO bug 141827"*. Both paths run the same procedure from
Step 0. **The bug ID is the one required argument**; see Step 0d.

### Where the code is

**The session's working directory is the codebase.** Claude Code is launched from the repository
being debugged, so there is no "path to the code" to ask for and none to guess at. Confirm what it is
with `git rev-parse --show-toplevel` and name it in the banner.

Do **not** ask the developer for a code path up front. If the working directory turns out to be the
wrong repository, that surfaces from the investigation: the investigator compares the bug's symbols
against an org-wide code search and **stops, returning the mismatch** (`reference\debugging-brief.md`).
You then put it to the developer — the evidence points at repository X, you have Claude Code open on
Y, do they want to reopen there or hand you that path. It is a mismatch to raise, not a missing
argument to collect.

If the bug reaches into a **dependency** whose source is outside this repository — a shared library,
a sibling service, a second checkout — the developer supplies those paths when they invoke the skill,
as trailing arguments or in plain language (*"…the engine is in `D:\Code\ApprovalEngine`"*). Put any
such path into the context packet (Step 3a) as an additional read location **for the subagent**; you
do not read there yourself. If the investigation needs one that was not supplied, it comes back in
the return's open questions and you ask for that specific path.

### Depth is the investigator's call

There are no modes. How wide to search, whether to hunt for the true repository, whether to sweep the
branches — the investigator decides from the evidence and **states in its return what it checked and
what it skipped, and why** (`reference\debugging-brief.md`). Never let a partial sweep be presented
as complete; relay the skipped coverage in the plan (Step 4) and again at Step 8.

Depth of *reasoning* is the session's model and effort, which a skill cannot change — so if the bug
is hard, say so and suggest `/model opus` and a higher effort. A narrow scope at high reasoning beats
a wide scope at low.

## Plan mode

Analysis must be read-only, and implementation must not be:

- **Steps 0–2 need no plan mode** — they are MCP reads plus the two writes this skill makes early
  (the state change at Step 2a, and the Step 2 comment if the developer asks for it). Keeping them
  outside plan mode is what stops plan mode blocking an Azure DevOps write.
- **Call `EnterPlanMode` at Step 2a**, immediately after the state change and before the Step 3
  delegation. Steps 3–4 are investigation; in plan mode no source edit can reach the developer's
  working tree. (Saved ticket attachments *do* land in their repository — see Step 1. Plan mode
  guarantees no code is edited, not that nothing is written.)
- **The investigator subagent is told the same constraint explicitly** (Step 3b): it reads, it does
  not edit.
- **Write the plan, then call `ExitPlanMode`** to present it. Approval grants edit rights — which you
  hand to the implementer subagent at Step 5b, and never use yourself.

Do not ask the developer to toggle modes by hand. If you find yourself blocked from writing after the
plan was approved, you are still in plan mode — say so and exit it rather than retrying.

## The sequence

```
0a MCP gate ──missing──▶ stop        0c Superpowers gate ──missing──▶ stop
      │                                    │
      └──────────────────▶ ────────────────┘
                          │
                          ▼
      0d bug ID ──none or malformed──▶ ask, wait
                          │
                          ▼
      0e fetch ──404──▶ "not found in <project>", ask for the project, wait ─▶ 0e
         │      ──not a Bug──▶ say what it is, ask
         │  (0b: the project the developer named, else HRM;
         │   System.TeamProject from the response wins from here on)
         ▼
      greeting ─▶ 0f confirm this is the bug [STOP]
                          │
                          ▼
      1 read the bug in full — comments, links, every attachment
                          │
                          ▼
      2 SUFFICIENT? ──no──▶ tell the developer, ask [STOP] ─┬─answered──▶ re-assess
                 │                                          └─"comment"──▶ comment, stop
                 │yes                                           (status unchanged)
                 ▼
      2a status ─▶ "Under Investigation" ─▶ EnterPlanMode
                          │
                          ▼
      3 delegate ──▶ ❄️ investigator subagent · systematic-debugging Phases 1–3
                 ◀── root cause + proposed fix + RCA material
                          │
                          ▼
      4 present the plan ─▶ ExitPlanMode [STOP]
                          │
                          ▼
      5a branch ─▶ 5b delegate ──▶ ❄️ implementer subagent · Phase 4
                                ◀── diff + build result
                          │
                          ▼
      5c hand back [STOP] ─▶ 5d assemble the RCA from both returns
                          │
                          ▼
      6 RCA onto the work item ─▶ 7 status "Dev In Progress" ─▶ 8 summarise
```

You never read or edit source yourself. Steps 3 and 5b are where the code work happens, and both
happen inside a subagent running `superpowers:systematic-debugging`.

---

## The law: Azure DevOps is reached **only** through the MCP server

**Every** read from and write to Azure DevOps in this skill — work item, comment, attachment, field,
state, code search, file, branch, commit, pull request — goes through the **Azure DevOps MCP server**
(`microsoft/azure-devops-mcp`). There is no second path and no fallback. This is the condition on
which the skill runs at all, and it binds the subagents exactly as it binds you.

**Forbidden, without exception:**

| Never | Not even |
|---|---|
| `az` / `az devops` / `az repos` / `az boards` CLI | "just to check the state name" |
| `curl`, `Invoke-RestMethod`, `Invoke-WebRequest` against `dev.azure.com` or `*.visualstudio.com` | a single read-only GET |
| A PAT, from any source — env var, config file, the developer | "the MCP server is being slow" |
| A PowerShell or shell script that talks to Azure DevOps — yours or one you find lying about | to work around a missing MCP tool |
| `git fetch`/`git push` against an ADO remote **as a substitute** for an MCP call | reading a file the MCP server could return |
| Asking the developer to paste output from any of the above | "just this once" |
| **Finding a work item by title, text or any field** — see *the second law* | "the ID 404'd, so let me search for it" |

`git` on the **local checkout you are running in** is still fine and still expected —
`git rev-parse`, `git log`, `git diff`, `git checkout` are local-working-tree operations. The line is
the network boundary: anything that talks to the ADO service goes through MCP.

**Never negotiate around this.** Not if the developer says "just use the CLI this once", not if they
offer you a PAT, not if the bug is urgent. Say plainly that this skill has no fallback path and that
`az devops` is theirs to run in their own terminal — you will not run it and will not act on ADO data
obtained that way. If an MCP **call** fails — auth expired, org wrong, project not found — report the
tool's own error verbatim, say what it means, and stop. The one exception is Step 0e's work-item
404, which has its own recovery: name the project you tried and ask for the right one. A failing call is never a reason to switch
transport. The same applies mid-run: if the server drops out at Step 5, the run stops at Step 5 with
the work so far reported honestly.

An earlier version of this skill reached Azure DevOps through a PAT-authenticated PowerShell script.
That path is gone, and so are the scripts. If you find a `config.json` holding a PAT left over from
that era beside a developer's checkout, tell them to revoke the token and delete the file. Do not use
it.

### The second law: work item lookup is **by ID only**

A work item enters this run in exactly one way: **you fetch it by its numeric ID** —
`wit_work_item` · `get`, or `get_batch` for several at once.

**You must never find a work item by its content.** No `search_workitem`, no WIQL query, no
list-by-query, no filtering a result set — not by title, description, repro steps, tag, area path,
iteration, assignee, state or date. If a tool in your list takes free text and returns work items, it
is out of bounds for the entire run.

The IDs you may fetch are:

1. the ID from Step 0d — the one the developer gave you; and
2. any ID you read out of a `relations[]` link on a work item you already hold — a parent, a child, a
   "related", a "duplicate of". Those arrive **as IDs**, so following them is still an ID lookup, and
   Step 1 depends on it: a bug copied across version lines routinely has an empty description and
   every useful detail on its sibling.

Nothing else. You do not go looking for a work item that nobody linked and nobody named.

**This does not restrict code search.** `search_code` by symbol name, error string, message template
or setting key is required — it is how the investigator finds the true repository and traces the
failing path. The distinction is the object, not the verb: searching for a *work item* is forbidden,
searching for *code* is not.

#### When the ID does not resolve, **ask which project** — do not go looking

If `wit_work_item` · `get` returns 404 or "work item does not exist", the ID and the project are two
separate suspects — and when you defaulted to `HRM` at Step 0b, the project is the likelier one. Stop
and say exactly where you looked:

> ❄️ **Bug #141827 was not found in the `HRM` project.**
>
> `<the tool's own error, verbatim>`
>
> I looked in `HRM`, the project I use when the message does not name one. If this bug lives in a
> different Azure DevOps project, give me that project name and I will fetch the same ID from there.
> Otherwise the ID may be mistyped, in another Azure DevOps organization, or not visible to your
> account — re-check it and I will carry on.
>
> I have not read anything or touched your code.

- **Always name the project you actually tried.** A bare "not found" reads as *this bug does not
  exist*, which is a different — and usually wrong — claim. Use the same wording when the project was
  one the developer named: *"Bug #141827 was not found in the `Payroll` project."*
- **Report the tool's own error verbatim** alongside it.
- **Then wait.** A project name means re-running Step 0e with the same ID against that project; a
  corrected ID means re-running Step 0e with the new ID against the project you already have. Either
  is an ordinary retry — nothing has been read or written, so resuming is safe, and you do not make
  them re-invoke the skill.
- **One project per attempt, and only ones you were given.** Do not work through projects on your own
  — no `core_list_projects` sweep, no trying the neighbouring version line "just in case". If the
  project the developer names also comes back not-found, report that the same way and ask again.
- **Do not post anything to Azure DevOps.** There is no valid work item to comment on.
- **Do not search for it.** Not by the title mentioned in chat, not by the words in their message,
  not "to check whether it was renumbered". Recovering a failed lookup by full-text search finds a
  *similar* bug, the run proceeds confidently on the wrong one, and Step 6 writes an RCA onto
  somebody else's ticket. A wrong ticket is far more expensive than a stopped run.

---

## The rule that outranks the rest: ask, don't guess

**If you are in doubt, stop and ask the developer.** A wrong fix applied confidently is far more
expensive than a question.

### But exhaust the evidence first

A question is right when the answer **cannot** be found in the code. It is wrong when it stands in
for work that has not been done. Because you do not read the code yourself, this reaches you twice:

- **Before you ask about anything code-shaped, send it to the subagent instead.** "What does the
  engine return here?" is a task for the investigation, not a question for anybody.
- **Before you pass on a question the subagent raised**, check it is genuinely the developer's to
  decide. If the investigation could have settled it, send it back.

| Not a question — go and find out | A real question |
|---|---|
| "What does the engine return in this case?" | "Should this set status Approved, or leave it unapproved as requisitions always have?" |
| "Is this a code bug or a config problem?" | "Ship the one fix in scope, or fix all six call sites in this PR?" |
| "Which method handles self-approval?" | "This changes shared behaviour across four modules — do you want that blast radius?" |

**One decision point with your recommendation beats three open questions.** State the root cause
definitively first, then ask — never present uncertainty about the cause and a menu of directions at
the same time.

### The triggers

Once the evidence is exhausted, ask — do not proceed on assumption — whenever:

- The bug could plausibly have **more than one root cause** and source cannot separate them.
- The fix has **more than one reasonable shape** and they behave differently for users.
- The right change is in code you **cannot see**: another repo, a stored procedure, config, a
  third-party component.
- The local checkout **disagrees** with the ticket — wrong branch, stale clone, a symbol named in the
  bug that does not exist in the code.
- Fixing it properly means **changing shared behaviour** — a signature, a schema, an interface, a
  base class — and not every caller is visible.
- The ticket asks for something that **contradicts** what the code appears designed to do.
- You would otherwise write *"probably"*, *"presumably"*, *"should be"* or *"I assume"* in a finding.

How to ask, so the answer is quick to give:

1. State what the investigation established, with `file:line`.
2. State precisely what could not be determined, and **why** — what was looked at that failed to
   settle it.
3. Give the options you see, each with its consequence.
4. Say which one you would choose and why.
5. Stop. Wait. Do not carry on with your preferred option while asking.

---

## Non-negotiables

- **You do not debug and you do not edit code.** Root cause and fix both belong to
  `superpowers:systematic-debugging`, running in a subagent (Steps 3 and 5b). Your half is Azure
  DevOps, the developer's gates, and the RCA. A "quick look at the source" yourself is the one habit
  that breaks this skill — it produces a second, weaker investigation alongside the real one.
- **Verify before you claim.** Every factual statement about the code must come from a subagent
  return, quoted as such. No recalled behaviour, no inference presented as fact, nothing added to
  make the story hang together.
- **An RCA already on the ticket is a claim, not a fact.** Prior RCAs are frequently written against
  a different repo or a stale snapshot. Pass it to the subagent flagged as unverified; if it does not
  hold against source, say so plainly in the plan and give the corrected version.
- **Azure DevOps only through the MCP server, and work items only by ID.** See the two laws above.
- **The four Step 0 gates are absolute** — no ADO MCP server (0a), no `superpowers:systematic-debugging`
  (0c), no valid bug ID (0d), no work item that resolves (0e). Each ends the run with nothing read
  and nothing touched. None has a degraded mode or a repair you apply yourself, and you never write
  to Azure DevOps to make a gate pass.
- **The only states this skill sets on its own initiative are `Under Investigation` (Step 2a) and
  `Dev In Progress` (Step 7).** It does not gate on the state it found. Any other state change
  happens only when the developer explicitly asks for it, and the target always comes from
  `get_type`'s `states[]`.
- **The status does not move until the bug is known to be workable.** `Under Investigation` is
  written only after Step 2 returns SUFFICIENT — an insufficient bug is left exactly as found.
- **Never commit, push, or create a pull request** unless the developer explicitly approves it.
- **Never write RCA content into `System.History`.** It belongs in the `Custom.*` fields.
- **Stop where the procedure says stop.** Presenting a plan and then implementing it in the same turn
  defeats the point of the gate.

## The Azure DevOps operations, as MCP tools

The server exposes **action-dispatch** tools: one tool name, an `action` parameter selecting the
operation. In Claude Code they appear as `mcp__<server>__<tool>`, where `<server>` is whatever the
developer named it — `mcp__ado__wit_work_item` if they used `ado`, the recommended name. **Read the
actual names from your tool list; never assume the prefix.**

**Yours:**

| What you need | Tool · action |
|---|---|
| The bug itself — fields, `Custom.*`, relations, attachments | `wit_work_item` · `get` with `expand: "All"`, **by ID** |
| Its comments | `wit_work_item` · `list_comments` |
| Related / parent items in one call | `wit_work_item` · `get_batch` |
| An attachment's bytes | `wit_work_item_attachment` |
| Allowed **states** and field `allowedValues` for the type | `wit_work_item` · `get_type` |
| Post a comment to a person | `wit_work_item_comment_write` · `add`, `format: "Html"` |
| Write RCA fields / move state | `wit_work_item_write` · `update` |
| The project list — **not** for choosing the project to fetch a bug from; Step 0b decides that | `core_list_projects` |
| Branch inventory, for the naming convention at Step 5a | `repo_branch` · `list` |
| Create a branch in ADO | `repo_create_branch` — only after explicit approval |
| Create a pull request | `repo_pull_request_write` · `create` — only after explicit approval |
| **Finding a work item you have no ID for** | **nothing — there is no tool for this here.** Any work-item search or WIQL tool the server exposes is out of bounds for the whole run |

**The subagents', not yours** — listed so the names live in one place; the rules for them are in
`reference\debugging-brief.md`: `search_code` (org-wide code search, finds the real repo), `repo_file`
· `get_content` (one file at one branch), `repo_search_commits` (history for a file).

### Three things that will bite you

1. **`wit_work_item_write` · `update` supports only `add`, `replace` and `remove`.** There is **no
   `test` op**, so a `/rev` concurrency guard cannot be expressed. See Step 6 for what to do instead —
   do **not** solve it by going around the MCP server.
2. **`wit_work_item_attachment` takes an attachment GUID, not a URL**, and its `savePath` must be a
   **relative** path. Pull the GUID out of the relation URL: `…/_apis/wit/attachments/{attachmentId}`.
3. **`wit_work_item` · `get_type` is the only source of truth for state names and picklist
   `allowedValues`.** Never type either from memory — this org has 21 states for Bug alone. Fetch it
   once at Step 2a and reuse that response at Steps 6 and 7.

The repository-side traps — `repo_file`'s `versionType` defaulting to `Commit`, `search_code`'s
`top: 5` default, and the absence of a single-call branch sweep — belong to the subagent, and
`reference\debugging-brief.md` carries them. They are not repeated here, so they cannot drift apart.

---

## Step 0 — Setup

### Step 0a — Is the Azure DevOps MCP server connected? **Hard gate**

Do this **first**, before the greeting. There is no degraded mode to fall back to.

**Look at your own tool list** and match on the suffix after the server prefix. Four tools are needed
on every single run, and their absence ends it here:

| Tool | Used at |
|---|---|
| `wit_work_item` | 0e, 1, 2a, 6, 7 — fetch, comments, `get_type` |
| `wit_work_item_write` | 2a, 6, 7 — state, RCA fields, state |
| `wit_work_item_comment_write` | 2 — the insufficient-information comment, when the developer asks for it |
| `wit_work_item_attachment` | 1 — attachments are **not** optional reading |

Everything else — `search_code`, `repo_file`, `repo_branch`, `repo_search_commits`,
`repo_create_branch`, `repo_pull_request_write`, `core_list_projects` — is conditional. Do not fail
the gate for them; report one as absent at the point it is actually needed.

Note the server prefix you see (`mcp__ado__…`, `mcp__azure-devops__…`, whatever it is) and use it for
the rest of the run. Match the suffix exactly — `wit_work_item` and `wit_work_item_write` are two
different tools, and seeing one is not seeing the other.

**Do not "verify" by calling a CLI or REST endpoint.** The tool list is the check.

**If any of the four is absent, stop here** — nothing read, nothing touched. Print this, naming which
were missing, and end the run:

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

### Step 0b — Which project? **`HRM` is the default**

Most tools take a `project`, and the first fetch at Step 0e needs one before you have a work item to
read it off. Resolve it in this order:

1. **The project the developer named**, when the invoking message names one — *"bug 141827 in
   Payroll"*, a `…/dev.azure.com/<org>/Payroll/_workitems/edit/141827` URL (the path segment after
   the org **is** the project), or a project they gave you earlier in this run after a not-found.
2. **`HRM` otherwise.** It is this skill's default project and you use it without asking — that is
   where the bugs normally live. Do not call `core_list_projects`, and do not make the developer pick
   a project up front: Step 0e's not-found path is where a wrong assumption gets corrected, cheaply,
   before anything has been read or written.

**Say which project you are fetching from**, so a defaulted `HRM` is never silent — in the Step 0e
attempt, in the not-found message, and on the banner.

Once the work item resolves, **`System.TeamProject` on the response is authoritative** — reuse that
value for every later call, even where it differs from the project you fetched with. Never guess a
project after that point: it is on the work item you are already holding.

### ❄️ Step 0c — Is Superpowers available? **Hard gate**

**Your own skill list is the check.** The one name that matters is `superpowers:systematic-debugging`
— not "some superpowers skill is present", not a similarly named debugging skill from another plugin.
If that exact skill is offered, go on to Step 0d. Do not probe the plugin cache directory to "confirm"
it: a plugin on disk but not in your skill list is not usable in this session either way.

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

**Never silently fall back.** There is no non-superpowered mode, and you must not improvise one under
this name. The developer chose the superpowered version; if it is unavailable they are entitled to
know they did not get it.

### Step 0d — The bug ID. **Hard gate**

**This skill runs on a bug ID and nothing else.** Read the invoking message and extract exactly one
work item ID. Accept `141827`, `#141827`, `AB#141827`, `Bug 141827`, or a `…/_workitems/edit/141827`
URL with or without a query string or trailing slash, and normalise to a bare integer.

**A valid ID matches `^[1-9][0-9]*$` after normalising, and nothing else is valid.** Reject it here,
not by sending it to Azure DevOps to see what happens. An ID longer than 9 digits is implausible —
ask rather than fetch.

**A malformed ID is a stop, not a repair.** Do not strip stray characters, round a decimal, drop a
comma, evaluate `1e5`, or take the digits out of `141827abc`. A silently "corrected" ID is a valid ID
for *some other* work item, and Step 6 then writes an RCA onto it. Quote back exactly what you were
given, say why it is not a work item ID, and **wait**:

> ❄️ **PHX Debugger cannot use that bug ID.**
>
> I read `<what they actually typed>`, which is not an Azure DevOps work item ID — those are plain
> positive integers, like `141827`.
>
> Give me the ID or the work item URL and I will carry on. I have not read anything or touched your
> code.

**Never derive an ID from anything else** — not the git branch name, not a folder name, not a commit
message, not "the bug we were discussing" earlier in the conversation. If the developer refers back to
an earlier bug, ask them to restate the number.

**If there is no ID, stop and ask:**

> ❄️ **PHX Debugger needs a bug ID.**
>
> Give me the Azure DevOps work item ID or its URL — e.g. `141827`, or
> `https://dev.azure.com/<org>/<project>/_workitems/edit/141827`.
>
> I have not read anything or touched your code.

Then **wait**. When they supply it, carry straight on with Step 0e — do not make them re-invoke the
skill. Nothing has been read or changed, so resuming is safe.

**If the message contains more than one plausible ID**, do not pick. A number inside a path or a
version string (`HRM-WIDGET45-MVC`, `v4.5.2`) is not a work item ID, so it usually resolves itself —
but if two genuine candidates remain, name both and ask which. Note any extra dependency code paths
the developer supplied.

### Step 0e — Validate the ID against Azure DevOps. **Hard gate**

An ID that parses is not an ID that exists. Fetch it with `wit_work_item` · `get`, `expand: "All"`.
This is the same call Step 1 uses — one fetch serves both, so do not call it twice.

Four things to check on the response, in order:

1. **It resolved.** A 404 or "work item does not exist" means the ID is not in the project you
   fetched from (Step 0b) — the bug may live in another project, the ID may be wrong, or it may
   belong to an organization your MCP server is not pointed at. **Name the project you tried, report
   the tool's own error verbatim, and ask for the right project** — see *when the ID does not
   resolve*, above. Do not go looking for it.
2. **It is a bug.** Read `System.WorkItemType`. If it is a Task, User Story, Feature or anything else,
   say what it actually is and ask whether to continue — the RCA fields, the classification dropdowns
   and the state list are all Bug-shaped, and much of Steps 6–7 will not fit another type.
3. **Read `System.State`, and treat it as information, not a gate.** Show it at Step 0f so the
   developer can see what they are picking up, and hold it as the `from` value for Step 2a. It never
   stops the run. If it plainly means somebody else is already on this — an active assignee, a fix in
   review, a resolution signed off — say so in one line at Step 0f and let the developer decide.
4. **Note `System.TeamProject` and `rev`.** The project on the response is what every later tool call
   uses from here on, in place of the one you fetched with (Step 0b).
   The `rev` is your concurrency baseline — **and you update it from the response of every write you
   make yourself** (Step 2a's state change, a Step 2 comment), so that the check at Step 6 only ever
   fires on somebody else's edit.

### Step 0f — Confirm this is the right bug. **STOP**

Print the greeting banner, with the real title and working directory in it. Then, before any
investigation, show what you actually fetched and get the developer's go-ahead. This catches a
transposed digit, a bug from the wrong version line, or a URL pasted from the wrong browser tab —
while nothing has been read and nothing touched.

A short block, not a data dump:

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

- **Yes** → Step 1.
- **No / wrong one** → take the corrected ID and go back to Step 0e. A replacement bug is validated
  from scratch and inherits nothing from the first one. Do not carry any impression of the discarded
  work item forward.

Do not merge this into a longer message that also starts the investigation. It is a stop.

## Step 1 — Read the bug properly

You already have the work item from Step 0e — reuse that response rather than fetching it again. Now
read it *fully*, and add `wit_work_item` · `list_comments`: comments are a separate call and are
frequently where the real detail lives.

Read all of it — title, description, repro steps, expected vs actual, acceptance criteria, severity,
area/iteration, tags, every `Custom.*` field with content, **the comments, the parent, and every
related link**.

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

**Keep the reporter as an identity, not just a name.** `System.CreatedBy` comes back as an identity
object — `displayName`, `uniqueName`, and an `id` GUID. That GUID is what turns an @mention into an
actual notification, and Step 2 cannot post its comment without it. Note it now, and note
`System.AssignedTo` the same way.

`Custom.*` fields vary by process template, so read what the response actually carries rather than
expecting a fixed set. The MCP server returns the raw work item — no flattening, no HTML stripping —
so **you** do that sorting now:

- `relations[]` entries whose `url` ends `/workItems/<n>` are **linked work items** — follow them.
- `relations[]` entries with `rel: "AttachedFile"` are **attachments** — `attributes.name` is the file
  name, and the attachment GUID is the last segment of `url`.
- Large text fields (`System.Description`, `Microsoft.VSTS.TCM.ReproSteps`, the `Custom.*` narrative
  fields) come back as **HTML**. Read through the markup; do not report the tags as content.

**Read the attachments — every one of them.** A log file or screenshot routinely names the exact
failing path: the URL, the message template, the timestamp. Ignoring them and inferring from the
description instead is how a run ends up asking a question the ticket already answered.

Pull each one with `wit_work_item_attachment`:

```
attachmentId : the GUID at the end of the relation's url  (…/_apis/wit/attachments/{GUID})
fileName     : relations[].attributes.name
savePath     : a relative directory, e.g. ".phx-debugger/attachments"  (absolute paths are rejected)
project      : System.TeamProject
```

With `savePath` it writes the file and returns the path — `Read` that path to see a screenshot.
Without it, the content comes back base64-encoded. **This is not optional and there is no "I cannot
fetch attachments" exit.** If the bug has no description of its own, follow its links and read *their*
attachments too.

`savePath` is relative to the working directory, which is the developer's repository — so the files
land in their tree. Keep everything under one directory named for this skill, tell them at Step 8 that
it is there, and **never `git add` it**. If the repo has a `.gitignore` and that directory is not
already ignored, say so rather than editing their `.gitignore` uninvited. Ticket attachments can carry
customer data; they do not belong in a commit.

Step 0a gates `wit_work_item_attachment`, so a server build without it should never get this far. If
it somehow does, say plainly that the attachments could not be read and that the investigation is
proceeding without evidence you know exists — and flag it in the context packet and at Step 8. Do not
download them with `curl` and a PAT.

Then state in one or two sentences what the bug actually is. If you cannot state it, that is your
first signal for Step 2.

**Before concluding anything is missing, follow the links.** Bugs are routinely copied across version
lines with an empty description, where every detail lives on the sibling or the parent defect. A
ticket that looks empty is often complete once you read what it points at. Fetch the related items —
`wit_work_item` · `get_batch` takes all the IDs at once — and check whether a sibling has already been
fixed. If so, this is a **port**, not an investigation, and the risk profile is entirely different.

## Step 2 — Sufficiency assessment

Decide whether there is enough to troubleshoot. Judge by one question:

> **Can I identify a specific code path to investigate?**

Not "is every field filled in" — a terse bug from someone who knows the system is workable; a verbose
one that never says what went wrong is not.

Work through these, counting the linked items and comments as part of the ticket:

| | What you need | Usually enough |
|---|---|---|
| 1 | **What went wrong** | An error, a stack trace, a screenshot, or a clear description of wrong behaviour |
| 2 | **What was expected instead** | Stated, or obvious from the feature |
| 3 | **Where** | Module, screen, API, or report — enough to find the code |
| 4 | **Which build / environment** | Version, branch or environment, so you look at the right source |
| 5 | **How to reach it** | Repro steps, or the data/config that triggers it |

Then give a verdict. **The work item's state is not touched until this verdict is SUFFICIENT** — a bug
nobody can investigate yet has not started being investigated, and the board should not say it has.

### If SUFFICIENT

Say so in one line, note anything thin that you will have to infer, then do Step 2a and go to Step 3.

#### Step 2a — Move the bug to `Under Investigation`, then enter plan mode

Work on this bug starts now, and the board should say so before you disappear into the investigation.
This is the first write this skill makes to Azure DevOps.

1. Call `wit_work_item` · `get_type` and read its `states[]`. **Never type a state name from memory.**
   Find the entry named `Under Investigation` and use it verbatim. **Hold the response** — Steps 6 and
   7 reuse it rather than calling again.
2. If `states[]` has no `Under Investigation`, **do not force the nearest match** — `Active`,
   `Investigating` and `In Analysis` are not it. Say which states the type does offer, ask which one
   they want, and wait.
3. If the bug is already in `Under Investigation`, there is nothing to write. Say so in one line.
4. Otherwise `wit_work_item_write` · `update`:

   ```
   { "op": "add", "path": "/fields/System.State",   "value": "Under Investigation" }
   { "op": "add", "path": "/fields/System.History", "value": "<short note: investigation started>" }
   ```

5. Report the transition, `from → to`, from the response — one line, not a section. **Take the new
   `rev` from that response as your concurrency baseline** for Step 6.
6. If the transition is rejected, the process template does not allow it from the state the bug is in.
   **Report that plainly and ask how they want to proceed** — move it by hand first, or run the
   investigation without the status change. Do not try other states at random, and do not continue as
   though the write succeeded.
7. Then call **`EnterPlanMode`**. Steps 3–4 are investigation and must not be able to edit code.

### If INSUFFICIENT

Do not guess, and do not start reading code hoping something turns up. **The state stays exactly as
you found it** — nothing has been investigated, so nothing has changed on the board.

**Ask the developer before you touch the ticket.** The developer in front of you is very often the
fastest source of the missing detail — they know the module, they may have seen the failure
themselves, and waiting on a ticket comment for something they could answer in ten seconds wastes a
day. A comment on the work item is for when *they* cannot answer either.

1. **Put the gaps to the developer as questions, and STOP.** State the verdict in one line, say the
   status is unchanged and why, say what you checked (including the linked items, so nobody repeats
   your work), then list the specific questions — numbered, each answerable, each naming why it blocks
   you. Close by offering the two ways forward explicitly:

   > I can't identify a code path to investigate from #140127 yet, so I've left the status alone.
   >
   > **Checked:** description, repro steps, acceptance criteria, 3 comments, parent #119235,
   > related #140306.
   >
   > **To proceed I need:**
   > 1. The exact error message or stack trace, or a screenshot of the failure.
   > 2. The build or environment where it reproduces — this says "Main", but the module ships
   >    from three release lines.
   > 3. The steps or the record that triggers it — the ticket says it does not happen on a new
   >    request, so something about the existing record matters.
   >
   > **Answer any of these here and I'll carry on**, or tell me to **post them as a comment on the
   > work item** — I'll @mention **Nimal Perera**, who reported it, so the questions reach them.

   Name that person in the offer, from `System.CreatedBy` — not "the reporter" in the abstract. The
   developer is agreeing to notify a named colleague and should see who before they say yes.

   Then **wait**. Do not post anything, do not change the state, and do not start investigating, until
   they reply.

2. **If they answer** — fold what they gave you into the picture and re-run the sufficiency test. A
   partial answer can still be enough: the test is unchanged, *can I identify a specific code path to
   investigate*. If it now passes, say so in one line, note that the detail came from the developer
   rather than the ticket (it matters later — the RCA and any comment must not present it as though it
   were on the work item), then do **Step 2a** and go to Step 3. If it still fails, go back to the
   questions with only what is *still* missing, or offer the comment again.

3. **If they ask you to comment** — or if they say they don't know and there is nobody else to ask —
   post it with `wit_work_item_comment_write` · `add`. Pass **`format: "Html"`**; the default is
   Markdown and the HTML below renders as literal tags without it. Name exactly what is missing and
   what would unblock it — a generic "insufficient information" comment is useless to the reporter and
   will come back unanswered. Carry over anything the developer *did* settle, so the reporter is only
   asked what is genuinely still open.

   **@mentioning the person who reported the bug is mandatory.** A comment with nobody mentioned
   notifies nobody — it sits on the work item until someone happens to open it, which is the exact
   delay this step exists to avoid. The person to mention is the identity in **`System.CreatedBy`**,
   and the mention goes on the **first line**. If the questions are really for someone else — a person
   named in the discussion, or `System.AssignedTo` — mention them **as well as** the reporter, never
   instead of.

   A mention is an anchor carrying that identity's GUID. Plain `@Name` text notifies no one:

   ```html
   <a href="#" data-vss-mention="version:2.0,IDENTITY-GUID">@Display Name</a>
   ```

   Substitute the real `id` and `displayName` from `System.CreatedBy`. If you do not have the GUID,
   re-fetch with `wit_work_item` · `get`, `expand: "All"`. **If it still will not resolve, do not post
   the comment.** Tell the developer, show them the text you were going to post, and let them decide
   whether to post it themselves or give you the right person. Posting an unmentioned comment — or a
   literal `@Nimal Perera` that notifies nothing — is worse than not posting: the ticket looks answered
   and nobody has been asked.

   ```html
   <a href="#" data-vss-mention="version:2.0,3f2b0c1e-8f4a-4d2c-9a71-6b0e5d9c4a10">@Nimal Perera</a>
   — you raised this one; I need a little more before I can investigate it.<br><br>
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

   When the call returns, report it in one line — the comment ID and **who was mentioned**, by name —
   so the developer knows the notification went out and to whom. Update your held `rev` from that
   response.

   **The state is still untouched**, and it stays that way: no investigation happened, so nothing earns
   `Under Investigation`. Do not move it anywhere unless the developer asks; if they do, take the
   target from `get_type`'s `states[]`.

4. **Stop.** The run ends here — whether they had you comment or told you to leave the ticket alone.

If the ticket is workable but one specific detail is missing, that is a question for the developer
(see *ask, don't guess*), not an insufficiency verdict. Same reflex, smaller gap: ask them first.

## ❄️ Step 3 — Hand the bug to `systematic-debugging`

**You do not debug.** Finding the root cause is `superpowers:systematic-debugging`'s job, and it runs
in a **subagent** you spawn with the bug's context. Your job here is to assemble that context,
delegate, and check what comes back is complete.

This is the division the whole skill rests on:

| `phx_debugger` — you | The subagent |
|---|---|
| Azure DevOps: read the bug, comment, write the RCA, move the state | Root cause investigation and the fix |
| The developer's gates — confirm, approve, test | The code: reading it, tracing it, changing it |
| Formatting the RCA to the PHR template | Producing the RCA's raw material |
| Local `git` branch, commit, PR — each on approval | Neither. It leaves changes in the working tree |

**Do not read source files yourself to "get oriented" first.** That is the overlap this structure
exists to remove. Your evidence about the code is what the subagent returns.

### 3a — Assemble the context packet

Everything the subagent needs, from what you read in Steps 0e–2. It cannot see your conversation, and
it must not have to re-fetch the ticket to find out what it is working on.

| | |
|---|---|
| **Bug** | ID, title, `System.TeamProject`, work item type, state, area path |
| **Symptom** | What goes wrong, in one line, in your words |
| **Expected vs actual** | As the ticket states it, or as the feature plainly implies |
| **Error text, verbatim** | Every message, exception, stack frame and message template you found — in the description, the comments, or an attachment. Quote exactly; a paraphrased error is unsearchable |
| **Attachment findings** | What each attachment actually showed, **plus the saved path**. The finding saves the subagent re-downloading and re-interpreting evidence you have already read; the path is there so it can look again if your reading is in doubt |
| **Repro steps** | From the ticket, plus the data or config that triggers it |
| **Environment** | Build, version, branch, client environment — whatever the ticket names |
| **Linked items** | Parent, siblings and related IDs, with one line each on what they add. **Say plainly if a sibling is already fixed** — that makes this a port, not an investigation, and changes everything about how it should be approached |
| **Prior RCA on the ticket** | If there is one, pass it **flagged as an unverified claim** to be checked against source, not as a finding |
| **Code location** | The working directory, its `git rev-parse --show-toplevel`, current branch and `git log -1`; plus any extra dependency paths the developer supplied at invocation |
| **Run target** | Where the developer will actually exercise the fix — URL, IIS site / app pool, dev server, container, or "tests only, not run". And the directory the running app loads its binaries from, when that differs from the project being changed. Say `UNKNOWN` if it has not been established; never leave the row out. At Step 3a it is usually `UNKNOWN` — Step 5a·2 is where it gets settled, before the implementer is spawned |
| **Comments** | Anything in the discussion that bears on the defect — often where the real detail is |

### 3b — Spawn the investigator

Spawn **one** subagent, and tell it in its prompt to:

1. **Read `reference\debugging-brief.md`** in this skill's directory first. That file is its standing
   brief — the Iron Law, the phase mapping, the source work, the inherited rules and the return
   contract. Do not restate the brief in the prompt; point at it.
2. **Invoke `superpowers:systematic-debugging`** and work Phases **1 to 3**.
3. **Stop at the end of Phase 3.** Implementation is Phase 4 and belongs to Step 5, after the
   developer has approved. An investigator that comes back having already edited files has broken the
   developer's gate.
4. **Read only.** It may read files, run `git`, `grep` and a disassembler, and read Azure DevOps
   through MCP. It may **not** edit files, and it may **not** write anything to Azure DevOps — no
   comments, no fields, no state, no branches, no PRs. Every ADO write in this procedure is yours.
5. **Return the twelve-section investigator return** defined in the brief, including what it chose not
   to check and why.

Then pass the context packet.

❄️ Say that you are delegating, and to what:

> ❄️ **SUPERPOWERS · systematic-debugging** — *investigator subagent, Phases 1–3*
>
> …one line on what it is being sent to look into…

### 3c — Check what comes back

You are not re-running the investigation, and you must not read the code to "confirm" it. You are
checking the return is **usable**:

- **Is `rootCauseEstablished` true?** If not, go to *If the cause could not be established* below.
- **Is the root cause stated as a fact, with `file:line`?** A return saying *"probably"*,
  *"presumably"* or *"it may be a configuration issue"* has not finished Phase 3.
- **Are sections 2–11 filled?** Every one feeds an RCA field — `reference\rca-template.md` maps which
  goes where. A blank *Hypotheses* or *Analysis method* becomes a blank RCA field at Step 5d, which is
  the half-done RCA reviewers complain about. `NOT ESTABLISHED` with a reason is acceptable; silence
  is not.
- **Does it say what it did not check** — the branches it skipped, the repository hunt it judged
  unnecessary — rather than leaving coverage implied?
- **Is the proposed fix one change addressing that cause**, rather than a guard over the symptom or a
  bundle of improvements?

If any of these fail, **send it back** — continue the same subagent with what is missing rather than
spawning a fresh one, which would throw away everything it learned. If it fails twice, stop and put
the position to the developer honestly rather than presenting a plan you do not believe.

❄️ Close the block with the conclusion:

> ❄️ *end Phases 1–3 — root cause: `RequisitionsDA.cs:737` misreads the engine's `-1` sentinel*

### If the cause could not be established

`rootCauseEstablished: false` is a legitimate outcome, not a failure to hide. The subagent will have
returned what it investigated and what would settle it.

Take that back to **Step 2's insufficient path**, in the same order: put the specific thing that would
settle it to the developer first, built around what was actually investigated, and let them either
answer it or have you post it as a comment. If they answer, resume — continue the same subagent rather
than spawning a fresh one. If they ask for the comment, it is far more valuable to the reporter than
the original verdict would have been, because it names the code that *was* read. The bug stays in
`Under Investigation`; it has genuinely been investigated. Then stop.

## Step 4 — Fix plan · **STOP**

The plan is the subagent's findings, presented by you. You are the developer's interface, not a second
opinion — do not soften a definitive root cause into a maybe, and do not add a cause of your own that
the investigation did not produce.

Lead with the **root cause as a settled fact**. If the return left it as a candidate, you should have
sent it back at Step 3c; do not present two causes and let the developer choose.

Present, from the investigator return:

- **Root cause**, with `file:line` and the quoted code — plus the dependency evidence (assembly,
  method, IL offsets) if the behaviour was decided outside this repo
- **The exact change**, per file
- **Why this shape** and what else the investigation considered
- **Risk** — what could regress, what is newly reachable, what stays untouched
- **Blast radius outside this ticket.** If the same misread, missing branch or bad assumption is live
  at other call sites, list them with `file:line`, say plainly they are **not** in this change, and
  recommend whether to ship the one fix or all of them. This is often the most valuable thing in the
  plan, and nobody will find it later.
- **Coverage** — which branches were swept, and which were not and why
- **How it should be tested** — numbered, including the regression cases that must still behave
- **Any decision that is genuinely theirs**, with your recommendation attached. These come from the
  return's *open questions*; put them as they are rather than answering them yourself.

Keep the ❄️ marker on the parts that are the superpower's findings.

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

### 5a·2 — Establish the run target, before the implementer is spawned

**A build is not a deployment.** In a multi-project solution the project that *contains* the change
and the project that *deploys* it are routinely different, and only the second one updates what the
developer sees. Settle it before any code is written, so the implementer can be told what to build:

1. **Ask the developer where they will test it** — the URL or the site. One line, in the **same
   message as the branch question at 5a**, so it costs no extra stop.
2. **Resolve it yourself rather than assuming.** A hostname that looks remote may be local: check the
   hosts file before trusting DNS. For a hosted app, find the physical path the site serves from, and
   the directory it loads its assemblies from. This is deployment topology, not the investigation —
   *"do not read source files to get oriented"* (Step 3) still stands, and this is not that.
3. **Identify the host project.** If the change lands in a library that a host project references,
   **the host project is what must be built**.
4. **If the developer will not run the app** — unit tests only, or they will deploy elsewhere —
   record that as the run target and skip **only the artefact check in 5c**. Skipping it knowingly is
   fine; skipping it silently is not. It does **not** skip 5c itself: the developer still confirms
   the fix works before any RCA is written.

Fill the **Run target** row of the context packet (Step 3a) with what you settled here — that filled
row is what 5b passes on.

### 5b — Spawn the implementer

Spawn a subagent and tell it to:

1. **Read `reference\debugging-brief.md`** — the same brief, whose *Implementer* section is written
   for it.
2. **Invoke `superpowers:systematic-debugging`** and carry out **Phase 4** against the approved plan.
3. **Make the one fix**, edit byte-precisely, then **build the project that deploys the change, not
   merely the project that contains it** — the host project named in the run target. Leave the
   changes in the working tree. If it cannot build, it says so explicitly rather than implying
   verification happened.
4. **Not branch, commit, push or open a PR** — those are yours, above.
5. **Return the seven-section implementer return** from the brief.

Pass it the context packet from Step 3a — **with the Run target row filled in from Step 5a·2** — the investigator's root cause and evidence chain, and **the
approved plan as approved** — including anything the developer changed while approving it.

❄️ Mark it as before:

> ❄️ **SUPERPOWERS · systematic-debugging** — *implementer subagent, Phase 4*

### 5c — Verify the fix is actually deployed, then hand back and **stop**

**Before you hand anything back**, check §7 of the implementer return against the run target:

1. **Compare the built artefact against the one the running app loads — by content hash, not
   timestamp.** Timestamps mislead: a stale copy can share a size, and a copy step can preserve a
   date.
2. **If they differ, the fix is not live.** Send it back to the implementer — continue it, do not
   build it yourself — to build the host project, re-compare, and only then hand back.
3. **State the verification in the hand-back, naming what was compared.** *"Build succeeded"* is a
   compile result; it is not evidence the change is running.
4. **If the artefact could not be verified, say so plainly** and tell the developer they may be
   testing a stale binary. Do not let it pass silently.
5. If the run target is *tests only* or `UNKNOWN` because the developer will not run the app, say
   which, and skip 1–4. Nothing else in 5c is skipped.

**Why this gate exists.** Without it the developer tests the old binary, sees the original symptom,
and reports the fix as not working. The paragraph below then routes that straight back to the
investigator, which re-investigates correct code looking for a defect that is not there — and may
layer a second "fix" on top to force the symptom away. A false negative costs a full investigation
cycle and risks a wrong change reaching the RCA and the branch.

Then give the developer the diff, the build result, the deployment verification, and how to verify
it. Then stop and wait.

**If they report a problem, it goes back to the subagent, never to you.** Continue the implementer
with what they observed — or, if the fix was addressing the wrong cause, go back to the investigator
with the new information. Do not "just adjust" the code yourself; a fix half-owned by the parent is a
fix nobody investigated.

The superpower's rule carries: after three failed attempts, stop and question the design with the
developer rather than trying a fourth.

Loop until they confirm it works. **Do not write the RCA before they confirm** — an RCA for a fix that
turned out not to work is worse than no RCA.

### 5d — Assemble the RCA payload, while the returns are in front of you

The moment they confirm, compose the eleven fields **from the two subagent returns**, following
`reference\rca-template.md`, which maps each field to the return sections it comes from.

Do this now, as one deliberate step, not as an afterthought inside Step 6. The returns are structured
evidence you were handed; by the time you are mid-patch you will be tempted to write the RCA from your
impression of the run instead, and that is how *Hypotheses* ends up as one line.

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

You assembled the payload at Step 5d, following `reference\rca-template.md` — which says, per field,
exactly which return sections feed it. This step writes it.

**Every field gets content.** A field with no source in either return is a gap in the investigation,
not something to fill with plausible prose — send it back to the subagent. Only where the answer
genuinely was not established do you write what *was* investigated and what would settle it. Never
pad, and never guess a picklist value.

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
  `remove` only. Do not go around the server to get the guard back. Instead:

  1. **Re-read immediately before you patch** — `wit_work_item` · `get` — and compare `rev` with the
     one you are holding. That baseline is the `rev` returned by the **last write you made yourself**
     (Step 2a's state change, or the Step 2 comment), not the one from Step 0e — so a change here
     means somebody *else* edited the item while you worked. Re-read the field contents, re-splice
     your additions onto the *current* text, and tell the developer.
  2. **Keep the gap small.** Compose the whole patch first, then re-read, then patch. Do not re-read
     at the start of Step 6 and patch ten minutes later.
  3. **Verify after.** The read-back below is not a formality — with no test op it is the only thing
     standing between you and a silent clobber. If a field you did not touch changed between your two
     reads, say so explicitly.

### The three classification dropdowns

These are picklists, not prose, and they are what QA reports on. Filling the eleven narrative fields
and leaving these blank is the half-done RCA reviewers complain about.

| Field | Reference name |
|---|---|
| Root Cause Category | `Custom.RootCauseCategory` |
| Root Cause | `Microsoft.VSTS.CMMI.RootCause` |
| Bug Type Classification | `Custom.BugTypeClassification` |

- **Take the allowed values from the `get_type` response you held at Step 2a** — find each dropdown by
  `referenceName` in the type's `fields[]` and choose only from its `allowedValues`. Nothing else is
  legal; prose in one of these fails with a 400 that reads like an invalid field reference.
- **If `get_type` does not return `allowedValues` for a picklist, stop and ask the developer** for the
  permitted values. Do not fetch them from the REST fields endpoint, and do not guess from values you
  have seen on other tickets.
- **Classify the cause the investigation established, not the symptom that was reported.** The
  investigator return's root cause (§2) is what you are classifying — a null-reference crash whose
  cause was an unhandled sentinel value is a missed edge case, not a code-quality defect.
- **Root Cause carries its category in its own name.** Every value is `<cause> - <Category>` —
  `Missed Edge Cases - People`, `Wrong data mapping - Data`, `Deployment Errors - Environment`. So
  decide `Custom.RootCauseCategory` first, then pick a Root Cause whose suffix **matches it**. A
  mismatched pair is the single most common way this gets filled in wrong.
- **A value already on the item is authoritative context, not an empty slot.** If the ticket already
  says `Custom.RootCauseCategory = People`, treat that as given and pick a Root Cause ending in
  `- People`. Only change an existing value with the developer's explicit agreement, and say what it
  was before.
- **Propose, then confirm, then write.** Give all three as one short block — the value, and one line
  on why it fits what the investigation established. Wait for the developer. Only then patch. These
  get counted in reports, so a wrong one is worse than a blank one.
- **If nothing in `allowedValues` genuinely fits, leave that field unset and say so** rather than
  forcing the nearest match.
- `Microsoft.VSTS.CMMI.RootCause` is a 255-char string and cannot hold prose. The narrative root cause
  still heads `Custom.Evidence`.

Then **re-read the item** — `wit_work_item` · `get` — and confirm every field landed and nothing else
moved. Report the rev change, the per-field character counts for the eleven, and the three dropdowns
as `before → after`. Update your held `rev` from the response.

## Step 7 — Status → **`Dev In Progress`**

The fix is written and the developer has confirmed it works (Step 5c), so the bug moves out of
`Under Investigation` and on to the next hand.

1. Reuse the `wit_work_item` · `get_type` response from Step 2a and read its `states[]`. Find
   `Dev In Progress` and use it verbatim. If the type does not offer it, **do not force the nearest
   match**: say which states it does offer and ask which one they want.
2. Say what you are about to do — *"the fix is confirmed, so I'll move #\<id\> from `Under
   Investigation` to `Dev In Progress`"* — and **confirm with the developer**.
3. Then `wit_work_item_write` · `update` with two operations in one call:

   ```
   { "op": "add", "path": "/fields/System.State",   "value": "Dev In Progress" }
   { "op": "add", "path": "/fields/System.History", "value": "<short note: what was done, by whom>" }
   ```

   A History note **is** what `System.History` is for — unlike RCA content, which never goes there.
4. Report the transition, `from → to`, from the response.

**Only a confirmed fix earns this transition.** If the developer's test failed, or they have not
tested yet, the bug stays in `Under Investigation` — that is what it is for. Say the status is
unchanged and why.

If the transition is rejected, the process template does not allow it from the current state. Report
that plainly and ask which state they want rather than trying alternatives at random.

## Step 8 — Done

Summarise in the chat:

- What was wrong, and the fix, in two lines
- Files changed, and whether they are committed (by default they are **not**)
- Where saved attachments landed, if any
- The RCA rev change
- The status transition
- **Anything still open** — an unproven version range, a defect found on other branches, a PR not
  raised, a question the developer still owes an answer to
- **Anything the investigation itself flagged as unresolved** — a `NOT ESTABLISHED` section, branches
  it did not sweep, a rejected hypothesis worth revisiting. Do not quietly drop these because the fix
  worked.

If something the developer did not ask about matters — the defect is live on eight other branches, the
RCA on the ticket is wrong, the checkout they are working in is stale — say it here plainly. That is
often the most valuable thing this run produces.
