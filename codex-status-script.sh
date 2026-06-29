#!/usr/bin/env bash

json=$(
(
  echo '{"id":1,"method":"initialize","params":{"clientInfo":{"name":"codex-status","title":null,"version":"0.1"},"capabilities":{"experimentalApi":false,"requestAttestation":false}}}'
  sleep 0.1
  echo '{"method":"initialized"}'
  sleep 0.1
  echo '{"id":2,"method":"account/rateLimits/read","params":null}'
  sleep 1
) | codex app-server | jq 'select(.id == 2)'
)

five_used=$(echo "$json" | jq -r '.result.rateLimits.primary.usedPercent')
week_used=$(echo "$json" | jq -r '.result.rateLimits.secondary.usedPercent')

five_reset=$(echo "$json" | jq -r '.result.rateLimits.primary.resetsAt')
week_reset=$(echo "$json" | jq -r '.result.rateLimits.secondary.resetsAt')

credits=$(echo "$json" | jq -r '.result.rateLimitResetCredits.availableCount')

five_left=$((100 - five_used))
week_left=$((100 - week_used))

five_reset_local=$(date -r "$five_reset" "+%I:%M %p")
week_reset_local=$(date -r "$week_reset" "+%I:%M %p")
week_reset_date=$(date -r "$week_reset" "+%b %d")

printf "5h: %3d%% (%s)   Weekly: %3d%% (%s)   Credits: %s\n" \
    "$five_left" "$five_reset_local" \
    "$week_left" "$week_reset_date $week_reset_local" \
    "$credits"
