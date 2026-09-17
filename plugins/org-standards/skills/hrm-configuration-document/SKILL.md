---
name: hrm-configuration-document
description: Use when a PeoplesHR/eHRM developer has finished a CR, feature or change request and needs the organization-standard Configuration Document (config doc, configuration guide, key card, implementation guide) — turning rough developer notes, a .md draft or a work item into the house .md and .docx, or reviewing or updating an existing configuration document before it goes to the SharePoint "Module's Configuration Docs" library.
---

# PeoplesHR Configuration Document

## Overview
A Configuration Document tells **implementation, support and client teams** how to configure and verify a delivered CR. The developer supplies rough `.md` notes; this skill produces `<Release>-<ID>-<Module>-<Title>-Doc.md` in the house structure and voice, then builds the branded `.docx` and PDF.

**Core principle: every fact in the document comes from the developer.** When a fact is missing from the notes, **ask the developer** before writing — never guess, never borrow it from another document, and never write `[TBD]` on your own. The document is written only after the questions are answered.

`[TBD - confirm with developer]` appears **only** where the developer explicitly answers "leave it TBD" (or "don't know yet — mark TBD") for that item.

**Where inference stops:**

| May be derived from the notes (no question needed) | Must come from the developer — ask if missing |
|---|---|
| The effect of a value, when a test result or sentence shows it ("enable=0 → no upload control") | Default values, data types, units (KB/MB), lengths |
| A dependency the notes state ("only works if ENABLE=1") and the truth-table rows it implies | Navigation paths or path segments, tab names |
| A value format shown by an example — labelled "Example:", never "Default" | Who configures it, which role logs in |
| A Troubleshooting row that restates a stated dependency or message | User-facing messages not quoted in the notes |
| Definitions from the house glossary in `references/input-mapping.md` | Behavior in combinations the notes don't cover; release version; author; acronyms |

If the developer already answered something in their request (screenshots, tier, author), use the answer — do not ask again.

## Workflow

1. **Ask about screenshots** — even when the developer says they are in a hurry. Ask exactly: *"Are there any screenshots for this feature?"*
   - **No** → the document has no figures, no image placeholders and no "screenshot to be added" text.
   - **Yes** → ask for the image files (paths) and one line saying what each shows. Open each image and confirm it matches its description; if it doesn't (blank, wrong screen), ask for a replacement. Insert only confirmed images, copied into an `images/` folder beside the .md.
2. **Read the notes** (and `assets/developer-input-template.md` if they used it).
3. **Extract facts** into a working list: work item/feature ID, release (+ version), module, title, author, each setting key (location, type, allowed values, default, owner), navigation path, security/capability setup, DB changes, behavior rules, test results, limitations, deployment steps.
4. **Pick the tier** (T1 / T2 / T3) with the rule in `references/template-outline.md`. The tier decides which sections — and therefore which facts — are required.
5. **Ask the developer for every missing required fact — one question at a time, before writing.**
   - First list the missing facts privately, ordered by section (Identity, Definitions, Parameters, Procedure, Security, Deployment…), and tell the developer how many questions are coming plus the tier and its one-line reason.
   - Ask each fact with a **separate AskUserQuestion call containing exactly one question**. Header shows progress (e.g. `Q3 of 10`). Give 2–4 options the developer can pick: the most likely answers drawn from the notes (mark the best-supported one "(Recommended)"), and always a **"TBD"** option ("Leave it TBD in the document"). The developer types their own value through the automatic "Other" choice — say so in the question when free input is the likely answer.
   - Never invent an option as fact; options are suggestions for the developer to confirm.
   - Wait for the answer before asking the next question. Use each answer to adjust or skip later questions; if an answer raises a new gap, add a question.
   - If you cannot talk to the developer in this run, stop and return the question list — do not write the document.
