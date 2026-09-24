# Install the Moonlight status line

Claude Code passes usage data (`rate_limits`) only to status line commands. Moonlight's script saves that object to `MOON_DIR/usage.json`, then runs the user's previous status line command if there was one, so their status line looks the same as before.

1. **Shell check.** The script needs bash. On Windows, continue only if Git Bash is installed (your Bash tool runs through it); otherwise skip this file and ask the user for their reset time.
2. Copy `SKILL_DIR/scripts/statusline.sh` to `MOON_DIR/statusline.sh` and make it executable. Confirm `echo '{}' | MOON_DIR/statusline.sh` prints a line.
3. Read `CFG/settings.json`; a missing file counts as `{}`.
4. If `statusLine` exists and its command isn't `MOON_DIR/statusline.sh`: save the whole `statusLine` object to `MOON_DIR/statusline.original.json`, and its `command` string, exactly, to `MOON_DIR/chain`.
5. Set `statusLine` to `{"type": "command", "command": "<MOON_DIR>/statusline.sh"}`, keeping `padding` and `refreshInterval` from the old object if it had them. Write the path with forward slashes; `~/.claude/moonlight/statusline.sh` works when `CFG` is `~/.claude`. Leave every other key untouched, and check the file still parses as JSON.
6. Claude Code re-runs the status line as soon as its command changes. Poll for `MOON_DIR/usage.json` with `sleep 3`, for up to about 15 seconds.
7. Read `rate_limits.seven_day.resets_at` (Unix seconds) and convert it to a weekday and time in the user's timezone: `TZ=<tz> date -d @<s> '+%a %H:%M'` on Linux and Git Bash, `TZ=<tz> date -r <s> '+%a %H:%M'` on macOS.

Only Pro and Max logins send usage data, so `usage.json` can stay missing even with the status line working. In that case keep the status line (the usage line or the user's own status line still shows) and ask the user for their reset time.
