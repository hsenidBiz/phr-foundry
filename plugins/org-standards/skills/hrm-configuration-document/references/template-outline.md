# Template Outline

One outline, three sizes. Sections always appear in this order; a section is included when its rule says so and omitted entirely otherwise (no empty headings, no "N/A" sections).

## Contents
- Choosing the tier
- Generated furniture (builder)
- Section catalogue (order, inclusion rule, content)
- Section wording patterns

## Choosing the tier

Decide from the facts, top rule first:

| Tier | Choose when the notes contain… | Typical length |
|---|---|---|
| **T3 Implementation guide** | multiple modes/variants, rollout or rollback steps, new error codes, acceptance gates, or 8+ settings | 25+ pages |
| **T2 Feature configuration doc** | UI procedure steps, a DB change, security/capability setup, settings that depend on each other, integration/file formats, or test results worth tabulating | 6–15 pages |
| **T1 Key card** | anything smaller: 1–3 independent settings, no DB change, no security setup | 2–3 pages |

Tell the developer: *"Tier T2 — two dependent settings, a capability requirement and a DB column."* Accept an override.

## Generated furniture (builder — never write in the .md)

- Cover: logo top-right; `Feature ID – <id>`, title, module, release (right-aligned, bold italic, brand blue); "Confidential | Internal".
- Page 2: "The version of this document is <doc_version>", hSenid copyright block, Table of Contents, List of Figures (when 2+ figures).
- Header: `Feature ID – <id> | <module>` over a blue rule. Footer: file base name, `Page X of Y`, classification.
- Heading numbers 1 / 1.1 / 1.1.1; `Change Control` and `Appendix …` unnumbered.

## Section catalogue

M = mandatory · C = include when condition true · — = omit.

| # | Heading (.md text) | T1 | T2 | T3 | Include when / content |
|---|---|---|---|---|---|
| 1 | `# Introduction` | M | M | M | Container. |
| 1.1 | `## Purpose` | M | M | M | 1–3 sentences: what this document configures, for which module and release. |
| 1.2 | `## Scope` | M | M | M | T1: one sentence. T2/T3: In scope / Out of scope table when the notes mention anything excluded or deferred. |
| 1.3 | `## Intended Audience` | — | C | M | T2 only when the audience is unusual (e.g. DBA, Cloud Team). |
| 1.4 | `## Definitions and Acronyms` | C | C | M | Terms, acronyms, table names the document uses. Definitions from the notes or the house glossary in `input-mapping.md`; otherwise ask the developer. |
| 2 | `# Feature Overview` | M | M | M | Problem before → behavior after (from notes), then `**Key features:**` bullets. T1: one short paragraph. |
| 3 | `# Prerequisites` | C | C | M | Minimum release, dependent module/feature, scripts that must be deployed, required licences/eligibility (only if stated). Table `Component \| What You Need`. |
| 4 | `# Configuration Parameters` | M | M | M | Summary table of every key (new and reused). |
| 4.x | `## Configuration Parameter: <Friendly Name>` | — | M | M | One `Item \| Specification` card per key. T1 has no cards: put "(existing key)" in the summary Description and, when the notes name an owner, a sentence "These keys are configured by <owner>." at the start of the Procedure. |
| 5 | `# Configuration Procedure` | M | M | M | Where and how to set each key: navigation path lines, numbered steps, figures (only supplied ones). |
| 5.x | `## <Country/Client/web.config> Configuration` | C | C | C | Variant-specific procedure. |
| 6 | `# Security and Access Setup` | — | C | C | Capability / Data Security / User / Eligibility group steps from the notes. |
| 7 | `# System Behavior` | C | M | M | Enabled vs disabled behavior; truth table when 2+ settings or conditions combine; user-facing messages quoted exactly. T1: include only when behavior isn't obvious from the key card. |
| 8 | `# Database Changes` | — | C | C | Table/column changes, script name and repository location, verification query if supplied. No DDL invented. |
| 9 | `# Integration and Data Formats` | — | C | C | File layouts, API/gateway parameters, mapping tables. |
| 10 | `# Validation and Test Cases` | — | C | M | From QA/dev test notes: `Test Case ID \| Configuration \| Steps / Action \| Expected Result`. IDs `TC-01…`. |
| 11 | `# Troubleshooting` | — | C | M | Known failure → `Symptom \| Likely Cause \| Resolution`. |
| 12 | `# Limitations` | C | C | M | Known issues, unsupported flows, deferred scope. |
| 13 | `# Deployment and Rollback` | — | — | M | Pre-deployment checklist, deployment steps, rollback, post-deployment verification. |
| 14 | `# Error Catalogue` | — | — | C | New error codes: `Code \| Condition \| Resolution \| Owner`. |
| 15 | `# Implementation Checklist` | — | — | M | `Step \| Action \| Owner` recap of everything above. |
| A | `# Appendix A - <Title>` | — | C | C | Long reference lists (field mappings, full key lists). |
| CC | `# Change Control` | M | M | M | Always last. |

