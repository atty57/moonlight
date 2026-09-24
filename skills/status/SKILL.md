---
name: status
description: Report on Moonlight's next run, weekly usage, queue and last results. Use when the user asks about Moonlight or what it did overnight.
---

# Moonlight status

1. Read `moonlight/config.json` in the Claude config folder (`$CLAUDE_CONFIG_DIR`, otherwise `~/.claude`). If it's missing, say Moonlight isn't set up on this machine and suggest `/moonlight:setup`.
2. Pull the queue (`git -C <queue_dir> pull --rebase --quiet`), then read `moonlight.json`, `QUEUE.md` and the latest entries of `NIGHTLY_LOG.md`.
3. If the RemoteTrigger tool is available (load it with ToolSearch if it's deferred), check each routine's recent runs with `list_runs`, and read `get_run_log` for any that failed. Also convert each routine's UTC cron to local time and compare it with `runs`: a daylight-saving change shifts them by an hour, and if they differ, offer to update the cron.
4. If `moonlight/usage.json` exists, read `rate_limits.seven_day` (`used_percentage`, `resets_at`) and `saved_at`, the reading's age. Convert `resets_at` to the configured timezone. If it differs from `weekly_reset` in `moonlight.json` by more than 30 minutes, the reset has moved: say so and offer to re-plan with the setup skill's plan step, then update `moonlight.json`, config.json and the routine schedule.
5. Report in a short block:
   - **Next run**: date, time and stop time.
   - **This week**: e.g. `41% used · resets Thu 09:00`, noting the reading's age if it's over a day old.
   - **Queue**: counts by status; each `blocked` task with its question; `wip` tasks; `pr` tasks with links.
   - **Last run**: the latest log entry in a few lines, plus any failed routine run.
6. With `gh` available, check the `pr` links and offer to remove tasks whose PRs are merged or closed; offer IDs for hand-written tasks that lack one. Commit and push whatever the user accepts.
