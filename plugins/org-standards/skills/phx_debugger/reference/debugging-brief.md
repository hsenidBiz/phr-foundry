# The debugging brief

**Read this if you were spawned by `phx_debugger`.** It is the standing brief for both of its
subagents — the **investigator** (Phases 1–3) and the **implementer** (Phase 4). Your spawn prompt
says which one you are and carries the bug context; this file says how the work is done and what you
must return.

`phx_debugger` itself does not debug. It talks to Azure DevOps, gates the developer's decisions, and
formats the RCA. **Finding the root cause and fixing it are yours.** Do not hand back a half-answer
expecting the parent to finish it — it will not, and cannot.

---

## First: run the superpower

**Invoke `superpowers:systematic-debugging` before you read a single line of source.** Everything
below is how its phases land on a PeoplesHR Azure DevOps bug; it is not a substitute for the skill
itself. If that skill is unavailable to you, stop and say so — do not improvise an investigation.

### The Iron Law

```
NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST
```

You may not propose a fix — not in your return, not in passing, not as "it's probably X" — until
Phase 1 is complete. Seeing the symptom is not understanding the cause.

### How the four phases land on an Azure DevOps bug

| Phase | What it means here |
|---|---|
| **1 · Root cause investigation** | Read the error *exactly* — the attached log line, the stack trace, the message template, all of which are in your context packet. Establish how it reproduces. Check recent changes to the failing path with `repo_search_commits`. Trace the data flow backwards to where the bad value originates, using `root-cause-tracing.md` in the superpower's own directory. |
| **2 · Pattern analysis** | Find working examples **in the same product** — another module that handles the same signal correctly. Read its branch completely, not skimmed. List every difference between working and broken, however small. |
| **3 · Hypothesis and testing** | State one hypothesis: *"X is the root cause because Y."* Test it minimally, one variable. Confirmed → return. Not confirmed → new hypothesis, never a second fix stacked on the first. |
| **4 · Implementation** | The **implementer's** job, and only after the developer has approved the plan. If you are the investigator, you stop at the end of Phase 3. |

### Red flags — stop and return to Phase 1

If you catch yourself thinking any of these, you have left the process:

- "Quick fix for now, investigate later"
- "It's probably X, let me fix that"
- "I don't fully understand but this might work"
- Listing fixes before tracing the data flow
- Proposing a second fix on top of a first that did not work

Three failed fixes is not a fourth hypothesis — it is a signal the architecture is wrong. Say so in
your return rather than trying a fourth.

---

## The rules you inherit

These are `phx_debugger`'s and they bind you exactly as they bind it.

**1 · Azure DevOps only through the MCP server.** No `az` / `az devops` CLI, no `curl` or
`Invoke-RestMethod` against `dev.azure.com`, no personal access token from any source, and no script
of your own to stand in for a missing tool. If a tool you need is not exposed, stop and say so.
Local `git` in the working tree is not an ADO call and is expected.

**2 · Work items are fetched by ID, never found by content.** `wit_work_item` · `get` /
`get_batch` with a numeric ID only. No `search_workitem`, no WIQL, no searching by title, text, tag,
area or assignee. The IDs you may fetch are those in your context packet and any you read from a
`relations[]` link on an item you already hold. **This does not restrict `search_code`** — finding
*code* by its content is required below. The distinction is the object, not the verb.

**3 · You do not write to Azure DevOps.** No comments, no field updates, no state changes, no pull
requests, no server-side branches. Every ADO write in this procedure belongs to the parent, behind a
developer gate. You read.

**4 · Ask rather than guess — but exhaust the evidence first.** You cannot talk to the developer
directly; put questions in your return and the parent will put them. Before you do, confirm you have
read every relevant file end to end, followed the call chain to where behaviour is actually decided,
opened the binary when the logic lives in a dependency, checked how sibling modules handle the same
signal, and re-read the attachment findings in your packet. A question is right when the answer
**cannot** be found in the code. It is wrong when it stands in for work you did not do.

**5 · Verify before you claim.** Every factual statement must come from a file you read or a command
you ran. No recalled behaviour, no inference presented as fact. If you would write *"probably"*,
*"presumably"*, *"should be"* or *"I assume"* in a finding, it is not a finding yet.

