# Learning Primer

A living document that teaches your AI assistant how to teach *you* — plus two skills that
keep it up to date automatically.

Works with **Claude Code** and **opencode**.

## The problem

Every new conversation with an AI assistant starts from zero. It doesn't know that you
already understand pointers but not virtual memory, that you learn better from a hint than
from an answer, or that you keep making the same mistake about the same concept. So it
either talks down to you or over your head, and it hands you solutions when you wanted a
nudge.

A primer fixes that by being a single file you load at the start of a session. It records:

- **How you want to be taught** — scaffold vs. solve, quiz vs. lecture, how blunt to be.
- **What you already know**, tracked on a four-stage ladder from `New` to `Understood`.
- **Where you're going** — the goal that decides what's worth your time.
- **Anchor context** — your real projects and background, so examples aren't `foo`/`bar`.
- **Your recurring mistakes**, so they get flagged the moment they reappear.

The part that makes it stick: after a session, you feed the transcript back in and the
primer updates itself, promoting skills only when the transcript shows real evidence you've
earned it.

## How it works

```
begin-tutor  ──►  loads the primer, orients you, asks what you're learning
                             │
                     (you have the session)
                             │
                  export it to primer/transcripts/
                             │
update-primer ──►  reads the transcript, promotes skills on evidence,
                   logs new mistakes, reports exactly what moved
```

Two skills, one document. Everything the tool writes lives between
`<!-- ...:auto:start -->` / `<!-- ...:auto:end -->` markers. Everything outside those
markers is yours and is never touched.

## Quickstart

