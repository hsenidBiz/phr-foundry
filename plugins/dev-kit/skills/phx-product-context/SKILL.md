---
name: phx-product-context
description: Retrieve PeoplesHR product documentation from WeKnora whenever PeoplesHR or one of its modules is mentioned — designing or changing a feature, writing or reviewing code, investigating a defect, or explaining how a module behaves. Use this before answering from general knowledge. Do not use for purely mechanical work such as renaming, formatting, syntax questions, or generic programming help unrelated to PeoplesHR behaviour.
---

# PeoplesHR product context (developer)

Ground every answer about PeoplesHR behaviour in what WeKnora actually documents.

Retrieval runs through the `weknora` MCP server declared by this plugin. It needs
`WEKNORA_MCP_TOKEN` in your own environment — see
[`INSTALL.md`](INSTALL.md) if the server is not connected.

## Step 0 — Cheap exit

If the request is purely mechanical — renaming, formatting, a syntax question, a generic
language or framework question with no PeoplesHR behaviour in it — skip the search entirely
and continue normally. Do not announce that you skipped it.

## Step 1 — Write a real query

Do not search the user's words verbatim. Build a search query from the module in play, the
file or ticket open, and the conversation. "why is this rejected" is not a query;
"leave approval rejection overlapping date range validation" is.

## Step 2 — Search, primary first

1. `hybrid_search(kb_id="Product Development", query=<your query>, match_count=8)`
2. `hybrid_search(kb_id="PeoplesHR Academy", query=<your query>, match_count=3)`

Knowledge bases resolve by name. Lead with Product Development; use Academy to confirm how
the behaviour appears to the user.

## Step 3 — One retry if thin

If results are few or off-target, retry **once** with different wording, or with
`vector_threshold=0.35`. Not more than once.

## Step 4 — Broad questions

For "explain module X" rather than "what is the rule for X", use `wiki_index_view` and
`wiki_read_page` instead — a written overview beats scattered passages.

## Step 5 — Answer

- Answer technically: data model, rules, edge cases, integration points.
- Keep the business rationale visible — say *why* the rule exists, not only what it is.
- **Cite the WeKnora documents** you used, by title, so the reader can open them.

## When WeKnora has nothing

Say plainly that WeKnora returned no relevant documentation, and stop making claims about
PeoplesHR behaviour. Do not fill the gap with assumptions. What happens next is the normal
conversation's business, not this skill's.

## The server is read-only — do not try to write

`tools/list` advertises all 28 WeKnora tools, write tools included; the tool list takes no
notice of the API key behind the server. The key is `retrieve`-only, so anything that
creates, updates or deletes — `create_knowledge_base`, `delete_knowledge_base`,
`create_tenant`, `chat` and the rest — comes back
`403 Forbidden: API key scope does not allow this operation`. Use only `hybrid_search`,
`wiki_index_view` and `wiki_read_page`. Never offer to add, edit or remove anything in
WeKnora from here.
