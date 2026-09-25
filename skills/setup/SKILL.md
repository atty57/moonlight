---
name: setup
description: Set up or reconfigure Moonlight's overnight routine, queue repo and schedule.
disable-model-invocation: true
argument-hint: "[repos Moonlight may work on, e.g. owner/app owner/api]"
---

# Set up Moonlight

Take the user from nothing to a scheduled Moonlight routine, asking as little as possible. Repos they named: $ARGUMENTS

Paths used below; resolve each to an absolute path once, with the shell:
- `SKILL_DIR`: `${CLAUDE_SKILL_DIR}`. If that placeholder wasn't filled in, use the "Base directory for this skill" path shown above.
- `CFG`: the Claude config folder, `$CLAUDE_CONFIG_DIR` if set, otherwise `~/.claude`.
- `MOON_DIR`: `CFG/moonlight`, where Moonlight keeps its local files.

## 1. Check what exists

1. `git --version` must succeed. `gh auth status` tells you whether you can create the GitHub repo yourself in step 6 or the user creates it in the browser.
2. If `MOON_DIR/config.json` exists, Moonlight is already set up on this machine: show the current plan from it, ask what to change, and redo only the steps that change.
3. If the user's GitHub account already has a `moonlight-queue` repo with a `moonlight.json` (set up from another machine), reuse it in step 6.

## 2. Ask everything at once

One AskUserQuestion call:
1. **Repos** (multi-select): "Which repos may Moonlight work on?" Offer up to four: repos from the arguments, this folder's GitHub remote, then recently pushed, unarchived repos from `gh repo list`. Add a "None for now" option if you have fewer than two. The user can type more; writing and research tasks need no repo.
2. **Sleep window**: "When are you usually asleep? Moonlight runs only then." Options: 23:00–07:00 (Recommended), 00:00–08:00, 22:00–06:00.
3. **Usage credits**: "Is extra usage (usage credits) off at claude.ai/settings/usage? If it's on, a run that uses up your limit keeps going on paid overage." Options: It's off / I'll turn it off now / Keep it on, I accept overage charges.
4. **Status line** (skip if `MOON_DIR/usage.json` exists): "Show weekly usage in your status line? This lets Moonlight read your reset time. An existing status line keeps working." Options: Yes (Recommended) / No, I'll type my reset time.

## 3. Find the timezone and weekly reset

1. Timezone, as an IANA name like `America/New_York`: macOS `readlink /etc/localtime`; Linux `timedatectl show -p Timezone --value`; Windows `powershell -NoProfile -Command "[TimeZoneInfo]::Local.Id"`, mapped from the Windows name to IANA.
2. Reset time: if the user chose the status line, follow `SKILL_DIR/statusline-install.md`, which ends with the reset as a weekday and time. Otherwise, or if that doesn't produce one, ask the user for the weekly reset shown by `/usage` or at claude.ai/settings/usage.

## 4. Plan the runs

Sleep windows repeat daily. With weekly reset `R` and sleep window `S`–`E`:
1. **Window**: if `R` falls inside a sleep window with at least 3 hours of it before `R`, use that window; otherwise use the latest window that ends before `R`.
2. **Stop time**: whichever is earlier, `E` or 20 minutes before `R`.
3. **Runs**: one at `S`, and a second at `S` + 5 h 15 min if that's at least an hour before the stop time. The second run gets a fresh 5-hour usage window; the extra 15 minutes clear the first window's end.
4. **Awake gap**: if the reset comes more than 12 hours after the stop time, tell the user the runs will spend usage they could still use themselves that day, so they can pick a different night in step 5.

Check your plan against these (sleep 23:00–07:00):

| Reset | Runs | Stop |
|---|---|---|
| Thu 09:00 | Wed 23:00, Thu 04:15 | Thu 07:00 |
| Thu 03:00 | Wed 23:00 | Thu 02:40 |
| Mon 00:30 | Sat 23:00, Sun 04:15 | Sun 07:00 |

## 5. Confirm

Show the plan, then ask with AskUserQuestion (Create it / Change something):

    Weekly reset:  Thu 09:00 (America/New_York)
    Runs:          Wed 23:00 and Thu 04:15, stopping by Thu 07:00
    Repos:         owner/app, owner/api
    Queue:         github.com/<login>/moonlight-queue (private, new)
    Routines:      "Moonlight" and "Moonlight (2nd run)" at claude.ai/code/routines, no connectors

## 6. Create the queue repo

