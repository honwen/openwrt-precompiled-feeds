#!/bin/bash
#
# update.sh - Auto-check and upgrade versions in OpenWrt precompiled feed Makefiles
#
# Copyright (C) 2026 honwen <https://github.com/honwen>
#
# Usage:
#   ./update.sh                     # Check all packages for updates (dry-run)
#   ./update.sh --update            # Apply updates to all outdated packages
#   ./update.sh --pkg clash         # Check/update a specific package only
#   ./update.sh --update --pkg xray
#   ./update.sh --commit            # Check + auto-commit each update
#   ./update.sh --update --commit   # Update all + commit
#   ./update.sh --lock xray-plugin  # Pin a package (skip in future scans)
#   ./update.sh --unlock xray-plugin
#
# GitHub API token (optional, avoids rate limits):
#   export GITHUB_TOKEN=ghp_xxxx
#

set -euo pipefail

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCK_FILE="${BASE_DIR}/.version-locks"
GITHUB_API="https://api.github.com"
TODAY="$(date +%Y%m%d)"
TODAY_DASH="$(date +%Y-%m-%d)"

# ─── colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── version lock ──────────────────────────────────────────────────────────────
# Lock file: one package per line, format: "<pkg_name> [optional: =<version>]"
# Load current locks into associative array
declare -A VERSION_LOCKS
load_locks() {
    VERSION_LOCKS=()
    if [[ -f "$LOCK_FILE" ]]; then
        while IFS= read -r line; do
            line="${line%%#*}"       # strip comments
            line="$(echo "$line" | xargs)"  # trim
            [[ -z "$line" ]] && continue
            local name="${line%%=*}"
            local ver="${line#*=}"
            [[ "$name" == "$ver" ]] && ver="*"  # no '=', match any version
            VERSION_LOCKS["$name"]="$ver"
        done < "$LOCK_FILE"
    fi
}

# Check if a package is locked. Returns 0 (locked) if:
#   - package name is in VERSION_LOCKS with value "*" → locked at any version
#   - package name is in VERSION_LOCKS with a specific version → only locked at that version
is_locked() {
    local name="$1" current_ver="$2"
    local locked_ver="${VERSION_LOCKS[$name]:-}"
    [[ -z "$locked_ver" ]] && return 1         # not locked
    [[ "$locked_ver" == "*" ]] && return 0     # locked at any version
    [[ "$locked_ver" == "$current_ver" ]] && return 0  # locked at this specific version
    return 1  # locked at a different version → allow update
}

lock_pkg() {
    local name="$1" ver="${2:-}"
    local entry="$name"
    [[ -n "$ver" ]] && entry="${name}=${ver}"

    # Deduplicate: remove existing entry for this package, then append
    if [[ -f "$LOCK_FILE" ]]; then
        grep -v "^${name}=" "$LOCK_FILE" | grep -v "^${name}$" > "${LOCK_FILE}.tmp" && mv "${LOCK_FILE}.tmp" "$LOCK_FILE"
    fi
    echo "$entry" >> "$LOCK_FILE"
    echo -e "${GREEN}locked${NC}  ${name}$([ -n "$ver" ] && echo " @ ${ver}")"
}

unlock_pkg() {
    local name="$1"
    if [[ -f "$LOCK_FILE" ]]; then
        grep -v "^${name}=" "$LOCK_FILE" | grep -v "^${name}$" > "${LOCK_FILE}.tmp" || true
        mv "${LOCK_FILE}.tmp" "$LOCK_FILE"
    fi
    echo -e "${YELLOW}unlocked${NC}  ${name}"
}

list_locks() {
    if [[ -f "$LOCK_FILE" ]] && [[ -s "$LOCK_FILE" ]]; then
        echo ""
        echo -e "${BOLD}version locks:${NC}"
        while IFS= read -r line; do
            line="${line%%#*}"
            line="$(echo "$line" | xargs)"
            [[ -z "$line" ]] && continue
            echo -e "  ${CYAN}🔒${NC} ${line}"
        done < "$LOCK_FILE"
        echo ""
    else
        echo ""
        echo -e "no version locks set."
        echo ""
    fi
}