**6 · An RCA already on the ticket is a claim, not a fact.** Prior RCAs are frequently written
against a different repo or a stale snapshot. Confirm each assertion against source; if it does not
hold, say so plainly in your return and give the corrected version.

---

## Investigator: the source work

### Find the true repository

The working directory is where you are, which is not automatically where the bug is: local clones go
stale and the same repo name often exists in several projects.

1. Pull distinctive identifiers from the bug — a type name, a setting key, an error string, a method
   — and `search_code` them across the org. Leave `project` unset so the search is org-wide, and
   **raise `top`**; the default of 5 is far too small to conclude anything from. A false "zero hits"
   sends you down the *logic is not in this repository* path for no reason.
2. Check the local checkout with `git rev-parse --abbrev-ref HEAD`, `git log -1`, `git remote -v`.

If the checkout disagrees with the search results, **say so in your return and stop** rather than
investigating the wrong tree. The parent puts it to the developer — you do not carry on in the hope
that it was close enough. A symbol named in the bug that does not exist in the working directory
means the developer has Claude Code open on the wrong repository, or on a stale clone — never "the
bug report is wrong". Name the repository the evidence points at.

### Read the code

Trace the failing path end to end, from where the value originates to where it is consumed. Quote
real `file:line`. Establishing "since when" requires reading the oldest branch that still has the
code — if you state a version range, prove it; if you cannot, say it is unverified rather than
repeating a claim from the ticket.

### Sweep the branches

Once you know what the fix *is*, sweep for a marker present only when the fix is applied. This
routinely shows the defect live on release lines nobody has filed a bug against.

The MCP server has no bulk sweep, so it is N calls:

1. `repo_branch` · `list` for the repository.
2. Per branch, `repo_file` · `get_content` with `version: "<branch>"` and **`versionType: "Branch"`**
   — the parameter defaults to `Commit` and a branch name will not resolve without it.
3. Classify: marker present → **FIXED**, file present without it → **AFFECTED**, file missing →
   **N/A** (usually the branch predates the code, not a failure).
4. Return the counts and the per-branch table.

On a 20-branch repo that is 21 calls, so **the depth is your call**: sweep the branches that
plausibly ship the code, and skip the ones that plainly cannot. What is not negotiable is saying so
— name the branches you checked and the ones you did not, with the reason, in §9 of your return.
**Never silently sweep a subset and present it as complete.** The same judgement applies to the
repository hunt above and to how wide you search: decide from the evidence, then report the decision.

### When the logic is not in this repository

Frequently the behaviour that decides the bug lives in a NuGet package or a shared DLL whose source
is not in Azure DevOps. **A search returning zero hits org-wide is a finding, not a dead end** — it
tells you the logic is compiled, and the compiled form is still readable.

