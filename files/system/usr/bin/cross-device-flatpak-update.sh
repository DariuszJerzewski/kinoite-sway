#!/usr/bin/env bash
set -euo pipefail

SYNC_ROOT="/var/lib/kinoite-sway-config/sync"
REPO_DIR="$SYNC_ROOT/repo"
STATE_FILE="$SYNC_ROOT/last-synced.txt"

REPO_URL="git@github.com:DariuszJerzewski/cross-device-os-sync.git"
BRANCH="main"
LIST_FILE="flatpak-pkgs.txt"

LOCK_FILE="/run/lock/cross-device-flatpak-push.lock"

mkdir -p "$SYNC_ROOT"

# Get hold of lock file, otherwise exit
exec 9>"$LOCK_FILE"
flock -n 9 || exit 0

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

CURRENT="$tmpdir/current.txt"
REMOTE="$tmpdir/remote.txt"
ADDED="$tmpdir/added.txt"
REMOVED="$tmpdir/removed.txt"
NEW_LIST="$tmpdir/new-list.txt"

# Current system-wide Flatpak applications.
flatpak list \
    --system \
    --app \
    --columns=application,origin \
    | awk '$2 == "flathub" { print $1 }' \
    | sed '/^[[:space:]]*$/d' \
    | sort -u > "$CURRENT"

# Clone repository if necessary.
if [[ ! -d "$REPO_DIR/.git" ]]; then
    rm -rf "$REPO_DIR"

    git clone \
        --branch "$BRANCH" \
        "$REPO_URL" \
        "$REPO_DIR"
else
    git -C "$REPO_DIR" fetch origin "$BRANCH" --prune
    git -C "$REPO_DIR" checkout "$BRANCH"
    git -C "$REPO_DIR" reset --hard "origin/$BRANCH"
fi

# Latest version from Git.
if [[ -f "$REPO_DIR/$LIST_FILE" ]]; then
    sort -u "$REPO_DIR/$LIST_FILE" > "$REMOTE"
else
    : > "$REMOTE"
fi

if [[ ! -f "$STATE_FILE" ]]; then
    cp "$CURRENT" "$STATE_FILE"
    exit 0
fi

LAST="$STATE_FILE"

# What changed locally since our last successful sync?
comm -13 <(sort -u "$LAST") "$CURRENT" > "$ADDED"
comm -23 <(sort -u "$LAST") "$CURRENT" > "$REMOVED"

# Nothing changed locally. Update our snapshot and we're done.
if [[ ! -s "$ADDED" && ! -s "$REMOVED" ]]; then
    cp "$CURRENT" "$STATE_FILE"
    exit 0
fi

# Apply our local changes on top of the latest repository state.
#
# This is the important bit:
#   repo + local additions - local removals
#
# So changes from other machines are preserved.
{
    cat "$REMOTE"
    cat "$ADDED"
} | sort -u > "$tmpdir/merged.txt"

comm -23 \
    "$tmpdir/merged.txt" \
    <(sort -u "$REMOVED") \
    > "$NEW_LIST"

# Only modify Git if the resulting package list is actually different.
if cmp -s "$NEW_LIST" "$REMOTE"; then
    cp "$CURRENT" "$STATE_FILE"
    exit 0
fi

cp "$NEW_LIST" "$REPO_DIR/$LIST_FILE"

git -C "$REPO_DIR" add "$LIST_FILE"

HOST="$(hostnamectl --static 2>/dev/null || hostname)"

git -C "$REPO_DIR" \
    -c user.name="Flatpak Sync" \
    -c user.email="flatpak-sync@localhost" \
    commit \
    -m "Sync Flatpak packages from $HOST"

# Do not update STATE_FILE until the push succeeds.
#
# If another machine pushed between our fetch and this push,
# this fails. The old STATE_FILE remains, so the next timer/path
# invocation will retry against the newer repository state.
git -C "$REPO_DIR" push origin "$BRANCH"

cp "$CURRENT" "$STATE_FILE"
