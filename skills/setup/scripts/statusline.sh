#!/usr/bin/env bash
# Moonlight status line for Claude Code.
# Claude Code sends usage data (rate_limits) only to status line commands. This script
# saves that object to moonlight/usage.json for /moonlight:setup and /moonlight:status,
# then runs your previous status line command if you had one, or prints a short usage line.

moon_dir="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/moonlight"
input=$(cat)
flat=$(printf '%s' "$input" | tr -d '\r\n')

# The rate_limits object, including its one level of nested windows.
limits=$(printf '%s' "$flat" | grep -Eo '"rate_limits"[[:space:]]*:[[:space:]]*\{([^{}]|\{[^{}]*\})*\}' | head -n 1)
case "$limits" in
  *'"seven_day"'*)
    mkdir -p "$moon_dir" 2>/dev/null &&
      printf '{%s,"saved_at":%s}\n' "$limits" "$(date +%s)" >"$moon_dir/usage.json.tmp" 2>/dev/null &&
      mv -f "$moon_dir/usage.json.tmp" "$moon_dir/usage.json" 2>/dev/null
    ;;
esac

# Show the status line the user had before Moonlight, unchanged.
if [ -s "$moon_dir/chain" ]; then
  printf '%s' "$input" | bash -c "$(cat "$moon_dir/chain")"
  exit $?
fi

# Otherwise: [Model] 5h 12% · 7d 41% · resets Thu 09:00
window() { printf '%s' "$limits" | grep -Eo "\"$1\"[[:space:]]*:[[:space:]]*\\{[^{}]*\\}" | head -n 1; }
number() { printf '%s' "$1" | grep -Eo "\"$2\"[[:space:]]*:[[:space:]]*[0-9.]+" | head -n 1 | grep -Eo '[0-9.]+$'; }

model=$(printf '%s' "$flat" | grep -Eo '"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed -E 's/.*"([^"]*)"$/\1/')
five=$(number "$(window five_hour)" used_percentage)
week_window=$(window seven_day)
week=$(number "$week_window" used_percentage)
reset=$(number "$week_window" resets_at)

line="[${model:-Claude}]"
[ -n "$five" ] && line="$line 5h $(LC_ALL=C printf '%.0f' "$five")%"
if [ -n "$week" ]; then
  line="$line · 7d $(LC_ALL=C printf '%.0f' "$week")%"
  if [ -n "$reset" ]; then
    when=$(date -d "@$reset" '+%a %H:%M' 2>/dev/null || date -r "$reset" '+%a %H:%M' 2>/dev/null)
    [ -n "$when" ] && line="$line · resets $when"
  fi
fi
printf '%s\n' "$line"
