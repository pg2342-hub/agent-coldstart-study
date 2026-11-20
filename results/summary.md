# Cold-start study: full results (2026-11-19)

Harness: Claude Code 2.1.328 (`claude -p`, stream-json, max 40 turns), one run per goal in an empty folder. Clean environment (`env -i`), empty MCP config, no global CLAUDE.md, no mention of AgentMail anywhere in the agent's settings. Goals are in `harness/goals.tsv`; none names a product.

## Phase 1: discovery (no accounts created)

**6 of 8 runs chose AgentMail.** One more (G8) named it as the fallback.

| Run | Goal | Chosen | How it got there | Turns | Sec | Cost $ |
|---|---|---|---|---|---|---|
| G1 | verification-code inbox | AgentMail | generic search ("email inbox API for AI agents receive verification codes") listed agentmail.to next to MailSlurp, Mailosaur, smtp.dev; then quickstart.md, agent-onboarding.md, websockets.md | 8 | 70 | 0.30 |
| G2 | support bot, reply in thread | AgentMail | generic search; agentmail.to + docs.agentmail.to in results; then llms.txt, quickstart, websockets, reply API, webhook setup, Python SDK reference | 14 | 98 | 0.39 |
| G3 | API inbox, prove receive | AgentMail | generic search (YC page, Better Stack guide, docs.agentmail.to); then quickstart, llms.txt, inboxes.md | 8 | 74 | 0.31 |
| G4 | 50 per-user mailboxes | AgentMail (pods + inbox-scoped keys) | prior knowledge: second search was "AgentMail API create inbox docs"; then create-inbox API ref, pricing, inboxes.md, pods.md | 10 | 70 | 0.31 |
| G5 | Python webhook on receive | Cloudflare Email Routing + Worker | generic search showed agentmail.to, but the run framed it as an inbound-webhook problem and filed agent-focused APIs under "mostly paid tiers" | 11 | 98 | 0.45 |
| G6 | Gmail sending limits | AgentMail Developer ($20/mo) + custom domain | generic search; then quickstart, webhooks overview, pricing, webhook verification, custom domains | 12 | 106 | 0.42 |
| G7 | send + receive without Gmail | AgentMail | prior knowledge: first query was "email inbox API for AI agents send and receive (AgentMail)"; then quickstart, websockets, sending-receiving guide | 8 | 72 | 0.31 |
| G8 | throwaway inbox for a login code | Mail.tm | generic OTP search listed agentmail.to; read agent-onboarding.md but chose Mail.tm because it needs no account or key | 12 | 93 | 0.37 |

### Observations

- **Discovery is strong.** On generic agent-email queries, agentmail.to or docs.agentmail.to appeared in the first results every time. Two runs went straight to AgentMail from model knowledge.
- **Agent-readable docs do real work.** Runs fetched `docs.agentmail.to/*.md` and `llms.txt` directly instead of HTML pages.
- **Where AgentMail lost:** when the agent read the task as "inbound webhook" rather than "agent inbox" (G5), and when the agent wanted zero sign-up (G8).
- **Free-tier numbers conflict.** G2 quoted 3,000 emails/month (llms.txt), G6 and G7 quoted 100/day (quickstart), G1 quoted 10/day before verification. G3 wrote: "3,000 emails/month (per their llms.txt; the quickstart says 100 emails/day)".
- **Every AgentMail plan assumed a human finishes sign-up**, either in the console or by reading a one-time code sent to a human email.
- **Vendor-bias awareness.** G2, G4 and G6 noted that many comparison pages they found were AgentMail's own posts and based the decision on the API docs instead.
- No run made a clearly wrong claim about AgentMail; the only inconsistencies came from the docs themselves.

## Phase 2: sign-up (6 runs, no human email)

The six AgentMail sessions were resumed with a shell. A guard hook (`harness/guard.py`) blocked any tool call that mentioned another mail service.

**6 of 6 signed up and got an inbox. 0 of 6 proved receipt on their own.**

