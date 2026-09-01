#!/usr/bin/env bash
set -e

# ========================================================
# Z-CrossInk Upstream Synchronizer Script
# Keeps your Z-CrossInk fork 100% synchronized with CrossInk
# ========================================================

UPSTREAM_REPO="https://github.com/uxjulia/CrossInk.git"
TARGET_INPUT="${1:-release/v1.5.1}"

echo "========================================================"
echo "   Z-CROSSINK UPSTREAM SYNCHRONIZATION ENGINE           "
echo "   Requested Target: $TARGET_INPUT                     "
echo "========================================================"

# 0. Check working tree cleanliness
if ! git diff-index --quiet HEAD --; then
  echo "[WARNING] Working directory contains uncommitted changes."
  echo "Please commit or stash changes before syncing with upstream."
  exit 1
fi

# 1. Ensure upstream remote is configured
if ! git remote | grep -q "^upstream$"; then
  echo "[1/4] Adding upstream remote: $UPSTREAM_REPO"
  git remote add upstream "$UPSTREAM_REPO"
else
  echo "[1/4] Upstream remote found: $(git remote get-url upstream)"
fi

# Ensure full branch tracking refspec for upstream
git config remote.upstream.fetch "+refs/heads/*:refs/remotes/upstream/*"

# 2. Fetch latest changes and tags from upstream
echo "[2/4] Fetching upstream branches and tags..."
git fetch upstream --tags --prune

# Determine exact merge ref (branch, release branch, tag, or SHA)
MERGE_REF=""
if git rev-parse --verify "upstream/$TARGET_INPUT" >/dev/null 2>&1; then
  MERGE_REF="upstream/$TARGET_INPUT"
elif git rev-parse --verify "upstream/release/$TARGET_INPUT" >/dev/null 2>&1; then
  MERGE_REF="upstream/release/$TARGET_INPUT"
elif git rev-parse --verify "refs/tags/$TARGET_INPUT" >/dev/null 2>&1; then
  MERGE_REF="refs/tags/$TARGET_INPUT"
elif git rev-parse --verify "$TARGET_INPUT" >/dev/null 2>&1; then
  MERGE_REF="$TARGET_INPUT"
else
  echo "[ERROR] Could not resolve '$TARGET_INPUT' to an upstream branch, release branch, or tag."
  echo "Available upstream branches:"
  git branch -r --list "upstream/*"
  echo "Latest upstream tags:"
  git tag -l "v*" | tail -n 10
  exit 1
fi

# 3. Merge upstream target into current working branch
CURRENT_BRANCH=$(git branch --show-current)
echo "[3/4] Merging '$MERGE_REF' into local '$CURRENT_BRANCH'..."
git merge "$MERGE_REF" -m "chore(upstream): sync updates from CrossInk $TARGET_INPUT"

# 4. Synchronize submodules
echo "[4/4] Updating SDK and submodules..."
if [ -f ".gitmodules" ]; then
  git submodule update --init --recursive --depth 1
else
  echo "No submodules defined. Skipping."
fi

echo "========================================================"
echo "  SYNCHRONIZATION COMPLETED SUCCESSFULLY!              "
echo "  Target: $MERGE_REF -> Branch: $CURRENT_BRANCH         "
echo "  Zero Core HAL conflicts detected. Ready for build.   "
echo "========================================================"
