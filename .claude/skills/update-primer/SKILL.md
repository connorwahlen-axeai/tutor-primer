---
name: update-primer
description: Update the user's learning primer (primer/learning-context.md) from a saved conversation transcript. Reads a transcript file, updates the auto-managed Tracks, Skills, and Traps sections with evidence-based mastery progression, adds newly-seen skills, records recurring mistakes, and reports what changed. Invoke when the user wants to refresh/update the primer or learning context after a conversation.
---

# update-primer

Update the living learning primer from a saved conversation transcript. You read a
transcript the user exported from another chat (Claude, ChatGPT, Gemini, etc.), compare it
against the current primer, and rewrite only the auto-managed sections.

## Inputs

- **Argument (optional):** a path to the transcript file to ingest
  (e.g. `primer/transcripts/2026-07-15-sorting-algorithms.md`). Pass one only to
  **override** the automatic pick.
  - **If no path is given — the normal case — auto-select the transcript by recency**
    (see "Selecting the transcript" below). Do **not** list files and ask the user which to
    use; the whole point is that the skill runs unattended.
- **Flags (optional):**
  - `--dry-run` — show the change report and proposed edits but write nothing. Do **not**
    pull, write, commit, or push; instead `git fetch` and note in the report whether the
    branch is behind its upstream.
  - `--apply` — skip the confirmation step and write immediately (still make a backup).
    Pull first, then write, then commit and push.
  - `--no-push` — do everything (pull, write, commit) but skip the final push, leaving the
    commit local. Combine with any mode.
  - Default (no flag) — **preview-then-confirm**: pull first, show the report and proposed
    edits, then ask the user to confirm before writing. On confirmation, write, commit,
    and push.

## Selecting the transcript

When no path argument is given (the default), pick the transcript to ingest automatically
— no prompting:

1. List the regular files in `primer/transcripts/`.
2. Exclude non-transcripts: `README.md`, dotfiles, and anything that isn't a `.md`
   transcript.
3. Choose the file with the **most recent modification time (mtime)** — the one closest to
   now. This is intentionally naming-agnostic: it doesn't matter whether the date sits at
   the front (`2026-07-20-topic.md`) or back (`topic-2026-07-20.md`) of the name, or is
   absent entirely.
4. Tie-break (rare): prefer the newer `YYYY-MM-DD` embedded in the filename, then fall back
   to alphabetical order. Any deterministic choice is acceptable.
5. If the directory has no eligible transcript, **stop and report** — never invent one.

Resolve it in one command from the repo root, e.g.:

```
ls -t primer/transcripts/*.md | grep -v '/README\.md$' | head -1
```

`ls -t` orders by mtime (newest first), so `head -1` is the pick. Always **name the file
you selected** at the top of the change report so the user can confirm the right transcript
was ingested. Auto-selection only chooses the file — it does **not** bypass the
preview-then-confirm gate before writing.

## The primer file

Target: `primer/learning-context.md`, relative to the **repo root** — the top level of the
git repository that contains this skill. Resolve it with `git rev-parse --show-toplevel`;
if that fails (not a git repo), use the directory the user opened the assistant in. If it
isn't at that relative path, search the project for `learning-context.md` before doing
anything else. Read it fully before making any edits.

## Git sync (pull before, push after — only if a remote exists)

The primer is often kept in a git repo synced across machines. To keep versions consistent
and avoid merge conflicts, **pull before touching the file and push after a successful
write.** Run all git commands from the repo root.

**First, check whether a remote is configured: `git remote`. If there is no remote, skip
every pull and push step below** — make the backup, write the file, and commit locally (a
local-only primer is a normal setup). Say so in the change report. If the directory isn't a
git repo at all, skip commits too and just back up and write.

### Before any work — pull

1. Confirm the current branch has an upstream (`git rev-parse --abbrev-ref '@{u}'`). If it
   has none, note it, skip the pull, and continue.
2. Check for uncommitted changes to the primer
   (`git status --porcelain -- primer/learning-context.md`). If it's already dirty, **stop
   and report** — don't pull over unsaved edits. (Ignored backups don't count and won't
   block.)
3. Pull fast-forward only: `git pull --ff-only`.
   - Success (fast-forward or already up to date): proceed.
   - Fails because the branch **diverged** (local commits + remote commits): stop and
     report. Do not auto-merge or rebase; let the user reconcile.
   - Fails for network/auth reasons: stop and report the error. Don't proceed on a
     possibly-stale file.
4. Under `--dry-run`, replace the pull with `git fetch` and just note whether the branch is
   behind its upstream — never mutate the working tree in dry-run.

### After a successful write — commit and push

1. Stage only the primer: `git add primer/learning-context.md`. Never `git add -A` —
   backups are gitignored and unrelated working-tree changes must not ride along.
2. Commit with a message in this style:
   `Update primer from <transcript-topic> session (<YYYY-MM-DD>)`
   (e.g. `Update primer from sorting-algorithms session (2026-07-19)`).
3. Push: `git push`. If push is **rejected** because the remote moved ahead since the pull,
   report it and suggest re-running (which will pull the new commits first) — don't
   force-push.
4. Skip commit and push entirely under `--dry-run`. Under `--no-push`, still commit locally
   and tell the user the commit is unpushed.

If any git step fails, report exactly what failed and stop — never silently swallow a
pull/push error, since that's what version control is here to prevent.

## What you may edit — and what you must never touch

Only rewrite content **between** these marker pairs:

