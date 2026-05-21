# install.ps1 -- Lynceus + Pi + argo-cli installer for Windows.
#
# Installs in order:
#   1. Pi (Earendil-works' coding-agent CLI)
#   2. @vela-argo/cli (argo binary)
#   3. @vela-argo/lynceus (Pi package: theme + splash + harness skill + autostart)
#
# Auth: if ~/.npmrc doesn't already configure @vela-argo against
# GitHub Packages, the script prompts for a GitHub Personal Access
# Token with read:packages scope (input hidden via Read-Host
# -AsSecureString) and writes the registry + token lines to ~/.npmrc.
#
# Re-runnable: existing global installs are upgraded; existing
# .npmrc config is left alone.

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

function Say  { param([string]$m) Write-Host ">> $m" -ForegroundColor DarkGray }
function Ok   { param([string]$m) Write-Host "[+] $m" -ForegroundColor Green }
function Warn { param([string]$m) Write-Host "[!] $m" -ForegroundColor Yellow }
function Fail { param([string]$m) Write-Host "[x] $m" -ForegroundColor Red; exit 1 }

$PiPackage      = '@earendil-works/pi-coding-agent'
$ArgoPackage    = '@vela-argo/cli'
$LynceusPackage = '@vela-argo/lynceus'
$GhPackagesUrl  = 'https://npm.pkg.github.com'
$VelaArgoScope  = '@vela-argo'

# ── 1. Prereqs ────────────────────────────────────────────────────────
Say "Checking prerequisites..."

$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Fail "Node.js is required but not on PATH. Install Node 20+ from https://nodejs.org"
}
$nodeVersionRaw = (node --version) -replace '^v', ''
$nodeMajor = [int]($nodeVersionRaw.Split('.')[0])
if ($nodeMajor -lt 20) {
    Fail "Node 20+ is required (found v$nodeVersionRaw). Upgrade at https://nodejs.org"
}
Ok "Node v$nodeVersionRaw"

$npm = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npm) {
    Fail "npm is required but not on PATH (ships with Node -- unusual state)."
}
Ok "npm $(& npm --version)"

# ── 2. GitHub Packages auth ──────────────────────────────────────────
$Npmrc = Join-Path $HOME '.npmrc'
Say "Checking GitHub Packages auth in $Npmrc..."

$hasConfig = $false
if (Test-Path $Npmrc) {
    $existing = Get-Content $Npmrc -Raw
    if ($existing -match "$([regex]::Escape($VelaArgoScope)):registry") {
        $hasConfig = $true
    }
}

if ($hasConfig) {
    Ok "@vela-argo registry already configured in $Npmrc"
} else {
    Write-Host ""
    Write-Host "Lynceus installs @vela-argo/* packages from GitHub Packages (private)."
    Write-Host "You need a GitHub Personal Access Token with the 'read:packages' scope."
    Write-Host ""
    Write-Host "Generate one at: https://github.com/settings/tokens"
    Write-Host "  - Click 'Generate new token (classic)'"
    Write-Host "  - Tick 'read:packages'"
    Write-Host "  - If your org enforces SSO, click 'Configure SSO' next to the new token"
    Write-Host ""
    Write-Host "Paste the token below. Input is hidden. Press Ctrl-C to abort."

    $patSecure = Read-Host -Prompt 'GitHub PAT' -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($patSecure)
    try {
        $pat = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) | Out-Null
    }

    if ([string]::IsNullOrWhiteSpace($pat)) {
        Fail "No token entered. Configure ~/.npmrc manually and re-run."
    }

    $now = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $lines = @(
        "",
        "# Added by Lynceus install.ps1 on $now",
        "${VelaArgoScope}:registry=$GhPackagesUrl",
        "//npm.pkg.github.com/:_authToken=$pat"
    )
    Add-Content -Path $Npmrc -Value $lines

    # Clear pat from local scope (best-effort; PowerShell strings aren't
    # securely zeroed but at least drop the reference).
    $pat = $null

    Ok "Wrote @vela-argo registry + auth token to $Npmrc"
}

# ── 3. Install Pi ────────────────────────────────────────────────────
Say "Installing Pi ($PiPackage)..."
# --ignore-scripts is the recommended install method per pi.dev docs.
& npm install -g --ignore-scripts $PiPackage
if ($LASTEXITCODE -ne 0) { Fail "npm install of $PiPackage exited $LASTEXITCODE" }
Ok "Pi installed"

if (Get-Command pi -ErrorAction SilentlyContinue) {
    $piVer = try { (& pi --version) 2>$null } catch { 'unknown' }
    Ok "pi --version: $piVer"
} else {
    Warn "pi binary not on PATH yet (open a new PowerShell window)."
}

# ── 4. Install @vela-argo/cli ────────────────────────────────────────
Say "Installing $ArgoPackage..."
& npm install -g $ArgoPackage
if ($LASTEXITCODE -ne 0) { Fail "npm install of $ArgoPackage exited $LASTEXITCODE" }
Ok "argo CLI installed"

if (Get-Command argo -ErrorAction SilentlyContinue) {
    $argoVer = try { (& argo --version) 2>$null } catch { 'unknown' }
    Ok "argo --version: $argoVer"
} else {
    Warn "argo binary not on PATH yet (open a new PowerShell window)."
}

# ── 5. Install Lynceus into Pi ───────────────────────────────────────
Say "Installing $LynceusPackage into Pi..."
if (Get-Command pi -ErrorAction SilentlyContinue) {
    & pi install "npm:$LynceusPackage"
    if ($LASTEXITCODE -ne 0) {
        Warn "pi install exited $LASTEXITCODE -- check the output above"
    } else {
        Ok "Lynceus installed into Pi"
    }
} else {
    Warn "pi not on PATH yet; run ``pi install npm:$LynceusPackage`` after opening a new PowerShell window"
}

# ── 6. Done ──────────────────────────────────────────────────────────
Write-Host ""
Ok "All three installed."
Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. (optional) Open a new PowerShell so PATH updates pick up Pi and argo."
Write-Host "  2. cd into a project where you want to use the harness."
Write-Host "  3. Run ``pi``. Lynceus's autostart will scaffold .argo\ on first session"
Write-Host "     and boot the harness daemon for you."
Write-Host ""
Write-Host "If something didn't install cleanly:"
Write-Host "  - Check $Npmrc for the @vela-argo lines"
Write-Host "  - Try running this script again -- it's idempotent"
Write-Host "  - Or install manually: npm install -g $ArgoPackage ; pi install npm:$LynceusPackage"
