# Developer Notes → Document Sections

| Found in the notes | Goes to | Treatment |
|---|---|---|
| Work item / feature / ticket ID | front matter `feature_id`, file name | Use as given. If the notes show two IDs (feature vs task), ask which is the Feature ID. |
| Release, version | front matter `release`, `release_version`; Purpose; Prerequisites | `26R1`, `10.3000.0`. |
| Module / repo / product area | front matter `module`, file name | Use the business module name the developer wrote (Employee Information, Attendance, Widgets…). Do not invent combined labels like "EHRM + X". |
| Title / CR name | front matter `title`, file name (shortened) | Rewrite into Title Case business wording; keep meaning. |
| Author | Change Control | If missing: ask. |
| Problem / why / before-after | Feature Overview | Rephrase in house voice. |
| What changed / capabilities | Feature Overview → Key features | Bullets. |
| Out of scope, later phase, not supported | Scope (Out of Scope), Limitations | |
| Terms, acronyms, table names | Definitions and Acronyms | Only terms used in the document. Definition from the notes or the house glossary below; any other term without a definition → ask. |
| Depends on release / module / script / license | Prerequisites | |
| Setting keys (app setting, web.config, table flag) | Configuration Parameters summary + card | Type, allowed values, default, location, owner — each from the notes or asked. |
| Reused/existing key | summary + card with `Key Status` row | |
| Menu path, tab, search text | Configuration Procedure | Exact; never from other documents. |
| Screenshots supplied in step 1 | Procedure / Behavior figures | Caption from the developer's one-line description. |
| Country / client / web.config variants | Procedure subsections | |
| Capability / data security / user / eligibility group needs | Security and Access Setup (+ Important callout in Procedure) | |
| "If A and B then…", dependencies between keys | System Behavior truth table; card `Dependencies` row | |
| Validation messages | System Behavior, Test Cases | Quoted exactly. |
| New/changed table, column, SQL script, dep.xml | Database Changes | Table, column, script name, repository. Do not write DDL that wasn't supplied. |
| File layouts, API, gateway, export mapping | Integration and Data Formats / Appendix | |
| QA results, test scenarios | Validation and Test Cases | Scenario → expected result. Drop "passed/failed" status unless asked. |
| Known issues, bugs not fixed | Limitations | |
| Error codes, log guidance | Troubleshooting / Error Catalogue | |
| Deploy/restart/cache clear/rollback steps | Deployment and Rollback (T3) or `> **Important:**` in Procedure (T1/T2) | |

## House glossary (may be used without the notes defining them)

| Term | Definition |
|---|---|
| SSHR | Self-Service HR portal of PeoplesHR. |
| ESS / MSS | Employee Self-Service / Manager Self-Service. |
| Common Configurator | The administration page where application settings (keys) are viewed and changed. |
| `HS_CLIENT_APPSETTING` | Table that stores application-wide configuration settings (keys and values). |
| Capability Group | A set of functional permissions assigned to users. |
| Data Security Group | A set of data-access rules that limits which employee records a user can see. |
| Eligibility Group | A rule-based group that decides which employees a feature applies to. |
| CR | Change Request. |

Include a Definitions and Acronyms section when the document uses any of these or other terms the notes define.

## Always removed (never appear in .md or .docx)
- Source file names: `.cs`, `.cshtml`, `.aspx`, `.js`, `.ts`, `.css`, `.config` file paths inside the repo, class and method names.
- PR numbers, branch names, commit hashes, ADO/Git/SharePoint URLs, repository internals (except the DB script repository/location).
- Secrets: connection strings, `Password=`, user IDs with passwords, API keys, tokens, internal IP addresses and server names used for testing.
- Developer chatter: "did the change", "works on my machine", TODOs, names of testers.

Mention removed secrets to the developer in the hand-back ("Your notes contained a database password; it was not included").

## Anything that fits nowhere
Do not drop it silently and do not force it into a section. List it in the hand-back under **Not included — please confirm**.
