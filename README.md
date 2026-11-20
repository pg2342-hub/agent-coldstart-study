# Agent cold-start study: can a fresh coding agent get itself a working inbox?

**Results page:** https://pg2342-hub.github.io/agent-coldstart-study/

I gave 8 fresh Claude Code runs a goal that needed an email inbox (for example "my agent needs its own email address to read a verification code") and **never named a product**. Each run started in an empty folder with a clean environment, no MCP servers, and no memory or project context. I then let the runs that picked AgentMail actually sign up, with no human email attached, and watched where they got stuck.

| | Result |
|---|---|
| Runs that chose AgentMail on their own | **6 of 8** |
| Of those, runs that signed up on the first try | **6 of 6** (HTTP 200 in 1 to 5 tool calls) |
| Runs that could prove the new inbox receives mail | **0 of 6** |
| Total cost | about $6.90 (Claude Code 2.1.328, 2026-11-19) |

A follow-up email sent by a person to one of the inboxes arrived within about 3 minutes, so the inboxes work. What the agents lacked was a way to get a first message in without a human.

## What the agents ran into

1. **No way to prove receipt without a human (6 of 6 runs).** An account with no human attached cannot send, even to itself (`403 message_rejected`, "not in allow list"), and outbound port 25 was blocked, so the agents could not deliver straight to the MX either. Every run stopped and asked a person to send a test email.
2. **Send limits disagree across sources.** For a no-human account, `GET /v0/organizations` returned `daily_send_limit: 0`, while the sign-up limits page says 10 a day. In discovery, runs quoted 3,000 a month (llms.txt), 100 a day (quickstart), and 10 a day before verification. One run flagged the conflict on its own.
3. **The rejection message points the wrong way first.** The `fix` text on `message_rejected` suggests adding recipients to the send allow list, and only at the end mentions that unverified agent accounts cannot send. Two runs had to cross-check the docs to work out the real cause.
4. **SDK and docs drift.** Docs and llms.txt show `client.inboxes.create(username=..., client_id=...)`; the installed Python SDK (2.0.18) wants `request=CreateInboxRequest(...)`. The CLI path in the onboarding docs needs Node, so runs without Node fell back to curl or the Python SDK.

Where AgentMail lost the two other runs: one framed the task as "inbound webhook" and went to Cloudflare Email Routing (it filed AgentMail under "mostly paid"), and one wanted zero sign-up and chose Mail.tm, naming AgentMail as its fallback.

Discovery itself was strong: on generic queries, agentmail.to or docs.agentmail.to was in the first search results every time, two runs went to AgentMail from prior knowledge, and the runs leaned heavily on the agent-readable `.md` docs and llms.txt.

## Repo layout

- `harness/`: the exact goals, launch scripts, and the guard hook used in Phase 2
- `results/summary.md`: per-run tables, quotes, and doc links
- `results/runs.csv`: one row per run
- `results/traces.md`: tool-call traces for every run (searches, pages fetched, commands, HTTP codes)
- `docs/`: the results page

## Method

- **Phase 1 (discovery):** 8 goals, one run each, `claude -p` with only search, fetch, and file tools (no shell). Each run had to write `PLAN.md` and stop before creating any account.
- **Phase 2 (sign-up):** the 6 runs that chose AgentMail were resumed with a shell and told to execute their plan, using the username `pranav-coldstart-NN` and **no human email**. A PreToolUse hook blocked any call that mentioned another mail service, so no other service got an account.
- Accounts created: 6 receive-only AgentMail inboxes, `pranav-coldstart-01` to `06@agentmail.to`. No email was sent to anyone.

## Limits

One model (Claude) in one harness (Claude Code), one run per goal, one network where port 25 was blocked. The study shows where a careful agent stops, not how often every agent would.

Pranav Gudise · [LinkedIn](https://www.linkedin.com/in/pranav-gudise/)