6. **Map facts to sections** using `references/input-mapping.md`. Drop code references (.cs/.cshtml/.js files, classes, methods, PR numbers, branches) and secrets (connection strings, passwords, tokens, internal IPs).
7. **Write the .md** by copying `assets/skeleton.md` and filling it — sections in skeleton order, headings unnumbered (the builder numbers them), voice and wording per `references/style-guide.md`. A row or section the developer said does not apply is removed, not marked TBD.
8. **Check**: `python scripts/check_doc.py <file.md>` (add `--no-screenshots` when the developer said none; add `--allow-tbd` only when the developer marked items TBD; add `--allow-internal-urls` only when the developer asked to keep an internal link) and fix every ERROR; then walk `references/quality-checklist.md`.
9. **Build**: `python scripts/build_docx.py <file.md>` → same-named `.docx`. (Needs `python -m pip install --user python-docx`.) On Windows with Word, run `powershell -ExecutionPolicy Bypass -File scripts/export_pdf.ps1 -Docx <file.docx>` for the SharePoint PDF. Open the PDF and look at it before handing back.
10. **Hand back**: file paths (.md, .docx, .pdf), the tier, **Removed from notes** (code references, secrets — advise rotating any exposed password), and — only if the developer chose TBD for something — the list of those TBD items. While `assets/house.json` has `"copyright_confirmed": false`, add: "The copyright block uses provisional wording — replace it in house.json with the official text."

Updating an existing document: keep the file name, bump `doc_version` (minor change 1.0.1 / new behavior 1.1.0), and append a Change Control row describing the change — never rewrite history rows.

**Worked example:** `examples/example-T2-developer-notes.md` shows typical incomplete notes; `examples/example-T2-questions.md` shows the question batch they require.

## Quick Reference

| Item | Rule |
|---|---|
| File name | `<Release>-<WorkItemID>-<Module>-<Short Title>-Doc` e.g. `26R1-116712-Employee Information-Hide Transport and Nominee Tabs-Doc` |
| Front matter | `feature_id, title, module, release, release_version, doc_version, tier` — all from the notes or the developer's answers |
| Cover, copyright, TOC, header/footer, numbering | Generated by the builder — never write them in the .md |
| Last section | `# Change Control` — `Version \| Date \| Description \| Author`, date DD/MM/YYYY |
| UI path | Bold, ` > ` separators, exactly as the developer gives it: `**Utilities > Common Controls > Common Configurator > EIM tab**` |
| Keys, tables, values | `` `EIM_QUAL_ATTACHMENT_ENABLE` `` exactly as the developer spelled it |
| Voice | Third person, present tense; procedures are numbered imperatives; no "we", "shall", "our" |
| Callouts | `> **Note:**` / `> **Important:**` / `> **Warning:**` / `> **Recommendation:**` |
| Figures | `![Figure 1: The Qualification Maintenance page with the upload control.](images/fig1.png)` |
| Missing fact | Ask the developer. `[TBD - confirm with developer]` (`[TBD]` in table cells) only when the developer replies TBD. |
| Module | One of the library's module names — AI Insights, Attendance, Beacon, EHRM, Employee Information, File Generator, Mobile Application, Report Navigator, Survey Tool, Widgets — or the name the developer confirms. Sub-areas (Request Tracker) go in the title. |
| Change Control date | The date the document is written (today), DD/MM/YYYY |

## Red Flags — stop and ask the developer

| Thought | Reality |
|---|---|
| "I'll put TBD and list it as an open item" | TBD is the developer's decision, not yours. Ask first. |
| "Too many questions will annoy the developer" | One quick pick-or-type question at a time is faster than a draft full of gaps. |
| "I'll bundle several questions in one prompt" | One question per AskUserQuestion call, with options plus TBD. |
| "The sample doc uses Menu > Common Controls > Common Configurator, so this key is there too" | Paths differ per module and client. Ask. |
| "A 1/0 flag obviously defaults to 0" / "it's clearly Integer" | Defaults and types live in the delta script. Ask. |
| "System Administrator configures everything" | Owner is a fact. Ask. |
| "I'll add a helpful definition / inferred side effect" | Inferences read as facts to a client. Ask or leave it out. |
| "The developer is in a hurry, don't ask about screenshots" | The screenshot question is always asked. It takes one line. |
| "I'll leave a screenshot placeholder just in case" | No screenshots → no placeholders. |
| "The code files help support" | Audience is implementation/support/client. Code references are removed. |
| "I'll number the headings in the .md" | The builder numbers them; hand numbers create "1. 1. Introduction". |