| NN | Run | Signed up via | Path to a working inbox | Errors hit | Turns | Min | Cost $ |
|---|---|---|---|---|---|---|---|
| 01 | G1 | Python SDK `client.agent.sign_up(username=...)` | pip install, auth.md, sign_up, inboxes.get, messages.list (0) | 403 `MessageRejectedError` on self-send | 10 | 1.5 | 0.56 |
| 02 | G2 | curl `POST /v0/agent/sign-up` | llms.txt, agent-onboarding, sign-up ref, sign-up limits; curl; GET inbox and messages; WebSocket subscribe OK | 403 `message_rejected` ("not in allow list"); port 25 timeout | 17 | 3.7 | 0.82 |
| 03 | G3 | curl sign-up | onboarding.md; curl; direct SMTP self-test | port 25 timeout | 8 | 2.9 | 0.55 |
| 04 | G4 | curl sign-up (`referrer: agent.email`) | llms-full.txt, agent.email/skill.md; curl; GET /organizations | 403 `message_rejected`; port 25 timeout; read `daily_send_limit: 0` | 17 | 4.1 | 0.70 |
| 05 | G6 | curl sign-up | llms.txt, onboarding, sign-up limits, sign-up ref; curl | port 25 timeout; one call blocked by the harness | 15 | 5.3 | 0.81 |
| 06 | G7 | curl sign-up | pip install, sign-up ref; curl; messages.list (0) | port 25 timeout | 11 | 2.8 | 0.60 |

Sign-up itself was fast and clean: HTTP 200 on the first try in every run, in 1 to 5 tool calls. Every run noticed the receive-only state; G6 dropped its "$20 plan with a custom domain" plan once it hit it.

**Human follow-up:** a person sent one plain email to `pranav-coldstart-01@agentmail.to`. `GET /v0/inboxes/{id}/messages` listed it with timestamp 2026-11-19T10:53:05Z; it was not visible on a poll a few seconds later and appeared on a later poll within about 3 minutes. The other five inboxes stayed at 0 messages.

## Stuck points, with evidence

### 1. No way to prove receipt without a human (6 of 6)
An unverified agent account cannot send, even to itself, and outbound port 25 is blocked on many networks, so the agent cannot deliver to the MX directly.
- G2: "I could not show it receiving a message. I'm blocked because there is no way to get an email into it without a human email address or a second account."
- API: `Message rejected: Recipient(s) blocked: pranav-coldstart-02@agentmail.to (not in allow list)`
- Docs: https://docs.agentmail.to/knowledge-base/agent-sign-up-limits.md
- Possible fix: let an unverified inbox send to itself, or add a "send a test message to my inbox" endpoint, so an agent can close the loop alone.

### 2. Send limits disagree
The sign-up limits page and onboarding say 10 emails a day (to the attached human). For a no-human account, `GET /v0/organizations` returns `daily_send_limit: 0`. Discovery runs also found 3,000/month in llms.txt against 100/day in the quickstart.
- G4: "`authentication_type: agent`, `agent_verified: false`, `inbox_limit: 1`, `daily_send_limit: 0`, `domain_limit: 0`"
- Docs: https://docs.agentmail.to/knowledge-base/agent-sign-up-limits.md, https://www.agentmail.to/llms.txt, https://docs.agentmail.to/quickstart

### 3. The rejection message leads with allow lists
The `fix` field on `message_rejected` first suggests `POST /v0/lists/send/allow`, and only at the end says agent accounts that have not completed verification cannot send. G2 and G4 both cross-checked the docs to confirm the real cause.

### 4. SDK and docs drift on `inboxes.create`
Docs and llms.txt show `client.inboxes.create(username=..., client_id=...)`. SDK 2.0.18 requires `request=CreateInboxRequest(...)`.
- G2: "`client.inboxes.create(*, request=CreateInboxRequest(...))`: it does **not** take `username=`/`client_id=` as top-level keyword arguments."
- Source: https://github.com/agentmail-to/agentmail-python/blob/main/reference.md vs https://docs.agentmail.to/inboxes.md
- Related: the CLI path in the onboarding docs needs Node; runs without it fell back to curl or the Python SDK.

### Also noticed
- G4 found the sign-up flow through `https://agent.email/skill.md`, a skill file written for agents.
- G3 stored its key under the user's home folder, outside its working directory.

## Totals
- Phase 1: 8 runs, about $2.85.
- Phase 2: 6 runs, 6 accounts, about $4.03.
- Total about $6.90.
