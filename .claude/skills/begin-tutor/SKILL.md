---
name: begin-tutor
description: Start a tutoring session from the user's learning primer. Syncs the primer from its git remote if one exists, loads primer/learning-context.md into the conversation as context, then asks "What are we learning today?" to begin. Invoke when the user wants to start learning, begin a tutoring session, or kick off a study session.
---

# begin-tutor

Open a tutoring session grounded in the living learning primer. You sync the primer (if it
has a git remote), read it into context so you know where the user stands on every track
and skill, then hand the floor back with a single opening question. This skill is
**read-only** with respect to the primer — it never edits, commits, or pushes the doc.
(Recording progress afterward is the separate `update-primer` skill's job.)

## The primer file

Target: `primer/learning-context.md`, relative to the **repo root** — the top level of the
git repository that contains this skill. Resolve it with `git rev-parse --show-toplevel`;
if that fails (not a git repo), use the directory the user opened the assistant in. This
keeps the skill portable across machines and OSes regardless of absolute path.

If the file isn't at that relative path, search the project for `learning-context.md`
before doing anything else. Some users keep it elsewhere or rename the folder.

## Git sync (pull only, and only if a remote exists)

The primer is often kept in a git repo synced across machines. Pull the latest before
loading it so the session starts from the current version. Run all git commands from the
repo root.

1. Check whether a remote is configured at all: `git remote`. **If there is no remote,
   skip this entire section** and go straight to loading the primer — a purely local
   primer is a perfectly normal setup, and there is nothing to sync.
2. If a remote exists, confirm the current branch has an upstream
   (`git rev-parse --abbrev-ref '@{u}'`). If it has none, note that and continue with the
   local copy — don't guess a remote or branch.
3. Pull fast-forward only: `git pull --ff-only`.
   - Success (fast-forward or already up to date): proceed.
   - Fails because the branch **diverged**, or for network/auth reasons: **don't block the
     session.** Note the failure in one line, then continue with the local copy so learning
     can still start. (This skill makes no commits, so a stale local copy is the only risk,
     and it's recoverable.)
4. Never merge, rebase, force, commit, or push here. Pull is the only git write.

## Procedure

1. **Sync (pull):** follow the Git sync steps above. One line of acknowledgement is enough
   ("Pulled latest primer" / "No remote configured — using local copy" / "Couldn't reach
   origin — using local copy").
2. **Load the primer:** read `primer/learning-context.md` in full so its Tracks, Skills,
   goals, teaching preferences, and recurring-mistake notes are all in context for the rest
   of the session. Actually read the file — don't rely on memory from a prior run.
3. **Orient (brief):** give the user a short, skimmable snapshot so they know you're loaded
   and where things stand. Keep it tight — a few lines, not a wall of text:
   - Anything marked **Recently mastered**.
   - 2–4 skills currently in `Learning`/`Applying` (the natural things to push on next).
   - Any recurring-mistake / trap notes worth keeping front of mind this session.

   Honor the teaching preferences in Section 1 of the primer when framing all of this.

   **If the primer is still blank** (empty tables, `[TODO]` placeholders — i.e. a fresh
   copy of the template), skip the snapshot. Instead say so plainly and offer to help fill
   in Section 1 (how to teach me), Section 3 (goals), and Section 4 (anchor context),
   since those three are hand-owned and drive everything else. Then continue to step 4.
4. **Hand off:** end your opening message with exactly the question:

   > What are we learning today?

   Then stop and wait for the user's answer — don't pick a topic for them or start teaching
   until they respond.

## Notes

- If the primer can't be found at all, say so plainly and ask where it lives rather than
  inventing content.
- This skill only starts the session. When the session is done and the user wants to record
  progress, that's `update-primer` (which handles its own pull, write, commit, and push).
