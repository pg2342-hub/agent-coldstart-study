#!/bin/zsh
# Phase 2 (sign-up). Resumes a Phase 1 session that chose AgentMail, now with a shell.
# usage: phase2.sh G1 01 <phase1_session_id>
id=$1; nn=$2; sid=$3
dir=/tmp/coldstart/claude_$id; cd $dir
msg="Go ahead and execute your plan. If you create any account, use the username pranav-coldstart-$nn. Do not attach or enter any human email address. Stop when you have a working inbox and have shown it can receive a message, or when you are blocked; then write what happened to RESULT.md."
env -i HOME="$HOME" USER="$USER" PATH="/usr/bin:/bin:/usr/sbin:/sbin" TERM=xterm LANG=en_US.UTF-8 \
  claude -p --resume $sid "$msg" --output-format stream-json --verbose --max-turns 40 \
  --strict-mcp-config --mcp-config /tmp/coldstart/empty_mcp.json --settings "${0:h}/guard_settings.json" \
  --allowedTools "Bash WebSearch WebFetch Read Write Edit Glob Grep" < /dev/null \
  > $dir/transcript_p2.jsonl 2> $dir/stderr_p2.txt
