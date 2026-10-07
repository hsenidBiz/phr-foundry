# CLAUDE.md

Internal Claude Code **plugin marketplace** for PeoplesHR, hosted on GitHub.
One repo holds both the catalog and the plugins.

- Marketplace: `phr-foundry` · Owner: PeoplesHR <sanuja.a@peopleshr.com>
- Repo: `https://github.com/hsenidBiz/phr-foundry`

## Layout
- `.claude-plugin/marketplace.json` — catalog (lists plugins + relative-path sources).
  **Must stay at the repo root** so `claude plugin marketplace add <repo-url>` can find it.
- `plugins/dev-kit/` — the developer plugin: build and design tooling.
  - `.claude-plugin/plugin.json` — manifest. Declares no MCP server.
  - `skills/hrm-deployment-script/SKILL.md` — its own skill: reformat SQL to PHR standard,
    **.NET Framework only**. Supporting files: `README.md` and `references/`
    (`deployment-rules.md`, `output-contract.md`, `reviewer-checklist.md`,
    `strict-sql-rules.md`). The whole folder ships together.
  - `skills/hrm-notification/SKILL.md` — its own skill: build an email notification for
    any module through the Job Scheduler (`HRM-JS45-SERVICE`) — the four views, the claim
    column, the `HS_HR_JS_TYPE` / `HS_HR_JS_MAIL_CONFIG` rows and the HTML template. A
    notification is **data, not code**; the skill writes no C#. Supporting files in
    `reference/` (`views-template.sql`, `config-template.sql`, `alert-template.html`),
    read by the skill itself. The whole folder ships together; `SKILL.md` alone is not
    the skill.
  - `skills/phx-debugger/SKILL.md` — its own skill: fix an Azure DevOps bug end to
    end from its bug ID. Supporting files: `INSTALL.md` (prerequisites the plugin
    deliberately does not ship — the `superpowers` plugin and a per-developer ADO
    MCP server) and `reference/` (`debugging-brief.md`, `rca-template.md`, both
    read by the subagents the skill spawns, not by the skill itself). The whole
    folder ships together; `SKILL.md` alone is not the skill.
  - `skills/hrm-configuration-document/SKILL.md` — its own skill: write the
    organization-standard Configuration Document for a finished CR from the developer's
    notes — the house `.md`, then a branded `.docx` and PDF. Asks the developer for every
    missing fact rather than guessing. Supporting files: `references/` (template outline,
    input mapping, style guide, quality checklist), `assets/` (skeleton, input template,
    `house.json` branding, logo), `examples/`, and `scripts/` (`check_doc.py`,
    `build_docx.py` — needs `python-docx` — and `export_pdf.ps1`, which needs Word on
    Windows). Ported from the personal skill `phr-configuration-document`, renamed for the
    `hrm-` prefix rule. The whole folder ships together; `SKILL.md` alone is not the skill.
  - `skills/phx-write-sdd/SKILL.md` — its own skill: author the **SDD — Architecture /
    Solution Design Document** (`ARCH-` prefix) for a feature. The template and the
    filled sample are **not vendored** — they are read live from the PHR-X project wiki
    (`/Manifesto/Document-Templates/Engineering/Solution-Design-Document-(SDD)` and its
    `Sample` child) on every run, through the developer's own ADO MCP server, so a change
    to the standard reaches everyone at once. A failed read is a hard stop; the skill
    never reconstructs the section list from memory. Its §5 resolves every cross-module
    touchpoint the linked FRD left open into a technical decision. Supporting file:
    `INSTALL.md` (the per-developer ADO MCP server, which the plugin deliberately does
    not ship — the same server `phx-debugger` needs). The whole folder ships together.
  - The first four moved here from `org-standards` in its `3.0.0` release. The skills
    are unchanged; only the invocation prefix changed (`/org-standards:` →
    `/dev-kit:`). `phx-write-sdd` is new in `dev-kit` `2.1.0`; its business companion
    `phx-write-frd` ships in `ba-kit`, because the FRD is the BA's document.
  - `phx-product-context` shipped here from `2.0.0` to `3.0.0`, when it was merged
    with `phx-business-context` and moved to `org-standards`, and the `weknora`
    declaration was dropped. A developer installs `dev-kit` + `org-standards`
    (+ `dba-kit`).
  - `hrm-notification` and `hrm-deployment-script` want a database; `phx-dbexplorer`
    now lives in `dba-kit`, so a developer installs `dev-kit` + `dba-kit` to get
    schema browsing.
  - Safe alongside every other plugin here.
