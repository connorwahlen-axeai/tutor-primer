---
description: Update the learning primer from a saved conversation transcript
---

Invoke the `update-primer` skill now — call `skill({ name: "update-primer" })` — and
follow its instructions exactly, start to finish.

Arguments passed to this command: `$ARGUMENTS`

Interpret them as the skill's documented inputs:

- A bare path (e.g. `primer/transcripts/2026-07-20-topic.md`) overrides transcript
  auto-selection.
- `--dry-run`, `--apply`, and `--no-push` are the skill's flags.
- **If the argument line above is empty, no arguments were given** — use the skill's
  default behavior: auto-select the newest transcript by mtime and use
  preview-then-confirm before writing.

Do not summarize the skill or describe what it would do. Actually run it, and end with the
change report in the format the skill specifies.