# ─── flags ─────────────────────────────────────────────────────────────────────
DO_UPDATE=false
DO_COMMIT=false
TARGET_PKG=""
CHECK_ALL=true
DO_LOCK=false
DO_UNLOCK=false
LOCK_PKG_NAME=""
LOCK_PKG_VER=""

# ─── usage ─────────────────────────────────────────────────────────────────────
usage() {
    sed -n '2,15s/^# //p' "$0"
    exit 0
}

# ─── parse args ────────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case "$1" in
        --update|-u)    DO_UPDATE=true ;;
        --commit|-c)    DO_COMMIT=true ;;
        --pkg|-p)       TARGET_PKG="$2"; CHECK_ALL=false; shift ;;
        --lock|-l)      DO_LOCK=true; LOCK_PKG_NAME="$2"; shift ;;
        --unlock|-k)    DO_UNLOCK=true; LOCK_PKG_NAME="$2"; shift ;;
        --help|-h)      usage ;;
        *)              echo -e "${RED}Unknown option: $1${NC}"; usage ;;
    esac
    shift
done

# Load locks (always)
load_locks

# ─── helpers ───────────────────────────────────────────────────────────────────

# Extract the first uncommented value of a Makefile variable.
# Usage: make_get_var <makefile> <varname>
make_get_var() {
    local f="$1" var="$2"
    grep -m1 "^${var}:=" "$f" 2>/dev/null | sed "s/^${var}:=//" | xargs
}

# Extract the GitHub owner/repo from a PKG_SOURCE_URL line.
# Resolves $(PKG_NAME) and other Makefile variables in the URL.
# "https://github.com/teddysun/$(PKG_NAME)/releases/download/..." -> "teddysun/xray-plugin"
make_get_github_repo() {
    local f="$1"
    local url raw_repo pkg_name
    url=$(grep -m1 '^PKG_SOURCE_URL:=https\?://github\.com/' "$f" 2>/dev/null)
    raw_repo=$(echo "$url" | sed -n 's|.*github\.com/\([^/]*/[^/]*\)/releases/download/.*|\1|p')

    # Expand $(PKG_NAME) if present (use intermediate variable to prevent
    # bash from interpreting $(PKG_NAME) as a command substitution).
    if echo "$raw_repo" | grep -q '\$(PKG_NAME)'; then
        pkg_name=$(make_get_var "$f" "PKG_NAME")
        local search='$(PKG_NAME)'
        raw_repo="${raw_repo//$search/$pkg_name}"
    fi

    echo "$raw_repo"
}

# Determine which variable (PKG_VERSION or PKG_RELEASE) is used as the upstream
# version in PKG_SOURCE_URL. Returns "PKG_VERSION" or "PKG_RELEASE".
make_get_version_var() {
    local f="$1"
    local url
    url=$(grep -m1 '^PKG_SOURCE_URL:=' "$f" 2>/dev/null)
    if echo "$url" | grep -q '\$(PKG_RELEASE)'; then
        echo "PKG_RELEASE"
    else
        echo "PKG_VERSION"
    fi
}

# Fetch the latest stable release tag for a GitHub repo.
# Method 1 (primary): git ls-remote --tags (no rate limit)
# Method 2 (fallback): GitHub API /releases/latest
# Strips leading 'v'/'V' from the tag.
# Returns empty string on failure.
github_latest_release() {
    local owner_repo="$1"
    local tag

    # ── method 1: git ls-remote (no rate limit) ──────────────────────────
    local all_tags
    all_tags=$(git ls-remote --tags "https://github.com/${owner_repo}.git" 2>/dev/null \
        | sed -n 's|.*refs/tags/||p' \
        | sed 's|\^{}||' \
        | grep -vE 'rc|alpha|beta|dev|pre|canary|nightly|not-quite|test|experimental|unstable|draft')

    if [[ -n "$all_tags" ]]; then
        # Pick the highest version-like tag (starts with digits or v+digit)
        tag=$(echo "$all_tags" \
            | grep -E '^(v?[0-9]|[0-9])' \
            | sort -V | tail -1)
    fi

    # ── method 2: fallback to GitHub API ─────────────────────────────────
    if [[ -z "$tag" ]]; then
        local url="${GITHUB_API}/repos/${owner_repo}/releases/latest"
        local curl_opts=(-s -f -L --connect-timeout 10 --max-time 15)
        local header=()

        if [[ -n "${GITHUB_TOKEN:-}" ]]; then
            header=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
        fi

        local resp http_code
        resp=$(curl "${curl_opts[@]}" "${header[@]}" -w '\n%{http_code}' "$url" 2>/dev/null) || return 0
        http_code=$(echo "$resp" | tail -1)
        resp=$(echo "$resp" | sed '$d')

        if [[ "$http_code" != "200" ]]; then
            return 0
        fi

        tag=$(echo "$resp" | grep -m1 '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')
    fi

    [[ -z "$tag" ]] && return 0

    # Strip leading 'v' or 'V'
    tag="${tag#v}"
    tag="${tag#V}"
    echo "$tag"
}

