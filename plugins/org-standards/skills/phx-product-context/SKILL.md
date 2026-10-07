---
name: phx-product-context
description: Retrieve PeoplesHR product knowledge from WeKnora before reasoning about a PeoplesHR module. Use when doing solution engineering (designing a feature, writing an SDD, impact analysis, planning a change), when writing a PRD or FRD or eliciting requirements, or whenever the work turns on how a PeoplesHR module actually behaves — its rules, data, configuration, integrations or known gaps.
---

# PeoplesHR product context

Acquire the product context a piece of PeoplesHR work needs, from the four WeKnora
knowledge bases, before you design, specify or answer. The output is **grounded
context with citations**; what you do with it is the surrounding task's business.

## The server

Retrieval runs through the **weknora-peopleshr-product-knowledge** MCP server, which
each person connects in Claude Code or Claude Desktop themselves — this plugin does
not declare it. Its tool names carry a client-specific prefix; match on the suffix:

| Tool | Use it for |
| --- | --- |
| `list_knowledge_bases` | Ids, names and capabilities (`semantic`, `keyword`, `wiki`) of every KB in scope. |
| `list_documents` | The documents in one KB, with a summary each; `keyword` filters titles. |
| `search_knowledge` | Ranked passages. `mode`: `hybrid` (default), `semantic`, `keyword`. Restrict with `knowledge_base_ids`; `limit` ≤ 30. |
| `grep_chunks` | Regex over chunk text — exact identifiers: table and column names, statement and finding IDs, work item numbers, setting codes. |
| `read_document` | A document's chunks in order. Pass `query` to get only the chunks holding a phrase (with one chunk of context each side); page with `offset`/`limit`. |
| `wiki_index`, `wiki_search`, `wiki_read_page` | Only for a KB whose capabilities include `wiki`. |

If none of these tools exist in the session, stop and tell the user the
weknora-peopleshr-product-knowledge server is not connected. Never substitute
general knowledge for PeoplesHR behaviour.

The server is retrieval-only. Every call here reads.

## The four knowledge bases

Pass KB names exactly as written — the tools accept a name or an id.

| KB | Holds | Reach for it when |
| --- | --- | --- |
| `PeoplesHR Module Behaviour Brief` | One analysed brief per module (`KS-ANL-<Module>-Behaviour-Brief-v<n>.md`), derived from reading the code and database: how the module **actually** behaves — rules, states, edge cases, data ownership, integrations, variation points. | You need the as-built truth. The most authoritative source on current behaviour, when one exists for the module. |
| `PeoplesHR Findings-Register` | One register per module (`KS-ANL-<Module>-Findings-Register-v<n>.md`): gaps, inconsistencies, open questions and defects found while writing the brief. | You need the pitfalls: what is broken, inconsistent or undecided in the area you are about to change or specify. |
| `Product Development` | PRDs, requirement docs, solution and technical blueprints, configuration docs, and release test-case suites. | You need prior design intent, existing technical design, schemas, SQL, or how a feature was specified and tested. |
| `PeoplesHR Academy` | End-user training: module overviews, user guides, configuration guides, release notes. No implementation. | You need what the user sees and does, the business process, and how a module is configured. |

### Reading the Brief and the Register

- **Statement IDs** — `MBB-<MOD>-BEH-nnn` (behaviour), `-DAT-` (data ownership),
  `-INT-` (integration), `-VAR-` (variation point). **Finding IDs** —
  `MBB-<MOD>-FND-nnn`. `<MOD>` is a three-letter module code (`ABS`, `ATT`, `PAY`, …).
  Cite by ID. To **read** an ID, call `read_document(<brief or register id>,
  query=<ID>)` — it lands on the defining chunk. `grep_chunks` on an ID finds the
  places that *mention* it and often misses the definition itself.
- **Publication state** travels with every statement: `Verified`,
  `Unverified (Derived)`, `Disputed`, `Retired`. A `critical-uncorroborated` flag marks
  monetary or statutory behaviour that rests on code reading alone. Carry the state
  into your context; treat `Retired` as no longer true.
- **Citations** — Form A points at repository / file / line range / commit; Form B at
  a database object with a definition hash and read date. Form B reflects one
  instance and can differ between tenants.
