# Quality Checklist

Run `python scripts/check_doc.py <file.md>` first — it automates the items marked ⚙. Then check the rest by reading the document.

## Identity and furniture
- [ ] ⚙ Front matter has `feature_id, title, module, release, doc_version`.
- [ ] ⚙ File name follows `<Release>-<ID>-<Module>-<Title>-Doc.md` and its release/ID match the front matter.
- [ ] ⚙ Last section is `# Change Control`; last row version equals `doc_version`; date is DD/MM/YYYY.
- [ ] No cover, copyright, TOC or page numbers written in the .md (builder generates them).
- [ ] Nothing copied from another document's header/footer/ID.

## Structure
- [ ] ⚙ Headings are not hand-numbered; no duplicate headings at the same level.
- [ ] Sections follow the order in `template-outline.md`; mandatory sections for the tier are present; no empty or "N/A" sections.
- [ ] Introduction text is not repeated in Feature Overview.
- [ ] Every key in the summary table has a card (T2/T3) and appears in the Procedure.

## Facts
- [ ] Every path, default, data type, owner, module name and message traces to the notes or to the developer's answers.
- [ ] ⚙ No `[TBD]` unless the developer chose TBD for that item (checker run with `--allow-tbd` only then).
- [ ] Key names match the notes character for character.
- [ ] Tier matches the rule and was stated to the developer.

## Content removed
- [ ] ⚙ No source files, classes/methods, PR numbers, branches, repo URLs.
- [ ] ⚙ No secrets (password, connection string, token, internal IP).

## Voice
- [ ] ⚙ No "we / our / us / I / shall"; no chat artifacts.
- [ ] ⚙ Navigation paths use ` > ` (not `->`, `→`, `/`).
- [ ] Procedures are numbered, one action per step; descriptions are third person present tense.
- [ ] UI labels bold, keys/values in code, messages in quotes.

## Figures
- [ ] Screenshot question was asked before writing.
- [ ] ⚙ Figures numbered 1..N in order; every image file exists.
- [ ] Developer said no screenshots → ⚙ no image syntax and no "screenshot"/"placeholder" text.

## Output
- [ ] `.docx` built without warnings; opened once to update fields.
- [ ] If the developer chose TBD for any item, the hand-back lists them, matching the ⚙ TBD count.
