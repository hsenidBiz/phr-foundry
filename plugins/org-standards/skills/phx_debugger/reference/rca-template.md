# RCA template — the eleven fields, and where each one comes from

This is the PHR Root Cause Analysis format, mapped field by field onto the work item.

**You do not write this from memory.** Every field is assembled from the subagent returns defined in
`debugging-brief.md` — the investigator's twelve sections and the implementer's six. If a field has
no source in either return, that is a gap in the investigation, not something to fill in with
plausible prose: send it back (Step 3c) or mark it honestly.

All eleven are **HTML-typed**. Plain text with newlines renders as one run-on blob in Azure DevOps.
Write real HTML — `<b>`, `<br>`, `<ul><li>`, `<ol><li>`, `<pre>` for code. And **append, never
overwrite**: if a field already has content, splice yours in and keep theirs.

---

## 📝 `Custom.InitialFindings`

**Source:** investigator §4 (initial findings), §9 (impacted area), §10 (historical context).

What was observed, before it was understood — the reported symptom as it presented, not the
conclusion. Then:

1. **Summary of the issue** — a clear, high-level description of the defect from a developer's point
   of view.
2. **Impact assessment** — which modules, pages or features are affected; data-integrity risk; which
   client environments or versions.
3. **Historical context and traceability** — the earliest known version the defect exists in (say
   plainly if that is unverified), and related PR / Bug / Feature / Task IDs connected to this change.

The technical root cause does **not** go here. It heads `Custom.Evidence`.

## 🔍 `Custom.ToolsandTechniques`

**Source:** investigator §5.

What was actually used to find it — `search_code`, IL disassembly, `git log` / `repo_search_commits`,
log review, SQL Profiler, the schema explorer, reading a sibling module. Name the real ones; this
field is read by people deciding how to debug the next one.

## 💡 `Custom.Hypotheses`

**Source:** investigator §6.

Every hypothesis formed, each marked **confirmed** or **rejected**, and **what rejected it**. The
rejected ones are the point — they are what stops the next person walking the same dead end. A single
line saying only the answer is a wasted field.

## ⚙️ `Custom.AnalysisMethod`

**Source:** investigator §7, and §8 (working-example comparison).

The ordered steps by which the cause was confirmed, so somebody else could repeat them. Include the
Phase 2 comparison: the module that handles the same signal correctly, with `file:line`, and the
differences from the broken path.

## 🧩 `Custom.FixDescription`

**Source:** implementer §4 (fix description), §2 (what each change does), §5 (deviations).

Precisely what code and logic changed, and why that shape. If the implementation deviated from the
approved plan, say so here and say why. Use `<pre>` for the changed lines.

## 🔬 `Custom.Evidence`

**Source:** investigator §2 (root cause), §3 (evidence chain).

**This field opens with the root cause**, stated as a fact in one paragraph: the specific logic, code
block or environmental factor that caused the failure, with `file:line` and the quoted code. Include
the dependency evidence — assembly, method, IL offsets — when the behaviour was decided outside the
repository.

Then the evidence chain: the ordered `file:line` steps from where the bad value originates to where
the symptom appears, each one a fact that was read rather than assumed.

`Microsoft.VSTS.CMMI.RootCause` is a 255-character picklist string and cannot hold any of this. The
narrative root cause lives here.

## 🧪 `Custom.Testing`

**Source:** investigator §11 (how it should be tested), implementer §6 (how to verify), plus what the
developer actually confirmed at Step 5c.

The steps taken to verify the fix, numbered, and the regression cases that had to keep behaving.
Distinguish what was tested from what was only recommended — do not write "verified" for a build that
was never run or a case the developer did not confirm.

## 📊 `Custom.ImpactedArea`

**Source:** investigator §9.

The scope, in more detail than the Initial Findings summary: modules, screens, APIs and reports;
other call sites carrying the same defect (with `file:line`), stated explicitly as **not** fixed by
this change; and the branch sweep table if one was run — FIXED / AFFECTED / N/A per branch. Name
the branches that were not checked, and why, rather than implying coverage.

## 🚀 `Custom.DeploymentPlan`

**Source:** the branch and PR decisions taken at Step 5a, plus investigator §9.

Where this change has to go: the target branch, which release lines also need it (from the sweep),
whether a DB script or config change accompanies it, and anything that must happen in a particular
order. If the developer chose to ship only the one fix and leave sibling call sites, record that
decision here.

## ✅ `Custom.PreventiveActions`

**Source:** investigator §6 and §8 — what would have caught this earlier.

How a defect of this shape gets prevented next time: the missing test, the missing guard, the
contract that was never written down, the review check. Be specific enough to act on. "Better
testing" is not a preventive action.

## 📘 `Custom.LessonsLearned`

**Source:** the run as a whole.

What is worth knowing for next time — the sentinel value nobody documented, the module that already
solved this, the ticket field that was misleading. Written for a developer who has never seen this
code.

---

## 🏷️ The three classification dropdowns

Not prose — picklists, and they are what QA reports on. Read the allowed values from
`wit_work_item` · `get_type`; never type one from memory. Root Cause values are named
`<cause> - <Category>`, so decide the category first and pick a Root Cause whose suffix matches it.

| Field | Reference name |
|---|---|
| Root Cause Category | `Custom.RootCauseCategory` |
| Root Cause | `Microsoft.VSTS.CMMI.RootCause` |
| Bug Type Classification | `Custom.BugTypeClassification` |

Full rules — matching the suffix, respecting a value already on the ticket, what to do when nothing
fits — are in `SKILL.md`, Step 6.

---

## 🔃 Pull request description

**Used only when the developer asks for a PR** (Step 5a). This is not part of the work item's RCA
fields — do not write these headings into `Custom.*`.

```
📝 Description:
[High level summary of the PR]

🧪 Testing:
[Steps taken to test and verify the fix]

📊 Impact:
🔴 Before Fix:  [What was broken]
✅ After Fix:   [How it behaves now]

✅ Preventive Methods:
[How to prevent this in the future]

📘 Lessons Learned:
[Key takeaways from this bug]
```

Draw it from the same returns: Description from implementer §4, Testing from `Custom.Testing`,
Before/After from investigator §2 and implementer §2, and the last two from
`Custom.PreventiveActions` and `Custom.LessonsLearned`.