1. Get the GitHub login from `gh api user --jq .login`, or ask.
2. Create an **empty** private repo: `gh repo create <login>/moonlight-queue --private --description "Moonlight task queue"`, with no README. Without `gh`, ask the user to create it at https://github.com/new?name=moonlight-queue&visibility=private with "Add a README" unticked, and wait until they confirm.
3. Build it in `MOON_DIR/queue`: `git init -b claude/queue`; copy `QUEUE.md`, `README.md` and `NIGHTLY_LOG.md` from `SKILL_DIR/templates/`; add an empty `outputs/.gitkeep`; write `moonlight.json` in the shape of `SKILL_DIR/templates/moonlight.json` with the real `timezone`, `weekly_reset`, `stop_at` and `runs`, `stop_at_utc` (the stop time converted to UTC, as for the crons in step 7), and `next_id: 1`. The routine reads only `stop_at_utc`, so it never depends on the cloud machine's timezone data.
4. Commit, add the remote (SSH if the user's other clones use SSH, HTTPS otherwise), and `git push -u origin claude/queue`.
5. The first branch pushed to an empty repo becomes its default. Confirm with `gh repo view <repo> --json defaultBranchRef`; if it isn't `claude/queue`, run `gh repo edit <repo> --default-branch claude/queue`. The queue lives on a `claude/` branch because cloud routines can always push to those.

To reuse an existing queue repo instead, clone it into `MOON_DIR/queue` and update its `moonlight.json` with the new plan, keeping `next_id`.

This step is done when `claude/queue` is the default branch on GitHub and holds all four files.

## 7. Create the routines

Invoke the built-in `schedule` skill with the Skill tool, passing everything below as its argument so it skips its opening question. It looks up the user's cloud environments and GitHub access, and creates routines through the RemoteTrigger tool. Each routine holds one UTC cron expression, so create one routine per run time, with identical settings otherwise:
- **Names**: `Moonlight`, and `Moonlight (2nd run)` for the second run time.
- **Schedule**: a weekly cron in UTC for each run time. Convert the local weekday and time, and show the user the conversion.
- **Prompt**: the full text of `SKILL_DIR/templates/routine-prompt.md`, unchanged. It reads everything user-specific from `moonlight.json`.
- **Repositories**: the queue repo first, then each repo from step 2, as `https://github.com/owner/name` URLs.
- **Model**: this session's model unless the user picked another (the schedule skill otherwise defaults to Sonnet).
- **Allowed tools**: `Bash`, `Read`, `Write`, `Edit`, `Glob`, `Grep`, `WebSearch`, `WebFetch`.
- **Connectors**: none; leave `mcp_connections` out. Moonlight needs only git.
- **Environment**: the user's default cloud environment.

If the schedule skill reports missing GitHub access, ask the user to run `/web-setup` or install the Claude GitHub App (https://github.com/apps/claude), then retry. If it isn't available or needs a claude.ai login (Claude Code signed in with an API key), use the web form instead: save the prompt to `MOON_DIR/routine-prompt.md`, copy it to the clipboard (`pbcopy`, `clip.exe`, `wl-copy` or `xclip`), open https://claude.ai/code/routines, give the user the settings above as form values, and wait for them to confirm.

This step is done when every routine exists and you have its ID and URL (`https://claude.ai/code/routines/<ID>`).

## 8. Save and smoke-test

1. Write `MOON_DIR/config.json`:

       {"queue_repo": "<login>/moonlight-queue", "queue_dir": "<MOON_DIR>/queue", "timezone": "America/New_York",
        "weekly_reset": "Thu 09:00", "stop_at": "Thu 07:00", "runs": ["Wed 23:00", "Thu 04:15"],
        "sleep": "23:00-07:00", "repos": ["owner/app"],
        "routines": [{"name": "Moonlight", "id": "...", "url": "..."}, {"name": "Moonlight (2nd run)", "id": "...", "url": "..."}],
        "statusline": true, "usage_credits": "off", "created": "2026-09-24"}

2. Offer a smoke test: start the first routine once now (RemoteTrigger `run`, or **Run now** on its page). It isn't the last night, so within a few minutes the run should add a "skipped" line to `NIGHTLY_LOG.md`, proving it can read and push the queue. It costs a little usage. `/moonlight:status` shows the result.

## 9. Finish

Tell the user, in a few lines:
- the next run's date and time;
- add tasks with `/moonlight:add <task>`, or by editing `QUEUE.md` on GitHub;
- results arrive as draft PRs (code) and files in `outputs/` (writing), summarized in `NIGHTLY_LOG.md`, and `/moonlight:status` shows them;
- **Run now** with the text `force` works the queue for up to 2 hours on any day;
- `/moonlight:uninstall` turns it off;
- if usage credits are still on, switch them off.
