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

6. If the repo isn't in `repos`, add it to every Moonlight routine: RemoteTrigger `get`, then `update` with the repo's `https://github.com/owner/name` URL added to the routine's sources (load the tool with ToolSearch if it's deferred; failing that, ask the user to add it at https://claude.ai/code/routines). Then add it to `repos` in config.json.
7. Commit (`moonlight: add MOON-7 <title>`) and push; if the push is rejected, pull with rebase and push again.
8. Reply with the ID, the title and the next run's date and time.
