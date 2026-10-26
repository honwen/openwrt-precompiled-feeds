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

# ─── release tag cache ────────────────────────────────────────────────────────
# All release-like tags for a repo, newest first, with any leading 'v'/'V'
# stripped. One `git ls-remote` per repo (no API rate limit).
declare -A TAGS_CACHE
declare -A TAGS_LOADED
load_tags() {
    local owner_repo="$1"
    [[ -n "${TAGS_LOADED[$owner_repo]:-}" ]] && return 0
    TAGS_LOADED[$owner_repo]=1

    TAGS_CACHE[$owner_repo]=$(git ls-remote --tags "https://github.com/${owner_repo}.git" 2>/dev/null \
        | sed -n 's|.*refs/tags/||p' \
        | sed 's|\^{}||' \
        | grep -vE 'rc|alpha|beta|dev|pre|canary|nightly|not-quite|test|experimental|unstable|draft' \
        | grep -E '^[vV]?[0-9]' \
        | sed 's|^[vV]||' \
        | sort -Vu | tac || true)
}

# Fetch the latest stable release tag for a GitHub repo.
# Method 1 (primary): cached git ls-remote --tags (no rate limit)
# Method 2 (fallback): GitHub API /releases/latest
# Strips leading 'v'/'V' from the tag.
# Returns empty string on failure.
github_latest_release() {
    local owner_repo="$1"
    local tag

    # ── method 1: git ls-remote (no rate limit) ──────────────────────────
    load_tags "$owner_repo"
    tag="${TAGS_CACHE[$owner_repo]:-}"
    tag="${tag%%$'\n'*}"

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

# ─── download URL probing ─────────────────────────────────────────────────────
# A git tag can exist while its release assets are not published yet (bad case:
# nxtrace v1.7.5, whose assets 404 while v1.7.4 is fine). Every candidate
# version is therefore verified against its real download URL before it is
# reported or applied.
declare -A PROBE_CACHE

# Probe an HTTP(S) URL.
# Returns: 0 = exists (2xx), 1 = definitely missing (404/410), 2 = unknown.
probe_url() {
    local url="$1" code get_code
    if [[ -n "${PROBE_CACHE[$url]:-}" ]]; then
        case "${PROBE_CACHE[$url]}" in
            ok)      return 0 ;;
            missing) return 1 ;;
            *)       return 2 ;;
        esac
    fi

    code=$(curl -sIL -o /dev/null -w '%{http_code}' \
        --connect-timeout 8 --max-time 20 "$url" 2>/dev/null) || code="000"

    # Some CDNs reject HEAD; retry with a one-byte ranged GET.
    if [[ "$code" == "403" || "$code" == "405" || "$code" == "000" ]]; then
        get_code=$(curl -sL -o /dev/null -r 0-0 -w '%{http_code}' \
            --connect-timeout 8 --max-time 20 "$url" 2>/dev/null) || get_code="000"
        [[ "$get_code" != "000" ]] && code="$get_code"
    fi

    case "$code" in
        2??)     PROBE_CACHE[$url]="ok";      return 0 ;;
        404|410) PROBE_CACHE[$url]="missing"; return 1 ;;
        *)       PROBE_CACHE[$url]="unknown"; return 2 ;;
    esac
}

