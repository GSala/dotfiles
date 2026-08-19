#!/usr/bin/env bash
# Claude Code statusLine script
# Reads JSON from stdin and outputs a compact one-line status bar.

input=$(cat)

# --- Colours (dim, so they don't fight the terminal theme) ---
RESET='\033[0m'
DIM='\033[2m'
CYAN='\033[36m'
YELLOW='\033[33m'
GREEN='\033[32m'
MAGENTA='\033[35m'
BLUE='\033[34m'
WHITE='\033[37m'

# --- Extract fields ---
cwd=$(echo "$input"       | jq -r '.workspace.current_dir // .cwd // empty')
model=$(echo "$input"     | jq -r '.model.display_name // empty')
branch=$(git -C "${cwd:-.}" --no-optional-locks rev-parse --abbrev-ref HEAD 2>/dev/null)

five_pct=$(echo "$input"   | jq -r '.rate_limits.five_hour.used_percentage  // empty')
five_reset=$(echo "$input" | jq -r '.rate_limits.five_hour.resets_at        // empty')
week_pct=$(echo "$input"   | jq -r '.rate_limits.seven_day.used_percentage  // empty')
ctx_pct=$(echo "$input"    | jq -r '.context_window.used_percentage         // empty')
cost_usd=$(echo "$input"   | jq -r '.cost.total_cost_usd                    // empty')

# --- Render a compact inline progress bar (filled/empty blocks) ---
make_bar() {
  local pct="$1"
  local width="${2:-8}"
  local filled=$(( (${pct%.*} * width + 50) / 100 ))
  [ "$filled" -lt 0 ] && filled=0
  [ "$filled" -gt "$width" ] && filled=$width
  local empty=$(( width - filled ))
  local bar=""
  local i
  for ((i = 0; i < filled; i++)); do bar+="█"; done
  for ((i = 0; i < empty; i++)); do bar+="░"; done
  printf '%s' "$bar"
}

# --- Convert an epoch (or epoch.fraction) timestamp to local HH:MM ---
epoch_to_local_time() {
  local ts="${1%.*}"
  [ -z "$ts" ] && return
  # BSD/macOS date first, fall back to GNU date
  date -r "$ts" "+%H:%M" 2>/dev/null || date -d "@$ts" "+%H:%M" 2>/dev/null
}

# --- Directory: replace $HOME with ~ ---
home="${HOME:-/Users/$(whoami)}"
display_dir="${cwd/#$home/${TILDE:-~}}"

# --- Build output ---
parts=()

# Directory
if [ -n "$display_dir" ]; then
  parts+=("$(printf "${CYAN}%s${RESET}" "$display_dir")")
fi

# Git branch
if [ -n "$branch" ]; then
  parts+=("$(printf "${YELLOW} %s${RESET}" "$branch")")
fi

# Model
if [ -n "$model" ]; then
  parts+=("$(printf "${MAGENTA}%s${RESET}" "$model")")
fi

# Session cost
if [ -n "$cost_usd" ]; then
  parts+=("$(printf "${WHITE}\$%.2f${RESET}" "$cost_usd")")
fi

# Rate-limit / context percentages
pct_parts=()

if [ -n "$five_pct" ]; then
  five_int="$(printf '%.0f' "$five_pct")"
  five_bar="$(make_bar "$five_int" 8)"
  pct_parts+=("$(printf "${GREEN}5h: %s %s%%${RESET}" "$five_bar" "$five_int")")
fi

if [ -n "$week_pct" ]; then
  pct_parts+=("$(printf "${GREEN}wk: %.0f%%${RESET}" "$week_pct")")
fi

if [ -n "$ctx_pct" ]; then
  pct_parts+=("$(printf "${BLUE}ctx: %.0f%%${RESET}" "$ctx_pct")")
fi

if [ ${#pct_parts[@]} -gt 0 ]; then
  # Join pct_parts with " | "
  sep="$(printf "${DIM} | ${RESET}")"
  joined_pcts=""
  for i in "${!pct_parts[@]}"; do
    if [ $i -eq 0 ]; then
      joined_pcts="${pct_parts[$i]}"
    else
      joined_pcts="${joined_pcts}${sep}${pct_parts[$i]}"
    fi
  done
  parts+=("$joined_pcts")
fi

# --- Join all parts with a dim separator ---
sep="$(printf "${DIM}  ${RESET}")"
result=""
for i in "${!parts[@]}"; do
  if [ $i -eq 0 ]; then
    result="${parts[$i]}"
  else
    result="${result}${sep}${parts[$i]}"
  fi
done

# --- Append 5h rate-limit reset time at the very end of the status line ---
if [ -n "$five_reset" ]; then
  reset_time="$(epoch_to_local_time "$five_reset")"
  if [ -n "$reset_time" ]; then
    result="${result}${sep}$(printf "${DIM}resets %s${RESET}" "$reset_time")"
  fi
fi

printf "%b\n" "$result"
