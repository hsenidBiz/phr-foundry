# Style Guide

## Voice and tone
- **Audience:** implementation engineers, support, system administrators, client admins. Not developers.
- **Descriptive text** (purpose, overview, behavior, cards): formal, third person, present tense. "The system displays…", "This setting controls…".
- **Procedures and checklists:** numbered imperatives, one action per step. "Navigate to…", "Select…", "Click **Save**."
- **The system is the actor** in behavior text, the administrator/user in procedures.
- Do not use: "we", "our", "us", "I", "shall", "will be able to", "can be configured" (without saying how), "simply", "just", "obviously", emojis, exclamation marks.
- Prefer "is displayed / is hidden" over "shows up / disappears"; "select" over "choose/tick"; "enable/disable" over "turn on/off".
- Short sentences (≤ 25 words). One idea per sentence.
- US spelling: behavior, color, customize, license (noun and verb), canceled.

## Wording conventions

| Element | Format | Example |
|---|---|---|
| Navigation path | Bold, ` > ` separators, full path | **Utilities > Common Controls > Common Configurator > EIM tab** |
| Location labels | Bold label, then value | **Navigation Path:** / **Configuration Tab:** / **Search Parameter:** |
| Screens, tabs, fields, buttons, menu items | Bold, exact on-screen text | Click **Save**. The **Qualification Maintenance** page |
| Setting keys, table/column names, file names of scripts, values | Inline code, exact spelling (keep existing typos in real keys) | `HS_CLIENT_APPSETTING`, `1` |
| Key = value | Inline code | `EIM_QUAL_ATTACHMENT_ENABLE = 1` |
| System messages | Double quotes, exact text | "Please attach the qualification certificate" |
| web.config / SQL / XML | Fenced code block with language | ```` ```xml ```` |
| Release | `26R1 (Version 10.3000.0)`; mobile `Mobile Release 43 and above` |
| Security objects | Capability Group, Data Security Group, User Group, Eligibility Group (title case) |
| Owners | System Administrator, Implementation Team, DBA, Cloud Team, Support Team (only as stated in notes) |
| Dates | DD/MM/YYYY |
| Missing fact | Ask the developer. `[TBD - confirm with developer]` only when the developer replies TBD |
| Cross-reference | "See the System Behavior section." (no hard-coded section numbers — the builder numbers) |

## Callouts
One per blockquote, first word bold with colon:
- `> **Note:**` — helpful context (grey).
- `> **Important:**` — a dependency or condition that changes the outcome (amber).
- `> **Warning:**` — data loss, security exposure, production impact, irreversible action (red).
- `> **Recommendation:**` — suggested practice stated by the developer (teal).
Use at most one callout per subsection; do not wrap ordinary sentences in callouts.

## Tables
- Header row always present; header text in Title Case.
- Two-column cards (`Item | Specification`, `Term | Definition`) — first column is labels.
- Multi-line cell content: `<br>` between lines.
- A literal pipe inside a cell: `\|`.
- Never leave a cell empty — use `—` for not applicable; an unknown value is asked of the developer (`[TBD]` only if they choose it).

## Figures
- Only images the developer supplied. Store paths relative to the .md (e.g. `images/`).
- Syntax: `![Figure N: Sentence-case caption ending with a full stop.](images/file.png)` on its own line, directly after the step or paragraph it illustrates.
- Number figures 1, 2, 3… in document order.
- Refer to them in text: "as shown in Figure 2".
- If the developer says their images have red highlight boxes, keep them; do not describe annotations the image doesn't have.

## Markdown discipline (the .md is also a deliverable)
- Headings `#`, `##`, `###` only, no numbers, no bold inside headings, no trailing colons.
- No HTML except `<br>` in table cells and `<!-- pagebreak -->`.
- No links to internal repos, PRs, ADO URLs.
- No raw chat artifacts ("Sure! Here is…", "As an AI…").