## Section wording patterns

**Purpose** — "This document describes how to configure <feature> in the <Module> module of PeoplesHR <Release> (Version <x>). It is intended for implementation, support and system administration teams."

**Scope (T2/T3)**
| In Scope | Out of Scope |
|---|---|
| Enabling the upload control on the Qualification Maintenance page | Bulk upload of qualifications |

**Feature Overview** — "Previously, <old behavior>. With this change, <new behavior>." When the notes don't describe the old behavior, start with "With this change, …" (no question needed). Then **Key features:** bullets, each starting with a noun or verb phrase.

**Configuration Parameters summary** (T2/T3; keep cells short — details belong in the cards)
| Parameter Key | Data Type | Allowed Values | Default Value | Configuration Location | Description |
|---|---|---|---|---|---|

T1 summary (no cards):
| Parameter Key | Allowed Values | Default Value | Configuration Location | Description |
|---|---|---|---|---|

**Parameter card**
| Item | Specification |
|---|---|
| Parameter Name | `KEY` |
| Description | What it controls. |
| Storage | `HS_CLIENT_APPSETTING` / web.config / other (from notes) |
| Data Type | … |
| Allowed Values | `1` – …<br>`0` – … |
| Default Value | … |
| Dependencies | Only when the notes state one. |
| Configuration Responsibility | … |

Mark a reused key: add row `Key Status \| Existing key (reused by this feature)`.

**Configuration Procedure**
```
**Navigation Path:** **Utilities > Common Controls > Common Configurator**
**Configuration Tab:** **EIM**
**Search Parameter:** `EIM_QUAL_ATTACHMENT_ENABLE`

1. Log in to PeoplesHR as a user with access to the Common Configurator.
2. Navigate to **Utilities > Common Controls > Common Configurator**.
3. Select the **EIM** tab.
4. Search for `EIM_QUAL_ATTACHMENT_ENABLE`.
5. Set the value to `1` and click **Save**.
```
Every step one action. Use the exact on-screen labels the notes give; if the notes give no path, ask the developer for it before writing. Omit the **Configuration Tab** / **Search Parameter** lines the notes don't support. Unknown button label → neutral wording without bold ("Save the change."), not an invented label.

**Figures** go directly after the step they illustrate (configuration screens → Configuration Procedure; the resulting user-facing screen → System Behavior, creating that section if needed).

**System Behavior truth table** — when keys are long, use short column headers ("Enable", "Mandatory") and state which key each header means in the sentence above the table.
| `KEY_A` | `KEY_B` | Result |
|---|---|---|
| `0` | Any | The upload control is not displayed. |

**Change Control**
| Version | Date | Description | Author |
|---|---|---|---|
| 1.0.0 | 17/09/2026 | Initial document | Nimal Perera |