# Compare two version strings using sort -V.
# Returns 0 (true) if $1 < $2 (i.e. an update is available).
version_lt() {
    local a="$1" b="$2"
    [[ "$a" != "$b" ]] && [[ "$(printf '%s\n%s\n' "$a" "$b" | sort -V | head -1)" == "$a" ]]
}

# ─── API result cache (avoid double-fetching in summary) ──────────────────────
declare -A LATEST_CACHE

# ─── process one Makefile ──────────────────────────────────────────────────────
# Returns: 0 = up-to-date, 1 = skipped/error, 2 = update available, 3 = locked
process_makefile() {
    local dir="$1"
    local mf="${dir}/Makefile"
    local pkg_dir
    pkg_dir="$(basename "$dir")"

    # Parse Makefile
    local pkg_name upstream_var current_ver github_repo
    pkg_name=$(make_get_var "$mf" "PKG_NAME")
    upstream_var=$(make_get_version_var "$mf")
    github_repo=$(make_get_github_repo "$mf")

    if [[ -z "$pkg_name" ]]; then
        echo -e "  ${YELLOW}skip${NC}  ${pkg_dir}: PKG_NAME not found"
        return 1
    fi
    if [[ -z "$github_repo" ]]; then
        echo -e "  ${YELLOW}skip${NC}  ${pkg_dir} (${pkg_name}): no GitHub releases URL found"
        return 1
    fi

    if [[ "$upstream_var" == "PKG_RELEASE" ]]; then
        current_ver=$(make_get_var "$mf" "PKG_RELEASE")
    else
        current_ver=$(make_get_var "$mf" "PKG_VERSION")
    fi

    if [[ -z "$current_ver" ]]; then
        echo -e "  ${YELLOW}skip${NC}  ${pkg_dir} (${pkg_name}): ${upstream_var} not found"
        return 1
    fi

    # Check version lock
    if is_locked "$pkg_name" "$current_ver"; then
        local lock_info="🔒"
        [[ "${VERSION_LOCKS[$pkg_name]}" != "*" ]] && lock_info="🔒 @${VERSION_LOCKS[$pkg_name]}"
        echo -e "  ${CYAN}lock${NC}  ${pkg_dir} (${pkg_name}): ${current_ver} ${lock_info}"
        return 3
    fi

    # Fetch latest release (use cache if available)
    local latest_ver
    if [[ -n "${LATEST_CACHE[$github_repo]:-}" ]]; then
        latest_ver="${LATEST_CACHE[$github_repo]}"
    else
        latest_ver=$(github_latest_release "$github_repo")
        LATEST_CACHE[$github_repo]="$latest_ver"
    fi

    if [[ -z "$latest_ver" ]]; then
        echo -e "  ${RED}fail${NC}  ${pkg_dir} (${pkg_name}): unable to fetch latest release from ${github_repo}"
        return 1
    fi

    # Compare versions
    if version_lt "$current_ver" "$latest_ver"; then
        echo -e "  ${GREEN}UPDATE${NC} ${pkg_dir} (${pkg_name}): ${current_ver} -> ${BOLD}${latest_ver}${NC}  [${github_repo}]"

        if $DO_UPDATE; then
            apply_update "$dir" "$mf" "$upstream_var" "$current_ver" "$latest_ver" "$pkg_name" "$github_repo"
        fi
        return 2
    else
        echo -e "  ok     ${pkg_dir} (${pkg_name}): ${current_ver}  [${github_repo}]"
        return 0
    fi
}

