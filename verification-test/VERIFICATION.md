# Verification record — opencode

**Date:** 2026-07-26
**Commit under test:** `34d1d2e`
**opencode version:** 1.18.5 (CLI, matching the 1.18.5 desktop app)
**Model:** `opencode/nemotron-3-ultra-free` — a free-tier model, run with **zero
credentials configured**

Every check below was run against a throwaway clone of this repository at the commit above.
The purpose was to confirm one thing: that someone who is handed this repo can clone it and
use it without setup, guesswork, or a support conversation.

**Result: all 12 checks pass.**

---

## Summary

| # | Check | Result |
|---|---|---|
| 1 | `git clone` produces a complete tree | Pass — all 12 files present |
| 2 | `scripts/sync-skills.sh` executable bit survives the clone | Pass — `-rwxr-xr-x`, runs directly |
| 3 | `./scripts/sync-skills.sh --check` on an untouched clone | Pass — `skills in sync`, exit 0 |
| 4 | `.claude/skills` and `.opencode/skills` are byte-identical | Pass — `diff -r` clean |
| 5 | opencode discovers both skills | Pass — resolved from `.opencode/skills/` |
| 6 | opencode registers both slash commands | Pass — correct names and descriptions |
| 7 | `/begin-tutor` end to end | Pass |
| 8 | `/update-primer --dry-run` writes nothing | Pass — verified against git, not self-reported |
| 9 | `/update-primer --apply` write path | Pass — backup, commit, markers respected |
| 10 | Newest-transcript auto-selection on a fresh clone | Pass — correctly ignored `README.md` |
| 11 | Repository with no remote configured | Pass — skipped sync, committed locally |
| 12 | Plain directory with no git repository at all | Pass — fell back to project-wide search |

---

## 5 — Skill discovery

```
$ opencode debug skill
update-primer  -> <clone>/.opencode/skills/update-primer/SKILL.md
begin-tutor    -> <clone>/.opencode/skills/begin-tutor/SKILL.md
```

The "known cosmetic wrinkle" documented under
[Why the skills are duplicated](../README.md#why-the-skills-are-duplicated) is confirmed.
At `--log-level DEBUG`:

```
level=WARN message="duplicate skill name" name=update-primer
  existing=<clone>/.claude/skills/update-primer/SKILL.md
  duplicate=<clone>/.opencode/skills/update-primer/SKILL.md
```

The warning fires, resolution still succeeds, and the `.opencode/` copy wins. Behavior is
unaffected, exactly as the README claims.

## 6 — Slash-command registration

Both commands appear in opencode's command registry with the descriptions from their
front-matter, and with `$ARGUMENTS` correctly threaded into the `update-primer` template.

## 7 — `/begin-tutor`

The full chain ran in order, unprompted:

1. `skill({ name: "begin-tutor" })` invoked from the slash command
2. `git rev-parse --show-toplevel` — repo root resolved
3. `git remote` — remote found
4. `git pull --ff-only` — `Already up to date.`
5. Read `primer/learning-context.md`
6. Orientation given, message ended on exactly `What are we learning today?`

## 10 — The fresh-clone timestamp trap

This is the check most likely to catch a naive implementation, and it is worth calling out
for anyone adapting this repo.

A `git clone` stamps **every** file with checkout time. That means `primer/transcripts/README.md`
is always *newer* than any transcript a user drops in:

```
2026-07-20-abstract-syntax-trees.md   Jul 20 20:14   <- correct target
README.md                             Jul 26 18:07   <- newest by mtime
git-github-2026-07-19.md              Jul 19 23:38
```

A literal "newest file by mtime" rule would pick `README.md` and try to ingest it as a
transcript. The skill correctly selected the abstract-syntax-trees transcript instead.

## 8 — `--dry-run` is genuinely dry

Confirmed by inspecting the repository afterwards rather than trusting the run's own report:

- `git diff -- primer/learning-context.md` → empty
- `primer/backups/` → still only `.gitkeep`
- `git log origin/main..HEAD` → empty

## 9 — `--apply` write path

The remote was removed before this run, so pushing was impossible rather than merely
discouraged.

- Backup written to `primer/backups/learning-context.md.<timestamp>.bak`
- Commit created: `Update primer from abstract-syntax-trees session`
- Diff: 14 insertions, 1 deletion — all inside the `tracks:`, `skills:`, and `traps:` auto
  markers, plus the `**Recently mastered:**` line, which `update-primer/SKILL.md` explicitly
  lists as auto-managed
- The `[TODO]` placeholders in Sections 1, 3, and 4 were untouched

## 11 and 12 — Degraded environments

| Environment | Behavior |
|---|---|
| Git repo, no remote | `git remote` returned empty; the skill skipped all sync and committed locally, as documented |
| No git repo at all (ZIP-style extract) | `begin-tutor` first tried the primer path relative to `SKILL.md`, failed, then self-corrected via its documented fallback (`Glob **/learning-context.md`), handled `git remote` erroring out cleanly, and finished normally |

The executable bit on `scripts/sync-skills.sh` also survives a `git archive` extract, so a
ZIP download stays usable.

---

## Known limitation: weak models drift outside the markers

Both issues below came from the free-tier model used for these runs. They are model-quality
limits, not packaging defects — the tool installed and ran correctly in every case. They are
recorded here because they happened on a real run, and because anyone running this on a
small or free model should expect them.

1. **Stray text written outside the auto markers.** The `--apply` run appended
   `(End of file - total 119 lines)` to the end of the primer and stripped the trailing
   newline. `update-primer/SKILL.md` says plainly: never edit outside the markers. The model
   did anyway.
2. **The `Recently mastered` cap was ignored.** The skill specifies up to the last 3 entries,
   newest first, each with its date. The model wrote 4 entries with no dates.

Neither affects whether the tool installs, is discovered, or runs. If you intend to drive
this with a small model, expect to tighten those two instructions.

---

## Reproducing this

With the opencode CLI installed:

```bash
git clone https://github.com/connorwahlen-axeai/tutor-primer.git verify && cd verify
opencode debug skill                    # check 5 — skill discovery
./scripts/sync-skills.sh --check        # check 3 — skills in sync
opencode run "/begin-tutor" --model opencode/nemotron-3-ultra-free
```

For the `update-primer` checks, drop a transcript into `primer/transcripts/` first. Use
`--dry-run` before `--apply`, and remove the remote (`git remote remove origin`) if you want
a guarantee that nothing can be pushed.
