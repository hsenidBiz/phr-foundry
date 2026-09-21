# `phx-business-context` — prerequisites

The skill ships with `ba-kit`. What it needs and the plugin deliberately does
**not** ship is one per-person credential: the WeKnora MCP bearer token.

## 1. Get the token

`WEKNORA_MCP_TOKEN` is a single shared value for the whole team, handed out through the
normal credential channel — your password manager or IT onboarding. It is **not** in this
repo, which is public, and it must never be committed, pasted into a chat, or typed into a
Claude conversation.

Ask PeoplesHR &lt;sanuja.a@peopleshr.com&gt; if you do not have it.

## 2. Set it as an environment variable

**Windows (PowerShell)** — prompt for it rather than using `setx`, which would put the
token in your PowerShell history and in `argv`:

```powershell
$s = Read-Host -AsSecureString 'WEKNORA_MCP_TOKEN'
[Environment]::SetEnvironmentVariable('WEKNORA_MCP_TOKEN',
  [Runtime.InteropServices.Marshal]::PtrToStringBSTR(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($s)), 'User')
```

This keeps the value out of history and argv. It is not a secret store: Windows keeps user
environment variables as plaintext in `HKCU\Environment` — the same exposure
`PHX_DB_CONNECTION_STRING` already has here.

**macOS / Linux** — `export WEKNORA_MCP_TOKEN=...` from your shell profile, with the
profile file at mode `600`.

## 3. Then restart Claude Code — and only then

Windows reads user environment variables **at process start**. A terminal or Claude Code
that was already running when you set the variable will never see it.

This is the one failure everyone hits, and a correctly installed token looks exactly like a
broken one: `$env:WEKNORA_MCP_TOKEN` is empty and `claude mcp list` warns that the variable
is missing for `weknora`. Check the registry, not the process, before concluding anything is
wrong:

```powershell
[Environment]::GetEnvironmentVariable('WEKNORA_MCP_TOKEN','User')   # authoritative
$env:WEKNORA_MCP_TOKEN                                              # only this process
```

## 4. Verify

`/mcp` should list `weknora` as connected. Then ask a real PeoplesHR question and check that
the answer cites WeKnora documents.

| Symptom | Meaning |
| --- | --- |
| Missing-variable warning in `claude mcp list` | The variable is unset, **or** this process started before you set it — restart first. |
| `401` | The token is wrong or was not sent. |
| `503` with a JSON body | WeKnora is in maintenance mode. Try again shortly. |
| A search returns `isError` | The token is fine. The knowledge-base name or the API key's scope is the issue — report it rather than retrying differently. |

The last row is the one that misleads: the bearer token gets you to the MCP server, and a
separate read-only API key on the server decides what it may do. A failing **search** is
almost never the token.

## Do not install the developer skill alongside this one

`phx-product-context`, in the `org-standards` plugin, searches the same two knowledge bases
in the opposite order and answers in technical rather than business terms. The two compete on
question wording and misroute if both are present. BAs install `ba-kit` only. Anyone
genuinely doing both jobs takes the developer skill instead, which keeps the business
rationale as a secondary.
