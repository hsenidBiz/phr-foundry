# Using PHR-Foundry plugins

A short, practical guide for engineers. If you only want to *use* the plugins,
this page is all you need — the [root README](../README.md) covers maintaining
the marketplace itself.

> **Keep this page current.** When a plugin or skill is added, renamed, or
> removed, update the [Plugin catalog](#plugin-catalog) below in the same PR.

Repo layout note: the empty Azure template dirs `deps/`, `scripts/`, and `src/`
have been removed from the repo — they held nothing but placeholder READMEs.
`docs/` (this guide) is the only one that remains, since it holds real content.
See the [root README](../README.md#repository-layout) for the current layout.

---

## 1. Install

You need this once per machine. Point Claude Code at the repo URL — no clone
required.

```shell
claude plugin marketplace add https://github.com/hsenidBiz/phr-foundry
claude plugin install org-standards@phr-foundry
```

The same commands work as slash commands inside a Claude Code session
(`/plugin marketplace add ...`, `/plugin install ...`).

`org-standards` also depends on 15 curated third-party skill plugins (see the
[Plugin catalog](#plugin-catalog) below), which install automatically alongside it. If any
show up as missing after install, their upstream marketplace probably isn't registered on
your machine yet — add it and reinstall:

```shell
claude plugin marketplace add https://github.com/obra/superpowers
claude plugin marketplace add https://github.com/dotnet/skills
claude plugin install org-standards@phr-foundry
```

**If the first command hangs or fails on authentication**, your machine has no
cached GitHub credentials. Use the URL with the account prefix so Git knows
which account to prompt for:

```shell
claude plugin marketplace add https://hsenidBiz@github.com/hsenidBiz/phr-foundry
```

### Make it automatic for a whole project

Add this to the project's `.claude/settings.json` and commit it. Anyone who
trusts the project gets the marketplace offered and the plugin enabled — no
manual install step.

```json
{
  "extraKnownMarketplaces": {
    "phr-foundry": {
      "source": {
        "source": "git",
        "url": "https://github.com/hsenidBiz/phr-foundry"
      }
    }
  },
  "enabledPlugins": {
    "org-standards@phr-foundry": true
  }
}
```

## 2. Check what you have

```shell
claude plugin list                  # installed plugins and versions
claude plugin marketplace list      # marketplaces Claude Code knows about
```

## 3. Update

```shell
claude plugin marketplace update phr-foundry
claude plugin update org-standards
```

You will **only** receive a new version when the maintainer bumps `version` in
the plugin's `plugin.json`. New commits alone do not reach you — if you expect a
change and don't see it, ask the maintainer whether the semver was bumped.

## 4. Uninstall

```shell
claude plugin uninstall org-standards
```

---

## Plugin catalog

### `org-standards` — PeoplesHR organization standards

| Skill | Use it for |
| --- | --- |
| `hrm_sql_standards` | Creating, converting, and PR-reviewing re-runnable **HRM-DB MSSQL deployment scripts** and their `dep.xml` registration. |

`org-standards` also pulls in these third-party plugins as dependencies, so they're
available as soon as `org-standards` is installed — no separate install step. They track
their upstream marketplace directly, so you get updates whenever the upstream maintainer
ships one; PHR-Foundry doesn't vendor or re-host their content.

| Plugin | Source | Use it for |
| --- | --- | --- |
| `superpowers` | [obra/superpowers](https://github.com/obra/superpowers) | TDD, systematic debugging, brainstorming, and code-review/collaboration workflow skills. |
| `dotnet`, `dotnet-advanced`, `dotnet-data`, `dotnet-diag`, `dotnet-nuget`, `dotnet-upgrade`, `dotnet-maui`, `dotnet-ai`, `dotnet-template-engine`, `dotnet-test`, `dotnet-test-migration`, `dotnet-aspnetcore`, `dotnet-blazor`, `dotnet11` | [dotnet/skills](https://github.com/dotnet/skills) | General .NET/C# development, testing, upgrades, ASP.NET Core, Blazor, MAUI, and package-management skills. |

#### What `hrm_sql_standards` does

Given SQL you supply, it packages that SQL as a deployment file under
`src/PeoplesHR/Current/<MODULE>/`, wraps it in re-runnable guards, adds
traceability banners, registers the new root script in `dep.xml`, and generates
localization files when you ask for them.

**It never rewrites your SQL.** No optimization, no normalization, no
reformatting — your statements are copied through byte-for-byte and only
deployment scaffolding is added around them. If a required safety guard can't be
applied without changing your SQL, it stops and asks you for corrected source.

#### How to invoke it

Explicitly:

```
/org-standards:hrm_sql_standards
```

Or just describe the work — Claude loads the skill on its own when you're
creating, converting, or reviewing HRM-DB deployment SQL.

#### What it needs from you

Mandatory for creating or converting a script:

- The **complete source SQL** (it will not invent business SQL from a prose
  description)
- User name
- Feature ID
- Task ID
- Module / folder
- Work-item type — one of `CR`, `CRB`, `RM`, `QRB`

Additionally, if your SQL inserts into or updates `HS_FORM_LABEL_MAP`, say
whether other languages are required and list them.

You don't have to supply all of this up front. Paste the SQL and the skill will
ask once for everything missing, then proceed straight to the work — there's no
extra confirmation step after that.

#### Copy-paste template

````text
Use /org-standards:hrm_sql_standards to create an HRM-DB deployment script.

User name:
Feature ID:
Task ID:
Module/folder:
Work-item type: CR | CRB | RM | QRB

For HS_FORM_LABEL_MAP inserts or updates:
Are other languages required? No | Yes
Required languages/regions: <complete only when Yes>

SQL:
```sql
<paste the complete SQL here>
```
````

#### Review-only mode

Say so explicitly — e.g. *"review these deployment files for PR readiness"* —
and it checks filenames and indexes, guards, banners, source-SQL preservation,
localization shape, and `dep.xml` placement without creating anything.

#### What you get back

A report covering: the metadata used, the index it detected, the file it created
and its `dep.xml` registration, the guards it added, a line-by-line confirmation
that your SQL is unchanged, localization results, validation queries (reported to
you, never written into the deployment files), and any risks or blockers.

---

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `claude plugin marketplace add` hangs or fails | No cached GitHub credentials — use the `https://hsenidBiz@github.com/...` form, or sign in via Git Credential Manager first. |
| Slash command not found after install | Run `/reload-plugins`, or restart the session. |
| An expected fix isn't there after updating | The maintainer likely didn't bump `version` in `plugin.json`. Commits alone don't ship. |
| Skill behaves oddly when copied by hand | Don't copy `SKILL.md` on its own — the skill needs its whole folder including `references/`. Install via the marketplace instead. |

## Reporting a problem

Open a PR or an issue against
[`PHR-Foundry`](https://github.com/hsenidBiz/phr-foundry), or
contact PeoplesHR &lt;sanuja.a@peopleshr.com&gt;.