- `<!-- tracks:auto:start -->` … `<!-- tracks:auto:end -->` (Section 2, Tracks table)
- `<!-- skills:auto:start -->` … `<!-- skills:auto:end -->` (Section 5, Skills table)
- `<!-- traps:auto:start -->` … `<!-- traps:auto:end -->` (Section 6, recurring mistakes)
- The **Recently mastered:** line at the top of Section 5.

Everything else is hand-owned — Section 1 (teaching prefs), Section 3 (goals), Section 4
(anchor context), the stage legend, the typo list in Section 6, and all prose. Never edit
outside the markers. Never move, rename, or delete the markers themselves. Preserve the
existing table columns and formatting exactly.

If the tables inside the markers are empty (a fresh copy of the template), that's expected
— just add the first rows. Keep the header row and its `|---|` separator.

## Mastery model

Stage ladder: `New` → `Learning` → `Applying` → `Understood`.

- `New` — added, not yet meaningfully engaged.
- `Learning` — actively working through it; asking questions, making mistakes.
- `Applying` — using it correctly, still with occasional prompting/correction.
- `Understood` — can use **and** explain it unaided; self-corrects.

### Rules for changing a stage

1. **Evidence-based by default.** Only promote a skill when the transcript shows concrete
   evidence for the next stage:
   - → `Learning`: the user engaged with the topic (asked about it, attempted it).
   - → `Applying`: the user applied it correctly, possibly with some prompting.
   - → `Understood`: the user used it unaided **and** explained it / caught their own error
     / taught it back. Explaining *how it works*, not just getting a right answer.

   Tag every `Understood` entry with `(evidence)`.
2. **Explicit self-report overrides.** If the user plainly states a mastery level in the
   transcript ("I've got X down now", "I finally understand Y"), honor it — set that stage
   and, if it lands on Understood, tag it `(self-reported)` instead of `(evidence)`. This
   is the only case where you set a stage without demonstrated evidence.
3. **Never silently demote.** If the transcript suggests a regression (the user now
   struggles with something previously higher), do **not** lower the stage on your own —
   flag it in the change report and let the user decide.
4. **Only promote one stage at a time** unless a self-report jumps further.

### Adding new skills

- A topic the user genuinely engaged with that isn't already listed → add a new row with
  the right stage, a one-line evidence note, and today's date.
- **Check for duplicates first.** Match against existing rows (including close paraphrases)
  so you don't add a near-copy of something already tracked. If it's the same underlying
  skill, update the existing row instead of adding one.
- New broad *efforts/areas* belong in the **Tracks** table; atomic, testable *concepts*
  belong in the **Skills** table. When unsure, prefer Skills.

## Dates

Get the real current date at run time (`date +%F`). Stamp the **Last touched** column with
that date for any track or skill that appeared in this transcript. Leave the date unchanged
for rows the transcript didn't touch. Replace any `(seed)` marker with the real date once a
row is genuinely touched.

## Recently mastered

After processing, set the **Recently mastered:** line in Section 5 to the skills that
reached `Understood` in this run, keeping up to the last 3 (newest first), each with its
date. If nothing new was mastered, leave the existing line as-is.

## Recurring mistakes

If the transcript shows a mistake — especially a repeated one — that isn't already in the
traps auto region, append a short bullet describing the pattern so it can be flagged in
future sessions. Don't duplicate existing bullets. Never touch the hand-owned typo list
below the markers.

## Procedure

1. **Sync (pull):** follow the "Before any work — pull" steps in the Git sync section
   (skipping them entirely if there's no remote). Stop and report if the repo is dirty,
   diverged, or the pull fails. (Dry-run: `git fetch` and note behind/ahead status instead
   of pulling.)
2. **Select the transcript:** if a path argument was given, use it; otherwise auto-pick the
   most-recently-modified transcript per "Selecting the transcript". Resolve and read the
   primer file. Read the chosen transcript file.
3. Work out the changes: track/skill promotions, new rows, date stamps, recently-mastered,
   recurring mistakes — following the rules above.
4. Build the **change report** (format below).
5. **Backup:** before writing, copy the current primer to
   `primer/backups/learning-context.<YYYY-MM-DD-HHMMSS>.bak.md`. Create the `backups/`
   directory if it doesn't exist. (Skip the backup only under `--dry-run`.)
6. Apply per the flag:
   - `--dry-run`: print the report + the proposed new content of each changed region; write
     nothing, commit nothing, push nothing.
   - default: print the report + proposed edits, then **ask the user to confirm**. On
     confirmation, make the backup and write. On decline, change nothing.
   - `--apply`: make the backup and write immediately, then print the report.
7. Only ever rewrite content between the markers; leave the rest byte-for-byte intact.
8. **Sync (push):** after a successful write, follow the "After a successful write — commit
   and push" steps (staging only the primer). Skip under `--dry-run` and `--no-push`, or if
   there's no remote. Report the result in the change report.

## Change report format

```
Primer update — <transcript filename> (<date>)

📄 Ingested   <transcript filename>  (<auto-selected: newest by mtime | path given>)
⇣ Pulled     <upstream> (<up to date | fast-forwarded N commits | no remote — local only>)
✎ Promoted   "<skill>"  <old stage> → <new stage>   (<why, from transcript>)
＋ Added      "<skill>"  (<stage>)   (<why>)
✓ Mastered   "<skill>"  → Understood (<evidence|self-reported>)
⚠ Possible regression  "<skill>"  (<what you saw>) — left unchanged, your call
⧗ Recurring mistake logged: "<pattern>"
· Unchanged  <n> tracked skills not touched this session
⇡ Pushed     <commit sha> to <upstream>   (or: commit left local under --no-push)
```

Only include lines that apply. Keep it short and skimmable — this report is the main way
the user learns what moved and whether they've reached understanding of something.