- `plugins/dba-kit/` — the DBA / database-tooling plugin
  - `.claude-plugin/plugin.json` — manifest. Also declares the `phx-dbexplorer`
    MCP server (see below).
  - `skills/phx-sql-standards-review/` — its own skill: review-only (never edits SQL) against
    either the OLD hSenid HRM (.NET Framework) or NEW PeoplesHR PHR-X (.NET Core) SQL
    standard, auto-detecting which system a script targets. Supporting files:
    `reference/OLD_SQL_Standards.md` and `reference/NEW_SQL_Standards.md`, the full source
    standards documents read by the skill during review. The whole folder ships together;
    `SKILL.md` alone is not the skill.
  - MCP server `phx-dbexplorer` — schema-browsing tool for SQL Server/Postgres.
    Source lives in the separate public repo
    `https://github.com/hsenidBiz/phx-dbexplorer` (a .NET project, **not**
    vendored into this repo). `plugin.json`'s `mcpServers.phx-dbexplorer.command`
    runs it via `npx -y github:hsenidBiz/phx-dbexplorer`, which downloads the
    self-contained binary matching the developer's OS/arch from that repo's
    GitHub Releases on first use — no local .NET SDK/runtime, no npm registry
    publish step. Each developer must set `PHX_DB_TYPE` and
    `PHX_DB_CONNECTION_STRING` (and optionally `PHX_DB_SCHEMA_FILTER`) in their
    own shell environment before launching Claude Code — these are per-developer
    secrets and must never be committed to either repo.
  - Both moved here from `org-standards` in its `4.0.0` release. The skill is
    unchanged; only the invocation prefix changed (`/org-standards:` → `/dba-kit:`),
    and `phx-dbexplorer` re-registers under `dba-kit`.
  - Ships no product-knowledge skill, so it is safe alongside any other plugin here.
- `plugins/org-standards/` — the shared product-knowledge plugin, for **every role**
  - `.claude-plugin/plugin.json` — manifest. Declares no MCP server.
  - `skills/phx-product-context/SKILL.md` — its own skill: acquire grounded, cited
    PeoplesHR context before solution engineering (developers) or PRD / FRD writing
    and requirement elicitation (BAs). Searches the four WeKnora knowledge bases —
    `PeoplesHR Module Behaviour Brief`, `PeoplesHR Findings-Register`,
    `Product Development`, `PeoplesHR Academy` — one call per base in parallel,
    weighted by the task, then drills and follows identifiers across bases. Hands
    back a context brief: sources with statement/finding IDs, disagreements, known
    findings, gaps. No supporting files.
  - It uses the **weknora-peopleshr-product-knowledge** MCP server, which each person
    connects in their own Claude Code or Claude Desktop. **No plugin declares it** —
    don't add a declaration; its tool names carry a client-specific prefix, so the
    skill matches on the tool-name suffix (`list_knowledge_bases`,
    `search_knowledge`, `grep_chunks`, `list_documents`, `read_document`, `wiki_*`).
  - New in `org-standards` `6.0.0`: the developer `phx-product-context` (`dev-kit`)
    and the BA `phx-business-context` (`org-standards`) merged into this one skill,
    rewritten from scratch, at the maintainer's explicit request. The old `weknora`
    HTTP server declarations (`https://weknora.phrsandbox.dev/mcp`,
    `WEKNORA_MCP_TOKEN`) were removed from `dev-kit`, `org-standards` and `ba-kit`
    in the same change.
  - With one product-knowledge skill left, nothing misroutes: every plugin is safe
    alongside every other.
- `plugins/ba-kit/` — the Business Analyst tooling plugin
  - `.claude-plugin/plugin.json` — manifest. Declares no MCP server (the unused
    `weknora` declaration was removed in `3.0.0`).
  - `skills/phx-write-frd/SKILL.md` — its own skill: author the **FRD — Feature
    Requirements Document** (`FRD-` prefix) for a feature. Same shape as
    `phx-write-sdd` in `dev-kit`: the template and filled sample are **not vendored**,
    but read live from the PHR-X project wiki
    (`/Manifesto/Document-Templates/Engineering/Feature-Requirement-Document-(FRD)` and
    its `Sample` child) on every run through the BA's own ADO MCP server, and a failed
    read is a hard stop. Stays on the business side of the line — §9 records the
    business need for a cross-module touchpoint and leaves the mechanism to the SDD.
    Supporting file: `INSTALL.md` (the per-developer ADO MCP server, which the plugin
    deliberately does not ship). The whole folder ships together.
  - `ba-kit` was empty between `2.0.0`, when `phx-business-context` moved to
    `org-standards`, and `2.1.0`, which filled the reserved slot with `phx-write-frd`.
  - A BA installs **both** `org-standards` and `ba-kit`. Safe alongside every other
    plugin here.
- `.github/workflows/validate.yml` — runs `claude plugin validate .` on every PR into `main`
- `docs/` — Azure repo template dir, holds `docs/USAGE.md` (real content — see rule below).
  The other empty Azure template dirs (`deps/`, `scripts/`, `src/`) were removed since they
  held nothing but placeholder READMEs.