1. **Locate the assembly** the branch actually links against — `deps\`, `packages\`, `bin\`, or the
   `.csproj` reference. Version matters: read the one this branch uses, not the newest.
2. **Strings first, cheapest.** Message literals, fail-reason comments and format templates are in
   the binary and often name the exact scenario in plain English.
3. **Disassemble the IL** for the method on the failing path — `ildasm`, `monodis`, `dotnet-ildasm`,
   or ILSpy if installed. Read what it actually returns on each branch.
4. **Report what each return path sets**, with offsets, so the claim is checkable. A sentinel like
   `Status = false, Id = "-1", Message = null`, distinguished from real failures that populate
   `Message`, is exactly the kind of fact that turns a guess into a root cause.
5. **Cross-check against a sibling module.** If another module in the same product already handles
   that signal, read its branch — the contract is established, and its absence here is the defect.

State the finding definitively once you have it. *"The engine returns `-1` with no message when no
approval level applies, at IL offsets 644/1613/2818"* is a root cause. *"It may be a configuration
issue"* is not.

**If you cannot establish the cause at all** — the code is unreachable, the behaviour depends on data
or a component you cannot see — return `rootCauseEstablished: false` with exactly what you
investigated and what specifically would settle it. The parent puts that to the developer first —
who may well know the answer and send it straight back to you — and only turns it into a comment on
the ticket if they cannot answer. Either way, be specific: a vague "needs more info" is useless to
both.

---

## Implementer: the fix

You are spawned only after the developer approved the plan, and you carry that approved plan.

❄️ **This is `systematic-debugging` Phase 4.** Its rules are not negotiable:

- **One fix, addressing the root cause** — not the symptom, not a guard that hides it.
- **No "while I'm here" improvements** and no bundled refactoring. They make it impossible to tell
  what actually fixed the bug.
- **If the fix does not work, return to Phase 1** with the new information. Do not stack a second fix
  on the first. After three failed attempts, stop and say the design is in question.
- **Implement the approved plan.** If the code turns out to contradict it, stop and return that —
  do not quietly implement something else the developer has not seen.

**Edit byte-precisely.** The diff must contain only the intended lines. After every edit run
`git diff` and confirm the change count matches your intent. If unrelated lines appear:

1. `git checkout -- <file>` to revert.
2. Re-apply with an exact-substring replacement that preserves the file's bytes.
3. **Preserve the BOM** — `UTF8Encoding.GetBytes()` does not emit the preamble; prepend
   `0xEF,0xBB,0xBF` yourself if the file had one.
4. Re-check `git diff`.

**Build** the affected project and report the result, distinguishing new warnings from pre-existing
ones. If you cannot build — no toolchain, a project that does not build standalone, a solution that
needs credentials you do not have — say so explicitly and return the build as *not run*. Never let a
build that did not happen read as verification that did.

**Do not branch, commit, push or open a pull request.** Those are the parent's, each behind the
developer's explicit approval. Leave your changes in the working tree.

---

## What you must return

Your final message **is** the return value — the parent parses it, the developer never sees it
directly. No preamble, no "I hope this helps". Return exactly these sections, and mark any you
genuinely cannot fill as `NOT ESTABLISHED` with the reason rather than omitting it or filling it
with plausible prose. **Sections 2–11 are the raw material for the RCA** the parent writes onto the
work item — `rca-template.md` maps each one to a field — so a thin answer anywhere in that range
becomes a thin RCA.

### Investigator return

1. **`rootCauseEstablished`** — `true` or `false`.
2. **Root cause** — one paragraph, definitive, with `file:line` and the quoted code. Include the
   dependency evidence (assembly, method, IL offsets) if the behaviour was decided outside the repo.
3. **Evidence chain** — the ordered `file:line` steps from where the bad value originates to where
   the symptom appears. Each step a fact you read, not a step you assume.
4. **Initial findings** — what you observed first, before you understood it, and a developer-level
   summary of the defect.
5. **Tools and techniques** — what you actually used: `search_code`, IL disassembly, `git log`,
   `repo_search_commits`, log review, the dbexplorer, reading a sibling module.
6. **Hypotheses** — each one you formed, and for each: confirmed or rejected, **and what rejected
   it**. The rejected ones matter; they are what stops the next person repeating your dead ends.
7. **Analysis method** — the ordered steps by which you confirmed the cause, so someone else could
   repeat them.
8. **Working-example comparison** (Phase 2) — the module that handles the same signal correctly,
   with `file:line`, and every difference from the broken path.
9. **Impacted area** — modules, screens, APIs, reports affected; data-integrity risk; which client
   environments or versions. Plus the branch sweep table — and, whether you swept or not, exactly
   which branches you checked, which you did not, and why.
10. **Historical context** — earliest version the defect exists in (proved, or stated as unverified),
    the commit that introduced it if you found it, and related bug/PR/task IDs you encountered.
11. **Proposed fix** — the exact change per file; why this shape and what else you considered; the
    risk and what could regress; the blast radius outside this ticket (other call sites with the
    same defect, listed with `file:line`, explicitly **not** in this change); and how it should be
    tested, numbered, including the regression cases that must still behave.
12. **Open questions** — only those that genuinely cannot be answered from the code, each with the
    options you see and which you would choose. The parent puts these to the developer.

### Implementer return

1. **Files changed**, with the full `git diff`.
2. **What each change does**, and the confirmation that the diff contains only intended lines.
3. **Build result** — succeeded or failed, with new warnings separated from pre-existing ones, or an
   explicit statement that you could not build.
4. **Fix description** — a precise account of the code and logic changed, for the RCA.
5. **Deviations** — anything in the approved plan you did not do, or did differently, and why.
6. **How to verify it** — what the developer should test to confirm the fix.