- A brief often states behaviour for **two applications** over one database (legacy
  Web Forms and MVC). Keep the distinction; say which one a statement covers.
- Findings are **observations, not defects**, and most are untriaged. The Register is
  restricted (Deny Read for Delivery and Support) and includes security findings.
  When the work ends in a document for wide circulation — a PRD, an FRD, a wiki page,
  anything client-facing — reference the finding ID and the business consequence, and
  leave the security mechanics in the Register.

## Step 1 — Frame

Name the module(s), the feature, and the questions the work actually turns on. Turn
each question into a **query**: the user's words translated into product vocabulary,
plus any identifier you already hold (screen name, table, setting code, work item
number). "why does this get rejected" is not a query; "leave application rejected
overlapping date range validation" is.

Pick the **lens** from the task:

- **Solution engineering** — design, SDD, impact analysis, a code change: lead with
  the Brief and `Product Development`; the Register for pitfalls; Academy to confirm
  the user-facing effect.
- **Requirements** — PRD, FRD, elicitation, a client question: lead with Academy and
  the Brief; the Register for gaps and open questions to raise; `Product Development`
  for prior PRDs and requirement docs.

Done when every question has a query and the lens is chosen.

## Step 2 — Map what exists

On the first run in a session, call `list_knowledge_bases`. Then
`list_documents` on `PeoplesHR Module Behaviour Brief` and on
`PeoplesHR Findings-Register` — both are small — and note whether your module has a
brief and a register, which version, and their document ids. Coverage grows over
time; read it fresh rather than assuming.

Done when you know, per module in play, whether a brief and a register exist.

## Step 3 — Retrieve, one call per KB, in parallel

Search each KB **separately**, all four calls in one message. A single unrestricted
search lets `Product Development`'s large test-case suites crowd the other three out.

| Lens | Brief | Register | Product Development | Academy |
| --- | --- | --- | --- | --- |
| Solution engineering | 10 | 6 | 10 | 4 |
| Requirements | 8 | 6 | 6 | 10 |

The numbers are `limit`s. Use `search_knowledge` with `knowledge_base_ids` set to the
one KB. Where the module has a brief, `read_document(<brief id>, query=<phrase>)` is
often sharper than searching the KB. For a table, column, setting or screen name, use
`grep_chunks` or `mode: "keyword"`; for a fuzzy concept, `hybrid` or `semantic`. Run several questions'
calls in the same message too.

## Step 4 — Drill and follow the trail

Search results are passages. For each strong hit, read around it with
`read_document(knowledge_id, query=<phrase>)` rather than paging the whole document —
briefs and registers run to over a thousand chunks. Make the phrase **distinctive**:
a statement or finding ID, a column name, an exact heading. A common phrase matches
everywhere and every match comes back with its neighbours.

Follow the trail the hits lay down, across KBs:

- A statement names a table, procedure or setting → `grep_chunks` that name across all
  four KBs to find the design doc, the related findings and the user guide.
- A finding cites a statement ID → read the statement; a statement's area → search the
  Register for findings on it.
- A PRD or blueprint names a work item → `grep_chunks` the number for its test cases.

If a KB returns nothing on-target, retry **once** with reworded vocabulary or a
different `mode`. Then accept the gap.

Done when every question from Step 1 has either a cited answer or a recorded gap, and
the last round of follow-ups returned nothing new.

## Step 5 — Hand back the context

Give the surrounding task a compact **context brief**, per question:

- **What the sources say**, attributed: KB, document title, and statement or finding
  ID where there is one, with its publication state.
- **Where sources disagree** — typically the Brief (as built) against Academy or a PRD
  (as intended). State both sides and leave it unresolved: for solution engineering it
  is a risk to design around; for requirements it is a question to put to the
  stakeholder.
- **Known findings** in the area, by ID and consequence.
- **Gaps** — what no KB documents. From here on, behaviour in a gap is unknown: say so
  in the work, and ask, rather than filling it with general HRM knowledge.

Then continue the task the skill was loaded for, using the brief as its grounding.

## Skip it

When the work holds no PeoplesHR behaviour — formatting, renaming, a generic language
or framework question, rewriting the user's own text — skip retrieval and carry on
without announcing it.
