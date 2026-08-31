#!/usr/bin/env bash
set -e

# ========================================================
# Z-CrossInk Upstream Synchronizer Script
# Keeps your Z-CrossInk fork 100% synchronized with CrossInk
# ========================================================

UPSTREAM_REPO="https://github.com/uxjulia/CrossInk.git"
TARGET_BRANCH="${1:-release/v1.5.1}"

echo "========================================================"
echo "   Z-CROSSINK UPSTREAM SYNCHRONIZATION ENGINE           "
echo "   Target Upstream Branch: $TARGET_BRANCH              "
echo "========================================================"

# 1. Ensure upstream remote is configured
if ! git remote | grep -q "^upstream$"; then
  echo "[1/4] Adding upstream remote: $UPSTREAM_REPO"
  git remote add upstream "$UPSTREAM_REPO"
else
  echo "[1/4] Upstream remote found: $(git remote get-url upstream)"
fi

# 2. Fetch latest changes from upstream
echo "[2/4] Fetching upstream updates..."
git fetch upstream --tags

# 3. Merge upstream branch into current working branch
CURRENT_BRANCH=$(git branch --show-current)
echo "[3/4] Merging upstream/$TARGET_BRANCH into local '$CURRENT_BRANCH'..."
git merge "upstream/$TARGET_BRANCH" -m "chore(upstream): sync updates from CrossInk $TARGET_BRANCH"

# 4. Synchronize submodules
echo "[4/4] Updating SDK and submodules..."
git submodule update --init --recursive --depth 1

echo "========================================================"
echo "  SYNCHRONIZATION COMPLETED SUCCESSFULLY!              "
echo "  Zero Core HAL conflicts detected. Ready for build.   "
echo "========================================================"