# Resolve a concrete download URL for <version> from PKG_SOURCE_URL and
# PKG_SOURCE, substituting the Makefile variables used by this feed.
# Returns 1 if the URL cannot be constructed, e.g. because the file name
# embeds a per-release commit hash (gost-plugin, tcping, pingtunnel) or an
# unknown variable.
make_download_url() {
    local f="$1" upstream_var="$2" ver="$3"
    local pkg_version pkg_release pkg_name pkg_arch pkg_libc arch
    local url_tmpl src_tmpl out ph

    pkg_version=$(make_get_var "$f" "PKG_VERSION")
    pkg_release=$(make_get_var "$f" "PKG_RELEASE")
    pkg_name=$(make_get_var "$f" "PKG_NAME")
    pkg_arch=$(make_get_var "$f" "PKG_ARCH")
    pkg_libc=$(make_get_var "$f" "PKG_LIBC")
    url_tmpl=$(make_get_var "$f" "PKG_SOURCE_URL")
    src_tmpl=$(make_get_var "$f" "PKG_SOURCE")

    [[ -z "$url_tmpl" || -z "$src_tmpl" ]] && return 1

    if [[ "$upstream_var" == "PKG_RELEASE" ]]; then
        pkg_release="$ver"
    else
        # A commit hash in the file name changes with every release, so the
        # current value says nothing about a future tag.
        if [[ "$src_tmpl" == *'$(PKG_RELEASE)'* && ! "$pkg_release" =~ ^[0-9]{8}$ ]]; then
            return 1
        fi
        pkg_version="$ver"
    fi

    # Pick a representative architecture: x86_64 maps to amd64 / x64 / 64
    # depending on the upstream naming, so read the mapping from the Makefile.
    if [[ "$pkg_arch" == '$(ARCH)' || -z "$pkg_arch" ]]; then
        pkg_arch=$(awk '
            /^ifeq[[:space:]]*\(\$\(ARCH\),x86_64\)[[:space:]]*$/ { inblock = 1; next }
            inblock && /^endif/ { inblock = 0; next }
            inblock && /^[[:space:]]*PKG_ARCH[[:space:]]*:?=/ {
                sub(/^[[:space:]]*PKG_ARCH[[:space:]]*:?=[[:space:]]*/, "")
                print
                exit
            }
        ' "$f")
        pkg_arch="${pkg_arch:-x86_64}"
    fi
    arch="x86_64"
    pkg_libc="${pkg_libc:-musl}"

    out="${url_tmpl}${src_tmpl}"
    ph='$(PKG_VERSION)'; out="${out//$ph/$pkg_version}"
    ph='$(PKG_RELEASE)'; out="${out//$ph/$pkg_release}"
    ph='$(PKG_NAME)';    out="${out//$ph/$pkg_name}"
    ph='$(PKG_ARCH)';    out="${out//$ph/$pkg_arch}"
    ph='$(ARCH)';        out="${out//$ph/$arch}"
    ph='$(PKG_LIBC)';    out="${out//$ph/$pkg_libc}"

    # Any remaining Makefile variable means this package cannot be probed.
    [[ "$out" == *'$('* ]] && return 1

    echo "$out"
}

# Verify that <version> has a downloadable asset. Probe contract:
# 0 = exists, 1 = missing, 2 = cannot verify.
probe_download_url() {
    local f="$1" upstream_var="$2" ver="$3"
    local url
    url=$(make_download_url "$f" "$upstream_var" "$ver") || return 2
    probe_url "$url"
}

# Walk tags newest -> oldest and stop at the first one the given probe accepts.
# Probe contract: 0 = exists, 1 = missing, 2 = cannot verify (accept).
# Sets LT_TAG (empty if none), LT_SKIPPED (newest tag with missing assets) and
# LT_UNVERIFIED (1 if the accepted tag could not be probed).
LT_TAG=""
LT_SKIPPED=""
LT_UNVERIFIED=0

latest_tag_with_probe() {
    local owner_repo="$1"; shift
    local tag rc attempts=0

    LT_TAG=""
    LT_SKIPPED=""
    LT_UNVERIFIED=0

    load_tags "$owner_repo"
    while IFS= read -r tag; do
        [[ -z "$tag" ]] && continue
        rc=0
        "$@" "$tag" || rc=$?
        case $rc in
            0) LT_TAG="$tag"; return 0 ;;
            2)
                # Cannot construct/verify the URL; fall back to accepting the
                # tag but remember that it was not verified.
                LT_UNVERIFIED=1
                LT_TAG="$tag"
                return 0
                ;;
            *)
                [[ -z "$LT_SKIPPED" ]] && LT_SKIPPED="$tag"
                attempts=$((attempts + 1))
                [[ $attempts -ge 5 ]] && break
                ;;
        esac
    done <<< "${TAGS_CACHE[$owner_repo]:-}"

    # No tags available from git (offline or unusual repo): fall back to the
    # GitHub API without asset verification.
    if [[ -z "${TAGS_CACHE[$owner_repo]:-}" ]]; then
        LT_TAG=$(github_latest_release "$owner_repo")
        [[ -n "$LT_TAG" ]] && LT_UNVERIFIED=1
    fi
    return 0
}

