# CLAUDE.md

Internal Claude Code **plugin marketplace** for PeoplesHR, hosted on GitHub.
One repo holds both the catalog and the plugins.

- Marketplace: `phr-foundry` · Owner: PeoplesHR <sanuja.a@peopleshr.com>
- Repo: `https://github.com/hsenidBiz/phr-foundry`

## Layout
- `.claude-plugin/marketplace.json` — catalog (lists plugins + relative-path sources).
  **Must stay at the repo root** so `claude plugin marketplace add <repo-url>` can find it.
- `plugins/dev-kit/` — the developer build-tooling plugin. **Skills only — declares no
  MCP servers.**
  - `.claude-plugin/plugin.json` — manifest. No `mcpServers` block at all.
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
  - These three moved here from `org-standards` in its `3.0.0` release. The skills are
    unchanged; only the invocation prefix changed (`/org-standards:` → `/dev-kit:`).
  - `hrm-notification` and `hrm-deployment-script` want a database; `phx-dbexplorer`
    now lives in `dba-kit`, so a developer installs `dev-kit` + `dba-kit` to get
    schema browsing.
  - Safe to install alongside `org-standards`, `dba-kit` or `ba-kit` — it ships no
    product-knowledge skill, so it has nothing to misroute against.
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
- `plugins/org-standards/` — the product-knowledge plugin
  - `.claude-plugin/plugin.json` — manifest. Also declares the `weknora` MCP server
    (see below).
  - `skills/phx-product-context/SKILL.md` — its own skill: before answering anything about
    how a PeoplesHR module behaves, retrieve the product documentation from WeKnora over
    the `weknora` MCP server (below) and cite it. Searches `Product Development` deep and
    `PeoplesHR Academy` shallow, and answers technically. Supporting file: `INSTALL.md`
    (the per-developer `WEKNORA_MCP_TOKEN`, which the plugin deliberately does not ship).
    The whole folder ships together; `SKILL.md` alone is not the skill.
  - MCP server `weknora` — read-only retrieval from the PeoplesHR WeKnora knowledge
    bases (`Product Development`, `PeoplesHR Academy`). Not vendored and not run
    locally: it is a `type: "http"` server hosted on the WeKnora VM at
    `https://weknora.phrsandbox.dev/mcp`, behind nginx. Each person must set
    `WEKNORA_MCP_TOKEN` in their own environment, which `plugin.json` expands into
    `Authorization: Bearer ${WEKNORA_MCP_TOKEN}`. **One shared token for the whole
    team** — distributed through the credential channel, never committed here (this
    repo is public). Read-only is enforced by the `retrieve`-only WeKnora API key on
    the server, *not* by the tool list, which advertises all 28 tools including writes.
- `plugins/ba-kit/` — the Business Analyst plugin
  - `.claude-plugin/plugin.json` — manifest. Declares the same `weknora` MCP server.
  - `skills/phx-business-context/SKILL.md` — its own skill: the BA counterpart of
    `phx-product-context`. Same two knowledge bases, opposite order (`PeoplesHR Academy`
    deep, `Product Development` shallow), and answers in business terms rather than code.
    Supporting file: `INSTALL.md`. The whole folder ships together.
  - **Never install `ba-kit` and `org-standards` in the same environment.**
    `phx-business-context` and `phx-product-context` compete on question wording and
    misroute. A BA takes `ba-kit`; a developer takes `org-standards`; anyone doing both
    jobs takes the developer skill, which keeps the business rationale as a secondary.
    This applies to that pair only — `dev-kit` and `dba-kit` ship no product-knowledge
    skill and are safe alongside either.
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
  - `ba-kit` — **Business Analysts only.** Same test, for BAs.
  - `org-standards` — **everyone.** Only things usable by *every* role regardless of
    job. If one role would never touch it, it does not belong here.
  - A new domain gets its **own** `plugins/<domain>/` plugin — never a corner of an
    existing one. See "New plugins" below.

  Decide by asking **who would ever invoke this**, not by which plugin already
  declares the supporting server. A developer-only skill belongs in `dev-kit` even
  when its MCP server is declared elsewhere, and a developer-only MCP server belongs
  in `dev-kit` even when a shared skill happens to call it. When a server is truly
  needed by two audiences — `weknora` today, used by `phx-product-context` in
  `org-standards` and `phx-business-context` in `ba-kit` — **each** plugin that needs
  it declares it. Identical duplicate declarations are the intended cost of keeping
  audiences clean; they resolve to one server at run time.

  **Known exception, deliberately grandfathered — do not "fix" it unprompted:**
  `phx-product-context` is developer-only but ships in `org-standards`. Moving it is a
  breaking change for installed users (a new slash-command prefix), so it happens only
  when someone asks for it explicitly. Until then, treat the rule as governing
  **additions**, and don't write docs that present the current placement as the
  intended design.

  `phx-sql-standards-review` and `phx-dbexplorer` were two further exceptions until
  `org-standards` `4.0.0`, when they were realigned into the new `dba-kit` plugin at
  the maintainer's explicit request.
- **Version lives in `plugin.json` only** (`dev-kit` is at `1.0.0`, `org-standards`
  at `4.0.0`, `ba-kit` at `1.0.0`, `dba-kit` at `1.0.0`). Bump the semver on every release — users only receive updates when it
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
  hooks. `org-standards` declares `weknora`; `ba-kit` declares `weknora`; `dba-kit`
  declares `phx-dbexplorer`; `dev-kit` declares none yet. Don't vendor an MCP server's source into this repo:
  `phx-dbexplorer` stays in its own repo and is fetched at run time via
  `npx github:...`, and `weknora` is a remote HTTP server on the WeKnora VM (see
  Layout above).
- **No credential may be committed** — this repo is public. `PHX_DB_CONNECTION_STRING`
  and `WEKNORA_MCP_TOKEN` are both read from the user's own environment via `${VAR}`
  expansion in `plugin.json`. Never inline a value, not even a placeholder that looks
  like one.
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
