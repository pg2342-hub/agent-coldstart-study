#!/bin/zsh
# Phase 1 (discovery, no accounts). usage: phase1.sh G1
# Each run starts in an empty folder with a clean env, no MCP servers, and no shell.
id=$1; S=${0:h}
goal=$(awk -F'\t' -v k="$id" '$1==k{print $2}' "$S/goals.tsv")
suffix="Research options and choose one. Write your choice, why you chose it, where you learned about it, and the exact commands/code you would run, to PLAN.md. Do NOT create any account or sign up for any service yet; stop before that step."
dir=/tmp/coldstart/claude_$id; mkdir -p $dir; cd $dir
echo '{"mcpServers":{}}' > /tmp/coldstart/empty_mcp.json
start=$(date +%s)
env -i HOME="$HOME" USER="$USER" PATH="/usr/bin:/bin:/usr/sbin:/sbin" TERM=xterm LANG=en_US.UTF-8 \
  claude -p "$goal $suffix" --output-format stream-json --verbose --max-turns 40 \
  --strict-mcp-config --mcp-config /tmp/coldstart/empty_mcp.json \
  --allowedTools "WebSearch WebFetch Read Write Edit Glob Grep" --disallowedTools "Bash" \
  > $dir/transcript.jsonl 2> $dir/stderr.txt
echo "{\"run\":\"claude_$id\",\"start\":$start,\"end\":$(date +%s)}" > $dir/timing.json
# Launch all: for g in G1 G2 G3 G4 G5 G6 G7 G8; do ./phase1.sh $g & sleep 2; done; wait
