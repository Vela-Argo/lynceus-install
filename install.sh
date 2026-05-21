#!/usr/bin/env bash
# install.sh — Lynceus + Pi + argo-cli installer for macOS / Linux.
#
# Installs in order:
#   1. Pi (Earendil-works' coding-agent CLI)
#   2. @vela-argo/cli (argo binary)
#   3. @vela-argo/lynceus (Pi package: theme + splash + harness skill + autostart)
#
# Auth: if ~/.npmrc doesn't already configure @vela-argo against
# GitHub Packages, the script prompts for a GitHub Personal Access
# Token with read:packages scope and writes the registry + token lines
# to ~/.npmrc. The token is read with input echo disabled.
#
# Re-runnable: existing global installs are upgraded; existing
# .npmrc config is left alone.

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
DIM='\033[2m'
RESET='\033[0m'

say()  { printf "${DIM}>>${RESET} %s\n" "$*"; }
ok()   { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}!${RESET} %s\n" "$*"; }
fail() { printf "${RED}✗${RESET} %s\n" "$*" >&2; exit 1; }

PI_PACKAGE="@earendil-works/pi-coding-agent"
ARGO_PACKAGE="@vela-argo/cli"
LYNCEUS_PACKAGE="@vela-argo/lynceus"
GH_PACKAGES_URL="https://npm.pkg.github.com"
VELA_ARGO_SCOPE="@vela-argo"

# ── 1. Prereqs ────────────────────────────────────────────────────────
say "Checking prerequisites…"

if ! command -v node >/dev/null 2>&1; then
  fail "Node.js is required but not on PATH. Install Node 20+ from https://nodejs.org"
fi
NODE_VERSION="$(node --version | sed 's/^v//')"
NODE_MAJOR="$(printf '%s' "$NODE_VERSION" | cut -d. -f1)"
if [ "$NODE_MAJOR" -lt 20 ]; then
  fail "Node 20+ is required (found v$NODE_VERSION). Upgrade at https://nodejs.org"
fi
ok "Node v$NODE_VERSION"

if ! command -v npm >/dev/null 2>&1; then
  fail "npm is required but not on PATH (ships with Node — unusual state)."
fi
ok "npm $(npm --version)"

# ── 2. GitHub Packages auth ──────────────────────────────────────────
NPMRC="$HOME/.npmrc"
say "Checking GitHub Packages auth in $NPMRC…"

if [ -f "$NPMRC" ] && grep -q "${VELA_ARGO_SCOPE}:registry" "$NPMRC"; then
  ok "@vela-argo registry already configured in $NPMRC"
else
  printf "\n"
  echo "Lynceus installs @vela-argo/* packages from GitHub Packages (private)."
  echo "You need a GitHub Personal Access Token with the 'read:packages' scope."
  echo ""
  echo "Generate one at: https://github.com/settings/tokens"
  echo "  - Click 'Generate new token (classic)'"
  echo "  - Tick 'read:packages'"
  echo "  - If your org enforces SSO, click 'Configure SSO' next to the new token"
  echo ""
  echo "Paste the token below. Input is hidden. Press Ctrl-C to abort."
  printf "GitHub PAT: "
  # Read from /dev/tty explicitly so this works under `curl ... | bash`
  # (where stdin is the pipe, not the terminal).
  if [ -r /dev/tty ]; then
    stty -echo < /dev/tty
    IFS= read -r PAT < /dev/tty
    stty echo < /dev/tty
  else
    stty -echo
    IFS= read -r PAT
    stty echo
  fi
  printf "\n"

  if [ -z "$PAT" ]; then
    fail "No token entered. Configure ~/.npmrc manually and re-run."
  fi

  {
    printf "\n# Added by Lynceus install.sh on %s\n" "$(date -u +%FT%TZ)"
    printf "%s:registry=%s\n" "$VELA_ARGO_SCOPE" "$GH_PACKAGES_URL"
    printf "//npm.pkg.github.com/:_authToken=%s\n" "$PAT"
  } >> "$NPMRC"
  chmod 600 "$NPMRC" 2>/dev/null || true
  ok "Wrote @vela-argo registry + auth token to $NPMRC"
fi

# ── 3. Install Pi ────────────────────────────────────────────────────
say "Installing Pi ($PI_PACKAGE)…"
# --ignore-scripts is the recommended install method per pi.dev docs.
npm install -g --ignore-scripts "$PI_PACKAGE"
ok "Pi installed"

if ! command -v pi >/dev/null 2>&1; then
  warn "pi binary not on PATH yet (you may need to open a new terminal)."
else
  ok "pi --version: $(pi --version 2>/dev/null || echo unknown)"
fi

# ── 4. Install @vela-argo/cli ────────────────────────────────────────
say "Installing $ARGO_PACKAGE…"
npm install -g "$ARGO_PACKAGE"
ok "argo CLI installed"

if ! command -v argo >/dev/null 2>&1; then
  warn "argo binary not on PATH yet (open a new terminal)."
else
  ok "argo --version: $(argo --version 2>/dev/null || argo --help 2>/dev/null | head -1 || echo unknown)"
fi

# ── 5. Install Lynceus into Pi ───────────────────────────────────────
say "Installing $LYNCEUS_PACKAGE into Pi…"
if command -v pi >/dev/null 2>&1; then
  pi install "npm:$LYNCEUS_PACKAGE" || warn "pi install completed with a non-zero exit — check above"
  ok "Lynceus installed into Pi"
else
  warn "pi not on PATH yet; run \`pi install npm:$LYNCEUS_PACKAGE\` after opening a new terminal"
fi

# ── 6. Done ──────────────────────────────────────────────────────────
printf "\n"
ok "All three installed."
printf "\n"
echo "Next steps:"
echo "  1. (optional) Open a new terminal so PATH updates pick up Pi and argo."
echo "  2. cd into a project where you want to use the harness."
echo "  3. Run \`pi\`. Lynceus's autostart will scaffold .argo/ on first session"
echo "     and boot the harness daemon for you."
echo ""
echo "If something didn't install cleanly:"
echo "  - Check $NPMRC for the @vela-argo lines"
echo "  - Try running this script again — it's idempotent"
echo "  - Or install manually: npm install -g $ARGO_PACKAGE ; pi install npm:$LYNCEUS_PACKAGE"
