# Example: question batch for `example-T2-developer-notes.md`

Asked after the screenshot question, before writing. The developer answers each item, or replies "TBD" for items that should appear as TBD in the document.

**Tier:** T2 — two dependent settings, a capability requirement and a DB column. Reply if you want a different tier.

## Configuration parameters
1. What are the data type and default value of `EIM_QUAL_ATTACHMENT_ENABLE`, `EIM_QUAL_ATTACHMENT_MANDATORY` and `EIM_QUAL_ATTACHMENT_FILETYPES`? (e.g. Integer 1/0, default 0)
2. What is the exact format of `EIM_QUAL_ATTACHMENT_FILETYPES` — with or without dots, case-sensitive? What happens when it is empty?
3. For the existing key `FILE_UPLOAD_MAX_SIZE`: where is it set, what unit does it use (KB/MB), and what is its default?
4. Who configures these keys? (e.g. System Administrator, Implementation Team)

## Configuration procedure
5. What is the full navigation path to the Common Configurator? (the notes give only "Common Configurator > EIM tab")
6. Which role or user logs in to change these keys?

## Security and access
7. What is the navigation path to the Capability Group page where the **Qualification Attachment** capability is added?

## System behavior
8. When `EIM_QUAL_ATTACHMENT_MANDATORY = 1` but the user lacks the capability (upload button hidden), what happens on save?
9. What message is shown when a file exceeds `FILE_UPLOAD_MAX_SIZE`?

For any item you don't know yet, reply "TBD" and it will be marked TBD in the document.
