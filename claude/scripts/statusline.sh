#!/bin/bash
data=$(cat)
used=$(echo "$data" | jq -r '.context_window.used_percentage // 0')
total=$(echo "$data" | jq -r '.context_window.total_input_tokens // 0')
size=$(echo "$data" | jq -r '.context_window.context_window_size // 200000')
cost=$(echo "$data" | jq -r '.cost.total_cost_usd // 0')
printf "ctx: %s%% (%s/%s tokens) | $%.4f\n" "$used" "$total" "$size" "$cost"