## Rules
- **Each plugin owns exactly one audience. Every skill and MCP server goes to the
  plugin whose audience it serves** — non-negotiable, and the first question to ask
  before adding anything:
  - `dev-kit` — **developers only.** Skills and MCP servers no other role would ever
    invoke.
  - `dba-kit` — **DBAs only.** Same test, for database work: SQL standards review and
    schema browsing.
  - `ba-kit` — **Business Analysts only.** Same test, for BAs: `phx-write-frd`, the
    FRD authoring skill.
  - `org-standards` — **every role.** Holds `phx-product-context`, which developers
    and BAs both use. Being the shared plugin does not make it a default: a skill
    goes here only when every role genuinely invokes it, decided case by case.
  - A new domain gets its **own** `plugins/<domain>/` plugin — never a corner of an
    existing one. See "New plugins" below.

  Decide by asking **who would ever invoke this**, not by which plugin already
  declares the supporting server. A developer-only skill belongs in `dev-kit` even
  when its MCP server is declared elsewhere, and a developer-only MCP server belongs
  in `dev-kit` even when a shared skill happens to call it. When a server is truly
  needed by two audiences, **each** plugin that needs it declares it. Identical
  duplicate declarations are the intended cost of keeping audiences clean; they
  resolve to one server at run time.

  **No grandfathered exceptions remain.** `phx-sql-standards-review` and
  `phx-dbexplorer` were realigned into `dba-kit` in `org-standards` `4.0.0`. The two
  product-knowledge skills were swapped in `org-standards` `5.0.0` / `dev-kit`
  `2.0.0`, then merged into one shared `phx-product-context` in `org-standards`
  `6.0.0` / `dev-kit` `3.0.0` — both at the maintainer's explicit request, because
  each changed slash-command prefixes for installed users.

- **Version lives in `plugin.json` only** (`dev-kit` is at `3.0.0`, `org-standards`
  at `6.0.0`, `ba-kit` at `3.0.0`, `dba-kit` at `1.0.0`). Bump the semver on every release — users only receive updates when it
  changes. Do NOT also set `version` in the
  marketplace entry; when both are set, `plugin.json` silently wins.
- **Skill names must start with `hrm-` or `phx-` and be kebab-case** — non-negotiable.
  The directory under `plugins/<plugin>/skills/` (which is also the skill's invocation
  name, e.g. `org-standards:hrm-my-skill`) must match `^(hrm|phx)-[a-z0-9]+(-[a-z0-9]+)*$`.
  Use `hrm-` for anything targeting the old .NET Framework HRM system, `phx-` for anything
  targeting PHR-X/.NET Core or general tooling. Enforced in CI by
  `.github/workflows/validate.yml`.
- **Every skill add/rename/remove, and every `plugin.json` version bump, must update all
  of the following in the same change** — non-negotiable. `claude plugin validate .` does
  not check doc coverage, so a missed update won't fail CI — only reviewer eyes catch it:
  - `docs/USAGE.md` — add/update/remove the skill's row in the Plugin catalog skill table,
    and its own `#### What \`<skill>\` does` walkthrough (invocation, inputs, output).
  - `README.md` (repo root) — the repository-layout tree, the "What's in `dev-kit`" /
    "What's in `dba-kit`" / "What's in `org-standards`" skills/MCP-server tables, and
    any invocation example listing skills by name.
  - the owning plugin's `README.md` (`plugins/dev-kit/README.md`,
    `plugins/dba-kit/README.md`, `plugins/org-standards/README.md` or
    `plugins/ba-kit/README.md`) — its Skills table and invocation-examples sentence.
  - `CLAUDE.md` (this file) — the `## Layout` bullet list under the owning plugin.
  - Any `version` mentioned in prose (e.g. "currently `X.Y.Z`") in `README.md`, this
    file, and the plugin's own `README.md` must match the new `plugin.json` version — these are
    plain text, not derived, so they silently rot independently of the version bump itself.
  - `.claude-plugin/marketplace.json` — the owning plugin's `description`, which lists its
    skills and MCP servers by name.
- New plugins: add a `plugins/<name>/` dir + a `marketplace.json` entry with
  `source: "./plugins/<name>"`, and a `version` in the plugin's `plugin.json`. State the
  plugin's **audience** in its `description` and in the first line of its `README.md` —
  a plugin whose audience you cannot name in one word is the wrong boundary.
- Skills, plus the MCP servers declared in each plugin's `plugin.json` — no agents or
  hooks. Only `dba-kit` declares one (`phx-dbexplorer`); `phx-product-context` relies
  on the weknora-peopleshr-product-knowledge server each person connects themselves.
  Don't vendor an MCP server's source into this repo: `phx-dbexplorer` stays in its
  own repo and is fetched at run time via `npx github:...`.
- **No credential may be committed** — this repo is public. `PHX_DB_CONNECTION_STRING`
  is read from the user's own environment via `${VAR}` expansion in `plugin.json`.
  Never inline a value, not even a placeholder that looks like one.
- **No third-party marketplace dependencies.** `org-standards` previously declared
  `dependencies` on `superpowers` (`superpowers-dev`) and 14 `.NET` skill plugins
  (`dotnet-agent-skills`) — removed in the `2.0.0` release (see git history). Claude Code
  only auto-resolves a cross-marketplace dependency if the user has already run
  `claude plugin marketplace add` for that dependency's marketplace, so it was never a true
  one-shot install — developers still had to run extra `marketplace add` commands
  themselves, which defeated the point of bundling them. Don't re-add cross-marketplace
  `dependencies` unless Claude Code changes to auto-register unknown marketplaces on
  install.

## Validate
```
claude plugin validate .
```