# Compare two version strings using sort -V.
# Returns 0 (true) if $1 < $2 (i.e. an update is available).
version_lt() {
    local a="$1" b="$2"
    [[ "$a" != "$b" ]] && [[ "$(printf '%s\n%s\n' "$a" "$b" | sort -V | head -1)" == "$a" ]]
}

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

    # Find the newest release that actually has a downloadable asset. A tag
    # can exist while its assets are unpublished (bad case: nxtrace v1.7.5).
    latest_tag_with_probe "$github_repo" probe_download_url "$mf" "$upstream_var"
    local latest_ver="$LT_TAG"

    if [[ -z "$latest_ver" ]]; then
        echo -e "  ${RED}fail${NC}  ${pkg_dir} (${pkg_name}): no downloadable release asset found  [${github_repo}]"
        local sample_url
        sample_url=$(make_download_url "$mf" "$upstream_var" "$LT_SKIPPED") || sample_url=""
        [[ -n "$sample_url" ]] && echo -e "         -> expected (404): ${sample_url}"
        return 1
    fi

    # Also check the version currently pinned in the Makefile; a missing asset
    # means the package cannot currently be built.
    local cur_rc=0
    probe_download_url "$mf" "$upstream_var" "$current_ver" || cur_rc=$?

    if [[ -n "$LT_SKIPPED" && "$LT_SKIPPED" != "$current_ver" ]]; then
        echo -e "  ${YELLOW}note${NC}  ${pkg_dir} (${pkg_name}): ${LT_SKIPPED} has no downloadable asset; newest published is ${latest_ver}"
    fi

    # Compare versions
    if version_lt "$current_ver" "$latest_ver"; then
        echo -e "  ${GREEN}UPDATE${NC} ${pkg_dir} (${pkg_name}): ${current_ver} -> ${BOLD}${latest_ver}${NC}  [${github_repo}]"
        if [[ "$LT_UNVERIFIED" == "1" ]]; then
            echo -e "         -> ${YELLOW}warning: download URL could not be verified${NC}"
        fi

        if $DO_UPDATE; then
            apply_update "$dir" "$mf" "$upstream_var" "$current_ver" "$latest_ver" "$pkg_name" "$github_repo"
        fi
        return 2
    fi

    if [[ $cur_rc -eq 1 ]]; then
        echo -e "  ${RED}warn${NC}  ${pkg_dir} (${pkg_name}): ${current_ver} has no downloadable asset (newest published: ${latest_ver})"
        return 1
    fi

    echo -e "  ok     ${pkg_dir} (${pkg_name}): ${current_ver}  [${github_repo}]"
    return 0
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
        commit_pkg_update "$dir" "$pkg_name" "$old_ver" "$new_ver" \
            "https://github.com/${github_repo}/releases/tag/v${new_ver}"
    fi
}

# ─── commit a version bump ─────────────────────────────────────────────────────
# Usage: commit_pkg_update <dir> <pkg_name> <old_ver> <new_ver> <source_url>
commit_pkg_update() {
    local dir="$1" pkg_name="$2" old_ver="$3" new_ver="$4" source_url="$5"
    local msg="bump ${pkg_name} ${old_ver} -> ${new_ver}"

    git -C "$BASE_DIR" add "${dir}/Makefile"
    if git -C "$BASE_DIR" diff --cached --quiet; then
        echo -e "         -> ${YELLOW}no changes to commit${NC}"
        return 0
    fi
    git -C "$BASE_DIR" commit -m "${msg}" \
        -m "Source: ${source_url}" \
        -m "Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>" \
        >/dev/null 2>&1
    echo -e "         -> ${GREEN}committed: ${msg}${NC}"
}

# ─── geodata: Download-based package (no PKG_SOURCE_URL) ──────────────────────
# openwrt-geodata pulls geoip.dat / geosite.dat through `define Download/`
# blocks, so the generic PKG_SOURCE_URL scan cannot see its upstream. The
# release tag maps to PKG_VERSION, and both HASH values must be re-fetched from
# the .sha256sum assets published next to each file, otherwise the build fails
# with a hash mismatch.
GEODATA_REPO="Loyalsoldier/v2ray-rules-dat"

# Verify a geodata release by probing its geoip.dat asset.
probe_geodata_asset() {
    probe_url "https://github.com/${GEODATA_REPO}/releases/download/$1/geoip.dat"
}

# Re-read the hash of every `define Download/` asset from <base_url>/<file>.sha256sum
refresh_download_hashes() {
    local mf="$1" base_url="$2"
    local file hash
    while read -r file; do
        [[ -z "$file" ]] && continue
        hash=$(curl -sfL --connect-timeout 10 --max-time 60 \
            "${base_url}/${file}.sha256sum" 2>/dev/null | awk '{print $1}')
        if [[ -z "$hash" ]]; then
            echo -e "         -> ${YELLOW}warning: no sha256sum found for ${file}${NC}"
            continue
        fi
        awk -v f="$file" -v h="$hash" '
            $0 ~ "^[[:space:]]*URL_FILE:=" f "$" { want=1; print; next }
            want && $0 ~ "^[[:space:]]*HASH:=" { sub(/HASH:=.*/, "HASH:=" h); want=0; print; next }
            { print }
        ' "$mf" > "${mf}.tmp" && mv "${mf}.tmp" "$mf"
        echo -e "         -> ${file} HASH -> ${hash:0:16}..."
    done < <(sed -n 's/^[[:space:]]*URL_FILE:=//p' "$mf")
}

