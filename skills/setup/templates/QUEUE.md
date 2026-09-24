# Moonlight queue

On the last night before your weekly usage resets, Moonlight works through these tasks from top to bottom. Add tasks with `/moonlight:add`, or edit this file directly (the GitHub mobile app works).

Moonlight changes only the `status` lines: `todo` → `wip since <time>` → `pr <link>` for code, `done <file>` for writing and research, or `blocked — <question>`. To answer a blocked task, put your answer in its `notes` and set `status` back to `todo`. Delete tasks once you've merged or used the result.

<!--
To add a task by hand, copy this block below the last task. You can leave out the ID
(write "## Short title") and Moonlight will number it.

## MOON-1: Short title
- status: todo
- repo: owner/name, or none for writing and research (results go to outputs/)
- goal: What to do, in a sentence or two.
- done when: Something checkable, e.g. `pytest tests/api` passes.
- notes: Constraints, files to look at, what to avoid. Optional.
-->
