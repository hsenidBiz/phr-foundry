---
name: phx-business-context
description: Retrieve PeoplesHR product documentation from WeKnora whenever PeoplesHR or one of its modules is mentioned — writing requirements, designing a solution, answering a client question, or explaining how a module works. Use this before answering from general knowledge. Do not use for general business writing, formatting, or document formatting tasks with no PeoplesHR behaviour in them.
---

# PeoplesHR business context (BA)

Ground every answer about PeoplesHR behaviour in what WeKnora actually documents.

Retrieval runs through the `weknora` MCP server declared by this plugin. It needs
`WEKNORA_MCP_TOKEN` in your own environment — see
[`INSTALL.md`](INSTALL.md) if the server is not connected.

## Step 0 — Cheap exit

If the request has no PeoplesHR behaviour in it — formatting, summarising the user's own
text, general writing help — skip the search and continue normally. Do not announce it.

## Step 1 — Write a real query

Build a search query from the module and the business process in play, not the user's words
verbatim. "how does this work for part timers" becomes
"leave entitlement proration part-time employees".

## Step 2 — Search, primary first

1. `hybrid_search(kb_id="PeoplesHR Academy", query=<your query>, match_count=8)`
2. `hybrid_search(kb_id="Product Development", query=<your query>, match_count=3)`

Lead with Academy — how the product actually behaves for a user. Use Product Development for
the intent and rules behind it.

## Step 3 — One retry if thin

Retry **once** with different wording or `vector_threshold=0.35`. Not more than once.

## Step 4 — Broad questions

For "explain module X", use `wiki_index_view` and `wiki_read_page` instead.

## Step 5 — Answer

- Answer in business terms: what the user sees, the process, the rules, the configuration.
- Avoid code, schemas and implementation detail **unless asked** — then give them fully.
- **Cite the WeKnora documents** you used, by title.

## When WeKnora has nothing

Say plainly that WeKnora returned no relevant documentation, and stop making claims about
PeoplesHR behaviour. Never invent product behaviour — a BA's output becomes a requirement
someone builds.

## The server is read-only — do not try to write

`tools/list` advertises all 28 WeKnora tools, write tools included; the tool list takes no
notice of the API key behind the server. The key is `retrieve`-only, so anything that
creates, updates or deletes — `create_knowledge_base`, `delete_knowledge_base`,
`create_tenant`, `chat` and the rest — comes back
`403 Forbidden: API key scope does not allow this operation`. Use only `hybrid_search`,
`wiki_index_view` and `wiki_read_page`. Never offer to add, edit or remove anything in
WeKnora from here.
