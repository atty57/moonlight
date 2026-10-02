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

window() { printf '%s' "$limits" | grep -Eo "\"$1\"[[:space:]]*:[[:space:]]*\\{[^{}]*\\}" | head -n 1; }
number() { printf '%s' "$1" | grep -Eo "\"$2\"[[:space:]]*:[[:space:]]*[0-9.]+" | head -n 1 | grep -Eo '[0-9.]+$'; }

# "Thu 13:00" -> minutes into the week, for comparing a weekday label with a timestamp.
label_minutes() {
  case "$1" in
    Mon*) day=0 ;; Tue*) day=1 ;; Wed*) day=2 ;; Thu*) day=3 ;;
    Fri*) day=4 ;; Sat*) day=5 ;; Sun*) day=6 ;; *) return 1 ;;
  esac
  clock=${1#* }
  hh=${clock%%:*}
  mm=${clock##*:}
  case "$hh$mm" in *[!0-9]*) return 1 ;; esac
  # ${x#0} keeps 08 from being read as octal.
  printf '%s' "$(( day * 1440 + ${hh#0} * 60 + ${mm#0} ))"
}

week_window=$(window seven_day)
reset=$(number "$week_window" resets_at)

# A moved weekly reset otherwise goes unnoticed until someone runs /moonlight:status,
# while the runs keep firing on the old night and spend the start of the next week.
# Compare the reset Claude Code reports with the one setup planned for, both in UTC.
warn=""
planned=$(grep -Eo '"reset_utc"[[:space:]]*:[[:space:]]*"[^"]*"' "$moon_dir/config.json" 2>/dev/null |
  head -n 1 | sed -E 's/.*"([^"]*)"$/\1/')
if [ -n "$planned" ] && [ -n "$reset" ]; then
  actual=$(date -u -d "@$reset" '+%a %H:%M' 2>/dev/null || date -u -r "$reset" '+%a %H:%M' 2>/dev/null)
  seen=$(label_minutes "$actual") || seen=""
  want=$(label_minutes "$planned") || want=""
  if [ -n "$seen" ] && [ -n "$want" ]; then
    # Minutes apart, whichever way round the week is shorter; 30 matches /moonlight:status.
    apart=$(( (seen - want + 10080) % 10080 ))
    [ "$apart" -gt 5040 ] && apart=$(( 10080 - apart ))
    if [ "$apart" -gt 30 ]; then
      warn=" ⚠ reset moved, run /moonlight:status"
    fi
  fi
fi

# Show the status line the user had before Moonlight, with the warning appended.
if [ -s "$moon_dir/chain" ]; then
  chained=$(printf '%s' "$input" | bash -c "$(cat "$moon_dir/chain")")
  chained_status=$?
  printf '%s%s\n' "$chained" "$warn"
  exit "$chained_status"
fi

# Otherwise: [Model] 5h 12% · 7d 41% · resets Thu 09:00
model=$(printf '%s' "$flat" | grep -Eo '"display_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -n 1 | sed -E 's/.*"([^"]*)"$/\1/')
five=$(number "$(window five_hour)" used_percentage)
week=$(number "$week_window" used_percentage)

line="[${model:-Claude}]"
[ -n "$five" ] && line="$line 5h $(LC_ALL=C printf '%.0f' "$five")%"
if [ -n "$week" ]; then
  line="$line · 7d $(LC_ALL=C printf '%.0f' "$week")%"
  if [ -n "$reset" ]; then
    when=$(date -d "@$reset" '+%a %H:%M' 2>/dev/null || date -r "$reset" '+%a %H:%M' 2>/dev/null)
    [ -n "$when" ] && line="$line · resets $when"
  fi
fi
printf '%s%s\n' "$line" "$warn"
