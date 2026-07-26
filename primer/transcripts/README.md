# Transcripts

Drop exported conversation transcripts here as `.md` files. The `update-primer` skill
reads them to work out what you actually learned.

## How it picks one

With no arguments, `update-primer` selects the **most recently modified `.md` file** in
this directory and ignores this README. So the normal workflow is just: export a
conversation into this folder, then run the skill.

Naming is up to you — `2026-07-20-topic.md` and `topic-2026-07-20.md` both work, since
selection is by modification time, not by filename. A date in the name is still worth
having for your own sake.

To ingest a specific file instead, pass its path:

```
update-primer primer/transcripts/2026-07-20-topic.md
```

## What makes a good transcript

The whole conversation, not a summary. The skill looks for evidence of *how* you engaged —
where you were corrected, where you explained something back correctly, where you got
something right unaided. A summary strips exactly the signal it needs to decide whether
something moved from `Learning` to `Applying` to `Understood`.

## A note on contents

These are raw exports and may contain anything you discussed. If this repo is public, or
if you'd rather not version them, uncomment the transcript lines in `.gitignore` — the
primer itself will still record what you learned.