The whole path, start to finish. Each step below was run against a clean clone and
verified — see [Verification](#verification).

```bash
git clone https://github.com/connorwahlen-axeai/tutor-primer.git my-primer
cd my-primer
```

1. Fill in the `[TODO]` placeholders in Sections 1, 3, and 4 of
   `primer/learning-context.md`. (Details under [Install](#install).)
2. Open the folder in Claude Code or opencode and run `/begin-tutor`.
3. Have your session.
4. Save the conversation into `primer/transcripts/`.
5. Run `/update-primer --dry-run` to see what would change, then re-run without
   `--dry-run` to apply it.

**No configuration is required.** There is no `opencode.json` to write and no settings to
change — the skills and slash commands are picked up straight from the clone. A remote is
optional, and the tool also works from a plain ZIP download with no git repository at all.

## Install

Use this repo as a GitHub template, or clone it:

```bash
git clone https://github.com/connorwahlen-axeai/tutor-primer.git my-primer && cd my-primer
```

Then point it at your own remote so your primer syncs across machines (optional — a purely
local primer works fine, and the skills detect when there's no remote and skip all git
sync):

```bash
git remote set-url origin git@github.com:YOUR-USERNAME/my-primer.git
```

### Then fill in three sections

Open `primer/learning-context.md` and replace the `[TODO]` placeholders in:

1. **Section 1 — How to teach me.** The highest-leverage part of the file. The defaults are
   a reasonable start; edit them to match how you actually learn.
2. **Section 3 — Where I'm going.** Be concrete. This is what the assistant uses to decide
   what's worth your time.
3. **Section 4 — Anchor context.** Your environment, your projects, your day job. This is
   what turns generic examples into ones that land.

Leave Sections 2, 5, and 6 empty — they fill themselves in as you go.

## Usage

### Claude Code

Skills are picked up from `.claude/skills/` automatically:

```
/begin-tutor
```

and after you've saved a transcript into `primer/transcripts/`:

```
/update-primer
```

### opencode

Slash commands in `.opencode/command/` map to the same skills:

```
/begin-tutor
/update-primer
```

You can also just ask for them in plain language ("start a tutoring session") — opencode
exposes skills to the model as a `skill` tool, so it will pick the right one from the
description.

### Flags

`update-primer` takes optional arguments in both tools:

| Argument | Effect |
|---|---|
| *(none)* | Auto-select the newest transcript, preview the changes, ask before writing |
| `<path>` | Ingest a specific transcript instead of auto-selecting |
| `--dry-run` | Show the report and proposed edits; write, commit, and push nothing |
| `--apply` | Skip the confirmation and write immediately (still makes a backup) |
| `--no-push` | Pull, write, and commit, but leave the commit local |

Example:

```
/update-primer primer/transcripts/2026-07-20-topic.md --dry-run
```

## The mastery ladder

Skills move through four stages, and the tool will not promote one without evidence in the
transcript:

| Stage | Means |
|---|---|
| `New` | Added, not yet meaningfully engaged. |
| `Learning` | Actively working through it; asking questions, making mistakes. |
| `Applying` | Using it correctly, still with occasional prompting. |
| `Understood` | Can use **and** explain it unaided; self-corrects. |

`Understood` is deliberately hard to reach: you have to use the concept without help *and*
explain how it works, or catch your own error, or teach it back. Entries are tagged
`(evidence)` when the transcript demonstrates it, or `(self-reported)` when you simply said
you had it down.

The tool also **never silently demotes** a skill. If a transcript suggests you've regressed,
it flags it in the report and leaves the decision to you.

## Repository layout

```
.
├── .claude/skills/          # source of truth for both tools
│   ├── begin-tutor/SKILL.md
│   └── update-primer/SKILL.md
├── .opencode/
│   ├── skills/              # generated copy — run scripts/sync-skills.sh
│   └── command/             # slash-command wrappers for opencode
├── primer/
│   ├── learning-context.md  # the primer itself — this is the file you edit
│   ├── transcripts/         # drop exported conversations here
│   └── backups/             # automatic, gitignored
├── verification-test/       # record of the tool verified from a clean clone
└── scripts/sync-skills.sh
```

### Why the skills are duplicated

`.claude/skills/` is the source of truth. `.opencode/skills/` is a byte-identical copy kept
in sync by `scripts/sync-skills.sh`.

opencode *does* read `.claude/skills/` natively, so the copy looks redundant — but that
compatibility bridge is opt-out (`OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1`) and is dropped in
opencode's v2 rewrite, which only scans `.opencode/skill{,s}/`. Shipping real files in both
places means the tool keeps working either way. Symlinks were avoided on purpose: they
break on Windows and don't survive a ZIP download.

After editing anything under `.claude/skills/`, run:

```bash
./scripts/sync-skills.sh
```

Or verify without writing — suitable for CI:

```bash
./scripts/sync-skills.sh --check
```

**Known cosmetic wrinkle:** because both directories exist, opencode discovers each skill
twice and writes a `duplicate skill name` warning to its debug log. The files are identical,
so behavior is unaffected. Setting `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1` silences it.

## Optional: auto-load the primer in opencode

opencode can inject the primer into every session in this repo without you invoking
anything. Add an `opencode.json` at the repo root:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": ["primer/learning-context.md"]
}
```

This is off by default. `begin-tutor` loads the primer deliberately and gives you an
orientation summary, which is usually what you want; always-on loading spends context on
every session, including ones that have nothing to do with learning.

## Verification

The [`verification-test/`](verification-test/) folder holds a full record of the tool
being exercised from a clean clone: skill and slash-command discovery, `/begin-tutor` and
`/update-primer` end to end, `--dry-run` proven to write nothing, and the `--apply` write
path checked for backup, commit, and marker discipline. It also covers the no-remote and
no-git-at-all cases.

Everything there was run on opencode's free models with no credentials configured, which
is why the [Quickstart](#quickstart) can promise that a recipient needs no setup.

## Notes

- **Transcripts should be the whole conversation, not a summary.** The tool looks for
  evidence of how you engaged — where you were corrected, where you explained something
  back. Summaries strip exactly that signal.
- **Backups are automatic.** Every write copies the current primer to `primer/backups/`
  first. That directory is gitignored.
- **The primer works without either tool.** It's a plain Markdown file — paste it into any
  assistant's chat window and Section 1 still does its job.
