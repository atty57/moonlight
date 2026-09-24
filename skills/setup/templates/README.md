# Moonlight queue

Private task queue for [Moonlight](https://github.com/atty57/moonlight). On the last night before your weekly usage resets, a cloud routine works through `QUEUE.md` while you sleep.

| File | What it is |
|---|---|
| `QUEUE.md` | Your tasks. Add them with `/moonlight:add` or edit the file here. |
| `NIGHTLY_LOG.md` | What each run did. |
| `outputs/` | Results of writing and research tasks (`repo: none`). |
| `moonlight.json` | Timezone, weekly reset and run times. `/moonlight:setup` keeps it in step with the routine. |

Code tasks come back as draft pull requests from `claude/moonlight-<ID>` branches in their own repos. This repo's default branch is `claude/queue` because cloud routines can always push to `claude/` branches.
