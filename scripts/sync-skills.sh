#!/usr/bin/env bash
# Sync skills from .claude/skills/ (the source of truth) into .opencode/skills/.
#
# The two directories hold identical files on purpose. Claude Code reads
# .claude/skills/; opencode reads both, but only .opencode/skills/ is guaranteed
# to keep working (its .claude compatibility bridge is opt-out via
# OPENCODE_DISABLE_CLAUDE_CODE_SKILLS and is dropped in the v2 rewrite).
#
# Run this after editing anything under .claude/skills/.
# Pass --check to verify they match without writing (useful in CI).

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
src="$root/.claude/skills"
dst="$root/.opencode/skills"

if [ ! -d "$src" ]; then
  echo "error: $src does not exist" >&2
  exit 1
fi

if [ "${1:-}" = "--check" ]; then
  if diff -r "$src" "$dst" >/dev/null 2>&1; then
    echo "skills in sync"
    exit 0
  fi
  echo "error: .claude/skills and .opencode/skills have drifted:" >&2
  diff -r "$src" "$dst" >&2 || true
  echo >&2
  echo "run scripts/sync-skills.sh to fix" >&2
  exit 1
fi

rm -rf "$dst"
mkdir -p "$dst"
cp -R "$src/." "$dst/"
echo "synced $src -> $dst"
