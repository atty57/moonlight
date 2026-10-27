---
name: uninstall
description: Turn Moonlight off - switch off its routine, restore your status line and remove its local files. Your queue repo stays.
disable-model-invocation: true
---

# Uninstall Moonlight

Confirm with the user, then:

1. **Routines**: read `moonlight/config.json` in the Claude config folder (`$CLAUDE_CONFIG_DIR`, otherwise `~/.claude`). If it's missing, say no routine IDs are recorded, point the user to https://claude.ai/code/routines to switch off and delete any Moonlight routines there, and continue to step 2. Otherwise, Claude Code can't delete routines, so switch each listed routine off with the RemoteTrigger tool's `update` action and `{"enabled": false}` (load the tool with ToolSearch if it's deferred). Then give the user each routine's link, `https://claude.ai/code/routines/<ID>`, to delete it there.
2. **Status line**: do this even if `config.json` is missing; it needs only `settings.json` and `moonlight/statusline.original.json`. If `statusLine.command` in `settings.json` points at Moonlight's `statusline.sh`, restore the saved object to the `statusLine` key if the backup exists, otherwise remove that key. Every other setting stays as it is.
3. **Local files**: if the queue clone in `moonlight/queue` has unpushed commits, push them first. Then remove the `moonlight/` folder.
4. Tell the user the queue repo stays on GitHub (`gh repo delete <queue_repo>` removes it), and to finish with `/plugin uninstall moonlight@moonlight`.
