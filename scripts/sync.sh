#!/usr/bin/env bash
# sync.sh — Copy all skills from this repo into a target project repo
# Usage: ./scripts/sync.sh <path-to-target-repo>
# Example: ./scripts/sync.sh ../sdlc-fe

set -e

TARGET="$1"

if [ -z "$TARGET" ]; then
  echo "Usage: ./scripts/sync.sh <path-to-target-repo>"
  exit 1
fi

if [ ! -d "$TARGET" ]; then
  echo "Error: target directory '$TARGET' does not exist"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/../skills"
DEST="$TARGET/.claude/skills"

mkdir -p "$DEST"

echo "Syncing skills from $(basename $SCRIPT_DIR/..)"
echo "→ $DEST"
echo ""

COUNT=0
for skill_dir in "$SKILLS_DIR"/*/; do
  skill_name="$(basename "$skill_dir")"
  rm -rf "$DEST/$skill_name"
  cp -r "$skill_dir" "$DEST/$skill_name"
  echo "  ✓ $skill_name"
  COUNT=$((COUNT + 1))
done

echo ""
echo "Done — $COUNT skills synced to $TARGET"