# ─── apply update to Makefile ──────────────────────────────────────────────────
apply_update() {
    local dir="$1" mf="$2" upstream_var="$3" old_ver="$4" new_ver="$5"
    local pkg_name="$6" github_repo="$7"

    # Update the upstream version line
    sed -i "s/^\(${upstream_var}:=\).*/\1${new_ver}/" "$mf"

    # Update the date-stamp variable
    if [[ "$upstream_var" == "PKG_RELEASE" ]]; then
        # PKG_RELEASE is the upstream version; PKG_VERSION is the date stamp
        sed -i "s/^\(PKG_VERSION:=\).*/\1${TODAY_DASH}/" "$mf"
    else
        # PKG_VERSION is the upstream version; PKG_RELEASE is the date stamp
        sed -i "s/^\(PKG_RELEASE:=\).*/\1${TODAY}/" "$mf"
    fi

    echo -e "         -> updated ${upstream_var} to ${new_ver}, date stamp to current"

    if $DO_COMMIT; then
        local msg="bump ${pkg_name} ${old_ver} -> ${new_ver}"
        git -C "$BASE_DIR" add "${dir}/Makefile"
        if git -C "$BASE_DIR" diff --cached --quiet; then
            echo -e "         -> ${YELLOW}no changes to commit${NC}"
        else
            git -C "$BASE_DIR" commit -m "${msg}" \
                -m "Source: https://github.com/${github_repo}/releases/tag/v${new_ver}" \
                -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>" \
                >/dev/null 2>&1
            echo -e "         -> ${GREEN}committed: ${msg}${NC}"
        fi
    fi
}

# ─── main ──────────────────────────────────────────────────────────────────────
main() {
    # Handle lock/unlock commands (no scan needed)
    if $DO_LOCK; then
        load_locks
        lock_pkg "$LOCK_PKG_NAME"
        exit 0
    fi
    if $DO_UNLOCK; then
        load_locks
        unlock_pkg "$LOCK_PKG_NAME"
        exit 0
    fi

    # Show locks
    list_locks

    echo -e "${BOLD}openwrt-precompiled-feeds :: version check${NC}"
    echo -e "date: ${TODAY_DASH}  |  mode: $($DO_UPDATE && echo 'update' || echo 'dry-run')$($DO_COMMIT && echo ' + commit')"
    echo ""

    local dirs=()
    if $CHECK_ALL; then
        for d in "$BASE_DIR"/openwrt-*/; do
            [[ -d "$d" ]] && dirs+=("$d")
        done
    else
        local d="${BASE_DIR}/openwrt-${TARGET_PKG}"
        if [[ -d "$d" ]]; then
            dirs+=("$d")
        else
            echo -e "${RED}Error: package 'openwrt-${TARGET_PKG}' not found${NC}"
            exit 1
        fi
    fi

    # Sort for consistent output
    readarray -t dirs < <(printf '%s\n' "${dirs[@]}" | sort)

    local total=0 skipped=0 updates=0 locked=0
    for d in "${dirs[@]}"; do
        local rc=0
        process_makefile "$d" || rc=$?
        total=$((total + 1))
        case $rc in
            0)  ;;                             # up-to-date
            1)  skipped=$((skipped + 1)) ;;    # error/skip
            2)  updates=$((updates + 1)) ;;    # update available
            3)  locked=$((locked + 1)) ;;      # version locked
        esac
    done

    echo ""
    echo -e "${BOLD}Summary:${NC} ${total} packages scanned, ${GREEN}${updates}${NC} update(s) available"
    if [[ $locked -gt 0 ]]; then
        echo -e "         ${CYAN}${locked}${NC} locked (skipped)"
    fi
    if [[ $skipped -gt 0 ]]; then
        echo -e "         ${YELLOW}${skipped}${NC} skipped (no releases source / API error)"
    fi

    if [[ $updates -gt 0 ]] && ! $DO_UPDATE; then
        echo ""
        echo -e "Run ${CYAN}./update.sh --update${NC} to apply these updates."
    fi
    echo ""
}

main