process_geodata() {
    local dir="$1"
    local mf="${dir}/Makefile"
    local pkg_dir
    pkg_dir="$(basename "$dir")"

    local pkg_name current_ver latest_ver
    pkg_name=$(make_get_var "$mf" "PKG_NAME")
    current_ver=$(make_get_var "$mf" "PKG_VERSION")

    if [[ -z "$pkg_name" || -z "$current_ver" ]]; then
        echo -e "  ${YELLOW}skip${NC}  ${pkg_dir}: PKG_NAME or PKG_VERSION not found"
        return 1
    fi

    if is_locked "$pkg_name" "$current_ver"; then
        local lock_info="🔒"
        [[ "${VERSION_LOCKS[$pkg_name]}" != "*" ]] && lock_info="🔒 @${VERSION_LOCKS[$pkg_name]}"
        echo -e "  ${CYAN}lock${NC}  ${pkg_dir} (${pkg_name}): ${current_ver} ${lock_info}"
        return 3
    fi

    latest_tag_with_probe "$GEODATA_REPO" probe_geodata_asset
    latest_ver="$LT_TAG"

    if [[ -z "$latest_ver" ]]; then
        echo -e "  ${RED}fail${NC}  ${pkg_dir} (${pkg_name}): no downloadable release asset found  [${GEODATA_REPO}]"
        [[ -n "$LT_SKIPPED" ]] && echo -e "         -> expected (404): https://github.com/${GEODATA_REPO}/releases/download/${LT_SKIPPED}/geoip.dat"
        return 1
    fi

    # Also check the version currently pinned in the Makefile.
    local cur_rc=0
    probe_geodata_asset "$current_ver" || cur_rc=$?

    if [[ -n "$LT_SKIPPED" && "$LT_SKIPPED" != "$current_ver" ]]; then
        echo -e "  ${YELLOW}note${NC}  ${pkg_dir} (${pkg_name}): ${LT_SKIPPED} has no downloadable asset; newest published is ${latest_ver}"
    fi

    if version_lt "$current_ver" "$latest_ver"; then
        echo -e "  ${GREEN}UPDATE${NC} ${pkg_dir} (${pkg_name}): ${current_ver} -> ${BOLD}${latest_ver}${NC}  [${GEODATA_REPO}]"

        if $DO_UPDATE; then
            sed -i "s/^\(PKG_VERSION:=\).*/\1${latest_ver}/" "$mf"
            sed -i "s/^\(PKG_RELEASE:=\).*/\1${TODAY}/" "$mf"
            echo -e "         -> updated PKG_VERSION to ${latest_ver}, PKG_RELEASE to ${TODAY}"
            refresh_download_hashes "$mf" \
                "https://github.com/${GEODATA_REPO}/releases/download/${latest_ver}"
            if $DO_COMMIT; then
                commit_pkg_update "$dir" "$pkg_name" "$current_ver" "$latest_ver" \
                    "https://github.com/${GEODATA_REPO}/releases/tag/${latest_ver}"
            fi
        fi
        return 2
    fi

    if [[ $cur_rc -eq 1 ]]; then
        echo -e "  ${RED}warn${NC}  ${pkg_dir} (${pkg_name}): ${current_ver} has no downloadable asset (newest published: ${latest_ver})"
        return 1
    fi

    echo -e "  ok     ${pkg_dir} (${pkg_name}): ${current_ver}  [${GEODATA_REPO}]"
    return 0
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
        case "$(basename "$d")" in
            openwrt-geodata) process_geodata "$d" || rc=$? ;;
            *)               process_makefile "$d" || rc=$? ;;
        esac
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
        echo -e "         ${YELLOW}${skipped}${NC} skipped (no releases source / no downloadable asset / API error)"
    fi

    if [[ $updates -gt 0 ]] && ! $DO_UPDATE; then
        echo ""
        echo -e "Run ${CYAN}./update.sh --update${NC} to apply these updates."
    fi
    echo ""
}

main