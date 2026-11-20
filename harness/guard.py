# PreToolUse guard for Phase 2: the study only approved AgentMail accounts,
# so any tool call that mentions another mail service or a personal mailbox is blocked and logged.
import json, sys, re, time
d = json.load(sys.stdin); s = json.dumps(d.get('tool_input', {})).lower()
bad = re.findall(r'mail\.tm|mailslurp|mailosaur|smtp\.dev|postmark|resend\.com|mailgun|sendgrid|wrangler|cloudflare|botemail|mail\.cx|guerrilla|temp-?mail|gmail\.com', s)
if bad:
    open('/tmp/coldstart/hook/blocked.log', 'a').write(f"{time.time()} {d.get('cwd')} {bad} {s[:300]}\n")
    print(f"Blocked by study harness: only AgentMail is permitted in this run ({bad[0]}).", file=sys.stderr)
    sys.exit(2)
