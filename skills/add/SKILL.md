---
name: add
description: Queue a task for Moonlight's overnight run. Use when the user asks to add work to Moonlight, or to get something done tonight or while they sleep.
argument-hint: "<what to do> [in owner/repo]"
---

# Queue a Moonlight task

Request: $ARGUMENTS

1. Read `moonlight/config.json` in the Claude config folder (`$CLAUDE_CONFIG_DIR`, otherwise `~/.claude`). If it's missing, tell the user to run `/moonlight:setup` and stop.
2. Pull the queue: `git -C <queue_dir> pull --rebase --quiet`.
3. Shape the request into a task an unattended run can finish in an hour or two:
   - **title**: a few words.
   - **repo**: `owner/name` from the request; else this folder's GitHub remote if it's in `repos`; else ask. Use `none` for writing or research.
   - **goal**: one or two specific sentences.
   - **done when**: a check someone could run or see: a command that passes, a file that exists, a behavior to verify. Draft it from the request (and, for code, a look at the repo); ask one short question only if you can't make it checkable.
   - **notes**: constraints and pointers, if any.

   If it's more than a night's work, propose splitting it and add the parts once the user agrees.
4. Take the ID `MOON-<next_id>` from the queue's `moonlight.json` and increment `next_id`.
5. Append the task to `QUEUE.md`, or put it above the other `todo` tasks if the user called it urgent:

       ## MOON-7: Add retries to the webhook sender
       - status: todo
       - repo: owner/name
       - goal: ...
       - done when: ...
       - notes: ...

6. If the repo isn't in `repos`, add it to every Moonlight routine with the RemoteTrigger tool (load it with ToolSearch if it's deferred; failing that, ask the user to add the repo at https://claude.ai/code/routines and skip to step 7):
   1. `get` the routine, then send `update` the **whole** `job_config` rebuilt from what you read — `environment_id`, `session_context` with its model, sources and allowed tools, and `events` with the prompt unchanged — with `https://github.com/owner/name` appended to the sources. Don't send the sources on their own: `update` is documented as a partial update at the top level, so a body holding only a nested `job_config.ccr.session_context.sources` may replace all of `job_config`. Note also that `get` returns the `session_request` shape, with the prompt under `events[].payload`, not the `job_config` shape that `update` takes.
   2. `get` again and check the prompt, model, allowed tools and existing sources all survived. If any of them are gone, restore them with another `update` before moving on.

   Then add the repo to `repos` in config.json.
7. Commit (`moonlight: add MOON-7 <title>`) and push; if the push is rejected, pull with rebase and push again.
8. Reply with the ID, the title and the next run's date and time.
